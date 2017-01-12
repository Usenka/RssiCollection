interface Calibrator {
	command void startCalibration();
	event void calibrationDone(Node* nodeList, BroadcastMsg* hopInfo, error_t error);
}
