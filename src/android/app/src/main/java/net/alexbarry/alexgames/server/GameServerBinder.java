package net.alexbarry.alexgames.server;

import android.os.Binder;

import java.util.Date;
import java.util.List;

public class GameServerBinder extends Binder {

    private Runnable updateListener = null;

    public static class ServerDownloadInfoEntry {
        private final String user;
        private final Date date;
        int downloads = 0;

        ServerDownloadInfoEntry(String user, Date date) {
            this.user = user;
            this.date = date;
        }

        public String getUser() { return this.user; }
        public Date getDate() { return this.date; }
        public int getDownloads() { return this.downloads; }

    }

    public static class ServerActiveConnectionEntry {
        private final String sessionId;
        private final String user;
        private final Date firstConnected;
        ServerActiveConnectionEntry(String sessionId, String user, Date firstConnected) {
            this.sessionId = sessionId;
            this.user = user;
            this.firstConnected = firstConnected;
        }

        public String getSessionId() { return this.sessionId; }
        public String getUser() { return this.user; }
        public Date getFirstConnected() { return this.firstConnected; }
    }

    private final GameServerService service;

    GameServerBinder(GameServerService service) {
        this.service = service;
    }

    public GameServerService getService() {
        return this.service;
    }

    // TODO maybe there should be a list here. What if more than one activity is opened?
    public void registerStatusUpdateListener(Runnable updateListener) {
        this.updateListener = updateListener;
    }

    void notifyUpdateListener() {
        if (this.updateListener != null) {
            this.updateListener.run();
        }
    }
}
