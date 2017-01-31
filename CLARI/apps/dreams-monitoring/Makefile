COMPONENT = TestC
CFLAGS += -DCC2420_DEF_RFPOWER=27
CFLAGS += -DCC2420_DEF_CHANNEL=26

CFLAGS += -DSERIAL_CONTROLLER

CFLAGS += -DTOSH_DATA_LENGTH=80

CFLAGS += -I./rxtxmonitoring

# Sampling of the sensors (including battery) 
#CFLAGS += -DSENSOR_READINGS

# Low level monitoring of received and transmitted messages
# CFLAGS += -DRXTX_MONITORING
# Low level monitoring of corrupted messages (must be RXTX_MONITORING enabled)
# CFLAGS += -DRXTX_MONITORING_CORRUPTED

# Java + Python
BUILD_EXTRA_DEPS = RxTxMonitoringMsg.java
CLEAN_EXTRA = RxTxMonitoringMsg.java

RxTxMonitoringMsg.java:
	mig java -target=null -java-classname=RxTxMonitoringMsg rxtxmonitoring/RxTxMonitoring.h RxTxMonitoringMsg -o $@

	
include $(TINYOS_ROOT_DIR)/Makefile.include
#include $(MAKERULES)

