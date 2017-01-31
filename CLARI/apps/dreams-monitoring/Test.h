#ifndef TEST_H
#define TEST_H

enum {
  AM_TEST_MSG = 13
};

enum {
  MAX_TESTSERIAL_RETRIES = 3,
  FAILED_TESTSERIAL_BACKOFF = 30,
  STARTUP_SEQ_NUM_WINDOW = 19,
};

enum {
  INITIATOR_NODE = 0,
  STEP_INTERVAL = 1024, //in ticks
  MS_INTERVAL = 1000, //in ms
  NUM_NODES = 14,
  NUM_TRANSMISSIONS = 2,
  STEP_IMI = 30 //in ticks
};

enum {
  NONE = 0,
  SEND = 1,
  RECEIVE = 2,
  FAILED_CRC = 3,
  INVALID = 0xFFFF
};

typedef nx_struct test_msg {
  nx_uint16_t type;  //2
  nx_uint32_t seq_num;  //6
  nx_uint16_t sender;  //8
  nx_uint16_t receiver;  //10
  nx_uint16_t rssi;  //12
  nx_uint16_t lqi;  //14
  nx_uint16_t temp;  //16
  nx_uint16_t hum;  //18
  nx_uint16_t sol;  //20
  nx_uint16_t synth;  //22
  nx_uint16_t batt;  //24
  nx_uint16_t noise1;  //26
  nx_uint16_t noise2;  //28
  nx_uint16_t noise3;  //30
  nx_uint32_t diff_time; //34
  nx_uint16_t channel; //36
  nx_uint16_t power; //38
  nx_uint16_t error; //40
} test_msg_t;

#endif
