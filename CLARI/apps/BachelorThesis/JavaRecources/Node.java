package JavaRecources;

import java.util.*;

public class Node {
	public final short id;

	public final ArrayList<Node> nodesInRange = new ArrayList<Node>();
	private final HashMap<Short, NodeRSSIPair> measurements = new HashMap <Short, NodeRSSIPair>();
	public final ArrayList<PredecessorSuccessor> nextNodes = new ArrayList<PredecessorSuccessor>();

	public Node(short id) {
		this.id = id;
	}

	
	public void addConnection(Node n) {
		if(!nodesInRange.contains(n)) {
			nodesInRange.add(n);
			measurements.put(n.id, new NodeRSSIPair(n));
		}
	}

	public void printNodesInRange() {
		for(Node n : nodesInRange) {
			System.out.print(n.id + " ");
		}
		System.out.print("\n");
	}

	public void addPredecessorSuccessor(Node predecessor, Node successor) {
		nextNodes.add(new PredecessorSuccessor(predecessor, successor));
	}

	public boolean hasInRange(Node n) {
		return nodesInRange.contains(n);
	}

	public boolean hasNext() {
		return nextNodes.size() != 0;
	}

	public boolean hasPredecessor(Node n) {
		for(PredecessorSuccessor ps : nextNodes)
			if(ps.predecessor == n)
				return true;

		return false;
	}

	public void changePredecessor(Node predecessor, Node newPredecessor) {
		for(PredecessorSuccessor ps : nextNodes)
			if(ps.predecessor == predecessor)
				ps.predecessor = newPredecessor;
	}

	public PredecessorSuccessor findPredecessor(Node n) {
		for(PredecessorSuccessor ps : nextNodes)
			if(ps.predecessor == n)
				return ps;
		return null;
	}

	public PredecessorSuccessor findSuccessor(Node n) {
		for(PredecessorSuccessor ps : nextNodes)
			if(ps.successor == n)
				return ps;
		return null;	
	}
/*=======================================================================================================*/
	public class NodeRSSIPair {
		public final Node node;
		public final ArrayList<Integer> measurements;

		public NodeRSSIPair(Node node) {
			this.node = node;
			this.measurements = new ArrayList<Integer>();
		}
	}

	public class PredecessorSuccessor {
		public Node predecessor;
		public Node successor;

		public PredecessorSuccessor(Node predecessor, Node successor) {
			this.predecessor = predecessor;
			this.successor = successor;
		}

		public String toString() {
			return "[" + predecessor + ";" + successor + "]";
		}
	}

	public String toString() {
		return ""+id;
	}
}
