package net.alexbarry.alexgames.network;

public interface ISendMsg {
    public void send_msg(String dst, byte[] msg, int msg_len);
}
