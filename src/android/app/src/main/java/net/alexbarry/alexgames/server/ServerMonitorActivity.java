package net.alexbarry.alexgames.server;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.util.Log;

import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import androidx.navigation.fragment.NavHostFragment;

import net.alexbarry.alexgames.R;

public class ServerMonitorActivity extends AppCompatActivity {
    private static final String TAG = "ServerMonitorActivity";

    // To start this activity via adb (but make sure to mark exported="true" in AndroidManifest.xml)
    //     adb shell am start net.alexbarry.alexgames/.server.ServerMonitorActivity


    private GameServerService service;
    private ServerMonitorViewModel viewModel;
    private ServiceConnection connection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            GameServerBinder binder = (GameServerBinder) service;
            ServerMonitorActivity.this.service = binder.getService();

            updateServiceFragment();
            binder.registerStatusUpdateListener(() -> {
                updateServiceFragment();
            });
        }

        @Override
        public void onServiceDisconnected(ComponentName name) {
            // TODO
        }
    };

    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.server_monitor_activity);
        //setContentView(R.layout.activity_main);
        Toolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
    }

    @Override
    public void onStart() {
        super.onStart();

        Intent intent = new Intent(this, GameServerService.class);
        bindService(intent, connection, Context.BIND_AUTO_CREATE);

        this.viewModel = new ViewModelProvider(this).get(ServerMonitorViewModel.class);

    }

    @Override
    public void onStop() {
        super.onStop();
        unbindService(connection);
    }

    private void updateServiceFragment() {
        runOnUiThread(() -> {
            Log.d(TAG, "updating viewModel with info");
            viewModel.setServerAddr(service.getAddress());
            viewModel.setServerStartDate(service.getServiceStartDate());
            viewModel.setActiveConnInfoList(service.getActiveConnectionInfo());
            viewModel.setDownloadInfoList(service.getHttpDownloadInfo());
        });
    }
}
