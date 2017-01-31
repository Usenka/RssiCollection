#include <Timer.h>
#include "DemoCollection.h"
#include "printf.h"
#include "CtpDebugMsg.h"
#include "Ctp.h"

module DemoCollectionC {
  uses {
    // System components
    interface Boot;
    interface SplitControl as RadioControl;
    interface Leds;
    //interface LowPowerListening as LPL;

    // Application and CTP
    interface Timer<TMilli> as DataTimer;
    interface RootControl;
    interface StdControl as RoutingControl;
    interface Send as DataSend;
    interface Receive as DataReceive;
    interface Intercept as DataIntercept;
    interface Read<uint16_t> as SensorRead;
    interface CC2420Packet;
    interface AMPacket;
    interface Packet as CtpDataPacket;
    interface CtpPacket;
    interface Random;

    // Control communication
    interface AMSend as SerialCtlSend;
    interface Receive as SerialCtlReceive;

    // UART Logger
    interface AMSend as SerialLogSend;
    interface SplitControl as SerialControl;
    interface Timer<TMilli> as LogTimer;
    interface Timer<TMilli> as RetxmitTimer;
    interface Pool<message_t> as LogMessagePool;
    interface Queue<message_t*> as LogSendQueue;

    // Radio low-level event handlers
    interface SplitControl as RadioLowState;

    //interface Send as RadioLowSend;
    //interface Receive as RadioLowRecv;
  }
  // Logger
  provides interface CollectionDebug;
}

implementation {
  message_t data_Pkt;
  uint32_t data_seqNum = 0;
  uint16_t data_lastValue = 0xbeaf;
  bool APP_BUSY_SND = FALSE;
  bool EXP_RUNNING = FALSE;
  bool EXP_PENDING = FALSE;

  // Logger variables
  bool serialBusy = FALSE;
  uint8_t retries = 0;
  message_t log_Packet;
  // Logger debuging 
  uint16_t log_statSent = 0;
  uint16_t log_statEnqueueFail = 0;
  uint16_t log_statPoolEmpty = 0;
  uint16_t log_statSendFail = 0;
  uint16_t log_statSendDoneFail = 0;
  uint16_t log_statSendDoneOk = 0;
  uint16_t log_statSendDoneBug = 0;

  // Tracking radio state
  bool RADIO_ON = FALSE;
  uint32_t radio_off_ts = 0;
  uint32_t radio_off_time = 0;


  /////////////////////////////////////////////////////////////
  // Logger
  // TODO: Extract this to an interface in a separate component
  /////////////////////////////////////////////////////////////

  /*
  *  The Logger's sending task
  */
  task void logSendTask() {
    if (serialBusy)
      return;
    else {
      if (call LogSendQueue.empty())
        return;
      else {
        message_t* smsg = call LogSendQueue.head();
        error_t eval = call SerialLogSend.send(AM_BROADCAST_ADDR, smsg, sizeof(LoggerMsg));
        if (eval == SUCCESS) {
          serialBusy = TRUE;
          log_statSent++;
          return;
        }
        else {
          retries++;
          log_statSendFail++;
          if (retries >= MAX_LOGSERIAL_RETRIES){
            retries = 0;
            call LogSendQueue.dequeue();
            call LogMessagePool.put(smsg);
          }
          if (! call LogSendQueue.empty())
            call RetxmitTimer.startOneShot(FAILED_LOGSERIAL_BACKOFF);//post logSendTask();
        }
      }
    }
  }

  event void RetxmitTimer.fired(){
    if (! call LogSendQueue.empty())
      post logSendTask();
  }
  
  /*
  *  The Logger's AM sender
  */
  event void SerialLogSend.sendDone(message_t *msg, error_t error) {
      message_t* qh = call LogSendQueue.head();
      if (qh == NULL || qh != msg) {
        // something is wrong here
        log_statSendDoneBug++;
      } 
      else {
        retries++;
        if (retries >= MAX_LOGSERIAL_RETRIES || error == SUCCESS){
          retries = 0;
          call LogSendQueue.dequeue();
          call LogMessagePool.put(msg);
        }
        if (error == SUCCESS) 
          log_statSendDoneOk++;
        else
          log_statSendDoneFail++;
      }
      serialBusy = FALSE;
      if (error != SUCCESS){
        call RetxmitTimer.startOneShot(FAILED_LOGSERIAL_BACKOFF);
      } else if (!call LogSendQueue.empty()){
          post logSendTask();
      }
  }

   /*
  * This function allocates a new empty Logger message.
  * It checks if there is memory left in the pool and the queue is not exhausted
  */
  message_t* logAllocNewMessage() {
    message_t* nmsg;
    LoggerMsg* log_msg;
    if (call LogMessagePool.empty()) {
      log_statPoolEmpty++;
      return NULL;
    }
    nmsg = call LogMessagePool.get();
    log_msg = call SerialLogSend.getPayload(nmsg, sizeof(LoggerMsg));

    // Populate the new message with 0s for the case not all fields will be set
    if (log_msg != NULL)
      memset(log_msg, 0, sizeof(LoggerMsg));
    else {
      return NULL;
    }
    return nmsg;
  }

  /* This function is called after the new message has been created 
  *  by the logEvent() and it is ready to be sent over the serial.
  *  It checks if the send quene is not exhausted and posts logSendTask
  */
  void logSendMessage(message_t* msg) {
    if (call LogSendQueue.enqueue(msg) == SUCCESS) {
      post logSendTask();
      return;
    } 
    else {
      log_statEnqueueFail++;
      call LogMessagePool.put(msg);
      return;
    }
  }

  /*
  * Event handler helpers
  */
  void logAppMsgSent(uint32_t etime, uint32_t seq_num) {
    LoggerMsg* log_msg;
    message_t* nmsg;

    nmsg = logAllocNewMessage();
    if (nmsg == NULL)
      return;
    log_msg = call SerialLogSend.getPayload(nmsg, sizeof(LoggerMsg));

    log_msg->type = LOG_APP_SND;
    log_msg->timestamp = etime;
    log_msg->log_src = TOS_NODE_ID;
    log_msg->src = TOS_NODE_ID;
    log_msg->seq_num = seq_num;
    
    logSendMessage(nmsg);
  }

  void logAppMsgReceived(uint32_t etime, am_addr_t origin, uint32_t seq_num, uint8_t rssi) {
    LoggerMsg* log_msg;
    message_t* nmsg;

    nmsg = logAllocNewMessage();
    if (nmsg == NULL)
      return;
    log_msg = call SerialLogSend.getPayload(nmsg, sizeof(LoggerMsg));

    log_msg->type = LOG_APP_RCV;
    log_msg->timestamp = etime;
    log_msg->log_src = TOS_NODE_ID;
    log_msg->src = origin;
    log_msg->seq_num = seq_num;
    // WARNING: The raw RSSI value is int8_t
    log_msg->arg_u8 = rssi;
    
    logSendMessage(nmsg);
  }

  void logAppMsgIntercepted(uint32_t etime, am_addr_t origin, uint16_t seq_num, am_addr_t prev_hop, uint8_t rssi) {
    LoggerMsg* log_msg;
    message_t* nmsg;

    nmsg = logAllocNewMessage();
    if (nmsg == NULL)
      return;
    log_msg = call SerialLogSend.getPayload(nmsg, sizeof(LoggerMsg));

    log_msg->type = LOG_APP_INT;
    log_msg->timestamp = etime;
    log_msg->log_src = TOS_NODE_ID;
    log_msg->src = origin;
    log_msg->seq_num = seq_num;
    log_msg->dst = prev_hop;
    // WARNING: The raw RSSI value is int8_t
    log_msg->arg_u8 = rssi;

    logSendMessage(nmsg);
  }

  void logAppErrorSending(uint32_t etime, am_addr_t nodeid, uint32_t seq_num, error_t error) {
    LoggerMsg* log_msg;
    message_t* nmsg;

    nmsg = logAllocNewMessage();
    if (nmsg == NULL)
      return;
    log_msg = call SerialLogSend.getPayload(nmsg, sizeof(LoggerMsg));

    log_msg->type = LOG_APP_ERR_SND;
    log_msg->timestamp = etime;
    log_msg->log_src = TOS_NODE_ID;
    log_msg->src = nodeid;
    log_msg->seq_num = seq_num;
    log_msg->arg_u8 = error;
    
    logSendMessage(nmsg);
  }
  
/*
  void logHopMessageReceived(uint32_t etime, am_addr_t origin, uint32_t seq_num, am_addr_t prev_hop, uint8_t rssi) {
    LoggerMsg* log_msg;
    message_t* nmsg;

    nmsg = logAllocNewMessage();
    if (nmsg == NULL)
      return;
    log_msg = call SerialLogSend.getPayload(nmsg, sizeof(LoggerMsg));

    log_msg->type = LOG_HOP_RCV;
    log_msg->timestamp = etime;
    log_msg->log_src = TOS_NODE_ID;
    log_msg->src = origin;
    log_msg->seq_num = seq_num;
    log_msg->dst = prev_hop;
    log_msg->arg_u8 = rssi;

    logSendMessage(nmsg);     
  }

  void logHopMessageSent(uint32_t etime, am_addr_t origin, uint32_t seq_num, am_addr_t nex_hop, error_t err) {
    LoggerMsg* log_msg;
    message_t* nmsg;

    nmsg = logAllocNewMessage();
    if (nmsg == NULL)
      return;
    log_msg = call SerialLogSend.getPayload(nmsg, sizeof(LoggerMsg));

    log_msg->type = LOG_HOP_SND;
    log_msg->timestamp = etime;
    log_msg->log_src = TOS_NODE_ID;
    log_msg->src = origin;
    log_msg->seq_num = seq_num;
    log_msg->dst = nex_hop;
    log_msg->arg_u8 = err;
    
    logSendMessage(nmsg);     
  }
*/

  void logCtrlBeaconSent(uint32_t etime, am_addr_t parent, uint16_t etx) {
    LoggerMsg* log_msg;
    message_t* nmsg;

    nmsg = logAllocNewMessage();
    if (nmsg == NULL)
      return;
    log_msg = call SerialLogSend.getPayload(nmsg, sizeof(LoggerMsg));

    log_msg->type = LOG_CTC_BCN;
    log_msg->timestamp = etime;
    log_msg->log_src = TOS_NODE_ID;
    log_msg->src = TOS_NODE_ID;
    log_msg->dst = parent;
    log_msg->arg_u16 = etx;

    logSendMessage(nmsg);
  }

  void logCtrlNewParent(uint32_t etime, am_addr_t parent, uint16_t etx) {
    LoggerMsg* log_msg;
    message_t* nmsg;

    nmsg = logAllocNewMessage();
    if (nmsg == NULL)
      return;
    log_msg = call SerialLogSend.getPayload(nmsg, sizeof(LoggerMsg));

    log_msg->type = LOG_CTC_NPT;
    log_msg->timestamp = etime;
    log_msg->log_src = TOS_NODE_ID;
    log_msg->src = TOS_NODE_ID;
    log_msg->dst = parent;
    log_msg->arg_u16 = etx;
    logSendMessage(nmsg);
  }

  void logDataPacketDroppedLocal(uint32_t etime, am_addr_t origin, uint32_t seq_num, am_addr_t dst) {
    LoggerMsg* log_msg;
    message_t* nmsg;

    nmsg = logAllocNewMessage();
    if (nmsg == NULL)
      return;
    log_msg = call SerialLogSend.getPayload(nmsg, sizeof(LoggerMsg));

    log_msg->type = LOG_CTD_DRP_LOCAL;
    log_msg->timestamp = etime;
    log_msg->log_src = TOS_NODE_ID;
    log_msg->src = origin;
    log_msg->seq_num = seq_num;
    log_msg->dst = dst;

    logSendMessage(nmsg);
  }

  void logDataPacketDroppedFwd(uint32_t etime, am_addr_t origin, uint32_t seq_num, am_addr_t dst) {
    LoggerMsg* log_msg;
    message_t* nmsg;

    nmsg = logAllocNewMessage();
    if (nmsg == NULL)
      return;
    log_msg = call SerialLogSend.getPayload(nmsg, sizeof(LoggerMsg));

    log_msg->type = LOG_CTD_DRP_FWD;
    log_msg->timestamp = etime;
    log_msg->log_src = TOS_NODE_ID;
    log_msg->src = origin;
    log_msg->seq_num = seq_num;
    log_msg->dst = dst;

    logSendMessage(nmsg);
  }

  void logDataRtmWaitack(uint32_t etime, am_addr_t origin, uint16_t seq_num, am_addr_t parent) {
    LoggerMsg* log_msg;
    message_t* nmsg;

    nmsg = logAllocNewMessage();
    if (nmsg == NULL)
      return;
    log_msg = call SerialLogSend.getPayload(nmsg, sizeof(LoggerMsg));

    log_msg->type = LOG_CTD_RTM_WAITACK;
    log_msg->timestamp = etime;
    log_msg->log_src = TOS_NODE_ID;
    log_msg->src = origin;
    log_msg->seq_num = seq_num;
    log_msg->dst = parent;

    logSendMessage(nmsg);
  }

  void logDataRtmFailure(uint32_t etime, am_addr_t origin, uint16_t seq_num, am_addr_t parent) {
    LoggerMsg* log_msg;
    message_t* nmsg;

    nmsg = logAllocNewMessage();
    if (nmsg == NULL)
      return;
    log_msg = call SerialLogSend.getPayload(nmsg, sizeof(LoggerMsg));

    log_msg->type = LOG_CTD_RTM_FAIL;
    log_msg->timestamp = etime;
    log_msg->log_src = TOS_NODE_ID;
    log_msg->src = origin;
    log_msg->seq_num = seq_num;
    log_msg->dst = parent;

    logSendMessage(nmsg);
  }

  void logDataPacketSent(uint32_t etime, am_addr_t origin, uint16_t seq_num, am_addr_t parent) {
    LoggerMsg* log_msg;
    message_t* nmsg;

    nmsg = logAllocNewMessage();
    if (nmsg == NULL)
      return;
    log_msg = call SerialLogSend.getPayload(nmsg, sizeof(LoggerMsg));

    log_msg->type = LOG_CTD_SND;
    log_msg->timestamp = etime;
    log_msg->log_src = TOS_NODE_ID;
    log_msg->src = origin;
    log_msg->seq_num = seq_num;
    log_msg->dst = parent;

    logSendMessage(nmsg);
  }

  void logDataPacketForwarded(uint32_t etime, am_addr_t origin, uint16_t seq_num, am_addr_t next_hop) {
    LoggerMsg* log_msg;
    message_t* nmsg;

    nmsg = logAllocNewMessage();
    if (nmsg == NULL)
      return;
    log_msg = call SerialLogSend.getPayload(nmsg, sizeof(LoggerMsg));

    log_msg->type = LOG_CTD_FWD;
    log_msg->timestamp = etime;
    log_msg->log_src = TOS_NODE_ID;
    log_msg->src = origin;
    log_msg->seq_num = seq_num;
    log_msg->dst = next_hop;

    logSendMessage(nmsg);
  }

  void logHardwareRadioStats(uint32_t etime) {
    LoggerMsg* log_msg;
    message_t* nmsg;

    nmsg = logAllocNewMessage();
    if (nmsg == NULL)
      return;
    log_msg = call SerialLogSend.getPayload(nmsg, sizeof(LoggerMsg));
    log_msg->type = LOG_HW_RADIO_STAT;
    log_msg->timestamp = etime;
    log_msg->log_src = TOS_NODE_ID;

    atomic {
      log_msg->seq_num = call LogTimer.getdt(); // the length of the interval
      log_msg->arg_u32 = radio_off_time; // time the radio was off during the interval

      // Reset the radio interval time (hence atomic)
      radio_off_time = 0;
    }

    logSendMessage(nmsg);
  }

  void logLoggerStats(uint32_t etime) {
    LoggerMsg* log_msg;
    message_t* nmsg;

    nmsg = logAllocNewMessage();
    if (nmsg == NULL)
      return;
    log_msg = call SerialLogSend.getPayload(nmsg, sizeof(LoggerMsg));

    log_msg->type = LOG_DBG_STAT;
    log_msg->timestamp = etime;
    log_msg->log_src = TOS_NODE_ID;
    log_msg->arg_u32 = log_statSent;
    log_msg->src = log_statPoolEmpty;
    log_msg->dst = log_statEnqueueFail;
    log_msg->seq_num = log_statSendFail;
    log_msg->arg_u8 = log_statSendDoneFail;
    log_msg->arg_u16 = log_statSendDoneBug;

    logSendMessage(nmsg);
  }

  void logSimpleEvent(uint32_t etime, uint8_t etype) {
    LoggerMsg* log_msg;
    message_t* nmsg;

    nmsg = logAllocNewMessage();
    if (nmsg == NULL)
      return;
    log_msg = call SerialLogSend.getPayload(nmsg, sizeof(LoggerMsg));

    log_msg->type = etype;
    log_msg->timestamp = etime;
    log_msg->log_src = TOS_NODE_ID;

    logSendMessage(nmsg);
  }
  
  // Soft reboot
  void reboot() {
    WDTCTL = WDT_ARST_1_9;
    while(1);
  }

  void startExperiment() {
    call RoutingControl.start();
    if (TOS_NODE_ID == ROOT_NODE_ID) {
      if (call RootControl.setRoot() != SUCCESS) {
        if (LEDS)
          call Leds.led0On();
      }
    }
    else {
      call DataTimer.startOneShot(DATA_TIMER_PERIOD_MILLI);
    }
    call LogTimer.startPeriodic(LOG_STAT_INTERVAL_MILLI);
    logSimpleEvent(call LogTimer.getNow(), LOG_EXP_START);

    if (LEDS)
      call Leds.led1Off();
  }

  void stopExperiment() {
    call RoutingControl.stop();
    call DataTimer.stop();
    call LogTimer.stop();
    data_seqNum = 0;
    
    logSimpleEvent(call LogTimer.getNow(), LOG_EXP_STOP);

    if (LEDS) {
      call Leds.led0Off();
      call Leds.led2Off();
      call Leds.led1On();
    }
  }

  event void LogTimer.fired() {
    // The timer was started as one shot to start the experiment
    if (!EXP_RUNNING) {
      startExperiment();
      EXP_RUNNING = TRUE;
    }
    else {
      logLoggerStats(call LogTimer.getNow());

      // Log radio stats
      logHardwareRadioStats(call LogTimer.getNow());
    }
  }

  /////////////////////////////////////////////////////////////
  // System components
  /////////////////////////////////////////////////////////////

  event void Boot.booted() {
    //call LPL.setLocalWakeupInterval(LPL_INTERVAL);
    
    // Cleanup the LogSendQueue and LogMessagePool FIXME: is this needed?
    while (! call LogSendQueue.empty()) {
      message_t* smsg = call LogSendQueue.head();
      call LogMessagePool.put(smsg);
      call LogSendQueue.dequeue();
    }

    call RadioControl.start();
    call SerialControl.start();
  }

  // Radio
  event void RadioControl.startDone(error_t err) {
    if (err != SUCCESS)
      call RadioControl.start();
    else {
      if (LEDS)
        call Leds.led1On();
      }
  }
  event void RadioControl.stopDone(error_t err) {}

  // Serial
  event void SerialControl.startDone(error_t err) {
    if (err != SUCCESS)
      call SerialControl.start();
    else {
      logSimpleEvent(call LogTimer.getNow(), LOG_HW_BOOT);
    }
  }
  event void SerialControl.stopDone(error_t err) {}


  /////////////////////////////////////////////////////////////
  // CollectionDebug interface implementation
  /////////////////////////////////////////////////////////////

  command error_t CollectionDebug.logEvent(uint8_t type) {
    switch (type) {
      case NET_C_FE_SEND_QUEUE_FULL:
        // CtpForwardingEngine cannot queue message, the queue is full
        break;

      case NET_C_FE_SENDQUEUE_EMPTY:
        // CtpForwardingEngine has sent the last message in the queue
        break;

      case NET_C_FE_NO_ROUTE:
        // CtpForwardingEngine tries to send a message, but there is no route
        break;

      case NET_C_FE_DUPLICATE_CACHE_AT_SEND:
        // CtpForwardingEngine encounters a duplicate message
        break;

      case NET_C_FE_PUT_MSGPOOL_ERR:
        // CtpForwardingEngine error putting a message in the MessagePool
        break;

      case NET_C_FE_PUT_QEPOOL_ERR:
        // CtpForwardingEngine error putting a queue entry in the QEntryPool
        break;

      case NET_C_FE_SUBSEND_SIZE:
        // CtpForwardingEngine error sending message: the packet is too big (will be truncated)
        break;

      case NET_C_FE_MSG_POOL_EMPTY:
        // CtpForwardingEngine forwarding message pool is empty
        break;

      case NET_C_FE_QENTRY_POOL_EMPTY:
        // CtpForwardingEngine forwarding entry pool is empty
        break;

      case NET_C_FE_DUPLICATE_CACHE:
        // CtpForwardingEngine has received a message to forward, but it was already forwarded (duplicate)
        break;

      case NET_C_FE_DUPLICATE_QUEUE:
        // CtpForwardingEngine has received a message to forward, but it is already in the queue
        break;

      default:
        printf("CollectionDebug.logEvent UNHANDLED EVENT TYPE: %x\n", type);
        printfflush();
        break;
    }
    return SUCCESS;
  }

  command error_t CollectionDebug.logEventSimple(uint8_t type, uint16_t arg) {
    switch(type) {
      default:
        printf("CollectionDebug.logEventSimple UNHANDLED EVENT TYPE: %x\n", type);
        printfflush();
        break; 
    }
    return SUCCESS;
  }

  command error_t CollectionDebug.logEventDbg(uint8_t type, uint16_t arg1, uint16_t arg2, uint16_t arg3) {
    switch (type) {
      case NET_C_TREE_NEW_PARENT:
        // CtpRoutingEngine selects a new parent: 
        // logEventDbg(NET_C_TREE_NEW_PARENT, best->neighbor, best->info.etx, minEtx)
        logCtrlNewParent(call LogTimer.getNow(), arg1, arg2);
        break;

      default:
        printf("CollectionDebug.logEventDbg UNHANDLED EVENT TYPE: %x\n", type);
        printfflush();
        break;
      }
    return SUCCESS;
  }

  // Events related to the data plane / messages forwarding
  command error_t CollectionDebug.logEventMsg(uint8_t type, uint32_t msg, am_addr_t origin, am_addr_t node) {
    switch (type) {
      case NET_C_FE_SENT_MSG:
        // CtpForwardingEngine the sent local message was delivered (acknowledged)
        // logEventMsg(NET_C_FE_SENT_MSG, seqno, origin, dst)
        logDataPacketSent(call LogTimer.getNow(), origin, msg, node);
        break;

      case NET_C_FE_SENDDONE_FAIL_ACK_SEND:
        // CtpForwardingEngine the sent local message was dropped (NOT acknowledged after max retries)
        // logEventMsg(NET_C_FE_SENDDONE_FAIL_ACK_SEND, seqno, origin, dst)
        logDataPacketDroppedLocal(call LogTimer.getNow(), origin, msg, node);
        break;

      case NET_C_FE_FWD_MSG:
        // CtpForwardingEngine the forwarded message was delivered (acknowledged)
        // logEventMsg(NET_C_FE_FWD_MSG, seqno, origin, dst)
        logDataPacketForwarded(call LogTimer.getNow(), origin, msg, node);
        break;

      case NET_C_FE_SENDDONE_FAIL_ACK_FWD:
        // CtpForwardingEngine the forwarded message was dropped (NOT acknowledged after max retries)
        // logEventMsg(NET_C_FE_SENDDONE_FAIL_ACK_FWD, seqno, origin, dst)
        logDataPacketDroppedFwd(call LogTimer.getNow(), origin, msg, node);
        break;

      case NET_C_FE_RCV_MSG:
        // CtpForwardingEngine has received a message to forward
        // logEventMsg(NET_C_FE_RCV_MSG, seq_num, origin, thl);
        break;

      case NET_C_FE_SENDDONE_FAIL:
        // CtpForwardingEngine radio (link layer) has failed to send a packet - it will be retransmitted
        // logEventMsg(NET_C_FE_SENDDONE_FAIL, seqno, origin, dst)
        logDataRtmFailure(call LogTimer.getNow(), origin, msg, node);
        break;

      case NET_C_FE_SENDDONE_WAITACK:
        // CtpForwardingEngine the forwarded message was not acknowledged - it will be retransmitted
        // logEventMsg(NET_C_FE_SENDDONE_WAITACK, seqno, origin, dst)
        logDataRtmWaitack(call LogTimer.getNow(), origin, msg, node);
        break;

      case NET_C_FE_LOOP_DETECTED:
        // CtpForwardingEngine has detected a loop
        // logEventMsg(NET_C_FE_LOOP_DETECTED, seqno, origin, dst)
        break;

      default:
        printf("CollectionDebug.logEventMsg UNHANDLED EVENT TYPE: %x\n", type);
        printfflush(); 
        break;
    }
    return SUCCESS;
  }

  // Events related to control plane / routing update
  command error_t CollectionDebug.logEventRoute(uint8_t type, am_addr_t parent, uint8_t hopcount, uint16_t metric) {
    switch (type) {
      case NET_C_TREE_SENT_BEACON:
        // CtpRoutingEngine sends a beacon: 
        // logEventRoute(NET_C_TREE_SENT_BEACON, parent, 0, etx)
        logCtrlBeaconSent(call LogTimer.getNow(), parent, metric);
        break;

      case NET_C_TREE_NEW_PARENT:
        // CtpRoutingEngine signal new parent for the root: 
        // logEventDbg(NET_C_TREE_NEW_PARENT, routeInfo.parent, 0, routeInfo.etx)
        break;
      
      default:
        printf("CollectionDebug.logEventRoute UNHANDLED EVENT TYPE: %x\n", type);
        printfflush();
        break;
    } 
    return SUCCESS;
  }


  /////////////////////////////////////////////////////////////
  // Radio Low-level events
  /////////////////////////////////////////////////////////////

  event void RadioLowState.startDone(error_t error) {
    RADIO_ON = TRUE;
    atomic radio_off_time += call LogTimer.getNow() - radio_off_ts;
  }

  event void RadioLowState.stopDone(error_t error) {
    RADIO_ON = FALSE;
    atomic radio_off_ts = call LogTimer.getNow();
  }
/*
  event message_t* RadioLowRecv.receive(message_t* msg, void* payload, uint8_t len) {
    // Do nothing if the root
    if (TOS_NODE_ID != ROOT_NODE_ID) {
      // First check that the received message is the CTP data message
      if (call AMPacket.type(msg) == AM_CTP_DATA) {
        // Now check if that is actually our application message
        if (call CtpPacket.getType(msg) == CTP_DEMOCOLLECTIONID) {
            // And finally, get the payload
            DemoCollectionMsg* pkt = (DemoCollectionMsg*) call CtpDataPacket.getPayload(msg, sizeof(DemoCollectionMsg));

            // log the reception event
            logHopMessageReceived(call LogTimer.getNow(), pkt->nodeid, pkt->seq_num, 
                                  call AMPacket.source(msg), (uint8_t) (call CC2420Packet.getRssi(msg)));
        }
      }
    }
    return msg;
  }

  event void RadioLowSend.sendDone(message_t* msg, error_t err) {
    // First check that the sent message is the CTP data message
    if (call AMPacket.type(msg) == AM_CTP_DATA) {
      // Now check if that is actually our application message
      if (call CtpPacket.getType(msg) == CTP_DEMOCOLLECTIONID) {
        DemoCollectionMsg* pkt;
        am_addr_t origin;
        am_addr_t dst;
        uint32_t seq_num;
        // And finally, get the payload
        pkt = (DemoCollectionMsg*) call CtpDataPacket.getPayload(msg, sizeof(DemoCollectionMsg));
        origin = pkt->nodeid;
        seq_num = pkt->seq_num;
        dst = call AMPacket.destination(msg);

        logHopMessageSent(call LogTimer.getNow(), origin, seq_num, dst, err);
      }
    }
  }
  */

  /////////////////////////////////////////////////////////////
  // Application and collection
  /////////////////////////////////////////////////////////////

  void dataSendMessage() {
    DemoCollectionMsg* msg = (DemoCollectionMsg*) call DataSend.getPayload(&data_Pkt, sizeof(DemoCollectionMsg));
    error_t snd_result;
    
    memset(msg, 0, sizeof(DemoCollectionMsg));
    msg->nodeid = TOS_NODE_ID;
    msg->seq_num = data_seqNum;
    msg->data = data_lastValue;

    //call LPL.setRemoteWakeupInterval(&data_Pkt, LPL_INTERVAL);
    snd_result = call DataSend.send(&data_Pkt, sizeof(DemoCollectionMsg));

    if (snd_result != SUCCESS) {
      // NOTE: CTP returns EBUSY when Apps one-packet queue is exhausted <- Congestion
      logAppErrorSending(call LogTimer.getNow(), TOS_NODE_ID, data_seqNum, snd_result);
      if (LEDS)
        call Leds.led0Toggle();
    }
    else {
      logAppMsgSent(call LogTimer.getNow(), data_seqNum);
      APP_BUSY_SND = TRUE;
      data_seqNum++;
    }
  }

  event void DataTimer.fired() {
    uint32_t nextInt;
    if (LEDS)
      call Leds.led2Toggle();

    call SensorRead.read();
    
    // Randomize the next timer interval
    nextInt = call Random.rand32() % DATA_TIMER_PERIOD_MILLI;
    nextInt += DATA_TIMER_PERIOD_MILLI >> 1;
    call DataTimer.startOneShot(nextInt);
  }

  // Sensing events
  event void SensorRead.readDone(error_t result, uint16_t value) {
    // We care about the value, so try sending anyway
    data_lastValue = value;
    if (!APP_BUSY_SND)
      dataSendMessage();
    else {
      if (LEDS)
        call Leds.led0Toggle();
      logSimpleEvent(call LogTimer.getNow(), LOG_APP_CNG);
    }
  }

  // CTP always signals SUCCESS: no processing needed
  event void DataSend.sendDone(message_t* m, error_t err) {
    APP_BUSY_SND = FALSE;
  }

  // Signalled by forwarding engine on receiving a packet by the root node
  event message_t* DataReceive.receive(message_t* msg, void* payload, uint8_t len) {
    int8_t rssi;
    if (len == sizeof(DemoCollectionMsg)) {
      DemoCollectionMsg* pkt = (DemoCollectionMsg*)payload;
      rssi = call CC2420Packet.getRssi(msg);
      logAppMsgReceived(call LogTimer.getNow(), pkt->nodeid, pkt->seq_num, (uint8_t) rssi);
    }
    if (LEDS)
      call Leds.led1Toggle();
    return msg;
  }

  // Signalled by forwarding engine on receiving a packet to forward by a node on the path
  event bool DataIntercept.forward(message_t* msg, void* payload, uint8_t len) {
    int8_t rssi;
    if (len == sizeof(DemoCollectionMsg)) {
      DemoCollectionMsg* pkt = (DemoCollectionMsg*)payload;
      rssi = call CC2420Packet.getRssi(msg);
      logAppMsgIntercepted(call LogTimer.getNow(), pkt->nodeid, pkt->seq_num, call AMPacket.source(msg), (uint8_t) rssi);
    }
    return TRUE;
  }


  /////////////////////////////////////////////////////////////
  // Serial control communication
  /////////////////////////////////////////////////////////////

  event message_t* SerialCtlReceive.receive(message_t* msg, void* payload, uint8_t len) {
    if (len == sizeof(SerialControlMsg)) {
      SerialControlMsg* smsg = (SerialControlMsg*) payload;
      uint8_t cmd = smsg->cmd;
      uint8_t param = smsg->param;
      switch (cmd) {
        case CMD_REBOOT:
          reboot();
          break;

        case CMD_EXP_START:
          if (!EXP_PENDING) {
            uint32_t delay;
	    logSimpleEvent(call LogTimer.getNow(),param);
            if (param == 0) {
              delay = call Random.rand32() % DEFAULT_DELAY_RAND_SEC;
            }
            else {
              delay = param;
            }
            delay += DEFAULT_DELAY_RAND_SEC >> 1;
            call LogTimer.startOneShot(delay * 1024);            
            EXP_PENDING = TRUE;
          }
          break;

        case CMD_EXP_STOP:
          if (EXP_RUNNING) {
            stopExperiment();
            EXP_PENDING = FALSE;
            EXP_RUNNING = FALSE;
          }
          break;
        }
    }
    else {
      printf ("Unknown serial control message received\n"); 
    }
    printfflush();
    return msg;
  }

  event void SerialCtlSend.sendDone(message_t* msg, error_t error) {} 
}
