package JavaRecources;

public class Configuration {
	public static final int NUMBER_OF_NODES = 32;
	public static Phase PHASE = Phase.CALIBRATION;
	public static final int MAX_NODES_PER_MESSAGE = (28-3)/2;
	public static final short ROOT_NODE = 1;

	public static final Command COMMAND_STARTCALIBRATION = new Command("START CALIBRATION", "STC");
	public static final Command COMMAND_LOADCALIBRATIONDATA = new Command("LOAD CALIBRATIONDATA", "LC");
	public static final Command COMMAND_CREATESCHEDULE = new Command("CREATE SCHEDULE", "CS");
	public static final Command COMMAND_SENDSCHEDULE = new Command("SEND SCHEDULE", "SS");
	public static final Command COMMAND_STARTSCHEDULE = new Command("START SCHEDULE", "STS");
	public static final Command COMMAND_STOPSCHEDULE = new Command("STOP SCHEDULE", "STOP");
	public static final Command COMMAND_HELP = new Command("HELP", "H");
	
	public enum Phase {
		CALIBRATION, SAMPLING
	}

	public static class Command {
		public String long_;
		public String short_;
	
		public Command(String _long, String _short) { 
			long_ = _long.toUpperCase();
			short_ = _short.toUpperCase();
		}

		public boolean equals(String s) {
			if(s.toUpperCase().startsWith(long_)) {
				return true;
			}
			if(s.toUpperCase().startsWith(short_)) {
				return true;
			}
			return false;
		} 

		public String toString() {
			return long_+" ("+short_+")";
		}
	}
}
