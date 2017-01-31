interface RxTx{
  event void rxtx(message_t *msg, uint8_t size, uint8_t rssi, uint8_t lqi);
  //, uint8_t *metadata);
}
