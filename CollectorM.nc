#include <Timer.h>
#include "printf.h"
#include "RadioImaging.h"

module CollectorM {
	provides interface Collector;

	uses interface Receive as FlagReceive;
	uses interface AMSend as FlagSend;
	uses interface Receive as RadioImageReceive;
	uses interface AMSend as RadioImageSend;
	uses interface AMSend as PCSend;

	uses interface AMPacket;
	uses interface Packet as Packet_;
	uses interface PacketAcknowledgements as PacketAck;
} implementation {
	Node* nodeList;	
	BroadcastMsg* hopInfo;

	uint8_t nodeListAttached = FALSE;
	uint8_t hopInfoAttached = FALSE;

	message_t f_msg;
	message_t ri_msg_queue[(NUMBER_OF_NODES/MAX_NODES_PER_MESSAGE) + ((NUMBER_OF_NODES%MAX_NODES_PER_MESSAGE == 0) ? 0 : 1)];

	bool fBusy = FALSE;
	bool riBusy = FALSE;
	bool pcBusy = FALSE;
	uint8_t notSendImg = FALSE;	

	uint8_t numberOfReceivedMsgs = 0;
  	uint8_t numberOfSendMsgs = 0;	

	uint8_t c_round = 0;		//collection round
	uint8_t requestID = 0;

	uint8_t requestedFrom = 0;

	bool root_send_image = FALSE;

	int8_t sendNodes = 0;

	void nl_update() {
		// update neighbor list -> nodes from which messages were received are in rang
		uint8_t i;	
		printf("Update\n");		

		for(i = 0; i < NUMBER_OF_NODES+1; i++) {
			if(nodeList[i].msg_counter == 0)
			nodeList[i].inRange = FALSE;

			nodeList[i].msg_counter = 0; // reset message counter for all nodes
			nodeList[i].receivedImage = NUMBER_OF_NODES; //reset recivedImage for all nodes
		}

		c_round++;
		requestID = 0;
		sendNodes = 0;
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

	void fillImgQueue(void) {
		uint8_t motesLeft = NUMBER_OF_NODES;
		RadioImageMsg* ripkt = (RadioImageMsg*) (call Packet_.getPayload(&ri_msg_queue[0], sizeof(RadioImageMsg)));
		numberOfReceivedMsgs = 0;	

		for(numberOfReceivedMsgs = 0; motesLeft != 0; numberOfReceivedMsgs++) {
			ripkt = (RadioImageMsg*) (call Packet_.getPayload(&ri_msg_queue[numberOfReceivedMsgs], sizeof(RadioImageMsg)));		
			ripkt->motesLeft = fillRadioImageMsg(ripkt);		
			ripkt->from = TOS_NODE_ID;
			ripkt->request_id = requestID;		

			motesLeft = ripkt->motesLeft;				
		}

		numberOfSendMsgs = 0;	
	}

	uint8_t getNextLeft() {
		uint8_t i;
		for(i = 1; i<NUMBER_OF_NODES+1; i++) {
			if(nodeList[i].nextHop == TOS_NODE_ID && nodeList[i].receivedImage) {
				return i;
			}
		}
		return 0;
	}  

	void fillRequestFlag(FlagMsg* fpkt) {
		//printf("Hui ich erstelle nen request dingen :) %d\n", requestID);
		fpkt->flag = FLAG_REQUEST;			
		fpkt->round = c_round;		
		fpkt->id = requestID +1;
		requestID++;
		//printf("Hui ich erstelle nen request dingen :) %d %d\n",fpkt->id , requestID);
	}

	command void Collector.initializeCollector() {
		uint8_t i;
		for(i = 0; i < (NUMBER_OF_NODES/MAX_NODES_PER_MESSAGE) + ((NUMBER_OF_NODES%MAX_NODES_PER_MESSAGE == 0) ? 0 : 1); i++) {
			call PacketAck.requestAck(&ri_msg_queue[i]);
		}
		call PacketAck.requestAck(&f_msg);
	};

	command void Collector.attacheNodeList(Node* nl) {
		nodeList = nl;
		nodeListAttached = TRUE;
		_printf("nodeListAttached %d\n", nodeList[4].nextHop);
	}

	command void Collector.attacheHopInfo(BroadcastMsg* hi) {
		hopInfo = hi;
		hopInfoAttached = TRUE;
		_printf("hopInfoAttached %d\n", hopInfo->nextHop);
	}

	command void Collector.startCollection() {
		uint8_t next = getNextLeft();

		_printf("%d\n", next);
	
		if(!nodeListAttached || !hopInfoAttached)
			return;	

		if(next > 0) {
			FlagMsg* fpkt = (FlagMsg*) (call Packet_.getPayload(&f_msg, sizeof(FlagMsg)));
			fillRequestFlag(fpkt);	

			if(!fBusy)
				if (call FlagSend.send(next, &f_msg, sizeof(FlagMsg)) == SUCCESS)
					fBusy = TRUE;		
		}
	}

	event message_t* RadioImageReceive.receive(message_t* msg, void* payload, uint8_t len) {
		if(len == sizeof(RadioImageMsg)) {
			uint8_t sour = call AMPacket.source(msg);
			RadioImageMsg* ripkt = (RadioImageMsg*) (call Packet_.getPayload(&ri_msg_queue[numberOfReceivedMsgs], sizeof(RadioImageMsg)));		

			_printf("req Image from: %d; rec from: %d; source: %d --- %d %d\n", requestedFrom, sour, ((RadioImageMsg*)payload)->from, ((RadioImageMsg*)payload)->request_id, requestID);
			if(requestedFrom == sour && ((RadioImageMsg*)payload)->request_id == requestID) {
				if( ((RadioImageMsg*)payload)->motesLeft >= nodeList[((RadioImageMsg*)payload)->from].receivedImage) {
					_printf("allreadyReceived!\n");

					return msg;
				}	

				memcpy(ripkt, payload, sizeof(RadioImageMsg));

				nodeList[ripkt->from].receivedImage = ripkt->motesLeft;
				numberOfReceivedMsgs++;

				if(nodeList[ripkt->from].receivedImage != 0) {
					return msg;
				}

				numberOfSendMsgs = 0;
				_printf("Got the whole image from %d over %d\n", ripkt->from, sour);

				if(TOS_NODE_ID == ROOT_NODE && !pcBusy) {
					//memcpy(&pc_msg, , sizeof(message_t));
					_printf("img from %d send to pc\n", hopInfo->nextHop);
					if (call PCSend.send(AM_BROADCAST_ADDR, &ri_msg_queue[numberOfSendMsgs], sizeof(RadioImageMsg)) == SUCCESS) 
						pcBusy = TRUE;
				}
				else if(!riBusy) {
					_printf("forwarded to %d\n", hopInfo->nextHop);	
					if (call RadioImageSend.send(hopInfo->nextHop, &ri_msg_queue[numberOfSendMsgs], sizeof(RadioImageMsg)) == SUCCESS)
						riBusy = TRUE;
				} else if(riBusy)
					_printf("BUSY not forwarded to %d\n", hopInfo->nextHop);
			}

		}
		return msg;
	}

	uint8_t retransmissions_img = 0;
	event void RadioImageSend.sendDone(message_t* msg, error_t err) {
		RadioImageMsg* ripkt = (RadioImageMsg*) (call Packet_.getPayload(msg, sizeof(RadioImageMsg)));
		uint8_t destination = call AMPacket.destination(msg);

		/* if(TOS_NODE_ID == 2)      
		printf("START RadioImageSend.sendDone\n");  */

		if(err == SUCCESS) 
			riBusy = FALSE;	

		retransmissions_img++;
		if (!call PacketAck.wasAcked(msg) && retransmissions_img < MAX_RETRANSMISSIONS && ripkt->request_id == requestID) {
			_printf("Retransmission IMG to %d\n", destination);
			if (call RadioImageSend.send(destination, &ri_msg_queue[numberOfSendMsgs], sizeof(RadioImageMsg)) == SUCCESS)
				riBusy = TRUE;	
		} else {
			if (call PacketAck.wasAcked(msg)){
				_printf("Got Ack for IMG send to %d\n", destination);}
			else if (retransmissions_img >= MAX_RETRANSMISSIONS){
				_printf("Max rtx dropped IMG.\n");}
			else {
				_printf("Received next Request.\n");}

			if(notSendImg == TRUE) {
				fillImgQueue();	
				notSendImg = FALSE;

				if (call RadioImageSend.send(hopInfo->nextHop, &ri_msg_queue[numberOfSendMsgs], sizeof(RadioImageMsg)) == SUCCESS)
					riBusy = TRUE;

				return;
			}

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

				signal Collector.collectionDone(SUCCESS);
			}
		}
	}

  
	void receivedRequest( void* payload, uint8_t len, uint8_t sour) {
		FlagMsg* fpkt = (FlagMsg*) (call Packet_.getPayload(&f_msg, sizeof(FlagMsg)));

		printf("%d %d %d %d\n", ((FlagMsg*)payload)->round, c_round, ((FlagMsg*)payload)->id, requestID);
		if(((FlagMsg*)payload)->round == c_round && ((FlagMsg*)payload)->id > requestID) {
			uint8_t next;
			requestID = ((FlagMsg*)payload)->id;

			next = getNextLeft();
			_printf("Received Request: next = %d\n", next);
			if(next > 0 && !fBusy) {
				memcpy(fpkt, payload, len);
				if (call FlagSend.send(next, &f_msg, sizeof(FlagMsg)) == SUCCESS)
					fBusy = TRUE;			
			} else if(!riBusy){
				fillImgQueue();	
				notSendImg = FALSE;
				_printf("received Image msgs %d | send Image msgs: %d\n",numberOfReceivedMsgs, numberOfSendMsgs);
				if (call RadioImageSend.send(hopInfo->nextHop, &ri_msg_queue[numberOfSendMsgs], sizeof(RadioImageMsg)) == SUCCESS)
					riBusy = TRUE;
			} else if(riBusy) {
				notSendImg = TRUE;
			}

		}
	}

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
			else if (retransmissions_flag >= MAX_RETRANSMISSIONS){
				_printf("Max rtx dropped FLAG.\n");}
			else {      
				_printf("Received the image.\n");}	

			retransmissions_flag = 0;
		}
	}

	event void PCSend.sendDone(message_t* msg, error_t err) {	
		uint8_t next = 0;
		_printf("Finished sending Msg to pc\n");
		if(err == SUCCESS) 
			pcBusy = FALSE;
		else
			return;

		numberOfSendMsgs++;
		if(numberOfSendMsgs != numberOfReceivedMsgs) {
			if (call PCSend.send(AM_BROADCAST_ADDR, &ri_msg_queue[numberOfSendMsgs], sizeof(RadioImageMsg)) == SUCCESS)
			pcBusy = TRUE;
			
			return;
		} else {
			RadioImageMsg* ripkt = call Packet_.getPayload(msg, sizeof(RadioImageMsg));
			_printf("Finished sending Img to pc\n");
			if(ripkt->from == ROOT_NODE && ripkt->motesLeft == 0) {
				_printf("HuHu\n");
				root_send_image = TRUE;	
			}	

			numberOfSendMsgs = 0;
			numberOfReceivedMsgs = 0;
		}

		next = getNextLeft();
		if(next > 0) {	
			FlagMsg* fpkt = (FlagMsg*) (call Packet_.getPayload(&f_msg, sizeof(FlagMsg)));
			fillRequestFlag(fpkt);

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

			signal Collector.collectionDone(SUCCESS);
		}
		/*if(TOS_NODE_ID == 2)      
		printf("ENDT PCSend.sendDone\n"); */
	}

}
