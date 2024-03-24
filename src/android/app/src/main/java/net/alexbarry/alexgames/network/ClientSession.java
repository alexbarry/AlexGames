package net.alexbarry.alexgames.network;

import android.util.Log;

import net.alexbarry.alexgames.util.StringFuncs;

import java.io.IOException;
import java.net.Socket;

public class ClientSession {

    private static final String TAG = "ClientSession";

    public interface Callback {
        void recv(byte[] data, int len);
        void disconnected();
    }

    private final Runnable thread_handler = new Runnable() {
        @Override
        public void run() {
            byte[] buff = new byte[4096];
            while (true) {
                try {
                    int len = recv_data(buff);
                    if (len <= 0) {
                        break;
                    }
                    callback.recv(buff, len);
                } catch (IOException e) {
                    Log.e(TAG, "IOException reading from socket", e);
                    callback.disconnected();
                    break;
                }
            }
        }
    };
    private final Thread thread = new Thread(thread_handler);

    private final Socket socket;
    private final Callback callback;
    private String name;


    public static ClientSession createFromAddr(String addr, int port, Callback callback) throws IOException {
        Socket socket = new Socket(addr, port);
        return new ClientSession(socket, callback);
    }

    void set_name(String name) {
        this.name = name;
    }


    ClientSession(Socket socket, Callback callback) {
        this.socket = socket;
        this.callback = callback;
        thread.start();
    }

    public void send_message(byte[] data, int len) throws IOException {
        Log.d(TAG, String.format("Sending msg to %s: %s",
                get_name(), StringFuncs.byteary_to_nice_str(data, len)));
        this.socket.getOutputStream().write(data, 0, len);
        this.socket.getOutputStream().flush();
    }

    private int recv_data(byte[] buff) throws IOException {
        return this.socket.getInputStream().read(buff);
    }

    public String get_name() {
        return this.name;
    }
}
