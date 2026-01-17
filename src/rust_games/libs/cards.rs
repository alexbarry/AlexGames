use rand::seq::SliceRandom;
use rand::thread_rng;

pub const SUIT_COUNT: usize = 4;
pub const RANK_COUNT: usize = 13;

#[derive(Copy, Clone, Debug, PartialEq)]
pub enum Rank {
    ValAce,
    Val2,
    Val3,
    Val4,
    Val5,
    Val6,
    Val7,
    Val8,
    Val9,
    Val10,
    ValJack,
    ValQueen,
    ValKing,
}

#[derive(Copy, Clone, Debug, PartialEq)]
pub enum Suit {
    Clubs,
    Spades,
    Diamonds,
    Hearts,
}

#[derive(Copy, Clone, Debug, PartialEq)]
pub struct Card {
    pub rank: Rank,
    pub suit: Suit,
}

use crate::rust_game_api::{CCallbacksPtr, TextAlign};

use crate::libs::draw::draw_rect_outline;
use crate::libs::point::Pt;

const CARD_BG: &str = "#ffffff";
const CARD_OUTLINE: &str = "#000000";
const CARD_FG_RED: &str = "#ff0000";
const CARD_FG_BLACK: &str = "#000000";
const CARD_OUTLINE_HIGHLIGHT: &str = "#ffcc0088";

const OUTLINE_THICKNESS: i32 = 1;
const OUTLINE_THICKNESS_HIGHLIGHT: i32 = 8;
const TEXT_SIZE_LARGE: i32 = 32;
const TEXT_SIZE_SMALL: i32 = 16;
const LARGE_TEXT_PADDING: i32 = 5;

// TODO make a good way for games to set their own card size, and not have to pass it in every time they draw a card?
//pub const CARD_SIZE: Pt = Pt { y: 70, x: 45 };
const CARD_WIDTH: i32 = 56;
pub const CARD_SIZE: Pt = Pt {
    y: CARD_WIDTH * 7 / 5,
    x: CARD_WIDTH,
};
const SUIT_SIZE_SMALL: Pt = Pt { y: 25, x: 20 };

fn num_to_rank(num: i32) -> Rank {
    match num {
        1 => Rank::ValAce,
        2 => Rank::Val2,
        3 => Rank::Val3,
        4 => Rank::Val4,
        5 => Rank::Val5,
        6 => Rank::Val6,
        7 => Rank::Val7,
        8 => Rank::Val8,
        9 => Rank::Val9,
        10 => Rank::Val10,
        11 => Rank::ValJack,
        12 => Rank::ValQueen,
        13 => Rank::ValKing,
        _ => {
            panic!("Unhandled value {} in num_to_rank", num);
        }
    }
}

fn rank_to_num(rank: Rank) -> i32 {
    match rank {
        Rank::ValAce => 1,
        Rank::Val2 => 2,
        Rank::Val3 => 3,
        Rank::Val4 => 4,
        Rank::Val5 => 5,
        Rank::Val6 => 6,
        Rank::Val7 => 7,
        Rank::Val8 => 8,
        Rank::Val9 => 9,
        Rank::Val10 => 10,
        Rank::ValJack => 11,
        Rank::ValQueen => 12,
        Rank::ValKing => 13,
    }
}

fn num_to_suit(num: i32) -> Suit {
    match num {
        0 => Suit::Clubs,
        1 => Suit::Spades,
        2 => Suit::Diamonds,
        3 => Suit::Hearts,
        _ => {
            panic!("Unhandled value in num_to_suit");
        }
    }
}

fn suit_to_num(suit: Suit) -> i32 {
    match suit {
        Suit::Clubs => 0,
        Suit::Spades => 1,
        Suit::Diamonds => 2,
        Suit::Hearts => 3,
    }
}

//     0 is reserved for "no card"
//  1-14 is for first suit,
// 15-28 is for second suit,
// 29-42 is for third suit,
// 43-56 is for fourth suit.
pub fn card_to_num(card: &Card) -> u8 {
    let num = 1 + suit_to_num(card.suit) * RANK_COUNT as i32 + rank_to_num(card.rank) - 1;
    num as u8
}

pub fn card_to_num_opt(card: &Option<Card>) -> u8 {
    if let Some(card) = card {
        card_to_num(card)
    } else {
        0
    }
}

pub fn num_to_card(num: u8) -> Option<Card> {
    match num {
        0 => None,
        1..=56 => {
            let num = num - 1;
            Some(Card {
                suit: num_to_suit((num / RANK_COUNT as u8) as i32),
                rank: num_to_rank((num % RANK_COUNT as u8 + 1) as i32),
            })
        }
        _ => {
            panic!("Unhandled num {} passed to num_to_card", num);
        }
    }
}

fn rank_to_text(rank: Rank) -> &'static str {
    match rank {
        Rank::ValAce => "A",
        Rank::Val2 => "2",
        Rank::Val3 => "3",
        Rank::Val4 => "4",
        Rank::Val5 => "5",
        Rank::Val6 => "6",
        Rank::Val7 => "7",
        Rank::Val8 => "8",
        Rank::Val9 => "9",
        Rank::Val10 => "10",
        Rank::ValJack => "J",
        Rank::ValQueen => "Q",
        Rank::ValKing => "K",
    }
}

const IMG_ID_CARD_FACEDOWN: &str = "card_facedown";
const IMG_ID_CARD_HIGHLIGHT: &str = "card_highlight";

fn suit_to_img_id(suit: Suit) -> &'static str {
    match suit {
        Suit::Clubs => "card_clubs",
        Suit::Spades => "card_spades",
        Suit::Diamonds => "card_diamonds",
        Suit::Hearts => "card_hearts",
    }
}

fn suit_is_red(suit: Suit) -> bool {
    match suit {
        Suit::Clubs | Suit::Spades => false,
        Suit::Diamonds | Suit::Hearts => true,
    }
}

pub fn draw_card(callbacks: &CCallbacksPtr, card: &Card, pt: &Pt, highlight: bool) {
    draw_card_internal(callbacks, Some(card), false, pt, highlight);
}
pub fn draw_card_facedown(callbacks: &CCallbacksPtr, pt: &Pt) {
    draw_card_internal(callbacks, None, true, pt, false);
}

pub fn draw_card_space(callbacks: &CCallbacksPtr, pt: &Pt) {
    draw_card_internal(callbacks, None, false, pt, false);
}

// TODO replace the card and face_down params with an enum or something
fn draw_card_internal(
    callbacks: &CCallbacksPtr,
    card: Option<&Card>,
    face_down: bool,
    pt: &Pt,
    highlight: bool,
) {
    let y1 = pt.y;
    let x1 = pt.x;
    let y2 = pt.y + CARD_SIZE.y;
    let x2 = pt.x + CARD_SIZE.x;

    //if let Some(card) = card {
    if !face_down && card.is_some() {
        let card = card.unwrap();

        callbacks.draw_rect(CARD_BG, y1, x1, y2, x2);
        let text = rank_to_text(card.rank);
        let txt_colour = if suit_is_red(card.suit) {
            CARD_FG_RED
        } else {
            CARD_FG_BLACK
        };

        let padding = 3;
        callbacks.draw_text(
            &text,
            &txt_colour,
            pt.y + padding + TEXT_SIZE_SMALL,
            pt.x + padding,
            TEXT_SIZE_SMALL,
            TextAlign::Left,
        );
        let suit_img_id = suit_to_img_id(card.suit);
        callbacks.draw_graphic(
            &suit_img_id,
            y1 + padding + SUIT_SIZE_SMALL.y / 2,
            x2 - padding - SUIT_SIZE_SMALL.x / 2,
            SUIT_SIZE_SMALL.x,
            SUIT_SIZE_SMALL.y,
            None,
        );
        callbacks.draw_text(
            &text,
            &txt_colour,
            y2 - padding - LARGE_TEXT_PADDING,
            x1 + CARD_SIZE.x / 2,
            TEXT_SIZE_LARGE,
            TextAlign::Middle,
        );
        draw_rect_outline(callbacks, &CARD_OUTLINE, OUTLINE_THICKNESS, y1, x1, y2, x2);
        if highlight {
            //draw_rect_outline(callbacks, &CARD_OUTLINE_HIGHLIGHT, OUTLINE_THICKNESS_HIGHLIGHT, y1, x1, y2, x2);
            let highlight_padding = 4;
            callbacks.draw_graphic(
                IMG_ID_CARD_HIGHLIGHT,
                pt.y + CARD_SIZE.y / 2,
                pt.x + CARD_SIZE.x / 2,
                CARD_SIZE.x + 2 * highlight_padding,
                CARD_SIZE.y + 2 * highlight_padding,
                None,
            );
        }
    } else if face_down {
        callbacks.draw_graphic(
            IMG_ID_CARD_FACEDOWN,
            pt.y + CARD_SIZE.y / 2,
            pt.x + CARD_SIZE.x / 2,
            CARD_SIZE.x,
            CARD_SIZE.y,
            None,
        );
        draw_rect_outline(callbacks, &CARD_OUTLINE, OUTLINE_THICKNESS, y1, x1, y2, x2);
    } else {
        callbacks.draw_rect(&"#00000044", y1, x1, y2, x2);
        draw_rect_outline(callbacks, &"#00000011", OUTLINE_THICKNESS, y1, x1, y2, x2);
    }
}

pub fn new_deck() -> Vec<Card> {
    let mut deck: Vec<Card> = Vec::new();
    for rank_num in 1..=13 {
        for suit_num in 0..=3 {
            let rank = num_to_rank(rank_num);
            let suit = num_to_suit(suit_num);
            let card = Card {
                rank: rank,
                suit: suit,
            };
            assert!(
                num_to_card(card_to_num(&card)).unwrap() == card,
                "error serializing {:?}",
                card
            );
            deck.push(card);
        }
    }
    return deck;
}

pub fn shuffle_deck(deck: &mut Vec<Card>) {
    let mut rng = thread_rng();
    deck.shuffle(&mut rng);
}

pub fn can_place_on_goal(card: Card, goal_stack: &Vec<Card>) -> bool {
    if goal_stack.len() == 0 {
        return card.rank == Rank::ValAce;
    } else {
        let goal_top = goal_stack[goal_stack.len() - 1];
        if goal_top.suit == card.suit {
            return rank_to_num(goal_top.rank) == rank_to_num(card.rank) - 1;
        }
    }

    return false;
}

pub fn can_place_on_play_area(card1: &Card, card2: &Card) -> bool {
    suit_is_red(card1.suit) != suit_is_red(card2.suit)
        && rank_to_num(card1.rank) == rank_to_num(card2.rank) - 1
}
