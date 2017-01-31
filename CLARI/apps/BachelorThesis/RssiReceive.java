import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;
import java.util.*;
import JavaRecources.*;
import java.io.*;

class RssiReceive{
	MoteIF moteIF;	
	
	MessageListener radioImageListener =  new MessageListener() {
			public void messageReceived(int to, Message message) {
				RadioImageMsg radioImageMsg = (RadioImageMsg) message;
				System.out.println("Image received from " + radioImageMsg.get_from() + "; Data Left: " + radioImageMsg.get_motesLeft());

				if(Configuration.PHASE == Configuration.Phase.CALIBRATION) {
					recivedCalibrationMsg(radioImageMsg);
				} else if (Configuration.PHASE == Configuration.Phase.SAMPLING) {
					recivedSamplingMsg(radioImageMsg);
				}
			}};
	MessageListener scheduleListener = new MessageListener() {
			public void messageReceived(int to, Message message) {
				System.out.println("Recived schedule Msg");
				ScheduleMsg msg = (ScheduleMsg) message;
				Short[] schedule = new Scheduler(nodes).createScheduleArray();	
				if(schedule.length - msg.get_left() != schedule.length) {
					try {
						sendSchedule(schedule, schedule.length - msg.get_left());	
					} catch(Exception e) {}				
				} else {
					printEvent("Schedule spreded!");
					moteIF.deregisterListener(new ScheduleMsg(), scheduleListener);
				}
			}};

	HashMap<Short, Node> nodes = new HashMap<Short, Node>();
	String recivedFrom = "";	

	boolean recivedCalibrationData = false;
	boolean scheduleCreated = false;
	boolean sendSchedule = false;
	boolean scheduleStarted = false;

	int scheduleMsgIndex = 0;

	/*TODO reciving the schedule message to know when to send the next one and to know when she schedule is received by every node.*/

	public RssiReceive(MoteIF moteIF) {		

		this.moteIF = moteIF;
					
		printEvent("Ready");

		while(true) {
			try {
				BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
				String command = br.readLine();

				if(Configuration.COMMAND_STARTCALIBRATION.equals(command)) {					
					initializeNodes();
					this.moteIF.registerListener(new RadioImageMsg(), radioImageListener);							
					CommandMsg msg = new CommandMsg();
					msg.set__command((short) 0);
					moteIF.send(MoteIF.TOS_BCAST_ADDR, msg);
					printEvent("Calibration started!");
				}
				/*else if(command.toUpperCase().startsWith(Configuration.COMMAND_LOADCALIBRATIONDATA)) {
					initializeNodes();
					nodes = readConnectionsFromFile(command.split(" ")[2], Configuration.NUMBER_OF_NODES);
					recivedCalibrationData = true;				
					/*TODO THIS STUFF
				}*/
				else if(Configuration.COMMAND_CREATESCHEDULE.equals(command)) {
					if(!recivedCalibrationData) {
						System.out.println("ERROR - No calibration data collected");
						continue;	
					}
					printEvent("Creating Schedule!");
					Scheduler s = new Scheduler(nodes);
					s.createSchedule();
					String scheduleString = s.createScheduleString();
					System.out.println("Schedule: " + scheduleString + " - Schedule has " + scheduleString.split(" ").length + "hops");
					scheduleCreated = true;
					printEvent("Schedule created!");
				}
				else if(Configuration.COMMAND_SENDSCHEDULE.equals(command)) {
					if(!scheduleCreated) {
						System.out.println("ERROR - No schedule created");
						continue;	
					}
					this.moteIF.registerListener(new ScheduleMsg(), scheduleListener);
					Short[] schedule = new Scheduler(nodes).createScheduleArray();
					try {	
						printEvent("Sending schedule!");
						sendSchedule(schedule, 0);	
					} catch (Exception e) {}			
				}
				else if(Configuration.COMMAND_STARTSCHEDULE.equals(command)) {
					CommandMsg msg = new CommandMsg();
					this.moteIF.registerListener(new RadioImageMsg(), radioImageListener);
					Configuration.PHASE = Configuration.Phase.SAMPLING;
					msg.set__command((short) 1);
					moteIF.send(MoteIF.TOS_BCAST_ADDR, msg);
					printEvent("Schedule started!");
				}
				else if(Configuration.COMMAND_STOPSCHEDULE.equals(command)) {
					System.out.println("RssiReceice is confused... it hurt itself...");
					System.exit(-1);
					/*TODO THIS STUFF*/
				}
				else if(Configuration.COMMAND_HELP.equals(command)) {
					System.out.println("\n--------------------------------Possible Commands------------------------------------");
					System.out.println("|                                                                                   |");
					System.out.println("| " + Configuration.COMMAND_STARTCALIBRATION + " - Collect data about the connections between Notes        |");
					//System.out.println("|  " + Configuration.COMMAND_LOADCALIBRATIONDATA + " <File> - Load data about connections between Notes |");
					System.out.println("| " + Configuration.COMMAND_CREATESCHEDULE + " - Create a schedule                                          |");
					System.out.println("| " + Configuration.COMMAND_SENDSCHEDULE + " - Send the schedule to the notes                               |");
					System.out.println("| " + Configuration.COMMAND_STARTSCHEDULE + " - Start the schedule                                         |");
					System.out.println("| " + Configuration.COMMAND_STOPSCHEDULE + " - Stop the schedule                                          |");
					System.out.println("|                                                                                   |");
					System.out.println("-------------------------------------------------------------------------------------\n");
				} else {
					System.out.println("RssiReceice is confused... it does nothing... 'HELP' could solve the confusion");	
				}
			} catch (Exception e) {System.out.println(e);}
		}
	}

	private void recivedCalibrationMsg(RadioImageMsg radioImageMsg) {
		Node n = nodes.get(radioImageMsg.get_from());
		short[] id = radioImageMsg.get_nodes_id();			

		for(int i = 0; i<Configuration.MAX_NODES_PER_MESSAGE; i++) {
			if(id[i] == 0)
				break;
			
			n.addConnection(nodes.get(id[i]));
		}
		
		if(radioImageMsg.get_motesLeft() == 0) {
			recivedFrom += n.id + " ";
			n.printNodesInRange();
			System.out.println("\n");
		}

		if(n.id == Configuration.ROOT_NODE && radioImageMsg.get_motesLeft() == 0) {
			System.out.println("\n");
			System.out.println("Recived from: " + recivedFrom + "; " + recivedFrom.split(" ").length);			

			evaluateReceivedData(recivedFrom.split(" "));

			printEvent("Calibration Finished!");
			recivedCalibrationData = true;
			this.moteIF.deregisterListener(new RadioImageMsg(), radioImageListener);
		}
	}

	private void evaluateReceivedData(String[] data) {
		for(int i = 1; i<=32; i++) {
			boolean contained = false;
			for(int j = 0; j < data.length; j++) {
				if(data[j].equals(""+i))
					contained = true;
			}
			if(contained == false)
				System.out.println("No data received from node " + i);
		}		
		
		ArrayList<String> processedData = new ArrayList<String>();		
		for(int i = 0; i < data.length; i++) {
			if(!processedData.contains(data[i])) {
				processedData.add(data[i]);
				
				int count = 1;
				for(int j = i+1; j<data.length; j++)
					if(data[j].equals(data[i]))
						count++;
				if(count > 1)
					System.out.println("Node " + i + " send multiple times: " + count + " times");
			}
		}
	}

	private int sendSchedule(Short[] schedule, int index) throws Exception{
		ScheduleMsg msg = new ScheduleMsg();
		int i;
		for(i = 0; i < 28-1 && index+i <schedule.length; i++) {
			msg.setElement_schedule(i, schedule[index+i]);
		}	
		msg.set_left((short) (schedule.length-(index+i)));
		System.out.println("Sending schedule part...");
		moteIF.send(MoteIF.TOS_BCAST_ADDR, msg);
		System.out.println("Schedule part send!");

		return index+i;
	}	

	int roundCounter = 1;

	long startTime = 0;
	boolean running = false;
	private void recivedSamplingMsg(RadioImageMsg radioImageMsg) {
		if(running && startTime != 0) {
			System.out.println("Sampling finnished (Time needed: " + (System.currentTimeMillis()-startTime) + ")");
			running = false;
			startTime = System.currentTimeMillis();
		}		
		if(radioImageMsg.get_from() == (short) 1) {
			System.out.println("Data collection finnished (Time needed: " + (System.currentTimeMillis()-startTime) + ")");
			System.out.println("Round " + roundCounter + " complete!\n\n");
			roundCounter++;
			startTime = System.currentTimeMillis();
			running = true;
		}
	}

	private void initializeNodes() {
		nodes = new HashMap<Short, Node>();
		for(short i = 1; i<Configuration.NUMBER_OF_NODES+1; i++) {
			nodes.put(i, new Node(i));
		}
	}

	public void printEvent(String event) {
		final short charNumber = 85;
		short charsToAdd = (short) ((charNumber-event.length())/2);
		for(int i = 0; i<charsToAdd; i++) {
			event = "-"+event+"-";
		}

		System.out.println("\n"+event+"\n");
	}

	public static void main(String[] args) {
		String source = null;

		if (args.length == 2) {
			if (!args[0].equals("-comm")) {
				System.out.println("arg[0] should be -comm");
				System.exit(1);
			}
			source = args[1];
		}
		else if (args.length != 0) {
			System.out.println("2 arguments are required");
			System.exit(1);
		}

		PhoenixSource phoenix;

		if (source == null) {
			phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
		}
		else {
			phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
		}

		MoteIF mif = new MoteIF(phoenix);

		new RssiReceive(mif);
	}
}
