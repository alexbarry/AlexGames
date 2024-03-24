package net.alexbarry.alexgames.graphics;

public interface IAlexGamesCanvas {
    void draw_graphic(String img_id, int y, int x, int width, int height, int angle_degrees);
    void draw_line(String colour, int line_size, int y1, int x1, int y2, int x2);
    void draw_text(String text, String colour, int y, int x, int size, int align);

    void draw_rect(String colour, int y_start, int x_start, int y_end, int x_end);

    void draw_circle(String fill_colour, String outline_colour, int y, int x, int radius);

    void draw_clear();

    float getScale();

    // TODO remove
    boolean post(Runnable r);

    void draw_refresh();
}
