package net.alexbarry.alexgames.popup;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.content.DialogInterface;
import android.util.Log;

public class PopupManagerImpl implements IAlexGamesPopupManager {
    private static final String TAG = "PopupManager";
    private final Activity activity;
    private Callback callback;

    AlertDialog activeDialog = null;

    public PopupManagerImpl(Activity activity) {
        this.activity = activity;
    }

    @Override
    public void set_callback(Callback callback) {
        this.callback = callback;
    }

    @Override
    public void show_popup(final String popup_id, final String title, final String msg, final String[] btns) {
        Log.i(TAG, String.format("Showing popup id=\"%s\"", popup_id));
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                AlertDialog.Builder builder = new AlertDialog.Builder(activity);
                // TODO handle an arbitrary number of buttons
                builder.setTitle(title)
                        .setMessage(msg);
                if (btns.length > 0) {
                    builder.setPositiveButton(btns[0], new DialogInterface.OnClickListener() {
                                @Override
                                public void onClick(DialogInterface dialog, int which) {
                                    callback.popup_button_clicked(popup_id, 0);
                                }
                            });
                }
                if (activeDialog != null) { activeDialog.dismiss(); }
                activeDialog = builder.create();
                activeDialog.show();
            }
        });

    }

    public void destroy() {
        if (activeDialog != null) { activeDialog.dismiss(); }
    }
}
