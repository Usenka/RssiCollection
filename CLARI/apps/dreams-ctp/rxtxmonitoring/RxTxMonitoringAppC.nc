
#include "RxTxMonitoring.h"

#warning "MONITORING RX AND TX MESSAGES"

configuration RxTxMonitoringAppC {}

implementation {
  components RxTxMonitoringC,MainC;
  components new TimerMilliC() as MonitoringTimer;
  components new TimerMilliC() as RetxmitTimer;
  components SerialActiveMessageC as SerialAM;
  components new PoolC(message_t, 15) as MonitoringMessagePool;
  components new QueueC(message_t*, 15) as MonitoringSendQueue;
  components CC2420ControlC;
  //components CC2420CsmaC;
#ifdef RXTX_MONITORING_CORRUPTED
  components CC2420ReceiveC;
#endif
  components UniqueSendC, UniqueReceiveC;
  components new TimerMilliC() as NoiseSamplingTimer;
  
  
  RxTxMonitoringC.Boot -> MainC;
  RxTxMonitoringC.SerialControl -> SerialAM;
  RxTxMonitoringC.SerialMonitoringSend -> SerialAM.AMSend[AM_RXTXMONITORINGMSG];
  RxTxMonitoringC.MonitoringTimer -> MonitoringTimer;
  RxTxMonitoringC.RetxmitTimer -> RetxmitTimer;
  RxTxMonitoringC.MonitoringMessagePool -> MonitoringMessagePool;
  RxTxMonitoringC.MonitoringSendQueue -> MonitoringSendQueue;
  RxTxMonitoringC.Noise -> CC2420ControlC;
  RxTxMonitoringC.NoiseSamplingTimer -> NoiseSamplingTimer;
  RxTxMonitoringC.RxEvent -> UniqueReceiveC.RxTx;
#ifdef RXTX_MONITORING_CORRUPTED
  RxTxMonitoringC.RxCorruptedEvent -> CC2420ReceiveC.RxTx;
#endif
  RxTxMonitoringC.TxEvent -> UniqueSendC.RxTx;
}
