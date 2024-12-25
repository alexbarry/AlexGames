// Trivia
//
// TODO:
//   * add local and network multiplayer support.
//   * track score(s)
//   * add more questions, maybe categories and difficulty level
//   * saved state?

use crate::rust_game_api;
use crate::rust_game_api::{AlexGamesApi, CCallbacksPtr, PopupInfo, PopupItem, PopupState};

use lazy_static::lazy_static;

const POPUP_ID_QUESTION: &str = "popup_question";
const POPUP_BTN_ID_ANSWER_A: i32 = 1;
const POPUP_BTN_ID_ANSWER_B: i32 = 2;
const POPUP_BTN_ID_ANSWER_C: i32 = 3;
const POPUP_BTN_ID_ANSWER_D: i32 = 4;

const POPUP_ID_RESULT: &str = "popup_result";

const POPUP_ID_RESTART: &str = "popup_restart";

#[derive(Debug)]
struct TriviaQuestion {
    question: &'static str,
    answers: [&'static str; 4],
    correct_answer_index: usize,
}

lazy_static! {
    static ref QUESTIONS: Vec<TriviaQuestion> = vec![
        TriviaQuestion {
            question: "What denomination of U.S. paper currency remains in circulation the longest, on average?",
            answers: ["$1", "$5", "$10", "$100"],
            correct_answer_index: 3,
        },

        TriviaQuestion {
            question: "Klondike, popularized by its digital version, is a well-known type of which card game?",
            answers: ["Solitaire", "Poker", "Bridge", "Rummy"],
            correct_answer_index: 0,
        },
        TriviaQuestion {
            question: "Pussy Galore, played by Honor Blackman, is a famous character from which James Bond movie?",
            answers: ["Goldfinger", "Dr. No", "Thunderball", "You Only Live Twice"],
            correct_answer_index: 0,
        },
        TriviaQuestion {
            question: "The Tesla Roadster, the first electric sports car, is named after Nikola Tesla, who invented what?",
            answers: ["Alternating current (AC)", "Direct current (DC)", "Electric motor", "Radio"],
            correct_answer_index: 0,
        },
        TriviaQuestion {
            question: "The Simpsons' fictional Springfield is a reference to the setting of which '50s TV sitcom?",
            answers: ["Leave It to Beaver", "The Adventures of Ozzie and Harriet", "Father Knows Best", "The Flintstones"],
            correct_answer_index: 2,
        },
        TriviaQuestion {
            question: "Dr. Gregory House's apartment number '221B' is a nod to the address of which famous detective?",
            answers: ["Hercule Poirot", "Philip Marlowe", "Sherlock Holmes", "Sam Spade"],
            correct_answer_index: 2,
        },
        TriviaQuestion {
            question: "In the 2010 Fortune Global 500 list, 3 of the top 4 companies belong to which sector?",
            answers: ["Technology", "Automotive", "Energy", "Banking"],
            correct_answer_index: 2,
        },
        TriviaQuestion {
            question: "On the Fahrenheit scale, 98.6 degrees is generally accepted as what?",
            answers: ["Room temperature", "Freezing point of water", "Normal body temperature", "Boiling point of water"],
            correct_answer_index: 2,
        },
        TriviaQuestion {
            question: "On food labels, the abbreviation 'DV' stands for 'daily' what?",
            answers: ["Value", "Vitamin", "Volume", "Variety"],
            correct_answer_index: 0,
        },
        TriviaQuestion {
            question: "In the acronym 'SRS', commonly used for airbags, what does the letter 'R' stand for?",
            answers: ["Response", "Restriction", "Restraint", "Reaction"],
            correct_answer_index: 2,
        },
        TriviaQuestion {
            question: "Discovery Day in the Bahamas commemorates the arrival of which European explorer?",
            answers: ["Ferdinand Magellan", "Christopher Columbus", "Amerigo Vespucci", "John Cabot"],
            correct_answer_index: 1,
        },
        TriviaQuestion {
            question: "In the computer game 'The Oregon Trail,' players take on the role of which historical group?",
            answers: ["Cowboys", "Explorers", "Pioneers", "Soldiers"],
            correct_answer_index: 2,
        },
        TriviaQuestion {
            question: "In the Latin phrase 'veni, vidi, vici,' what does 'vidi' translate to?",
            answers: ["Came", "Conquered", "Fought", "Saw"],
            correct_answer_index: 3,
        },
        TriviaQuestion {
            question: "Which French leader is the namesake of Paris’s largest airport?",
            answers: ["Napoleon Bonaparte", "Charles de Gaulle", "Louis XVI", "François Mitterrand"],
            correct_answer_index: 1,
        },
        TriviaQuestion {
            question: "People who prevent others from succeeding are often compared to which animal 'in a bucket'?",
            answers: ["Frogs", "Crabs", "Snakes", "Mice"],
            correct_answer_index: 1,
        },
        TriviaQuestion {
            question: "What rock band, fronted by Jim Morrison, named one of their albums 'Morrison Hotel'?",
            answers: ["The Rolling Stones", "Led Zeppelin", "The Doors", "The Who"],
            correct_answer_index: 2,
        },
        TriviaQuestion {
            question: "Patients undergoing malar augmentation surgery are seeking to enhance what part of their body?",
            answers: ["Chin", "Nose", "Cheekbones", "Forehead"],
            correct_answer_index: 2,
        },
        TriviaQuestion {
            question: "In 1972, Jane Fonda earned an infamous nickname after being photographed on an anti-aircraft gun. What was it?",
            answers: ["Hanoi Jane", "Agent Jane", "War Jane", "Combat Jane"],
            correct_answer_index: 0,
        },
    ];
}

fn get_trivia_question(question_idx: usize) -> &'static TriviaQuestion {
    &QUESTIONS[question_idx]
}

pub struct AlexGamesTrivia {
    callbacks: &'static rust_game_api::CCallbacksPtr,

    question_idx: usize,
}

impl AlexGamesTrivia {
    fn show_question_popup_for_question(&self, question_info: &TriviaQuestion) {
        println!("show_question_popup...");
        let item_msg = PopupItem::Message {
            text: question_info.question,
        };
        let item_btn_a = &PopupItem::Button {
            id: POPUP_BTN_ID_ANSWER_A,
            text: question_info.answers[0],
        };
        let item_btn_b = &PopupItem::Button {
            id: POPUP_BTN_ID_ANSWER_B,
            text: question_info.answers[1],
        };
        let item_btn_c = &PopupItem::Button {
            id: POPUP_BTN_ID_ANSWER_C,
            text: question_info.answers[2],
        };
        let item_btn_d = &PopupItem::Button {
            id: POPUP_BTN_ID_ANSWER_D,
            text: question_info.answers[3],
        };

        let popup_info = Box::new(PopupInfo {
            title: "Question",
            items: vec![
                &item_msg,
                &item_btn_a,
                &item_btn_b,
                &item_btn_c,
                &item_btn_d,
            ],
        });
        println!("calling callbacks show_popup");
        self.callbacks.show_popup(POPUP_ID_QUESTION, &popup_info);
        println!("done calling callbacks show_popup");
    }

    fn show_question_popup(&self) {
        if self.question_idx < QUESTIONS.len() {
            let question = get_trivia_question(self.question_idx);
            self.show_question_popup_for_question(&question);
        } else {
            self.callbacks.show_popup(
                POPUP_ID_RESTART,
                &Box::new(PopupInfo {
                    title: "Out of questions",
                    items: vec![&PopupItem::Button {
                        id: 0,
                        text: "Restart",
                    }],
                }),
            );
        }
    }
}

impl AlexGamesApi for AlexGamesTrivia {
    fn init(&mut self, _callbacks: &rust_game_api::CCallbacksPtr) {
        //self.state = State::new();
        //print_questions();
    }

    fn callbacks(&self) -> &CCallbacksPtr {
        self.callbacks
    }

    fn start_game(&mut self, _state: Option<(i32, Vec<u8>)>) {
        self.show_question_popup();
    }

    fn update(&mut self, _dt_ms: i32) {}
    fn handle_user_clicked(&mut self, _pos_y: i32, _pos_x: i32) {}
    fn handle_btn_clicked(&mut self, _btn_id: &str) {}

    fn handle_popup_btn_clicked(
        &mut self,
        popup_id: &str,
        btn_idx: i32,
        _popup_state: &PopupState,
    ) {
        match popup_id {
            POPUP_ID_QUESTION => {
                let question = get_trivia_question(self.question_idx);
                let correct_answer_idx = question.correct_answer_index;
                let correct = (btn_idx - 1) == correct_answer_idx as i32;
                if correct {
                    self.callbacks.set_status_msg("Correct!");
                } else {
                    self.callbacks.set_status_msg("Incorrect!");
                }

                // TODO should do this
                //self.callbacks.hide_popup();

                let next_question_btn = &PopupItem::Button {
                    id: 0,
                    text: "Next question",
                };

                let incorrect_answer_text = &PopupItem::Message {
                    text: &format!(
                        "You guessed \"{}\", the correct answer was \"{}\".",
                        question.answers[btn_idx as usize - 1],
                        question.answers[correct_answer_idx]
                    ),
                };

                let correct_answer_text = &PopupItem::Message {
                    text: &format!(
                        "You correctly guessed \"{}\".",
                        question.answers[correct_answer_idx]
                    ),
                };

                let mut items: Vec<&PopupItem> = vec![];

                if !correct {
                    items.push(&incorrect_answer_text);
                } else {
                    items.push(&correct_answer_text);
                }

                items.push(&next_question_btn);

                self.callbacks.show_popup(
                    POPUP_ID_RESULT,
                    &Box::new(PopupInfo {
                        title: if correct { "Correct!" } else { "Incorrect!" },
                        items: items,
                    }),
                );
            }

            POPUP_ID_RESULT => {
                self.question_idx += 1;
                self.show_question_popup();
            }

            POPUP_ID_RESTART => {
                self.question_idx = 0;
                self.show_question_popup();
            }

            _ => {
                self.callbacks
                    .set_status_err(&format!("internal error: unhandled popup id {}", popup_id));
            }
        }
    }
}

pub fn init_trivia(callbacks: &'static rust_game_api::CCallbacksPtr) -> Box<dyn AlexGamesApi + '_> {
    let mut api = AlexGamesTrivia {
        callbacks: callbacks,
        question_idx: 0,
    };

    api.init(callbacks);
    Box::from(api)
}
