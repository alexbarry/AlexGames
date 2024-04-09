package net.alexbarry.alexgames;

import android.util.Log;
import android.view.MotionEvent;
import android.content.Context;

import net.alexbarry.alexgames.graphics.IAlexGamesCanvas;
import net.alexbarry.alexgames.popup.IAlexGamesPopupManager;

import java.util.HashMap;
import java.util.Map;
import java.util.Timer;
import java.util.TimerTask;

public class AlexGamesJni {

	private static final String TAG = "AlexGamesJni";

	// TODO should either get from C header, or be able to set from Java
	// (e.g. for non square screens ... when tilting phone sideways, it is essential that the
	// thumbstick button is in the corner. It's hard to press if it's not.
	public static final int GAME_CANVAS_WIDTH = 480;
	public static final int GAME_CANVAS_HEIGHT = 480;

	static {
		System.loadLibrary("alex_games_android_jni");
	}


	public interface SendMessage {
		void send_message(String src, byte[] msg, int msg_len);
	}

	private IAlexGamesCanvas canvas;
	private IAlexGamesPopupManager popupManager;
	private SendMessage send_msg_callback;

	private long last_timer_fired_ms = 0;


	private final Object lock = new Object();

	private int timer_handle_counter = 1;
	private final Map<Integer, Timer> timers = new HashMap<>();

	private final Runnable timerTaskRunnable = () -> {
			// Log.v(TAG, "timerTask firing");
			runOnThread(() -> {
				long dt_ms = 0;
				long current_time_ms = System.currentTimeMillis();
				if (AlexGamesJni.this.last_timer_fired_ms != 0) {
					dt_ms = current_time_ms - AlexGamesJni.this.last_timer_fired_ms;
				}
				AlexGamesJni.this.last_timer_fired_ms = current_time_ms;
				AlexGamesJni.this.update((int)dt_ms);
			});
		};

	/*
	private BlockingQueue<Runnable> queue = new LinkedBlockingDeque<>();
	private Runnable queueHandler = new Runnable() {
		@Override
		public void run() {
			while (true) {
				try {
					Log.d(TAG, "waiting for runnable in lua JNI queue...");
					Runnable r = queue.take();
					Log.d(TAG, "found runnable in JNI queue...");
					r.run();
					Log.d(TAG, "finished running runnable in JNI queue");
				} catch (InterruptedException ex) {
					continue;
				} catch (Exception ex) {
					Log.e(TAG, "Received exception from thread", ex);
					break;
				}
			}
		}
	};
	private Thread thread = new Thread(queueHandler);
	 */

	private void runOnThread(Runnable r) {
		// TODO it seems way better to run all Lua stuff on its own thread.
		// But right now the UI flickers when I do that.
		// Perhaps I simply need to ensure that the canvas is double buffered?
		this.canvas.post(r);
        //this.queue.add(r);
	}

	public void setCanvas(IAlexGamesCanvas canvas) {
		this.canvas = canvas;
	}

	public void setPopupManager(IAlexGamesPopupManager popupManager) {
		popupManager.set_callback(new IAlexGamesPopupManager.Callback() {
			@Override
			public void popup_button_clicked(final String popup_id, final int btn_id) {
				runOnThread(new Runnable() {
								@Override
								public void run() {
									jniHandlePopupBtnClicked(popup_id, btn_id);
								}
							});
			}
		});

		this.popupManager = popupManager;
	}


	public void setSendMessageCallback(SendMessage send_msg_callback) {
		this.send_msg_callback = send_msg_callback;
	}
	
	private void draw_graphic(String img_id, int y, int x,
	                          int width, int height, int angle_degree) {
	    //img_id = img_id;
        img_id = String.copyValueOf(img_id.toCharArray()); // I don't think this is actually necessary?
		//Log.i(TAG, String.format("draw_graphic called with img_id \"%s\", " +
		//		"y=%d, x=%d, width=%d, height=%d", img_id, y, x, width, height));
		this.canvas.draw_graphic(img_id, y, x, width, height, angle_degree);
	}

	private void draw_line(String colour, int line_size,
	                       int y1, int x1,
	                       int y2, int x2) {
	    colour = String.copyValueOf(colour.toCharArray());
		this.canvas.draw_line(colour, line_size, y1, x1, y2, x2);
	}
	private void draw_text(String text, String colour,
	                       int y, int x, int size, int align) {
	    text = String.copyValueOf(text.toCharArray());
	    colour = String.copyValueOf(colour.toCharArray());
		this.canvas.draw_text(text, colour, y, x, size, align);
	}

	private void draw_rect(String colour,
	                       int y_start, int x_start,
	                       int y_end, int x_end) {
	    colour = String.copyValueOf(colour.toCharArray());
		this.canvas.draw_rect(colour, y_start, x_start, y_end, x_end);
	}

	private void draw_circle(String fill_colour, String outline_colour,
	                         int y, int x, int radius) {
		this.canvas.draw_circle(fill_colour, outline_colour, y, x, radius);
	}

	private void draw_clear() {
		this.canvas.draw_clear();
	}

	private void draw_refresh() { this.canvas.draw_refresh(); }

	private void send_message(String dst, byte[] msg, int len) {
		if (this.send_msg_callback == null) {
			Log.e(TAG, "send_msg_callback is null");
			return;
		}
		this.send_msg_callback.send_message(dst, msg, len);
	}

	private void show_popup(String popup_id, String title, String msg, String[] btn_strs) {
		String s = String.format("show_popup{popup_id=%s, title=%s, msg=%s", popup_id, title, msg);
		s += ", btn_strs = {";
		for (String btn_str : btn_strs) {
			s += btn_str + ", ";
		}
		s += "}};";
		Log.i(TAG, s);

		popupManager.show_popup(popup_id, title, msg, btn_strs);
	}

	private int set_update_timer_ms(long timer_period_ms) {
		Log.i(TAG, String.format("set_update_timer_ms(period=%d ms)", timer_period_ms));
		if (timer_period_ms <= 0) {
			Log.e(TAG, String.format("Can not schedule timer period <= 0: %d", timer_period_ms));
			return -1;
		}
		Timer timer = new Timer();
		TimerTask timerTask = new AlexTimerTask(timerTaskRunnable);
		timer.scheduleAtFixedRate(timerTask, timer_period_ms, timer_period_ms);
		int timer_handle = timer_handle_counter++;
		timers.put(timer_handle, timer);
		return timer_handle;
	}

	private void delete_timer(int handle) {
		if (!timers.containsKey(handle)) {
			Log.e(TAG, String.format("delete_timer: Timer with handle %d not found", handle));
			return;
		}

		Timer timer = timers.get(handle);
		timer.cancel();
		timers.remove(handle);
	}

	public native void jniHello();


	public void init(Context context, final String game_id) {
		runOnThread(new Runnable() {
			@Override
			public void run() {
				//String data_dir_path = context.getCacheDir().getAbsolutePath();
				String data_dir_path = context.getDataDir().getAbsolutePath();

				// TODO this should probably be done in C
				//data_dir_path += "/";
				data_dir_path += "/files/games/";

				jniInit(data_dir_path, game_id);
				jniStartGame(0, null);
			}
		});
		/*
		thread.setName("alex_games_jni");
		thread.start(); // TODO uncomment
		 */
	}
	public void update(int dt_ms) {
		runOnThread(new Runnable() {
			@Override
			public void run() {
				jniDrawBoard(dt_ms);
			}
		});
	}

	private native void jniInit(String data_dir_path, String game_id);
	private native void jniDrawBoard(int dt_ms);
	private native void jniHandleUserClicked(int pos_y, int pos_x);
	private native void jniHandleMousemove(int pos_y, int pos_x, int buttons);
	private native void jniHandleMouseEvt(int mouse_evt_id, int pos_y, int pos_x);
	private native void jniHandleTouchEvt(String evt_id_str, long touch_id, int touch_y, int touch_x);
	private native void jniHandlePopupBtnClicked(String popup_id, int btn_id);
	private native void jniHandleMessageReceived(String src, byte[] data, int data_len);
	private native void jniStartGame(int session_id, byte[] serialized_state);
	private static native int jniGetGameListCount();
	private static native String jniGetGameId(int idx);

	public void handle_touch_event(final String evt_id_str, final long touch_id, final int touch_y, final int touch_x) {
		runOnThread(new Runnable() {
			@Override
			public void run() {
				synchronized (lock) {
					jniHandleTouchEvt(evt_id_str, touch_id, touch_y, touch_x);
				}
			}
		});
	}

	private final long MIN_TIME_BETWEEN_TOUCHMOVE = 1000/60;
	private long lastTouchMoveProcessed = 0;
	public boolean onTouch(MotionEvent event, float scale) {

		if (event.getActionMasked() == MotionEvent.ACTION_MOVE) {
			long currentTime = System.currentTimeMillis();
			if (lastTouchMoveProcessed != 0 && (currentTime - lastTouchMoveProcessed) < MIN_TIME_BETWEEN_TOUCHMOVE) {
				// throttled
				return false;
			}
			lastTouchMoveProcessed = currentTime;
		}

		String evt_id_str;
		switch (event.getActionMasked()) {
			case MotionEvent.ACTION_DOWN:
			//case MotionEvent.ACTION_POINTER_DOWN:
				evt_id_str = "touchstart";
				break;
			case MotionEvent.ACTION_MOVE:
				evt_id_str = "touchmove";
				break;
			case MotionEvent.ACTION_UP:
			//case MotionEvent.ACTION_POINTER_UP:
				evt_id_str = "touchend";
				break;
			//case MotionEvent.ACTION_OUTSIDE:
			case MotionEvent.ACTION_CANCEL:
				evt_id_str = "touchcancel";
				break;
			default:
				Log.e(TAG, String.format("unexpected onTouch action: %d", event.getActionMasked()));
				return false;
		}
		long touch_id = event.getActionIndex();
		int touch_y = (int)(event.getY()/scale);
		int touch_x = (int)(event.getX()/scale);
		Log.v(TAG, String.format("handle_touch_evt str=%s, id=%d, y=%d, x=%d",
				evt_id_str, touch_id, touch_y, touch_x));
		// TODO this is crashing, probably because more touch events are coming in
		// before the first one is processed? (perhaps the touch start and touch move come in very
		// close together)
		// should move all Lua API calls to separate thread
		handle_touch_event(evt_id_str, touch_id, touch_y, touch_x);
		return true;
	}

	public static String[] getGamesList() {
		int count = jniGetGameListCount();
		String[] games_list = new String[count];
		for (int i=0; i<jniGetGameListCount(); i++) {
			games_list[i] = jniGetGameId(i);
		}
		return games_list;
	}

	public void onClick(float y, float x, float scale) {
		y /= scale;
		x /= scale;
		Log.d(TAG, String.format("user_click{y=%8.3f, x=%8.3f}", y, x));
		jniHandleUserClicked((int)y, (int)x);
	}

	public void handle_msg_received(String name, byte[] data, int len) {
		jniHandleMessageReceived(name, data, len);
	}

	private class AlexTimerTask extends TimerTask {
		private final Runnable runnable;
		AlexTimerTask(Runnable runnable) {
			this.runnable = runnable;
		}

		@Override
		public void run() {
			this.runnable.run();
		}
	}
}

