interface Sampler {
	command void attacheNodeList(Node* nl);
	command void attacheSchedule(uint8_t* nl);
	command void startRound();
	event void finishedRound();
}
