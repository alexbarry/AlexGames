package net.alexbarry.alexgames.util;

import android.view.MotionEvent;

import java.util.HashMap;
import java.util.Map;

public class TouchEvtToClickEvt {

    public class TouchInfo {
        TouchInfo(float y, float x) {
            this.y = y;
            this.x = x;
        }
        public final float y;
        public final float x;
    }

    private Map<Integer, TouchInfo> possibleClickTouches = new HashMap<>();

    public TouchInfo handleTouchEvt(MotionEvent event) {
        TouchInfo click = null;
        if (event.getActionMasked() == MotionEvent.ACTION_DOWN) {
            possibleClickTouches.put(event.getActionIndex(), new TouchInfo(event.getY(), event.getX()));
        } else if (event.getActionMasked() == MotionEvent.ACTION_MOVE) {
            possibleClickTouches.remove(event.getActionIndex());
        } else if (event.getActionMasked() == MotionEvent.ACTION_UP) {
            if (possibleClickTouches.containsKey(event.getActionIndex())) {
                click = possibleClickTouches.remove(event.getActionIndex());
            }
        }
        return click;
    }
}
