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
priv struct DeltaContext {
  c : @shared_types.Rechar
  prev_cat : @shared_types.Category
  next_cat : @shared_types.Category
  seen : @hashset.HashSet[ExprId]
}

///|
fn append_thread(
  thread : Thread,
  frame : Int,
  frames : Array[(Expr, Int)],
  rem : Array[Thread],
) -> Unit {
  let mut threads = [thread]
  for index = frame; index >= 0; {
    let (next, parent) = frames[index]
    let wrapped = []
    ts_seq(First, threads, next, wrapped)
    threads = wrapped
    continue parent
  }
  rem.append(threads)
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
  delta_thread(Exp(marks, expr), c, rem, false)
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
fn delta_thread(
  thread : Thread,
  c : DeltaContext,
  rem : Array[Thread],
  ordered : Bool,
) -> Unit {
  let frames : Array[(Expr, Int)] = []
  // The frame index names an immutable suffix chain. Derived work has already
  // consumed this character and must be emitted rather than executed again.
  let work : Array[(Thread, Int, Bool, Bool)] = [(thread, -1, false, ordered)]
  while !work.is_empty() {
    let (thread, frame, derived, ordered) = work.unsafe_pop()
    if derived || thread is End(_) {
      match thread {
        End(marks) =>
          if frame < 0 {
            rem.push(thread)
          } else {
            let (next, parent) = frames[frame]
            work.push((Exp(marks, next), parent, false, true))
          }
        _ => append_thread(thread, frame, frames, rem)
      }
      continue
    }
    match thread {
      Seq(First, first, tail) => {
        let index = frames.length()
        frames.push((tail, frame))
        for i = first.0.length() - 1; i >= 0; i = i - 1 {
          work.push((first.0[i], index, false, true))
        }
      }
      Seq(pref, first, tail) => {
        let first_delta = []
        delta_threads(first, c, first_delta)
        let derived = []
        delta_seq(pref, first_delta, tail, c, derived)
        for i = derived.length() - 1; i >= 0; i = i - 1 {
          work.push((derived[i], frame, true, false))
        }
      }
      Exp(marks, expr) =>
        match expr.def {
          Seq(First, first, tail) => {
            let index = frames.length()
            frames.push((tail, frame))
            work.push((Exp(marks, first), index, false, true))
          }
          Eps => work.push((End(marks), frame, true, false))
          _ => {
            let ordered = ordered ||
              expr.def is Rep(_, First, _) ||
              expr.def is RepStart(_)
            if ordered {
              guard c.seen.add_and_check(expr.id) else { continue }
            }
            match expr.def {
              Chr(s) =>
                if s.contains(c.c) {
                  append_thread(Exp(marks, e_eps), frame, frames, rem)
                }
              Alt(exprs) =>
                for i = exprs.length() - 1; i >= 0; i = i - 1 {
                  work.push((Exp(marks, exprs[i]), frame, false, ordered))
                }
              Rep(mode, First, body) | RepStart(mode, body, _, _) => {
                let repeat = match expr.def {
                  RepStart(_, _, repeat, _) => repeat
                  _ => expr
                }
                let required = expr.def is RepStart(_, _, _, true)
                let index = frames.length()
                frames.push((repeat, frame))
                if !required && mode is Greedy {
                  work.push((End(marks), frame, true, false))
                }
                work.push((Exp(marks, body), index, false, true))
                if !required && mode is NonGreedy {
                  work.push((End(marks), frame, true, false))
                }
              }
              Mark(mark) =>
                work.push((End(marks.add_mark(mark)), frame, true, false))
              Before(cat) =>
                if @shared_types.Category::intersects(c.next_cat, cat) {
                  work.push((End(marks), frame, true, false))
                }
              After(cat) =>
                if @shared_types.Category::intersects(c.prev_cat, cat) {
                  work.push((End(marks), frame, true, false))
                }
              Seq(pref, first, tail) => {
                let first_delta = []
                delta_expr(first, c, marks, first_delta)
                let derived = []
                delta_seq(pref, first_delta, tail, c, derived)
                for i = derived.length() - 1; i >= 0; i = i - 1 {
                  work.push((derived[i], frame, true, false))
                }
              }
              Rep(mode, pref, body) => {
                let derived = []
                delta_rep(expr, mode, pref, body, c, marks, derived)
                for i = derived.length() - 1; i >= 0; i = i - 1 {
                  work.push((derived[i], frame, true, false))
                }
              }
              Eps => panic()
            }
          }
        }
      End(_) => panic()
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
    delta_thread(thread, c, rem, true)
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
    if marks.has_unassigned {
      has_unassigned_slots = true
    }
    for slot in marks.slots {
      if slot.is_assigned() {
        ctx.book.mark_used(slot)
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
  ctx.seen.clear()
  delta_threads(state.desc, { prev_cat, next_cat, c, seen: ctx.seen, }, rem)
  ctx.seen.clear()
  remove_duplicates(rem, e_eps, ctx.seen)
  let desc = ThreadSet(rem)
  let slot = find_slot(ctx~, desc)
  if slot.is_assigned() {
    desc.assign_slot_in_place(slot)
  }
  State::new(slot, next_cat, desc)
}
