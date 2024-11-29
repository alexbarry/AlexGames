	const PUBLIC_URL = "https://alexbarry.github.io/AlexGames"

	const UNSET_GAME_TITLE = translations.choose_a_game;
	const UNSET_GAME_ID = "unset";

	const BITMASK_MOUSE_BTN_1 = 0x1; // primary mouse button (usually left)
	const BITMASK_MOUSE_BTN_2 = 0x2; // secondary mouse button (usually right)
	const BITMASK_MOUSE_BTN_3 = 0x4; // third mouse button (usually middle?)

	function partial_init() {
		update_status_msg_init();
		if (allReady()) {
			console.log("[init] all ready, initializing game", gfx.game_id);
			if (gfx.game_id == UNSET_GAME_ID) {
				//let game_list = get_game_list();
				set_game_choice_popup_visible(true);
			} else {
				//game_init(gfx.game_id);
				game_chosen(gfx.game_id, gfx.url_state_b64);
				// If another game is loaded later, don't pass this state to it.
				// (e.g. if user selects history browser)
				// gfx.url_state_b64 = null;
			}
		} else if (game_ready_without_network() && ws_error) {
			set_status_err(gfx, translations.websocket_failed2);
		}
	}

	function update_status_msg_init() {
		let str = "";
		let show_as_error = false;
		if (allReady()) {
			str = translations.init_complete;
			if (!gfx.no_ws && ws_error) {
				str += translations.websocket_failed;
				show_as_error = true;
			}
		} else {
			str = translations.waiting_for;
			let waiting_count = 0;
			if (!wasm_init) {
				waiting_count += 1;
				str += " " + translations.wasm_init;
			}
			if (!gfx.no_ws && !ws_init) {
				if (waiting_count > 0) { str += ","; }
				waiting_count += 1;
				str += " " + translations.websocket_connection;
			}

			if (!html_init) {
				if (waiting_count > 0) { str += ","; }
				waiting_count += 1;
				str += " " + translations.html_load;
			}

			if (!dict_is_init) {
				if (waiting_count > 0) { str += ","; }
				waiting_count += 1;
				str += " " + translations.dictionary_init;
			}
		}

		if (str.length > 0) {
			if (!show_as_error) {
				set_status_msg(gfx, str);
			} else {
				set_status_err(gfx, str);
			}
		}
	}

	function init_game_options(gfx) {
		let options_children = gfx.game_options.children;
		for (let game_options_item of options_children) {
			if (game_options_item.id == gfx.game_options_none_placeholder.id) {
				continue;
			}
			console.log("removing options item", game_options_item);
			gfx.game_options.removeChild(game_options_item);
		}
		gfx.game_options_none_placeholder.style.display = "";
	}

	function game_init(game, state_b64) {
		if (gfx.ptr != null) {
			console.log("[init] Game already initialized, destroying old game", gfx.ptr);
			init_game_options(gfx);
			destroy_game(gfx.ptr);
		}
		console.log("[init] game_init, setting gfx.game_id to", game);
		gfx.game_id = game;
		console.log("[init] Initializing game", game);
		gfx.ptr = init_game_api(game);
		if (gfx.ptr == 0) {
			console.error("Error initializing game");
			return;
		}
		console.debug("[init] gfx.ptr is ", gfx.ptr.toString(16));
		if (state_b64) {
			console.log("[init] Calling start_game with state from URL arg, base64: ", state_b64);
			set_status_msg(gfx, translations.loading_state_from_url_param);
			start_game_b64(gfx.ptr, state_b64);
		} else {
			console.log("[init] Calling start_game with no saved state param", game);
			start_game(gfx.ptr);
		}

		update(gfx.ptr, 0);
	}


	function get_game_coords(evt) {
		let rect = canvas.getBoundingClientRect();
		return {
			x: (evt.clientX - rect.left)/(rect.right - rect.left) * canvas.width,
			y: (evt.clientY - rect.top)/(rect.bottom - rect.top) * canvas.height,
		};
	}

	function handle_canvas_clicked(evt) {
		if (gfx.popup.style.display == "block") {
			console.debug("Ignoring user click on canvas because popup is shown");
			return;
		}
		if (gfx.ptr == null) {
			set_game_choice_popup_visible(true);
			return;
		}
		let pos = get_game_coords(evt);
		handle_user_clicked(gfx.ptr, pos.y, pos.x);
	}

	function handle_event_mousemove(evt) {
		//console.debug("mousemove evt", evt);
		if (gfx.popup.style.display == "block") {
			console.debug("Ignoring user mouse move on canvas because popup is shown");
			return;
		}
		let pos = get_game_coords(evt);
		handle_mousemove(gfx.ptr, pos.y, pos.x, evt.buttons);
	}
	function enable_event_mousemove() {
		canvas.addEventListener('mousemove', handle_event_mousemove);
	}

	function disable_event_mousemove() {
		canvas.removeEventListener('mousemove', handle_event_mousemove);
	}

	function handle_mouse_down(evt) {
		console.debug("handle_mouse_down", evt);
		evt.preventDefault();
		if (gfx.popup.style.display == "block") {
			return;
		}
		let pos = get_game_coords(evt);

		let evts = [];
		// If right clicks aren't enabled, assume the mouse down event is for the primary mouse button.
		// Note that on iOS, when using my finger, evt.buttons seems to be 0, so no mouse events would work.
		if (!gfx.mouse_alt_evt_enabled) {
			evts.push(2); // alexgames.MOUSE_EVT_DOWN
		} else {
			const prev_mouse_btns_down = gfx.mouse_btns_down;
			let diff = prev_mouse_btns_down ^ evt.buttons;
			gfx.mouse_btns_down = evt.buttons;

			// I'm not sure I really like this behaviour.
			// I don't think this bitmask can ever change by more than a single bit at a time-- execept
			// if the user moves the mouse off screen, releases a held button (or presses a previously unheld button)
			// and then moves it back on screen.
			//
			// It would make the most sense to send those pseudo "button released" events
			// as soon as the mouse is moved back on screen, but the mousemove event isn't always registered.
			//
			// The game could just look at the evt.buttons that are passed to it, but
			// then it would need to ignore these seemingly duplicate events.
			// I guess it could do that, but it would be a mess.
	
			if ((diff & BITMASK_MOUSE_BTN_1) > 0) {
				evts.push(2); // alexgames.MOUSE_EVT_DOWN
			}
			if ((diff & BITMASK_MOUSE_BTN_2) > 0) {
				evts.push(4); // alexgames.MOUSE_EVT_ALT_DOWN
			}
			if ((diff & BITMASK_MOUSE_BTN_3) > 0) {
				evts.push(6); // alexgames.MOUSE_EVT_ALT2_DOWN
			}
		}

		if (evts.length == 0) {
			console.error("handle_mouse_down: events len zero?");
			set_status_err(gfx, "handle_mouse_down: events len zero?");
		}

		for (const evt_id of evts) {
			handle_mouse_evt(gfx.ptr, evt_id, pos.y, pos.x, evt.buttons);
		}
	}

	function handle_mouse_leave(evt) {
			evt.preventDefault();
			if (gfx.popup.style.display == "block") {
				return;
			}
			let pos = get_game_coords(evt);
			handle_mouse_evt(gfx.ptr, 3, pos.y, pos.x, evt.buttons);
	}

	function handle_mouse_up(evt) {
		console.debug("handle_mouse_up", evt);
		if (gfx.popup.style.display == "block") {
			return;
		}
		let pos = get_game_coords(evt);

		let evts = [];

		if (!gfx.mouse_alt_evt_enabled) {
			evts.push(1); // alexgames.MOUSE_EVT_UP
		} else {
			const prev_mouse_btns_down = gfx.mouse_btns_down;
			let diff = prev_mouse_btns_down ^ evt.buttons;
			gfx.mouse_btns_down = evt.buttons;

			if ((diff & BITMASK_MOUSE_BTN_1) > 0) {
				evts.push(1); // alexgames.MOUSE_EVT_UP
			}
			if ((diff & BITMASK_MOUSE_BTN_2) > 0) {
				evts.push(5); // alexgames.MOUSE_EVT_ALT_UP
			}
			if ((diff & BITMASK_MOUSE_BTN_3) > 0) {
				evts.push(7); // alexgames.MOUSE_EVT_ALT2_UP
			}
		}

		if (evts.length == 0) {
			console.error("handle_mouse_up: events len zero?");
			set_status_err(gfx, "handle_mouse_up: events len zero?");
		}

		for (const evt_id of evts) {
			handle_mouse_evt(gfx.ptr, evt_id, pos.y, pos.x, evt.buttons);
		}
		evt.preventDefault();
	}

	function handle_contextmenu(evt) {
			console.debug("contextmenu");
			evt.preventDefault();
		}

	function enable_event_mouse_updown() {
		canvas.addEventListener('mousedown',  handle_mouse_down);
		canvas.addEventListener('mouseleave', handle_mouse_leave);
		canvas.addEventListener('mouseup',    handle_mouse_up);
	}

	function enable_event_mouse_alt_updown() {
		gfx.mouse_alt_evt_enabled = true;
		canvas.addEventListener('contextmenu', handle_contextmenu);
	}

	function disable_event_mouse_updown() {
		canvas.removeEventListener('mousedown',  handle_mouse_down);
		canvas.removeEventListener('mouseleave', handle_mouse_leave);
		canvas.removeEventListener('mouseup',    handle_mouse_up);
	}

	function disable_event_mouse_alt_updown() {
		gfx.mouse_alt_evt_enabled = false;
		canvas.removeEventListener('contextmenu', handle_contextmenu);
	}

	function handle_evt_wheel(evt) {
		//console.debug("wheel evt:", evt);
		evt.preventDefault();
		if (gfx.popup.style.display == "block") {
			return;
		}
		handle_wheel_evt(gfx.ptr, event.deltaY, event.deltaX);
	}

	// typically this is a mouse wheel.
	function enable_event_wheel() {
		canvas.addEventListener('wheel', handle_evt_wheel);
	}

	function disable_event_wheel() {
		canvas.removeEventListener('wheel', handle_evt_wheel);
	}

	function handle_touch_evt_wrapper(evt) {
		handle_touch_evt(canvas, gfx.ptr, evt);
	}

	function enable_event_touch() {
		canvas.addEventListener('touchstart', handle_touch_evt_wrapper);
		canvas.addEventListener('touchmove', handle_touch_evt_wrapper);
		canvas.addEventListener('touchend', handle_touch_evt_wrapper);
		// TODO isn't there touchcancel??
	}

	function disable_event_touch() {
		canvas.removeEventListener('touchstart', handle_touch_evt_wrapper);
		canvas.removeEventListener('touchmove', handle_touch_evt_wrapper);
		canvas.removeEventListener('touchend', handle_touch_evt_wrapper);
		// TODO isn't there touchcancel??
	}

   function handle_event_keyup(evt) {
		let handled = handle_key_evt(gfx.ptr, 'keyup', evt.code);
		if (handled && !(evt.ctrlKey && gfx.control_keys_do_not_prevent_default.has(evt.code))) {
			// See comment on the 'keydown' event.
			evt.preventDefault();
		}
	}

	function handle_event_keydown(evt) {

		if (g_options_visible || gfx.popup_shown) {
			console.debug("ignoring keypress because either options_visible", g_options_visible, "or popup_shown", gfx.popup_shown);
			return;
		}

		if (gfx.enter_sent) {
			console.warn("Ignoring enter keydown because it was likely sent from string input popup. This is an ugly hack and is likely to " +
			             "cause a bug later");
			gfx.enter_sent = false;
			return;
		}

		// NOTE: don't try to track ctrl state based on key events here.
		//       I found that if you press Ctrl L (jump to address bar), then release
		//       control in the address bar, this handler doesn't receive the release event.
		//       So control would be stuck.
		if (evt.ctrlKey  && !gfx.control_keys_do_not_prevent_default.has(evt.code)) {
			console.debug("Ignoring key", evt.code, "while Control is pressed");
			return;
		}

		let handled = handle_key_evt(gfx.ptr, 'keydown', evt.code);
		if (handled && !(evt.ctrlKey && gfx.control_keys_do_not_prevent_default.has(evt.code))) {
			// Don't let the key do what it would normally do if it is part
			// of the game, e.g. scroll on screen with arrow keys.
			//
			// But if it is not handled by the game, especially important
			// keys for development like F12 (open dev tools), refresh, etc...
			// absolutely do not override them.
			//
			// TODO: however, refreshing some games can make you lose your progress.
			// Consider allowing the user to disable these keys even if the game doesn't handle it.
			// TODO: and alternatively, consider allowing these keys to do their intended action
			// even if the game does override it, to protect against malicious (or at least lazy) games
			evt.preventDefault();
		}
	}

	function enable_event_keys() {
		gfx.key_evts_enabled = true;
		document.addEventListener('keydown', handle_event_keydown);
		document.addEventListener('keyup',   handle_event_keyup);
	}

	function disable_event_keys() {
		gfx.key_evts_enabled = false;
		document.removeEventListener('keydown', handle_event_keydown);
		document.removeEventListener('keyup',   handle_event_keyup);
	}

	function enable_event(evt_id) {
		switch(evt_id) {
			case "mouse_move":       enable_event_mousemove();        break;
			case "mouse_updown":     enable_event_mouse_updown();     break;
			case "mouse_alt_updown": enable_event_mouse_alt_updown(); break;
			case "wheel":            enable_event_wheel();            break;
			case "touch":            enable_event_touch();            break;
			case "key":              enable_event_keys();             break;
			default:
				console.error("Unexpected evt_id in enable_event:", evt_id);
				break;
		}
	}

	function disable_event(evt_id) {
		switch(evt_id) {
			case "mouse_move":       disable_event_mousemove();        break;
			case "mouse_updown":     disable_event_mouse_updown();     break;
			case "mouse_alt_updown": disable_event_mouse_alt_updown(); break;
			case "wheel":            disable_event_wheel();            break;
			case "touch":            disable_event_touch();            break;
			case "key":              disable_event_keys();             break;
			default:
				console.error("Unexpected evt_id in disable_event:", evt_id);
				break;
		}
	}

	function disable_all_events() {
		disable_event_mousemove();
		disable_event_mouse_updown();
		disable_event_mouse_alt_updown();
		disable_event_touch();
		disable_event_wheel();
		disable_event_keys();
	}

	function update_url_args(game, session_id) {
		console.log(`[init] update_url_args(game=${game}, session_id=${session_id})`);
		if (!game) {
			game = URL_args.game;
			console.log(`[init] update_url_args game not provided, taking ${game} from URL args`);
		}
		console.log("setting url args to game:", game, "session_id:", session_id);
		let url_args = "game=" + game + "&id=" + session_id;
		if (URL_args && URL_args.no_ws) {
			url_args += "&no_ws=" + !!URL_args.no_ws;
		}
		if (URL_args && URL_args.ws_server) {
			// TODO is this vulnerable to injection of some kind?
			// may need to escape it
			url_args += "&ws_server=" + URL_args.ws_server;
		}
		set_url_args(url_args);
		// TODO this is causing a page reload and seemingly breaking WASM,
		// saying "both sync and async loading failed"
		// set_url_args("id=" + session_id);
	}

	function get_session_id() {
		return g_session_id;
	}

	function set_game_choice_popup_visible(is_visible) {
		console.log(`set_game_choice_popup_visible(${is_visible}), game_id=${gfx.game_id}`);
		let display_type;
		if (is_visible) {
			display_type = "";
		} else {
			display_type = "none";
		}
		gfx.game_choice_popup.style.display = display_type;
		if (gfx.game_id == UNSET_GAME_ID) {
			set_unset_game_instructions_visible(!is_visible);
		}
	}

	function set_unset_game_instructions_visible(is_visible) {
		console.log(`set_unset_game_instructions_visible(${is_visible})`);
		let elem = document.getElementById("unset_game_instructions");
		if (is_visible) {
			elem.style.visibility = "visible";
		} else {
			elem.style.visibility = "hidden";
		}
		set_fullscreen_msg_visible(is_visible);
	}

	function game_chosen(game_id, state_b64) {
		console.log(`[init] game_chosen(game_id=${game_id}, state_b64=${state_b64})`);
		set_options_popup_visible(false);
		if (game_id != UNSET_GAME_ID) {
			console.log("[init] game_chosen, setting game_id to", game_id);
			gfx.game_id = game_id;
			set_game_choice_popup_visible(false);
			update_url_args(game_id, get_session_id());
			add_status_break(gfx);
			game_init(game_id, state_b64);
			set_game_title(game_id);
			set_unset_game_instructions_visible(false);
		} else {
			set_game_choice_popup_visible(true);
		}
	}

	function set_header_visible(title_visible) {
		let display_type;
		if (title_visible) {
			 // ugh is there no other way to make elements disappear, without hardcoding their proper display type?
			header_display_type            = "";
			status_option_btn_display_type = "none";
		} else {
			header_display_type            = "none";
			status_option_btn_display_type = "block";
		}
		document.getElementById("header").style.display = header_display_type;
		document.getElementById("btn_status_options").style.display = status_option_btn_display_type;
	}

	function escape_url(val) {
		if (typeof val !== 'string' && !(val instanceof String) ) {
			console.error(`escape_url: Unexpected param ${val}, type: ${typeof val}`);
			return null;
		}

		return (val
			.replaceAll("=", "%3d")
		    .replaceAll("/", "%2f"));
	}

	function set_href_and_innertext(elem, val) {
		elem.href      = val;

		let val_escaped = val;
		val_escaped = new Option(val).innerHTML;
		elem.innerHTML = val_escaped;
	}

	function gen_url_with_state(state_enc) {
		state_enc = escape_url(state_enc);
		let url = get_base_url();
		url += "?game=" + gfx.game_id;
		url += "&state=" + state_enc;
		return url;
	}

	function url_is_private(url) {
		if (url.startsWith('file://')) {
			return true;
		} else if (url.startsWith('https://appassets.androidplatform.net/')) {
			return true;
		}

		return false;
	}

	function get_base_url() {
		let url = window.location.href;
		url = url.split('?')[0];

		// TODO check for the android webview URL too
		if (url_is_private(url)) {
			console.debug(`window.location.href=${window.location.href} appears to be ` +
			              `private (based on hardcoded list), so using a hardcoded ` +
			              `public URL "${PUBLIC_URL}" instead`);
			return PUBLIC_URL;
		} else {
			return url;
		}
	}

	function update_game_state_urls() {
		const elem_state_current               = document.getElementById("url_current_state");
		const elem_state_current_supported     = document.getElementById("current_state_supported");
		const elem_state_current_not_supported = document.getElementById("current_state_not_supported");

		const elem_state_init                  = document.getElementById("url_init_state");
		const elem_state_init_supported        = document.getElementById("init_state_supported");
		const elem_state_init_not_supported    = document.getElementById("init_state_not_supported");
		const elem_state_init_eq_current_state = document.getElementById("init_state_eq_state");

		let state_current;
		let state_init;

		// Do not let errors in either of these functions cause the options
		// menu to not be shown.
		try {
			state_current = get_state(gfx.ptr);
		} catch (e) {
			console.error("get_state: ", e);
		}
		try {
			state_init    = get_init_state(gfx.ptr);
		} catch (e) {
			console.error("get_init_state: ", e);
		}

		if (state_current && state_current.length > 0) {
			let url_state_current = gen_url_with_state(state_current);
			set_href_and_innertext(elem_state_current, url_state_current);
			elem_state_current_not_supported.style.display = "none";
			elem_state_current_supported.style.display     = "";
		} else {
			elem_state_current_not_supported.style.display = "";
			elem_state_current_supported.style.display     = "none";
		}

		if (state_init && state_init == state_current && state_current.length > 0 ) {
			elem_state_init_supported.style.display     = "none";
			elem_state_init_not_supported.style.display = "none";
			elem_state_init_eq_current_state.style.display = "";
		} else if (state_init && state_init.length > 0) {
			let url_state_init    = gen_url_with_state(state_init);
			set_href_and_innertext(elem_state_init,    url_state_init);
			elem_state_init_supported.style.display     = "";
			elem_state_init_not_supported.style.display = "none";
			elem_state_init_eq_current_state.style.display = "none";
		} else {
			elem_state_init_supported.style.display     = "none";
			elem_state_init_not_supported.style.display = "";
			elem_state_init_eq_current_state.style.display = "none";
		}
	}

	function set_options_popup_visible(options_visible) {
		console.log(`set_options_popup_visible(${options_visible})`);
		let options_display_type;
		if (options_visible) {
			update_game_state_urls();
			options_display_type = "";
			g_options_visible = true;
			// TODO for the case where the web app is embedded in another app,
			// I should use `get_base_url()` here to use a hardcoded URL that points
			// to a public version of this site.
			// But when doing that, I'll need to add the URL params too
			document.getElementById("url_share_multiplayer").href = window.location.href;
			document.getElementById("url_share_multiplayer").innerText = window.location.href;

			const stored_colour_pref = get_user_stored_colour_pref();
			if (stored_colour_pref) {
				const select_user_colour_pref = document.getElementById("select_user_colour_pref");
				const options = select_user_colour_pref.children;
				for (let i=0; i<options.length; i++) {
					if (stored_colour_pref == options[i].value) {
						console.log("[options][colour_pref] Setting options popup colour preference dropdown to stored preference", stored_colour_pref, "index ", i); 
						select_user_colour_pref.selectedIndex = i;
						break;
					}
				}
			}
		} else {
			options_display_type = "none";
			g_options_visible = false;
		}
		document.getElementById("options_popup").style.display = options_display_type;
	}

	function capitalize_first_letter(s) {
		return s[0].toUpperCase() + s.substring(1,s.length);
	}

	function set_game_title(game_id) {
		const TITLE_BASE = "AlexGames: "
		let game_title = game_id;
		if (game_id == UNSET_GAME_ID) {
			game_title = UNSET_GAME_TITLE;
		} else {
			game_title = capitalize_first_letter(game_id);
		}
		document.getElementById("subtitle").innerText = game_title;
		document.title = TITLE_BASE + game_title;
	}


	function set_about_popup_visible(is_visible) {
		const popup = document.getElementById("about_popup");

		let display_style;
		if (is_visible) {
			display_style = "";
		} else {
			display_style = "none";
		}

		popup.style.display = display_style;
	}

	function set_fullscreen_msg_visible(is_visible) {
		const fullscreen_msg_wrapper = document.getElementById("fullscreen_msg_wrapper");
		let val;
		if (is_visible) {
			val = "";
		} else {
			val = "none";
		}
		fullscreen_msg_wrapper.style.display = val;
	}

	function set_fullscreen_err(msg) {
		set_unset_game_instructions_visible(false);
		set_fullscreen_msg_visible(true);

		console.error("fullscreen_err_msg:", msg);
		const fullscreen_err_msg = document.getElementById("fullscreen_err_msg");
		fullscreen_err_msg.style.display = "";
		let p = document.createElement("p");
		p.innerText = msg;
		fullscreen_err_msg.appendChild(p);
	}
		
