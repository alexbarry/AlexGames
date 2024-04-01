/**
 * AlexGames dictionary library for web games.
 *
 * Update: this library should probably be removed in favour
 *         of alexgames_c_dict.js and the C implementation.
 *         It uses ~10 MB less memory.
 *
 * This library is only used if the game requests a dictionary.
 *
 * The whole init sequence looks something like this:
 *     - game is initialized,
 *     - game calls alexgames.dict.init(), which calls the javascript
 *       dict_init defined in this file
 *     - dict_init starts to fetch the dictionary file asynchronously
 *     - when the file arrives, the game is re-initialized.
 *
 * It would probably be better to remove all of this and rely on
 * something similar implemented in C.
 * I only added these APIs to do it in javascript because I initially
 * assumed that a hashmap would be the best way to do a dictionary lookup.
 * But storing each word as keys in a hashmap took around 25 MB of memory.
 * The list storing the words is only 6 MB.
 * Addition: storing each word as a javascript string seems to use a lot
 *           of memory too.
 */


function _parse_wordlist_chunk(state, chunk) {
    if (!chunk) { return; }
    let s = state.text_decoder.decode(chunk);
    s = state.prev_chunk + s
    //console.log("received chunk: ", s);

    let i = 0;
    while (i <= s.length) {
        //log("i = " + i + ", len: " + s.length);
        let delim   = s.indexOf(",", i);
        let lineEnd = s.indexOf("\n", i);

        if (lineEnd == -1) {
            break;
        }

        let word     = s.substr(i, delim-i);
        let freq_str = s.substr(delim+1, lineEnd-delim-1);


        i = lineEnd + 1;

        let freq = Number(freq_str);

        //state.words.set(word, freq);
		state.word_list.push({ word: word, freq: freq });
        state.words_count++;

    }
    state.prev_chunk = s.substr(i);
}

function _read_chunk(reader, state, resolve) {
    return reader.read()
        .then( ({done, value}) => {
            _parse_wordlist_chunk(state, value);
            if (!done) {
                // TODO how do you do this without going deeper and deeper
                // into the stack every time?
                _read_chunk(reader, state, resolve);
            } else {
                console.log("Finished reading words, count: " + state.words_count);
				// TODO clean this up, this is bad
				//dict_is_init = true;
                //gfx.dict = state;
				resolve(state);
            }
        })
}

function _bisect_search(list, getSortValue, value) {
	let startIdx = 0;
	let endIdx   = list.length-1;

	//console.log("finding value", value, "in list", list);
	let iter = 0;
	while (startIdx < endIdx) {
		let middleIdx = Math.floor( (endIdx + startIdx)/2 );
		let middleValue = getSortValue(list[middleIdx]);

		let startValue = getSortValue(list[startIdx]);
		let endValue   = getSortValue(list[endIdx]);

		console.assert(startValue  <= endValue,    "list is not sorted (start <= end)");
		console.assert(startValue  <= middleValue, "list is not sorted (start <= middle)");
		console.assert(middleValue <= endValue,    "list is not sorted (middle <= end)");
		if (!(startValue  <= endValue) ||
		    !(startValue  <= middleValue) ||
		    !(middleValue <= endValue)) {
			set_status_err(gfx, "Dictionary word list is not sorted!");
			throw "word list is not sorted";
		}

		if (startIdx + 1 == endIdx) {
			//console.log("almost done: ", value, list[startIdx], list[endIdx]);
			if (value == getSortValue(list[startIdx])) { return startIdx; }
			if (value == getSortValue(list[endIdx])  ) { return endIdx; }
			break;
		}
	
		if (value == middleValue) {
			return middleIdx;
		} else if (value < middleValue) {
			endIdx = middleIdx;
		} else if (value > middleValue) {
			startIdx = middleIdx;
		} else {
			assert(false);
			throw "_bisect_search assertion error";
		}

		iter++;
		if (iter > 200) { break; }
	}

	return -1;
}

function is_valid_word(state, word) {

	if (!state) {
		set_status_err(gfx, "is_valid_word: dictionary not loaded yet");
		return false;
	}
	return _bisect_search(state.word_list, (word_info) => word_info.word, word) != -1;
}

function get_word_freq(state, word) {
	if (!state) {
		set_status_err(gfx, "get_word_freq: dictionary not loaded yet");
		return 0;
	}
	let idx = _bisect_search(state.word_list, word);
	if (idx == -1) {
		throw "get_valid_word_freq: word \"" + word + "\" not found!";
	}

	return state.word_list[idx].freq;
}


function get_random_word(state, params) {
	//console.log("get_random_word called with", params);
	let words = [];
	let i = 0;
	for (let word_info of state.word_list) {
		let word = word_info.word;
		//if (i % 1000 == 0) {
		//	console.log("checking if word", word_info, "matches params:", params, 
		//	            params.min_length <= word.length, word.length <= params.max_length,
		//                word_info.freq >= params.min_freq);
		//}
		if (params.min_length <= word.length && word.length <= params.max_length &&
		    word_info.freq >= params.min_freq) {
			words.push(word_info)
			//console.log("Found matching word: ", word, "words.len is now", words.length);
		}
		i++;
	}

	if (words.length == 0) {
		console.error("No words matching params", params, "out of total dict", state.word_list.length);
		throw "get_random_word: no words matching params";
	}

	console.log("get_random_word: found ", words.length, "possible words");

	let idx = Math.floor(Math.random() * words.length);
	//console.log("chosen: ", words[idx]);
	return words[idx].word;
}

function fetch_words_list(uri) {
	let state = {
		text_decoder: new TextDecoder(),

		// NOTE: don't use a hashmap here without testing memory usage.
		// I found that a hashmap containing all words took up ~25 MB of memory.
		// An array took ~6 MB.
		// Doing a bisection search on a sorted list of ~200k entries should 
		// only take log2(200e3) checks, which is < 18.
		// At one point I was searching through every single entry and it
		// was almost not user perceivable, so this is well worth the memory savings.
		word_list: [],
		words_count: 0,
		prev_chunk: "",
	};
	return new Promise((resolve, reject) => {
		fetch(uri)
	    .then((response) => {
	        const reader = response.body.getReader();
	        _read_chunk(reader, state, resolve);
	    });
	});
}

function js_dict_init(language) {
	console.debug("[init] js_dict_init called");
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
	fetch_words_list(words_uri).then((dict) => {
		console.log("[init] Word dict loaded!");
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
