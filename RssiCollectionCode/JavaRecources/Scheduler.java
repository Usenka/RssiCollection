package JavaRecources;

import java.util.*;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;

public class Scheduler {
	HashMap<Short,Node> nodeList;	
	ArrayList<NodeCircle> circleList;

	public Scheduler(HashMap<Short,Node> nodeList) {
		this.nodeList = nodeList;
	}

	public void createSchedule() {
		circleList = new ArrayList<NodeCircle>();
		circlesAroundRoot(nodeList.get(Configuration.ROOT_NODE));
		
		for(int i = 0; i < circleList.size(); i++) {
			NodeCircle circle = circleList.get(i);
			for(Node node: circle.followingNodes) {
					if(circlesAroundRoot(node) > 0) {
						Node.PredecessorSuccessor remove = node.nextNodes.get(0);	
						Node.PredecessorSuccessor updatePredecessor = node.findPredecessor(null);
						Node.PredecessorSuccessor updateSuccessor = node.findSuccessor(null);

						updatePredecessor.predecessor = remove.predecessor;
						updateSuccessor.successor = remove.successor;
						node.nextNodes.remove(remove); 
					}			
			}
		}
	}
	
	/*Circle gets ccreated backwrds, return number of circles*/
	private int circlesAroundRoot(Node root) {
		Node lastNode = null;
		Node firstInnerPredecessor = null;
		int numberOfCircles = 0;
		Node n;	
		while((n = getBestNextNode(root, root)) != null) {
			if(!n.hasNext() && n.hasInRange(root)) {
				numberOfCircles++;
				NodeCircle circle = new NodeCircle(root);
				firstInnerPredecessor = finishCircle(n,circle.root,circle);
				root.addPredecessorSuccessor(lastNode, firstInnerPredecessor);
				lastNode = n;
				circleList.add(circle);
				System.out.println("Circle: " + circle.root + " -> " + circle.followingNodes);		 			
			}
		}
		if(firstInnerPredecessor != null)
			root.addPredecessorSuccessor(lastNode, null); /*TODO HERE IS AM ERROR */

		return numberOfCircles;
	}

	/*Returns the last Node of the Circle*/
	private Node finishCircle(Node node, Node before, NodeCircle circle) {
		circle.followingNodes.add(node);
		Node n;		
		while((n = getBestNextNode(node, circle.root)) != null) {
			node.addPredecessorSuccessor(n, before);
			return finishCircle(n, node, circle);
			/*if(n.hasPredecessor(root)) {
				n.changePredecessor(root, n);
			}*/
		}
		node.addPredecessorSuccessor(circle.root, before);
		return node;
	}

	private Node getBestNextNode(Node current, Node root) {
		int bestRssi = 1;
		Node currentBest = null;

		for(Node n : current.nodesInRange) {
			//System.out.println("ID:  " + n.id);
			if(n.hasInRange(root) && !n.hasNext()) {
				int rssi = current.getLastMeasurement(n.id) + n.getLastMeasurement(root.id);
				//System.out.println("RSSI vergleich: " + rssi + " > " + bestRssi);
				if(rssi > bestRssi || bestRssi == 1) {
					bestRssi = rssi;
					currentBest = n;
				}
			}
		}
		//System.out.println("Best is: " + currentBest);
		return currentBest;
	}

	public String createScheduleString() {		
		NodeSave nodeSave = new NodeSave();
		String schedule = "";
		Node.PredecessorSuccessor ps;
		Node n = nodeList.get((short) 1);
		nodeSave.node = n;
		System.out.println(n);	
		schedule += n;
		for (ps = n.nextNodes.get(0); ps.successor != null; ps = getNext(nodeSave,ps)) {					
			schedule += " " +ps.successor;
		}

		return schedule;
	}

	public Short[] createScheduleArray() {		
		NodeSave nodeSave = new NodeSave();
		ArrayList<Short> schedule = new ArrayList<Short>();
		Node.PredecessorSuccessor ps;
		Node n = nodeList.get((short) 1);
		nodeSave.node = n;
		System.out.println(n);	
		schedule.add(n.id);
		
		for (ps = n.nextNodes.get(0); ps.successor != null; ps = getNext(nodeSave,ps)) {					
			schedule.add(ps.successor.id);
		}
		
		return schedule.toArray(new Short[schedule.size()]);
	}

	private Node.PredecessorSuccessor getNext(NodeSave nodeSave, Node.PredecessorSuccessor ps) {
		Node n = ps.successor;
		if(n == null)
			return null;
		for (Node.PredecessorSuccessor f_ps : n.nextNodes) {
			if(f_ps.predecessor == nodeSave.node) {
				nodeSave.node = n;				
				return f_ps;
			}
		}
		return null;
	}
/*=========================================================================================================================================================================*/
	private class NodeSave {
		public Node node;
	}

	public class NodeCircle {
		public Node root;
		public ArrayList<Node> followingNodes = new ArrayList<Node>();
		public boolean isRooted = true;

		public NodeCircle(Node root) {
			this.root = root;
		}		
	}

	public static void main(String[] args) {
		HashMap<Short, Node> nodes = readConnectionsFromFile("Connections.txt",32);		
			
		/*HashMap<Short, Node> nodes = new HashMap<Short, Node>();
		
		for(short i = 1; i<=5; i++) {
			Node n = new Node(i);			
			nodes.put(i, n);	
		}

		Node n1 = nodes.get((short) 1);
		Node n2 = nodes.get((short) 2);
		Node n3 = nodes.get((short) 3);
		Node n4 = nodes.get((short) 4);
		Node n5 = nodes.get((short) 5);
	
		/*Bei neuem knoten schauen ob dieser einen nachbarn hat der den root als nachbarn hat*/

		/*n1.nodesInRange.add(n2);
		n1.nodesInRange.add(n3);
		n1.nodesInRange.add(n4);
		n1.nodesInRange.add(n5);

		n2.nodesInRange.add(n3);
		n2.nodesInRange.add(n1);
		n2.nodesInRange.add(n4);

		n3.nodesInRange.add(n2);
		n3.nodesInRange.add(n1);
		n3.nodesInRange.add(n4);
		n3.nodesInRange.add(n5);

		n4.nodesInRange.add(n1);
		n4.nodesInRange.add(n2);
		n4.nodesInRange.add(n3);

		n5.nodesInRange.add(n1);
		n5.nodesInRange.add(n3);*/

		Scheduler s = new Scheduler(nodes);
		s.createSchedule();
		String schedule = s.createScheduleString();

		for(Node n : nodes.values())
			System.out.println(n + ": " + n.nextNodes);

		System.out.println(schedule);


	}

	private static HashMap<Short, Node> readConnectionsFromFile(String filepath, int nodeCount) {
		HashMap<Short, Node> nodes = new HashMap<Short, Node>();
		
		for(short i = 1; i<=nodeCount; i++) {
			Node n = new Node(i);			
			nodes.put(i, n);	
		}		

		try {		
			BufferedReader reader = new BufferedReader(new FileReader(filepath));
			String currentLine;
		
			short lineCounter = 1;
			for(currentLine = reader.readLine(); currentLine != null; currentLine = reader.readLine()) {
				Node node = nodes.get(lineCounter);
				
				String[] connections = currentLine.split(" ");
				for(String connection : connections) {
					node.nodesInRange.add(nodes.get(new Short(connection)));
				}
				//System.out.println(node.nodesInRange);
				lineCounter++;
			}

		} catch(IOException e) {

		}

		return nodes;
	}
}
