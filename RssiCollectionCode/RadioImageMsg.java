/**
 * This class is automatically generated by mig. DO NOT EDIT THIS FILE.
 * This class implements a Java interface to the 'RadioImageMsg'
 * message type.
 */

public class RadioImageMsg extends net.tinyos.message.Message {

    /** The default size of this message type in bytes. */
    public static final int DEFAULT_MESSAGE_SIZE = 27;

    /** The Active Message type associated with this message. */
    public static final int AM_TYPE = 137;

    /** Create a new RadioImageMsg of size 27. */
    public RadioImageMsg() {
        super(DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /** Create a new RadioImageMsg of the given data_length. */
    public RadioImageMsg(int data_length) {
        super(data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new RadioImageMsg with the given data_length
     * and base offset.
     */
    public RadioImageMsg(int data_length, int base_offset) {
        super(data_length, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new RadioImageMsg using the given byte array
     * as backing store.
     */
    public RadioImageMsg(byte[] data) {
        super(data);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new RadioImageMsg using the given byte array
     * as backing store, with the given base offset.
     */
    public RadioImageMsg(byte[] data, int base_offset) {
        super(data, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new RadioImageMsg using the given byte array
     * as backing store, with the given base offset and data length.
     */
    public RadioImageMsg(byte[] data, int base_offset, int data_length) {
        super(data, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new RadioImageMsg embedded in the given message
     * at the given base offset.
     */
    public RadioImageMsg(net.tinyos.message.Message msg, int base_offset) {
        super(msg, base_offset, DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new RadioImageMsg embedded in the given message
     * at the given base offset and length.
     */
    public RadioImageMsg(net.tinyos.message.Message msg, int base_offset, int data_length) {
        super(msg, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
    /* Return a String representation of this message. Includes the
     * message type name and the non-indexed field values.
     */
    public String toString() {
      String s = "Message <RadioImageMsg> \n";
      try {
        s += "  [from=0x"+Long.toHexString(get_from())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [request_id=0x"+Long.toHexString(get_request_id())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [motesLeft=0x"+Long.toHexString(get_motesLeft())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [nodes.id=";
        for (int i = 0; i < 12; i++) {
          s += "0x"+Long.toHexString(getElement_nodes_id(i) & 0xff)+" ";
        }
        s += "]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [nodes.rssi=";
        for (int i = 0; i < 12; i++) {
          s += "0x"+Long.toHexString(getElement_nodes_rssi(i) & 0xff)+" ";
        }
        s += "]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      return s;
    }

    // Message-type-specific access methods appear below.

    /////////////////////////////////////////////////////////
    // Accessor methods for field: from
    //   Field type: short
    //   Offset (bits): 0
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'from' is signed (false).
     */
    public static boolean isSigned_from() {
        return false;
    }

    /**
     * Return whether the field 'from' is an array (false).
     */
    public static boolean isArray_from() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'from'
     */
    public static int offset_from() {
        return (0 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'from'
     */
    public static int offsetBits_from() {
        return 0;
    }

    /**
     * Return the value (as a short) of the field 'from'
     */
    public short get_from() {
        return (short)getUIntBEElement(offsetBits_from(), 8);
    }

    /**
     * Set the value of the field 'from'
     */
    public void set_from(short value) {
        setUIntBEElement(offsetBits_from(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'from'
     */
    public static int size_from() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'from'
     */
    public static int sizeBits_from() {
        return 8;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: request_id
    //   Field type: short
    //   Offset (bits): 8
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'request_id' is signed (false).
     */
    public static boolean isSigned_request_id() {
        return false;
    }

    /**
     * Return whether the field 'request_id' is an array (false).
     */
    public static boolean isArray_request_id() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'request_id'
     */
    public static int offset_request_id() {
        return (8 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'request_id'
     */
    public static int offsetBits_request_id() {
        return 8;
    }

    /**
     * Return the value (as a short) of the field 'request_id'
     */
    public short get_request_id() {
        return (short)getUIntBEElement(offsetBits_request_id(), 8);
    }

    /**
     * Set the value of the field 'request_id'
     */
    public void set_request_id(short value) {
        setUIntBEElement(offsetBits_request_id(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'request_id'
     */
    public static int size_request_id() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'request_id'
     */
    public static int sizeBits_request_id() {
        return 8;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: motesLeft
    //   Field type: short
    //   Offset (bits): 16
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'motesLeft' is signed (false).
     */
    public static boolean isSigned_motesLeft() {
        return false;
    }

    /**
     * Return whether the field 'motesLeft' is an array (false).
     */
    public static boolean isArray_motesLeft() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'motesLeft'
     */
    public static int offset_motesLeft() {
        return (16 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'motesLeft'
     */
    public static int offsetBits_motesLeft() {
        return 16;
    }

    /**
     * Return the value (as a short) of the field 'motesLeft'
     */
    public short get_motesLeft() {
        return (short)getUIntBEElement(offsetBits_motesLeft(), 8);
    }

    /**
     * Set the value of the field 'motesLeft'
     */
    public void set_motesLeft(short value) {
        setUIntBEElement(offsetBits_motesLeft(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'motesLeft'
     */
    public static int size_motesLeft() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'motesLeft'
     */
    public static int sizeBits_motesLeft() {
        return 8;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: nodes.id
    //   Field type: short[]
    //   Offset (bits): 0
    //   Size of each element (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'nodes.id' is signed (false).
     */
    public static boolean isSigned_nodes_id() {
        return false;
    }

    /**
     * Return whether the field 'nodes.id' is an array (true).
     */
    public static boolean isArray_nodes_id() {
        return true;
    }

    /**
     * Return the offset (in bytes) of the field 'nodes.id'
     */
    public static int offset_nodes_id(int index1) {
        int offset = 0;
        if (index1 < 0 || index1 >= 12) throw new ArrayIndexOutOfBoundsException();
        offset += 24 + index1 * 16;
        return (offset / 8);
    }

    /**
     * Return the offset (in bits) of the field 'nodes.id'
     */
    public static int offsetBits_nodes_id(int index1) {
        int offset = 0;
        if (index1 < 0 || index1 >= 12) throw new ArrayIndexOutOfBoundsException();
        offset += 24 + index1 * 16;
        return offset;
    }

    /**
     * Return the entire array 'nodes.id' as a short[]
     */
    public short[] get_nodes_id() {
        short[] tmp = new short[12];
        for (int index0 = 0; index0 < numElements_nodes_id(0); index0++) {
            tmp[index0] = getElement_nodes_id(index0);
        }
        return tmp;
    }

    /**
     * Set the contents of the array 'nodes.id' from the given short[]
     */
    public void set_nodes_id(short[] value) {
        for (int index0 = 0; index0 < value.length; index0++) {
            setElement_nodes_id(index0, value[index0]);
        }
    }

    /**
     * Return an element (as a short) of the array 'nodes.id'
     */
    public short getElement_nodes_id(int index1) {
        return (short)getUIntBEElement(offsetBits_nodes_id(index1), 8);
    }

    /**
     * Set an element of the array 'nodes.id'
     */
    public void setElement_nodes_id(int index1, short value) {
        setUIntBEElement(offsetBits_nodes_id(index1), 8, value);
    }

    /**
     * Return the total size, in bytes, of the array 'nodes.id'
     */
    public static int totalSize_nodes_id() {
        return (192 / 8);
    }

    /**
     * Return the total size, in bits, of the array 'nodes.id'
     */
    public static int totalSizeBits_nodes_id() {
        return 192;
    }

    /**
     * Return the size, in bytes, of each element of the array 'nodes.id'
     */
    public static int elementSize_nodes_id() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of each element of the array 'nodes.id'
     */
    public static int elementSizeBits_nodes_id() {
        return 8;
    }

    /**
     * Return the number of dimensions in the array 'nodes.id'
     */
    public static int numDimensions_nodes_id() {
        return 1;
    }

    /**
     * Return the number of elements in the array 'nodes.id'
     */
    public static int numElements_nodes_id() {
        return 12;
    }

    /**
     * Return the number of elements in the array 'nodes.id'
     * for the given dimension.
     */
    public static int numElements_nodes_id(int dimension) {
      int array_dims[] = { 12,  };
        if (dimension < 0 || dimension >= 1) throw new ArrayIndexOutOfBoundsException();
        if (array_dims[dimension] == 0) throw new IllegalArgumentException("Array dimension "+dimension+" has unknown size");
        return array_dims[dimension];
    }

    /**
     * Fill in the array 'nodes.id' with a String
     */
    public void setString_nodes_id(String s) { 
         int len = s.length();
         int i;
         for (i = 0; i < len; i++) {
             setElement_nodes_id(i, (short)s.charAt(i));
         }
         setElement_nodes_id(i, (short)0); //null terminate
    }

    /**
     * Read the array 'nodes.id' as a String
     */
    public String getString_nodes_id() { 
         char carr[] = new char[Math.min(net.tinyos.message.Message.MAX_CONVERTED_STRING_LENGTH,12)];
         int i;
         for (i = 0; i < carr.length; i++) {
             if ((char)getElement_nodes_id(i) == (char)0) break;
             carr[i] = (char)getElement_nodes_id(i);
         }
         return new String(carr,0,i);
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: nodes.rssi
    //   Field type: byte[]
    //   Offset (bits): 8
    //   Size of each element (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'nodes.rssi' is signed (false).
     */
    public static boolean isSigned_nodes_rssi() {
        return false;
    }

    /**
     * Return whether the field 'nodes.rssi' is an array (true).
     */
    public static boolean isArray_nodes_rssi() {
        return true;
    }

    /**
     * Return the offset (in bytes) of the field 'nodes.rssi'
     */
    public static int offset_nodes_rssi(int index1) {
        int offset = 8;
        if (index1 < 0 || index1 >= 12) throw new ArrayIndexOutOfBoundsException();
        offset += 24 + index1 * 16;
        return (offset / 8);
    }

    /**
     * Return the offset (in bits) of the field 'nodes.rssi'
     */
    public static int offsetBits_nodes_rssi(int index1) {
        int offset = 8;
        if (index1 < 0 || index1 >= 12) throw new ArrayIndexOutOfBoundsException();
        offset += 24 + index1 * 16;
        return offset;
    }

    /**
     * Return the entire array 'nodes.rssi' as a byte[]
     */
    public byte[] get_nodes_rssi() {
        byte[] tmp = new byte[12];
        for (int index0 = 0; index0 < numElements_nodes_rssi(0); index0++) {
            tmp[index0] = getElement_nodes_rssi(index0);
        }
        return tmp;
    }

    /**
     * Set the contents of the array 'nodes.rssi' from the given byte[]
     */
    public void set_nodes_rssi(byte[] value) {
        for (int index0 = 0; index0 < value.length; index0++) {
            setElement_nodes_rssi(index0, value[index0]);
        }
    }

    /**
     * Return an element (as a byte) of the array 'nodes.rssi'
     */
    public byte getElement_nodes_rssi(int index1) {
        return (byte)getSIntBEElement(offsetBits_nodes_rssi(index1), 8);
    }

    /**
     * Set an element of the array 'nodes.rssi'
     */
    public void setElement_nodes_rssi(int index1, byte value) {
        setSIntBEElement(offsetBits_nodes_rssi(index1), 8, value);
    }

    /**
     * Return the total size, in bytes, of the array 'nodes.rssi'
     */
    public static int totalSize_nodes_rssi() {
        return (192 / 8);
    }

    /**
     * Return the total size, in bits, of the array 'nodes.rssi'
     */
    public static int totalSizeBits_nodes_rssi() {
        return 192;
    }

    /**
     * Return the size, in bytes, of each element of the array 'nodes.rssi'
     */
    public static int elementSize_nodes_rssi() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of each element of the array 'nodes.rssi'
     */
    public static int elementSizeBits_nodes_rssi() {
        return 8;
    }

    /**
     * Return the number of dimensions in the array 'nodes.rssi'
     */
    public static int numDimensions_nodes_rssi() {
        return 1;
    }

    /**
     * Return the number of elements in the array 'nodes.rssi'
     */
    public static int numElements_nodes_rssi() {
        return 12;
    }

    /**
     * Return the number of elements in the array 'nodes.rssi'
     * for the given dimension.
     */
    public static int numElements_nodes_rssi(int dimension) {
      int array_dims[] = { 12,  };
        if (dimension < 0 || dimension >= 1) throw new ArrayIndexOutOfBoundsException();
        if (array_dims[dimension] == 0) throw new IllegalArgumentException("Array dimension "+dimension+" has unknown size");
        return array_dims[dimension];
    }

    /**
     * Fill in the array 'nodes.rssi' with a String
     */
    public void setString_nodes_rssi(String s) { 
         int len = s.length();
         int i;
         for (i = 0; i < len; i++) {
             setElement_nodes_rssi(i, (byte)s.charAt(i));
         }
         setElement_nodes_rssi(i, (byte)0); //null terminate
    }

    /**
     * Read the array 'nodes.rssi' as a String
     */
    public String getString_nodes_rssi() { 
         char carr[] = new char[Math.min(net.tinyos.message.Message.MAX_CONVERTED_STRING_LENGTH,12)];
         int i;
         for (i = 0; i < carr.length; i++) {
             if ((char)getElement_nodes_rssi(i) == (char)0) break;
             carr[i] = (char)getElement_nodes_rssi(i);
         }
         return new String(carr,0,i);
    }

}