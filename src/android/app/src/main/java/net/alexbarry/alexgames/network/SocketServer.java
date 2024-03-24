package net.alexbarry.alexgames.network;

import android.util.Log;

import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.HashMap;
import java.util.Map;

public class SocketServer {
    private static final String TAG = "SocketServer";

    public interface Callback {
        public void recv(String name, byte[] data, int len);
    }

    private final Map<String, ClientSession> clients = new HashMap<>();

    private int port;
    private ServerSocket server_socket;
    private Callback callback;

    public void init(int port, Callback callback) throws IOException {
        this.port = port;
        this.server_socket = new ServerSocket(port);
        this.callback = callback;
    }

    public void wait_for_clients() throws IOException {
        Log.i(TAG, String.format("Waiting for clients on port %d", port));
        Socket client_socket = server_socket.accept();
        String name = get_client_name(client_socket);
        Log.i(TAG, String.format("Received connection from %s", name));
        ClientSession.Callback recv_handler = new ClientSession.Callback() {
            @Override
            public void recv(byte[] data, int len) {
                callback.recv(name, data, len);
            }

            public void disconnected() {
                Log.i(TAG, String.format("Client %s disconnected", name));
                clients.remove(name);
            }
        };
        ClientSession clientSession = new ClientSession(client_socket, recv_handler);
        clientSession.set_name(name);
        clients.put(name, clientSession);
    }

    private static String get_client_name(Socket socket) {
        return socket.getInetAddress().getHostAddress();
    }

    private void send_msg(ClientSession client, byte[] msg, int msg_len) {
        try {
            client.send_message(msg, msg_len);
        } catch (IOException ex) {
            Log.e(TAG, String.format("Received IO Exception when writing to client %s", client.get_name()), ex);
            // TODO remove client from map?
        }
    }

    public void send_msg(String src, byte[] msg, int msg_len) {
        if (src.equals("all")) {
            for (ClientSession client : clients.values()) {
                send_msg(client, msg, msg_len);
            }
            return;
        }
        // TODO need to protect from concurrency in case this clients map changes after we read it
        if (!clients.containsKey(src)) {
            Log.e(TAG, String.format("Could not find client %s in clients", src));
            return;
        }
        ClientSession client = clients.get(src);
        send_msg(client, msg, msg_len);
    }
}
