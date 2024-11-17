mod rust_game_api;

mod gem_match;
mod libs;
mod table_tennis;
mod reversi;
mod trivia;

use std::ptr;
use std::slice;

//use libc::{size_t, c_char, c_void};
use libc::{c_int, c_void, size_t};

use gem_match::gem_match_main;
use reversi::reversi_main;
use trivia::trivia_main;
use table_tennis::table_tennis_main;
use rust_game_api::{AlexGamesApi, CCallbacksPtr, MouseEvt, TouchInfo, PopupState};

// A pointer to this struct is returned to C, and then passed back
// to the rust APIs. A pointer to AlexGamesApi is needed, and also
// an identifier to know which struct to convert it to.
// NOTE: even though the core game logic only needs to call the `AlexGamesApi`
// trait functions, Rust still needs to know which structure to convert it to
// under the hood.
struct AlexGamesHandle {
    //api: Box<dyn AlexGamesApi>,
    api: *mut dyn AlexGamesApi,
    game_id: String,
}

#[repr(C)]
pub struct TouchInfoCStruct {
    pub id: i64,
    pub y: f64,
    pub x: f64,
}

fn get_rust_game_init_func(
    game_id: &str,
) -> Option<fn(&'static CCallbacksPtr) -> Box<dyn AlexGamesApi + '_>> {
    return match game_id {
        "reversi" => Some(reversi_main::init_reversi),
        "gem_match" => Some(gem_match_main::init_gem_match),
        "table_tennis" => Some(table_tennis_main::init_table_tennis),
        "trivia" => Some(trivia_main::init_trivia),
        _ => None,
    };
}

fn find_null_terminator(str_ptr: *const u8, max_bytes: usize) -> Option<usize> {
    let mut str_end_pos: usize = 0;
    for i in 0..=max_bytes {
        let val = unsafe { *str_ptr.add(i) };
        println!("Checking i={}, val is {:#?}", i, val);
        if val == 0 {
            str_end_pos = i;
            println!("breaking");
            break;
        }
        if i == max_bytes {
            println!("Could not find terminating null in first {} bytes of string passed to handle_btn_clicked", max_bytes);
            return None;
        }
    }
    return Some(str_end_pos);
}

fn c_str_to_str(str_ptr: *const u8, str_len: Option<usize>) -> String {
    // TODO does this call `find_null_terminator` whether it is needed or not?
    let str_len = str_len
        .unwrap_or(find_null_terminator(str_ptr, 1024).expect("could not find null terminator"));

    let bytes_slice = unsafe { std::slice::from_raw_parts(str_ptr, str_len) };

    let str_slice = std::str::from_utf8(bytes_slice).expect("could not convert C string to string");

    return String::from(str_slice);
}

// TODO is static okay here? It isn't truly static, but ownership is not managed by rust
fn handle_void_ptr_to_trait_ref(handle: *mut c_void) -> &'static mut dyn AlexGamesApi {
    let handle = handle as *mut AlexGamesHandle;
    let handle = unsafe { handle.as_mut().expect("handle null?") };

    let api: *mut dyn AlexGamesApi = match handle.game_id.as_str() {
        "reversi" => handle.api as *mut reversi_main::AlexGamesReversi,
        "gem_match" => handle.api as *mut gem_match_main::AlexGamesGemMatch,
        "table_tennis" => handle.api as *mut table_tennis_main::AlexGamesTableTennis,
        "trivia" => handle.api as *mut trivia_main::AlexGamesTrivia,
        _ => panic!("unhandled game_id passed to handle_void_ptr_to_trait_ref"),
    };

    return unsafe { api.as_mut().expect("handle.api null?") };
}

// TODO these should use libc types (c_int, etc)
#[no_mangle]
pub extern "C" fn rust_game_api_handle_user_clicked(handle: *mut c_void, pos_y: i32, pos_x: i32) {
    println!("rust_handle_user_clicked: {} {}", pos_y, pos_x);
    let handle = handle_void_ptr_to_trait_ref(handle);
    //println!("rust_handle_user_clicked: {:#?}", handle.handle_user_clicked);
    handle.handle_user_clicked(pos_y, pos_x);
}

#[no_mangle]
pub extern "C" fn rust_game_api_handle_btn_clicked(handle: *mut c_void, btn_id_cstr: *const u8) {
    let handle = handle_void_ptr_to_trait_ref(handle);
    let btn_id = c_str_to_str(btn_id_cstr, None);
    handle.handle_btn_clicked(&btn_id);
}

#[no_mangle]
pub extern "C" fn rust_game_api_handle_mousemove(
    handle: *mut c_void,
    pos_y: i32,
    pos_x: i32,
    buttons: i32,
) {
    let handle = handle_void_ptr_to_trait_ref(handle);
    handle.handle_mousemove(pos_y, pos_x, buttons);
}

#[no_mangle]
pub extern "C" fn rust_game_api_handle_mouse_evt(
    handle: *mut c_void,
    mouse_evt_id: i32,
    pos_y: i32,
    pos_x: i32,
    buttons: i32,
) {
    let handle = handle_void_ptr_to_trait_ref(handle);
    let mouse_evt_id = match mouse_evt_id {
        1 => MouseEvt::Up,
        2 => MouseEvt::Down,
        3 => MouseEvt::Leave,
        4 => MouseEvt::AltDown,
        5 => MouseEvt::AltUp,
        6 => MouseEvt::Alt2Down,
        7 => MouseEvt::Alt2Up,
        _ => {
            panic!("unhandled mouse_evt_id {}", mouse_evt_id);
        }
    };
    handle.handle_mouse_evt(mouse_evt_id, pos_y, pos_x, buttons);
}

#[no_mangle]
pub extern "C" fn rust_game_api_handle_touch_evt(
    handle: *mut c_void,
    evt_id_cstr: *const u8,
    evt_id_str_len: c_int,
    changed_touches: *const TouchInfoCStruct,
    changed_touches_len: c_int,
) {
    let handle = handle_void_ptr_to_trait_ref(handle);
    let evt_id = c_str_to_str(evt_id_cstr, Some(evt_id_str_len as usize));
    let mut touches = Vec::<TouchInfo>::new();
    for i in 0..changed_touches_len {
        let c_touch = changed_touches.wrapping_add(i as usize);
        let c_touch = unsafe { &(*c_touch) };
        touches.push(TouchInfo {
            id: c_touch.id,
            y: c_touch.y,
            x: c_touch.x,
        });
    }
    handle.handle_touch_evt(&evt_id, touches);
}


#[no_mangle]
pub fn rust_game_api_handle_popup_btn_clicked(handle: *mut c_void, popup_id: *const u8, btn_idx: i32, _popup_state: *const c_void) {
    let handle = handle_void_ptr_to_trait_ref(handle);
	let popup_id = c_str_to_str(popup_id, None);
	let popup_state = PopupState {}; // TODO add real state here
	handle.handle_popup_btn_clicked(&popup_id, btn_idx, &popup_state);
}

#[no_mangle]
pub extern "C" fn rust_game_api_update(handle: *mut c_void, dt_ms: i32) {
    let handle = handle_void_ptr_to_trait_ref(handle);
    //println!("rust_update: {} (dbg: {:#?}, {:#?}", dt_ms, handle.api, handle.api.update);
    handle.update(dt_ms);
}

#[no_mangle]
pub extern "C" fn rust_game_api_start_game(
    handle: *mut c_void,
    session_id: i32,
    state_ptr: *const u8,
    state_len: usize,
) {
    println!("rust_game_api_start_game, handle={:#?}", handle);
    let handle = handle_void_ptr_to_trait_ref(handle);
    //let handle = handle as *mut dyn AlexGamesApi;
    //let handle: &mut dyn AlexGamesApi = unsafe { &mut *(handle as *mut dyn AlexGamesApi) };
    //let handle = Box::from_raw(handle as *mut dyn AlexGamesApi);
    let mut session_id_and_state: Option<(i32, Vec<u8>)> = None;
    if state_len > 0 {
        unsafe {
            let slice = slice::from_raw_parts(state_ptr, state_len);
            session_id_and_state = Some((session_id, Vec::from(slice)));
        }
    }
    handle.start_game(session_id_and_state);
}

#[no_mangle]
pub extern "C" fn rust_game_api_get_state(
    handle: *mut c_void,
    state_out: *mut u8,
    state_out_max_len: size_t,
) -> size_t {
    let handle = handle_void_ptr_to_trait_ref(handle);
    println!("rust_game_api_get_state");
    let state = handle.get_state();

    if !state.is_some() {
        return 0;
    }
    let state = state.expect("state should be some at this point");

    if state.len() > state_out_max_len {
        handle.callbacks().set_status_err(&format!(
            "get_state: state is {} bytes long but buffer is only {}",
            state_out_max_len,
            state.len()
        ));
        // TODO can I return -1 here? I don't know if I even checked for this case
        // before.
        return 0;
    }

    unsafe {
        ptr::copy_nonoverlapping(state.as_ptr(), state_out, state.len());
    }

    return state.len();
}

#[no_mangle]
pub extern "C" fn rust_game_supported(game_str_ptr: *const u8, game_str_len: usize) -> bool {
    let game_id = c_str_to_str(game_str_ptr, Some(game_str_len));

    println!("Game ID is {}, hello from rust!", game_id);

    return get_rust_game_init_func(&game_id).is_some();
}

#[no_mangle]
pub extern "C" fn start_rust_game_rust(
    game_str_ptr: *const u8,
    game_str_len: size_t,
    callbacks: *const CCallbacksPtr,
) -> *mut c_void {
    let game_id = c_str_to_str(game_str_ptr, Some(game_str_len));

    println!("Game ID is {}, hello from rust!", game_id);

    let game_init_fn = get_rust_game_init_func(&game_id).expect("game id not handled by rust");

    let callbacks = unsafe { callbacks.as_ref().expect("callbacks null?") };

    let api = game_init_fn(callbacks);

    // tell rust that we are giving up ownership of this struct
    // and passing a raw pointer to C
    let api = Box::into_raw(api);
    println!("api = {:#?}", api);

    Box::into_raw(Box::from(AlexGamesHandle {
        api: api,
        game_id: game_id,
    })) as *mut c_void
}

#[no_mangle]
pub extern "C" fn rust_game_api_destroy_game(handle: *mut c_void) {
    let api = handle_void_ptr_to_trait_ref(handle);

    // free the pointers
    unsafe {
        let _ = Box::from_raw(handle);
        let _ = Box::from_raw(api);
    }
}
