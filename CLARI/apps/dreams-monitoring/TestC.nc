#include "Test.h"

configuration TestC {
}

implementation {
  components MainC;
  components new AlarmMilli32C() as TimerSend;
  components new TimerMilliC() as TimerSerialRetxmit;
  components new TimerMilliC() as TimerRadioRetxmit;
  components TimeSyncMessageC;
  components CC2420ActiveMessageC;
  components SerialActiveMessageC;
  components new SerialAMSenderC(AM_TEST_MSG) as SerialSend;
  components new SerialAMReceiverC(AM_TEST_MSG) as SerialReceive;

#ifdef SENSOR_READINGS
  components new SensirionSht11C() as TempHum;
  components new HamamatsuS10871TsrC() as TotalSolar;
  components new HamamatsuS1087ParC() as PhotoSynth;
  components new VoltageC() as Battery;
#endif
  components CC2420ControlC;
  components CC2420PacketC;
  components CC2420CsmaC;
  components LedsC;

  components TestP;

  components CC2420ReceiveP;

  components new PoolC(message_t, 10) as SerialMessagePool;
  components new QueueC(message_t*, 10) as SerialSendQueue;

#ifdef RXTX_MONITORING
  components RxTxMonitoringAppC;
#endif
  
  TestP.Boot -> MainC;
  TestP.TimerSend -> TimerSend;
  TestP.TimerSerialRetxmit -> TimerSerialRetxmit;
  TestP.TimerRadioRetxmit -> TimerRadioRetxmit;
  TestP.RadioControl -> TimeSyncMessageC;
  TestP.RadioSend -> TimeSyncMessageC.TimeSyncAMSendMilli[AM_TEST_MSG];
  TestP.PacketTime -> TimeSyncMessageC;
  TestP.RadioReceive -> TimeSyncMessageC.Receive[AM_TEST_MSG];
  TestP.SerialControl -> SerialActiveMessageC;
  TestP.SerialSend -> SerialSend;
  TestP.SerialReceive -> SerialReceive;
#ifdef SENSOR_READINGS
  TestP.Temp -> TempHum.Temperature;
  TestP.Hum -> TempHum.Humidity;
  TestP.TotalSolar -> TotalSolar;
  TestP.PhotoSynth -> PhotoSynth;
  TestP.Battery -> Battery;
#endif
  TestP.Noise -> CC2420ControlC;
  TestP.CC2420Config -> CC2420ControlC;
  TestP.RadioBackoff -> CC2420CsmaC;
  TestP.CC2420Packet -> CC2420PacketC;
  TestP.PacketAcknowledgements -> CC2420ActiveMessageC;
  TestP.AMPacket -> TimeSyncMessageC;
  TestP.SerialPacket -> SerialActiveMessageC;

  TestP.Leds -> LedsC;

  TestP.SerialMessagePool -> SerialMessagePool;
  TestP.SerialSendQueue -> SerialSendQueue;
}
