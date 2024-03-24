package net.alexbarry.alexgames.server;

import android.util.Log;

import java.io.IOException;
import java.nio.charset.CharacterCodingException;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class WebsocketServer extends fi.iki.elonen.NanoWSD {

    private static final String TAG = "WebsocketServer";
    private static final long PING_TIME_MS = 4*1000;
    private Map<String, List<WebsocketSession>> sessions = new HashMap<>();
    private final TimerTask timerTask = new TimerTask() {
        @Override
        public void run() {
            pingWebsockets();
        }
    };
    private final Timer timer = new Timer();
    private BlockingQueue<Runnable> queue = new LinkedBlockingQueue<>();
    private Runnable onConnectionsChanged = null;
    private int activeConnections = 0;
    private Thread thread = new Thread(new Runnable() {
        @Override
        public void run() {
            while (true) {
                try {
                    Runnable r = queue.take();
                    r.run();
                } catch (InterruptedException ex) {
                    Log.e(TAG, "interrupted exception", ex);
                    break;
                }
            }
        }
    });
    public WebsocketServer(int port) {
        super(port);
        Log.i(TAG, String.format("Starting websocket server on port %d with ping time %d ms",
                port, PING_TIME_MS));
        thread.start();
        timer.schedule(timerTask, PING_TIME_MS, PING_TIME_MS);
    }

    private void addWsToSession(String session_id, WebsocketSession ws) {
        queue.add(new Runnable() {
            @Override
            public void run() {
                if (!sessions.containsKey(session_id)) {
                    sessions.put(session_id, new ArrayList<>());
                }
                Log.d(TAG, String.format("Adding ws %s to session %s", ws, session_id));
                sessions.get(session_id).add(ws);
                activeConnections++;
                broadcastToSession(session_id, ws, String.format("\"ctrl\":player_joined:%s", ws.getName()));
                if (onConnectionsChanged != null) { onConnectionsChanged.run(); }
            }
        });
    }

    private void removeWsFromSession(String session_id, WebsocketSession ws) {
        queue.add(new Runnable() {
            @Override
            public void run() {
                Log.d(TAG, String.format("Removing ws %s from session %s", ws, session_id));
                sessions.get(session_id).remove(ws);
                activeConnections--;
                broadcastToSession(session_id, ws, String.format("\"ctrl\":player_left:%s", ws.getName()));
                if (onConnectionsChanged != null) { onConnectionsChanged.run(); }
            }
        });
    }


    private void broadcastToSession(String session_id, WebsocketSession src, String msg) {
        broadcastToSession(session_id, src, str_to_ws_frame(msg));
    }

    private void broadcastToSession(String session_id, WebsocketSession src, byte[] msg) {
        broadcastToSession(session_id, src, bytes_to_ws_frame(msg));
    }

    private void broadcastToSession(String session_id, WebsocketSession src, WebSocketFrame message) {
        queue.add(new Runnable() {
            @Override
            public void run() {
                Log.v(TAG, String.format("broadcasting msg from %s to all: %s", src, message.getTextPayload()));
                List<WebsocketSession> websockets = sessions.get(session_id);
                message.setUnmasked();
                for (WebsocketSession ws : websockets) {
                    if (ws == src) { continue; }
                    try {
                        ws.sendFrame(message);
                    } catch (java.net.SocketException e) {
                        Log.d(TAG, "removing socket from session due to socket ex while broadcasting");
                        removeWsFromSession(session_id, ws);
                        continue;
                    } catch (IOException e) {
                        Log.e(TAG, "exception sending frame to sessions", e);
                        removeWsFromSession(session_id, ws);
                        continue;
                    }
                }
            }
        });
    }

    private static WebSocketFrame str_to_ws_frame(String msg) {
        try {
            return new WebSocketFrame(WebSocketFrame.OpCode.Text, true, msg);
        } catch (CharacterCodingException e) {
            Log.i(TAG, "char coding exception", e);
            return null;
        }
    }

    private static WebSocketFrame bytes_to_ws_frame(byte[] msg) {
        return new WebSocketFrame(WebSocketFrame.OpCode.Text, true, msg);

    }

    public int getActiveConnections() {
        return activeConnections;
    }

    public void setOnConnectionsChangedCallback(Runnable callback) {
        this.onConnectionsChanged = callback;
    }

    static class MsgInfo {
        final String dst;
        final byte[] payload;
        MsgInfo(String dst, byte[] payload) {
            this.dst = dst;
            this.payload = payload;
        }
    }

    private MsgInfo parse_msg_info(byte[] msg) {
        int payload_delim_pos = -1;
        boolean found_close_quote = false;
        for (int i=0; i<msg.length; i++) {
            if (i != 0 && msg[i] == '"') {
                found_close_quote = true;
            }
            if (found_close_quote && msg[i] == ':') {
                payload_delim_pos = i;
                break;
            }
        }
        if (payload_delim_pos == -1) { return null; }

        StringBuilder dstStringBuilder = new StringBuilder();
        for (int i=1; i<payload_delim_pos-1; i++) {
            dstStringBuilder.append(Character.toString((char)msg[i]));
        }
        String dst = dstStringBuilder.toString();
        int payload_len = msg.length - payload_delim_pos - 1;
        // TODO seems wasteful to allocate a new one of these for every message
        byte[] payload = new byte[payload_len];
        for (int i=0; i<payload_len; i++) {
            payload[i] = msg[payload_delim_pos+1+i];
        }

        return new MsgInfo(dst, payload);
    }

    private static byte[] add_src_header(WebsocketSession src, byte[] payload) {
        String header = String.format("\"%s\":", src.getName());
        byte[] send_msg = new byte[header.length() + payload.length];
        for (int i=0; i<header.length(); i++) {
            send_msg[i] = (byte)header.charAt(i);
        }
        for (int i=0; i<payload.length; i++) {
            send_msg[header.length() + i] = payload[i];
        }
        return send_msg;
    }

    private void handleMessage(String session_id, WebsocketSession src, byte[] msg) {
        MsgInfo info = parse_msg_info(msg);
        Log.i(TAG, String.format("Received from %s to %s: %c %c %c %c",
                src.getName(), info.dst,
                info.payload[0], info.payload[1],
                info.payload[2], info.payload[3]));
        byte[] send_msg = add_src_header(src, info.payload);
        if (info.dst.equals("all")) {
            broadcastToSession(session_id, src, send_msg);
        } else {
            List<WebsocketSession> websockets = sessions.get(session_id);
            if (websockets == null) {
                Log.e(TAG, String.format("no websockets list found for session %s?", session_id));
                return;
            }
            for (WebsocketSession ws : websockets) {
                if (ws == src) { continue; }
                if (ws.getName().equals(info.dst)) {
                    ws.safe_send(send_msg);
                    return;
                }
            }
            Log.e(TAG, String.format("tried to message player %s but they were not found", info.dst));
        }
    }


    @Override
    protected WebSocket openWebSocket(IHTTPSession handshake) {
        Log.i(TAG, "returning new websocket");
        return new WebsocketSession(handshake);
    }

    static int ping_counter = 0x12345678;
    private void pingWebsockets() {
        byte[] payload = {
                (byte)((ping_counter>>24)&0xFF),
                (byte)((ping_counter>>16)&0xFF),
                (byte)((ping_counter>>8)&0xFF),
                (byte)((ping_counter>>0)&0xFF),
        };
        ping_counter++;
        for (String session_id : sessions.keySet()) {
            queue.add(new Runnable() {
                @Override
                public void run() {
                    List<WebsocketSession> websockets = sessions.get(session_id);
                    for (WebsocketSession ws : websockets) {
                        try {
                            ws.ping(payload);
                        } catch (java.net.SocketException e) {
                            Log.d(TAG, "removing socket due to socket ex while pinging");
                            removeWsFromSession(session_id, ws);
                        } catch (IOException e) {
                            Log.e(TAG, "io exception pinging websocket", e);
                            removeWsFromSession(session_id, ws);
                        }
                    }
                }
            });
        }
    }

    class WebsocketSession extends WebSocket {

        String session_id = null;

        // TODO figure out how to get the port and use that instead
        private int extra_id;
        private Date startTime;

        public WebsocketSession(IHTTPSession handshakeRequest) {
            super(handshakeRequest);
            this.extra_id = (10000 + (int)(Math.random()*(40e3)));
        }

        String getName() {
            String addr = this.getHandshakeRequest().getRemoteIpAddress();
            return String.format("%s:%d", addr, extra_id);
        }

        private void safe_send(WebSocketFrame frame) {
            queue.add(new Runnable() {
                @Override
                public void run() {
                    try {
                        WebsocketSession.this.sendFrame(frame);
                    } catch (IOException e) {
                        Log.e(TAG, "error sending msg", e);
                        removeWsFromSession(session_id, WebsocketSession.this);
                    }
                }
            });
        }
        private void safe_send(String msg) {
            safe_send(str_to_ws_frame(msg));
        }
        private void safe_send(byte[] msg) {
            safe_send(bytes_to_ws_frame(msg));
        }

        @Override
        protected void onOpen() {
            this.startTime = Calendar.getInstance().getTime();
        }

        @Override
        protected void onClose(WebSocketFrame.CloseCode code, String reason, boolean initiatedByRemote) {
            Log.i(TAG, String.format("Websocket.onClose(code=%s, reason=%s, byRemote=%b",
                    code, reason, initiatedByRemote));
            removeWsFromSession(session_id, this);
        }

        @Override
        protected void onMessage(WebSocketFrame message) {
            if (this.session_id == null) {
                if (message.getTextPayload().equals("\"ctrl\":new_session")) {
                    this.session_id = generate_new_session_id();
                    this.safe_send(String.format("\"ctrl\":connected:%s", session_id));
                } else if (message.getTextPayload().startsWith("\"ctrl\":session:")) {
                    Pattern pattern = Pattern.compile("\"ctrl\":session:(.*)");
                    Matcher matcher = pattern.matcher(message.getTextPayload());
                    if (matcher.find()) {
                        this.session_id = matcher.group(1);
                    } else {
                        Log.e(TAG, String.format("unexpected msg: %s", message.getTextPayload()));
                        return;
                    }
                    //this.safe_send(String.format("\"ctrl\":connected:%s", session_id));
                    // TODO
                } else {
                    Log.e(TAG, "unexpected first message");
                    return;
                }
                addWsToSession(session_id, this);
            } else {
                Log.i(TAG, String.format("recvd msg %s", message.toString()));
                handleMessage(session_id, this, message.getBinaryPayload());
            }
        }

        @Override
        protected void onPong(WebSocketFrame pong) {
            /*
            try {
                this.send(pong.getBinaryPayload());
            } catch (IOException e) {
                Log.e(TAG, "error sending pong", e);
            }
             */
        }

        @Override
        protected void onException(IOException exception) {
            Log.e(TAG, "WebsocketServer.onException", exception);
        }

        public Date getStartTime() {
            return this.startTime;
        }
    }


    public List<GameServerBinder.ServerActiveConnectionEntry> getActiveConnectionInfo() {
        List<GameServerBinder.ServerActiveConnectionEntry> activeConnectionInfo = new ArrayList<>();

        for (String sessionId : this.sessions.keySet()) {
            for (WebsocketSession connection : this.sessions.get(sessionId)) {
                GameServerBinder.ServerActiveConnectionEntry connectionInfo =
                        new GameServerBinder.ServerActiveConnectionEntry(
                                sessionId,
                                connection.getName(),
                                connection.getStartTime());
                activeConnectionInfo.add(connectionInfo);

            }
        }

        return activeConnectionInfo;
    }

    // TODO implement multiple sessions?
    private static String generate_new_session_id() {
        return "session1";
    }
}
