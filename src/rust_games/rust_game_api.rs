use core::slice;
use libc;
use std::ffi::CString;

//use libc::{c_int, c_char, size_t, c_void, c_ulong, c_ulonglong};
use libc::{c_char, c_int, c_ulong, c_void, size_t};

// TODO maybe change game_api.h to use int instead...
// apparently the official type in Rust libc for stdbool.h bool is TBD
// https://stackoverflow.com/a/47705543/9596600
// #[allow(non_camel_case_types)]
//type c_bool = bool;
type CBool = bool;

//pub type TimeMs = u32;
pub type TimeMs = c_ulong;

pub const CANVAS_WIDTH: i32 = 480;
pub const CANVAS_HEIGHT: i32 = 480;

#[derive(Copy, Clone, Debug)]
pub enum MouseEvt {
    Up,
    Down,
    Leave,
    AltDown,
    AltUp,
    Alt2Down,
    Alt2Up,
}

#[derive(Copy, Clone, Debug)]
pub enum TextAlign {
    Left,
    Middle,
    Right,
}

#[derive(Copy, Clone, Debug)]
pub struct TouchInfo {
    pub id: i64,
    pub y: f64,
    pub x: f64,
}

pub enum PopupItem<'a> {
	Message { text: &'a str },
	Button { id: i32, text: &'a str },
	Dropdown { id: &'a str, label: &'a str , options: Vec<&'a str> },
}

pub struct PopupInfo<'a> {
	pub title: &'a str,
	pub items: Vec<&'a PopupItem<'a>>,
}

pub struct PopupState {
	// TODO
}

#[derive(Copy, Clone, Debug)]
pub enum OptionType {
	Button = 1,
	Toggle = 2,
}

pub struct OptionInfo {
	pub option_type: OptionType,
	pub label: String,
	
	/* only for toggle */
	pub value: i32,
}


#[repr(C)]
pub struct CCallbacksPtr {
    pub set_game_handle: Option<unsafe extern "C" fn(*mut c_void, *const c_char)>,
    pub get_game_id: Option<unsafe extern "C" fn(*mut c_void, *mut c_char, size_t)>,
    pub draw_graphic:
        Option<unsafe extern "C" fn(*const c_char, c_int, c_int, c_int, c_int, *mut c_void)>,
    pub draw_line: Option<unsafe extern "C" fn(*const c_char, c_int, c_int, c_int, c_int, c_int)>,
    pub draw_text: Option<
        unsafe extern "C" fn(
            *const c_char,
            size_t,
            *const c_char,
            size_t,
            c_int,
            c_int,
            c_int,
            c_int,
        ),
    >,
    pub draw_rect: Option<unsafe extern "C" fn(*const c_char, size_t, c_int, c_int, c_int, c_int)>,

    pub draw_triangle: Option<
        unsafe extern "C" fn(*const c_char, size_t, c_int, c_int, c_int, c_int, c_int, c_int),
    >,
    pub draw_circle: Option<
        unsafe extern "C" fn(
            *const c_char,
            size_t,
            *const c_char,
            size_t,
            c_int,
            c_int,
            c_int,
            c_int,
        ),
    >,
    pub draw_clear: Option<unsafe extern "C" fn()>,
    pub draw_refresh: Option<unsafe extern "C" fn()>,

    pub send_message: Option<unsafe extern "C" fn(*const c_char, size_t, *const c_char, size_t)>,

    pub create_btn: Option<unsafe extern "C" fn(*const c_char, *const c_char, c_int)>,
    pub set_btn_enabled: Option<unsafe extern "C" fn(*const c_char, CBool)>,
    pub set_btn_visible: Option<unsafe extern "C" fn(*const c_char, CBool)>,
    pub hide_popup: Option<unsafe extern "C" fn()>,

    // TODO add params
    pub add_game_option: Option<unsafe extern "C" fn(*const c_char, *const c_void)>,

    pub set_status_msg: Option<unsafe extern "C" fn(*const c_char, size_t)>,
    pub set_status_err: Option<unsafe extern "C" fn(*const c_char, size_t)>,

    pub show_popup: Option<unsafe extern "C" fn(*const c_void, *const c_char, size_t, *const c_void)>,

    pub prompt_string: Option<unsafe extern "C" fn(*const c_char, size_t, *const c_char, size_t)>,

    pub update_timer_ms: Option<unsafe extern "C" fn(c_int) -> c_int>,
    pub delete_timer: Option<unsafe extern "C" fn(c_int)>,

    pub enable_evt: Option<unsafe extern "C" fn(*const c_char, size_t)>,
    pub disable_evt: Option<unsafe extern "C" fn(*const c_char, size_t)>,

    //pub get_time_ms: Option<unsafe extern "C" fn() -> c_ulonglong>,
    pub get_time_ms: Option<unsafe extern "C" fn() -> c_ulong>,
    pub get_time_of_day: Option<unsafe extern "C" fn(*mut c_char, size_t)>,

    pub store_data: Option<unsafe extern "C" fn(*mut c_void, *const c_char, *const u8, size_t)>,
    pub read_stored_data:
        Option<unsafe extern "C" fn(*mut c_void, *const c_char, *mut u8, size_t) -> size_t>,
    pub get_new_session_id: Option<unsafe extern "C" fn() -> c_int>,
    pub get_last_session_id: Option<unsafe extern "C" fn(*const c_char) -> c_int>,

    pub save_state: Option<unsafe extern "C" fn(c_int, *const u8, size_t)>,
    pub has_saved_state_offset: Option<unsafe extern "C" fn(c_int, c_int) -> CBool>,
    pub adjust_saved_state_offset:
        Option<unsafe extern "C" fn(c_int, c_int, *mut u8, size_t) -> size_t>,

    pub draw_extra_canvas: Option<unsafe extern "C" fn(*const c_char, c_int, c_int, c_int, c_int)>,
    pub new_extra_canvas: Option<unsafe extern "C" fn(*const c_char)>,
    pub set_active_canvas: Option<unsafe extern "C" fn(*const c_char)>,
    pub delete_extra_canvases: Option<unsafe extern "C" fn()>,

    //get_user_colour_pref: Option<unsafe extern "C" fn(*mut c_char, size_t) -> size_t>, // TODO
    pub get_user_colour_pref: Option<unsafe extern "C" fn(*mut u8, size_t) -> size_t>,

    pub is_feature_supported: Option<unsafe extern "C" fn(*const c_char, size_t) -> CBool>,

    pub destroy_all: Option<unsafe extern "C" fn()>,
}


// TODO use bindgen or at least replace all of these hardcoded sizes
#[repr(C)]
#[derive(Copy, Clone)]
struct CPopupInfo {
	title: [c_char; 128],
	item_count: i32,
	items: [CPopupItem; 64],
}


#[repr(C)]
#[derive(Copy, Clone)]
struct CPopupItem {
	item_type: i32,
	info: CPopupItemInfo,
}

#[repr(C)]
#[derive(Copy, Clone)]
union CPopupItemInfo {
	msg: CPopupItemInfoMsg,
	btn: CPopupItemInfoBtn,
	dropdown: CPopupItemInfoDropdown,
}

#[repr(C)]
#[derive(Copy, Clone, Debug)]
struct CPopupItemInfoMsg {
	msg: [c_char; 4096],
}

#[repr(C)]
#[derive(Copy, Clone, Debug)]
struct CPopupItemInfoBtn {
	id: i32,
	text: [c_char; 256],
}

#[repr(C)]
#[derive(Copy, Clone, Debug)]
struct CPopupItemInfoDropdown {
	id: i32,
	label: [c_char; 256],
	option_count: i32,
	options: [[c_char; 128]; 16],
}

#[repr(C)]
#[derive(Copy, Clone)]
struct COptionInfo {
	option_type: i32,
	label: [c_char; 256],
	value: i32,
}


fn copy_str_to_c_array(src: &str, dest: &mut [c_char]) {
    let c_str = CString::new(src).unwrap();
    let bytes = c_str.as_bytes_with_nul();
    let len = dest.len().min(bytes.len());
    //dest[..len].copy_from_slice(&bytes[..len]);
    for (i, &byte) in bytes.iter().enumerate().take(len) {
        dest[i] = byte as c_char;
    }
}

impl CCallbacksPtr {
    pub fn draw_rect(&self, fill: &str, y1: i32, x1: i32, y2: i32, x2: i32) {
        let fill_len = fill.len();
        let fill = CString::new(fill).expect("CString::new failed");
        if let Some(draw_rect) = self.draw_rect {
            unsafe {
                draw_rect(fill.as_ptr() as *const c_char, fill_len, y1, x1, y2, x2);
            }
        } else {
            println!("draw_rect is null");
        }
    }

    pub fn draw_text(&self, text: &str, colour: &str, y: i32, x: i32, size: i32, align: TextAlign) {
        let text_len = text.len();
        let text_cstr = CString::new(text).expect("CString::new failed");

        let colour_len = colour.len();
        let colour_cstr = CString::new(colour).expect("CString::new failed");

        // TODO auto generate this from the definition in game_api.h
        let align = match align {
            TextAlign::Left => 1,
            TextAlign::Middle => 0,
            TextAlign::Right => -1,
        };

        if let Some(draw_text) = self.draw_text {
            unsafe {
                (draw_text)(
                    text_cstr.as_ptr() as *const c_char,
                    text_len,
                    colour_cstr.as_ptr() as *const c_char,
                    colour_len,
                    y,
                    x,
                    size,
                    align,
                );
            }
        } else {
            println!("draw_text is null");
        }
    }

    pub fn draw_circle(
        &self,
        fill: &str,
        outline: &str,
        y: i32,
        x: i32,
        radius: i32,
        outline_width: i32,
    ) {
        let fill_len = fill.len();
        let fill = CString::new(fill).expect("CString::new failed");

        let outline_len = outline.len();
        let outline = CString::new(outline).expect("CString::new failed");
        if let Some(draw_circle) = self.draw_circle {
            //draw_circle(fill.as_ptr()    as *const c_char, fill.len(),
            //            outline.as_ptr() as *const c_char, outline.len(),
            unsafe {
                draw_circle(
                    fill.as_ptr(),
                    fill_len,
                    outline.as_ptr(),
                    outline_len,
                    y,
                    x,
                    radius,
                    outline_width,
                );
            }
        } else {
            println!("draw_circle is null");
        }
    }

    pub fn draw_line(&self, line_colour: &str, line_size: i32, y1: i32, x1: i32, y2: i32, x2: i32) {
        let line_colour_cstr = CString::new(line_colour).expect("CString::new failed");
        //let line_colour_cstr: *const c_char = [ '#', '0', '0', '8', '8', '0', '0', 0 as c_char ];
        //let line_colour_cstr = b"#008800\0";
        //println!("calling draw_line...");
        unsafe {
            if let Some(draw_line) = self.draw_line {
                //println!("calling ptr...");
                let line_colour_cstr = line_colour_cstr.as_ptr();
                //let line_colour_cstr = line_colour_cstr.as_bytes_with_nul();
                //let line_colour_cstr = line_colour_cstr as *const i8;
                (draw_line)(line_colour_cstr, line_size, y1, x1, y2, x2);
            //println!("done calling ptr");
            } else {
                println!("draw_line is null");
            }
        }
        //println!("done calling draw_line!");
    }

    pub fn draw_triangle(
        &self,
        fill_colour: &str,
        y1: i32,
        x1: i32,
        y2: i32,
        x2: i32,
        y3: i32,
        x3: i32,
    ) {
        let fill_colour_len = fill_colour.len();
        let fill_colour_cstr = CString::new(fill_colour).expect("CString::new failed");
        unsafe {
            if let Some(draw_triangle) = self.draw_triangle {
                (draw_triangle)(
                    fill_colour_cstr.as_ptr(),
                    fill_colour_len,
                    y1,
                    x1,
                    y2,
                    x2,
                    y3,
                    x3,
                );
            } else {
                println!("draw_triangle is null");
            }
        }
    }

    pub fn draw_clear(&self) {
        if let Some(draw_clear) = self.draw_clear {
            unsafe {
                (draw_clear)();
            }
        } else {
            println!("draw_clear not set");
        }
    }

    pub fn draw_refresh(&self) {
        if let Some(draw_refresh) = self.draw_refresh {
            unsafe {
                (draw_refresh)();
            }
        } else {
            println!("draw_refresh not set");
        }
    }

    pub fn create_btn(&self, btn_id: &str, btn_text: &str, weight: i32) {
        let btn_id_cstr = CString::new(btn_id).expect("CString::new failed");
        let btn_text_cstr = CString::new(btn_text).expect("CString::new failed");

        if let Some(create_btn) = self.create_btn {
            unsafe {
                (create_btn)(btn_id_cstr.as_ptr(), btn_text_cstr.as_ptr(), weight);
            }
        } else {
            println!("create_btn is null");
        }
    }

    pub fn set_btn_enabled(&self, btn_id: &str, is_enabled: bool) {
        let btn_id_cstr = CString::new(btn_id).expect("CString::new failed");

        if let Some(set_btn_enabled) = self.set_btn_enabled {
            unsafe {
                (set_btn_enabled)(btn_id_cstr.as_ptr(), is_enabled);
            }
        } else {
            println!("set_btn_enabled is null");
        }
    }

    pub fn set_status_err(&self, msg: &str) {
        let msg_cstr = CString::new(msg).expect("CString::new failed");
        if let Some(set_status_err) = self.set_status_err {
            unsafe {
                (set_status_err)(msg_cstr.as_ptr(), msg.len());
            }
        } else {
            println!("set_status_err is null");
        }
    }
    pub fn set_status_msg(&self, msg: &str) {
        let msg_cstr = CString::new(msg).expect("CString::new failed");
        if let Some(set_status_msg) = self.set_status_msg {
            unsafe {
                (set_status_msg)(msg_cstr.as_ptr(), msg.len());
            }
        } else {
            println!("set_status_msg is null");
        }
    }

	pub fn add_game_option(&self, option_id: &str, option_info: &OptionInfo) {
		let option_id_cstr = CString::new(option_id).expect("CString::new failed");
		let c_option_info = rust_option_info_to_c(&option_info);
		let c_option_info_ptr: *const COptionInfo = &c_option_info;
		if let Some(add_game_option) = self.add_game_option {
			unsafe {
				(add_game_option)(option_id_cstr.as_ptr(), c_option_info_ptr as *const c_void);
			}
		} else {
			println!("add_game_option is null");
		}
	}

	pub fn show_popup(&self, id: &str, popup_info: &PopupInfo) {
		let popup_id_c_str = CString::new(id).expect("CString::new failed");
		let c_popup_info = rust_popup_info_to_c(popup_info);
		let c_popup_info_ptr: *const CPopupInfo = &c_popup_info;
		let handle = 0 as *const c_void;
		if let Some(show_popup) = self.show_popup {
			unsafe {
				(show_popup)(handle, popup_id_c_str.as_ptr(), id.len(), c_popup_info_ptr as *const c_void);
			}
		} else {
			println!("show_popup is null");
		}
	}

    pub fn get_time_ms(&self) -> TimeMs {
        if let Some(get_time_ms) = self.get_time_ms {
            unsafe {
                return (get_time_ms)();
            }
        } else {
            println!("get_time_ms is null");
            return 0;
        }
    }

    pub fn get_new_session_id(&self) -> i32 {
        if let Some(get_new_session_id) = self.get_new_session_id {
            unsafe {
                return (get_new_session_id)();
            }
        } else {
            println!("get_new_session_id is null");
            return 0;
        }
    }

    pub fn get_last_session_id(&self, game_id: &str) -> Option<i32> {
        let game_id_cstr = CString::new(game_id).expect("CString::new failed");
        if let Some(get_last_session_id) = self.get_last_session_id {
            unsafe {
                let session_id = (get_last_session_id)(game_id_cstr.as_ptr());
                if session_id != -1 {
                    return Some(session_id);
                }
            }
        } else {
            println!("get_last_session_id is null");
        }
        return None;
    }

    pub fn save_state(&self, session_id: i32, state: Vec<u8>) {
        if let Some(save_state) = self.save_state {
            unsafe {
                (save_state)(session_id, state.as_ptr(), state.len());
            }
        } else {
            println!("save_state is null");
        }
    }

    pub fn has_saved_state_offset(&self, session_id: i32, move_id_offset: i32) -> bool {
        if let Some(has_saved_state_offset) = self.has_saved_state_offset {
            unsafe {
                return (has_saved_state_offset)(session_id, move_id_offset);
            }
        } else {
            println!("has_saved_state_offset is null");
            return false;
        }
    }

    pub fn adjust_saved_state_offset(
        &self,
        session_id: i32,
        move_id_offset: i32,
    ) -> Option<Vec<u8>> {
        if let Some(adjust_saved_state_offset) = self.adjust_saved_state_offset {
            let buff_size = 16 * 1024; // TODO define a common constant in C for this max size
            let mut buffer: Vec<u8> = Vec::with_capacity(buff_size);
            let buff_ptr = buffer.as_mut_ptr();
            unsafe {
                let state_len =
                    (adjust_saved_state_offset)(session_id, move_id_offset, buff_ptr, buff_size);
                if state_len > 0 {
                    //let state_vec = Vec::from_raw_parts(buff_ptr, state_len, state_len);
                    //return Some(state_vec);
                    buffer.set_len(state_len as usize);
                    return Some(buffer);
                }
            }
        } else {
            println!("has_saved_state_offset is null");
        }
        return None;
    }

    pub fn get_user_colour_pref(&self) -> String {
        //return "dark"; // TODO
        if let Some(get_user_colour_pref) = self.get_user_colour_pref {
            let buff_size = 512;
            //let mut buffer: Vec<c_char> = Vec::with_capacity(buff_size); // TODO
            let mut buffer: Vec<u8> = Vec::with_capacity(buff_size);
            unsafe {
                let colour_pref_len = (get_user_colour_pref)(buffer.as_mut_ptr(), buff_size);
                if colour_pref_len > 0 {
                    let slice = slice::from_raw_parts(buffer.as_ptr(), colour_pref_len);
                    if let Ok(user_colour_pref) = std::str::from_utf8(slice) {
                        return String::from(user_colour_pref);
                    } else {
                        println!("Error decoding user colour preference string");
                    }
                }
            }
        } else {
            println!("get_user_colour_pref is null");
        }
        return String::from("light");
    }

    pub fn update_timer_ms(&self, dt_ms: c_int) -> c_int {
        if let Some(update_timer_ms) = self.update_timer_ms {
            unsafe {
                return (update_timer_ms)(dt_ms);
            }
        } else {
            println!("update_timer_ms not set");
            return -1;
        }
    }

    pub fn enable_evt(&self, evt_id: &str) {
        if let Some(enable_evt) = self.enable_evt {
            let evt_id_cstr = CString::new(evt_id).expect("CString::new failed");
            unsafe {
                (enable_evt)(evt_id_cstr.as_ptr(), evt_id.len());
            }
        } else {
            println!("enable_evt is null");
        }
    }
}

fn default_c_popup_item() -> CPopupItem {
	CPopupItem {
		item_type: 0,
		info: CPopupItemInfo {
			msg: CPopupItemInfoMsg {
				msg: [ 0; 4096],
			},
		},
	}
}

fn rust_popup_info_to_c(popup_info: &PopupInfo) -> CPopupInfo {
	let mut c_popup_info = CPopupInfo {
		title: [ 0; 128],
		item_count: 0,
		items: [default_c_popup_item(); 64],
	};
	copy_str_to_c_array(&popup_info.title, &mut c_popup_info.title);

	for (item_idx, &item) in popup_info.items.iter().enumerate() {
		match item {
			PopupItem::Message { text } => {
				c_popup_info.items[item_idx].item_type = 1;
				copy_str_to_c_array(&text, unsafe {&mut c_popup_info.items[item_idx].info.msg.msg });
			},
			PopupItem::Button { id, text } => {
				c_popup_info.items[item_idx].item_type = 2;
				c_popup_info.items[item_idx].info.btn.id = *id;
				println!("creating popup button with text {}", text);
				copy_str_to_c_array(&text, unsafe { &mut c_popup_info.items[item_idx].info.btn.text });
			},
			PopupItem::Dropdown { id: _, label: _, options: _ } => {
				c_popup_info.items[item_idx].item_type = 3;
				panic!("popup dropdown not implemented in Rust yet");
				// TODO
			},
		}
	}
	c_popup_info.item_count = popup_info.items.len() as i32;

	c_popup_info
}

fn rust_option_info_to_c(option_info: &OptionInfo) -> COptionInfo {
	let mut c_option_info = COptionInfo {
		option_type: option_info.option_type as i32,
		label: [0; 256],
		value: option_info.value,
	};
	copy_str_to_c_array(&option_info.label, &mut c_option_info.label);

	c_option_info
}

pub trait AlexGamesApi {
    fn callbacks(&self) -> &CCallbacksPtr;

    fn init(&mut self, callbacks: &'static CCallbacksPtr);
    fn start_game(&mut self, state: Option<(i32, Vec<u8>)>);
    fn update(&mut self, dt_ms: i32);
    fn handle_user_clicked(&mut self, pos_y: i32, pos_x: i32);
    fn handle_btn_clicked(&mut self, btn_id: &str);
    fn handle_mousemove(&mut self, pos_y: i32, pos_x: i32, buttons: i32) {
        println!(
            "handle_mousemove unimplemented, y={}, x={} buttons={:x}",
            pos_y, pos_x, buttons
        );
    }
    fn handle_mouse_evt(&mut self, evt_id: MouseEvt, pos_y: i32, pos_x: i32, buttons: i32) {
        println!(
            "handle_mouse_evt unimplemented, evt_id={:#?}, y={}, x={}, buttons={:x}",
            evt_id, pos_y, pos_x, buttons
        );
    }
    fn handle_touch_evt(&mut self, evt_id: &str, touches: Vec<TouchInfo>) {
        println!(
            "handle_touch_evt unimplemented, evt_id={:#?}, touches={:#?}",
            evt_id, touches
        );
    }

	fn handle_popup_btn_clicked(&mut self, popup_id: &str, btn_idx: i32, _popup_state: &PopupState) {
		println!("handle_popup_btn_clicked unimplemented");
	}

	fn handle_game_option_evt(&mut self, option_id: &str, option_type: OptionType, value: i32) {
		println!("handle_game_option_evt unimplemented, option_id={option_id}, option_type={option_type:#?}");
	}


    fn get_state(&self) -> Option<Vec<u8>> {
        println!("get_state not implemented");
        None
    }
}
