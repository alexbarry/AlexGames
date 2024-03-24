package net.alexbarry.alexgames.graphics;

import android.content.res.Resources;
import android.graphics.BitmapFactory;
import android.graphics.drawable.Drawable;
import android.graphics.Bitmap;
import android.util.Log;

import java.io.File;
import java.util.HashMap;
import java.util.Map;

class GraphicsManager {

    private static final String TAG = "GraphicsManager";

    private static final Map<String, Integer> img_id_map = new HashMap<>();
    private static final Map<String, String>  img_id_to_path = new HashMap<>();
    //private static final String IMG_FS_PATH = "/data/data/net.alexbarry.alexgames/cache";

    private static final Map<String,Drawable> cached_drawables = new HashMap<>();

    private File cacheDir;

    static {
        // TODO I'm not sure if this is the best way for now.
        // In the interest of speed, just load these like the lua scripts--
        // from a file on the file system, and put them there with something like
        // `adb push src/lua_scripts/ /data/data/net.alexbarry.alexgames/cache/src/lua_scripts`
        // then eventually I can figure out how to include them in the assets folder nicely.
        // But I want to support reading arbitrary scripts/images from the file system
        // eventually, so assuming it's easy, I might as well do that one first


        //img_id_map.put("board", R.id.derp);

        img_id_to_path.put("board" ,                  "img/wooden_board.png");
        img_id_to_path.put("piece_black" ,            "img/black_piece.png");
        img_id_to_path.put("piece_white" ,            "img/white_piece.png");
        img_id_to_path.put("piece_highlight" ,        "img/piece_highlight.png");

        img_id_to_path.put("piece_king_icon" ,        "img/piece_king_icon.png");

        img_id_to_path.put("card_diamonds" ,          "img/cards/diamonds.png");
        img_id_to_path.put("card_hearts"   ,          "img/cards/hearts.png");
        img_id_to_path.put("card_spades"   ,          "img/cards/spades.png");
        img_id_to_path.put("card_clubs"    ,          "img/cards/clubs.png");
        img_id_to_path.put("card_blank"    ,          "img/cards/blank_card.png");
        img_id_to_path.put("card_facedown" ,          "img/cards/card_facedown.png");
        img_id_to_path.put("card_highlight" ,         "img/cards/card_highlight.png");

        img_id_to_path.put("more_info_btn" ,          "img/more_info_btn.png");

		img_id_to_path.put("backgammon_triangle_black",      "img/backgammon/triangle_black.png");
		img_id_to_path.put("backgammon_triangle_white",      "img/backgammon/triangle_white.png");
		img_id_to_path.put("backgammon_triangle_highlight",  "img/backgammon/triangle_highlight.png");

		img_id_to_path.put("chess_rook_white",               "img/chess/rook_white.png");
		img_id_to_path.put("chess_knight_white",             "img/chess/knight_white.png");
		img_id_to_path.put("chess_bishop_white",             "img/chess/bishop_white.png");
		img_id_to_path.put("chess_pawn_white",               "img/chess/pawn_white.png");
		img_id_to_path.put("chess_queen_white",              "img/chess/queen_white.png");
		img_id_to_path.put("chess_king_white",               "img/chess/king_white.png");

		img_id_to_path.put("chess_rook_black",               "img/chess/rook_black.png");
		img_id_to_path.put("chess_knight_black",             "img/chess/knight_black.png");
		img_id_to_path.put("chess_bishop_black",             "img/chess/bishop_black.png");
		img_id_to_path.put("chess_pawn_black",               "img/chess/pawn_black.png");
		img_id_to_path.put("chess_queen_black",              "img/chess/queen_black.png");
		img_id_to_path.put("chess_king_black",               "img/chess/king_black.png");


		img_id_to_path.put("dice1",                "img/dice/dice1.png");
		img_id_to_path.put("dice2",                "img/dice/dice2.png");
		img_id_to_path.put("dice3",                "img/dice/dice3.png");
		img_id_to_path.put("dice4",                "img/dice/dice4.png");
		img_id_to_path.put("dice5",                "img/dice/dice5.png");
		img_id_to_path.put("dice6",                "img/dice/dice6.png");


        img_id_to_path.put("minesweeper_mine" ,       "img/minesweeper/mine.png");
        img_id_to_path.put("minesweeper_box1" ,       "img/minesweeper/box1.png");
        img_id_to_path.put("minesweeper_box2" ,       "img/minesweeper/box2.png");
        img_id_to_path.put("minesweeper_box3" ,       "img/minesweeper/box3.png");
        img_id_to_path.put("minesweeper_box4" ,       "img/minesweeper/box4.png");
        img_id_to_path.put("minesweeper_box5" ,       "img/minesweeper/box5.png");
        img_id_to_path.put("minesweeper_box6" ,       "img/minesweeper/box6.png");
        img_id_to_path.put("minesweeper_box7" ,       "img/minesweeper/box7.png");
        img_id_to_path.put("minesweeper_box8" ,       "img/minesweeper/box8.png");
        img_id_to_path.put("minesweeper_box_unclicked"    ,   "img/minesweeper/box_unclicked.png");
        img_id_to_path.put("minesweeper_box_empty"        ,   "img/minesweeper/box_empty.png");
        img_id_to_path.put("minesweeper_box_flagged_red"  ,   "img/minesweeper/box_flagged_red.png");
        img_id_to_path.put("minesweeper_box_flagged_blue" ,   "img/minesweeper/box_flagged_blue.png");

        img_id_to_path.put("hospital_floor_tile" ,            "img/hospital/floor_tile.png");
        img_id_to_path.put("hospital_doctor1"    ,            "img/hospital/doctor1.png");
        img_id_to_path.put("hospital_doctor2"    ,            "img/hospital/doctor2.png");
        img_id_to_path.put("hospital_doctor3"    ,            "img/hospital/doctor3.png");
        img_id_to_path.put("hospital_doctor4"    ,            "img/hospital/doctor4.png");
        img_id_to_path.put("hospital_patient_in_bed"    ,     "img/hospital/patient_in_bed.png");
        img_id_to_path.put("hospital_patient_in_bed_flipped", "img/hospital/patient_in_bed-flipped.png");
        img_id_to_path.put("hospital_ui_dirpad"  ,            "img/hospital/ui/dirpad.png");
        img_id_to_path.put("hospital_ui_thumb_buttons"  ,     "img/hospital/ui/thumb_buttons.png");
        img_id_to_path.put("hospital_bed"        ,            "img/hospital/bed1.png");
        img_id_to_path.put("hospital_bed_flipped",            "img/hospital/bed1-flipped.png");
        img_id_to_path.put("hospital_iv_bag"     ,            "img/hospital/iv_stand_bag1.png");
        img_id_to_path.put("hospital_defib"      ,            "img/hospital/defibrillator_sabrina.png");
        img_id_to_path.put("hospital_ventilator" ,            "img/hospital/ventilator.png");
        img_id_to_path.put("hospital_xray_sheet" ,            "img/hospital/xray_sheet.png");
        img_id_to_path.put("hospital_xray_source" ,            "img/hospital/xray_source.png");
        img_id_to_path.put("hospital_ui_patient_needs_bg" ,            "img/hospital/patient_need_icons/bg.png");
        img_id_to_path.put("hospital_ui_patient_needs_bg_fixer" ,      "img/hospital/patient_need_icons/bg_fixer.png");
        img_id_to_path.put("hospital_ui_patient_needs_attention" ,     "img/hospital/patient_need_icons/attention.png");
        img_id_to_path.put("hospital_ui_patient_needs_low_fluids" ,    "img/hospital/patient_need_icons/low_fluids.png");
        img_id_to_path.put("hospital_ui_patient_needs_low_oxygen" ,    "img/hospital/patient_need_icons/low_oxygen.png");
        img_id_to_path.put("hospital_ui_patient_needs_no_heartbeat" ,  "img/hospital/patient_need_icons/no_heartbeat.png");
        img_id_to_path.put("hospital_ui_patient_needs_broken_bone" ,   "img/hospital/patient_need_icons/broken_bone.png");
        img_id_to_path.put("hospital_ui_green_cross" ,                 "img/hospital/green_cross_icon.png");

		img_id_to_path.put("space_ship1",                "img/space/ship1.png");
		img_id_to_path.put("swarm_grass_bg1",            "img/swarm/grass_bg1.png");
		img_id_to_path.put("swarm_broccoli",             "img/swarm/broccoli.png");
		img_id_to_path.put("swarm_hammer",               "img/swarm/hammer.png");


		img_id_to_path.put("brick_wall", "img/brick_wall.png");
		img_id_to_path.put("spider",     "img/spider.png");

    }

    private Resources res;

    void init(Resources res, File cacheDir) {
        this.res = res;
        this.cacheDir = cacheDir;
    }

    Drawable get_drawable(String img_id_str) {
        //int img_android_id = get_android_id_from_id_str(img_id_str);
        //return res.getDrawable(img_android_id);

        if (cached_drawables.containsKey(img_id_str)) {
            return cached_drawables.get(img_id_str);
        }

        String img_path = img_id_to_path.get(img_id_str);
        String IMG_FS_PATH = cacheDir.getAbsolutePath();
        img_path = IMG_FS_PATH + "/" + img_path;
        // Bitmap bitmap = BitmapFactory.decodeFile(img_path);
        //Log.d(TAG, String.format("Loading graphic from file \"%s\"", img_path));
        Drawable d = Drawable.createFromPath(img_path);
        cached_drawables.put(img_id_str, d);
        return d;
    }

    private static int get_android_id_from_id_str(String img_id_str) {
        return img_id_map.get(img_id_str);
    }
}
