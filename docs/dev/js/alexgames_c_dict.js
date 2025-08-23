
function _write_chunk_to_file(reader, f, resolve) {
    return reader.read()
        .then( ({done, value}) => {
            if (!done) {
				// TODO actually write the chunk to the file here
				let dataView = new DataView(value.buffer, value.byteOffset, value.byteLength);
				write_data_view_to_file(null, f, dataView);
                // TODO how do you do this without going deeper and deeper
                // into the stack every time?
                _write_chunk_to_file(reader, f, resolve);
            } else {
				// TODO clean this up, this is bad
				//dict_is_init = true;
				close_file(null, f);
				resolve(true);
            }
        })

}

function fetch_words_list2(uri) {
	return new Promise((resolve, reject) => {
		fetch(uri)
	    .then((response) => {
	        const reader = response.body.getReader();
			const f = new_file(null, "words-en.txt");
			_write_chunk_to_file(reader, f, resolve);
	    });
	});
}

function js_c_dict_init(language) {
	console.debug("[init] js_c_dict_init called");
	dict_needed = true;

	if (gfx.dict && gfx.language == language) {
		return true;
	} else {
		const msg = "Game has requested dictionary. Game will restart when it is downloaded.";
		set_status_msg(gfx, msg);
		console.log("[init]", msg);
	}
	console.debug("fetching dictionary file because", gfx.dict, gfx.language, language);

	const words_uri = "words-en.txt";
	fetch_words_list2(words_uri).then((dict) => {
		console.log("[init] Word dict loaded!");
		update_dict();
		dict_is_init = true;
		gfx.dict = dict;
		gfx.language = language;

		if (allReady()) {
			let msg =  "Dictionary downloaded, re-initializing game";
			set_status_msg(gfx,msg);
			// Don't call an init API here, partial_init already does that
		}

		console.log("dict_init: calling partial init");
		partial_init();
	});
}
