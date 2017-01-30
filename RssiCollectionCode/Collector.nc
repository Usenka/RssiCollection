interface Collector {
	command void attacheNodeList(Node* nl);
	command void attacheHopInfo(BroadcastMsg* nl);
	command void initializeCollector();
	command void startCollection();
	event void collectionDone(error_t error);
}
