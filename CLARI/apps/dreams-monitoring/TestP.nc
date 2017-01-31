#include "Test.h"

module TestP {
  uses {
    interface Boot;
    interface Alarm<TMilli, uint32_t> as TimerSend;
    interface Timer<TMilli> as TimerSerialRetxmit;
    interface Timer<TMilli> as TimerRadioRetxmit;
    interface TimeSyncAMSend<TMilli, uint32_t> as RadioSend;
    interface TimeSyncPacket<TMilli, uint32_t> as PacketTime;
    interface Receive as RadioReceive;
    interface AMSend as SerialSend;
    interface Receive as SerialReceive;
    interface Packet as SerialPacket;
    interface CC2420Packet;
    interface RadioBackoff;
    interface PacketAcknowledgements;
    interface AMPacket;
    interface SplitControl as RadioControl;
    interface SplitControl as SerialControl;
    interface CC2420Config;
    interface Leds;
#ifdef SENSOR_READINGS
    interface Read<uint16_t> as Temp;
    interface Read<uint16_t> as Hum;
    interface Read<uint16_t> as TotalSolar; 
    interface Read<uint16_t> as PhotoSynth;
    interface Read<uint16_t> as Battery;
#endif
    interface Read<uint16_t> as Noise;
    interface Pool<message_t> as SerialMessagePool;
    interface Queue<message_t*> as SerialSendQueue;
  }
}

implementation {

  test_msg_t received;
  norace test_msg_t to_send;
  uint8_t noise_sample;
  norace uint32_t firing_time;
  message_t radio_packet;
  uint8_t num_transmissions;

  bool serialBusy = FALSE;
  uint8_t s_retries = 0;

  task void send_radio();
  
  task void serialSendTask() {
    if (serialBusy)
      return;
    else {
      if (call SerialSendQueue.empty())
        return;
      else {
        message_t* smsg = call SerialSendQueue.head();
        error_t eval = call SerialSend.send(AM_BROADCAST_ADDR, smsg, sizeof(test_msg_t));
        if (eval == SUCCESS) {
          serialBusy = TRUE;
          return;
        }
        else {
          s_retries++;
          if (s_retries >= MAX_TESTSERIAL_RETRIES){
            s_retries = 0;
            call SerialSendQueue.dequeue();
            call SerialMessagePool.put(smsg);
          }
          if (! call SerialSendQueue.empty())
            call TimerSerialRetxmit.startOneShot(FAILED_TESTSERIAL_BACKOFF);
        }
      }
    }
  }

  event void TimerSerialRetxmit.fired(){
    if (! call SerialSendQueue.empty())
      post serialSendTask();
  }
  
  event void SerialSend.sendDone(message_t *msg, error_t error) {
      message_t* qh = call SerialSendQueue.head();
      if (qh == NULL || qh != msg) {
        // something is wrong here
      } 
      else {
        s_retries++;
        if (s_retries >= MAX_TESTSERIAL_RETRIES || error == SUCCESS){
          s_retries = 0;
          call SerialSendQueue.dequeue();
          call SerialMessagePool.put(msg);
        }
      }
      serialBusy = FALSE;
      if (error != SUCCESS){
        call TimerSerialRetxmit.startOneShot(FAILED_TESTSERIAL_BACKOFF);
      } else if (!call SerialSendQueue.empty()){
          post serialSendTask();
      }
  }
    
  /*
   * This function allocates a new empty message.
   * It checks if there is memory left in the pool and the queue is not exhausted
   */
  message_t* serialAllocNewMessage() {
    message_t* pmsg;
    test_msg_t* temp_msg;
    if (call SerialMessagePool.empty()) {
      return NULL;
    }
    pmsg = call SerialMessagePool.get();
    temp_msg = call SerialSend.getPayload(pmsg, sizeof(test_msg_t));
    
    // Populate the new message with 0s for the case not all fields will be set
    if (temp_msg != NULL)
      memset(temp_msg, 0, sizeof(test_msg_t));
    else {
      return NULL;
    }
    return pmsg;
  }
  
  /* This function is called after the new message has been created 
   *  by the monitoringEvent() and it is ready to be sent over the serial.
   *  It checks if the send quene is not exhausted and posts logSendTask
   */
  void serialSendMessage(message_t* msg) {
    if (call SerialSendQueue.enqueue(msg) == SUCCESS) {
      post serialSendTask();
      return;
    } 
    else {
      call SerialMessagePool.put(msg);
      return;
    }
  }

  test_msg_t *processing_msg;
  message_t *nmsg;

  event void Boot.booted(){
    while (! call SerialSendQueue.empty()) {
      message_t* smsg = call SerialSendQueue.head();
      call SerialMessagePool.put(smsg);
      call SerialSendQueue.dequeue();
    }
    noise_sample = 0;
    to_send.type = SEND;
    to_send.seq_num = 0;
    to_send.sender = TOS_NODE_ID;
    to_send.receiver = AM_BROADCAST_ADDR;
    to_send.rssi = INVALID;
    to_send.lqi = INVALID;
    to_send.noise1 = INVALID;
    to_send.noise2 = INVALID;
    to_send.noise3 = INVALID;
    to_send.temp = INVALID;
    to_send.hum = INVALID;
    to_send.sol = INVALID;
    to_send.synth = INVALID;
    to_send.batt = INVALID;
    to_send.diff_time = INVALID;
    to_send.channel = CC2420_DEF_CHANNEL;
    to_send.power = CC2420_DEF_RFPOWER;
    to_send.error = INVALID;
    call RadioControl.start();
    call SerialControl.start();
#ifndef SERIAL_CONTROLLER
    if (TOS_NODE_ID == INITIATOR_NODE){
      call TimerSend.start(STEP_INTERVAL * NUM_NODES);
    }
#endif
  }

  event void RadioControl.startDone(error_t error){
    if (error != SUCCESS)
      call RadioControl.start();
  }

  event void RadioControl.stopDone(error_t error){}

  event void SerialControl.startDone(error_t error){
    if (error != SUCCESS)
        call SerialControl.start();
  }

  event void SerialControl.stopDone(error_t error){}

  async event void RadioBackoff.requestCca(message_t *msg){
    call RadioBackoff.setCca(FALSE);
  }

  async event void RadioBackoff.requestCongestionBackoff(message_t *msg){
    call RadioBackoff.setCongestionBackoff(0);
  }

  async event void RadioBackoff.requestInitialBackoff(message_t *msg){
    call RadioBackoff.setInitialBackoff(0);
  }

  event void RadioSend.sendDone(message_t* msg,
                                error_t error){
    atomic to_send.error = error;
    nmsg = serialAllocNewMessage();
    if (nmsg == NULL){
      return;
    }
    processing_msg = call SerialSend.getPayload(nmsg, sizeof(test_msg_t));
    memcpy(processing_msg, &to_send, sizeof(test_msg_t));
    noise_sample = 1;
    call Noise.read();
  }


  event message_t* RadioReceive.receive(message_t *msg,
                                        void * payload,
                                        uint8_t len){
    if (len == sizeof(test_msg_t)){
      uint32_t sending_time = 0;
      received = *((test_msg_t *)payload);
      received.type = RECEIVE;
      received.receiver = TOS_NODE_ID;
      received.rssi = call CC2420Packet.getRssi(msg);
      received.lqi = call CC2420Packet.getLqi(msg);
      if (call PacketTime.isValid(msg) &&
          call TimerSend.getNow() > sending_time){
        sending_time = call TimerSend.getNow() -
          call PacketTime.eventTime(msg);
      }
#ifndef SERIAL_CONTROLLER
      if (TOS_NODE_ID > received.sender){
        to_send.seq_num = received.seq_num - 1;
        call TimerSend.start((TOS_NODE_ID - received.sender) *
                             STEP_INTERVAL - sending_time);
      } else {
        atomic to_send.seq_num = received.seq_num;
        call TimerSend.start((NUM_NODES + TOS_NODE_ID -
			      received.sender) *
                             STEP_INTERVAL - sending_time);
      }
#endif
      received.diff_time = sending_time;
      received.error = INVALID;
      nmsg = serialAllocNewMessage();
      if (nmsg == NULL){
        return msg;
      }
      processing_msg = call SerialSend.getPayload(nmsg, sizeof(test_msg_t));
      memcpy(processing_msg, &received, sizeof(test_msg_t));
      noise_sample = 1;
      call Noise.read();
    }
    return msg;
  }

  event message_t* SerialReceive.receive(message_t *msg,
                                        void * payload,
                                        uint8_t len){
#ifdef SERIAL_CONTROLLER
    if (len == sizeof(test_msg_t)){
      uint16_t cmd_seq_num = ((test_msg_t *)payload)->seq_num;
      if (cmd_seq_num <= to_send.seq_num &&
          cmd_seq_num > STARTUP_SEQ_NUM_WINDOW){
        return msg;
      }
      firing_time = call TimerSend.getNow();
      to_send.type = SEND;
      to_send.seq_num = ((test_msg_t *)payload)->seq_num;
      to_send.channel = ((test_msg_t *)payload)->channel;
      to_send.power = ((test_msg_t *)payload)->power;
      to_send.sender = TOS_NODE_ID;
      to_send.receiver = AM_BROADCAST_ADDR;
      to_send.rssi = INVALID;
      to_send.lqi = INVALID;
      to_send.noise1 = INVALID;
      to_send.noise2 = INVALID;
      to_send.noise3 = INVALID;
      to_send.temp = INVALID;
      to_send.hum = INVALID;
      to_send.sol = INVALID;
      to_send.synth =  INVALID;
      to_send.batt = INVALID;
      to_send.diff_time = INVALID;
      to_send.error = INVALID;
      num_transmissions = 0;
      if (to_send.channel != call CC2420Config.getChannel()){
        call CC2420Config.setChannel(to_send.channel);
      } else {
        post send_radio();
      }
    }
#endif
    return msg;
  }

  void createAndSendMsg(){
    firing_time = call TimerSend.getNow();
    to_send.seq_num++;
    to_send.sender = TOS_NODE_ID;
    to_send.receiver = AM_BROADCAST_ADDR;
    to_send.rssi = INVALID;
    to_send.lqi = INVALID;
    to_send.noise1 = INVALID;
    to_send.noise2 = INVALID;
    to_send.noise3 = INVALID;
    to_send.temp = INVALID;
    to_send.hum = INVALID;
    to_send.sol = INVALID;
    to_send.synth =  INVALID;
    to_send.batt = INVALID;
    to_send.diff_time = INVALID;
    to_send.error = INVALID;
    post send_radio();
  }

  event void TimerRadioRetxmit.fired(){
    createAndSendMsg();
  }
  
  async event void TimerSend.fired(){
    createAndSendMsg();
    call TimerSend.start(NUM_NODES * STEP_INTERVAL);
  }


  event void Noise.readDone(error_t result, uint16_t val){
    if (result != SUCCESS)
      val += 0xF000;
    switch (noise_sample){
    case 1:
      processing_msg->noise1 = val;
      noise_sample = 2;
      call Noise.read();
      break;
    case 2:
      processing_msg->noise2 = val;
      noise_sample = 3;
      call Noise.read();
      break;
    case 3:
      processing_msg->noise3 = val;
      noise_sample = 0;
      if (processing_msg->type == SEND){
        num_transmissions++;
        if (num_transmissions < NUM_TRANSMISSIONS){
          processing_msg->diff_time = call TimerSend.getNow() - firing_time;
          serialSendMessage(nmsg);
          call TimerRadioRetxmit.startOneShot(STEP_IMI);
        }  else {
#ifdef SENSOR_READINGS
          call Temp.read();
#else
          processing_msg->diff_time = call TimerSend.getNow() - firing_time;
          serialSendMessage(nmsg);
#endif
        }

      } else {
        serialSendMessage(nmsg);
      }
      break;
    }
  }


#ifdef SENSOR_READINGS
  event void Temp.readDone(error_t result, uint16_t val){
    if (result != SUCCESS)
      val += 0xF000;
    processing_msg->temp = val;
    call Hum.read();
  }

  event void Hum.readDone(error_t result, uint16_t val){
    if (result != SUCCESS)
      val += 0xF000;
    processing_msg->hum = val;
    call TotalSolar.read();
  }
  
  event void TotalSolar.readDone(error_t result, uint16_t val){
    if (result != SUCCESS)
      val += 0xF000;
    processing_msg->sol = val;
    call PhotoSynth.read();
  }
  
  event void PhotoSynth.readDone(error_t result, uint16_t val){
    if (result != SUCCESS)
      val += 0xF000;
    processing_msg->synth = val;
    call Battery.read();
  }
  
  event void Battery.readDone(error_t result, uint16_t val){
    if (result != SUCCESS)
      val += 0xF000;
    processing_msg->batt = val;
    processing_msg->diff_time = call TimerSend.getNow() - firing_time;
    serialSendMessage(nmsg);
  }
#endif

  task void send_radio(){
    error_t error;
    test_msg_t *tmsg = (test_msg_t *) call RadioSend.getPayload(&radio_packet,
                                                        sizeof(test_msg_t));
    memcpy(tmsg, &to_send, sizeof(test_msg_t));
    call CC2420Packet.setPower(&radio_packet, to_send.power);
    call PacketAcknowledgements.noAck(&radio_packet);

    error = call RadioSend.send(AM_BROADCAST_ADDR, &radio_packet, 
                                sizeof(test_msg_t),
                                firing_time);
    if (error != SUCCESS){
          atomic to_send.error = error;
          nmsg = serialAllocNewMessage();
          if (nmsg == NULL){
            return;
          }
          processing_msg = call SerialSend.getPayload(nmsg, sizeof(test_msg_t));
          memcpy(processing_msg, &to_send, sizeof(test_msg_t));
          noise_sample = 1;
          call Noise.read();
    }
  }

  event void CC2420Config.syncDone(error_t error) { 
    if (to_send.type == SEND){
      post send_radio();
    }
  } 


}

