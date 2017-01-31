TINYOS_ROOT_DIR?=$(TINYOS)
TINYOS_OS_DIR?=$(TINYOS_ROOT_DIR)/tos

COMPONENT=DemoCollectionAppC
CFLAGS += -DLOW_POWER_LISTENING

CFLAGS += -DCC2420_DEF_RFPOWER=3
CFLAGS += -DCC2420_CHANNEL=26

CFLAGS += -I./lib/net \
          -I./lib/net/ctp \
          -I. \
          -I./rxtxmonitoring \
          -I$(TINYOS_OS_DIR)/lib/net \
          -I$(TINYOS_OS_DIR)/lib/net/le \
          -I$(TINYOS_OS_DIR)/lib/printf\

# LPL
CFLAGS += -DLPL_DEF_LOCAL_WAKEUP=1024
CFLAGS += -DLPL_DEF_REMOTE_WAKEUP=1024

# Low level monitoring of received and transmitted messages
# CFLAGS += -DRXTX_MONITORING
# Low level monitoring of corrupted messages (must be RXTX_MONITORING enabled)
# CFLAGS += -DRXTX_MONITORING_CORRUPTED




include $(TINYOS_ROOT_DIR)/Makefile.include
#include $(MAKERULES)
