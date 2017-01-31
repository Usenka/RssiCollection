#include <Timer.h>
#include "RxTxMonitoring.h"

module RxTxMonitoringC {
  uses {
    interface Boot;
    interface SplitControl as SerialControl;
    interface AMSend as SerialMonitoringSend;
    interface Timer<TMilli> as MonitoringTimer;
    interface Timer<TMilli> as RetxmitTimer;
    interface Pool<message_t> as MonitoringMessagePool;
    interface Queue<message_t*> as MonitoringSendQueue;
    interface Timer<TMilli> as NoiseSamplingTimer;
    interface Read<uint16_t> as Noise;
    interface RxTx as RxEvent;
    interface RxTx as TxEvent;
#ifdef RXTX_MONITORING_CORRUPTED
    interface RxTx as RxCorruptedEvent;
#endif
  }
}

implementation {

  // Logger variables
  bool serialBusy = FALSE;
  message_t log_Packet;
  uint16_t seq_num = 0;
  uint8_t retries = 0;
  
  task void monitoringSendTask() {
    if (serialBusy)
      return;
    else {
      if (call MonitoringSendQueue.empty())
        return;
      else {
        message_t* smsg = call MonitoringSendQueue.head();
        error_t eval = call SerialMonitoringSend.send(AM_BROADCAST_ADDR, smsg, sizeof(RxTxMonitoringMsg));
        if (eval == SUCCESS) {
          serialBusy = TRUE;
          return;
        }
        else {
          retries++;
          if (retries >= MAX_RXTXMONITORINGSERIAL_RETRIES){
            retries = 0;
            call MonitoringSendQueue.dequeue();
            call MonitoringMessagePool.put(smsg);
          }
          if (! call MonitoringSendQueue.empty())
            call RetxmitTimer.startOneShot(FAILED_RXTXMONITORINGSERIAL_BACKOFF);
        }
      }
    }
  }

  event void RetxmitTimer.fired(){
    if (! call MonitoringSendQueue.empty())
      post monitoringSendTask();
  }

  event void SerialMonitoringSend.sendDone(message_t *msg, error_t error) {
      message_t* qh = call MonitoringSendQueue.head();
      if (qh == NULL || qh != msg) {
        // something is wrong here
      } 
      else {
        retries++;
        if (retries >= MAX_RXTXMONITORINGSERIAL_RETRIES || error == SUCCESS){
          retries = 0;
          call MonitoringSendQueue.dequeue();
          call MonitoringMessagePool.put(msg);
        }
      }
      serialBusy = FALSE;
      if (error != SUCCESS){
        call RetxmitTimer.startOneShot(FAILED_RXTXMONITORINGSERIAL_BACKOFF);
      } else if (!call MonitoringSendQueue.empty()){ 
        post monitoringSendTask();
      }
  }


  
   /*
  * This function allocates a new empty message.
  * It checks if there is memory left in the pool and the queue is not exhausted
  */
  message_t* monitoringAllocNewMessage() {
    message_t* nmsg;
    RxTxMonitoringMsg* monitoring_msg;
    if (call MonitoringMessagePool.empty()) {
      return NULL;
    }
    nmsg = call MonitoringMessagePool.get();
    monitoring_msg = call SerialMonitoringSend.getPayload(nmsg, sizeof(RxTxMonitoringMsg));

    // Populate the new message with 0s for the case not all fields will be set
    if (monitoring_msg != NULL)
      memset(monitoring_msg, 0, sizeof(RxTxMonitoringMsg));
    else {
      return NULL;
    }
    return nmsg;
  }

  /* This function is called after the new message has been created 
  *  by the monitoringEvent() and it is ready to be sent over the serial.
  *  It checks if the send quene is not exhausted and posts logSendTask
  */
  void monitoringSendMessage(message_t* msg) {
    if (call MonitoringSendQueue.enqueue(msg) == SUCCESS) {
      post monitoringSendTask();
      return;
    } 
    else {
      call MonitoringMessagePool.put(msg);
      return;
    }
  }

  /*
  * Event handler helpers
  */

  RxTxMonitoringMsg* processing_msg;
  message_t* nmsg;
  bool sampling_noise = FALSE;


  void monitoringRxEvent(uint32_t etime, message_t *msg, uint8_t size, uint8_t rssi, uint8_t lqi) {
    seq_num++;
    nmsg = monitoringAllocNewMessage();
    if (nmsg == NULL)
      return;
    processing_msg = call SerialMonitoringSend.getPayload(nmsg, sizeof(RxTxMonitoringMsg));

    processing_msg->infos.type = RX_EVENT;
    processing_msg->infos.log_src = TOS_NODE_ID;
    processing_msg->infos.timestamp = etime;
    processing_msg->infos.seq_num = seq_num;
    processing_msg->infos.size_data = size;
    processing_msg->infos.valid_noise_samples = 0;
    processing_msg->infos.rssi = rssi;
    processing_msg->infos.lqi = lqi;
    //memcpy(processing_msg->infos.metadata, metadata, 2);
    memcpy(processing_msg->data, msg, size);

    sampling_noise = TRUE;
    call Noise.read();
  }


  void monitoringRxCorruptedEvent(uint32_t etime, message_t *msg, uint8_t size, uint8_t rssi, uint8_t lqi) {
    seq_num++;
    nmsg = monitoringAllocNewMessage();
    if (nmsg == NULL)
      return;
    processing_msg = call SerialMonitoringSend.getPayload(nmsg, sizeof(RxTxMonitoringMsg));

    processing_msg->infos.type = RX_CORRUPTED_EVENT;
    processing_msg->infos.log_src = TOS_NODE_ID;
    processing_msg->infos.timestamp = etime;
    processing_msg->infos.seq_num = seq_num;
    processing_msg->infos.size_data = size;
    processing_msg->infos.valid_noise_samples = 0;
    processing_msg->infos.rssi = rssi;
    processing_msg->infos.lqi = lqi;
    //memcpy(processing_msg->infos.metadata, metadata, 2);
    memcpy(processing_msg->data, msg, TOSH_DATA_LENGTH-sizeof(rxtx_infos));

    sampling_noise = TRUE;
    call Noise.read();
  }

  void monitoringTxEvent(uint32_t etime, message_t *msg, uint8_t size, uint8_t rssi, uint8_t lqi) {
    seq_num++;
    nmsg = monitoringAllocNewMessage();
    if (nmsg == NULL)
      return;
    processing_msg = call SerialMonitoringSend.getPayload(nmsg, sizeof(RxTxMonitoringMsg));

    processing_msg->infos.type = TX_EVENT;
    processing_msg->infos.log_src = TOS_NODE_ID;
    processing_msg->infos.timestamp = etime;
    processing_msg->infos.seq_num = seq_num;
    processing_msg->infos.size_data = size;
    processing_msg->infos.valid_noise_samples = 0;
    processing_msg->infos.rssi = rssi;
    processing_msg->infos.lqi = lqi;
    //memcpy(processing_msg->infos.metadata, metadata, 2);
    memcpy(processing_msg->data, msg, size);

    sampling_noise = TRUE;
    call Noise.read();
  }

  
  event void MonitoringTimer.fired() {}

  event void RxEvent.rxtx(message_t *msg, uint8_t size, uint8_t rssi, uint8_t lqi){
    if (sampling_noise){
      sampling_noise = FALSE;
      monitoringSendMessage(nmsg);
    }
    monitoringRxEvent(call MonitoringTimer.getNow(), msg, size, rssi, lqi);//, metadata);
  }

#ifdef RXTX_MONITORING_CORRUPTED
  event void RxCorruptedEvent.rxtx(message_t *msg, uint8_t size, uint8_t rssi, uint8_t lqi){
    if (sampling_noise){
      sampling_noise = FALSE;
      monitoringSendMessage(nmsg);
    }
    monitoringRxCorruptedEvent(call MonitoringTimer.getNow(), msg, size, rssi, lqi);//, metadata);
  }
#endif
  
  event void TxEvent.rxtx(message_t *msg, uint8_t size, uint8_t rssi, uint8_t lqi){
    if (sampling_noise){
      sampling_noise = FALSE;
      monitoringSendMessage(nmsg);
    }
    monitoringTxEvent(call MonitoringTimer.getNow(), msg, size, rssi, lqi);//, metadata);
  }

  event void NoiseSamplingTimer.fired(){}
  
  event void Noise.readDone(error_t result, uint16_t val){
    if (!sampling_noise)
      return;
    processing_msg->infos.noise[processing_msg->infos.valid_noise_samples++] = val;
    if (processing_msg->infos.valid_noise_samples > 2){
      sampling_noise = FALSE;
      monitoringSendMessage(nmsg);
    } else {
      call Noise.read();
    }
  }

  event void Boot.booted() {
    // Cleanup the LogSendQueue and LogMessagePool FIXME: is this needed?
    while (! call MonitoringSendQueue.empty()) {
      message_t* smsg = call MonitoringSendQueue.head();
      call MonitoringMessagePool.put(smsg);
      call MonitoringSendQueue.dequeue();
    }
    call SerialControl.start();
  }

  event void SerialControl.startDone(error_t err) {
    if (err != SUCCESS)
      call SerialControl.start();
  }
  
  event void SerialControl.stopDone(error_t err) {}
}
