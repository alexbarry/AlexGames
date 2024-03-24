package net.alexbarry.alexgames.graphics;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.drawable.Drawable;
import android.util.AttributeSet;
import android.util.Log;
import android.view.View;

import net.alexbarry.alexgames.AlexGamesJni;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Queue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.LinkedBlockingDeque;

public class AlexGamesCanvas extends View implements IAlexGamesCanvas {

    private static final String TAG = "AlexGamesCanvas";

    private interface DrawHandler {
        void draw(Canvas canvas, float scaleX, float scaleY);
    }

    private final BlockingQueue<Runnable> queue = new LinkedBlockingDeque<>();
    private final Runnable queueHandler = new Runnable() {
        @Override
        public void run() {
            while (true) {
                try {
                    Runnable r = queue.take();
                    r.run();
                } catch (InterruptedException ex) {
                    continue;
                } catch (Exception ex) {
                    Log.e(TAG, "Received exception from thread", ex);
                    break;
                }
            }
        }
    };
    private final Thread thread = new Thread(queueHandler);

    private GraphicsManager graphicsManager = new GraphicsManager();
    //private List<DrawHandler> draw_runnables = new ArrayList<>();
    private Queue<DrawHandler> draw_runnables = new ConcurrentLinkedQueue<>();
    private boolean need_redraw;
    private float scale = 1.0f;

    public AlexGamesCanvas(Context context, AttributeSet attr) {
        super(context, attr);
    }

    public void init(Context context, File res_dir) {
        graphicsManager.init(context.getResources(), res_dir);
        thread.setName("alex_games_canvas");
        thread.start();
    }

    private void runOnThread(Runnable r) {
        // TODO does this really need its own thread?
        // All we do in the thread is add stuff to draw_runnables.
        // What else needs to be serialized? The invalidate calls?
        //this.post(r);
        this.queue.add(r);
    }

    @Override
    public void draw_graphic(final String img_id, final int y, final int x,
                             final int width, final int height, final int angle_degree) {
        //Log.i(TAG, "draw_graphic called...");
        runOnThread(new Runnable() {
            @Override
            public void run() {
                draw_runnables.add(new DrawHandler() {
                    @Override
                    public void draw(Canvas canvas, float scaleX, float scaleY) {
                        //Log.i(TAG, String.format("calling canvas.draw with img_id=%s START", img_id));
                        Drawable d = graphicsManager.get_drawable(img_id);
                        if (d == null) {
                            Log.e(TAG, String.format("Received null drawable for img_id=%s", img_id));
                            return;
                        }
                        int y2 = y - height/2;
                        int x2 = x - width/2;
                        d.setBounds((int)(x2*scaleX), (int)(y2*scaleY), (int)((x2 + width)*scaleX), (int)((y2 + height)*scaleY));
                        d.draw(canvas);
                        //Log.i(TAG, String.format("calling canvas.draw with img_id=%s DONE", img_id));
                    }
                });
                need_redraw = true;
            }
        });
    }

    @Override
    public void draw_line(final String colour, final int line_size,
                          final int y1, final int x1,
                          final int y2, final int x2) {
        runOnThread(new Runnable() {
            @Override
            public void run() {
                draw_runnables.add(new DrawHandler() {
                    @Override
                    public void draw(Canvas canvas, float scaleX, float scaleY) {
                        Paint paint = colour_str_to_colour_obj(colour);
                        //long colorLong = colour_str_to_int(colour);
                        //paint.setColor((int)colorLong);
                        //Log.d(TAG, String.format("draw_line y1=%.1f, x1=%.1f, y2=%.1f, x2=%.1f",
                        //                         y1*scaleY, x1*scaleX, y2*scaleY, x2*scaleX));
                        canvas.drawLine(x1*scaleX, y1*scaleY, x2*scaleX, y2*scaleY, paint);
                    }
                });
                need_redraw = true;
            }
        });
    }

    @Override
    public void draw_text(final String text, final String colour,
                          final int y, final int x,
                          final int size, final int align) {
        runOnThread(new Runnable() {
            @Override
            public void run() {
                draw_runnables.add(new DrawHandler() {
                    @Override
                    public void draw(Canvas canvas, float scaleX, float scaleY) {
                        Paint paint = colour_str_to_colour_obj(colour);
                        paint.setTextSize(size*scaleX);
                        switch(align) {
                            case  1: paint.setTextAlign(Paint.Align.LEFT);   break;
                            case  0: paint.setTextAlign(Paint.Align.CENTER); break;
                            case -1: paint.setTextAlign(Paint.Align.RIGHT);  break;
                            default:
                                Log.e(TAG, String.format("Unexpected text align value %d", align));
                        }
                        canvas.drawText(text, x*scaleX, y*scaleY, paint);
                    }
                });
            }
        });

    }

    @Override
    public void draw_rect(final String colour,
                          final int y_start, final int x_start,
                          final int y_end, final int x_end) {
        runOnThread(new Runnable() {
            @Override
            public void run() {
                draw_runnables.add(new DrawHandler() {
                    @Override
                    public void draw(Canvas canvas, float scaleX, float scaleY) {
                        Paint paint = colour_str_to_colour_obj(colour);
                        canvas.drawRect(x_start*scaleX, y_start*scaleY, x_end*scaleX, y_end*scaleY, paint);
                    }
                });
                need_redraw = true;
            }
        });
    }

    @Override
    public void draw_circle(final String fill_colour, final String outline_colour,
                            final int y, final int x, final int radius) {
        runOnThread(new Runnable() {
            @Override
            public void run() {
                draw_runnables.add(new DrawHandler() {
                    @Override
                    public void draw(Canvas canvas, float scaleX, float scaleY) {
                        Paint paint_fill    = colour_str_to_colour_obj(fill_colour);
                        Paint paint_outline = colour_str_to_colour_obj(outline_colour);
                        // TODO how do you do the outline?
                        // TODO how should the radius be scaled? I think scaleX and scaleY
                        //  should be combined into just one "scale" ...
                        canvas.drawCircle(x*scaleX, y*scaleY, radius*scaleX, paint_fill);
                    }
                });
                need_redraw = true;
            }
        });
    }

    @Override
    public void draw_clear() {
        runOnThread(new Runnable() {
            @Override
            public void run() {
                draw_runnables.clear();
                //Log.v(TAG, String.format("called draw_clear, queue now has %d elements", draw_runnables.size()));
                need_redraw = true;
            }
        });
    }

    @Override
    public void draw_refresh() {
        runOnThread(new Runnable() {
            @Override
            public void run() {
                AlexGamesCanvas.this.postInvalidate();
            }
        });
    }

    public void invalidate_enqueue() {
        runOnThread(new Runnable() {
            @Override
            public void run() {
                AlexGamesCanvas.this.postInvalidate();
            }
        });
    }

    private static boolean is_drawing = false;
    protected void onDraw(Canvas canvas) {
        if (is_drawing) {
            Log.e(TAG, "tried to draw while already drawing!");
            return;
        }

        float newScale = Math.min(getMeasuredHeight()*1.0f/AlexGamesJni.GAME_CANVAS_HEIGHT,
                getMeasuredWidth()*1.0f/AlexGamesJni.GAME_CANVAS_WIDTH);
        if (newScale != this.scale) {
            Log.i(TAG, String.format("Now drawing with scale %.3f", newScale));
        }
        this.scale = newScale;
        is_drawing = true;
        //List<DrawHandler> copy_draw_runnables = new ArrayList<>(draw_runnables);
        Queue<DrawHandler> copy_draw_runnables = draw_runnables; // not actually a copy... TODO
        Log.d(TAG, String.format("onDraw called with %d runnables in queue", copy_draw_runnables.size()));
        for (DrawHandler drawHandler : copy_draw_runnables) {
            drawHandler.draw(canvas, scale, scale);
        }
        Log.d(TAG, String.format("onDraw finished with %d runnables in queue", copy_draw_runnables.size()));
        need_redraw = false;
        is_drawing = false;
    }

    private static int hex_char_to_int(char c) {
        if ('0' <= c && c <= '9') { return c - '0';}
        else if ( 'a' <= c && c <= 'f') { return 0xa + c - 'a'; }
        else if ('A' <= c && c <= 'F') { return 0xa + c - 'A'; }
        else {
            throw new RuntimeException(String.format("unexpected hex char = %c", c));
        }
    }

    private static int hex_char2_to_int(char c1, char c2) {
        return (hex_char_to_int(c1) << 4) | hex_char_to_int(c2);
    }

    private static Paint colour_str_to_colour_obj(String colour_str) {
        int r, g, b, a;
        if (colour_str.length() == 0) {
            Log.e(TAG, String.format("Received invalid colour str, \"%s\"", colour_str));
            colour_str = "0000";
        } else if (colour_str.charAt(0) == '#') {
            colour_str = colour_str.substring(1);
        }
        switch(colour_str.length()) {
            case 3: {
                r = hex_char_to_int(colour_str.charAt(0))*0x10;
                g = hex_char_to_int(colour_str.charAt(1))*0x10;
                b = hex_char_to_int(colour_str.charAt(2))*0x10;
                a = 0xff;
                break;
            }
            case 4: {
                r = hex_char_to_int(colour_str.charAt(0))*0x10;
                g = hex_char_to_int(colour_str.charAt(1))*0x10;
                b = hex_char_to_int(colour_str.charAt(2))*0x10;
                a = hex_char_to_int(colour_str.charAt(3))*0x10;
                break;
            }
            case 6: {
                r = hex_char2_to_int(colour_str.charAt(0), colour_str.charAt(1));
                g = hex_char2_to_int(colour_str.charAt(2), colour_str.charAt(3));
                b = hex_char2_to_int(colour_str.charAt(4), colour_str.charAt(5));
                a = 0xff;
                break;
            }
            case 8: {
                r = hex_char2_to_int(colour_str.charAt(0), colour_str.charAt(1));
                g = hex_char2_to_int(colour_str.charAt(2), colour_str.charAt(3));
                b = hex_char2_to_int(colour_str.charAt(4), colour_str.charAt(5));
                a = hex_char2_to_int(colour_str.charAt(6), colour_str.charAt(7));
                break;
            }
            default: {
                throw new RuntimeException(String.format("unexpected hex string length %d", colour_str.length()));
            }
        }
        //return (r<<(8*3)) | (g<<(8*2)) | (b<<8) | a;
        Paint paint = new Paint();
        paint.setARGB(a, r, g, b);
        return paint;
    }

    @Override
    public float getScale() {
        return scale;
    }
}
