// TODO figure out how to get these from the C header
const OPTION_TYPE_BTN = 1;
const OPTION_TYPE_TOGGLE = 2;

const POPUP_ITEM_TYPE_MSG      = 1;
const POPUP_ITEM_TYPE_BTN      = 2;
const POPUP_ITEM_TYPE_DROPDOWN = 3;

// TODO rename from "gfx" to something generic like state
function new_gfx(canvas, graphics, popup, status_msg, status_err, game_options_div) {
	let gfx = {
		game_id: UNSET_GAME_ID,
		ptr: null,
		main_canvas: canvas,
		graphics: graphics,
		lua_btn_count: 0,
		lua_btn_ids: new Map(),

		last_timer_fired_ms: undefined,

		popup_shown: false,
		popup: popup,
		popup_info: [],

		game_options: game_options_div,
		option_elems_to_id: new Map(),

		enter_sent: false,

		key_evts_enabled: false,

		mouse_alt_evt_enabled: false,
		mouse_btns_down: 0,

		status_msg: status_msg,
		status_err: status_err,
		handle_user_string_input: handle_user_string_input,
		update_timers: new Set(),

		active_canvas: canvas,
		extra_canvases: new Map(),

		/**
		 * Keys present in this map should not preventDefault() if "control" is pressed.
		 * And for now I'm making them not get passed to the game at all (though I'm not sure about this).
		 * The goal here is so that games can blindly respond to Ctrl L (when using movement keys HJKL),
		 * and not need to check the meta key state like "control".
		 */
		control_keys_do_not_prevent_default: new Map(),
	};

	let meta_keys = [
		"ControlLeft",
		"ControlRight",
	];

	// Maybe all keys should not be passed to the game if you hold control.
	// I'm not familiar with most browser shortcuts.
	let control_keys_do_not_prevent_default = [
		"KeyH",
		"KeyJ",
		"KeyK",
		"KeyL",
	];

	for (let key of control_keys_do_not_prevent_default) {
		gfx.control_keys_do_not_prevent_default.set(key, true);
	}

	return gfx;
}

function draw_graphic(gfx, img_id, y, x, width, height, params) {
	if (!gfx.graphics.has(img_id)) {
		const err_msg = `img_id "${img_id}" not found`;
		console.error(err_msg);
		set_status_err(gfx, err_msg);
		return;
	}
	let img = gfx.graphics.get(img_id);
	let ctx = gfx.active_canvas.getContext("2d");
	let ctx_saved = false;

	if (params.angle_degrees != 0) {
		ctx.save();
		//ctx.translate(x, y);
		ctx.translate(x - 0*width/2, y - 0*height/2);
		ctx.rotate(params.angle_degrees*Math.PI/180);
		//y = 0;
		//x = 0;
		y = -height/2;
		x = -width/2;
		ctx_saved = true;
	} else {
		// optimizing by just translating rather than saving canvas and rotating 0 degrees.
		// Should be possible to remove this entirely and always ctx.save() and rotate(0)
		y += -height/2;
		x += -width/2;
	}

	// TODO I don't know if this works for images that are both
	// flipped and rotated
	if (params.flip_x || params.flip_y) {
		if (!ctx_saved) {
			ctx.save();
		}
		let scaleX = 1;
		let scaleY = 1;
		if (params.flip_x) {
			x += width;
			scaleX = -1;
		}
		if (params.flip_y) {
			y += height;
			scaleY = -1;
		}
		ctx.translate(x, y)
		ctx.scale(scaleX, scaleY);
		x = 0;
		y = 0;
		ctx_saved = true;
	}

	let filter_str = "";

	if (params.invert) {
		filter_str += "invert(100%) ";
	}

	// Note that brightness has to be after inverting,
	// otherwise decreased brightness actually makes things brighter.
	if (params.brightness_percent == null) {
		console.error("unexpected params.brightness_percent == null, should be 100");
	} else if (params.brightness_percent != 100) {
		filter_str += " brightness(" + (params.brightness_percent/100) + ") ";
	}
	if (filter_str.length > 0) {
		ctx.filter = filter_str;
	}
	ctx.drawImage(img, x, y, width, height);
	ctx.filter = "none";

	if (ctx_saved) {
		ctx.restore();
	}
}

/** Draws one of the gfx.extra_canvases on the active canvas */
function draw_extra_canvas(gfx, canvas_id, y, x, width, height, params) {
	if (!gfx.extra_canvases.has(canvas_id)) {
		let msg = "canvas_id \"" + canvas_id + "\"not found";
		console.error(msg);
		set_status_err(gfx, msg);
		return;
	}
	let canvas_to_read = gfx.extra_canvases.get(canvas_id);
	if (!canvas_to_read) {
		console.error("canvas_to_read is ", canvas_to_read);
		return;
	}

	let ctx = gfx.active_canvas.getContext("2d");
	ctx.drawImage(canvas_to_read, x, y, width, height);
}


function draw_line(gfx, colour, line_size, y1, x1, y2, x2) {
	let ctx = gfx.active_canvas.getContext("2d");
	ctx.beginPath();
	ctx.lineWidth = line_size;
	ctx.strokeStyle = colour;
	ctx.moveTo(x1, y1);
	ctx.lineTo(x2, y2);
	ctx.stroke();
	ctx.closePath();
}

function draw_text(gfx, text, colour, y1, x1, size, align, angle_degree) {
	let ctx = gfx.active_canvas.getContext("2d");
	ctx.beginPath();
	ctx.font = size + "pt Arial";
	ctx.fillStyle = colour;
	switch(align) {
		case -1: ctx.textAlign = 'right';  break;
		case  0: ctx.textAlign = 'center'; break;
		case  1: ctx.textAlign = 'left';   break;
		default:
			console.error("Unexpected align val ", align);
			break;
	}
	ctx.fillText(text, x1, y1);
	ctx.stroke();
	ctx.closePath();
}

function draw_rect(gfx, fill_colour, y_start, x_start, y_end, x_end) {
	let ctx = gfx.active_canvas.getContext("2d");
	// TODO why aren't rect() and fill() working?

	//ctx.beginPath();
	ctx.fillStyle = fill_colour;
	//ctx.rect(x_start, y_start, (x_end - x_start)/2, (y_end - y_start)/2);
	ctx.fillRect(x_start, y_start, (x_end - x_start), (y_end - y_start));
	//console.log("Drawing rect with params", fill_colour, x_start, y_start, x_end - x_start, y_end - y_start);
	//ctx.closePath();
	//ctx.fill();
}

function draw_triangle(gfx, fill_colour, y1, x1, y2, x2, y3, x3) {
	console.log(`draw_triangle(fill=${fill_colour}, {${y1}, ${x1}}, {${y2}, ${x2}}, {${y3}, ${x3}})`);
	let ctx = gfx.active_canvas.getContext("2d");
	ctx.beginPath();
	ctx.fillStyle   = fill_colour;
	ctx.strokeStyle = null;
	ctx.lineWidth   = 0;
	ctx.moveTo(x1, y1);
	ctx.lineTo(x2, y2);
	ctx.lineTo(x3, y3);
	ctx.lineTo(x1, y1);
	ctx.fill();
	ctx.closePath();
}

function draw_circle(gfx, fill_colour, outline_colour, y, x, radius, outline_width) {
	//console.log(`draw_circle(fill=${fill_colour}, outline=${outline_colour}, y=${y}, x=${x}, radius=${radius}, outline_width=${outline_width})`);
	let ctx = gfx.active_canvas.getContext("2d");
	ctx.beginPath();
	ctx.arc(x, y, radius, 0, 2*Math.PI);
	ctx.fillStyle   = fill_colour;
	ctx.strokeStyle = outline_colour;
	ctx.lineWidth   = 1;
	if (outline_width > 0) {
		ctx.lineWidth   = outline_width;
	}
	ctx.fill();
	ctx.stroke();
	ctx.closePath();
}

function draw_clear(gfx) {
	let ctx = gfx.active_canvas.getContext("2d");
	ctx.clearRect(0, 0, gfx.active_canvas.width, gfx.active_canvas.height);
}

function create_btn(gfx, btn_lua_id, name, weight) {
	let button_row = document.getElementById("game_button_row");

	let btn = document.createElement("button");
	btn.innerText = name;
	btn.id = "btn_lua_" + gfx.lua_btn_count;
	btn.classList.add("game_btn");
	gfx.lua_btn_count++;
	btn.style.flex = weight;

	gfx.lua_btn_ids.set(btn_lua_id, btn.id);
	btn.addEventListener('click', function () {
		console.log("User clicked button", btn_lua_id);
		handle_btn_clicked(gfx.ptr, btn_lua_id);
	});

	button_row.appendChild(btn);
}

function set_btn_enabled(gfx, btn_lua_id, enabled) {
	let btn_id = gfx.lua_btn_ids.get(btn_lua_id);
	if (!btn_id) {
		console.error("Could not find btn_lua_id", btn_lua_id);
		return;
	}
	let btn = document.getElementById(btn_id);
	if (btn == null) {
		console.error("Could not find btn_id", btn_id);
		return;
	}
	btn.disabled = !enabled;
}

function set_btn_visible(gfx, btn_lua_id, visible) {
	let btn_id = gfx.lua_btn_ids.get(btn_lua_id);
	if (!btn_id) {
		console.error("Could not find btn_lua_id", btn_lua_id);
		return;
	}
	let btn = document.getElementById(btn_id);
	if (btn == null) {
		console.error("Could not find btn_id", btn_id);
		return;
	}

	let display;
	if (visible) {
		display = "block";
	} else {
		display = "none";
	}
	btn.style.display = display;
}

function get_popup_state(gfx) {
	let popup_state = {
		items: []
	};

	for (let elem of gfx.popup_info) {
		if (elem.type == "dropdown") {
			popup_state.items.push({id: elem.id, selected: elem.elem.selectedIndex});
		} else {
			console.error("unhandled elem.type", elem.type, elem);
		}
	}

	return popup_state;
}

function show_popup(gfx, popup_id, info) {
	gfx.popup.style.display = "block";

	gfx.popup.innerHTML = "";
	let title_node = document.createElement("h2");
	title_node.innerText = info.title;
	gfx.popup.appendChild(title_node);

	gfx.popup_info = [];

	let item_id = 0;
	for (let item of info.items) {
		if (item.type == POPUP_ITEM_TYPE_MSG) {
			let message = item.msg;
			for (let line of message.split("\n")) {
				let p_node = document.createElement("p");
				p_node.innerText = line;
				gfx.popup.appendChild(p_node);
			}
		} else if (item.type == POPUP_ITEM_TYPE_BTN) {
			let btn_id = item.id;
			let button_txt = item.text;
			let button = document.createElement("button");
			button.innerText = button_txt;
			button.addEventListener('click', function () {
				console.debug("Button id ", btn_id, "clicked in popup", popup_id);
				handle_popup_btn_clicked(gfx.ptr, popup_id, btn_id, get_popup_state(gfx));
			});
			gfx.popup.appendChild(button);
		} else if (item.type == POPUP_ITEM_TYPE_DROPDOWN) {
			let dropdown_label = document.createElement("label");
			dropdown_label.classList.add("popup_dropdown_label");
			dropdown_label.innerText = item.label;
			let dropdown = document.createElement("select");
			gfx.popup_info.push({type: "dropdown", id: item.id, elem: dropdown});
			dropdown.classList.add("popup_dropdown");
			dropdown.id="popup_dropdown";
			for (let option_text of item.options) {
				let option = document.createElement("option");
				option.innerText = option_text;
				dropdown.appendChild(option);
			}
			let dropdown_container = document.createElement("div");
			dropdown_container.classList.add("popup_dropdown_container");
			dropdown_container.appendChild(dropdown_label);
			dropdown_container.appendChild(dropdown);
			gfx.popup.appendChild(dropdown_container);
		} else {
			console.error("Unhandled popup item type", item.type);
		}
		item_id += 1;
	}
}

function add_game_option(gfx, option_id, option_info) {
	console.log("add_game_option", option_info);
	let elem = undefined;
	switch(option_info.type) {
		case OPTION_TYPE_BTN:
		{
			console.log("adding game option button");
			elem = document.createElement("button");
			elem.classList.add("options_button");
			elem.innerText = option_info.label;
			elem.addEventListener('click', () => {
				handle_game_option_evt(gfx.ptr, option_info.type, option_id);
				set_options_popup_visible(false);
			});
			gfx.option_elems_to_id.set(option_id, elem);

			gfx.game_options.appendChild(elem);
			break;
		}
		case OPTION_TYPE_TOGGLE:
		{
			let checkbox_elem = document.createElement("input");
			checkbox_elem.type = "checkbox";
			checkbox_elem.id = "game_option_checkbox_" + Math.random().toString();
			checkbox_elem.checked = option_info.value;
			checkbox_elem.addEventListener('change', (e) => {
				handle_game_option_evt(gfx.ptr, option_info.type, option_id, e.target.checked);
			});
			let label_elem = document.createElement("label");
			label_elem.innerText = option_info.label;
			label_elem.setAttribute('for', checkbox_elem.id);
			elem = document.createElement("div");
			elem.appendChild(checkbox_elem);
			elem.appendChild(label_elem);
			gfx.option_elems_to_id.set(option_id, elem);
			gfx.game_options.appendChild(elem);
			break;
		}
		default:
			console.error("unhandled game option type", option_info.type, "full info:", option_info);
	}

	gfx.game_options_none_placeholder.style.display = "none";
}

// Show a popup asking the user to enter a string of text.
// The idea is that showing an image of a keyboard will never be as good as
// letting the user use their real (soft) keyboard on a phone. (On a device with a physical
// keyboard, I suppose it doesn't matter either way)
// Phone soft keyboard gets autocomplete and the feature where you can drag your finger over multiple
// keys and it figures out what word you mean (swipe?)
function prompt_string(gfx, title, message) {

	// The prompt doesn't seem to force the virtual keyboard on mobile to pop up either...
	let use_prompt = false;
	if (use_prompt) {
		// TODO don't use setTimeout, post it to a queue or something
		setTimeout(function () {
		let user_input = prompt(message);
		if (user_input != null) {
			gfx.handle_user_string_input(gfx.ptr, user_input, /* is_cancelled */ false);
		} else {
			gfx.handle_user_string_input(gfx.ptr, "", /* is_cancelled */ true);
		}
		}, 100);
		return;
	}
	
	console.debug("popup_shown: true");
	gfx.popup_shown = true;
	gfx.popup.style.display = "block";
	gfx.popup.innerHTML = "";

	let title_node = document.createElement("h2");
	title_node.innerText = title;
	gfx.popup.appendChild(title_node);

	for (let line of message.split("\n")) {
		let p_node = document.createElement("p");
		p_node.innerText = line;
		gfx.popup.appendChild(p_node);
	}

	let input_node = document.createElement("input");
	input_node.classList.add("popup_input_row");

	function submit_string() {
		let user_input = input_node.value;
		gfx.handle_user_string_input(gfx.ptr, user_input, /* is_cancelled */ false);
		hide_popup(gfx);
		gfx.popup.innerHTML = "";
	}
	function cancel_prompt() {
			gfx.handle_user_string_input(gfx.ptr, "", /* is_cancelled */ true);
			hide_popup(gfx);
			gfx.popup.innerHTML = "";
	}

	// this wasn't working for me on its own, needed to call `input_node.focus()`
	//input_node.autofocus = true;
	input_node.addEventListener('keydown', function (e) {
		if (e.key == "Enter") {
			console.debug("Received 'enter' from string prompt, sending to game");
			if (gfx.key_evts_enabled) {
				gfx.enter_sent = true;
			}

			e.preventDefault();
			submit_string();
		} else if (e.key == "Escape") {
			e.preventDefault();
			cancel_prompt();
		}
	});
	gfx.popup.appendChild(input_node);
	input_node.focus();


	{
		let button = document.createElement("button");
		button.innerText = "Cancel";
		button.addEventListener('click', function () {
			cancel_prompt();
		});
		gfx.popup.appendChild(button);
	}

	{
		let button = document.createElement("button");
		button.innerText = "Submit";
		button.addEventListener('click', function () {
			submit_string();
		});
		gfx.popup.appendChild(button);
	}

}

function hide_popup(gfx) {
	console.debug("hide_popup: popup_shown = false");
	gfx.popup_shown = false;
	gfx.popup.style.display = "none";
}

function zeropad(val, len) {
	val = val + '';
	return val.length >= len ? val : new Array(len - val.length + 1).join('0') + val;
}

function get_time_str() {
	let date = new Date();
	let hours = zeropad(date.getHours(), 2);
	let minutes = zeropad(date.getMinutes(), 2);
	let seconds = zeropad(date.getSeconds(), 2);
	return `${hours}:${minutes}:${seconds}`;
}

function add_status_break(gfx) {
	let status_break = document.createElement("div");
	status_break.classList.add("status_break_line");
	gfx.status_msg.appendChild(status_break);
}

function set_status_msg(gfx, msg) {
	if (msg.length == 0) { return; }
	let line = document.createElement("span");
	line.classList.add("status_msg");
	line.innerText = get_time_str() + ": " + msg;
	gfx.status_msg.appendChild(line);

	gfx.status_msg.scrollTop = gfx.status_msg.scrollHeight;
}

function set_status_err(gfx, msg) {
	if (msg.length == 0) { return; }
	let line = document.createElement("span");
	line.innerText = get_time_str() + ": " + msg;
	line.classList.add("status_msg");
	line.classList.add("status_error");
	gfx.status_msg.appendChild(line);
	gfx.status_msg.scrollTop = gfx.status_msg.scrollHeight;
}

function delete_timer(gfx, handle) {
	console.log(`[timer] delete_timer(handle=${handle})`)
	if (!gfx.update_timers.has(handle)) {
		const err_msg = `delete_timer: timer handle ${handle} not found`;
		set_status_err(gfx, err_msg);
		console.error(err_msg);
		return;
	}
	console.log("clearing old timer", handle);
	clearInterval(handle);
	gfx.update_timers.delete(handle);
}

function trunc_val(val, trunc_fact) {
	return Math.floor(Math.abs(val)/trunc_fact)*trunc_fact * Math.sign(val);
}

function delete_all_timers(gfx) {
	for (handle of gfx.update_timers) {
		delete_timer(gfx, handle);
	}
}

// Call with arg "0" to clear the old timer and not set a new one.
// Always clears an old timer when a new one is set.
function update_timer_period_ms(gfx, timer_period_ms) {
	console.log(`[timer] update_timer_period_ms called with period_ms=${timer_period_ms}`)
	console.log("updater_timer_period_ms", gfx, timer_period_ms);
	let update_func = function() {
		let dt_ms;
		let current_time_ms = alexgames_get_time_ms();
		if (gfx.last_timer_fired_ms === undefined) {
			//console.debug(`First timer fired, using period ${timer_period_ms} as dt_ms`);
			dt_ms = timer_period_ms;
		} else {
			dt_ms = current_time_ms - gfx.last_timer_fired_ms;
			let round_val = 5;
			let deviation = dt_ms - timer_period_ms;
			//console.debug(`Subsequent timer fired, time since last timer is: ${trunc_val(dt_ms, round_val)}, deviation: ${trunc_val(deviation, round_val)}`);
		}
		update(gfx.ptr, dt_ms);
		gfx.last_timer_fired_ms = current_time_ms;
	}

	if (timer_period_ms == 0) {
		delete_all_timers(gfx);
	}

	if (timer_period_ms != 0) {
		const handle = setInterval(update_func, timer_period_ms);
		console.log(`[timer] creating timer with period_ms=${timer_period_ms}, handle=${handle}`)
		gfx.update_timers.add(handle);
		return handle;
	}
}

function new_extra_canvas(gfx, canvas_id) {
	let extra_canvas = document.createElement("canvas");
	extra_canvas.width  = gfx.main_canvas.width;
	extra_canvas.height = gfx.main_canvas.height;
	extra_canvas.style.display = "none";
	gfx.extra_canvases.set(canvas_id, extra_canvas);
}

function delete_extra_canvases(gfx) {
	for (canvas_id of gfx.extra_canvases) {
		gfx.extra_canvases.delete(canvas_id);
	}
}

function set_active_canvas(gfx, canvas_id) {
	let canvas;
	if (canvas_id.length == 0) {
		canvas = gfx.main_canvas;
	} else {
		canvas = gfx.extra_canvases.get(canvas_id);
		if (!canvas) {
			let msg = "canvas \"" + canvas_id + "\" not found";
			set_status_err(gfx, msg);
			console.error(msg);
			return;
		}
	}
	console.log("Active canvas is now id=", canvas_id, "canvas=", canvas);
	gfx.active_canvas = canvas;
}

function set_game_handle(L, game_id_str) {
	console.log("[init] set_game_handle", L, game_id_str);
	gfx.ptr = L;

	set_game_title(game_id_str);
	update_url_args(game_id_str, get_session_id());

	// TODO should I be setting gfx.game_id here too?
	// TODO this is ugly, game_id should at least be set from a common function
	console.log("[init] set_game_handle setting gfx.game_id to ", game_id_str);
	gfx.game_id = game_id_str;
}

function destroy_all(L) {
	let button_row = document.getElementById("game_button_row");
	while (button_row.firstChild) {
		button_row.removeChild(button_row.firstChild);
	}
	disable_event_touch();
	disable_event_mousemove();
	disable_event_mouse_updown();
	disable_event_keys();
	disable_event_wheel();
	delete_all_timers(gfx);
}
	

function leftPadZero(val, len) {
	val = "" + val;
	while (val.length < len) {
		val = "0" + val;
	}
	return val;
}

function get_time_of_day() {
	let d = new Date();
	return d.getFullYear() +
	       '-' +
	       leftPadZero(d.getMonth() + 1, 2) +
	       '-' +
	       leftPadZero(d.getDate(),      2) +
	       ' ' +
	       leftPadZero(d.getHours(),     2) +
	       ':' +
	       leftPadZero(d.getMinutes(),     2) +
	       ':' +
	       leftPadZero(d.getSeconds(),     2);
}


function alexgames_get_time_ms() {
	let d = new Date();
	return d.getTime();
}

