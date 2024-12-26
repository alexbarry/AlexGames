use std::cell::RefCell;
use std::cmp::Ordering;
use std::collections::HashMap;
use std::rc::{Rc, Weak};

use rand::Rng;

// TODO move these structs to the general AI crate,
// and maybe make a "random" implementation of AI,
// then make MCTS separate

//pub struct MCTSParams<GameState> {
pub struct MCTSParams<GameState, GameMove> {
    //get_game_state: fn(GameState) -> String,
    pub get_possible_moves: fn(GameState) -> Vec<GameMove>,
    pub apply_move: fn(GameState, GameMove) -> GameState,
    pub get_score: fn(GameState) -> i32,
    pub init_state: GameState,
}

pub struct MCTSState<GameState, GameMove> {
    get_possible_moves: fn(GameState) -> Vec<GameMove>,
    apply_move: fn(GameState, GameMove) -> GameState,
    get_score: fn(GameState) -> i32,

    current_node: Rc<RefCell<Node<GameState, GameMove>>>,
}

struct Node<GameState, GameMove> {
    state: GameState,
    win_count: i32,
    sim_count: i32,
    parent: Option<Weak<RefCell<Node<GameState, GameMove>>>>,
    //children: Map<GameMove, RefCell<Box<Node<GameState, GameMove>>>>,
    children: HashMap<GameMove, Rc<RefCell<Node<GameState, GameMove>>>>,
}

impl<GameState, GameMove> Node<GameState, GameMove> {
    pub fn new(init_state: GameState) -> Rc<RefCell<Node<GameState, GameMove>>> {
        let new_node = Node {
            state: init_state,
            win_count: 0,
            sim_count: 0,
            parent: None,
            children: HashMap::new(),
        };
        let new_node = Rc::new(RefCell::new(new_node));
        new_node
    }

    // UCT: Upper Confidence Bound 1 applied to Trees
    pub fn uct_score(&self, parent_sim_count: i32) -> f64 {
        if self.sim_count == 0 {
            return f64::INFINITY;
        }
        let win_count = self.win_count as f64;
        let sim_count = self.sim_count as f64;
        let exploration_param_squared = 2.0f64;

        let parent_sim_count = parent_sim_count as f64;

        win_count / sim_count
            + (exploration_param_squared * parent_sim_count.ln() / sim_count).sqrt()
    }
}

impl<GameState, GameMove> MCTSState<GameState, GameMove>
where
    GameState: Copy + std::fmt::Debug,
    GameMove: Copy + std::cmp::Eq + std::hash::Hash + std::fmt::Debug,
{
    pub fn init(params: MCTSParams<GameState, GameMove>) -> MCTSState<GameState, GameMove> {
        MCTSState::<GameState, GameMove> {
            get_possible_moves: params.get_possible_moves,
            apply_move: params.apply_move,
            get_score: params.get_score,
            current_node: Node::new(params.init_state),
        }
    }

    pub fn get_move(&mut self, game_state: GameState) -> Option<GameMove> {
        //println!("AI get_move called with state: {:?}", game_state);
        //println!("AI get_move found {} possible moves", moves.len());

        // TODO:
        // struct Node that has game state and scores
        // create a Map<Pt,Node>
        // populate it randomly, update scores of previous nodes
        // that's it?

        // Get random move
        if false {
            let moves = self.get_possible_moves(game_state);
            let random_index = rand::thread_rng().gen_range(0..moves.len());
            return Some(moves[random_index]);
        }

        //for _ in 0..10_000 {
        for _ in 0..5 {
            self.expand_tree_once();
        }

        let mut best_move = None;
        let mut best_move_score = 0.0;
        let binding = self.current_node.borrow();
        for (game_move, node) in binding.children.iter() {
            let score = node.borrow().uct_score(0);
            println!("Move {:?} has score: {}", game_move, score);
            if score > best_move_score {
                best_move = Some(game_move);
                best_move_score = score;
            }
        }

        return best_move.copied();
    }

    fn get_possible_moves(&self, game_state: GameState) -> Vec<GameMove> {
        return (self.get_possible_moves)(game_state);
    }

    fn simulate_node(&self, current_node: &mut Rc<RefCell<Node<GameState, GameMove>>>) -> i32 {
        let mut rng = rand::thread_rng();
        let apply_move = self.apply_move;
        let get_score = self.get_score;
        let get_possible_moves = self.get_possible_moves;

        let mut state = current_node.borrow().state;
        loop {
            let moves = get_possible_moves(state);
            // TODO: right now a pass is not an option
            // but it should be. Perhaps just hack something in to have get_possible_moves return a pass if
            // there aren't any other moves, so that the game can continue simulating
            // TODO: so then I don't think I strictly need a separate function for "is the game over?",
            // zero possible moves means game over
            if moves.len() == 0 {
                break;
            }
            let game_move = moves[rng.gen_range(0..moves.len())];
            state = (apply_move)(state, game_move);
        }
        return (get_score)(state);
    }

    fn inc_counts_and_parents(
        &mut self,
        node: &mut Rc<RefCell<Node<GameState, GameMove>>>,
        win_change: i32,
        sim_change: i32,
    ) {
        loop {
            node.borrow_mut().win_count += win_change;
            node.borrow_mut().sim_count += sim_change;

            let parent_opt = {
                let node_borrow = node.borrow();
                node_borrow.parent.as_ref().and_then(|weak| weak.upgrade())
            };

            if let Some(parent) = parent_opt {
                *node = parent;
            } else {
                break;
            }
        }
    }

    fn expand_node(&mut self, current_node: &mut Rc<RefCell<Node<GameState, GameMove>>>) {
        let apply_move = self.apply_move;
        let get_possible_moves = self.get_possible_moves;

        //let node = &mut self.current_node;
        let node = current_node;
        let game_state = node.borrow().state;
        let moves = (get_possible_moves)(game_state);

        for game_move in moves.iter() {
            let new_game_state = game_state.clone();
            let new_game_state = (apply_move)(new_game_state, *game_move);
            let mut new_node = Node::new(new_game_state);

            let parent = &mut *node;
            let score = self.simulate_node(&mut new_node);
            let score_inc = if score > 0 { 1 } else { 0 };
            self.inc_counts_and_parents(&mut new_node, score_inc, 1);
            new_node.borrow_mut().parent = Some(Rc::downgrade(parent));
            parent.borrow_mut().children.insert(*game_move, new_node);
        }
    }

    fn expand_tree_once(&mut self) {
        //let mut node = &mut self.current_node;
        let mut node = Rc::clone(&self.current_node);
        let mut depth = 0;

        loop {
            let parent_sim_count = node.borrow().sim_count;
            let next_node_and_key = {
                let children = node.borrow().children.clone();
                children.into_iter().max_by(|(_, a), (_, b)| {
                    a.borrow()
                        .uct_score(parent_sim_count)
                        .partial_cmp(&b.borrow().uct_score(parent_sim_count))
                        .unwrap_or(Ordering::Less)
                })
            };

            if let Some((_, next_node)) = next_node_and_key {
                node = next_node;
                depth += 1;
            } else {
                self.expand_node(&mut node);
                println!("Expanded tree at depth {}", depth);
                break;
            }
        }
    }
}
