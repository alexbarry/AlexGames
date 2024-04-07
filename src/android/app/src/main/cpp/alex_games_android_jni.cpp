#include <string.h>

#include <jni.h>
#include <android/log.h>

#include<string.h>
#include<iostream>
#include<memory>


// TODO failing to open files.
// Maybe do something like this:
// https://stackoverflow.com/questions/13317387/how-to-get-file-in-assets-from-android-ndk
// will need to override the lua file opening API... not sure
// how to do that. What the hell is it using now?

#include "game_api.h"

#if 0
extern "C"
FILE* fopen(const char *fname, const char *mode) {
	return NULL;
}
#endif


extern "C" {
JNIEXPORT void JNICALL
Java_net_alexbarry_alexgames_AlexGamesJni_jniHello( JNIEnv* env, jobject thiz );

JNIEXPORT void JNICALL
Java_net_alexbarry_alexgames_AlexGamesJni_jniInit(JNIEnv* env, jobject thiz,
                                                  jstring data_dir_path_jstr,
                                                  jstring game_id_jstr);
JNIEXPORT void JNICALL
Java_net_alexbarry_alexgames_AlexGamesJni_jniDrawBoard(JNIEnv* env, jobject thiz,
                                                       jint dt_ms);

JNIEXPORT void JNICALL
Java_net_alexbarry_alexgames_AlexGamesJni_jniHandleUserClicked(JNIEnv* env, jobject thiz,
                                                               jint pos_y, jint pos_x);

JNIEXPORT void JNICALL
Java_net_alexbarry_alexgames_AlexGamesJni_jniHandleMousemove(JNIEnv* env, jobject thiz,
                                                             jint pos_y, jint pos_x, jint buttons);

JNIEXPORT void JNICALL
Java_net_alexbarry_alexgames_AlexGamesJni_jniHandleMouseEvt(JNIEnv* env, jobject thiz,
                                                            jint mouse_evt_id,
                                                            jint pos_y, jint pos_x);

JNIEXPORT void JNICALL
Java_net_alexbarry_alexgames_AlexGamesJni_jniHandleTouchEvt(JNIEnv* env, jobject thiz,
                                                            jstring evt_id_jstr, jlong touch_id,
                                                            jint pos_y, jint pos_x);

JNIEXPORT void JNICALL
Java_net_alexbarry_alexgames_AlexGamesJni_jniHandlePopupBtnClicked(JNIEnv* env, jobject thiz,
                                                            jstring popup_id, jint btn_id);
}

// TODO keep as part of the object
static void *L = nullptr;

// TODO pass in to each callback from Lua API
static JNIEnv* g_env = nullptr;
static jclass  g_cls = nullptr;
static jobject g_thiz = nullptr;



void log_jni(std::string str) {
	__android_log_write(ANDROID_LOG_INFO, "alex_games_android_jni.cpp", str.c_str());
}

void log_jni_err(std::string str) {
    __android_log_write(ANDROID_LOG_ERROR, "alex_games_android_jni.cpp", str.c_str());
}

static void alex_log(const char *format, va_list args) {
	char s[1024];
	vsnprintf(s, sizeof(s), format, args);
	log_jni(std::string(s));
}

static void alex_logf(const char *format, ...) {
	va_list args;
	va_start(args, format);
	alex_log(format, args);
	va_end(args);
}

static void alex_log_err(const char *format, va_list args) {
	char s[1024];
	vsnprintf(s, sizeof(s), format, args);
	log_jni_err(std::string(s));
}

static jstring cstr_to_jstr(JNIEnv* env, const char *str, int max_len) {
	size_t str_len = strnlen(str, max_len);
	jchar *jchar_ary = (jchar*)malloc(str_len*sizeof(jchar));
	for (int i=0; i<str_len; i++) {
		jchar_ary[i] = str[i];
	}

	jstring jstr = env->NewString(jchar_ary, str_len);
#warning "uncomment this free"
	free(jchar_ary);
	return jstr;
}

// TODO this compiles and links but I don't think I see the logs.
// There must be a better way to override printf?
#if 0
int fprintf(FILE *f, const char *format, ...) {
	va_list args;
	va_start(args, format);
	alex_log(format, args);
	va_end(args);
}
int printf(const char *format, ...) {
	va_list args;
	va_start(args, format);
	alex_log(format, args);
	va_end(args);
}
#endif

static void jni_set_game_handle(const void *L, const char *game_id) {
	// TODO
}


static void jni_get_game_id(const void *L, char *game_id_out, size_t game_id_out_max_len) {
	// TODO
}

static void jni_draw_graphic(const char *img_id,
                             int y, int x,
                             int width, int height, const struct draw_graphic_params *params) {
	
	if (g_env->ExceptionCheck() == JNI_TRUE) {
		return;
	}
	static jmethodID mid = NULL;
	if (mid == NULL) {
		mid = g_env->GetMethodID(g_cls, "draw_graphic", "(Ljava/lang/String;IIIII)V");
	}
	jstring img_id_jstr = cstr_to_jstr(g_env, img_id, 1024);
	g_env->CallVoidMethod(g_thiz, mid, img_id_jstr, y, x, width, height, params->angle_degrees);
	// TODO handle param->flip_[yx]
	if (params->flip_y || params->flip_x) {
		alex_log_err("draw_graphic( ... param->flip_[yx]) not implemented yet on android\n");
	}
	g_env->DeleteLocalRef(img_id_jstr);
}

static void jni_draw_line(const char *colour_str, int line_size, int y1, int x1, int y2, int x2) {
	if (g_env->ExceptionCheck() == JNI_TRUE) {
		return;
	}
	static jmethodID mid = NULL;
	if (mid == NULL) {
		mid = g_env->GetMethodID(g_cls, "draw_line", "(Ljava/lang/String;IIIII)V");
	}
	jstring colour_jstr = cstr_to_jstr(g_env, colour_str, 1024);
	g_env->CallVoidMethod(g_thiz, mid, colour_jstr, line_size, y1, x1, y2, x2);
	g_env->DeleteLocalRef(colour_jstr);
}

static void jni_draw_text(const char *text_str, size_t text_str_len,
	                  const char *colour_str, size_t colour_str_len,
	                  int y, int x, int size, int align) {
	if (g_env->ExceptionCheck() == JNI_TRUE) {
		return;
	}
	static const char method_id_str[] = "(Ljava/lang/String;Ljava/lang/String;IIII)V";
	static jmethodID mid = NULL;
	if (mid == NULL) {
		mid = g_env->GetMethodID(g_cls, "draw_text", method_id_str);
	}
	jstring text_jstr   = cstr_to_jstr(g_env, text_str,   text_str_len);
	jstring colour_jstr = cstr_to_jstr(g_env, colour_str, colour_str_len);
	g_env->CallVoidMethod(g_thiz, mid, text_jstr, colour_jstr, y, x, size, align);
	g_env->DeleteLocalRef(text_jstr);
	g_env->DeleteLocalRef(colour_jstr);
}

static void jni_draw_rect(const char *fill_colour_str, size_t fill_colour_len,
	                  int y_start, int x_start,
	                  int y_end  , int x_end) {
	if (g_env->ExceptionCheck() == JNI_TRUE) {
		return;
	}
	static jmethodID mid = NULL;
	if (mid == NULL) {
		mid = g_env->GetMethodID(g_cls, "draw_rect", "(Ljava/lang/String;IIII)V");
	}
	jstring colour_jstr = cstr_to_jstr(g_env, fill_colour_str, fill_colour_len);
	g_env->CallVoidMethod(g_thiz, mid, colour_jstr, y_start, x_start, y_end, x_end);
	g_env->DeleteLocalRef(colour_jstr);
}

static void jni_draw_triangle(const char *fill_colour_str,    size_t fill_colour_len,
	                          int y1, int x1,
	                          int y2, int x2,
	                          int y3, int x3) {
	// TODO
}


static void jni_draw_circle(const char *fill_colour_str,    size_t fill_colour_len,
	                    const char *outline_colour_str, size_t outline_colour_len,
	                    int y, int x, int radius, int outline_width) {
	if (g_env->ExceptionCheck() == JNI_TRUE) {
		return;
	}
	static jmethodID mid = NULL;
	if (mid == NULL) {
		mid = g_env->GetMethodID(g_cls, "draw_circle", "(Ljava/lang/String;Ljava/lang/String;III)V");
	}
	jstring fill_colour_jstr    = cstr_to_jstr(g_env, fill_colour_str,    fill_colour_len);
	jstring outline_colour_jstr = cstr_to_jstr(g_env, outline_colour_str, outline_colour_len);
	g_env->CallVoidMethod(g_thiz, mid, fill_colour_jstr, outline_colour_jstr, y, x, radius);
	g_env->DeleteLocalRef(fill_colour_jstr);
	g_env->DeleteLocalRef(outline_colour_jstr);
}

static void jni_draw_clear(void) {
	if (g_env->ExceptionCheck() == JNI_TRUE) {
		return;
	}
	static jmethodID mid = NULL;
	if (mid == NULL) {
		mid = g_env->GetMethodID(g_cls, "draw_clear", "()V");
	}
	g_env->CallVoidMethod(g_thiz, mid);
}

static void jni_draw_refresh(void) {
	if (g_env->ExceptionCheck() == JNI_TRUE) {
		return;
	}
	static jmethodID mid = NULL;
	if (mid == NULL) {
		mid = g_env->GetMethodID(g_cls, "draw_refresh", "()V");
	}
	g_env->CallVoidMethod(g_thiz, mid);
}

static void jni_send_message(const char *dst, size_t dst_len, const char *msg, size_t msg_len) {
	if (g_env->ExceptionCheck() == JNI_TRUE) {
		return;
	}
	static jmethodID mid = NULL;
	if (mid == NULL) {
		mid = g_env->GetMethodID(g_cls, "send_message", "(Ljava/lang/String;[BI)V");
	}

	jstring dst_jstr = cstr_to_jstr(g_env, dst, dst_len);
	// TODO could allocate this just once instead
	jbyteArray msg_jbyteary = g_env->NewByteArray(msg_len);
	g_env->SetByteArrayRegion(msg_jbyteary, 0, msg_len, (const jbyte*)msg);
	g_env->CallVoidMethod(g_thiz, mid, dst_jstr, msg_jbyteary, (jint)msg_len);
	g_env->DeleteLocalRef(dst_jstr);
	g_env->DeleteLocalRef(msg_jbyteary);
}

static void jni_create_btn(const char *btn_id_str, const char *btn_text_str, int weight) {
	// TODO
}

static void jni_set_btn_enabled(const char *btn_id_str, bool enabled) {
	// TODO
}
static void jni_set_btn_visible(const char *btn_id_str, bool visible) {
	// TODO
}
static void jni_hide_popup(void) {
	// TODO
}

static void jni_add_game_option(const char *option_id, const struct option_info *option_info) {
	// TODO
}

static void jni_set_status_msg(const char *msg, size_t msg_len) {
	char str[1024];
	snprintf(str, sizeof(str), "Received lua status msg: %s", msg);
	log_jni(str);

}
static void jni_set_status_err(const char *msg, size_t msg_len) {
	char str[1024];
	snprintf(str, sizeof(str), "Received lua err msg: %s", msg);
	log_jni(str);
	// TODO
}
static void jni_show_popup(void *L, const char *popup_id, size_t popup_id_str_len,
                           const struct popup_info *info) {
	// TODO
	//
	if (g_env->ExceptionCheck() == JNI_TRUE) {
		return;
	}
	jmethodID mid = NULL;
	jclass    str_clsid = NULL;
#define JSTR_PROTO "Ljava/lang/String;"
	static const char prototype[] = "(" JSTR_PROTO JSTR_PROTO JSTR_PROTO "[" JSTR_PROTO ")V";
	if (mid == NULL) {
		mid = g_env->GetMethodID(g_cls, "show_popup", prototype);
		str_clsid = g_env->FindClass("java/lang/String");
	}

	jstring popup_id_jstr = cstr_to_jstr(g_env, popup_id, popup_id_str_len);
	jstring title_jstr    = cstr_to_jstr(g_env, info->title,    sizeof(info->title));
	jstring msg_jstr      = nullptr;
    // TODO update this to support an arbitrary list of popup stuff (many messages, buttons, or a dropdown)
    for (int i=0; i < info->item_count; i++) {
        const struct popup_item *item = &info->items[i];
        if (item->type == POPUP_ITEM_TYPE_MSG) {
            msg_jstr = cstr_to_jstr(g_env, item->info.msg.msg, sizeof(item->info.msg));
            break;
        }
    }
    int btn_count = 0;
    for (int i=0; i < info->item_count; i++) {
        const struct popup_item *item = &info->items[i];
        if (item->type == POPUP_ITEM_TYPE_BTN) {
            btn_count++;
        }
    }
    alex_log("Found %d buttons", btn_count);
	jobjectArray btn_jstrs = g_env->NewObjectArray(btn_count, str_clsid, NULL);
	jstring *btn_strs = (jstring*)malloc(btn_count*sizeof(jstring));
    int btn_str_idx = 0;
	for (int i=0; i<info->item_count; i++) {
        const struct popup_item *item = &info->items[i];
        if (item->type == POPUP_ITEM_TYPE_BTN) {
            btn_strs[btn_str_idx] = cstr_to_jstr(g_env, item->info.btn.text,
                                                 sizeof(item->info.btn.text));
            g_env->SetObjectArrayElement(btn_jstrs, btn_str_idx, btn_strs[btn_str_idx]);
            btn_str_idx++;
        }
	}
    alex_log("Populated strings for  %d buttons", btn_str_idx);

    // TODO update this to support an arbitrary list of popup stuff (many messages, buttons, or a dropdown)
	g_env->CallVoidMethod(g_thiz, mid, popup_id_jstr, title_jstr, msg_jstr, btn_jstrs);
	g_env->DeleteLocalRef(popup_id_jstr);
	g_env->DeleteLocalRef(title_jstr);
	g_env->DeleteLocalRef(msg_jstr);
	g_env->DeleteLocalRef(btn_jstrs);
	for (int i=0; i<btn_count; i++) {
		g_env->DeleteLocalRef(btn_strs[i]);
	}
	free(btn_strs);
	
}
static int jni_update_timer_ms(int update_period_ms) {
    if (g_env->ExceptionCheck() == JNI_TRUE) {
        return -1;
    }
    static jmethodID mid = NULL;
    if (mid == NULL) {
        mid = g_env->GetMethodID(g_cls, "set_update_timer_ms", "(J)I");
    }
    jlong update_period_ms_long = update_period_ms;
    jint handle =  g_env->CallIntMethod(g_thiz, mid, update_period_ms_long);

	return handle;
}

static void jni_delete_timer(jint handle) {
    static jmethodID mid = NULL;
    if (mid == NULL) {
        mid = g_env->GetMethodID(g_cls, "delete_timer", "(I)V");
    }

	g_env->CallVoidMethod(g_thiz, mid, handle);
}

static void jni_enable_evt(const char *evt_id_str, size_t evt_id_len) {
	// TODO
}
static long jni_get_time_ms(void) {
	// TODO
	return 0;
}

static void jni_prompt_string(const char *prompt_title, size_t prompt_title_len,
                              const char *prompt_msg,   size_t prompt_msg_len) {
	// TODO
}
static void jni_store_data(void *L, const char *key, const uint8_t *value, size_t value_len) {
	// TODO
}
static size_t jni_read_stored_data(void *L, const char *key, uint8_t *value_out, size_t max_val_len) {
	// TODO
	return -1;
}

static void jni_disable_evt(const char *evt_id_str, size_t evt_id_len) {

}

static size_t jni_get_time_of_day(char *time_str, size_t max_time_str_len) {

}

static int jni_get_new_session_id(void) {
	return 0; // TODO
}

static int jni_get_last_session_id(const char *game_id) {
	return 0; // TODO
}

static void jni_save_state(int session_id, const uint8_t *state, size_t state_len) {

}

static bool jni_get_saved_state_offset(int session_id, int move_id_offset) { return false; }
static int  jni_has_saved_state_offset(int session_id, int move_id_offset, uint8_t *state_out, size_t state_out_max) { return 0; }

static void jni_draw_extra_canvas(const char *img_id,
                                  int y, int x,
                                  int width, int height) {}
static void jni_new_extra_canvas(const char *canvas_id) {}
static void jni_set_active_canvas(const char *canvas_id) {}
static void jni_delete_extra_canvases(void) {}

static size_t jni_get_user_colour_pref(char *colour_pref_out, size_t max_colour_pref_out_len) {
	snprintf(colour_pref_out, max_colour_pref_out_len, "");
	return 0;
}

static bool jni_is_feature_supported(const char *feature_id, size_t feature_id_len) {
	// TODO
	return false;
}

static void jni_destroy_all(void) {
	// TODO
}


JNIEXPORT void JNICALL
Java_net_alexbarry_alexgames_AlexGamesJni_jniHello( JNIEnv* env, jobject thiz )
{
	log_jni("hello, world!");
}

static const struct game_api_callbacks api = {
	jni_set_game_handle,
	jni_get_game_id,
	jni_draw_graphic,
	jni_draw_line,
	jni_draw_text,
	jni_draw_rect,
	jni_draw_triangle,
	jni_draw_circle,
	jni_draw_clear,
	jni_draw_refresh,
	jni_send_message,
	jni_create_btn,
	jni_set_btn_enabled,
	jni_set_btn_visible,
	jni_hide_popup,
	jni_add_game_option,
	jni_set_status_msg,
	jni_set_status_err,
	jni_show_popup,
	jni_prompt_string,
	jni_update_timer_ms,
	jni_delete_timer,
	jni_enable_evt,
	jni_disable_evt,
	jni_get_time_ms,
	jni_get_time_of_day,
	jni_store_data,
	jni_read_stored_data,

	jni_get_new_session_id,
	jni_get_last_session_id,
	jni_save_state,
	jni_get_saved_state_offset,
	jni_has_saved_state_offset,

	jni_draw_extra_canvas,
	jni_new_extra_canvas,
	jni_set_active_canvas,
	jni_delete_extra_canvases,

	jni_get_user_colour_pref,

	jni_is_feature_supported,
	jni_destroy_all
};

JNIEXPORT void JNICALL
Java_net_alexbarry_alexgames_AlexGamesJni_jniInit(JNIEnv* env, jobject thiz,
                                                  jstring data_dir_path_jstr,
                                                  jstring game_id_jstr) {
	set_alex_log_func(alex_log);
	set_alex_log_err_func(alex_log_err);

	const char *game_id_cstr = env->GetStringUTFChars(game_id_jstr, NULL);
	size_t game_id_cstr_len = env->GetStringLength(game_id_jstr);
	g_env = env;
	g_thiz = thiz;
	jclass cls = env->FindClass("net/alexbarry/alexgames/AlexGamesJni");
	g_cls = reinterpret_cast<jclass>(env->NewGlobalRef(cls));
	if (g_cls == NULL) {
		log_jni("Could not find class AlexGames");
		return;
	}

	jboolean is_copy;
	const char *data_dir_path_cstr = (env)->GetStringUTFChars(data_dir_path_jstr, &is_copy);
	alex_log("Setting alexgames root dir to data_dir_path = \"%s\"\n", data_dir_path_cstr);
	alex_set_root_dir(data_dir_path_cstr);
	(env)->ReleaseStringUTFChars(data_dir_path_jstr, data_dir_path_cstr);

	L = alex_init_game(&api, game_id_cstr, (int)game_id_cstr_len);
	if (L == NULL) {
		log_jni("init_lua_api returned NULL");
	}
	env->ReleaseStringUTFChars(game_id_jstr, game_id_cstr);
}

JNIEXPORT void JNICALL
Java_net_alexbarry_alexgames_AlexGamesJni_jniDrawBoard(JNIEnv* env, jobject thiz, jint dt_ms) {
	g_env = env;
	g_thiz = thiz;
	//g_cls = env->FindClass("net/alexbarry/alexgames/AlexGamesJni");
	game_api->draw_board(L, dt_ms);
}

JNIEXPORT void JNICALL
Java_net_alexbarry_alexgames_AlexGamesJni_jniHandleUserClicked(JNIEnv* env, jobject thiz,
                                                               jint pos_y, jint pos_x) {
	g_env = env;
	g_thiz = thiz;
	//g_cls = env->FindClass("net/alexbarry/alexgames/AlexGamesJni");
	game_api->handle_user_clicked(L, pos_y, pos_x);
}

JNIEXPORT void JNICALL
Java_net_alexbarry_alexgames_AlexGamesJni_jniHandleMousemove(JNIEnv* env, jobject thiz,
                                                             jint pos_y, jint pos_x, jint buttons) {
	g_env = env;
	g_thiz = thiz;
	//g_cls = env->FindClass("net/alexbarry/alexgames/AlexGamesJni");
	game_api->handle_mousemove(L, pos_y, pos_x, buttons);
}

JNIEXPORT void JNICALL
Java_net_alexbarry_alexgames_AlexGamesJni_jniHandleMouseEvt(JNIEnv* env, jobject thiz,
                                                            jint mouse_evt_id,
                                                            jint pos_y, jint pos_x) {
	g_env = env;
	g_thiz = thiz;
	//g_cls = env->FindClass("net/alexbarry/alexgames/AlexGamesJni");
	int buttons = 0; // TODO
	game_api->handle_mouse_evt(L, mouse_evt_id, pos_y, pos_x, buttons);
}

// jniHandleTouchEvent(evt_id_str, touch_id, touch_x, touch_y);
JNIEXPORT void JNICALL
Java_net_alexbarry_alexgames_AlexGamesJni_jniHandleTouchEvt(JNIEnv* env, jobject thiz,
                                                            jstring evt_id_jstr, jlong touch_id,
                                                            jint pos_y, jint pos_x) {

	if (env->ExceptionCheck() == JNI_TRUE) {
		return;
	}
	g_env = env;
	g_thiz = thiz;
	//g_cls = env->FindClass("net/alexbarry/alexgames/AlexGamesJni");
	const char *touch_evt_id_str = env->GetStringUTFChars(evt_id_jstr, NULL);
	size_t touch_evt_id_str_len  = env->GetStringLength(evt_id_jstr);
	int changed_touches_len = 1;
	uint8_t *changed_touches = (uint8_t*)malloc(changed_touches_len*8*3);
	//uint8_t *changed_touches = (uint8_t*)malloc(changed_touches_len*(sizeof(long) + 2*sizeof(double)));
	/*
	long *touch_id_ptr  = (long*)  (changed_touches);
	double *touch_y_ptr = (double*)(changed_touches +   sizeof(long));
	double *touch_x_ptr = (double*)(changed_touches + sizeof(long) + sizeof(double));
	*/
	long   *touch_id_ptr =   (long*)(changed_touches);
	double *touch_y_ptr  = (double*)(changed_touches +   8);
	double *touch_x_ptr  = (double*)(changed_touches + 2*8);
	*touch_id_ptr = touch_id;
	*touch_y_ptr  = 1.0*pos_y;
	*touch_x_ptr  = 1.0*pos_x;

	if (L == NULL) {
		log_jni("handle_touch_evt, L = null");
		return;
	}
	
	game_api->handle_touch_evt(L, touch_evt_id_str, touch_evt_id_str_len, 
	                           changed_touches, changed_touches_len);
	free(changed_touches);
	env->ReleaseStringUTFChars(evt_id_jstr, touch_evt_id_str);
}

JNIEXPORT void JNICALL
Java_net_alexbarry_alexgames_AlexGamesJni_jniHandlePopupBtnClicked(JNIEnv* env, jobject thiz,
                                                                   jstring popup_id_jstr, jint btn_id) {

	g_env = env;
	g_thiz = thiz;
	const char *popup_id_cstr = env->GetStringUTFChars(popup_id_jstr, NULL);
	game_api->handle_popup_btn_clicked(L, popup_id_cstr, btn_id, NULL); // TODO add popup state here
}

extern "C"
JNIEXPORT jint JNICALL
Java_net_alexbarry_alexgames_AlexGamesJni_jniGetGameListCount(JNIEnv* env, jobject thiz) {
	return alex_get_game_count();
}

extern "C"
JNIEXPORT jstring JNICALL
Java_net_alexbarry_alexgames_AlexGamesJni_jniGetGameId(JNIEnv* env, jobject thiz, jint idx) {
	const char *cstr = alex_get_game_name(idx);
	jstring jstr = cstr_to_jstr(env, cstr, 1024);
	return jstr;
}

extern "C"
JNIEXPORT void JNICALL
Java_net_alexbarry_alexgames_AlexGamesJni_jniHandleMessageReceived(JNIEnv* env, jobject thiz,
                                                                   jstring src,
                                                                   jbyteArray data, jint data_len) {
	g_env  = env;
	g_thiz = thiz;
	const char *src_cstr      = env->GetStringUTFChars(src, NULL);
	size_t      src_cstr_len  = env->GetStringLength(src);
	jbyte      *data_bytes    = env->GetByteArrayElements(data, NULL);

	game_api->handle_msg_received(L, src_cstr, src_cstr_len, (const char *)data_bytes, data_len);
}

extern "C"
JNIEXPORT void JNICALL
Java_net_alexbarry_alexgames_AlexGamesJni_jniStartGame(JNIEnv* env, jobject thiz,
                                                                   jint session_id,
                                                                   jbyteArray serialized_state) {
	g_env  = env;
	g_thiz = thiz;

    alex_log("Calling game_api->start_game, game_api=%p\n", game_api);
	// TODO pass session_id and serialized_state
	game_api->start_game(L, 0, NULL, 0);
}
