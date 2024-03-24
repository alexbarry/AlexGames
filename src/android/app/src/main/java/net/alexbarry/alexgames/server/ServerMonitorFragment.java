package net.alexbarry.alexgames.server;

import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.graphics.Paint;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;

import net.alexbarry.alexgames.R;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;

public class ServerMonitorFragment extends Fragment {

    private static final String TAG = "ServerMonitorFragment";

    private final SimpleDateFormat timeDateFormat = new SimpleDateFormat("HH:mm:ss");

    private TextView serverInfoTv;
    private TextView httpServerInfoTv;
    private TextView activeConnServerInfoTv;
    private Button stopServerBtn;

    private ServerMonitorViewModel viewModel;

    private String serverAddr;
    private Date serverStartDate;

    @Override
    public View onCreateView(
            LayoutInflater inflater, ViewGroup container,
            Bundle savedInstanceState
    ) {
        return inflater.inflate(R.layout.server_monitor_fragment, container, false);
    }


    public void onViewCreated(@NonNull View view, Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        this.serverInfoTv = view.findViewById(R.id.serverInfo);
        this.httpServerInfoTv = view.findViewById(R.id.httpServerStatus);
        this.activeConnServerInfoTv = view.findViewById(R.id.wsServerStatus);
        this.stopServerBtn = view.findViewById(R.id.btnStopServer);
        TextView addrTv = (TextView)view.findViewById(R.id.serverAddr);

        this.viewModel = new ViewModelProvider(requireActivity()).get(ServerMonitorViewModel.class);
        this.viewModel.getDate().observe(getViewLifecycleOwner(), startDate -> {
            //Log.d(TAG, "updating serverStateDate to " + startDate);
            this.serverStartDate = startDate;
            setServerInfo(this.serverStartDate, this.serverAddr);
        });
        this.viewModel.getServerAddr().observe(getViewLifecycleOwner(), addr -> {
            //Log.d(TAG, "updating serverAddr to: " + addr);
            this.serverAddr = addr;
            addrTv.setText(addr);
            setServerInfo(this.serverStartDate, this.serverAddr);
        });
        this.viewModel.getActiveConnInfoList().observe(getViewLifecycleOwner(), connInfoList -> {
            //Log.d(TAG, String.format("updating activeConnInfoList, data len: %d", connInfoList.size()));
            setActiveConnData(connInfoList);
        });
        this.viewModel.getDownloadInfoList().observe(getViewLifecycleOwner(), downloadInfoList -> {
            //Log.d(TAG, "updating downloadInfoList");
            setHttpData(downloadInfoList);
        });

        this.stopServerBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                GameServerService.stopService(getContext());
            }
        });

        addrTv.setPaintFlags(addrTv.getPaintFlags() | Paint.UNDERLINE_TEXT_FLAG);
        view.findViewById(R.id.serverAddr).setOnClickListener(v -> {
            ClipboardManager clipboard = (ClipboardManager) getContext().getSystemService(Context.CLIPBOARD_SERVICE);
            String msg = "Game URL copied to clipboard";
            String label = msg;
            String text = this.serverAddr;
            ClipData clip = ClipData.newPlainText(label, text);
            clipboard.setPrimaryClip(clip);

            Toast.makeText(getActivity(), msg, Toast.LENGTH_LONG).show();
        });

        view.findViewById(R.id.serverAddrBtnShare).setOnClickListener(v -> {
            try {
                Intent shareIntent = new Intent(Intent.ACTION_SEND);
                shareIntent.setType("text/plain");
                String url = this.serverAddr;
                shareIntent.putExtra(Intent.EXTRA_TEXT, url);
                startActivity(Intent.createChooser(shareIntent, "Share game server URL"));
            } catch (Exception e) {
                Log.e(TAG, "Exception trying to share server addr", e);
            }
        });

        view.findViewById(R.id.serverAddrBtnOpen).setOnClickListener(v -> {
            Uri uri = Uri.parse(this.serverAddr); // TODO use real URL
            Intent browserIntent = new Intent(Intent.ACTION_VIEW, uri);
            startActivity(browserIntent);
        });
    }

    private void setServerInfo(Date serviceStartDate, String serverAddr) {
        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append(String.format("Hosting server at %s\n", serverAddr));
        stringBuilder.append(String.format("Started hosting at %s\n", serviceStartDate));

        serverInfoTv.setText(stringBuilder.toString());
    }

    private void setHttpData(List<GameServerBinder.ServerDownloadInfoEntry> httpDownloadInfo) {
        StringBuilder stringBuilder = new StringBuilder();
        for (GameServerBinder.ServerDownloadInfoEntry downloadEntry : httpDownloadInfo) {
            stringBuilder.append(String.format("%s: (dl:%4d) %s\n",
                    timeDateFormat.format(downloadEntry.getDate()),
                    downloadEntry.getDownloads(),
                    downloadEntry.getUser()));
        }

        httpServerInfoTv.setText(stringBuilder.toString());
    }

    private void setActiveConnData(List<GameServerBinder.ServerActiveConnectionEntry> activeConnectionInfo) {
        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append(String.format("%d active connections:\n", activeConnectionInfo.size()));
        int i = 0;
        for (GameServerBinder.ServerActiveConnectionEntry conn : activeConnectionInfo) {
            stringBuilder.append(String.format("%d: %s %s (since %s)\n",
                    i,
                    conn.getSessionId(),
                    conn.getUser(),
                    timeDateFormat.format(conn.getFirstConnected())));
            i++;
        }

        activeConnServerInfoTv.setText(stringBuilder.toString());
    }
}
