#include "RadioImaging.h"
#include <Timer.h>
#include "printf.h"

module RadioImagingC {
	uses interface Boot;
  	uses interface SplitControl as AMControl;
	uses interface SplitControl as SerialControl;
	uses interface Receive as CommandReceive;
	uses interface Calibrator;
	uses interface Collector;
	uses interface ScheduleSender;
	uses interface Sampler;
}
implementation {
	uint8_t phase = PHASE_CALIBRATION;
	bool scheduleRunning = FALSE;	

	event void Boot.booted() {
		call AMControl.start();
		call SerialControl.start();
	}

	event void AMControl.startDone(error_t err) {
		// initialise program if successfully started, else try again
		if (err == SUCCESS) {

		} else {
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

	event message_t* CommandReceive.receive(message_t* msg, void* payload, uint8_t len) {
		if(len == sizeof(CommandMsg)) {
			CommandMsg* cpkt = (CommandMsg*) payload;

			if(cpkt->_command == COMMAND_STARTCALIBRATION) {
				call Calibrator.startCalibration();
			}
			else if(cpkt->_command == COMMAND_STARTSCHEDULE && !scheduleRunning) {
				phase = PHASE_SAMPLING;
				scheduleRunning = TRUE;
				call Sampler.startRound();
			} else {
				_printf("Unknown command\n");
			}
		}

		return msg;
	}

	event void Calibrator.calibrationDone(Node* nodeList, BroadcastMsg* hopInfo, error_t error) {
		_printf("FIN calibration\n");		
		call ScheduleSender.initializeScheduleSender();		
		call ScheduleSender.attacheNodeList(nodeList);
		call ScheduleSender.attacheHopInfo(hopInfo);	
		
		call Collector.initializeCollector();		
		call Collector.attacheNodeList(nodeList);
		call Collector.attacheHopInfo(hopInfo);

		call Sampler.attacheNodeList(nodeList);	

		if(TOS_NODE_ID == ROOT_NODE) {
			call Collector.startCollection();
		}
	}

	event void Collector.collectionDone(error_t error) {
		_printf("FIN collection\n");
		if(TOS_NODE_ID == ROOT_NODE && phase == PHASE_SAMPLING) {
			//_printf("Start Round!\n");
			call Sampler.startRound();
		}
	}

	event void ScheduleSender.receivedSchedule(uint8_t* schedule) {
		call Sampler.attacheSchedule(schedule);				
	}

	event void ScheduleSender.scheduleSpreaded() {
		_printf("FIN spreading\n");
	}

	event void Sampler.finishedRound() {
		_printf("FIN round\n");
		call Collector.startCollection();
	}
}
