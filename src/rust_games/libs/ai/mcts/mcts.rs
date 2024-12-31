use std::cell::RefCell;
use std::cmp::Ordering;
use std::collections::HashMap;
use std::rc::{Rc, Weak};
//use std::time::{SystemTime, UNIX_EPOCH};

// TODO REMOVE, figure out how to remove this
use crate::rust_game_api::{CCallbacksPtr, TimeMs};

use rand::Rng;

// TODO move these structs to the general AI crate,
// and maybe make a "random" implementation of AI,
// then make MCTS separate

pub type PlayerId = i32;

pub trait MCTSGameFuncs<GameState: ?Sized, GameMove>: 'static {
    fn get_possible_moves(&self, state: &GameState) -> Vec<GameMove>;
    //fn get_possible_moves<'a>(&'a self, state: GameState<'a>) -> Vec<GameMove<'a>>;

    /*
        fn get_player_turn(&self, state: GameState) -> PlayerId;
        fn apply_move(&mut self, state: GameState, game_move: GameMove) -> GameState;
        fn get_score(&self, state: GameState, player: PlayerId) -> i32;
    */
}

//pub struct MCTSParams<GameState> {
#[derive(Clone)]
pub struct MCTSParams<GameState, GameMove>
where
    GameState: Clone,
    GameMove: Clone,
{
    //get_game_state: fn(GameState) -> String,
    pub get_possible_moves: fn(&GameState) -> Vec<GameMove>,
    pub get_player_turn: fn(&GameState) -> PlayerId,
    pub apply_move: fn(&GameState, GameMove) -> GameState,
    pub get_score: fn(&GameState, PlayerId) -> i32,

    pub game_funcs: Rc<dyn MCTSGameFuncs<GameState, GameMove>>,

    pub init_state: GameState,

    pub get_time_ms: Option<fn() -> TimeMs>,
    pub expansion_count: i32,

    // TODO REMOVE, figure out how to remove this
    pub callbacks: &'static CCallbacksPtr,
}

#[allow(dead_code)]
#[derive(Debug)]
pub struct MCTSInfo {
    pub score: f64,
    pub max_depth: i32,
    pub node_count: i32,
    pub time_ms: i32,
}

pub struct MCTSState<GameState, GameMove>
where
    GameState: Clone,
    GameMove: Clone,
{
    params: MCTSParams<GameState, GameMove>,
    current_node: Rc<RefCell<Node<GameState, GameMove>>>,
}

// I don't understand this, why would I make this uppercase if it changes?
#[allow(non_upper_case_globals)]
static mut g_node_count: i64 = 10;
struct Node<GameState, GameMove> {
    #[allow(dead_code)]
    id: i64,
    state: GameState,
    win_count: i32,
    sim_count: i32,
    parent: Option<Weak<RefCell<Node<GameState, GameMove>>>>,
    //children: Map<GameMove, RefCell<Box<Node<GameState, GameMove>>>>,
    children: HashMap<GameMove, Rc<RefCell<Node<GameState, GameMove>>>>,
}

/*
impl<GameState, GameMove> Clone for Node<GameState, GameMove> {
    fn clone(&self) -> Self {
        Node {
            id: 1_000_000 + self.id,
            state: self.state,
            win_count: self.win_count,
            sim_count: self.sim_count,
            parent: self.parent.clone(),
            children: self.children.clone(),
        }
    }
}
*/

impl<GameState, GameMove> Node<GameState, GameMove> {
    pub fn new(init_state: GameState) -> Rc<RefCell<Node<GameState, GameMove>>> {
        //println!("[mcts] Read node count {} for new node...", unsafe { g_node_count });
        let new_node = Node {
            id: unsafe { g_node_count },
            state: init_state,
            win_count: 0,
            sim_count: 0,
            parent: None,
            children: HashMap::new(),
        };
        let new_node = Rc::new(RefCell::new(new_node));
        unsafe {
            g_node_count += 1;
        }
        //println!("[mcts] Node count is now {}, returned new node with id {}", unsafe { g_node_count }, new_node.borrow().id);
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
            + if parent_sim_count > 0.0 {
                (exploration_param_squared * parent_sim_count.ln() / sim_count).sqrt()
            } else {
                0.0
            }
    }

    fn get_info(&self) -> (i32, i32) {
        let mut max_depth = 1;
        let mut node_count = 1;

        let mut max_depth_from_here = 0;
        for (_, child) in self.children.iter() {
            let (child_max_depth, child_node_count) = child.borrow().get_info();
            if child_max_depth > max_depth_from_here {
                max_depth_from_here = child_max_depth;
            }
            node_count += child_node_count;
        }
        max_depth += max_depth_from_here;

        (max_depth, node_count)
    }
}

impl<GameState, GameMove> MCTSState<GameState, GameMove>
where
    //GameState: Copy + std::fmt::Debug /* TODO remove after debugging */ + std::cmp::PartialEq,
    //GameMove: Copy + std::cmp::Eq + std::hash::Hash + std::fmt::Debug + std::clone::Clone,
    GameState:
        std::fmt::Debug /* TODO remove after debugging */ + std::cmp::PartialEq + std::clone::Clone,
    GameMove: std::cmp::Eq + std::hash::Hash + std::fmt::Debug + std::clone::Clone,
{
    pub fn init(params: MCTSParams<GameState, GameMove>) -> MCTSState<GameState, GameMove> {
        let mut state = MCTSState::<GameState, GameMove> {
            params: params.clone(),
            current_node: Node::new(params.clone().init_state),
        };
        //state.expand_node(current_node);
        MCTSState::expand_node(params.clone(), &mut state.current_node);
        //println!("[mcts] Initialized tree, root node id {} with children {}", state.current_node.borrow().id, state.current_node.borrow().children.len());

        state
    }

    pub fn move_node(&mut self, game_state: GameState, game_move: GameMove) {
        let debug = true;
        if debug {
            assert!(self.current_node.borrow().state == game_state);
            assert!(self
                .get_possible_moves(&self.current_node.borrow().state)
                .contains(&game_move));
        }

        let new_node = Rc::clone(self.current_node.borrow().children.get(&game_move).unwrap());
        self.current_node = new_node;
    }

    fn get_time_ms(&self) -> TimeMs {
        if let Some(get_time_ms) = self.params.get_time_ms {
            return (get_time_ms)();
        } else {
            //return SystemTime::now().duration_since(UNIX_EPOCH).expect("error getting time from std::time::Instant").as_millis() as i32;
            return self.params.callbacks.get_time_ms();
        }
    }

    /*
    pub fn iter_mcts(&mut self, game_state: GameState, iter_count: i32) {
    //pub fn get_move(&mut self, game_state: GameState) -> (Option<GameMove>, MCTSInfo) {
        //let start_time = Instant::now();
        let start_time = self.get_time_ms();
        //println!("get_move");
        //println!("AI get_move called with state: {:?}", game_state);
        //println!("AI get_move found {} possible moves", moves.len());

        // TODO:
        // struct Node that has game state and scores
        // create a Map<Pt,Node>
        // populate it randomly, update scores of previous nodes
        // that's it?

        //let expansion_count = 300;
        //for _ in 0..10_000 {
        for _ in 0..self.params.expansion_count {
            //println!("expand_tree_once count");
            self.expand_tree_once();
        }
        //self.print_node(&self.current_node.borrow(), 0, 0);
    }
    */

    pub fn get_move(&mut self, game_state: GameState) -> Option<GameMove> {
        let mut best_move = None;
        let mut best_move_score = 0.0;
        let binding = self.current_node.borrow();
        for (game_move, node) in binding.children.iter() {
            let score = node.borrow().uct_score(0);
            println!("[mcts] Move {:?} has score: {}", game_move, score);
            if best_move_score == 0.0 || score > best_move_score {
                best_move = Some(game_move);
                best_move_score = score;
            }
        }

        println!(
            "[mcts] Choosing best move {:?}, score: {}",
            best_move, best_move_score
        );
        //let search_duration = (self.get_time_ms() - start_time) as i32;

        let (max_depth, node_count) = self.current_node.borrow().get_info();
        let info = MCTSInfo {
            max_depth: max_depth,
            node_count: node_count,
            score: best_move_score,
            //time_ms: search_duration,
            time_ms: 0,
        };
        //return (best_move.copied(), info);
        //return best_move.copied();
        return best_move.cloned();
    }

    fn get_possible_moves(&self, game_state: &GameState) -> Vec<GameMove> {
        return (self.params.get_possible_moves)(game_state);
    }

    fn simulate_node(
        params: MCTSParams<GameState, GameMove>,
        current_node: &Rc<RefCell<Node<GameState, GameMove>>>,
    ) -> i32 {
        let mut rng = rand::thread_rng();

        let mut state = current_node.borrow().state.clone();
        let player = (params.get_player_turn)(&state);
        loop {
            let moves = (params.get_possible_moves)(&state);
            // TODO: right now a pass is not an option
            // but it should be. Perhaps just hack something in to have get_possible_moves return a pass if
            // there aren't any other moves, so that the game can continue simulating
            // TODO: so then I don't think I strictly need a separate function for "is the game over?",
            // zero possible moves means game over
            if moves.len() == 0 {
                break;
            }
            let game_move = moves[rng.gen_range(0..moves.len())].clone();
            state = (params.apply_move)(&state, game_move);
        }
        return (params.get_score)(&state, player);
    }

    fn update_node_counts(
        params: &MCTSParams<GameState, GameMove>,
        mut node: Rc<RefCell<Node<GameState, GameMove>>>,
        player: PlayerId,
        win_change: i32,
        sim_change: i32,
    ) {
        //let max_depth = 1000;
        //for _ in 0..max_depth {
        loop {
            //println!("Incremented node counts by ({}, {})", win_change, sim_change);
            let node_player = (params.get_player_turn)(&node.borrow().state);

            if player == node_player {
                node.borrow_mut().win_count += win_change;
            }
            node.borrow_mut().sim_count += sim_change;

            let parent_opt = {
                let node_borrow = node.borrow();
                node_borrow.parent.as_ref().and_then(|weak| weak.upgrade())
            };

            if let Some(parent) = parent_opt {
                node = parent.clone();
            } else {
                break;
            }
        }
    }

    fn expand_node(
        params: MCTSParams<GameState, GameMove>,
        current_node: &mut Rc<RefCell<Node<GameState, GameMove>>>,
    ) {
        //println!("[mcts] expand_node");

        //let node = &mut self.current_node;
        let node = current_node;
        let game_state = &node.borrow().state;
        let moves = (params.get_possible_moves)(game_state);

        for game_move in moves.iter() {
            //let new_game_state = game_state.clone();
            let player = (params.get_player_turn)(&game_state);
            let new_game_state = (params.apply_move)(&game_state, game_move.clone());
            let new_node = Node::new(new_game_state);
            //println!("[mcts] Created new node with id {}", new_node.borrow().id);

            //let parent = &mut *node;
            //let parent = node;
            //println!("[mcts] 1/5 Double checking new node id {} ###", new_node.borrow().id);
            let score = MCTSState::simulate_node(params.clone(), &new_node);
            //println!("[mcts] 2/5 Double checking new node id {} ###", new_node.borrow().id);
            let score_inc = if score > 0 { 1 } else { 0 };
            //let score_inc = if score > 0 { 1 + (score / 10) } else { 0 };
            //println!("[mcts] 3/5 Double checking new node id {} ###", new_node.borrow().id);
            new_node.borrow_mut().parent = Some(Rc::downgrade(node));
            //println!("[mcts] 4/5 Double checking new node id {} ###", new_node.borrow().id);
            MCTSState::update_node_counts(&params, Rc::clone(&new_node), player, score_inc, 1);
            //println!("[mcts] 5/5 Double checking new node id {} ###", new_node.borrow().id);
            //println!("[mcts] to node {}, added child node {}", node.borrow().id, new_node.borrow().id);
            node.borrow_mut()
                .children
                .insert(game_move.clone(), new_node);
        }
    }

    pub fn expand_tree_once(&mut self) {
        //println!("[mcts] expand_tree_once");
        //let mut node = &mut self.current_node;
        let mut node = Rc::clone(&self.current_node);
        //let mut depth = 0;

        //println!("[mcts] Starting with node {}, (children count: {})", node.borrow().id, node.borrow().children.len());
        for (_game_move, _child_node) in node.borrow().children.iter() {
            //println!("[mcts]     child: node {}", child_node.borrow().id);
        }
        //let max_depth = 10_000;
        //for _ in 0..max_depth {
        loop {
            if node.borrow().children.len() == 0 {
                MCTSState::expand_node(self.params.clone(), &mut node);
                //println!("Expanded tree at depth {}", depth);
                break;
            }

            //println!("expand_tree_once loop... node {}", node.borrow().id);
            let parent_sim_count = node.borrow().sim_count;
            let next_node_key = {
                node.borrow()
                    .children
                    .iter()
                    .max_by(|(_, a), (_, b)| {
                        a.borrow()
                            .uct_score(parent_sim_count.into())
                            .partial_cmp(&b.borrow().uct_score(parent_sim_count.into()))
                            .unwrap_or(Ordering::Equal)
                    })
                    .map(|(key, _)| key.clone())
                    .unwrap()
                //.cloned()
            };

            //let node_borrow = node.borrow();
            let next_node = {
                let children = node.borrow().children.clone();
                children.get(&next_node_key).unwrap().clone()
            };
            //node = Rc::clone(next_node);
            node = next_node.clone();
            //println!("[mcts] Moving to node {}", node.borrow().id);
            //depth += 1;
        }
    }

    pub fn get_move_score(&self, game_move: GameMove) -> f64 {
        self.current_node
            .borrow()
            .children
            .get(&game_move)
            .unwrap()
            .borrow()
            .uct_score(0)
    }

    pub fn get_info(&self) -> MCTSInfo {
        let (max_depth, node_count) = self.current_node.borrow().get_info();
        MCTSInfo {
            score: 0.0,
            max_depth: max_depth,
            node_count: node_count,
            time_ms: 0,
        }
    }

    fn _print_node(
        &self,
        node: &Node<GameState, GameMove>,
        parent_sim_count: i32,
        indent_depth: i32,
    ) {
        let indent = "   ".repeat(indent_depth as usize);
        println!(
            "{}Node (w:{}, n:{}, N:{}, score: {}) with {} children:",
            indent,
            node.win_count,
            node.sim_count,
            parent_sim_count,
            node.uct_score(parent_sim_count),
            node.children.len()
        );
        for (_game_move, child) in node.children.iter() {
            self._print_node(&child.borrow(), node.sim_count, indent_depth + 1);
        }
    }
}
