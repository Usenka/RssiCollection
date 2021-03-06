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

	uint8_t numberOfReceivedMsgs = 0;		//The amount of image messages received 
  	uint8_t numberOfSendMsgs = 0;			//The amount of image messages send

	uint8_t c_round = 0;		//collection round
	uint8_t requestID = 0;

	uint8_t requestedFrom = 0;

	int8_t sendNodes = 0;

	bool running = FALSE;

	void nl_update() {
		// update neighbor list -> nodes from which messages were received are in rang
		uint8_t i;	
		for(i = 0; i < NUMBER_OF_NODES+1; i++) {
			if(nodeList[i].msg_counter == 0)
				nodeList[i].inRange = FALSE;

			nodeList[i].msg_counter = 0; // reset message counter for all nodes
		}
	}

	void collection_update() {
		uint8_t i;
		for(i = 0; i < NUMBER_OF_NODES+1; i++) {
			nodeList[i].receivedImage = NUMBER_OF_NODES; //reset recivedImage for all nodes
		}

		c_round++;
		requestID = 0;
		sendNodes = 0;
	}

	/*fills the given payload with as much data as posible. Returns the amount of data remaining*/
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

	/*Fills the array that contains the image messages whith the own image. It also increases the numberOfReceivedMsgs so there can be a check later if numberOfReceivedMsgs is 
	equals the  numberOfSendMsgs the see if all the data was transmittet yet*/
	void fillImgQueue(void) {
		uint8_t motesLeft = NUMBER_OF_NODES;
		RadioImageMsg* ripkt = (RadioImageMsg*) (call Packet_.getPayload(&ri_msg_queue[0], sizeof(RadioImageMsg)));
		numberOfReceivedMsgs = 0;	
	
		nl_update();

		for(numberOfReceivedMsgs = 0; motesLeft != 0; numberOfReceivedMsgs++) {
			ripkt = (RadioImageMsg*) (call Packet_.getPayload(&ri_msg_queue[numberOfReceivedMsgs], sizeof(RadioImageMsg)));		
			ripkt->motesLeft = fillRadioImageMsg(ripkt);		
			ripkt->from = TOS_NODE_ID;
			ripkt->request_id = requestID;		

			motesLeft = ripkt->motesLeft;				
		}

		numberOfSendMsgs = 0;	
	}

	/*Evaluates the next node the request should be forwarded to. Returns 0 if there is no child left and the node can send it's own image*/
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
		fpkt->flag = FLAG_REQUEST;			
		fpkt->round = c_round;		
		fpkt->id = requestID +1;
		requestID++;
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
	}

	command void Collector.attacheHopInfo(BroadcastMsg* hi) {
		hopInfo = hi;
		hopInfoAttached = TRUE;
	}

	command void Collector.startCollection() {
		uint8_t next = getNextLeft();

		if(running == TRUE) {
			_printf("ERROR 101\n");
			return;
		}
			
		running = TRUE;

		_printf("START collection\n");
	
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

	task void sendImgToPC() {
		if(!pcBusy)
			if (call PCSend.send(AM_BROADCAST_ADDR, &ri_msg_queue[numberOfSendMsgs], sizeof(RadioImageMsg)) == SUCCESS) 
				pcBusy = TRUE;
	}

	task void forwardImage() {
		if(!riBusy) {
			if (call RadioImageSend.send(hopInfo->nextHop, &ri_msg_queue[numberOfSendMsgs], sizeof(RadioImageMsg)) == SUCCESS)
				riBusy = TRUE;
		} else if(riBusy) {
		}
	}

	task void forwardRequest() {
		uint8_t next = getNextLeft();
		if(!fBusy)
			if (call FlagSend.send(next, &f_msg, sizeof(FlagMsg)) == SUCCESS)
				fBusy = TRUE;
	}

	event message_t* RadioImageReceive.receive(message_t* msg, void* payload, uint8_t len) {
		if(len == sizeof(RadioImageMsg)) {
			uint8_t sour = call AMPacket.source(msg);
			RadioImageMsg* ripkt = (RadioImageMsg*) (call Packet_.getPayload(&ri_msg_queue[numberOfReceivedMsgs], sizeof(RadioImageMsg)));		

			if(requestedFrom == sour && ((RadioImageMsg*)payload)->request_id == requestID) {
				//checks if the part of the image got received already				
				if( ((RadioImageMsg*)payload)->motesLeft >= nodeList[((RadioImageMsg*)payload)->from].receivedImage) {
					return msg;
				}	

				//save the received msg
				memcpy(ripkt, payload, sizeof(RadioImageMsg));

				nodeList[ripkt->from].receivedImage = ripkt->motesLeft;
				numberOfReceivedMsgs++;

				//do not continue until the whole image is received from that node
				if(nodeList[ripkt->from].receivedImage != 0) {
					return msg;
				}

				numberOfSendMsgs = 0;
				
				if(TOS_NODE_ID == ROOT_NODE && !pcBusy) {
					post sendImgToPC();
				}
				else if(!riBusy) {
					post forwardImage();
				} else if(riBusy) {
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
		if (!call PacketAck.wasAcked(msg) && retransmissions_img < MAX_RETRANSMISSIONS && ripkt->request_id == requestID) {
			if (call RadioImageSend.send(destination, &ri_msg_queue[numberOfSendMsgs], sizeof(RadioImageMsg)) == SUCCESS)
				riBusy = TRUE;	
		} else {

			/*if (call PacketAck.wasAcked(msg)){
				//_printf("Got Ack for IMG send to %d\n", destination);}
			}
			else if (retransmissions_img >= MAX_RETRANSMISSIONS){
				//_printf("Max rtx dropped IMG.\n");}
			}
			else {
			}*/

			if(notSendImg == TRUE) {
				fillImgQueue();	
				notSendImg = FALSE;

				post forwardImage();

				return;
			}

			retransmissions_img = 0;
			numberOfSendMsgs++;
			if(numberOfSendMsgs != numberOfReceivedMsgs) {
				post forwardImage();
			} else {
				numberOfSendMsgs = 0;
				numberOfReceivedMsgs = 0;

				if(ripkt->motesLeft == 0 && ripkt->from == TOS_NODE_ID) {
					collection_update();
					running = FALSE;
					signal Collector.collectionDone(SUCCESS);
				}
			}
		}
	}

  	
	void receivedRequest( void* payload, uint8_t len, uint8_t sour) {
		FlagMsg* fpkt = (FlagMsg*) (call Packet_.getPayload(&f_msg, sizeof(FlagMsg)));

		if(((FlagMsg*)payload)->round == c_round && ((FlagMsg*)payload)->id > requestID) {
			uint8_t next;
			requestID = ((FlagMsg*)payload)->id;
			
			next = getNextLeft();
			if(next > 0) {
				memcpy(fpkt, payload, len);
				post forwardRequest();		
			} else if(!riBusy){
				fillImgQueue();	
				notSendImg = FALSE;
				post forwardImage();
			} else if(riBusy) {
				//some retransmission is blocking the stuff
				notSendImg = TRUE;
			}

		}
	}

	/*This is a leftover from when i had multiple flags in the FlagMsg now it could be removed...*/
	event message_t* FlagReceive.receive(message_t* msg, void* payload, uint8_t len) {	
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
			if (call FlagSend.send(destination, &f_msg, sizeof(FlagMsg)) == SUCCESS)
				fBusy = TRUE;	
		} else {
			if (call PacketAck.wasAcked(msg)){
				//_printf("Got Ack for FLAG send to %d\n", destination);
			}
			else if (retransmissions_flag >= MAX_RETRANSMISSIONS){
				_printf("ERROR max drops reached\n");
			}
			else {      
			}	

			retransmissions_flag = 0;
		}
	}

	event void PCSend.sendDone(message_t* msg, error_t err) {	
		uint8_t next = 0;
		if(err == SUCCESS) 
			pcBusy = FALSE;
		else
			return;

		numberOfSendMsgs++;
		if(numberOfSendMsgs != numberOfReceivedMsgs) {
			post sendImgToPC();
		} else {
			RadioImageMsg* ripkt = call Packet_.getPayload(msg, sizeof(RadioImageMsg));
		
			numberOfSendMsgs = 0;
			numberOfReceivedMsgs = 0;			

			if(ripkt->from == ROOT_NODE && ripkt->motesLeft == 0) {
				collection_update();
				running = FALSE;
				signal Collector.collectionDone(SUCCESS);
			} else {
				next = getNextLeft();
				if(next > 0) {	
					FlagMsg* fpkt = (FlagMsg*) (call Packet_.getPayload(&f_msg, sizeof(FlagMsg)));
					fillRequestFlag(fpkt);

					post forwardRequest();			
				} else if (!pcBusy) {
					//The root starts sending its image
					fillImgQueue();	

					post sendImgToPC();
				}
			}	
		}
	}

}
