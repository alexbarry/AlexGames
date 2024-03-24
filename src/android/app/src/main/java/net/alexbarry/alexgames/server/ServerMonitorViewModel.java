package net.alexbarry.alexgames.server;

import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

import java.util.Date;
import java.util.List;

public class ServerMonitorViewModel extends ViewModel {

    private final MutableLiveData<Date> serverStartDate = new MutableLiveData<>();
    private final MutableLiveData<String> serverAddr = new MutableLiveData<>();
    private final MutableLiveData<List<GameServerBinder.ServerDownloadInfoEntry>> downloadInfoList =
            new MutableLiveData<>();
    private final MutableLiveData<List<GameServerBinder.ServerActiveConnectionEntry>> activeConnInfoList =
            new MutableLiveData<>();

    public void setServerStartDate(Date date) { this.serverStartDate.setValue(date); }
    public void setServerAddr(String addr) { this.serverAddr.setValue(addr); }
    public void setDownloadInfoList(List<GameServerBinder.ServerDownloadInfoEntry> dlInfoList) { this.downloadInfoList.setValue(dlInfoList); }
    public void setActiveConnInfoList(List<GameServerBinder.ServerActiveConnectionEntry> connInfoList) { this.activeConnInfoList.setValue(connInfoList); }

    public LiveData<Date> getDate() { return this.serverStartDate; }
    public LiveData<String> getServerAddr() { return this.serverAddr; }
    public LiveData<List<GameServerBinder.ServerDownloadInfoEntry>> getDownloadInfoList() { return this.downloadInfoList; }
    public LiveData<List<GameServerBinder.ServerActiveConnectionEntry>> getActiveConnInfoList() { return this.activeConnInfoList; }

}
