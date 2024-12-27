use std::cell::RefCell;
use std::cmp::Ordering;
use std::collections::HashMap;
use std::rc::{Rc, Weak};

use rand::Rng;

// TODO move these structs to the general AI crate,
// and maybe make a "random" implementation of AI,
// then make MCTS separate

//pub struct MCTSParams<GameState> {
#[derive(Clone)]
pub struct MCTSParams<GameState, GameMove> {
    //get_game_state: fn(GameState) -> String,
    pub get_possible_moves: fn(GameState) -> Vec<GameMove>,
    pub apply_move: fn(GameState, GameMove) -> GameState,
    pub get_score: fn(GameState) -> i32,
    pub init_state: GameState,
}

pub struct MCTSState<GameState, GameMove> {
    params: MCTSParams<GameState, GameMove>,
    current_node: Rc<RefCell<Node<GameState, GameMove>>>,
}

static mut node_count: i64 = 10;

struct Node<GameState, GameMove> {
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
        //println!("[mcts] Read node count {} for new node...", unsafe { node_count });
        let new_node = Node {
            id: unsafe { node_count },
            state: init_state,
            win_count: 0,
            sim_count: 0,
            parent: None,
            children: HashMap::new(),
        };
        let new_node = Rc::new(RefCell::new(new_node));
        unsafe {
            node_count += 1;
        }
        //println!("[mcts] Node count is now {}, returned new node with id {}", unsafe { node_count }, new_node.borrow().id);
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
}

impl<GameState, GameMove> MCTSState<GameState, GameMove>
where
    GameState: Copy + std::fmt::Debug /* TODO remove after debugging */ + std::cmp::PartialEq,
    GameMove: Copy + std::cmp::Eq + std::hash::Hash + std::fmt::Debug + std::clone::Clone,
{
    pub fn init(params: MCTSParams<GameState, GameMove>) -> MCTSState<GameState, GameMove> {
        let mut state = MCTSState::<GameState, GameMove> {
            params: params.clone(),
            current_node: Node::new(params.init_state),
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
                .get_possible_moves(self.current_node.borrow().state)
                .contains(&game_move));
        }

        let new_node = Rc::clone(self.current_node.borrow().children.get(&game_move).unwrap());
        self.current_node = new_node;
    }

    pub fn get_move(&mut self, game_state: GameState) -> Option<GameMove> {
        //println!("get_move");
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
        for _ in 0..100 {
            //println!("expand_tree_once count");
            self.expand_tree_once();
        }
        self.print_node(&self.current_node.borrow(), 0, 0);

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
        return best_move.copied();
    }

    fn get_possible_moves(&self, game_state: GameState) -> Vec<GameMove> {
        return (self.params.get_possible_moves)(game_state);
    }

    fn simulate_node(
        params: MCTSParams<GameState, GameMove>,
        current_node: &Rc<RefCell<Node<GameState, GameMove>>>,
    ) -> i32 {
        let mut rng = rand::thread_rng();

        let mut state = current_node.borrow().state;
        loop {
            let moves = (params.get_possible_moves)(state);
            // TODO: right now a pass is not an option
            // but it should be. Perhaps just hack something in to have get_possible_moves return a pass if
            // there aren't any other moves, so that the game can continue simulating
            // TODO: so then I don't think I strictly need a separate function for "is the game over?",
            // zero possible moves means game over
            if moves.len() == 0 {
                break;
            }
            let game_move = moves[rng.gen_range(0..moves.len())];
            state = (params.apply_move)(state, game_move);
        }
        return (params.get_score)(state);
    }

    fn update_node_counts(
        mut node: Rc<RefCell<Node<GameState, GameMove>>>,
        win_change: i32,
        sim_change: i32,
    ) {
        let max_depth = 1000;
        for _ in 0..max_depth {
            //println!("Incremented node counts by ({}, {})", win_change, sim_change);
            node.borrow_mut().win_count += win_change;
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
        let game_state = node.borrow().state;
        let moves = (params.get_possible_moves)(game_state);

        for game_move in moves.iter() {
            let new_game_state = game_state.clone();
            let new_game_state = (params.apply_move)(new_game_state, *game_move);
            let mut new_node = Node::new(new_game_state);
            //println!("[mcts] Created new node with id {}", new_node.borrow().id);

            //let parent = &mut *node;
            //let parent = node;
            //println!("[mcts] 1/5 Double checking new node id {} ###", new_node.borrow().id);
            let score = MCTSState::simulate_node(params.clone(), &new_node);
            //println!("[mcts] 2/5 Double checking new node id {} ###", new_node.borrow().id);
            let score_inc = if score > 0 { 1 } else { 0 };
            //println!("[mcts] 3/5 Double checking new node id {} ###", new_node.borrow().id);
            new_node.borrow_mut().parent = Some(Rc::downgrade(node));
            //println!("[mcts] 4/5 Double checking new node id {} ###", new_node.borrow().id);
            MCTSState::update_node_counts(Rc::clone(&new_node), score_inc, 1);
            //println!("[mcts] 5/5 Double checking new node id {} ###", new_node.borrow().id);
            //println!("[mcts] to node {}, added child node {}", node.borrow().id, new_node.borrow().id);
            node.borrow_mut().children.insert(*game_move, new_node);
        }
    }

    fn expand_tree_once(&mut self) {
        //println!("[mcts] expand_tree_once");
        //let mut node = &mut self.current_node;
        let mut node = Rc::clone(&self.current_node);
        let mut depth = 0;

        //println!("[mcts] Starting with node {}, (children count: {})", node.borrow().id, node.borrow().children.len());
        for (game_move, child_node) in node.borrow().children.iter() {
            //println!("[mcts]     child: node {}", child_node.borrow().id);
        }
        let max_depth = 10_000;
        for _ in 0..max_depth {
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
            depth += 1;
        }
    }

    fn print_node(
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
            self.print_node(&child.borrow(), node.sim_count, indent_depth + 1);
        }
    }
}
