use libc::c_void;

use crate::rust_game_api::CCallbacksPtr;

use crate::libs::ai::mcts;

use std::ptr;
use std::rc::Rc;

//type GameState = [u8];
//type GameMove = [u8];

type GameState = Vec<u8>;
type GameMove = Vec<u8>;

//type GameState = Rc<Vec<u8>>;
//type GameMove = Rc<Vec<u8>>;

//#[derive(Clone)]
//struct CopyableVec(Vec<u8>);
/*
impl Clone for CopyableVec {
    fn clone(&self) -> Self {
        CopyableVec(self.0.clone())
    }
}
*/

/*
impl CopyableVec {
    pub fn new(data: Vec<u8>) -> CopyableVec {

    }
    pub fn len(&self) -> usize {
        self.0.len()
    }

    pub fn as_ptr(&self) -> *const u8 {
        self.0.as_ptr()
    }
}
*/

//type GameState = CopyableVec;
//type GameMove = CopyableVec;

// Passed from C to initialize the MCTS library.
// See struct rust_ai_init_params in game_api_ai.h
#[derive(Clone)]
#[repr(C)]
pub struct AiInitParamsCStruct {
    callbacks: *const CCallbacksPtr,

    // TODO convert to reference?
    callback_handle: *mut c_void,

    get_possible_moves: Option<
        unsafe extern "C" fn(
            *mut c_void,
            *const u8,
            usize,
            *mut u8,
            usize,
            move_len_out: *mut usize,
        ) -> usize,
    >,
    get_player_turn: Option<unsafe extern "C" fn(*mut c_void, *const u8, usize) -> i32>,
    apply_move: Option<
        unsafe extern "C" fn(
            *mut c_void,
            *const u8,
            usize,
            *const u8,
            usize,
            *mut u8,
            usize,
        ) -> usize,
    >,
    get_score: Option<unsafe extern "C" fn(*mut c_void, *const u8, usize, i32) -> i32>,
}

impl mcts::MCTSGameFuncs<'_, GameState, GameMove> for AiInitParamsCStruct {
    //impl mcts::MCTSGameFuncs<GameState<'_>, GameMove<'_>> for AiInitParamsCStruct {
    //fn get_possible_moves<'a>(&'a self, game_state: GameState) -> Vec<GameMove<'a>> {
    fn get_possible_moves(&self, game_state: &GameState) -> Vec<GameMove> {
        //fn get_possible_moves<'a, 'b, 'c>(&'a self, game_state: &'b [u8]) -> Vec<&'b [u8]> {
        const MAX_GAME_MOVES_LEN: usize = 1024;
        if let Some(get_possible_moves) = self.get_possible_moves {
            let mut game_moves_buff = vec![0; MAX_GAME_MOVES_LEN];
            let mut game_moves_len: usize = 0;
            let game_state_len = game_state.len();
            let moves_ary_len = unsafe {
                (get_possible_moves)(
                    self.callback_handle,
                    game_state.as_ptr(),
                    game_state_len,
                    game_moves_buff.as_mut_ptr(),
                    MAX_GAME_MOVES_LEN,
                    &mut game_moves_len as *mut usize,
                )
            };

            game_moves_buff.truncate(moves_ary_len);

            if game_moves_buff.len() == 0 {
                println!("Received 0 bytes from Lua, returning empty vector");
                return vec![];
            }

            //return game_moves_buff.chunks(game_moves_len).collect();
            let moves = game_moves_buff
                .chunks(game_moves_len)
                .map(|chunk| chunk.to_vec())
                //.map(|chunk| CopyableVec::new(chunk.to_vec()))
                .collect::<Vec<Vec<u8>>>();
            //.collect();

            println!("Received moves {:?} from Lua", moves);

            return moves;
        } else {
            panic!("get_possible_moves is null");
        }
    }

    fn get_player_turn(&self, state: &GameState) -> mcts::PlayerId {
        if let Some(get_player_turn) = self.get_player_turn {
            let state_len = state.len();
            unsafe { (get_player_turn)(self.callback_handle, state.as_ptr(), state_len) }
        } else {
            panic!("get_player_turn is null");
        }
    }

    fn apply_move(&self, state: &GameState, game_move: GameMove) -> GameState {
        const MAX_GAME_STATE_OUT_LEN: usize = 1024;

        if let Some(apply_move) = self.apply_move {
            let state_len = state.len();
            let game_move_len = game_move.len();
            let mut state_out_buff = vec![0; MAX_GAME_STATE_OUT_LEN];

            let state_out_len = unsafe {
                (apply_move)(
                    self.callback_handle,
                    state.as_ptr(),
                    state_len,
                    game_move.as_ptr(),
                    game_move_len,
                    state_out_buff.as_mut_ptr(),
                    MAX_GAME_STATE_OUT_LEN,
                )
            };

            state_out_buff.truncate(state_out_len);

            state_out_buff
        } else {
            panic!("apply_move is null");
        }
    }
    fn get_score(&self, state: &GameState, player: mcts::PlayerId) -> i32 {
        if let Some(get_score) = self.get_score {
            let state_len = state.len();
            unsafe { (get_score)(self.callback_handle, state.as_ptr(), state_len, player) }
        } else {
            panic!("get_score is null");
        }
    }
}

#[no_mangle]
pub extern "C" fn rust_game_api_ai_init(
    params: *const AiInitParamsCStruct,
    state: *const u8,
    state_len: usize,
) -> *mut c_void {
    println!("from rust: rust_game_api_ai_init called");
    let params = unsafe { &(*params) };

    // TODO game state and moves will be &[u8] (slice)
    let state = unsafe { std::slice::from_raw_parts(state, state_len) }.to_vec();
    //let state = Rc::new(state);

    let mcts_state = mcts::MCTSState::init(mcts::MCTSParams {
        get_time_ms: None, // TODO part of default
        //get_time_ms: Some(|callbacks| callbacks.get_time_ms() as i32),
        callbacks: unsafe { &(*params.callbacks) },

        // TODO not used anymore, now the client manually calls the expansion function
        expansion_count: 10_000,
        //expansion_count: 100_000,
        //expansion_count: 1_000_000,
        game_funcs: Rc::new(params.clone()),

        init_state: state,
        /*
                // TODO need to init ai_state when we get init game state, not here
                init_state: state,
                get_possible_moves: |game_state| {
                    params.get_possible_moves(game_state)
                },
                get_player_turn: |game_state| {
                    params.get_player_turn(game_state)
                },
                apply_move: |game_state, game_move| {
                    params.apply_move(game_state, game_move)
                },
                get_score: |game_state, player| {
                    params.get_score(game_state, player)
                },
                */
        /*
                get_possible_moves: |game_state| vec![],
                get_player_turn: |game_state| 0,
                apply_move: |game_state, game_move| {
                    //Rc::new(vec![])
                    vec![]
                },
                get_score: |game_state, player| 0,
        */
    });

    let mcts_state = Box::new(mcts_state);
    Box::into_raw(mcts_state) as *mut c_void
}

#[no_mangle]
pub extern "C" fn rust_game_api_ai_destroy(handle: *mut c_void) {
    unsafe {
        let _ = Box::from_raw(handle);
    }
}

fn handle_ptr_to_ref(handle: *mut c_void) -> &'static mut mcts::MCTSState<GameState, GameMove> {
    let handle = handle as *mut mcts::MCTSState<GameState, GameMove>;
    let handle = unsafe { handle.as_mut().expect("handle null?") };
    handle
}

fn state_ptr_to_ref(state: *const u8, state_len: usize) -> GameState {
    let state = unsafe { std::slice::from_raw_parts(state, state_len) };
    let state = state.to_vec();
    state
}

fn game_move_ptr_to_ref(game_move: *const u8, game_move_len: usize) -> GameMove {
    let game_move = unsafe { std::slice::from_raw_parts(game_move, game_move_len) };
    let game_move = game_move.to_vec();
    game_move
}

#[no_mangle]
pub extern "C" fn rust_game_api_ai_expand_tree(handle: *mut c_void, count: i32) {
    let mut handle = handle_ptr_to_ref(handle);

    for _ in 0..count {
        handle.expand_tree_once();
    }
}

#[no_mangle]
pub extern "C" fn rust_game_api_ai_get_move(
    handle: *mut c_void,
    state: *const u8,
    state_len: usize,
    move_out: *mut u8,
    max_move_out_len: usize,
) -> usize {
    let mut handle = handle_ptr_to_ref(handle);
    let state = state_ptr_to_ref(state, state_len);

    // TODO why is this mutable?
    let game_move = handle.get_move(state);
    // TODO write game_move ptr to `move_out` up to max_move_out_len, return length

    let game_move = game_move.expect("AI game move is null?");

    if game_move.len() >= max_move_out_len {
        panic!("rust_game_api_ai_get_move: game_move.len() >= max_move_out_len");
    }

    unsafe {
        ptr::copy_nonoverlapping(game_move.as_ptr(), move_out, max_move_out_len);
    }

    game_move.len()
}

#[no_mangle]
pub extern "C" fn rust_game_api_ai_get_move_score(
    handle: *mut c_void,
    game_move: *const u8,
    game_move_len: usize,
) -> f64 {
    // TODO
    let mut handle = handle_ptr_to_ref(handle);
    let game_move = game_move_ptr_to_ref(game_move, game_move_len);
    handle.get_move_score(game_move)
}

#[no_mangle]
pub extern "C" fn rust_game_api_ai_move_node(
    handle: *mut c_void,
    state: *const u8,
    state_len: usize,
    game_move: *const u8,
    game_move_len: usize,
) {
    let mut handle = handle_ptr_to_ref(handle);
    let state = game_move_ptr_to_ref(state, state_len);
    let game_move = game_move_ptr_to_ref(game_move, game_move_len);
    handle.move_node(state, game_move)
}
