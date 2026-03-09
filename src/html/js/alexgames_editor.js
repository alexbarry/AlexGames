const ID_LUA_EDITOR_FILE_LIST = "lua_editor_file_list";
const PERSISTENT_DIR_NAME = "/alexgames_persistent";

let g_current_file = undefined;
const span_file_indicator = document.getElementById("editor_file_indicator");

function fs_listdir(path) {
	const files = Module.FS.readdir(path);
	return files.filter(fname => fname != "." && fname != "..");
}

function fs_isdir(path) {
	const stat = Module.FS.stat(path);
	return Module.FS.isDir(stat.mode);
}

function fs_ispresent(path) {
	const lookup = Module.FS.analyzePath(path);
	const val = lookup.exists;
	console.log("fs_ispresent", path, "returning", val);
	return val;
}

function fs_create_parent_dirs(path) {
	const parts = path.split('/').filter(p => p.length > 0);
	if (parts.length < 1) {
		return;
	} else {
		// remove last one, which should be the file name,
		// which we don't want to create as a directory
		parts.pop();
	}

	let current_path = '';
	for (part of parts) {
		current_path += '/' + part;
		if (!fs_ispresent(current_path)) {
			console.log("[idbfs] creating directory because it does not exist:", current_path);
			Module.FS.mkdir(current_path);
		}
	}
}

function fs_isfile(path) {
	const stat = Module.FS.stat(path);
	const val = Module.FS.isFile(stat.mode);
	console.log("fs_isfile", path, "returning", val);
	return val;
}

function fs_readfile(path) {
	return Module.FS.readFile(path, { encoding: 'utf8' });
}

function fs_writefile(path, content) {
	//console.log("Updating file", path, "with string ", content);
	const encoder = new TextEncoder();
	const uint8Array = encoder.encode(content);

	const handle = null;
	let f = new_file(handle, path);
	console.log("created file handle", f, "from", path);
	write_array_buffer_to_file(handle, f, uint8Array.buffer);
	close_file(handle, f);

}

function get_idbfs_path(path) {
	return path.replace(/^\/preload\//, PERSISTENT_DIR_NAME + "/");
}

// Returns an array of objects with fields:
//  - name: global file path
//  - children: undefined if a file, otherwise contains array of child nodes
function get_preload_files() {
	return get_files_internal("/preload");
}

function get_files_internal(path) {
	const files = fs_listdir(path);

	const nodes = [];

	for (file of files) {
		let name = path + "/" + file;
		let children = undefined;
		if (fs_isdir(name)) {
			children = get_files_internal(name);
		}
		const idbfs_present = fs_ispresent(PERSISTENT_DIR_NAME + "/" + file);
		nodes.push({
			name,
			idbfs_present,
			children,
		});
	}

	return nodes;
}

function mount_idbfs() {
	return new Promise((resolve, reject) => {
	Module.FS.mkdir(PERSISTENT_DIR_NAME);
	Module.FS.mount(Module.IDBFS, {}, PERSISTENT_DIR_NAME);
	Module.FS.syncfs(true, (err) => {
		if (err) {
			console.error("Error loading from IndexedDB", err);
			reject(err);
		} else {
			console.log("[init] IDBFS successfully loaded to ", PERSISTENT_DIR_NAME);
			resolve();
		}
	});
	});
}

function idbfs_sync() {
	Module.FS.syncfs(false, (err) => {
		if (err) {
			console.error("Error syncing IDBFS", err);
		} else {
			console.debug("[idbfs] Successfully synced IDBFS");
		}
	});
}

async function lua_editor_init() {
	await mount_idbfs();
	lua_editor_build_file_list();
}

function clear_file_list() {
	document.getElementById(ID_LUA_EDITOR_FILE_LIST).innerText = '';
}

function lua_editor_build_file_list() {
	const list_root = document.getElementById(ID_LUA_EDITOR_FILE_LIST);
	build_file_list_internal(list_root, "/preload");
}

function build_file_list_internal(parent_node, path) {
	const files = fs_listdir(path);
	for (file of files) {
		const li = document.createElement("li");
		let li_main_body = document.createElement("a");
		let li_main_body_text = document.createElement("span");
		li_main_body.href = "#";
		let name = path + "/" + file;
		let is_dir = fs_isdir(name);

		li.appendChild(li_main_body);

		const idbfs_ver_present = fs_ispresent(get_idbfs_path(name))


		if (is_dir) {
			let open_state_indicator = document.createElement("span");
			open_state_indicator.innerText = "[+]";
			li_main_body.appendChild(open_state_indicator);
			li_main_body.appendChild(li_main_body_text);


			li_main_body_text.innerText = name + "/";

			let child_ul = document.createElement("ul");
			child_ul.classList.add("lua_editor_dir_item");
			child_ul.classList.add("collapsed");
			li_main_body.addEventListener('click', (evt) => {
				evt.stopPropagation();
				if (child_ul.classList.contains("collapsed")) {
					child_ul.classList.remove("collapsed");
					open_state_indicator.innerText = "[-]";
				} else {
					child_ul.classList.add("collapsed");
					open_state_indicator.innerText = "[+]";
				}
			});
			li.appendChild(child_ul);
			build_file_list_internal(child_ul, name);
		} else {
			li_main_body.appendChild(li_main_body_text);
			li_main_body_text.innerText = name;
			if (idbfs_ver_present) {
				li_main_body_text.innerText += " (modified)";
			}
		}

		li_main_body.addEventListener('click', (evt) => {
			evt.stopPropagation();
			evt.preventDefault();
			if (!is_dir) {
				// TODO
				// console.log("Should switch to file ", name);

				const idbfs_name = get_idbfs_path(name);
				let file_content = '';
				if (fs_ispresent(idbfs_name)) {
					file_content = fs_readfile(idbfs_name);
				} else {
					file_content = fs_readfile(name);
					fs_create_parent_dirs(idbfs_name);
					fs_writefile(idbfs_name, file_content);
				}
				//const file_content = fs_readfile(name);
				// console.log("file content is", file_content);
				AlexGamesBundle.update_lua_editor(file_content);
				g_current_file = name;
				span_file_indicator.innerText = name;
				btn_write_editor_contents_to_file.disabled = false;
				editor_file_list_set_visible(false);
			} else {
			}
		});


		parent_node.appendChild(li);
	}
}

function update_file_from_lua_editor(path, content) {
	fs_writefile(path, content);
}

btn_write_editor_contents_to_file = document.getElementById("write_editor_contents_to_file");
btn_write_editor_contents_to_file.addEventListener('click', () => {
	console.log("btn_write_editor_contents_to_file clicked...");
	const editor_contents = AlexGamesBundle.get_editor_contents();
	update_file_from_lua_editor(g_current_file, editor_contents);
	const idbfs_name = get_idbfs_path(g_current_file);
	console.log("trying to write to", idbfs_name);
	// fs_create_parent_dirs(idbfs_name);
	update_file_from_lua_editor(idbfs_name, editor_contents);
	idbfs_sync();
	clear_file_list();
	lua_editor_build_file_list();
	set_status_msg(gfx, "Reloading game code after editor update...");

	// TODO not just calling start_game func, need to re-load all Lua stuff
	console.log("Reinitializing game", gfx.game_id);
	destroy_game(gfx.ptr);
	gfx.ptr = init_game_api(gfx.game_id);
	start_game(gfx.ptr);
});


function editor_file_list_set_visible(is_visible) {
	if (is_visible) {
		btn_select_editor_file.innerText = "Hide file picker";
		editor_file_list.classList.remove("hidden")
	} else {
		btn_select_editor_file.innerText = "Show file picker";
		editor_file_list.classList.add("hidden")
	}
}

editor_file_list = document.getElementById("editor_file_list");
btn_select_editor_file = document.getElementById("btn_select_editor_file");
btn_select_editor_file.addEventListener('click', () => {
	if (editor_file_list.classList.contains("hidden")) {
		editor_file_list_set_visible(true);
	} else {
		editor_file_list_set_visible(false);
	}
});

const editor = document.getElementById("lua_editor");
document.getElementById("btn_hide_editor").addEventListener('click', () => {
	editor.classList.add("hidden");
});
document.getElementById("btn_open_editor").addEventListener('click', () => {
	editor.classList.remove("hidden");
	set_options_popup_visible(false);
});


/*

What's next:

* lua syntax highlighting
* handle case where server side files change and are now incompatiable with user's changes. At a minimum, need to show files changed in IndexedDB in options menu, and add an option to delete one/all?

nice to have:
* vi keybindings
* generate git patch file from changes?
* open editor when clicking error messages in status bar? Jumping to line? That would be great
* jump to symbol in editor
* breakpoints? Showing Lua state?

*/

