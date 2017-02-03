#include <Timer.h>
#include "printf.h"
#include "RadioImaging.h"

module SamplerM {
	provides interface Sampler;

	uses interface Receive as SampleReceive;
	uses interface AMSend as SampleSend;
	uses interface AMPacket;
	uses interface Packet as Packet_;
	uses interface Alarm<TMilli, uint32_t> as DropTimer;
	uses interface CC2420Packet as Rssi;
	uses interface Leds;
	//uses interface Leds;
}
implementation {
	norace message_t s_msg;
	norace bool sBusy = FALSE;

	Node* nodeList;	
	uint8_t* schedule;	//The schedule is saved as an array of ids. The nodes send in the order they are listed in this array
	norace SchedulePSCollection schedulePSCollection;
	norace uint8_t psPointer = 0;	//contains the index of the next predecessor successor pair in the schedulePSCollection 

	uint8_t attachedNodeList = FALSE;
	uint8_t attachedSchedule = FALSE;

	norace uint8_t sourceInCaseOfDrop = 0;
	
	/*This methode evaluates the node i have to send to now. before is the node that send me the message, next is the one now in turn
	In theory it should not be possible to reach the return 0. But it happen that this methode returns 0 when the round is finished 
	(when the root received the last message and calls this methode)*/
	uint8_t getNextInSchedule(uint8_t before) {	
		/*uint8_t i;	
		for(i = 0; i<NUMBER_OF_NODES*2; i++) {
			if(schedule[i] == before && schedule[i+1] == next) {
				return schedule[i+2];
			}
		}*/
		//_printf("get next after: %d\n", before);
		if(schedulePSCollection.preSuc[psPointer].predecessor == before) {
			uint8_t next = schedulePSCollection.preSuc[psPointer].successor;
			psPointer++;
			psPointer = psPointer % schedulePSCollection.size;
			return next;
		} else {
			uint8_t i;
			for(i = 0; i<schedulePSCollection.size; i++) {
				if(schedulePSCollection.preSuc[i].predecessor == before) {
					uint8_t next = schedulePSCollection.preSuc[i].successor;
					psPointer = (i + 1) % schedulePSCollection.size;
					return next;
				}	
			}
		}
		return NUMBER_OF_NODES + 1;
	}

	void receivedSample(uint8_t id, int8_t rssi) {
		nodeList[id].msg_counter++;
    		nodeList[id].last_rssi = rssi-45;
   	 	nodeList[id].inRange = TRUE;
	}

	/*This methode evaluates the amount of nodes that send a message before me. Source is the source of a received message, receiver is the receiver of that message. 
	It returns 0 if the node does not appear in the schedule anymore (e.g. when it already send a message).
	As an example if node 1 send a message to node 2 and node 5 receives that message 5 will call this methode. Source will now be 1 and reveiver 2. If know 2, 3 and 4 need 
	to send a message before 5 this method should return 3 (This methode is somewhat complex since you have to take into account that a node could appear multiple times 
	inside the schedule)*/
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

			if(schedule[i] == 0) {
				
				return 0;
			}

		}
		

		return 0;
	}

	void sendSample() {
		if(!sBusy)
			if (call SampleSend.send(AM_BROADCAST_ADDR, &s_msg, sizeof(SampleMsg)) == SUCCESS)
				sBusy = TRUE;
	}

	void sendMessageAccordingToSchedule(uint8_t source) {
		uint8_t next = getNextInSchedule(source);
		

		//_printf("Send To = %d\n", next);

		if(next > 0 && next < NUMBER_OF_NODES + 1) {
			SampleMsg* spkt = (SampleMsg*) (call Packet_.getPayload(&s_msg, sizeof(SampleMsg)));
			spkt->receiver = next;


			sendSample();
		} else if (next == 0) {
			call Leds.led0Off();
			signal Sampler.finishedRound();
		} else {
			call Leds.led1On();
		}
	}

	/*void post_sendMessageAccordingToSchedule(uint8_t source) {
		
		if(isEvaluating == FALSE) {
			isEvaluating  = TRUE;
			previousNode = source;
			post sendMessageAccordingToSchedule();
		}
	}*/

	void definePredecessorSuccessor() {
		uint8_t i;
		schedulePSCollection.size = 0;		
		for(i = 0; i<NUMBER_OF_NODES*2; i++) {
			if(schedule[i] == TOS_NODE_ID) {
				schedulePSCollection.preSuc[schedulePSCollection.size].predecessor = (i == 0) ? 0 : schedule[i-1];
				schedulePSCollection.preSuc[schedulePSCollection.size].successor = schedule[i+1];
				//printf("SCHEDULE %d: %d -> %d -> %d\n",schedulePSCollection.size, schedulePSCollection.preSuc[schedulePSCollection.size].predecessor, TOS_NODE_ID, 
					//schedulePSCollection.preSuc[schedulePSCollection.size].successor);				
				schedulePSCollection.size++;
			}

			if(schedule[i] == 0)
				break;
		}
	}

	command void Sampler.attacheNodeList(Node* nl) {
		nodeList = nl;
		attachedNodeList = TRUE;
	}

	command void Sampler.attacheSchedule(uint8_t* sd) {		
		schedule = sd;
		definePredecessorSuccessor();
		attachedSchedule = TRUE;
	}

	command void Sampler.startRound() {
		_printf("START round\n");
		call Leds.led0On();
		sendMessageAccordingToSchedule(0);
		/*SampleMsg* spkt = (SampleMsg*) (call Packet_.getPayload(&s_msg, sizeof(SampleMsg)));
		spkt->receiver = schedule[1];

		if(spkt != NULL && !sBusy)
			if (call SampleSend.send(AM_BROADCAST_ADDR, &s_msg, sizeof(BroadcastMsg)) == SUCCESS)
				sBusy = TRUE;*/
	}

	event message_t* SampleReceive.receive(message_t* msg, void* payload, uint8_t len) {
		SampleMsg* bcpkt = (SampleMsg*) payload;
		uint8_t source = call AMPacket.source(msg);
		int8_t rssi = call Rssi.getRssi(msg);		

		receivedSample(source,rssi);

		call DropTimer.stop();	
		if(bcpkt->receiver == TOS_NODE_ID) {
			call Leds.led0On();
			sendMessageAccordingToSchedule(source);
		} else {
			uint8_t hopps;
			//call Leds.led0On();
			hopps = getNodeCountUntilMe(source, bcpkt->receiver);
			//call Leds.led0Off();
			//_printf("rec: %d->%d: %d until me\n", source, bcpkt->receiver, hopps);
			if(hopps != 0) {
				uint16_t timeToWait = hopps * TIME_MAX_MESSAGE_SENDING;
				//_printf("Time to wait: %d\n", timeToWait);
				call DropTimer.start(timeToWait);
			}
		
		}

		return msg;
	}

	event void SampleSend.sendDone(message_t* msg, error_t err) {
		SampleMsg* spkt = (SampleMsg*) (call Packet_.getPayload(msg, sizeof(SampleMsg)));
		uint8_t hopps = getNodeCountUntilMe(TOS_NODE_ID, spkt->receiver);
		
		call Leds.led0Off();

		if(err == SUCCESS)
			sBusy = FALSE;

		//_printf("sen: %d->%d: %d until me\n", TOS_NODE_ID, spkt->receiver, hopps);
		if(hopps != 0) {
			uint16_t timeToWait = hopps * TIME_MAX_MESSAGE_SENDING;
			//_printf("Time to wait: %d\n", timeToWait);
			call DropTimer.start(timeToWait);
		}
	}

	async event void DropTimer.fired() {
		call Leds.led0On();
		sendMessageAccordingToSchedule(sourceInCaseOfDrop);
	}
}
