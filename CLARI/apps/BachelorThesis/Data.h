#ifndef DATA_H
#define DATA_H 

//#define LQI

#include "RadioImaging.h"
#include <message.h>
#include "printf.h"

typedef struct Node {
  uint16_t msg_counter;
  int8_t last_rssi;
  int8_t inRange;
  uint8_t nextHop;
  int8_t receivedImage;
  int8_t receivedSchedule;
} Node;

uint8_t phase = PHASE_CALIBRATION;
uint8_t c_round = 0;
uint8_t recived_request = 0;

//message_t ri_msg;
message_t pc_msg;
message_t brca_msg;
message_t f_msg;
message_t sd_msg;

bool sdBusy = FALSE;
bool pcBusy = FALSE;
bool riBusy = FALSE;
bool brcaBusy = FALSE;
bool fBusy = FALSE;

uint8_t requestedFrom = 0;
uint8_t processingRequest = 0;
/*typedef nx_struct HopInfo {
	nx_int8_t hopCount;
  	nx_uint8_t nextHop;
  	nx_int8_t goodness;
  	nx_uint8_t receiver;	
} HopInfo;*/

BroadcastMsg hopInfo;// = {NO_HOP_COUNT, -1, 0};


Node nodeList[NUMBER_OF_NODES+1];
uint8_t schedule[NUMBER_OF_NODES*2];

uint8_t sendNodes = 0;
uint8_t scheduleFilled = 0;
uint8_t scheduleLeft = -1;

/*This is for collecting the rssitables*/
uint8_t getNextLeft() {
	uint8_t i;
	for(i = 1; i<NUMBER_OF_NODES+1; i++) {
		if(nodeList[i].nextHop == TOS_NODE_ID && nodeList[i].receivedImage) {
			return i;
		}
	}
	return 0;
}  

/*This is for spreading the schedule (Does basically the same...)*/
uint8_t getNextLeftSchedule() {
	uint8_t i;
	for(i = 1; i<NUMBER_OF_NODES+1; i++) {
		if(nodeList[i].nextHop == TOS_NODE_ID && !nodeList[i].receivedSchedule) {
			return i;
		}
	}
	return hopInfo.nextHop;
} 

/*This gives the next to send messages according to the schedule*/
uint8_t getNextInSchedule(uint8_t before, uint8_t next) {
	uint8_t i;	
	for(i = 0; i<NUMBER_OF_NODES*2; i++) {
		if(schedule[i] == before && schedule[i+1] == next) {
			return schedule[i+2];
		}
	}
	return 0;
}

uint8_t fillRadioImageMsg(RadioImageMsg* radioImageMsg) {
	uint8_t msgIndex = 0;	
	uint8_t nodeCounter = 0;
  	uint8_t i_;
	for(i_ = 1; i_<NUMBER_OF_NODES+1; i_++) {
		if(nodeList[i_].inRange) {
			nodeCounter++;
			if(nodeCounter > sendNodes && msgIndex < MAX_NODES_PER_MESSAGE) {
				radioImageMsg->nodes[msgIndex].id = i_;
				radioImageMsg->nodes[msgIndex].rssi = nodeList[i_].last_rssi;
				msgIndex++;
				sendNodes++;
			}
		}
	}

	if(msgIndex < MAX_NODES_PER_MESSAGE) {
		radioImageMsg->nodes[msgIndex].id = 0;
		radioImageMsg->nodes[msgIndex].rssi = 1;
	}

	return nodeCounter - sendNodes;
}

void receivedSchedule(nx_uint8_t scheduleMsg[]) {
	uint8_t i;
	for(i = 0; i < 27; i++) {
		schedule[scheduleFilled] = scheduleMsg[i];
		scheduleFilled++;

	}
}

void addHopInfoToBCMsg(BroadcastMsg* bpkt, uint8_t receiver) {
	hopInfo.receiver = receiver;
	memcpy(bpkt, &hopInfo, sizeof(BroadcastMsg));
}


uint8_t computeIndicator(int8_t indicator) {
#ifdef LQI
	if(indicator > 105)
		return 1;
	else if(indicator > 100)
		return 2;
	else if(indicator > 95)
		return 8;
	else if(indicator > 90)
		return 16;
#else
	indicator = indicator-45;

	if(indicator > -50)
		return 1;
	else if(indicator > -70)
		return 2;
	else if(indicator > -80)
		return 7;
	else if(indicator > -90)
		return 14;
#endif
	
	return 22;
}
#endif
