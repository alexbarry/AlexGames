

#[derive(PartialEq, Clone)]
pub enum MorseChar {
	Short,
	Long,
	NewChar,
	NewWord,
}

pub struct State {
	btn_down_time_ms: Option<u32>,
	btn_up_time_ms: Option<u32>,
	morse_chars: Vec<MorseChar>,


	tentative_morse_char: Option<MorseChar>,

	dit_time_ms: u32,
	new_char_time_ms: u32,
	new_word_time_ms: u32,
}

const MORSE_TBL: [ (&'static str, &'static str) ; 26 + 10 + 5 ] = [
	( "a", ".-"      ),
	( "b", "-..."    ),
	( "c", "-.-."    ),
	( "d", "-.."     ),
	( "e", "."       ),
	( "f", "..-."    ),
	( "g", "--."     ),
	( "h", "...."    ),
	( "i", ".."      ),
	( "j", ".---"    ),
	( "k", "-.-"     ),
	( "l", ".-.."    ),
	( "m", "--"      ),
	( "n", "-."      ),
	( "o", "---"     ),
	( "p", ".--."    ),
	( "q", "--.-"    ),
	( "r", ".-."     ),
	( "s", "..."     ),
	( "t", "-"       ),
	( "u", "..-"     ),
	( "v", "...-"    ),
	( "w", ".--"     ),
	( "x", "-..-"    ),
	( "y", "-.--"    ),
	( "z", "--.."    ),
	( "0", "-----"   ),
	( "1", ".----"   ),
	( "2", "..---"   ),
	( "3", "...--"   ),
	( "4", "....-"   ),
	( "5", "....."   ),
	( "6", "-...."   ),
	( "7", "--..."   ),
	( "8", "---.."   ),
	( "9", "----."   ),

	( ",", "..-.."   ),
	( ".", ".-.-.-"  ),
	( "?", "..--.."  ),
	( ";", "-.-.-"   ),
	( "!", "-.-.--"  ),
];

fn morse_tokens_to_char(morse_tokens: &[MorseChar]) -> String {
	// TODO use a hashmap
	let morse_tokens_str: String = morse_tokens.iter().map(|morse_token| match morse_token {
		MorseChar::Short => ".",
		MorseChar::Long => "-",
		_ => {
			panic!("Unexpected morse token encountered in morse_tokens_to_char");
		},
	}).collect();

	for (english_char, morse_str) in MORSE_TBL.iter() {
		if *morse_str ==  morse_tokens_str {
			return (*english_char).to_string().to_uppercase();
		}
	}

	return format!("(unexpected \"{}\")", morse_tokens_str);
}

impl State {
	pub fn new() -> Self {
		State {
			btn_down_time_ms: None,
			btn_up_time_ms: None,
			morse_chars: Vec::new(),
			tentative_morse_char: None,

			dit_time_ms: 250,
			new_char_time_ms: 400,
			new_word_time_ms: 1500,
		}
	}

	pub fn btn_down(&mut self, time_ms: u32) {
		if let Some(btn_up_time_ms) = self.btn_up_time_ms {
			let time_diff = time_ms - btn_up_time_ms;
			if time_diff < self.new_char_time_ms {
			} else if time_diff < self.new_word_time_ms {
				self.morse_chars.push(MorseChar::NewChar);
			} else {
				self.morse_chars.push(MorseChar::NewWord);
			}
		}

		self.btn_down_time_ms = Some(time_ms);
		self.btn_up_time_ms = None;
		self.tentative_morse_char = Some(MorseChar::Short);
	}

	pub fn btn_up(&mut self, time_ms: u32) {
		if self.btn_down_time_ms.is_none() {
			return;
		}

		let time_diff = time_ms - self.btn_down_time_ms.unwrap();

		let morse_char = if time_diff < self.dit_time_ms {
			MorseChar::Short
		} else {
			MorseChar::Long
		};

		self.morse_chars.push(morse_char);
		self.btn_down_time_ms = None;
		self.btn_up_time_ms = Some(time_ms);
		self.tentative_morse_char = None;
	}

	pub fn btn_is_down(&self) -> bool {
		self.btn_down_time_ms.is_some()
	}

	pub fn time_passed(&mut self, time_ms: u32) {
		if let Some(btn_down_time_ms) = self.btn_down_time_ms {
			let time_diff = time_ms - btn_down_time_ms;
			self.tentative_morse_char = if time_diff < self.dit_time_ms {
				println!("time_diff is {} so short", time_diff);
				Some(MorseChar::Short)
			} else {
				println!("time_diff is {} so long", time_diff);
				Some(MorseChar::Long)
			};
		} else {
			if let Some(btn_up_time_ms) = self.btn_up_time_ms {
				let time_diff = time_ms - btn_up_time_ms;
				self.tentative_morse_char = if time_diff < self.new_char_time_ms {
					None
				} else if time_diff < self.new_word_time_ms {
					Some(MorseChar::NewChar)
				} else {
					Some(MorseChar::NewWord)
				}
			}
		}
	}

	fn get_morse_chars_incl_tentative(&self) -> Vec<MorseChar> {
		let mut morse_chars = self.morse_chars.clone();
		if self.tentative_morse_char.as_ref().is_some_and(|val| *val == MorseChar::Long || *val == MorseChar::NewChar) {
			morse_chars.push(self.tentative_morse_char.as_ref().unwrap().clone())
		}

		morse_chars
	}

	pub fn get_text_morse_dits(&self) -> String {
		//"--.".to_string()
		//self.get_morse_chars_incl_tentative().iter().map(|morse| match morse {
		//let mut morse_dits_str = self.morse_chars.iter().map(|morse| match morse {
		return self.get_morse_chars_incl_tentative().iter().map(|morse| match morse {
			MorseChar::Short => ".",
			MorseChar::Long => "-",
			MorseChar::NewChar => " ",
			MorseChar::NewWord => " / ",
		}).collect();

		/*
		if let Some(tentative_morse_char) = &self.tentative_morse_char {
			morse_dits_str = morse_dits_str + "(" + match tentative_morse_char {
				MorseChar::Short => ".",
				MorseChar::Long => "-",
				MorseChar::NewChar => " ",
			} + ")";
		}

		return morse_dits_str;
		*/
		
	}

	pub fn get_text_readable(&self) -> String {
		//"Hello, world!".to_string()

		let morse_chars = self.get_morse_chars_incl_tentative();
		//let mut show_last_char = self.tentative_morse_char.as_ref().is_some_and(|val| *val == MorseChar::NewChar);
		//let show_last_char = morse_chars.last().is_none_or(|val| *val == MorseChar::NewChar);
		let show_last_char = true;
		let morse_chars_split: Vec<_> = morse_chars.split(|m| *m == MorseChar::NewChar || *m == MorseChar::NewWord) // TODO handle new word delim
			.filter(|word| !word.is_empty())
			.collect();
		let morse_chars_split = if show_last_char {
			&morse_chars_split
		} else {
			&morse_chars_split[..morse_chars_split.len().saturating_sub(1)]
		};
		morse_chars_split.iter()
			.map(|word| morse_tokens_to_char(word))
			.collect()
	}

}
