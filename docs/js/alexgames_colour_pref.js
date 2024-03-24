const STORAGE_KEY_USER_COLOUR_PREF = "user_colour_pref";

function user_colour_pref_to_game_format(colour_pref) {
	if (colour_pref == "very_dark") {
		return "dark"
	}

	return colour_pref;
}

function get_user_colour_pref() {
	let storedPref = window.localStorage[STORAGE_KEY_USER_COLOUR_PREF];
	if (storedPref) {
		return user_colour_pref_to_game_format(storedPref);
	}

	if (window.matchMedia("(prefers-color-scheme: dark)")) {
		return "dark";
	} else {
		return "light";
	}
}


function set_user_colour_pref(pref) {
	window.localStorage[STORAGE_KEY_USER_COLOUR_PREF] = pref;
}

function set_html_colour_theme(theme) {
	document.body.classList.remove("dark");
	document.body.classList.remove("very_dark");
	document.body.classList.add(theme);
}
