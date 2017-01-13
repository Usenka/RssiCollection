import net.tinyos.message.*;

import java.io.IOException;
import java.util.Enumeration;
import java.util.Vector;

public class SerialComm extends Thread implements MessageListener {

	private Vector<MoteIF> nodes;
	private PrintfListener printf_listener;
	private boolean active;
	private Vector<Message> msgs;

	public SerialComm(Vector<MoteIF> nodes, 
			PrintfListener printf_listener) {
		this.nodes = nodes;
		this.printf_listener = printf_listener;
		this.active = false;
		this.msgs = new Vector<Message>();
	}

	public Vector<MoteIF> getSerials() {
		return nodes;
	}

	public void activate() {
		active = true;
		printf_listener.activate();
		Enumeration<MoteIF> el = nodes.elements();
		while (el.hasMoreElements()) {
			MoteIF node = el.nextElement();
                        node.registerListener(new PrintfMsg(), this);
		}
		new Thread(this).start();
	}

	public void deactivate() {
		Enumeration<MoteIF> el = nodes.elements();
		while (el.hasMoreElements()) {
			MoteIF node = el.nextElement();
                        node.deregisterListener(new PrintfMsg(), this);
		}
		active = false;
                printf_listener.deactivate();
		synchronized (msgs) {
			msgs.clear();
		}
		el = nodes.elements();
		while (el.hasMoreElements()) {
			el.nextElement().getSource().shutdown();
		}
	}

	public void messageReceived(int to, Message message) {
		synchronized (msgs) {
			msgs.add(message);
			msgs.notifyAll();
		}
	}

	public void sendToAll(Message msg) {
		try {
			Enumeration<MoteIF> el = nodes.elements();
			while (el.hasMoreElements()) {
				el.nextElement().send(MoteIF.TOS_BCAST_ADDR, msg);
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	public void sendToOne(Message msg) {
		try {
			Enumeration<MoteIF> el = nodes.elements();
			if (el.hasMoreElements())
				el.nextElement().send(MoteIF.TOS_BCAST_ADDR, msg);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	public void sendTo(Message msg, MoteIF mote) {
		try {
			if (mote != null)
				mote.send(MoteIF.TOS_BCAST_ADDR, msg);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	public void run() {
		while (this.active) {
			Message message = null;
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
				if (message instanceof PrintfMsg) {
					//printf_listener.messageReceived((PrintfMsg) message);
				}
			}
		}
	}

}
