package net.alexbarry.alexgames.network;

public interface IMsgRecvd {
    public void handle_msg_received(String src, byte[] data, int data_len);
    public void disconnected(String src);
}
