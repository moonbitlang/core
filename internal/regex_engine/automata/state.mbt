// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
/// A state in the regex automaton representing the current execution status.
///
/// `State` encapsulates all information needed to track the automaton's current
/// position during pattern matching. Each state contains a collection of execution
/// threads (`ThreadSet`) that represent possible matching paths from this point.
///
/// # Fields
///
/// - `slot`: When reaching this state, the current position is stored at this slot
///   (if assigned). Used to track mark positions for capture groups.
/// - `cat`: The category of the current character, used for lookaround assertions
///   (word boundaries, line boundaries, etc.)
/// - `desc`: The collection of execution threads representing all possible paths
///   from this state
/// - `hash`: Cached hash value for efficient state deduplication in the automaton
///
/// # State Lifecycle
///
/// 1. Start with `State::start(cat, expr)` containing initial expression
/// 2. Apply `delta` to compute derivative with respect to input character
/// 3. Check `status()` to see if matching succeeded, failed, or is still running
/// 4. If running, continue with next input character
///
/// # Implementation Note
///
/// Hash is computed eagerly and cached because states are frequently used as
/// hash map keys during automaton construction and execution.
pub struct State {
  priv slot : Slot
  priv cat : @shared_types.Category
  priv desc : ThreadSet
  priv hash : Int
}

///|
pub let st_dummy : State = {
  slot: Slot::unassigned(),
  cat: @shared_types.Category::dummy(),
  desc: ts_empty,
  hash: -1,
}

///|
/// The execution status of a state.
///
/// - `Failed`: No execution threads remain; matching has failed
/// - `Match(MarkSlotMap)`: First thread reached match state with these marks
/// - `Running`: Threads are still executing; need more input
pub enum Status {
  Failed
  Match(MarkSlotMap)
  Running
}

///|
pub impl Eq for State with equal(self, other) {
  self.hash == other.hash &&
  self.slot == other.slot &&
  self.cat == other.cat &&
  self.desc == other.desc
}

///|
pub impl Hash for State with hash_combine(self, hasher) {
  hasher.combine(self.hash)
}

///|
fn State::new(
  slot : Slot,
  cat : @shared_types.Category,
  desc : ThreadSet,
) -> State {
  State::{ slot, cat, desc, hash: (slot, cat, desc).hash() }
}

///|
pub fn State::start(cat : @shared_types.Category, expr : Expr) -> State {
  State::new(Slot::unassigned(), cat, ts_exp(MarkSlotMap::empty(), expr))
}

///|
pub fn State::slot(self : State) -> Slot {
  self.slot
}

///|
pub fn State::status(self : State) -> Status {
  match self.desc.first() {
    None => Failed
    Some(End(marks)) => Match(marks)
    Some(Exp(_) | Seq(_)) => Running
  }
}
