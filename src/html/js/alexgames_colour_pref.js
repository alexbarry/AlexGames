const STORAGE_KEY_USER_COLOUR_PREF = "user_colour_pref";

function user_colour_pref_to_game_format(colour_pref) {
	if (colour_pref == "very_dark") {
		return "dark"
	}

	return colour_pref;
}

function get_user_stored_colour_pref() {
	let storedPref = window.localStorage[STORAGE_KEY_USER_COLOUR_PREF];
	if (storedPref) {
		const colour_pref = user_colour_pref_to_game_format(storedPref);
		if (colour_pref != "auto") {
			return colour_pref;
		}
	}

	return undefined;
}

function get_user_colour_pref() {
	let stored_pref = get_user_stored_colour_pref();
	if (stored_pref) {
		return stored_pref;
	}

	const colour_pref_dark = window.matchMedia("(prefers-color-scheme: dark)");
	let colour_pref;
	if (colour_pref_dark && colour_pref_dark.matches) {
		colour_pref = "dark";
	} else {
		colour_pref = "light";
	}
	return colour_pref;
}


function set_user_colour_pref(pref) {
	window.localStorage[STORAGE_KEY_USER_COLOUR_PREF] = pref;
}

function set_html_colour_theme(theme) {
	document.body.classList.remove("dark");
	document.body.classList.remove("very_dark");
	document.body.classList.add(theme);
}

let g_on_colour_theme_change;

function set_on_colour_theme_change_handler(callback) {
	g_on_colour_theme_change = callback;
}

window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', evt => {
    const colour_pref = evt.matches ? "dark" : "light";
	console.log("[colour_pref] User browser colour scheme preference changed to ", colour_pref, "updating html and game");
	const stored_colour_pref = get_user_stored_colour_pref();
	if (stored_colour_pref) {
		console.log("[colour_pref] Browser colour scheme pref changed, but user has specified explicit preference", stored_colour_pref, "so not changing anything");
		return;
	}

	if (g_on_colour_theme_change) {
		g_on_colour_theme_change(colour_pref);
	}
});
