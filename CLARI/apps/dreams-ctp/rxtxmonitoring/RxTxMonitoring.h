#ifndef RXTXMONITORING_H
#define RXTXMONITORING_H

#include "AM.h"

#ifndef TOSH_DATA_LENGTH
#define TOSH_DATA_LENGTH 80
#endif

enum {
  MAX_RXTXMONITORINGSERIAL_RETRIES = 10,
  FAILED_RXTXMONITORINGSERIAL_BACKOFF = 30,
};

enum {
        AM_RXTXMONITORINGMSG = 0x90,

        RX_EVENT = 0x01,
        TX_EVENT = 0x02,
        RX_CORRUPTED_EVENT = 0x03,
        STATS_EVENT = 0x04,
};

typedef nx_struct rxtx_infos {
  nx_uint16_t type;
  nx_uint16_t log_src;
  nx_uint32_t timestamp;
  nx_uint16_t seq_num;
  nx_uint8_t rssi;
  nx_uint8_t lqi;
  nx_uint8_t size_data;
  nx_uint8_t valid_noise_samples;
  nx_uint16_t noise[3];
  //nx_uint8_t metadata[2];
} rxtx_infos;

typedef nx_struct RxTxMonitoringMsg {
  rxtx_infos infos;
  nx_uint8_t data[TOSH_DATA_LENGTH-sizeof(rxtx_infos)];
} RxTxMonitoringMsg;


#endif
