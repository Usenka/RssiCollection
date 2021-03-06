#include <Timer.h>
#include "RadioImaging.h"
#include "Data.h"
#include "printf.h"

module CalibratorC {
  uses interface Receive as ScheduleReceive;
  uses interface AMSend as ScheduleSend;
  uses interface AMSend as FlagSend;
  uses interface AMSend as BroadcastSend;
  uses interface AMSend as PCScheduleSend;
  uses interface Receive as PCScheduleReceive;
  uses interface Timer<TMilli> as BroadcastTimer;	//Schedules the calibration broadcasts
  uses interface Timer<TMilli> as BreakTimer;		//The ROOT_MOTE should take a small break when he finnished sending it calibration broadcasts before requesting the Images.
  uses interface Packet as Packet_;
  uses interface AMPacket;
  uses interface PacketAcknowledgements as PacketAck;

}
implementation {

  uint16_t sendBroadcasts = 0;

  /*void printInRange() {
	int i;
	for(i = 1; i<NUMBER_OF_NODES+1;i++) {
		if(nodeList[i].inRange)
	}
  } */ 



  event void BroadcastTimer.fired() {
	if(!brcaBusy) {
		BroadcastMsg* bpkt = (BroadcastMsg*) (call Packet_.getPayload(&brca_msg, sizeof(BroadcastMsg)));
		addHopInfoToBCMsg(bpkt, 0);
		
		//_printf("Broadcast: %d %d\n", bpkt->hopValue, bpkt->nextHop);

		if(bpkt != NULL && !brcaBusy)
			if (call BroadcastSend.send(AM_BROADCAST_ADDR, &brca_msg, sizeof(BroadcastMsg)) == SUCCESS)
				brcaBusy = TRUE;
	}
  }

  event void BreakTimer.fired() {
	uint8_t next = getNextLeft();
	
	if(next > 0) {
		FlagMsg* fpkt = (FlagMsg*) (call Packet_.getPayload(&f_msg, sizeof(FlagMsg)));
		fpkt->flag = FLAG_REQUEST;			
		fpkt->round = ++c_round;		

		if (call FlagSend.send(next, &f_msg, sizeof(FlagMsg)) == SUCCESS)
			fBusy = TRUE;		
	/*}  else if (!pcBusy) {*/
		/*TODO SEND OWN TO PC, this case should never happen so it's not realy neccassary...*/
	}
	
  }	

   event message_t* PCScheduleReceive.receive(message_t* msg, void* payload, uint8_t len) {
	if(len == sizeof(ScheduleMsg)) {
		ScheduleMsg* spkt = (ScheduleMsg*) call Packet_.getPayload(&sd_msg, sizeof(ScheduleMsg));		
		uint8_t next;
		memcpy(spkt, payload, len);

		/*receivedSchedule(spkt->schedule);
		scheduleLeft = spkt->left;*/

		if(spkt->left < scheduleLeft) {
			uint8_t i;
			for(i = 0; i< NUMBER_OF_NODES+1; i++) {
				nodeList[i].receivedSchedule = FALSE;
			}		
			
			scheduleLeft = spkt->left;
			receivedSchedule(spkt->schedule);
		}

		next = getNextLeftSchedule();
		if (call ScheduleSend.send(next, &sd_msg, sizeof(ScheduleMsg)) == SUCCESS)
			sdBusy = TRUE;
	}

	return msg;
  }

  uint8_t notForwarded = 0;
  event message_t* ScheduleReceive.receive(message_t* msg, void* payload, uint8_t len) {
	uint8_t next;
	uint8_t from = call AMPacket.source(msg);
	ScheduleMsg* spkt = (ScheduleMsg*) call Packet_.getPayload(&sd_msg, sizeof(ScheduleMsg));

	_printf("received from: %d\n",from);

	/*TODO if an ack did not get received but the node still sends the schedule back the other node resends the part and will trigger that the node already got the part but won't forward it anymore to the 		next one strange stuff*/

	if(((ScheduleMsg*)payload)->left < scheduleLeft) {
		uint8_t i;
		for(i = 0; i< NUMBER_OF_NODES+1; i++) {
			nodeList[i].receivedSchedule = FALSE;
		}		
				
		scheduleLeft = ((ScheduleMsg*)payload)->left;
		receivedSchedule(((ScheduleMsg*)payload)->schedule);
	}

	if(nodeList[from].receivedSchedule == TRUE) {
		_printf("Already received that schedulepart from that node\n");
		return msg;
	}

	memcpy(spkt, payload, len);
	nodeList[from].receivedSchedule = TRUE;
	
	next = getNextLeftSchedule();
	if(next > 0 && sdBusy == FALSE) {
		_printf("Forward to: %d\n",next);
		if (call ScheduleSend.send(next, &sd_msg, sizeof(ScheduleMsg)) == SUCCESS)
			sdBusy = TRUE;
		notForwarded = 0;
	}  else if(sdBusy == TRUE){
		notForwarded = 1;
		//_printf("Something went horribly wrong dude...\n");
	} else if(pcBusy == FALSE){
		ScheduleMsg* spcpkt = (ScheduleMsg*) call Packet_.getPayload(&pc_msg, sizeof(ScheduleMsg));
		memcpy(spcpkt, spkt, len);
	
		if (call PCScheduleSend.send(next, &pc_msg, sizeof(ScheduleMsg)) == SUCCESS)
			pcBusy = TRUE;
	}

	if(scheduleLeft == 0)
		phase = PHASE_SAMPLING;

	return msg;
  }
   
  uint8_t retransmissions_sd = 0;
  event void ScheduleSend.sendDone(message_t* msg, error_t err) {	
	uint8_t destination = call AMPacket.destination(msg);		

	if(err == SUCCESS) 
	        sdBusy = FALSE;

	retransmissions_sd++;
	if (!nodeList[destination].receivedSchedule && !call PacketAck.wasAcked(msg) && retransmissions_sd < MAX_RETRANSMISSIONS) {	
		_printf("Retransmission to %d\n", destination);
		if (call ScheduleSend.send(destination, &sd_msg, sizeof(ScheduleMsg)) == SUCCESS)
			sdBusy = TRUE;	
	} else {
		if (call PacketAck.wasAcked(msg)){
			_printf("Acked\n");
		}
		else if(nodeList[destination].receivedSchedule) {
			_printf("Not Acked but got back\n");
		}
		else{
			_printf("Max rtx dropped.\n");}
	
		if(notForwarded) {
			uint8_t next = getNextLeftSchedule();
			//_printf("Was not forwarded, do it now\n");
			if (call ScheduleSend.send(next, &sd_msg, sizeof(ScheduleMsg)) == SUCCESS)
				sdBusy = TRUE;
			notForwarded = 0;
		}

		retransmissions_sd = 0;
	}
  }

  event void FlagSend.sendDone(message_t* msg, error_t err) {
  }

  event void PCScheduleSend.sendDone(message_t* msg, error_t err) {
	if(err == SUCCESS) 
	        pcBusy = FALSE;
  }

  event void BroadcastSend.sendDone(message_t* msg, error_t err) {
	if(phase != PHASE_CALIBRATION)
		return;
	
	brcaBusy = FALSE;

	sendBroadcasts++;	


	if(sendBroadcasts >= BROADCAST_AMOUNT)  {
		call BroadcastTimer.stop();
		
		if(TOS_NODE_ID == ROOT_NODE) {
			call BreakTimer.startOneShot(TIME_TAKE_A_BREAK);
				
		}
	}
  }
}
