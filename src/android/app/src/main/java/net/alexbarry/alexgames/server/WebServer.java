package net.alexbarry.alexgames.server;

import android.content.Context;
import android.util.Log;

import net.alexbarry.alexgames.util.AssetRawToFilesDir;

import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;

import fi.iki.elonen.NanoHTTPD;

public class WebServer {

    private final static String TAG = "WebServer";

    //private final static int HTTP_PORT = 55080;
    private final static long HTTP_DOWNLOAD_GROUP_TIME_SECONDS = 5;
    private final static SimpleDateFormat httpDebugTimeFormat = new SimpleDateFormat("hh:mm:ss");

    /*
    public int getHttpPort() {
        return HTTP_PORT;
    }
     */

    public interface Callback {
        void onStatsChanged();
    }

    private HttpServer httpServer;
    private WebsocketServer ws_server;
    private Callback callback;
    private ServerDownloadStatsHelper serverDownloadStatsHelper = new ServerDownloadStatsHelper(HTTP_DOWNLOAD_GROUP_TIME_SECONDS);


    public void setCallback(Callback callback) {
        this.callback = callback;
    }

    public void init_server(Context context, int httpPort, int wsPort) {
        Log.i(TAG, String.format("(%s) init_server, httpPort=%d, wsPort=%d", this, httpPort, wsPort));

        AssetRawToFilesDir.copyFromAssetsToFiles(context, "games");
        AssetRawToFilesDir.copyFromAssetsToFiles(context, "html");

        // To forward:
        //     adb forward tcp:55433 tcp:55433
        this.ws_server = new WebsocketServer(wsPort);
        try {
            ws_server.start();
            ws_server.setOnConnectionsChangedCallback(() -> {
                callback.onStatsChanged();
            });
        } catch (IOException ex) {
            Log.e(TAG, "io exception when starting ws server", ex);
        }

        this.serverDownloadStatsHelper.clear();
        //ServerRunner.run(HttpServer.class);
        // To forward:
        //     adb forward tcp:55080 tcp:55080
        this.httpServer = new HttpServer(context, httpPort);
        try {
            httpServer.start(NanoHTTPD.SOCKET_READ_TIMEOUT, false);
            httpServer.setOnDownloadCallback(new HttpServer.Callback() {
                @Override
                public void httpDownload(String user) {
                    serverDownloadStatsHelper.onHttpDownload(user);
                    callback.onStatsChanged();
                }
            });
        } catch (IOException ex) {
            Log.e(TAG, "io exception when starting http server", ex);
        }
        callback.onStatsChanged();
        Log.i(TAG, String.format("(%s) init_server done, httpServer (%s), wsServer (%s)", this, httpServer, ws_server));
    }

    public int getHttpDownloads() {
        if (httpServer == null) { return -1; }
        return httpServer.getHttpDownloads();
    }

    public String getHttpDlInfo() {
        List<GameServerBinder.ServerDownloadInfoEntry> infoList =
                serverDownloadStatsHelper.getDownloadStats();
        if (infoList.size() == 0) { return "no last download"; }
        GameServerBinder.ServerDownloadInfoEntry info = infoList.get(infoList.size()-1);

        return String.format("%s: %s dl:%d", httpDebugTimeFormat.format(info.getDate()), info.getUser(), info.getDownloads());
    }


    public int getWsConnections() {
        if (ws_server == null) { return -1; }
        return ws_server.getActiveConnections();
    }

    public void destroy() {
        if (this.httpServer != null) {
            this.httpServer.stop();
            this.httpServer = null;
        }
        if (this.ws_server != null) {
            this.ws_server.stop();
            this.ws_server = null;
        }
    }

    public List<GameServerBinder.ServerDownloadInfoEntry> getHttpDownloadInfoList() {
        return serverDownloadStatsHelper.getDownloadStats();
    }

    public List<GameServerBinder.ServerActiveConnectionEntry> getActiveConnectionInfo() {
        if (ws_server == null) { return new ArrayList<>(); }
        return ws_server.getActiveConnectionInfo();
    }
}
