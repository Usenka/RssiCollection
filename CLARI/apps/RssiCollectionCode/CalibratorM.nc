#include <Timer.h>
#include "printf.h"
#include "RadioImaging.h"

module CalibratorM {
	provides interface Calibrator;

	uses interface AMSend as BroadcastSend;
	uses interface Receive as BroadcastReceive;

	uses interface Timer<TMilli> as BroadcastTimer;		//Schedules the calibration broadcasts
 	uses interface Timer<TMilli> as BreakTimer;		//The ROOT_MOTE should take a small break when he finnished sending it calibration broadcasts before requesting the Images.
	uses interface AMPacket;
	uses interface Packet as Packet_;
	uses interface CC2420Packet as Rssi;
} implementation {
	uint16_t sendBroadcasts = 0;
	uint8_t running = FALSE;

	uint8_t attachedNodeList = FALSE;
	Node nodeList[NUMBER_OF_NODES+1];
	BroadcastMsg hopInfo;

	uint8_t brcaBusy = FALSE;
	message_t brca_msg;

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

	void initializeHopInfo() {
		if(TOS_NODE_ID == ROOT_NODE) {
			hopInfo.hopValue = 0;
			hopInfo.nextHop = 0;
		} else {
			hopInfo.hopValue = NO_HOP_COUNT;
			hopInfo.nextHop = -1;
		}
	}

	void addHopInfoToBCMsg(BroadcastMsg* bpkt, uint8_t receiver) {
		hopInfo.receiver = receiver;
		memcpy(bpkt, &hopInfo, sizeof(BroadcastMsg));
	}

	void nl_received_msg(uint16_t id, int8_t rssi, int8_t nHop) {
		// increase message counter for a specific node
		nodeList[id].msg_counter++;
		nodeList[id].last_rssi = rssi-45;
		nodeList[id].inRange = TRUE;
		nodeList[id].nextHop = nHop;
	}

	command void Calibrator.startCalibration() {
		_printf("START calibration\n");
		initializeNodeList();
		initializeHopInfo();
		running = TRUE;	
		call BroadcastTimer.startPeriodic(TIME_BETWEEN_BRAODCASTS+((TOS_NODE_ID^2)%NUMBER_OF_NODES));
	}

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
		signal Calibrator.calibrationDone(nodeList, &hopInfo, SUCCESS);
	}

	event void BroadcastSend.sendDone(message_t* msg, error_t err) {
		brcaBusy = FALSE;
		sendBroadcasts++;	
		if(sendBroadcasts >= BROADCAST_AMOUNT)  {
			call BroadcastTimer.stop();
		
			if(TOS_NODE_ID == ROOT_NODE) 
				call BreakTimer.startOneShot(TIME_TAKE_A_BREAK);
			else {
				signal Calibrator.calibrationDone(nodeList, &hopInfo, SUCCESS);
			}
		}
	}

	event message_t* BroadcastReceive.receive(message_t* msg, void* payload, uint8_t len) {
		int8_t usedIndicator;		
		int8_t rssi;
		uint8_t source;
		#ifdef LQI
			int8_t lqi;
		#endif
		
		BroadcastMsg* bpkt = (BroadcastMsg*) payload;
		int8_t tmp_hopValue;


		if(running == FALSE) {
			call Calibrator.startCalibration();
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

		return msg;
	}
}
