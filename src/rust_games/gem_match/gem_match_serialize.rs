use crate::gem_match::gem_match_core::State;

use bincode;

pub const VERSION: u8 = 1;

pub enum Error {
    UnhandledVersion(u8),
    SerdeError(bincode::Error),
}

pub fn serialize(state: State) -> Result<Vec<u8>, bincode::Error> {
    let mut serialized_state = match bincode::serialize(&state) {
        Ok(state_encoded) => state_encoded,
        Err(e) => {
            return Err(e);
        }
    };

    serialized_state.insert(0, VERSION);

    return Ok(serialized_state);
}

pub fn deserialize(serialized_state: &Vec<u8>) -> Result<State, Error> {
    let mut serialized_state = serialized_state.clone();
    let version = serialized_state.remove(0);

    if version != VERSION {
        return Err(Error::UnhandledVersion(version));
    }

    let deserialize_result = bincode::deserialize::<State>(&serialized_state);
    match deserialize_result {
        Ok(state) => {
            return Ok(state);
        }
        Err(bincode) => {
            return Err(Error::SerdeError(bincode));
        }
    }
}
