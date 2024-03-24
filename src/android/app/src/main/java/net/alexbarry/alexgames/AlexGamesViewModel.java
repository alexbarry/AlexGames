package net.alexbarry.alexgames;

import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

public class AlexGamesViewModel extends ViewModel {
    private MutableLiveData<String> game_selected;

    public void setGameId(String game_id) {
        if (game_selected == null) {
            game_selected = new MutableLiveData<>();
        }
        game_selected.setValue(game_id);
    }

    public String getGameId() {
        if (game_selected != null) {
            return game_selected.getValue();
        } else {
            return "minesweeper";
        }
    }
}
