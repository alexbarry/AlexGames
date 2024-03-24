package net.alexbarry.alexgames.util;

public class StringFuncs {
    public static String byteary_to_nice_str(byte[] ary, int msg_len) {
        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append("[");
        for (int i=0; i<ary.length; i++) {
            if (i >= msg_len) { break; }
            if (i != 0) { stringBuilder.append(","); }
            stringBuilder.append(String.format(" %02x", ary[i]));
        }
        stringBuilder.append("]");
        return stringBuilder.toString();
    }
}
