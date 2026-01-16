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
/// Brzozowski derivative computation for the regex automaton.
///
/// This module implements the core derivative operation that powers the automaton.
/// Given a state and an input character, the derivative produces a new state
/// representing what remains to be matched after consuming that character.
///
/// # Key Concept: Derivative
///
/// The derivative of a regular expression r with respect to a character c,
/// written as ∂c(r), is a new expression that matches the remainder of strings
/// that r would match after removing the leading character c.
///
/// For example:
/// - ∂'a'("abc") = "bc"  (if 'a' matches, continue with "bc")
/// - ∂'a'("a*b") = "a*b" (after matching 'a', can match more 'a's then 'b')
///
/// # Implementation Strategy
///
/// Instead of computing derivatives on expressions directly, this implementation:
/// 1. Maintains execution threads representing active matching paths
/// 2. Computes derivatives on threads, which may split into multiple threads
/// 3. Handles preferences (First/Longest/Shortest) to prioritize results
/// 4. Removes duplicate threads to avoid redundant computation
/// 5. Assigns slots to track positions for capture groups
///
/// # Key Functions
///
/// - `delta`: Main entry point - computes derivative of state w.r.t. character
/// - `delta_expr`: Computes derivative of expression, handling all expression types
/// - `delta_threads`: Applies derivative to a collection of threads
/// - `find_slot`: Allocates a slot for the new state to track positions
#warnings("-3")
priv struct Delta {}

///|
#valtype
priv struct DeltaContext {
  c : @shared_types.Rechar
  prev_cat : @shared_types.Category
  next_cat : @shared_types.Category
}

///|
fn delta_rep(
  outer : Expr,
  mode : @shared_types.QuantifierMode,
  pref : @shared_types.Preference,
  inner : Expr,
  c : DeltaContext,
  marks : MarkSlotMap,
) -> ThreadSet {
  let inner_delta = delta_expr(inner, c, marks)
  let first_match_marks = inner_delta.find_first_match()
  match mode {
    Greedy => {
      let (marks, inner_delta) = match first_match_marks {
        None => (marks, inner_delta)
        Some(marks) => (marks, inner_delta.remove_matches())
      }
      ts_seq(pref, inner_delta, outer) + ts_end(marks)
    }
    NonGreedy =>
      ts_end(marks) + ts_seq(pref, inner_delta.remove_matches(), outer)
  }
}

///|
fn delta_expr(expr : Expr, c : DeltaContext, marks : MarkSlotMap) -> ThreadSet {
  match expr.def {
    Chr(cs) => if cs.contains(c.c) { ts_exp(marks, e_eps) } else { ts_empty }
    Alt(exprs) =>
      exprs.fold(init=ts_empty, (acc, expr) => acc + delta_expr(expr, c, marks))
    Seq(pref, first, next) => {
      let first_delta = delta_expr(first, c, marks)
      delta_seq(pref, first_delta, next, c)
    }
    Rep(mode, pref, body) => delta_rep(expr, mode, pref, body, c, marks)
    Eps => ts_end(marks)
    Mark(mark) => ts_end(marks.add_mark(mark))
    Before(cat) =>
      if @shared_types.Category::intersects(c.next_cat, cat) {
        ts_end(marks)
      } else {
        ts_empty
      }
    After(cat) =>
      if @shared_types.Category::intersects(c.prev_cat, cat) {
        ts_end(marks)
      } else {
        ts_empty
      }
  }
}

///|
fn delta_seq(
  pref : @shared_types.Preference,
  first : ThreadSet,
  next : Expr,
  c : DeltaContext,
) -> ThreadSet {
  match first.find_first_match() {
    None => ts_seq(pref, first, next)
    Some(marks) =>
      match pref {
        Longest =>
          ts_seq(pref, first.remove_matches(), next) +
          delta_expr(next, c, marks)
        Shortest =>
          delta_expr(next, c, marks) +
          ts_seq(pref, first.remove_matches(), next)
        First => {
          let (until_first_match, after_first_match) = first.split_at_first_match()
          ts_seq(pref, until_first_match, next) +
          delta_expr(next, c, marks) +
          ts_seq(pref, after_first_match.remove_matches(), next)
        }
      }
  }
}

///|
fn delta_thread(
  thread : Thread,
  c : DeltaContext,
  marks : MarkSlotMap,
) -> ThreadSet {
  match thread {
    End(_) => ts_one(thread)
    Exp(marks, expr) => delta_expr(expr, c, marks)
    Seq(pref, first, next) => {
      let first_delta = delta_threads(first, c, marks)
      delta_seq(pref, first_delta, next, c)
    }
  }
}

///|
fn delta_threads(
  curr : ThreadSet,
  c : DeltaContext,
  marks : MarkSlotMap,
) -> ThreadSet {
  curr.flat_map(thread => delta_thread(thread, c, marks))
}

///|
/// Finds an available slot for the new state to store positions.
///
/// Uses the SlotBook to track which slots are already in use by threads
/// in the descriptor, then finds an unused slot. If no unassigned marks
/// exist in any thread, returns an unassigned slot (no tracking needed).
fn find_slot(ctx~ : Context, desc : ThreadSet) -> Slot {
  if ctx.book_dirty {
    ctx.book.clear()
  }
  let mut has_unassigned_slots = false
  for marks in desc.iter_marks() {
    for _mark, slot in marks {
      if slot.is_assigned() {
        ctx.book.mark_used(slot)
      } else {
        has_unassigned_slots = true
      }
    }
  }
  if !has_unassigned_slots {
    Slot::unassigned()
  } else {
    let slot = ctx.book.find_unused()
    if ctx.book.need_grow(slot) {
      ctx.book = ctx.book.grow()
      ctx.book_dirty = false
    } else {
      ctx.book_dirty = true
    }
    slot
  }
}

///|
/// Computes the derivative of a state with respect to an input character.
///
/// This is the main derivative function that transitions the automaton from
/// one state to the next. It:
/// 1. Applies derivative to all threads in the current state
/// 2. Removes duplicate threads to avoid redundant computation
/// 3. Finds an available slot for position tracking
/// 4. Assigns the slot to all threads (if needed)
/// 5. Returns the new state with updated threads and category
pub fn delta(
  ctx~ : Context,
  state : State,
  c : @shared_types.Rechar,
  next_cat~ : @shared_types.Category,
) -> State {
  let prev_cat = state.cat
  let desc = delta_threads(
    state.desc,
    { prev_cat, next_cat, c },
    MarkSlotMap::empty(),
  )
  let desc = desc.remove_duplicates(e_eps)
  let slot = find_slot(ctx~, desc)
  let desc = if slot.is_assigned() { desc.assign_slot(slot) } else { desc }
  State::new(slot, next_cat, desc)
}
