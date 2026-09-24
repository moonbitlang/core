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

///|
#valtype
priv struct DeltaContext {
  c : @shared_types.Rechar
  prev_cat : @shared_types.Category
  next_cat : @shared_types.Category
}

///|
/// Every `delta_*` producer appends the threads it derives to `rem`, in
/// priority order, instead of returning a set; concatenation is then free
/// and nested sets are only allocated where a `Seq` thread needs one.
fn delta_rep(
  outer : Expr,
  mode : @shared_types.QuantifierMode,
  pref : @shared_types.Preference,
  inner : Expr,
  c : DeltaContext,
  marks : MarkSlotMap,
  rem : Array[Thread],
) -> Unit {
  let inner_delta = []
  delta_expr(inner, c, marks, inner_delta)
  let marks_after = match first_match(inner_delta) {
    None => marks
    Some(marks) => {
      remove_matches(inner_delta)
      marks
    }
  }
  match mode {
    Greedy => {
      ts_seq(pref, inner_delta, outer, rem)
      rem.push(End(marks_after))
    }
    NonGreedy => {
      rem.push(End(marks))
      ts_seq(pref, inner_delta, outer, rem)
    }
  }
}

///|
fn delta_expr(
  expr : Expr,
  c : DeltaContext,
  marks : MarkSlotMap,
  rem : Array[Thread],
) -> Unit {
  match expr.def {
    Chr(cs) => if cs.contains(c.c) { rem.push(Exp(marks, e_eps)) }
    Alt(exprs) =>
      for expr in exprs {
        delta_expr(expr, c, marks, rem)
      }
    Seq(pref, first, next) => {
      let first_delta = []
      delta_expr(first, c, marks, first_delta)
      delta_seq(pref, first_delta, next, c, rem)
    }
    Rep(mode, pref, body) => delta_rep(expr, mode, pref, body, c, marks, rem)
    Eps => rem.push(End(marks))
    Mark(mark) => rem.push(End(marks.add_mark(mark)))
    Before(cat) =>
      if @shared_types.Category::intersects(c.next_cat, cat) {
        rem.push(End(marks))
      }
    After(cat) =>
      if @shared_types.Category::intersects(c.prev_cat, cat) {
        rem.push(End(marks))
      }
  }
}

///|
fn delta_seq(
  pref : @shared_types.Preference,
  first : Array[Thread],
  next : Expr,
  c : DeltaContext,
  rem : Array[Thread],
) -> Unit {
  match first_match(first) {
    None => ts_seq(pref, first, next, rem)
    Some(marks) =>
      match pref {
        Longest => {
          remove_matches(first)
          ts_seq(pref, first, next, rem)
          delta_expr(next, c, marks, rem)
        }
        Shortest => {
          delta_expr(next, c, marks, rem)
          remove_matches(first)
          ts_seq(pref, first, next, rem)
        }
        First => {
          let after_first_match = split_at_first_match(first)
          ts_seq(pref, first, next, rem)
          delta_expr(next, c, marks, rem)
          ts_seq(pref, after_first_match, next, rem)
        }
      }
  }
}

///|
fn delta_thread(thread : Thread, c : DeltaContext, rem : Array[Thread]) -> Unit {
  match thread {
    End(_) => rem.push(thread)
    Exp(marks, expr) => delta_expr(expr, c, marks, rem)
    Seq(pref, first, next) => {
      let first_delta = []
      delta_threads(first, c, first_delta)
      delta_seq(pref, first_delta, next, c, rem)
    }
  }
}

///|
fn delta_threads(
  curr : ThreadSet,
  c : DeltaContext,
  rem : Array[Thread],
) -> Unit {
  for thread in curr.0 {
    delta_thread(thread, c, rem)
  }
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
  desc.each_marks(marks => {
    for _mark, slot in marks {
      if slot.is_assigned() {
        ctx.book.mark_used(slot)
      } else {
        has_unassigned_slots = true
      }
    }
  })
  // The loop above may have marked slots even when nothing needs one, so the
  // book must be cleared before its next use either way.
  ctx.book_dirty = true
  if !has_unassigned_slots {
    Slot::unassigned()
  } else {
    let slot = ctx.book.find_unused()
    if ctx.book.need_grow(slot) {
      ctx.book = ctx.book.grow()
      ctx.book_dirty = false
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
  let rem = []
  delta_threads(state.desc, { prev_cat, next_cat, c, }, rem)
  ctx.seen.clear()
  remove_duplicates(rem, e_eps, ctx.seen)
  let desc = ThreadSet(rem)
  let slot = find_slot(ctx~, desc)
  if slot.is_assigned() {
    desc.assign_slot_in_place(slot)
  }
  State::new(slot, next_cat, desc)
}
