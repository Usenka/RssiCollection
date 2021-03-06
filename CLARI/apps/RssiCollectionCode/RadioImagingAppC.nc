#include <Timer.h>
#include "RadioImaging.h"
#include <message.h>
#define NEW_PRINTF_SEMANTICS

configuration RadioImagingAppC {
}
implementation {
	components MainC;
	components CC2420ActiveMessageC;
	components SerialStartC;

	components RadioImagingC as App;
	components CalibratorM;
	components CollectorM;
	components ScheduleSenderM;
	components SamplerM;
	
	components new AMReceiverC(AM_BROADCAST) as BroadcastReceiver;
	components new AMSenderC(AM_BROADCAST) as BroadcastSender;
	components new AMReceiverC(AM_RADIOIMAGE) as RadioImageReceiver;
 	components new AMSenderC(AM_RADIOIMAGE) as RadioImageSender;
	components new AMReceiverC(AM_FLAG) as FlagReceiver;
	components new AMSenderC(AM_FLAG) as FlagSender;
	components new AMSenderC(AM_SCHEDULE) as ScheduleSender;
	components new AMReceiverC(AM_SCHEDULE) as ScheduleReceiver;
	components new AMSenderC(AM_SAMPLE) as SampleSender;
	components new AMReceiverC(AM_SAMPLE) as SampleReceiver;
	
	components new TimerMilliC() as BroadcastTimer;
	components new TimerMilliC() as BreakTimerA;
	components new AlarmMilli32C() as DropTimer;

	components LedsC;

	#ifdef REAL 
		components PrintfC;
	#else
		components SerialPrintfC;
	#endif

	App.Boot -> MainC;
	App.AMControl -> CC2420ActiveMessageC;
	App.Calibrator -> CalibratorM;
	App.Collector -> CollectorM;
	App.ScheduleSender -> ScheduleSenderM;
	App.Sampler -> SamplerM;

	CalibratorM.Rssi -> CC2420ActiveMessageC.CC2420Packet;
	CalibratorM.BroadcastTimer -> BroadcastTimer;
	CalibratorM.BreakTimer -> BreakTimerA;
	CalibratorM.Packet_ -> BroadcastSender;
	CalibratorM.AMPacket -> BroadcastSender;
	CalibratorM.BroadcastSend -> BroadcastSender;
	CalibratorM.BroadcastReceive -> BroadcastReceiver;

	CollectorM.Packet_ -> RadioImageSender;
	CollectorM.AMPacket -> RadioImageSender;
	CollectorM.PacketAck -> CC2420ActiveMessageC;
	CollectorM.RadioImageReceive -> RadioImageReceiver;
	CollectorM.RadioImageSend -> RadioImageSender;
	CollectorM.FlagReceive -> FlagReceiver;
	CollectorM.FlagSend -> FlagSender;

	ScheduleSenderM.Packet_ -> ScheduleSender;
	ScheduleSenderM.AMPacket -> ScheduleSender;
	ScheduleSenderM.PacketAck -> CC2420ActiveMessageC;
	ScheduleSenderM.ScheduleReceive -> ScheduleReceiver;
  	ScheduleSenderM.ScheduleSend -> ScheduleSender;

	SamplerM.SampleReceive -> SampleReceiver;
	SamplerM.SampleSend -> SampleSender;
	SamplerM.Packet_ -> BroadcastSender;
	SamplerM.AMPacket -> BroadcastSender;
	SamplerM.DropTimer -> DropTimer;
	SamplerM.Rssi -> CC2420ActiveMessageC.CC2420Packet;
	SamplerM.Leds -> LedsC;

	/*PCSend*/
	components SerialActiveMessageC as AM;
	components new SerialAMReceiverC(AM_COMMANDMSG) as pcCommandReceive;
	components new SerialAMSenderC(AM_RADIOIMAGEMSG) as pcRadioSend;
	components new SerialAMSenderC(AM_SCHEDULEMSG) as pcScheduleSend;
	components new SerialAMReceiverC(AM_SCHEDULEMSG) as pcScheduleReceive;
	
	App.SerialControl -> AM;
	App.CommandReceive -> pcCommandReceive; 

	CollectorM.PCSend -> pcRadioSend;

	ScheduleSenderM.PCScheduleSend -> pcScheduleSend;
	ScheduleSenderM.PCScheduleReceive -> pcScheduleReceive;
}
