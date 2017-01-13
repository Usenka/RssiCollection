#ifndef RADIOIMAGING_H
#define RADIOIMAGING_H 

#define MAX_MSG_PAYLOAD 28
#define _printf(...) printf(__VA_ARGS__);printfflush()
//#define _printf(...) if(TOS_NODE_ID == 1) {printf(__VA_ARGS__);printfflush();}
//#define _printf(...) ;

enum {
  ROOT_NODE = 1,
  AM_RADIOIMAGEMSG = 0x89,
  AM_SCHEDULEMSG = 0x90,
  AM_COMMANDMSG = 0x91,
  AM_RADIOIMAGE = 6,
  AM_BROADCAST = 7,
  AM_SCHEDULE = 8,
  AM_FLAG = 9,
  AM_SAMPLE = 10,
  NUMBER_OF_NODES = 32,
  MAX_NODES_PER_MESSAGE = (MAX_MSG_PAYLOAD-3)/2,
  PHASE_CALIBRATION = 0,
  PHASE_SAMPLING = 1,
  TIME_BETWEEN_BRAODCASTS = 20,
  TIME_ACK_TIMEOUT = 20,
  TIME_SCHEDULE_TIMEOUT = 5000,
  TIME_REQUEST_TIMEOUT = 500,
  TIME_TAKE_A_BREAK = 20000,
  TIME_MAX_MESSAGE_SENDING = 20,
  BROADCAST_AMOUNT = 30,//500,
  NO_HOP_COUNT = -1,
  FLAG_REQUEST = 1,
  ROUNDS_BEFORE_COLLECTION = 1,

  MAX_RETRANSMISSIONS = 50,

  COMMAND_STARTCALIBRATION = 0,
  COMMAND_STARTSCHEDULE = 1
};

typedef nx_struct BroadcastMsg {
  nx_int8_t hopValue;
  nx_uint8_t nextHop;
  nx_uint8_t receiver;
} BroadcastMsg;

typedef nx_struct SampleMsg {
  nx_uint8_t receiver;
} SampleMsg;

typedef nx_struct NodeMsg {
  nx_uint8_t id;
  nx_int8_t rssi;
} NodeMsg;

typedef nx_struct RadioImageMsg {
  nx_uint8_t from;
  nx_uint8_t request_id;
  nx_uint8_t motesLeft;
  NodeMsg nodes[MAX_NODES_PER_MESSAGE];
} RadioImageMsg;

typedef nx_struct FlagMsg {
  nx_uint8_t flag;
  nx_uint8_t id;
  nx_uint8_t round;
} FlagMsg;

typedef nx_struct ScheduleMsg {
  nx_uint8_t msgid;	
  nx_uint8_t left;
  nx_uint8_t schedule[MAX_MSG_PAYLOAD-2];
} ScheduleMsg;

typedef nx_struct CommandMsg {
  nx_uint8_t _command;
} CommandMsg;

typedef struct Node {
  uint16_t msg_counter;
  int8_t last_rssi;
  int8_t inRange;
  uint8_t nextHop;
  int8_t receivedImage;
  int8_t receivedSchedule;
} Node;

typedef struct PredecessorSuccessor {
  uint8_t predecessor;
  uint8_t successor;
} PredecessorSuccessor;

typedef struct SchedulePSCollection {
  uint8_t size;
  PredecessorSuccessor preSuc[10]; 
} SchedulePSCollection;

#endif
