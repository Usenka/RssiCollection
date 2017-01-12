#include <Timer.h>
#include "printf.h"
#include "RadioImaging.h"

module SamplerM {
	provides interface Sampler;

	uses interface Receive as SampleReceive;
	uses interface AMSend as SampleSend;
	uses interface AMPacket;
	uses interface Packet as Packet_;
	uses interface Timer<TMilli> as DropTimer;
	uses interface CC2420Packet as Rssi;
	//uses interface Leds;
}
implementation {
	message_t s_msg;
	bool sBusy = FALSE;

	Node* nodeList;
	uint8_t* schedule;

	uint8_t attachedNodeList = FALSE;
	uint8_t attachedSchedule = FALSE;

	uint8_t sourceInCaseOfDrop = 0;
	
	uint8_t getNextInSchedule(uint8_t before, uint8_t next) {	
		uint8_t i;	
		for(i = 0; i<NUMBER_OF_NODES*2; i++) {
			if(schedule[i] == before && schedule[i+1] == next) {
				return schedule[i+2];
			}
		}
		return 0;
	}

	void receivedSample(uint8_t id, int8_t rssi) {
		nodeList[id].msg_counter++;
    		nodeList[id].last_rssi = rssi-45;
   	 	nodeList[id].inRange = TRUE;
	}

	uint8_t getNodeCountUntilMe(uint8_t source, uint8_t receiver) {
		uint8_t i;	
		bool counting = FALSE;
		uint8_t counter = 0;
		/*if(TOS_NODE_ID == 2)      
			printf("START getNodeCountUntilMe\n");*/
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
				/*if(TOS_NODE_ID == 2)      
					printf("END getNodeCountUntilMe\n");*/
				return counter;
			}

			if(schedule[i] == 0) {
				/*if(TOS_NODE_ID == 2)      
					printf("END getNodeCountUntilMe\n");*/
				return 0;
			}

		}
		/*if(TOS_NODE_ID == 2)      
			printf("END getNodeCountUntilMe\n");*/

		return 0;
	}

	void sendMessageAccordingToSchedule(uint8_t source) {
		uint8_t next = getNextInSchedule(source, TOS_NODE_ID);

		_printf("Send To = %d\n", next);

		if(next > 0) {
			SampleMsg* spkt = (SampleMsg*) (call Packet_.getPayload(&s_msg, sizeof(SampleMsg)));
			//addHopInfoToBCMsg(spkt, next);
			spkt->receiver = next;

			//printf("broadcastTimer: bs: %d\n", sendBroadcasts);

			if(spkt != NULL && !sBusy)
				if (call SampleSend.send(AM_BROADCAST_ADDR, &s_msg, sizeof(SampleMsg)) == SUCCESS)
					sBusy = TRUE;
		} else {
			signal Sampler.finishedRound();
		}
	}

	command void Sampler.attacheNodeList(Node* nl) {
		nodeList = nl;
		attachedNodeList = TRUE;
	}

	command void Sampler.attacheSchedule(uint8_t* sd) {
		schedule = sd;
		attachedSchedule = TRUE;
	}

	command void Sampler.startRound() {
		SampleMsg* spkt = (SampleMsg*) (call Packet_.getPayload(&s_msg, sizeof(SampleMsg)));
		spkt->receiver = schedule[1];

		if(spkt != NULL && !sBusy)
			if (call SampleSend.send(AM_BROADCAST_ADDR, &s_msg, sizeof(BroadcastMsg)) == SUCCESS)
				sBusy = TRUE;
	}

	event message_t* SampleReceive.receive(message_t* msg, void* payload, uint8_t len) {
		SampleMsg* bcpkt = (SampleMsg*) payload;
		uint8_t source = call AMPacket.source(msg);
		int8_t rssi = call Rssi.getRssi(msg);		

		receivedSample(source,rssi);

		call DropTimer.stop();	
		if(bcpkt->receiver == TOS_NODE_ID) {
			sendMessageAccordingToSchedule(source);
		} else {
			uint8_t hopps;
			//call Leds.led0On();
			hopps = getNodeCountUntilMe(source, bcpkt->receiver);
			//call Leds.led0Off();
			_printf("rec: %d->%d: %d until me\n", source, bcpkt->receiver, hopps);
			if(hopps != 0) {
				uint16_t timeToWait = (hopps + 1) * TIME_MAX_MESSAGE_SENDING;
				_printf("Time to wait: %d\n", timeToWait);
				call DropTimer.startOneShot(timeToWait);
			}
		
		}

		return msg;
	}

	event void SampleSend.sendDone(message_t* msg, error_t err) {
		SampleMsg* spkt = (SampleMsg*) (call Packet_.getPayload(msg, sizeof(SampleMsg)));
		uint8_t hopps = getNodeCountUntilMe(TOS_NODE_ID, spkt->receiver);
		
		if(err == SUCCESS)
			sBusy = FALSE;

		//uint8_t next = getNextInSchedule(TOS_NODE_ID, spkt->receiver);
		_printf("sen: %d->%d: %d until me\n", TOS_NODE_ID, spkt->receiver, hopps);
		if(hopps != 0) {
			uint16_t timeToWait = (hopps + 1) * TIME_MAX_MESSAGE_SENDING;
			_printf("Time to wait: %d\n", timeToWait);
			call DropTimer.startOneShot(timeToWait);
		}
	}

	event void DropTimer.fired() {
		_printf("DropTimer Fired...\n");
		sendMessageAccordingToSchedule(sourceInCaseOfDrop);
	}
}
