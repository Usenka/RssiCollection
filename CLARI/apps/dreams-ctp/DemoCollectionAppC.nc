
#include "DemoCollection.h"

configuration DemoCollectionAppC {}
implementation {

#ifdef RXTX_MONITORING
  components RxTxMonitoringAppC;
#endif
  
  components DemoCollectionC, MainC, LedsC, ActiveMessageC;
  components CollectionC as Collector;
  components new CollectionSenderC(CTP_DEMOCOLLECTIONID);
  components new TimerMilliC() as DataTimer;
  components new TimerMilliC() as LogTimer;
  components new TimerMilliC() as RetxmitTimer;
  components PrintfC;
  //components SerialStartC; //FIXME: Was that causing the bug?
  //components CC2420ActiveMessageC as LPLProvider;
  components new DemoSensorC() as Sensor;
  components SerialActiveMessageC as SerialAM;
  components CC2420ActiveMessageC;
  components RandomC;
  components new PoolC(message_t, 15) as LogMessagePool;
  components new QueueC(message_t*, 15) as LogSendQueue;

  // Depending on whether LPL is enabled or not, we use different
  // interfaces to track events of packet reception and transmisison
  /*
  #if defined(LOW_POWER_LISTENING)
    components DefaultLplC as RadioLow;
  #else
    components DummyLplC as RadioLow;
  #endif*/
  // "Lowest" radio sending interface to track radio on/off events
  components CC2420CsmaC as RadioLowest;

  DemoCollectionC.Boot -> MainC;
  DemoCollectionC.RadioControl -> ActiveMessageC;
  DemoCollectionC.SerialControl -> SerialAM;
  DemoCollectionC.RoutingControl -> Collector;
  DemoCollectionC.Leds -> LedsC;
  DemoCollectionC.DataTimer -> DataTimer;
  DemoCollectionC.RootControl -> Collector;
  DemoCollectionC.DataSend -> CollectionSenderC;
  DemoCollectionC.DataReceive -> Collector.Receive[CTP_DEMOCOLLECTIONID];
  DemoCollectionC.CtpDataPacket -> Collector.Packet;
  DemoCollectionC.CtpPacket -> Collector;
  //DemoCollectionC.LPL -> LPLProvider;
  DemoCollectionC.SensorRead -> Sensor.Read;
  DemoCollectionC.Random -> RandomC;

  // Serial control communication
  DemoCollectionC.SerialCtlSend -> SerialAM.AMSend[AM_SERIALCONTROLMSG];
  DemoCollectionC.SerialCtlReceive -> SerialAM.Receive[AM_SERIALCONTROLMSG];
  DemoCollectionC.DataIntercept -> Collector.Intercept[CTP_DEMOCOLLECTIONID];

  // To extract CC2420 specific information from the packets
  DemoCollectionC -> CC2420ActiveMessageC.CC2420Packet;
  // To extract AM information from the packets (e.g., src or dst)
  DemoCollectionC -> CC2420ActiveMessageC.AMPacket;

  // UART Logger
  DemoCollectionC.SerialLogSend -> SerialAM.AMSend[AM_LOGGERMSG];
  DemoCollectionC.LogTimer -> LogTimer;
  DemoCollectionC.RetxmitTimer -> RetxmitTimer;
  DemoCollectionC.LogMessagePool -> LogMessagePool;
  DemoCollectionC.LogSendQueue -> LogSendQueue;
  Collector.CollectionDebug -> DemoCollectionC;

  // Radio low-level event handlers
  DemoCollectionC.RadioLowState -> RadioLowest.SplitControl;
  //DemoCollectionC.RadioLowSend -> RadioLow.Send;
  //DemoCollectionC.RadioLowRecv -> RadioLow.Receive;
}
