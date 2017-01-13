import java.io.FileWriter;
import java.io.IOException;
import java.util.Vector;

import net.tinyos.message.Message;
import net.tinyos.message.MessageListener;
import net.tinyos.message.MoteIF;
import net.tinyos.packet.NetworkByteSource;
import net.tinyos.util.Dump;

public class RawPrintfListener extends Thread {

	boolean active;
	static String filename = "log/raw_printf.txt";
	NetworkByteSource node;
	int id;
	long start;

	public RawPrintfListener(NetworkByteSource node, int id, long start) {
		active = false;
		this.node = node;
		this.id = id;
		this.start = start;
	}

	protected void activate() {
		active = true;
		try {
			node.open();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		new Thread(this).start();
	}

	protected void deactivate() {
		active = false;
		node.close();
	}

	public void run() {
		int i;
		String message = "";
		try {
			while (this.active && (i = node.readByte()) != -1) {
				if (i != 0x7e) {
					message += (char) i;
				}
				if ((char) i == '\n') {
					long time = System.currentTimeMillis() - start;
					RawPrintfListener.writeToFile(time, id, message);
					message = "";
				}
			}
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	public static synchronized void writeToFile(long time, int mote_id, String message) {
		FileWriter writer;
		try {
			writer = new FileWriter(filename, true);
			writer.write("[ " + mote_id + "\t" + time + "] ");
			writer.write(message);
			writer.flush();
			writer.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
}
