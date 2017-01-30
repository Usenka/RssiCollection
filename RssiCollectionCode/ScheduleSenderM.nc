module ScheduleSenderM {
	provides interface ScheduleSender;

	uses interface AMSend as ScheduleSend;
	uses interface Receive as ScheduleReceive;
	uses interface AMSend as PCScheduleSend;
 	uses interface Receive as PCScheduleReceive;

	uses interface AMPacket;
	uses interface Packet as Packet_;
	uses interface PacketAcknowledgements as PacketAck;
} implementation {
	Node* nodeList;	
	BroadcastMsg* hopInfo;

	uint8_t nodeListAttached = FALSE;
	uint8_t hopInfoAttached = FALSE;

	uint8_t schedule[NUMBER_OF_NODES*2];

	message_t sd_msg;
	bool sdBusy = FALSE;
	bool pcBusy = FALSE;

	uint8_t scheduleFilled = 0;
	uint8_t scheduleLeft = -1;

	uint8_t scheduleMsgId = 0;

	uint8_t notForwarded = 0;
	uint8_t retransmissions_sd = 0;

	void receivedSchedule(nx_uint8_t scheduleMsg[]) {
		uint8_t i;
		for(i = 0; i < 26; i++) {
			schedule[scheduleFilled] = scheduleMsg[i];
			scheduleFilled++;
		}
	}	
	
	uint8_t getNextLeftSchedule() {
		uint8_t i;
		for(i = 1; i<NUMBER_OF_NODES+1; i++) {
			if(nodeList[i].nextHop == TOS_NODE_ID && !nodeList[i].receivedSchedule) {
				return i;
			}
		}
		return hopInfo->nextHop;
	} 

	void initializeSchedule() {
		uint8_t i;
		for(i = 0; i<NUMBER_OF_NODES*2; i++) 
			schedule[i] = 0;
	}

	command void ScheduleSender.initializeScheduleSender() {
		initializeSchedule();
		call PacketAck.requestAck(&sd_msg);
	}

	command void ScheduleSender.attacheNodeList(Node* nl) {
		nodeList = nl;
		nodeListAttached = TRUE;
	}

	command void ScheduleSender.attacheHopInfo(BroadcastMsg* hi) {
		hopInfo = hi;
		hopInfoAttached = TRUE;
	}

	event message_t* PCScheduleReceive.receive(message_t* msg, void* payload, uint8_t len) {
		if(!nodeListAttached || !hopInfoAttached)
			return msg;
		
		_printf("Received Schdeule Part from pc");

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

			spkt->msgid = ++scheduleMsgId;
			next = getNextLeftSchedule();
			if (call ScheduleSend.send(next, &sd_msg, sizeof(ScheduleMsg)) == SUCCESS)
				sdBusy = TRUE;
		}

		return msg;
  	}

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

		if(nodeList[from].receivedSchedule == TRUE || ((ScheduleMsg*)payload)->msgid < scheduleMsgId) {
			_printf("Already received that schedulepart from that node\n");
			return msg;
		}

		memcpy(spkt, payload, len);
		nodeList[from].receivedSchedule = TRUE;
		scheduleMsgId = ++((ScheduleMsg*)payload)->msgid;

		next = getNextLeftSchedule();
		if(next > 0 && sdBusy == FALSE) {
			_printf("Forward to: %d\n",next);
			spkt->msgid = scheduleMsgId;
			if (call ScheduleSend.send(next, &sd_msg, sizeof(ScheduleMsg)) == SUCCESS)
				sdBusy = TRUE;
			notForwarded = 0;
		}  else if(sdBusy == TRUE){
			notForwarded = 1;
			//_printf("Something went horribly wrong dude...\n");
		} else if(pcBusy == FALSE){
			if (call PCScheduleSend.send(next, &sd_msg, sizeof(ScheduleMsg)) == SUCCESS)
				pcBusy = TRUE;
		}

		return msg;
	}
   
	event void ScheduleSend.sendDone(message_t* msg, error_t err) {	
		uint8_t destination = call AMPacket.destination(msg);		

		if(err == SUCCESS) 
		sdBusy = FALSE;

		retransmissions_sd++;
		if (!call PacketAck.wasAcked(msg) && retransmissions_sd < MAX_RETRANSMISSIONS) {	
			_printf("Retransmission to %d\n", destination);
			if (call ScheduleSend.send(destination, &sd_msg, sizeof(ScheduleMsg)) == SUCCESS)
				sdBusy = TRUE;	
		} else {
			if (call PacketAck.wasAcked(msg)){
				_printf("Acked\n");
			} else{
				_printf("Max rtx dropped.\n");
			}

			retransmissions_sd = 0;

			if(notForwarded) {
				uint8_t next = getNextLeftSchedule();
				_printf("Was not forwarded, do it now\n");
				if (call ScheduleSend.send(next, &sd_msg, sizeof(ScheduleMsg)) == SUCCESS)
					sdBusy = TRUE;
				notForwarded = 0;
				
				return;
			}
	
			if(scheduleLeft == 0 && destination == hopInfo->nextHop)
				signal ScheduleSender.receivedSchedule(schedule);	
		}
	}

	event void PCScheduleSend.sendDone(message_t* msg, error_t err) {
		ScheduleMsg* spkt = (ScheduleMsg*) call Packet_.getPayload(msg, sizeof(ScheduleMsg));		
		if(err == SUCCESS) 
			pcBusy = FALSE;

		if(spkt->left == 0) {
			signal ScheduleSender.receivedSchedule(schedule);
			signal ScheduleSender.scheduleSpreaded();
		}
	}
}
