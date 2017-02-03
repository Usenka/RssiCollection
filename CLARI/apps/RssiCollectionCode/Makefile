TINYOS_ROOT_DIR?=../../..

COMPONENT=RadioImagingAppC
#TOSMAKE_PRE_EXE_DEPS += Java
TOSMAKE_CLEAN_EXTRA = *.class ./JavaRecources/*.class RadioImageMsg.java ScheduleMsg.java CommandMsg.java *~ ./JavaRecources/*~

Java: $(wildcard *.java) RadioImageMsg.java ScheduleMsg.java CommandMsg.java RssiReceive.class
	javac ./JavaRecources/*.java

RssiReceive.class: 
	javac *.java

RadioImageMsg.java:
	nescc-mig java -java-classname=RadioImageMsg RadioImaging.h RadioImageMsg -o $@

ScheduleMsg.java:
	nescc-mig java -java-classname=ScheduleMsg RadioImaging.h ScheduleMsg -o $@

CommandMsg.java:
	nescc-mig java -java-classname=CommandMsg RadioImaging.h CommandMsg -o $@

CFLAGS+=-DCC2420_DEF_CHANNEL=11
CFLAGS+=-DCC2420_DEF_RFPOWER=20 #31 is most power
CFLAGS+=-I$(TINYOS_ROOT_DIR)/tos/lib/printf
CFLAGS += -I$(TINYOS_ROOT_DIR)/tos/lib/T2Hack
CFLAGS += -DREAL

include $(TINYOS_ROOT_DIR)/Makefile.include

#include $(MAKERULES)
