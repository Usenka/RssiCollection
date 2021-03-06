import java.io.File;
import java.util.Enumeration;
import java.util.Vector;

import net.tinyos.message.MoteIF;
import net.tinyos.packet.BuildSource;
import net.tinyos.packet.NetworkByteSource;
import net.tinyos.packet.PhoenixSource;
import net.tinyos.util.PrintStreamMessenger;

public class Launcher {

	private static void printUsageAndExit() {
		System.err.println("help: java Launcher [-comm <source>]+ [-raw]");
		System.exit(-1);
	}

	public static void main(String[] args) {
		int i = 0;
		Vector<String> ports = new Vector<String>();
		boolean raw = false;
		while (i < args.length && args[i].startsWith("-")) {
			String arg = args[i++];
			if (arg.equals("-comm")) {
				if (i < args.length)
					ports.add(args[i++]);
				else
					printUsageAndExit();
			} else if (arg.equals("-raw")) {
				raw = true;
				//System.out.println("RAW mode");
			} else {
				printUsageAndExit();
			}
		}
		if (i != args.length) {
			printUsageAndExit();
		}

		File directory = new File("./log");
		directory.mkdirs();

		long start = System.currentTimeMillis();

		Enumeration<String> el = ports.elements();
		int id = 1;
		//System.out.prinln("started!");
		while (el.hasMoreElements()) {
			if (!raw) {
				PhoenixSource phoenix = BuildSource.makePhoenix(el.nextElement(), PrintStreamMessenger.err);
				PrintfListener listener = new PrintfListener(new MoteIF(phoenix), id++, start);
				listener.activate();
			} else {
				String comm = el.nextElement().split("@")[1];
				String host = comm.split(":")[0];
				int port = Integer.valueOf(comm.split(":")[1]);
				NetworkByteSource source = new NetworkByteSource(host, port);
				RawPrintfListener listener = new RawPrintfListener(source, id++, start);
				listener.activate();
			}
		}
	}
}
