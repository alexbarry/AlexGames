/**
 * Libraries for games using or drawing playing cards.
 */
use rand::seq::SliceRandom;
use rand::thread_rng;

pub const SUIT_COUNT: usize = 4;
pub const RANK_COUNT: usize = 13;

pub const TEXT_SUIT_SPADES: &'static str = "\u{2660}";
pub const TEXT_SUIT_HEARTS: &'static str = "\u{2665}";
pub const TEXT_SUIT_DIAMONDS: &'static str = "\u{2666}";
pub const TEXT_SUIT_CLUBS: &'static str = "\u{2663}";

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

impl Suit {
    pub fn to_unicode_symbol(&self) -> &'static str {
        match self {
            Suit::Clubs => TEXT_SUIT_CLUBS,
            Suit::Spades => TEXT_SUIT_SPADES,
            Suit::Diamonds => TEXT_SUIT_DIAMONDS,
            Suit::Hearts => TEXT_SUIT_HEARTS,
        }
    }
}

#[derive(Copy, Clone, Debug, PartialEq)]
pub struct Card {
    pub rank: Rank,
    pub suit: Suit,
}

use crate::rust_game_api::{CCallbacksPtr, TextAlign};

use crate::libs::draw::draw_rect_outline;
use crate::libs::point::Pt;

#[derive(Copy, Clone, Debug)]
pub struct CardDrawColours {
    pub bg: &'static str,
    pub outline: &'static str,
    pub fg_red: &'static str,
    pub fg_black: &'static str,
    pub outline_highlight: &'static str,

    pub empty_space_outline: &'static str,
    pub empty_space_fill: &'static str,

    pub overlay_colour: Option<&'static str>,
}

pub const DEFAULT_CARD_COLOURS_LIGHT: CardDrawColours = CardDrawColours {
    bg: "#ffffff",
    outline: "#000000",
    fg_red: "#ff0000",
    fg_black: "#000000",
    outline_highlight: "#ffcc0088",

    empty_space_fill: "#00000044",
    empty_space_outline: "#00000011",

    overlay_colour: None,
};

pub const DEFAULT_CARD_COLOURS_DARK: CardDrawColours = CardDrawColours {
    bg: "#ffffff",
    outline: "#000000",
    fg_red: "#ff0000",
    fg_black: "#000000",
    outline_highlight: "#ffcc0088",

    empty_space_fill: "#00000044",
    empty_space_outline: "#00000011",

    overlay_colour: Some("#00000088"),
};

#[derive(Copy, Clone, Debug)]
pub struct CardDrawSize {
    pub width: i32,
    pub height: i32,
    pub suit_width: i32,
    pub suit_height: i32,
    pub text_size_large: i32,
    pub text_size_small: i32,
    pub large_text_padding: i32,
    pub padding: i32,
    pub highlight_padding: i32,

    pub outline_thickness: i32,
    pub outline_thickness_highlight: i32,
}

/**
 * Cards that are just wide enough that 8 of them can fit on a 480 pixel wide canvas,
 * with a bit of padding between them.
 */
pub const CARD_SIZE_8_WIDE: CardDrawSize = CardDrawSize {
    width: 56,
    height: 56 * 7 / 5,
    suit_width: 20,
    suit_height: 25,
    text_size_large: 32,
    text_size_small: 16,
    large_text_padding: 5,
    padding: 3,
    highlight_padding: 4,

    outline_thickness: 1,
    outline_thickness_highlight: 8,
};

#[derive(Copy, Clone, Debug)]
pub struct CardDraw {
    pub size: CardDrawSize,
    pub colours: Option<&'static CardDrawColours>,
}

// const SUIT_SIZE_SMALL: Pt = Pt { y: 25, x: 20 };

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

pub fn rank_to_num(rank: Rank) -> i32 {
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

pub fn num_to_suit(num: i32) -> Suit {
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

pub fn suit_to_num(suit: Suit) -> i32 {
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

impl CardDraw {
    pub fn draw_card(&self, callbacks: &CCallbacksPtr, card: &Card, pt: &Pt, highlight: bool) {
        self.draw_card_internal(callbacks, Some(card), false, pt, highlight);
    }
    pub fn draw_card_facedown(&self, callbacks: &CCallbacksPtr, pt: &Pt) {
        self.draw_card_internal(callbacks, None, true, pt, false);
    }

    pub fn draw_card_space(&self, callbacks: &CCallbacksPtr, pt: &Pt) {
        self.draw_card_internal(callbacks, None, false, pt, false);
    }

    pub fn card_centre(&self, pt: &Pt) -> Pt {
        pt.add(Pt {
            y: self.size.height / 2,
            x: self.size.width / 2,
        })
    }

    pub fn draw_card_space_text(
        &self,
        callbacks: &CCallbacksPtr,
        pt: &Pt,
        text: &str,
        text_colour: &str,
        text_size: i32,
    ) {
        let pt = pt.add(Pt {
            y: self.size.height / 2 + text_size / 2,
            x: self.size.width / 2,
        });
        callbacks.draw_text(text, text_colour, pt.y, pt.x, text_size, TextAlign::Middle);
    }

    // TODO replace the card and face_down params with an enum or something
    fn draw_card_internal(
        &self,
        callbacks: &CCallbacksPtr,
        card: Option<&Card>,
        face_down: bool,
        pt: &Pt,
        highlight: bool,
    ) {
        //let card_size = &CARD_SIZE_8_WIDE;
        //let card_colours = &DEFAULT_CARD_COLOURS_LIGHT;
        let card_size = &self.size;
        let card_colours = if let Some(colours) = self.colours {
            colours
        } else {
            &DEFAULT_CARD_COLOURS_LIGHT
        };
        let y1 = pt.y;
        let x1 = pt.x;
        let y2 = pt.y + card_size.height;
        let x2 = pt.x + card_size.width;

        //if let Some(card) = card {
        if !face_down && card.is_some() {
            let card = card.unwrap();

            callbacks.draw_rect(card_colours.bg, y1, x1, y2, x2);
            let text = rank_to_text(card.rank);
            let txt_colour = if suit_is_red(card.suit) {
                card_colours.fg_red
            } else {
                card_colours.fg_black
            };

            let padding = card_size.padding;
            callbacks.draw_text(
                &text,
                &txt_colour,
                pt.y + padding + card_size.text_size_small,
                pt.x + padding,
                card_size.text_size_small,
                TextAlign::Left,
            );
            let suit_img_id = suit_to_img_id(card.suit);
            callbacks.draw_graphic(
                &suit_img_id,
                y1 + padding + card_size.suit_height / 2,
                x2 - padding - card_size.suit_width / 2,
                card_size.suit_width,
                card_size.suit_height,
                None,
            );
            callbacks.draw_text(
                &text,
                &txt_colour,
                y2 - padding - card_size.large_text_padding,
                x1 + card_size.width / 2,
                card_size.text_size_large,
                TextAlign::Middle,
            );
            draw_rect_outline(
                callbacks,
                &card_colours.outline,
                card_size.outline_thickness,
                y1,
                x1,
                y2,
                x2,
            );

            if let Some(overlay_colour) = card_colours.overlay_colour {
                callbacks.draw_rect(overlay_colour, y1, x1, y2, x2);
            }
            if highlight {
                //draw_rect_outline(callbacks, &CARD_OUTLINE_HIGHLIGHT, OUTLINE_THICKNESS_HIGHLIGHT, y1, x1, y2, x2);
                callbacks.draw_graphic(
                    IMG_ID_CARD_HIGHLIGHT,
                    pt.y + card_size.height / 2,
                    pt.x + card_size.width / 2,
                    card_size.width + 2 * card_size.highlight_padding,
                    card_size.height + 2 * card_size.highlight_padding,
                    None,
                );
            }
        } else if face_down {
            callbacks.draw_graphic(
                IMG_ID_CARD_FACEDOWN,
                pt.y + card_size.height / 2,
                pt.x + card_size.width / 2,
                card_size.width,
                card_size.height,
                None,
            );
            draw_rect_outline(
                callbacks,
                card_colours.outline,
                card_size.outline_thickness,
                y1,
                x1,
                y2,
                x2,
            );
        } else {
            callbacks.draw_rect(card_colours.empty_space_fill, y1, x1, y2, x2);
            draw_rect_outline(
                callbacks,
                card_colours.empty_space_outline,
                card_size.outline_thickness,
                y1,
                x1,
                y2,
                x2,
            );
        }
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
