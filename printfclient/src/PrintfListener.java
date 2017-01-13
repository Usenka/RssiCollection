import java.io.FileWriter;
import java.io.IOException;
import java.util.Vector;

import net.tinyos.message.Message;
import net.tinyos.message.MessageListener;
import net.tinyos.message.MoteIF;

public class PrintfListener extends Thread implements MessageListener {

	boolean active;
	Vector<PrintfMsg> msgs;
	static String filename = "log/printf.txt";
	
	static boolean moteFilesInitialized = false;
	static String[] moteFiles = new String[33];

	MoteIF node;
	int id;
	long start;

	public PrintfListener(MoteIF node, int id, long start) {
		active = false;
		msgs = new Vector<PrintfMsg>();
		this.node = node;
		this.id = id;
		this.start = start;
		
		if (moteFilesInitialized == false) { 
			for(int i = 0; i<33; i++) {
				moteFiles[i] = "log/motes/m_"+i+"_printf.txt";
			} 
			moteFilesInitialized = true;
		}
	}

	public void messageReceived(int to, Message message) {
		synchronized (msgs) {
			msgs.add((PrintfMsg) message);
			msgs.notifyAll();
		}
	}

	protected void activate() {
		node.registerListener(new PrintfMsg(), this);
		active = true;
		new Thread(this).start();
	}

	protected void deactivate() {
		active = false;
		node.deregisterListener(new PrintfMsg(), this);
		synchronized (msgs) {
			msgs.clear();
		}
		node.getSource().shutdown();
	}

	public void run() {
		while (this.active) {
			PrintfMsg message = null;
			synchronized (msgs) {
				if (!msgs.isEmpty()) {
					message = msgs.remove(0);
				} else {
					try {
						msgs.wait();
					} catch (InterruptedException e) {
						e.printStackTrace();
					}
				}
			}
			if (message != null) {
				long time = System.currentTimeMillis() - start;
				PrintfListener.writeToFile(time, id, message);
			}
		}
	}

	public static synchronized void writeToFile(long time, int mote_id, PrintfMsg message) {
		FileWriter writer;
		FileWriter m_writer;
		try {
			writer = new FileWriter(filename, true);
			m_writer = new FileWriter(moteFiles[mote_id], true);
			writer.write("[ " + mote_id + "\t" + time + "] ");
			m_writer.write("[" + time + "] ");
			for (int i = 0; i < message.get_buffer().length; i++) {
				char nextChar = (char) (message.get_buffer()[i]);
				if (nextChar != 0) {
					writer.write(nextChar);
					m_writer.write(nextChar);
				}
			}
			writer.flush();
			m_writer.flush();
			writer.close();
			m_writer.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
}
