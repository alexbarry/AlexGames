package net.alexbarry.alexgames;

import static net.alexbarry.alexgames.util.StringFuncs.byteary_to_nice_str;

import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import net.alexbarry.alexgames.local_client.LocalClient;
import net.alexbarry.alexgames.network.IMsgRecvd;
import net.alexbarry.alexgames.server.AlexGamesNetworkHandler;
import net.alexbarry.alexgames.server.WebServer;
import net.alexbarry.alexgames.util.AssetRawToFilesDir;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.navigation.fragment.NavHostFragment;

public class FirstFragment extends Fragment {

    private static final String TAG = "FirstFragment";

    private LocalClient localClient;

    @Override
    public View onCreateView(
            LayoutInflater inflater, ViewGroup container,
            Bundle savedInstanceState
    ) {
        // Inflate the layout for this fragment
        return inflater.inflate(R.layout.fragment_first, container, false);
    }

    public void onViewCreated(@NonNull View view, Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        view.findViewById(R.id.button_first).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                NavHostFragment.findNavController(FirstFragment.this)
                        .navigate(R.id.action_FirstFragment_to_SecondFragment);
            }
        });

        view.findViewById(R.id.button_to_root_test).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                NavHostFragment.findNavController(FirstFragment.this)
                        //.navigate(R.id.action_FirstFragment_to_hostOrLocalFragment);
                        .navigate(R.id.action_FirstFragment_to_SecondFragment);
            }
        });

        this.localClient = new LocalClient();

        IMsgRecvd msg_received_callback = new IMsgRecvd() {
            @Override
            public void handle_msg_received(String src, byte[] data, int data_len) {
                Log.i(TAG, String.format("Received msg from %s (%d bytes): %s", src, data_len, byteary_to_nice_str(data, data_len)));
                localClient.handle_msg_received(src, data, data_len);
            }

            @Override
            public void disconnected(String src) {
                // TODO

            }
        };

        AssetRawToFilesDir.copyFromAssetsToFiles(getContext(), "games");
        AssetRawToFilesDir.copyFromAssetsToFiles(getContext(), "html");
        AssetRawToFilesDir.copyFromAssetsToFiles(getContext(), "words-en.txt");

        boolean startLocalClientGames = true;

        if (startLocalClientGames) {
            localClient.init_alex_games(requireActivity(), view, null);
        }

        /*
        // TODO move this to the service, figure out how to pass messages through
        // bound service API
        mainServer.init(msg_received_callback);

        //init_alex_games(view, send_msg);
        mainServer.runOnThread(new Runnable() {
            @Override
            public void run() {
                localClient.init_alex_games(requireActivity(), view, mainServer.getSendMsg());
                localClient.setSendMessageCallback(mainServer.getSendMsg());
            }
        });

         */

    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        localClient.destroy();
    }
}
