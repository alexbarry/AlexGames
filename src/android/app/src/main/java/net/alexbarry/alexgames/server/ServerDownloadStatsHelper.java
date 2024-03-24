package net.alexbarry.alexgames.server;

import android.util.Log;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Call {@link #onHttpDownload(String user)} every time a user downloads a page. Aggregates the
 * results into a list of each entry grouped by the time set in {@code groupTimeSeconds} constructor
 * argument (if from the same user).
 */
class ServerDownloadStatsHelper {

    private static final String TAG = "ServerDownloadStatsHelper";



    private static class DownloadInfo {
        private final Date firstVisitInGroup;
        private final GameServerBinder.ServerDownloadInfoEntry lastDownloadInfoEntry;

        DownloadInfo(String user, Date date) {
            this.firstVisitInGroup = date;
            this.lastDownloadInfoEntry = new GameServerBinder.ServerDownloadInfoEntry(user, date);

        }
    }

    private final Map<String, DownloadInfo> firstVisitInGroupTime = new HashMap<>();
    private final List<GameServerBinder.ServerDownloadInfoEntry> downloadStats = new ArrayList<>();


    /**
     * Max time between a group of downloads for them to remain a group (single entry)
     *
     * <p>e.g. if this is 5 seconds, then if a client continuously downloaded stuff for 6 seconds,
     * the first 5 seconds worth would be one group, and the rest would be a second group. (And if
     * the same client downloads stuff 20 seconds later, that will be a separate group).
     */
    private final long groupTimeSeconds;

    ServerDownloadStatsHelper(long groupTimeSeconds) {
        this.groupTimeSeconds = groupTimeSeconds;
    }

    void clear() {
        firstVisitInGroupTime.clear();
        downloadStats.clear();
    }

    public void onHttpDownload(String user) {
        Date now = Calendar.getInstance().getTime();

        DownloadInfo info = getInfo(user, now);
        info.lastDownloadInfoEntry.downloads++;
    }

    public List<GameServerBinder.ServerDownloadInfoEntry> getDownloadStats() {
        return this.downloadStats;
    }

    private DownloadInfo getInfo(String user, Date now) {
        DownloadInfo info = null;
        if (firstVisitInGroupTime.containsKey(user)) {
            DownloadInfo entry  = firstVisitInGroupTime.get(user);
            long timeDiffMillis = (now.getTime() - entry.firstVisitInGroup.getTime());
            // Log.d(TAG, String.format("getInfo time diff: %5d, now: %s, lastEntry: %s",
            //         timeDiffMillis, now, entry.firstVisitInGroup));
            if (timeDiffMillis < groupTimeSeconds * 1000) {
                info = entry;
            }
        }

        if (info == null) {
            info = newInfo(user, now);
        }

        return info;
    }

    private DownloadInfo newInfo(String user, Date now) {
        DownloadInfo info = new DownloadInfo(user, now);
        firstVisitInGroupTime.put(user, info);
        downloadStats.add(info.lastDownloadInfoEntry);
        return info;
    }
}
