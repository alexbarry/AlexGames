function init_game_api(game_name) {
	console.log("[init] init_game_api");
	let rc = Module.ccall("init_game_api", "number",
		["string", "number"],
		[game_name, game_name.length]);
	if (rc == 0) {
		throw ("init_game_api from js returning " + rc);
	}
	return rc;
}

function start_game(ptr) {
	console.log("[init] start_game");
	let rc = Module.ccall("start_game", null,
		["number"],
		[ptr]);
	if (rc == 0) {
		throw ("start_game from js returning " + rc);
	}
	return rc;
}

function destroy_game(ptr) {
	disable_all_events();
	let rc = Module.ccall("destroy_game", null,
		["number"],
		[ptr]);
	if (rc == 0) {
		throw ("destroy_game from js returning " + rc);
	}
}

function get_game_list() {
	let game_count = Module.ccall("get_game_count", "number", [], []);
	let list = new Array(game_count);
	for (let i=0; i<game_count; i++) {
		let str_ptr = Module.ccall("get_game_name", "number", ["number"], [i]);
		let str = Module.UTF8ToString(str_ptr);
		list[i] = str;
	}
	return list;
}

/**
 * Called when the screen needs to be drawn.
 *
 * By default this only happens initially,
 * but if the `set_timer_period_ms(period_ms)` API is called then
 * it is called again every `period_ms` milliseconds.
 *
 * TODO: maybe it makes sense to have a separate API for this
 */
function draw_board(ptr, dt_ms) {
	if (dt_ms === undefined) {
		dt_ms = 0;
	}
	return Module.ccall("draw_board", null, ["number", "number"], [ptr, dt_ms]);
}

// Previously this was an API to receive a string from the user.
// I used it in Go for command line input, and then completely forgot about it,
// since using mouse/touch seemed a lot more natural.
// I'm repurposing it now to receive strings from the user for "enter your name",
// specifically in the poker chips game, where a name is helpful to identify who
// is who in the real world.
// I'm also adding an "is_cancelled" argument, to indicate that the "prompt string" popup
// was closed.
function handle_user_string_input(ptr, user_input, is_cancelled) {
	return Module.ccall("handle_user_string_input", null,
		["number", "string", "number", "number"],
		[ptr, user_input, user_input.length, is_cancelled]);
}

function handle_user_clicked(ptr, pos_y, pos_x) {
	pos_y = Math.floor(pos_y);
	pos_x = Math.floor(pos_x);
	return Module.ccall("handle_user_clicked", null,
		["number", "number", "number"],
		[ptr, pos_y, pos_x]);
}

function handle_mousemove(ptr, pos_y, pos_x, buttons) {
	pos_y = Math.floor(pos_y);
	pos_x = Math.floor(pos_x);
	return Module.ccall("handle_mousemove", null,
		["number", "number", "number", "number"],
		[ptr, pos_y, pos_x, buttons]);
}

function handle_mouse_evt(ptr, evt_id, pos_y, pos_x, buttons) {
	pos_y = Math.floor(pos_y);
	pos_x = Math.floor(pos_x);
	return Module.ccall("handle_mouse_evt", null,
		["number", "number", "number", "number", "number"],
		[ptr, evt_id, pos_y, pos_x, buttons]);
}

function handle_wheel_evt(ptr, delta_y, delta_x) {
	return Module.ccall("handle_wheel_changed", null,
		["number", "number", "number"],
		[ptr, delta_y, delta_x]);
}

function handle_key_evt(ptr, evt_id, code) {
	let val =  Module.ccall("handle_key_evt", ["number"],
		["number", "string", "string"],
		[ptr, evt_id, code]);
	return !!val;
}

// writes javascript string `str` to address `ptr`,
// up to max size `ptr_size`.
// Adds null terminator.
function write_str(ptr, ptr_size, str) {
	if (ptr_size <= 0) {
		console.error("write_str: ptr_size is ", ptr_size);
		return;
	}
	// loop from start of string to end inclusive (including null terminator)
	for (let i=0; i<=str.length; i++) {
		if (i >= ptr_size) {
			console.error("write_str: ptr_size", ptr_size, "too small for string len", str.length, "str: ", str);
			Module.setValue(ptr, 0);
			return;
		}

		let char_val;
		if (i < str.length) {
			char_val = str.charCodeAt(i);
		} else if (i == str.length) {
			char_val = 0;
		} else {
			console.error("programming error: write_str, i = ", i, ", str.length =", str.length);
			char_val = 0;
			Module.setValue(ptr + i, char_val);
			return;
		}
		
		console.log("writing value", char_val, "to ptr", ptr + i);
		Module.setValue(ptr + i, char_val);
	}
}

function handle_touch_evt(canvas, ptr, evt) {
	evt.preventDefault();
	let rect = canvas.getBoundingClientRect();
	let sizeof_double = 8;
	let sizeof_id     = 8;
	let sizeof_elem = 2 * sizeof_double + sizeof_id;
	let touch_ary_ptr = Module._malloc(evt.changedTouches.length * sizeof_elem);
	try {
		for (let i=0; i<evt.changedTouches.length; i++) {
			let touch = evt.changedTouches[i];
			let offset = touch_ary_ptr + i * sizeof_elem;
			const x = (touch.clientX - rect.left)/(rect.right - rect.left)* canvas.width;
			const y = (touch.clientY - rect.top)/(rect.bottom - rect.top) * canvas.height;

			Module.setValue(offset + 0,                         touch.identifier, 'i64');
			Module.setValue(offset + sizeof_id,                 y,                'double');
			Module.setValue(offset + sizeof_id + sizeof_double, x,                'double');
		}

		return Module.ccall("handle_touch_evt", null,
			["number", "string", "number", "number", "number"],
			[ptr, evt.type, evt.type.length, touch_ary_ptr, evt.changedTouches.length]);
	} finally {
		Module._free(touch_ary_ptr);
	}
}

function i8_to_u8(val) {
	if (val < 0) { return 256 + val; }
	else { return val; }
}

function newByteArray(msg) {
	let msg_ptr = Module._malloc(msg.length);
	for (let i=0; i<msg.length; i++) {
		Module.setValue(msg_ptr + i, (msg.charCodeAt(i)), 'i8');
	}
	return msg_ptr;
}

function handle_msg_received(ptr, msg_src, msg) {
	let msg_ptr = newByteArray(msg);
	try {
		let rc = Module.ccall("handle_msg_received", null,
			["number", "string", "number", "number", "number"],
			[ptr, msg_src, msg_src.length, msg_ptr, msg.length]);
		return rc;
	} finally {
		Module._free(msg_ptr);
	}
}

function handle_btn_clicked(ptr, btn_id) {
	return Module.ccall("handle_btn_clicked", null,
		["number", "string"],
		[ptr, btn_id]);
}

function write_popup_state_to_mem(dst, popup_state) {
	let ptr = dst;
	Module.setValue(ptr, popup_state.items.length, 'i32');
	ptr += 4;
	for (let item of popup_state.items) {
		Module.setValue(ptr, item.id, 'i32');
		ptr += 4;

		Module.setValue(ptr, item.selected, 'i32');
		ptr += 4;
	}
}

function handle_popup_btn_clicked(ptr, popup_id, btn_idx, popup_state) {
	let popup_state_buff = Module._malloc(4096);
	try {
		write_popup_state_to_mem(popup_state_buff, popup_state);
		return Module.ccall("handle_popup_btn_clicked", null,
			["number", "string", "number", "number"],
			[ptr, popup_id, btn_idx, popup_state_buff]);
	} finally {
		Module._free(popup_state_buff);
	}
}

function handle_game_option_evt(ptr, option_type, option_id, value) {
	try {
		return Module.ccall("handle_game_option_evt", null,
		                    ["number", "number", "string", "number"],
		                    [ptr, option_type, option_id, value]);
	} finally {
	}
}

function start_game_b64(ptr, state_b64, session_id) {
	if (session_id === undefined) {
		session_id = 0;
	}
	console.log("start_game_b64", state_b64);
	return Module.ccall("start_game_b64", null,
		["number", "number", "string", "number"],
		[ptr, session_id, state_b64, state_b64.length]);
}

function get_byteary_func(ptr, func_name, buff_len) {
	let buff = Module._malloc(buff_len);
	try {
		let state_len = Module.ccall(func_name, ["number"],
		                             ["number", "number", "number"],
		                             [ptr, buff, buff_len]);

		let state_str = Module.UTF8ToString(buff, state_len);
		return state_str;
	} finally {
		Module._free(buff);
	}
}

function get_state(ptr) {
	return get_byteary_func(ptr, "get_state", 64*1024);
}

function get_init_state(ptr) {
	return get_byteary_func(ptr, "get_init_state", 64*1024);
}

function new_file(ptr, fname) {
	let f = Module.ccall("new_file", "number", ["number", "string"], [ptr, fname]);
	return f;
}

function dump_array_buffer(dataView) {
	let buff = new Uint8Array(16);
	try {
	let i=0;
	while (i < dataView.byteLength) {
		//let slice = arrayBuffer.slice(i, i+16);
		//console.log(slice);
		//i += 16;
		for (let j=0; j<16; j++) {
			buff[j] = dataView.getUint8(i+j);
		}
		console.log(buff);
		i += 16;
	}
	} finally {
		Module._free(buff);
	}
}

// void write_to_file(void *L, FILE *f, void *data, size_t data_len) {
function write_array_buffer_to_file(ptr, f, arrayBuffer) {
	let dataView = new DataView(arrayBuffer);
	return write_data_view_to_file(ptr, f, dataView);
}
function write_data_view_to_file(ptr, f, dataView) {
	const CHUNK_SIZE = 4096;
	let buff = new Uint8Array(CHUNK_SIZE);
	try {
	let file_pos = 0;
	while (file_pos < dataView.byteLength) {
		let buff_len = CHUNK_SIZE;
		for (let i=0; i<CHUNK_SIZE; i++) {
			if (file_pos+i >= dataView.byteLength) {
				buff_len = i;
				break;
			}
			buff[i] = dataView.getUint8(file_pos+i);
		}
		let valid_buff = buff.slice(0, buff_len);
		file_pos += CHUNK_SIZE;
		//console.log(valid_buff);
		Module.ccall("write_to_file", null,
		            ["number", "number", "array", "number"],
		            [ptr, f, valid_buff, valid_buff.length]);
	}
	} finally {
		Module._free(buff);
	}
/*
	let buff = Module._malloc(data_js_ary.length);
	try {
	for (let i=0; i<data_js_ary.length; i++) {
		Module.setValue(buff + i, data_js_ary[i], 'i8');
	}
	Module.ccall("write_to_file", null,
	             ["number", "number", "number", "number"],
	             [ptr, f, buff, data_js_ary.length]);
	} finally {
		Module._free(buff);
	}
*/
}

function unzip_file(ptr, fname, dst_name) {
	return Module.ccall("unzip_file", null,
	                    ["number", "string", "string"],
	                    [ptr, fname, dst_name]);
}

function close_file(ptr, f) {
	Module.ccall("close_file", [], ["number", "number"], [ptr, f]);
}

function dump_file(ptr, fname) {
	Module.ccall("dump_file", [], ["number", "string"], [ptr, fname]);
}

// called from C code
function writeStringToPtr(dst_ptr, dst_ptr_size, word) {
	for (let i=0; i<word.length; i++) {
		if (i >= dst_ptr_size) {
			console.error("writeStrToPtr: word.length >= dst_ptr_size", word, dst_ptr_size);
			assert(false);
			return;
		}
		Module.setValue(dst_ptr + i, word.charCodeAt(i), 'i8');
	}
}



function update_dict() {
	Module.ccall("update_dict", null, [], []);
}

// For debugging only
function lua_run_cmd(ptr, cmd) {
	return Module.ccall("lua_run_cmd", null,
		["number", "string", "number"],
		[ptr, cmd, cmd.length]);
}
