package net.alexbarry.alexgames.server;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Build;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.IBinder;
import android.os.Looper;
import android.os.Message;
import android.os.Process;
import android.util.Log;
import android.widget.Toast;

import androidx.annotation.Nullable;

import net.alexbarry.alexgames.AlexConstants;
import net.alexbarry.alexgames.R;

import java.util.Calendar;
import java.util.Date;
import java.util.List;

public class GameServerService extends Service {

    public static final int DEFAULT_HTTP_PORT = 55080;
    public static final int DEFAULT_WS_PORT   = 55433;

    public static final int SERVICE_ID = 1234;
    public static final int SERVICE_STATUS_NOTIFICATION_ID = 4567;
    private static final String STOP_SERVICE_ACTION = "STOP_SERVICE";
    private static final String TAG = "GameServerService";

    private static final String EXTRA_HTTP_PORT = "http_port";
    private static final String EXTRA_WS_PORT   = "ws_port";


    private final GameServerBinder binder = new GameServerBinder(this);
    private final WebServer webServer = new WebServer();
    private AlexGamesNetworkHandler mainServer;

    // TODO replace with state variable
    private boolean isActive = false;

    private String serverAddr = null;


    private final BroadcastReceiver broadcastReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if (intent.getAction().equals(STOP_SERVICE_ACTION)) {
                recvdStopServiceRequest();
            }
        }
    };
    private int httpPort;
    private int wsPort;

    private enum ServiceMsgId {
        START_SERVERS,
        STOP_SERVICE,
        UPDATE_STATS,
    }

    public static void startService(Context context, Integer httpPort, Integer wsPort) {
        Intent gameServerServiceStartIntent = new Intent(context, GameServerService.class);
        if (httpPort != null) {
            gameServerServiceStartIntent.putExtra(EXTRA_HTTP_PORT, httpPort.intValue());
        }
        if (wsPort != null) {
            gameServerServiceStartIntent.putExtra(EXTRA_WS_PORT, wsPort.intValue());
        }
        Log.i(TAG, "Starting service...");
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            context.startService(gameServerServiceStartIntent);
        } else {
            context.startForegroundService(gameServerServiceStartIntent);
        }
        Log.i(TAG, "Service should be started...?");
    }

    private static int serviceMsgIdToInt(ServiceMsgId msgIdEnum) {
        switch(msgIdEnum) {
            case START_SERVERS: return 1;
            case STOP_SERVICE: return 2;
            case UPDATE_STATS: return 3;
        }
        throw new RuntimeException(String.format("unhandled val %s", msgIdEnum));
    }

    private static ServiceMsgId serviceMsgIdIntToEnum(int msgIdInt) {
        switch(msgIdInt) {
            case 1: return ServiceMsgId.START_SERVERS;
            case 2: return ServiceMsgId.STOP_SERVICE;
            case 3: return ServiceMsgId.UPDATE_STATS;
        }
        throw new RuntimeException(String.format("unhandled val %d", msgIdInt));
    }

    private ServiceHandler serviceHandler;
    private Date serverStartDate = null;

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return binder;
    }


    @Override
    public void onCreate() {
        Log.i(TAG, "onCreate");
        // Don't start the servers until onStartCommand is received?
        // that's where the ports come in
    }
    private void internalStartServers() {
        Log.i(TAG, "internalStartServers");
        // Start up the thread running the service. Note that we create a
        // separate thread because the service normally runs in the process's
        // main thread, which we don't want to block. We also make it
        // background priority so CPU-intensive work doesn't disrupt our UI.
        HandlerThread thread = new HandlerThread("ServiceStartArguments",
                Process.THREAD_PRIORITY_BACKGROUND);
        thread.start();

        // Get the HandlerThread's Looper and use it for our Handler
        Looper serviceLooper = thread.getLooper();
        this.serviceHandler = new ServiceHandler(serviceLooper);

        IntentFilter intentFilter = new IntentFilter();
        intentFilter.addAction(STOP_SERVICE_ACTION);
        registerReceiver(broadcastReceiver, intentFilter);

        this.isActive = true;
        startForeground(SERVICE_STATUS_NOTIFICATION_ID, buildNotification());

        Message msg = serviceHandler.obtainMessage();
        msg.arg1 = serviceMsgIdToInt(ServiceMsgId.START_SERVERS);
        serviceHandler.sendMessage(msg);
    }

    private void updateNotification() {
        Log.d(TAG, "#updateNotification");
        if (!this.isActive) { return; }
        Notification notification = buildNotification();

        final NotificationManager notificationManager = getSystemService(NotificationManager.class);
        notificationManager.notify(SERVICE_STATUS_NOTIFICATION_ID, notification);
    }

    private void clearNotification() {
        final NotificationManager notificationManager = getSystemService(NotificationManager.class);
        notificationManager.cancel(SERVICE_STATUS_NOTIFICATION_ID);
    }


    private String buildNotificationMsg() {
        int httpDownloads = webServer.getHttpDownloads();
        int wsConnections = webServer.getWsConnections();
        return String.format("Hosting %s, ws: %d, lastHttpDl: %s",
                serverAddr, wsConnections, webServer.getHttpDlInfo());
    }

    private Notification buildNotification() {
        String msg = buildNotificationMsg();
        return buildNotification(msg);
    }

    public static void stopService(Context context) {
        Intent stopIntent = new Intent();
        stopIntent.setAction(STOP_SERVICE_ACTION);
        context.sendBroadcast(stopIntent);
    }

    private Notification buildNotification(String msg) {
        Intent stopIntent = new Intent();
        stopIntent.setAction(STOP_SERVICE_ACTION);
        PendingIntent pendingStopIntent = PendingIntent.getBroadcast(this, 0, stopIntent, 0);

        //Intent openServiceMonitoringIntent = new Intent();
        //openServiceMonitoringIntent.setAction(".server.ServerMonitoringActivity");
        //PendingIntent pendingOpenServiceMonitoring = PendingIntent.getBroadcast(this, 0, openServiceMonitoringIntent, 0)

        Intent openServiceMonitoringIntent = new Intent(this, ServerMonitorActivity.class);
        openServiceMonitoringIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        PendingIntent pendingOpenServiceMonitoringIntent = PendingIntent.getActivity(this, 0, openServiceMonitoringIntent, 0);

        // TODO make it so you can click the notification and open
        // an activity that will show more server info
        Notification.Builder notificationBuilder = new Notification.Builder(this)
                .setNumber(SERVICE_ID)
                .setContentTitle("Hosting AlexGame server")
                .setContentText(msg)
                .setSmallIcon(R.drawable.ic_launcher_foreground)
                .addAction(R.drawable.ic_stop, getString(R.string.stop_service), pendingStopIntent)
                .setContentIntent(pendingOpenServiceMonitoringIntent);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            notificationBuilder.setChannelId(AlexConstants.HOST_SERVER_SERVICE_NOTIFICATION_CHANNEL_ID);
        }

        return notificationBuilder.build();
    }


    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.i(TAG, "#onStartCommand");
        this.httpPort = intent.getIntExtra(EXTRA_HTTP_PORT, DEFAULT_HTTP_PORT);
        this.wsPort   = intent.getIntExtra(EXTRA_WS_PORT,   DEFAULT_WS_PORT  );
        internalStartServers();
        Toast.makeText(this, getString(R.string.service_starting_toast), Toast.LENGTH_SHORT).show();

        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        Log.i(TAG, "#onDestroy");
        super.onDestroy();
        unregisterReceiver(broadcastReceiver);
        Toast.makeText(this, getString(R.string.service_done_toast), Toast.LENGTH_SHORT).show();
        this.webServer.destroy();
        this.isActive = false;
        clearNotification();
    }

    public List<GameServerBinder.ServerDownloadInfoEntry> getHttpDownloadInfo() {
        return this.webServer.getHttpDownloadInfoList();
    }

    public List<GameServerBinder.ServerActiveConnectionEntry> getActiveConnectionInfo() {
        return this.webServer.getActiveConnectionInfo();
    }

    public Date getServiceStartDate() {
        return this.serverStartDate;
    }
    public String getAddress() { return this.serverAddr; }


    // Handler that receives messages from the thread
    private final class ServiceHandler extends Handler {
        public ServiceHandler(Looper looper) {
            super(looper);
        }
        @Override
        public void handleMessage(Message msg) {
            ServiceMsgId msgId = serviceMsgIdIntToEnum(msg.arg1);
            switch(msgId) {
                case STOP_SERVICE: stopSelf(SERVICE_ID); break;
                case START_SERVERS: startServers(); break;
                case UPDATE_STATS: updateStats(); break;
            }
        }

        private void startServers() {
            webServer.setCallback(new WebServer.Callback() {
                @Override
                public void onStatsChanged() {
                    updateNotification();
                    binder.notifyUpdateListener();
                }
            });
            GameServerService.this.serverStartDate = Calendar.getInstance().getTime();
            serverAddr = String.format("http://%s:%d", getIpAddress(), httpPort);
            webServer.init_server(GameServerService.this, httpPort, wsPort);
            mainServer = new AlexGamesNetworkHandler();

            Log.i(TAG, "binder.notifyUpdateListener()");
            binder.notifyUpdateListener();

        }

        private void updateStats() {
            updateNotification();
        }
    }

    private void recvdStopServiceRequest() {
        Log.i(TAG, "recvdStopServiceRequest");
        stopSelf();
    }

    private String getIpAddress() {
        WifiManager wifiManager = (WifiManager)getSystemService(WifiManager.class);
        WifiInfo wifiInfo = wifiManager.getConnectionInfo();
        int ipAddress = wifiInfo.getIpAddress();
        return String.format("%d.%d.%d.%d",
                (ipAddress >>  0) & 0xff,
                (ipAddress >>  8) & 0xff,
                (ipAddress >> 16) & 0xff,
                (ipAddress >> 24) & 0xff);
    }



}
