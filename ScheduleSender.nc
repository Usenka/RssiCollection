interface ScheduleSender {
	command void initializeScheduleSender();
	command void attacheNodeList(Node* nl);
	command void attacheHopInfo(BroadcastMsg* nl);
	event void receivedSchedule(uint8_t* schedule);
	event void scheduleSpreaded();
}
