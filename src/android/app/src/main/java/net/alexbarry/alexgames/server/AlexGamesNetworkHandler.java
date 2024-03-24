package net.alexbarry.alexgames.server;

import static net.alexbarry.alexgames.util.StringFuncs.byteary_to_nice_str;

import android.util.Log;

import net.alexbarry.alexgames.AlexGamesJni;
import net.alexbarry.alexgames.network.ClientSession;
import net.alexbarry.alexgames.network.IMsgRecvd;
import net.alexbarry.alexgames.network.ISendMsg;
import net.alexbarry.alexgames.network.SocketServer;

import java.io.IOException;
import java.net.Socket;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;

/**
 * I think this is a socket server used only by the NDK implementation of AlexGames.
 * It is not needed to host a web (HTTP and websockets) server, for people to play
 * with each other (and optionally you, using a browser on your phone, connecting
 * to the same URL as the rest of them (or probably "localhost")).
 *
 * The NDK implementation of AlexGames is more of a proof of concept than a real
 * playable thing at the moment. This socket server is even more of a proof of
 * concept and less useful.
 *
 * The web version uses websockets, but I wanted to make sure that using
 * "normal" sockets would still work, and that I could achieve cross platform
 * play between an Android device and a wxWidgets program, with a normal socket
 * server hosted on either.
 *
 * Ideally every server could both host a (regular) socket and websocket server, then
 * clients of either kind could connect, and then non web clients would not need
 * to include a websocket client library.
 * But it is probably far more practical to just stick to a single type of server.
 *
 * I am writing this comment a long time after having written this code and really using the
 * Android app at all. It may be inaccurate.
 *
 * This class also seems to be poorly named. It is not needed if you are hosting a web games server,
 * it is only meant if you are playing on the NDK implementation and want to host your own socket
 * server to play with other Android NDK or wxWidget clients (which support regular sockets).
 */
public class AlexGamesNetworkHandler {
    private static final String TAG = "MainServer";
    private BlockingQueue<Runnable> network_queue = new LinkedBlockingQueue<>();
    private Runnable network_thread_handler = new Runnable() {
        @Override
        public void run() {
            while (true) {
                Runnable r;
                try {
                    r = network_queue.take();
                } catch (InterruptedException ex) {
                    Log.e(TAG, "interrupt exeception", ex);
                    break;
                }
                r.run();
            }
        }
    };
    private final Thread network_thread = new Thread(network_thread_handler);
    private ISendMsg send_msg;


        public void init(IMsgRecvd msg_received_callback) {

        network_thread.start();
        boolean is_host = true;

        if (is_host) {
            SocketServer.Callback callback = new SocketServer.Callback() {
                @Override
                public void recv(String name, byte[] data, int len) {
                    msg_received_callback.handle_msg_received(name, data, len);
                }
            };

            SocketServer server = new SocketServer();
            // To allow clients outside the emulator to connect to this port, run:
            //     adb forward tcp:55123 tcp:55123
            try {
                server.init(55123, callback);
            } catch (IOException ex) {
                Log.e(TAG, "io exception in server.init", ex);
            }
            Thread server_thread = new Thread(new Runnable() {
                @Override
                public void run() {
                    try {
                        server.wait_for_clients();
                    } catch (IOException e) {
                        Log.e(TAG, "io exception waiting for clients", e);
                        //return;
                    }
                }
            });
            send_msg = new ISendMsg() {
                @Override
                public void send_msg(String dst, byte[] msg, int msg_len) {
                    server.send_msg(dst, msg, msg_len);
                }
            };
            server_thread.start();
        } else {
            ClientSession.Callback callback = new ClientSession.Callback() {
                @Override
                public void recv(byte[] data, int len) {
                    msg_received_callback.handle_msg_received("host", data, len);
                }

                @Override
                public void disconnected() {
                    // TODO
                    msg_received_callback.disconnected("host");
                }
            };
            final ClientSession[] session = new ClientSession[1];
            network_queue.add(new Runnable() {
                @Override
                public void run() {
                    try {
                        // To access this port on the emulator from outside the emulator,
                        // run:
                        //     adb reverse tcp:55345 tcp:55345
                        session[0] = ClientSession.createFromAddr("127.0.0.1", 55345, callback);
                        Log.i(TAG, "finished connecting to socket as client");
                    } catch (IOException e) {
                        Log.e(TAG, "io exception when connecting to host as client", e);
                        return;
                    }
                }
            });
            send_msg = new ISendMsg() {
                @Override
                public void send_msg(String dst, byte[] msg, int msg_len) {
                    Log.d(TAG, "trying to send msg as client");
                    try {
                        session[0].send_message(msg, msg_len);
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            };
        }
    }

    public void runOnThread(Runnable r) {
        this.network_queue.add(r);
    }

    public ISendMsg getSendMsg() {
        return new ISendMsg() {
            @Override
            public void send_msg(String dst, byte[] msg, int msg_len) {
                network_queue.add(new Runnable() {
                    @Override
                    public void run() {
                        send_msg.send_msg(dst, msg, msg_len);
                    }
                });
            }
        };
    }
}
