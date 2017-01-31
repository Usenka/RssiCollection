#include <Timer.h>
#include "RadioImaging.h"
#include "Data.h"
#include "printf.h"

module SamplerC {
  uses interface Receive as BroadcastReceive;
  uses interface AMSend as BroadcastSend;
  uses interface AMSend as FlagSend;
  uses interface AMPacket;
  uses interface Packet as Packet_;
  uses interface Timer<TMilli> as DropTimer;
}
implementation {
  uint8_t rounds = 0;

  uint8_t sourceInCaseOfDrop = 0;
  uint8_t getNodeCountUntilMe(uint8_t source, uint8_t receiver) {
	uint8_t i;	
	bool counting = FALSE;
	uint8_t counter = 0;
	for(i = 0; i<NUMBER_OF_NODES*2; i++) {
		if(schedule[i] == source && schedule[i+1] == receiver) {
			i++;
			counting = TRUE;
			continue;
		}

		if(counting == TRUE) {
			counter++;
		}
				
		if(schedule[i] == TOS_NODE_ID && counting == TRUE) {
			sourceInCaseOfDrop = schedule[i-1];
			return counter;
		}

		if(schedule[i] == 0)
			return 0;

	}
	return 0;
  }

  void sendMessageAccordingToSchedule(uint8_t source) {
	uint8_t next = getNextInSchedule(source, TOS_NODE_ID);

	_printf("Send To = %d\n", next);
	
	if(next > 0) {
		BroadcastMsg* bpkt = (BroadcastMsg*) (call Packet_.getPayload(&brca_msg, sizeof(BroadcastMsg)));
		addHopInfoToBCMsg(bpkt, next);
		//bpkt->receiver = next;

		//printf("broadcastTimer: bs: %d\n", sendBroadcasts);

		if(bpkt != NULL && !brcaBusy)
			if (call BroadcastSend.send(AM_BROADCAST_ADDR, &brca_msg, sizeof(BroadcastMsg)) == SUCCESS)
				brcaBusy = TRUE;
	} else {
		rounds++;
		if(rounds < ROUNDS_BEFORE_COLLECTION) {
			/*Next Round*/
		} 
		else {
			uint8_t flag_next = getNextLeft();
			FlagMsg* fpkt = (FlagMsg*) (call Packet_.getPayload(&f_msg, sizeof(FlagMsg)));
			
			fpkt->flag = FLAG_REQUEST;
			fpkt->round = ++c_round;

			if (call FlagSend.send(flag_next, &f_msg, sizeof(FlagMsg)) == SUCCESS)
				fBusy = TRUE;	
		}
	}
  }

  event message_t* BroadcastReceive.receive(message_t* msg, void* payload, uint8_t len) {
	BroadcastMsg* bcpkt = (BroadcastMsg*) payload;
	uint8_t source = call AMPacket.source(msg);
	call DropTimer.stop();	
	if(bcpkt->receiver == TOS_NODE_ID) {
		sendMessageAccordingToSchedule(source);
	} else {
		uint8_t hopps = getNodeCountUntilMe(source, bcpkt->receiver);
		_printf("rec: %d->%d: %d until me\n", source, bcpkt->receiver, hopps);
		if(hopps != 0)
			call DropTimer.startOneShot(hopps * TIME_MAX_MESSAGE_SENDING);	
	}

  	return msg;
  }

  event void BroadcastSend.sendDone(message_t* msg, error_t err) {
	if(phase == PHASE_SAMPLING) {
		BroadcastMsg* bpkt = (BroadcastMsg*) (call Packet_.getPayload(msg, sizeof(BroadcastMsg)));
		//uint8_t next = getNextInSchedule(TOS_NODE_ID, bpkt->receiver);
		uint8_t hopps = getNodeCountUntilMe(TOS_NODE_ID, bpkt->receiver);
		_printf("sen: %d->%d: %d until me\n", TOS_NODE_ID, bpkt->receiver, hopps);
		if(hopps != 0)
			call DropTimer.startOneShot((hopps + 1) * TIME_MAX_MESSAGE_SENDING);
  	}
  }

  event void FlagSend.sendDone(message_t* msg, error_t err) {
	
  }

  event void DropTimer.fired() {
	_printf("DropTimer Fired...\n");
	sendMessageAccordingToSchedule(sourceInCaseOfDrop);
  }
}
