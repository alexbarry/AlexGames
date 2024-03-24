package net.alexbarry.alexgames.popup;

public interface IAlexGamesPopupManager {
    interface Callback {
        void popup_button_clicked(String popup_id, int btn_id);
    }

    void set_callback(Callback callback);
    void show_popup(String popup_id, String title, String msg, String btns[]);
}
