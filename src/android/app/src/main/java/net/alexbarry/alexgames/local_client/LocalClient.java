package net.alexbarry.alexgames.local_client;

import static net.alexbarry.alexgames.util.StringFuncs.byteary_to_nice_str;

import android.app.Activity;
import android.content.Context;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;

import androidx.fragment.app.FragmentActivity;
import androidx.lifecycle.ViewModelProvider;

import net.alexbarry.alexgames.AlexGamesJni;
import net.alexbarry.alexgames.AlexGamesViewModel;
import net.alexbarry.alexgames.R;
import net.alexbarry.alexgames.graphics.AlexGamesCanvas;
import net.alexbarry.alexgames.network.ISendMsg;
import net.alexbarry.alexgames.popup.PopupManagerImpl;
import net.alexbarry.alexgames.util.TouchEvtToClickEvt;

import java.io.File;

/**
 * Class to initialize local Android native instance of AlexGames.
 *
 * <p>Using this class runs games in Android native code, or an Android native instance of Lua.
 */
public class LocalClient {

    private static final String TAG = "AlexGamesLocalClient";


    private final TouchEvtToClickEvt touchEvtToClickEvt = new TouchEvtToClickEvt();

    private AlexGamesCanvas alexGamesCanvas;
    private PopupManagerImpl popupManager;
    private AlexGamesJni alexGames;
    private AlexGamesViewModel viewModel;


    public void init_alex_games(FragmentActivity activity, View view, ISendMsg send_msg) {
        Context context = activity.getApplicationContext();
        File res_dir = new File(context.getFilesDir(), "games");
        this.alexGamesCanvas = (AlexGamesCanvas)view.findViewById(R.id.alex_games_canvas);
        this.popupManager = new PopupManagerImpl(activity);
        this.alexGames = new AlexGamesJni();
        this.viewModel = new ViewModelProvider(activity).get(AlexGamesViewModel.class);


        alexGamesCanvas.init(context, res_dir);
        alexGames.setCanvas(alexGamesCanvas);
        alexGames.setPopupManager(popupManager);

        //alexGames.jniInit("go");
        //alexGames.init("solitaire");
        //alexGames.init("minesweeper");
        //alexGames.init("touch_test");
        String game_id = viewModel.getGameId();
        //String game_id = "minesweeper";
        //game_id = "stick";
        Log.i(TAG, String.format("initializing alexgames with game_id=\"%s\"", game_id));
        alexGames.init(game_id);
        alexGames.draw_board(0);

        alexGamesCanvas.setOnTouchListener(new View.OnTouchListener() {
            @Override
            public boolean onTouch(View v, MotionEvent event) {
                alexGames.onTouch(event, alexGamesCanvas.getScale());

                TouchEvtToClickEvt.TouchInfo click = touchEvtToClickEvt.handleTouchEvt(event);
                if (click != null) {
                    alexGames.onClick(click.y, click.x, alexGamesCanvas.getScale());
                }

                return true;
            }
        });
}

    public void handle_msg_received(String name, byte[] data, int len) {
        alexGames.handle_msg_received(name, data, len);
    }

    public void setSendMessageCallback(ISendMsg sendMsg) {
        alexGames.setSendMessageCallback(new AlexGamesJni.SendMessage() {
            @Override
            public void send_message(String src, byte[] msg, int msg_len) {
                sendMsg.send_msg(src, msg, msg_len);
            }
        });
    }

    public void destroy() {
        if (popupManager != null) { popupManager.destroy(); }
    }
}
