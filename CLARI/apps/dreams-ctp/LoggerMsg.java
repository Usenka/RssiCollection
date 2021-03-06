/**
 * This class is automatically generated by mig. DO NOT EDIT THIS FILE.
 * This class implements a Java interface to the 'LoggerMsg'
 * message type.
 */

public class LoggerMsg extends net.tinyos.message.Message {

    /** The default size of this message type in bytes. */
    public static final int DEFAULT_MESSAGE_SIZE = 20;

    /** The Active Message type associated with this message. */
    public static final int AM_TYPE = 7;

    /** Create a new LoggerMsg of size 20. */
    public LoggerMsg() {
        super(DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /** Create a new LoggerMsg of the given data_length. */
    public LoggerMsg(int data_length) {
        super(data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new LoggerMsg with the given data_length
     * and base offset.
     */
    public LoggerMsg(int data_length, int base_offset) {
        super(data_length, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new LoggerMsg using the given byte array
     * as backing store.
     */
    public LoggerMsg(byte[] data) {
        super(data);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new LoggerMsg using the given byte array
     * as backing store, with the given base offset.
     */
    public LoggerMsg(byte[] data, int base_offset) {
        super(data, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new LoggerMsg using the given byte array
     * as backing store, with the given base offset and data length.
     */
    public LoggerMsg(byte[] data, int base_offset, int data_length) {
        super(data, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new LoggerMsg embedded in the given message
     * at the given base offset.
     */
    public LoggerMsg(net.tinyos.message.Message msg, int base_offset) {
        super(msg, base_offset, DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new LoggerMsg embedded in the given message
     * at the given base offset and length.
     */
    public LoggerMsg(net.tinyos.message.Message msg, int base_offset, int data_length) {
        super(msg, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
    /* Return a String representation of this message. Includes the
     * message type name and the non-indexed field values.
     */
    public String toString() {
      String s = "Message <LoggerMsg> \n";
      try {
        s += "  [type=0x"+Long.toHexString(get_type())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [timestamp=0x"+Long.toHexString(get_timestamp())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [log_src=0x"+Long.toHexString(get_log_src())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [src=0x"+Long.toHexString(get_src())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [dst=0x"+Long.toHexString(get_dst())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [seq_num=0x"+Long.toHexString(get_seq_num())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [arg_u8=0x"+Long.toHexString(get_arg_u8())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [arg_u16=0x"+Long.toHexString(get_arg_u16())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [arg_u32=0x"+Long.toHexString(get_arg_u32())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      return s;
    }

    // Message-type-specific access methods appear below.

    /////////////////////////////////////////////////////////
    // Accessor methods for field: type
    //   Field type: short, unsigned
    //   Offset (bits): 0
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'type' is signed (false).
     */
    public static boolean isSigned_type() {
        return false;
    }

    /**
     * Return whether the field 'type' is an array (false).
     */
    public static boolean isArray_type() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'type'
     */
    public static int offset_type() {
        return (0 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'type'
     */
    public static int offsetBits_type() {
        return 0;
    }

    /**
     * Return the value (as a short) of the field 'type'
     */
    public short get_type() {
        return (short)getUIntBEElement(offsetBits_type(), 8);
    }

    /**
     * Set the value of the field 'type'
     */
    public void set_type(short value) {
        setUIntBEElement(offsetBits_type(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'type'
     */
    public static int size_type() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'type'
     */
    public static int sizeBits_type() {
        return 8;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: timestamp
    //   Field type: long, unsigned
    //   Offset (bits): 8
    //   Size (bits): 32
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'timestamp' is signed (false).
     */
    public static boolean isSigned_timestamp() {
        return false;
    }

    /**
     * Return whether the field 'timestamp' is an array (false).
     */
    public static boolean isArray_timestamp() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'timestamp'
     */
    public static int offset_timestamp() {
        return (8 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'timestamp'
     */
    public static int offsetBits_timestamp() {
        return 8;
    }

    /**
     * Return the value (as a long) of the field 'timestamp'
     */
    public long get_timestamp() {
        return (long)getUIntBEElement(offsetBits_timestamp(), 32);
    }

    /**
     * Set the value of the field 'timestamp'
     */
    public void set_timestamp(long value) {
        setUIntBEElement(offsetBits_timestamp(), 32, value);
    }

    /**
     * Return the size, in bytes, of the field 'timestamp'
     */
    public static int size_timestamp() {
        return (32 / 8);
    }

    /**
     * Return the size, in bits, of the field 'timestamp'
     */
    public static int sizeBits_timestamp() {
        return 32;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: log_src
    //   Field type: int, unsigned
    //   Offset (bits): 40
    //   Size (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'log_src' is signed (false).
     */
    public static boolean isSigned_log_src() {
        return false;
    }

    /**
     * Return whether the field 'log_src' is an array (false).
     */
    public static boolean isArray_log_src() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'log_src'
     */
    public static int offset_log_src() {
        return (40 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'log_src'
     */
    public static int offsetBits_log_src() {
        return 40;
    }

    /**
     * Return the value (as a int) of the field 'log_src'
     */
    public int get_log_src() {
        return (int)getUIntBEElement(offsetBits_log_src(), 16);
    }

    /**
     * Set the value of the field 'log_src'
     */
    public void set_log_src(int value) {
        setUIntBEElement(offsetBits_log_src(), 16, value);
    }

    /**
     * Return the size, in bytes, of the field 'log_src'
     */
    public static int size_log_src() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of the field 'log_src'
     */
    public static int sizeBits_log_src() {
        return 16;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: src
    //   Field type: int, unsigned
    //   Offset (bits): 56
    //   Size (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'src' is signed (false).
     */
    public static boolean isSigned_src() {
        return false;
    }

    /**
     * Return whether the field 'src' is an array (false).
     */
    public static boolean isArray_src() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'src'
     */
    public static int offset_src() {
        return (56 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'src'
     */
    public static int offsetBits_src() {
        return 56;
    }

    /**
     * Return the value (as a int) of the field 'src'
     */
    public int get_src() {
        return (int)getUIntBEElement(offsetBits_src(), 16);
    }

    /**
     * Set the value of the field 'src'
     */
    public void set_src(int value) {
        setUIntBEElement(offsetBits_src(), 16, value);
    }

    /**
     * Return the size, in bytes, of the field 'src'
     */
    public static int size_src() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of the field 'src'
     */
    public static int sizeBits_src() {
        return 16;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: dst
    //   Field type: int, unsigned
    //   Offset (bits): 72
    //   Size (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'dst' is signed (false).
     */
    public static boolean isSigned_dst() {
        return false;
    }

    /**
     * Return whether the field 'dst' is an array (false).
     */
    public static boolean isArray_dst() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'dst'
     */
    public static int offset_dst() {
        return (72 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'dst'
     */
    public static int offsetBits_dst() {
        return 72;
    }

    /**
     * Return the value (as a int) of the field 'dst'
     */
    public int get_dst() {
        return (int)getUIntBEElement(offsetBits_dst(), 16);
    }

    /**
     * Set the value of the field 'dst'
     */
    public void set_dst(int value) {
        setUIntBEElement(offsetBits_dst(), 16, value);
    }

    /**
     * Return the size, in bytes, of the field 'dst'
     */
    public static int size_dst() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of the field 'dst'
     */
    public static int sizeBits_dst() {
        return 16;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: seq_num
    //   Field type: int, unsigned
    //   Offset (bits): 88
    //   Size (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'seq_num' is signed (false).
     */
    public static boolean isSigned_seq_num() {
        return false;
    }

    /**
     * Return whether the field 'seq_num' is an array (false).
     */
    public static boolean isArray_seq_num() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'seq_num'
     */
    public static int offset_seq_num() {
        return (88 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'seq_num'
     */
    public static int offsetBits_seq_num() {
        return 88;
    }

    /**
     * Return the value (as a int) of the field 'seq_num'
     */
    public int get_seq_num() {
        return (int)getUIntBEElement(offsetBits_seq_num(), 16);
    }

    /**
     * Set the value of the field 'seq_num'
     */
    public void set_seq_num(int value) {
        setUIntBEElement(offsetBits_seq_num(), 16, value);
    }

    /**
     * Return the size, in bytes, of the field 'seq_num'
     */
    public static int size_seq_num() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of the field 'seq_num'
     */
    public static int sizeBits_seq_num() {
        return 16;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: arg_u8
    //   Field type: short, unsigned
    //   Offset (bits): 104
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'arg_u8' is signed (false).
     */
    public static boolean isSigned_arg_u8() {
        return false;
    }

    /**
     * Return whether the field 'arg_u8' is an array (false).
     */
    public static boolean isArray_arg_u8() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'arg_u8'
     */
    public static int offset_arg_u8() {
        return (104 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'arg_u8'
     */
    public static int offsetBits_arg_u8() {
        return 104;
    }

    /**
     * Return the value (as a short) of the field 'arg_u8'
     */
    public short get_arg_u8() {
        return (short)getUIntBEElement(offsetBits_arg_u8(), 8);
    }

    /**
     * Set the value of the field 'arg_u8'
     */
    public void set_arg_u8(short value) {
        setUIntBEElement(offsetBits_arg_u8(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'arg_u8'
     */
    public static int size_arg_u8() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'arg_u8'
     */
    public static int sizeBits_arg_u8() {
        return 8;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: arg_u16
    //   Field type: int, unsigned
    //   Offset (bits): 112
    //   Size (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'arg_u16' is signed (false).
     */
    public static boolean isSigned_arg_u16() {
        return false;
    }

    /**
     * Return whether the field 'arg_u16' is an array (false).
     */
    public static boolean isArray_arg_u16() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'arg_u16'
     */
    public static int offset_arg_u16() {
        return (112 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'arg_u16'
     */
    public static int offsetBits_arg_u16() {
        return 112;
    }

    /**
     * Return the value (as a int) of the field 'arg_u16'
     */
    public int get_arg_u16() {
        return (int)getUIntBEElement(offsetBits_arg_u16(), 16);
    }

    /**
     * Set the value of the field 'arg_u16'
     */
    public void set_arg_u16(int value) {
        setUIntBEElement(offsetBits_arg_u16(), 16, value);
    }

    /**
     * Return the size, in bytes, of the field 'arg_u16'
     */
    public static int size_arg_u16() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of the field 'arg_u16'
     */
    public static int sizeBits_arg_u16() {
        return 16;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: arg_u32
    //   Field type: long, unsigned
    //   Offset (bits): 128
    //   Size (bits): 32
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'arg_u32' is signed (false).
     */
    public static boolean isSigned_arg_u32() {
        return false;
    }

    /**
     * Return whether the field 'arg_u32' is an array (false).
     */
    public static boolean isArray_arg_u32() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'arg_u32'
     */
    public static int offset_arg_u32() {
        return (128 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'arg_u32'
     */
    public static int offsetBits_arg_u32() {
        return 128;
    }

    /**
     * Return the value (as a long) of the field 'arg_u32'
     */
    public long get_arg_u32() {
        return (long)getUIntBEElement(offsetBits_arg_u32(), 32);
    }

    /**
     * Set the value of the field 'arg_u32'
     */
    public void set_arg_u32(long value) {
        setUIntBEElement(offsetBits_arg_u32(), 32, value);
    }

    /**
     * Return the size, in bytes, of the field 'arg_u32'
     */
    public static int size_arg_u32() {
        return (32 / 8);
    }

    /**
     * Return the size, in bits, of the field 'arg_u32'
     */
    public static int sizeBits_arg_u32() {
        return 32;
    }

}
