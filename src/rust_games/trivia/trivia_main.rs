// Trivia
//
// TODO:
//   * add local and network multiplayer support.
//   * track score(s)
//   * add more questions, maybe categories and difficulty level
//   * saved state?

use crate::rust_game_api;
use crate::rust_game_api::{
    AlexGamesApi, CCallbacksPtr, MouseEvt, PopupInfo, PopupItem, PopupState,
};

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

        // TODO add more questions

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
    fn init(&mut self, callbacks: &rust_game_api::CCallbacksPtr) {
        //self.state = State::new();
        //print_questions();
    }

    fn callbacks(&self) -> &CCallbacksPtr {
        self.callbacks
    }

    fn start_game(&mut self, state: Option<(i32, Vec<u8>)>) {
        self.show_question_popup();
    }

    fn update(&mut self, dt_ms: i32) {}
    fn handle_user_clicked(&mut self, pos_y: i32, pos_x: i32) {}
    fn handle_btn_clicked(&mut self, btn_id: &str) {}

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
