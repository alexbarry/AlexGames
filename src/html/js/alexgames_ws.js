	const WAITING_FOR_CONNECTION   = 0;
	const WAITING_FOR_OTHER_PLAYER = 1;
	const CONNECTION_ESTABLISHED   = 2;

	let state = WAITING_FOR_CONNECTION;
	function init_ws(no_ws) {
		if (!no_ws) {
			let ws;
			let ws_addr = null;
			if (URL_args && URL_args.ws_server) {
				// TODO show a popup asking someone to confirm that they want to connect to this ws address?
				// Otherwise someone could share a link that is mostly legit, but with a malicious parameter that...
				// well, should at most be able to MITM their multiplayer.
				ws_addr = URL_args.ws_server;
			} else {
				const DEFAULT_WS_PORT = "55433";
				let hostname = window.location.hostname;
				if (hostname.length == 0) {
					console.warn("window.location.hostname not set, falling back to localhost");
					hostname = "localhost"
				} else if (hostname.includes("alexbarry.github.io")) {
					console.log("Using alexbarry.net since you are accessing this site hosted on github. If this doesn't work or you want to use a different server, add the 'ws_server' URL parameter.");
					hostname = "alexbarry.net";
				} else {
					console.log(`Checking for websocket server on the hostname of the site: \"${hostname}\"`);

				}
				if (hostname.startsWith("192.168.") ||
				    hostname.startsWith("127.0.0.") ||
				    hostname == "localhost") {
					// when hosting this locally, I don't have any SSL certs.
					console.warn("Connecting to unsecured websocket server: " + hostname);
					set_status_err(gfx, translations.unsecure_websocket_server_warning + hostname);
					ws_addr = "ws://" + hostname + ":" + DEFAULT_WS_PORT;
				} else {
					ws_addr = "wss://" + hostname + ":" + DEFAULT_WS_PORT;
				}
			}
			let msg = translations.connecting_to + ws_addr;
			console.log(msg);
			set_status_msg(gfx, msg);
			try {
				ws = new WebSocket(ws_addr);
			} catch (err) {
				console.error("Error connecting to websocket", err);
				set_status_err(gfx, translations.failed_to_connect_to_websocket + err.message);
				//throw err;
				ws_error = true;
				partial_init();
			}
		
			if (ws) {
				ws.onerror = function (err) {
					console.log(err);
					console.error("Error connecting to websocket", err);
					let msg = translations.ws_onerror;
					//msg += "not loading game";
					set_status_err(gfx, msg);
					ws_error = true;
					partial_init();
				}
				ws.onmessage = handle_msg_from_server;
			}
	
			return ws;
		
		} else {
			set_status_msg(gfx, translations.skipping_ws);
		}
	}

	function binstr_to_nice_str(data) {
		let to_return = "";
		for (let i=0; i<data.length; i++) {
			let x = data.charCodeAt(i).toString(16).padStart(2, '0');
			to_return += x + " ";
		}
		return to_return;
	}

	function binasciistr_to_nice_str(data) {
		let to_return = "";
		for (let i=0; i<data.length; i++) {
			let code = data.charCodeAt(i);
			if ( 32 <= code && code <= 126) { 
				to_return += data.charAt(i);
			} else {
				to_return += "\\x" + data.charCodeAt(i).toString(16).padStart(2, '0');
			}
		}
		return to_return;
	}

	function parse_message(data) {
		// console.log("data is ", binasciistr_to_nice_str(data), data);
		// Note: don't use dot here or it won't match newlines
		//let match = /"([0-9.:]+)":(.*)/.exec(data)

		// first group is outer brackets, containing part that should be removed
		// second match is the address taken out of the first group
		let match = /("([0-9.:a-zA-Z_]+)":)([\s\S]*)/.exec(data)
		if (match == null) {
			console.error("Received message without proper src header", data);
			return;
		}
		let data_src = match[2];
		data         = data.substring(match[1].length);
		// console.log("data now is ", binasciistr_to_nice_str(data));
		let i = data.indexOf(":");
		if (i == -1) {
			console.error("data did not contain colon: " + data);
			return null;
		}
		return { msg_id:  data.substring(0,i),
		         payload: data.substring(i+1,data.length),
		         src:     data_src };
	}

	function bin_str_to_nice_str(data) {
		let s = "";
		for (let i=0; i<data.length; i++) {
			s += data.charCodeAt(i).toString(16).padStart(2, '0') + " ";
		}
		return s;
	}

	function handle_msg_from_server(evt) {
		//console.debug("received message", evt.data); 
		//console.debug("data: ", bin_str_to_nice_str(evt.data));

		let msg = parse_message(evt.data);
		//console.debug("received message", msg);

		switch(msg.msg_id) {
			// TODO make sure payload is alphanumeric
			case "connected": {
				if (msg.src != "ctrl") {
					console.error("Received 'connected' message from another user (and not ctrl)");
					return;
				}
				g_session_id = msg.payload;
				console.log("Connected to session:", g_session_id);
				session_id_input.value = g_session_id;
				update_url_args(gfx.game_id, g_session_id);
				ws_send_message("all", "player_joined:");
				state = WAITING_FOR_OTHER_PLAYER
				break;
			}

			case "player_joined": {
				state = CONNECTION_ESTABLISHED;
				//ws_send_message("all", "ready:");
				break;
			}

			case "player_left": {
				if (msg.src != "ctrl") {
					console.error("Received 'player_left' message from another player");
					return;
				}
				handle_msg_received(gfx.ptr, msg.src, msg.msg_id + ":" + msg.payload);
				break;
			}

			case "game": {
				//let payload_array = new Array(msg.payload.length);
				//for (let i=0; i<msg.payload.length; i++) {
				//	payload_array[i] = msg.payload.charCodeAt(i);
				//}
				//console.debug("recvd game msg", bin_str_to_nice_str(msg.payload));
				handle_msg_received(gfx.ptr, msg.src, msg.payload);
				break;
			}

			default:
				console.log("unexpected message", msg);
				break;
		}

	}

	function ws_send_message(dst, msg) {
		return ws_send_message_internal(dst, msg, false);
	}

	function ws_send_message_ctrl(msg) {
		return ws_send_message_internal("ctrl", msg, true);
	}

	function ws_send_message_internal(dst, msg, is_ctrl) {
		if (gfx.no_ws) {
			return;
		} else if (ws == null) {
			set_status_err(gfx, translations.tried_to_send_ws_but_disconnected);
			return;
		}
		let msg_str = "";
		msg_str += "\"" + dst + "\":";
		if (!is_ctrl) {
			msg_str += "game:";
		}
		if (typeof(msg) == "string") {
			msg_str += msg;
		} else {
			//for (let i=0; i < msg.length; i++) {
			//	msg_str += String.fromCharCode(msg[i]);
			//}
			let enc_str = msg.map(function (val) { return String.fromCharCode(val); }).join('');
			msg_str += enc_str;
		}
		//console.debug(`ws_send_message dst=${dst}, msg=${msg}, msg_str=${msg_str}`);
		//console.debug("sending msg", binasciistr_to_nice_str(msg_str));
		try {
			ws.send(msg_str);
		} catch (err) {
			console.log("Error sending game msg", msg_str);
			throw err;
		}
	}

	function on_ws_ready() {
		console.log("[init] websocket ready");
		ws_init = true;
		partial_init();
	}


	function ws_connect_to_session(ws, g_session_id) {
		// connect to server and request session URL_args.id
		console.log("Connecting to session ID", URL_args.id);
		ws.onopen = function (event) {
			console.debug("ws.onopen");
			ws_send_message_ctrl("session: " + URL_args.id);
			ws_send_message("all", "player_joined:");
			set_status_msg(gfx, translations.connected_to_ws + " " + ws.url);
			on_ws_ready();
		}
	}

	function ws_new_session(ws) {
		console.log("Found no ID arg, requesting new session");
		ws.onopen = function (event) {
			console.debug("ws.onopen");
			ws_send_message_ctrl("new_session");
			on_ws_ready();
		}
	}
