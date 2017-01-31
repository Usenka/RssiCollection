#ifndef DEMOCOLLECTION_H
#define DEMOCOLLECTION_H
// To suppress "new printf format" warning
#define NEW_PRINTF_SEMANTICS
#define LEDS FALSE

#include "AM.h"

enum {
	// Application
	AM_DEMOCOLLECTIONMSG = 0x06,
	CTP_DEMOCOLLECTIONID = 0xee,
	DATA_TIMER_PERIOD_MILLI = 1*1024U,
	DEFAULT_DELAY_RAND_SEC = 60,
	ROOT_NODE_ID=1,

	// System and control
	//LPL_INTERVAL = 200,
	AM_SERIALCONTROLMSG = 0x89,

	// Control commands
	CMD_REBOOT = 0x01,
	CMD_EXP_START = 0x02,
	CMD_EXP_STOP = 0x03,

	// Logger 
	AM_LOGGERMSG = 0x07,
	LOG_STAT_INTERVAL_MILLI = 60*1024U, // Sending interval for stats
        MAX_LOGSERIAL_RETRIES = 10,
        FAILED_LOGSERIAL_BACKOFF = 30,

	// Message types
	// 0x01 - 0x10 - APP /normal/ events
	LOG_APP_SND = 0x01,
	LOG_APP_RCV = 0x02,
	LOG_APP_INT = 0x03,

	// 0x11 - 0x20 - APP errors
	LOG_APP_ERR_SND = 0x11,	// error = EBUSY means CTP congestion.
	LOG_APP_CNG = 0x12,	// CTP did not signal sendDone before timer expired

	// 0x21 - 0x30 - "hop" events
	LOG_HOP_RCV = 0x21,
	LOG_HOP_SND = 0x22,

	// CTP 
	// 0x41 - 0x50 - Control Plane events
	LOG_CTC_BCN = 0x41,
	LOG_CTC_NPT	= 0x42,
	
	// 0x51 - 0x60 - Data Plane events
	LOG_CTD_DRP_LOCAL = 0x51,
	LOG_CTD_DRP_FWD = 0x52,
	LOG_CTD_RTM_WAITACK = 0x53,
	LOG_CTD_RTM_FAIL = 0x54,
	LOG_CTD_SND = 0x55,
	LOG_CTD_FWD = 0x56,

	// 0x61 - 0x70 - Experiment control
	LOG_EXP_START = 0x61,
	LOG_EXP_STOP = 0x62,

	// 0x81 - 0x90 - Hardware info
	LOG_HW_BOOT = 0x81,
	LOG_HW_RADIO_STAT = 0x82,

	// 0x91 - 0x99 - Logger debugging
	LOG_DBG_STAT = 0x91,
};

typedef nx_struct DemoCollectionMsg {
 	nx_uint16_t nodeid;		// 2
 	nx_uint32_t seq_num;	// 6
 	nx_uint16_t data;	// 8
 	nx_uint16_t hop_id;	// 10
 	nx_uint32_t hop_rcvt;	// 14
 	nx_uint32_t hop_sndt;	// 18
 	//nx_uint16_t data_u16;	// 20
 	//nx_uint32_t data_u32;	// 24
 	//nx_uint64_t data_u64;	// 32
} DemoCollectionMsg;

typedef nx_struct SerialControlMsg {
  nx_uint8_t cmd;
  nx_uint8_t param;
} SerialControlMsg;

typedef nx_struct LoggerMsg {
	nx_uint8_t type;		// 1 LOG Event Type
	nx_uint32_t timestamp;	// 5 Local timestamp
	nx_am_addr_t log_src;	// 7 The logging source
 	nx_am_addr_t src;		// 9 Message source (origin for most)
 	nx_am_addr_t dst;		// 11 Message destination (next hop for most)
 	nx_uint16_t seq_num;	// 13 Message sequence number
 	nx_uint8_t arg_u8;		// 14 8-bit optional field (e.g., error code)
 	nx_uint16_t arg_u16;	// 16 Extra field 0 (e.g., for the message RSSI)
 	nx_uint32_t arg_u32;	// 20 Extra field 1 (e.g., for latency)
} LoggerMsg;

#endif
