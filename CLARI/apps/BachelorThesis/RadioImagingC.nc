#include <Timer.h>
#include "RadioImaging.h"
#include "Data.h"
#include "printf.h"

module RadioImagingC {
  uses interface Boot;
  uses interface SplitControl as AMControl;
  uses interface Receive as RadioImageReceive;
  uses interface Receive as BroadcastReceive;
  uses interface Receive as FlagReceive;
  uses interface Packet as Packet_;
  uses interface AMPacket;
  uses interface AMSend as RadioImageSend;
  uses interface AMSend as BroadcastSend;
  uses interface AMSend as FlagSend;
  uses interface AMSend as ScheduleSend;
	
  uses interface Timer<TMilli> as BroadcastTimer;
 
  uses interface Random;

  /*PC stuff*/
  uses interface SplitControl as SerialControl;
  uses interface AMSend as PCSend;
  uses interface Packet as PCPacket;
  uses interface PacketAcknowledgements as PacketAck;
  uses interface CC2420Packet as Rssi;
  uses interface Receive as CommandReceive;

  provides interface Receive as SamplerBroadcastReceive;
}
implementation {
  
  /*Notes: java net.tinyos.tools.PrintfClient -comm network@localhost:60001*/

  uint16_t source = 1;

  bool root_send_image = FALSE;
  bool running = FALSE;

  message_t ri_msg_queue[(NUMBER_OF_NODES/MAX_NODES_PER_MESSAGE) + ((NUMBER_OF_NODES%MAX_NODES_PER_MESSAGE == 0) ? 0 : 1)];
  uint8_t numberOfReceivedMsgs = 0;
  uint8_t numberOfSendMsgs = 0;


  void initializeNodeList() {
    uint8_t i;
    for(i = 0; i<NUMBER_OF_NODES+1; i++) {
      nodeList[i].msg_counter = 0;
      nodeList[i].last_rssi = 1;
      nodeList[i].inRange = FALSE;
      nodeList[i].nextHop = 0;
      nodeList[i].receivedImage = NUMBER_OF_NODES;
    }
  }

  void initializeSchedule() {
    uint8_t i;
    for(i = 0; i<NUMBER_OF_NODES*2; i++) 
      schedule[i] = 0;
  }

  void initializeHopInfo() {
    hopInfo.hopValue = NO_HOP_COUNT;
    hopInfo.nextHop = -1;
  }

  void nl_received_msg(uint16_t id, int8_t rssi, int8_t nHop) {
    // increase message counter for a specific node
    nodeList[id].msg_counter++;
    nodeList[id].last_rssi = rssi-45;
    nodeList[id].inRange = TRUE;
    nodeList[id].nextHop = nHop;
  }

  void nl_update() {
    // update neighbor list -> nodes from which messages were received are in range
    int i;	
    for(i = 0; i < NUMBER_OF_NODES+1; i++) {
      if(nodeList[i].msg_counter == 0)
        nodeList[i].inRange = FALSE;

      nodeList[i].msg_counter = 0; // reset message counter for all nodes
      nodeList[i].receivedImage = NUMBER_OF_NODES; //reset recivedImage for all nodes
    }

    //c_round++;
    sendNodes = 0;
  }

  event void Boot.booted() {
    call AMControl.start();
    call SerialControl.start();
  }

  event void AMControl.startDone(error_t err) {
    // initialise program if successfully started, else try again
    if (err == SUCCESS) {
      uint8_t i;
      for(i = 0; i < (NUMBER_OF_NODES/MAX_NODES_PER_MESSAGE) + ((NUMBER_OF_NODES%MAX_NODES_PER_MESSAGE == 0) ? 0 : 1); i++) {
      	call PacketAck.requestAck(&ri_msg_queue[i]);
      }
      call PacketAck.requestAck(&f_msg);
      call PacketAck.requestAck(&sd_msg);

      initializeNodeList();
      initializeSchedule();
      initializeHopInfo();

      if (TOS_NODE_ID == ROOT_NODE) {
        hopInfo.hopValue = 0;
        hopInfo.nextHop = 0;
	c_round++;		
      }
    }
    else {
      call AMControl.start();
    }
  }

  event void SerialControl.startDone(error_t err) {
    if (err == SUCCESS) {
    }
    else {
      call SerialControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
  }

  event void SerialControl.stopDone(error_t err) {
  }

  bool scheduleRunning = FALSE;
  event message_t* CommandReceive.receive(message_t* msg, void* payload, uint8_t len) {

    
    if(len == sizeof(CommandMsg)) {
      CommandMsg* cpkt = (CommandMsg*) payload;

      if(cpkt->_command == COMMAND_STARTCALIBRATION) {
        call BroadcastTimer.startPeriodic(TIME_BETWEEN_BRAODCASTS+((TOS_NODE_ID^2)%NUMBER_OF_NODES));
        running = TRUE;
      }
      else if(cpkt->_command == COMMAND_STARTSCHEDULE && !scheduleRunning) {
        BroadcastMsg* bpkt = (BroadcastMsg*) (call Packet_.getPayload(&brca_msg, sizeof(BroadcastMsg)));
        addHopInfoToBCMsg(bpkt, schedule[1]);
        //bpkt->receiver = schedule[1];


        phase = PHASE_SAMPLING;
        scheduleRunning = TRUE;

        if(bpkt != NULL && !brcaBusy)
          if (call BroadcastSend.send(AM_BROADCAST_ADDR, &brca_msg, sizeof(BroadcastMsg)) == SUCCESS)
            brcaBusy = TRUE;
      } else {
        _printf("Unknown command\n");
      }
    }

    return msg;
  }

  event message_t* BroadcastReceive.receive(message_t* msg, void* payload, uint8_t len) {
      
      if(len == sizeof(BroadcastMsg)) {
        int8_t rssi;
#ifdef LQI
        int8_t lqi;
#endif
        int8_t usedIndicator;
        
      BroadcastMsg* bpkt = (BroadcastMsg*) payload;
      int8_t tmp_hopValue;


      if(running == FALSE) {
        call BroadcastTimer.startPeriodic(TIME_BETWEEN_BRAODCASTS+((TOS_NODE_ID^2)%NUMBER_OF_NODES));
        running = TRUE;
      }

      
      source = call AMPacket.source(msg);
      rssi = call Rssi.getRssi(msg);
#ifdef LQI
      lqi = call Rssi.getLqi(msg);	
      usedIndicator = lqi;
#else
      usedIndicator = rssi;
#endif


      nl_received_msg(source, rssi, bpkt->nextHop);

      tmp_hopValue = bpkt->hopValue + computeIndicator(usedIndicator);
      if(bpkt->hopValue != NO_HOP_COUNT && (tmp_hopValue < hopInfo.hopValue || hopInfo.hopValue == NO_HOP_COUNT)) {
        hopInfo.nextHop	= source;	
        hopInfo.hopValue = tmp_hopValue;
      }
    }

      
    if(phase == PHASE_SAMPLING) {
      signal SamplerBroadcastReceive.receive(msg, payload, len);
    }
    
    return msg;
  }

  event void BroadcastSend.sendDone(message_t* msg, error_t err) {
    if(err == SUCCESS) {
      brcaBusy = FALSE;
    }
  }

  uint8_t notForwarded_img = 0;
  event message_t* RadioImageReceive.receive(message_t* msg, void* payload, uint8_t len) {
    if(len == sizeof(RadioImageMsg)) {
      uint8_t sour = call AMPacket.source(msg);
      RadioImageMsg* ripkt = (RadioImageMsg*) (call Packet_.getPayload(&ri_msg_queue[numberOfReceivedMsgs], sizeof(RadioImageMsg)));		
	
      _printf("req Image from: %d; rec from: %d; source: %d\n", requestedFrom, sour, ((RadioImageMsg*)payload)->from);
      if(requestedFrom == sour && ((RadioImageMsg*)payload)->request_round == c_round) {
	//_printf("image from: %d; msg motes left: %d; my motes left: %d\n", ripkt->from, ripkt->motesLeft, nodeList[ripkt->from].receivedImage);
	if( ((RadioImageMsg*)payload)->motesLeft >= nodeList[((RadioImageMsg*)payload)->from].receivedImage) {
		_printf("allreadyReceived!\n");
		
		return msg;
	}	

	memcpy(ripkt, payload, sizeof(RadioImageMsg));
	
        nodeList[ripkt->from].receivedImage = ripkt->motesLeft;
        numberOfReceivedMsgs++;
	
	if(nodeList[ripkt->from].receivedImage != 0)
		return msg;

	numberOfSendMsgs = 0;
	_printf("Got the whole image from %d over %d\n", ripkt->from, sour);
	
        if(TOS_NODE_ID == ROOT_NODE && !pcBusy) {
          //memcpy(&pc_msg, , sizeof(message_t));
	   _printf("img from %d send to pc\n", hopInfo.nextHop);
          if (call PCSend.send(AM_BROADCAST_ADDR, &ri_msg_queue[numberOfSendMsgs], sizeof(RadioImageMsg)) == SUCCESS) {
            pcBusy = TRUE;
          }
        }
        else if(!riBusy) {
	  _printf("forwarded to %d\n", hopInfo.nextHop);	
          if (call RadioImageSend.send(hopInfo.nextHop, &ri_msg_queue[numberOfSendMsgs], sizeof(RadioImageMsg)) == SUCCESS)
            riBusy = TRUE;
        } else if(riBusy) {
	  _printf("BUSY not forwarded to %d\n", hopInfo.nextHop);
	}
      }

    }
    return msg;
  }

  uint8_t retransmissions_img = 0;
  event void RadioImageSend.sendDone(message_t* msg, error_t err) {
    RadioImageMsg* ripkt = (RadioImageMsg*) (call Packet_.getPayload(msg, sizeof(RadioImageMsg)));
    uint8_t destination = call AMPacket.destination(msg);

    if(err == SUCCESS) 
      riBusy = FALSE;	

    retransmissions_img++;
    if (!call PacketAck.wasAcked(msg) && retransmissions_img < MAX_RETRANSMISSIONS && ripkt->request_round == c_round) {
      _printf("Retransmission IMG to %d\n", destination);
      if (call RadioImageSend.send(destination, &ri_msg_queue[numberOfSendMsgs], sizeof(RadioImageMsg)) == SUCCESS)
        riBusy = TRUE;	
    } else {
	if (call PacketAck.wasAcked(msg)){
        	_printf("Got Ack for IMG send to %d\n", destination);}
      	else{
        	_printf("Max rtx dropped IMG.\n");}
		
	retransmissions_img = 0;
	numberOfSendMsgs++;
	_printf("received Image msgs %d | send Image msgs: %d\n",numberOfReceivedMsgs, numberOfSendMsgs);
	if(numberOfSendMsgs != numberOfReceivedMsgs) {
		if (call RadioImageSend.send(destination, &ri_msg_queue[numberOfSendMsgs], sizeof(RadioImageMsg)) == SUCCESS)
       			riBusy = TRUE;
	} else {
		numberOfSendMsgs = 0;
		numberOfReceivedMsgs = 0;
	}	

	if(ripkt->motesLeft == 0 && ripkt->from == TOS_NODE_ID) {
		nl_update();
	}
    }

  }

  void fillImgQueue(void) {
	uint8_t motesLeft = NUMBER_OF_NODES;
	RadioImageMsg* ripkt = (RadioImageMsg*) (call Packet_.getPayload(&ri_msg_queue[0], sizeof(RadioImageMsg)));
	numberOfReceivedMsgs = 0;	

	for(numberOfReceivedMsgs = 0; motesLeft != 0; numberOfReceivedMsgs++) {
		ripkt = (RadioImageMsg*) (call Packet_.getPayload(&ri_msg_queue[numberOfReceivedMsgs], sizeof(RadioImageMsg)));		
		ripkt->motesLeft = fillRadioImageMsg(ripkt);		
		ripkt->from = TOS_NODE_ID;
		ripkt->request_round = c_round;		

		motesLeft = ripkt->motesLeft;				
	}

	numberOfSendMsgs = 0;	
  }

  void receivedRequest( void* payload, uint8_t len, uint8_t sour) {
    FlagMsg* fpkt = (FlagMsg*) (call Packet_.getPayload(&f_msg, sizeof(FlagMsg)));
    
    if(((FlagMsg*)payload)->round > c_round) {
      uint8_t next;
      c_round = ((FlagMsg*)payload)->round;

      next = getNextLeft();
      _printf("Received Request: next = %d\n", next);
      if(next > 0 && !fBusy) {
	memcpy(fpkt, payload, len);
        if (call FlagSend.send(next, &f_msg, sizeof(FlagMsg)) == SUCCESS)
          fBusy = TRUE;			
      } else if(!riBusy){
	fillImgQueue();	

	_printf("received Image msgs %d | send Image msgs: %d\n",numberOfReceivedMsgs, numberOfSendMsgs);
        //_printf("Send Image to: %d\n; left = %d", nextHop, ripkt->motesLeft);
        if (call RadioImageSend.send(hopInfo.nextHop, &ri_msg_queue[numberOfSendMsgs], sizeof(RadioImageMsg)) == SUCCESS)
          riBusy = TRUE;
      }

    }
  }

  /*TODO ROOT DOES NOT HANDLE THE NEW MULTIPLE MESSAGES JET*/

  event message_t* FlagReceive.receive(message_t* msg, void* payload, uint8_t len) {	
	
    _printf("Flag received\n");
    if(len == sizeof(FlagMsg) && call AMPacket.isForMe(msg)) {
      FlagMsg* fpkt = (FlagMsg*) payload;
      switch(fpkt->flag) {
      case FLAG_REQUEST:
        receivedRequest(payload, len, call AMPacket.source(msg));
        break;
      default:
        break;
      }
    }	
	
    return msg;
  }

  uint8_t retransmissions_flag = 0;
  
  event void FlagSend.sendDone(message_t* msg, error_t err) {
    FlagMsg* fpkt = (FlagMsg*) (call Packet_.getPayload(msg, sizeof(FlagMsg)));			
    uint8_t destination = call AMPacket.destination(msg);	
		
    if(err == SUCCESS) 
      fBusy = FALSE;
    
    requestedFrom = destination;
    retransmissions_flag++;
    if (!call PacketAck.wasAcked(msg) && retransmissions_flag < MAX_RETRANSMISSIONS && nodeList[destination].receivedImage == NUMBER_OF_NODES){
      _printf("Retransmission FLAG to %d\n", destination);
      if (call FlagSend.send(destination, &f_msg, sizeof(FlagMsg)) == SUCCESS)
        fBusy = TRUE;	
    } else {
      if (call PacketAck.wasAcked(msg)){
        _printf("Got Ack for FLAG send to %d\n", destination);}
      else{
        _printf("Max rtx dropped FLAG.\n");}
      
      retransmissions_flag = 0;
      if(fpkt->flag == FLAG_REQUEST) {
        _printf("Set reqfrom %u.\n", destination);
      }
    }
  }

  event void PCSend.sendDone(message_t* msg, error_t err) {	
    uint8_t next = 0;
    if(err == SUCCESS) 
      pcBusy = FALSE;
    else 
      return;

    //_printf("Request to you %d", next);

    numberOfSendMsgs++;
    if(numberOfSendMsgs != numberOfReceivedMsgs) {
	if (call PCSend.send(AM_BROADCAST_ADDR, &ri_msg_queue[numberOfSendMsgs], sizeof(RadioImageMsg)) == SUCCESS)
        	pcBusy = TRUE;
	return;
    } else {
	RadioImageMsg* ripkt = call Packet_.getPayload(msg, sizeof(RadioImageMsg));
	if(ripkt->from == ROOT_NODE && ripkt->motesLeft == 0)
		root_send_image = TRUE;		

	numberOfSendMsgs = 0;
	numberOfReceivedMsgs = 0;
    }

    next = getNextLeft();
    if(next > 0) {	
      FlagMsg* fpkt = (FlagMsg*) (call Packet_.getPayload(&f_msg, sizeof(FlagMsg)));
      fpkt->flag = FLAG_REQUEST;
      fpkt->round = ++c_round;
      _printf("Request to you %d\n", next);
      if (call FlagSend.send(next, &f_msg, sizeof(FlagMsg)) == SUCCESS)
        fBusy = TRUE;			
    } else if (!pcBusy && !root_send_image) {
      fillImgQueue();	

      if (call PCSend.send(AM_BROADCAST_ADDR, &ri_msg_queue[numberOfSendMsgs], sizeof(RadioImageMsg)) == SUCCESS)
        pcBusy = TRUE;
    } else if (root_send_image) {
      _printf("Root send its image\n");
      root_send_image = FALSE;
      nl_update();

      //_printf("collection round: %d\n", c_round);
	
      if(phase == PHASE_SAMPLING) {
        BroadcastMsg* bpkt = (BroadcastMsg*) (call Packet_.getPayload(&brca_msg, sizeof(BroadcastMsg)));
        addHopInfoToBCMsg(bpkt, schedule[1]);
        //bpkt->receiver = schedule[1];

        phase = PHASE_SAMPLING;

        if(bpkt != NULL && !brcaBusy)
          if (call BroadcastSend.send(AM_BROADCAST_ADDR, &brca_msg, sizeof(BroadcastMsg)) == SUCCESS)
            brcaBusy = TRUE;
      }
    }
  }
  
  event void ScheduleSend.sendDone(message_t* msg, error_t err) {
    /*if(err == SUCCESS) 
      sdBusy = FALSE;*/
  }

  event void BroadcastTimer.fired() {

  }
}
