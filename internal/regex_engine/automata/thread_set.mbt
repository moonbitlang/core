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
/// The ordered collection of execution threads of a state.
///
/// Threads are kept in an array in priority order: the first thread to reach
/// `End` wins, so producers append in the order the semantics dictate and
/// nothing ever inserts in the middle. Sets are built append-only through an
/// accumulator (`rem` in `delta_*`, the same shape as ocaml-re's list
/// accumulator), scanned a few times while the new state is finalized, and
/// then frozen inside a `State`.
///
/// Ownership: every array reachable from a set under construction was
/// allocated by the current `delta` call (producers build new arrays for
/// nested `Seq` threads and `remove_duplicates` rebuilds every level), so
/// `assign_slot_in_place` may mutate them. Once a set is stored in a
/// `State` it is never mutated again.
priv struct ThreadSet(Array[Thread])

///|
impl Eq for ThreadSet with fn equal(self, other) {
  self.0 == other.0
}

///|
impl Hash for ThreadSet with fn hash_combine(self, hasher) {
  for thread in self.0 {
    hasher.combine(thread)
  }
}

///|
let ts_empty : ThreadSet = ThreadSet([])

///|
fn ThreadSet::first(self : ThreadSet) -> Thread? {
  self.0.get(0)
}

///|
/// Marks of the first `End` thread, if any (nested `Seq` threads never
/// contain `End`: their matches were consumed by `delta_seq`).
fn first_match(threads : Array[Thread]) -> MarkSlotMap? {
  for thread in threads {
    if thread is End(marks) {
      return Some(marks)
    }
  }
  None
}

///|
/// Drop every `End` thread, in place (the array is owned by this delta).
fn remove_matches(threads : Array[Thread]) -> Unit {
  threads.retain(thread => !(thread is End(_)))
}

///|
/// Shrink an owned array to its first `len` elements.
fn truncate(threads : Array[Thread], len : Int) -> Unit {
  while threads.length() > len {
    threads.unsafe_pop() |> ignore
  }
}

///|
/// Split at the first `End`: `threads` keeps what came before it, and the
/// threads after it (with any further `End` removed) are returned. The
/// caller has checked an `End` exists.
fn split_at_first_match(threads : Array[Thread]) -> Array[Thread] {
  for i, thread in threads {
    if thread is End(_) {
      let after = threads.drain(i + 1, threads.length())
      threads.unsafe_pop() |> ignore
      remove_matches(after)
      return after
    }
  }
  panic()
}

///|
/// Append a `Seq` thread for `first` followed by `next`, collapsing the two
/// shapes that must not become a `Seq`: an empty `first` (nothing to run) and
/// a single finished thread (which is exactly a thread sitting at `next`).
fn ts_seq(
  pref : @shared_types.Preference,
  first : Array[Thread],
  next : Expr,
  rem : Array[Thread],
) -> Unit {
  match first {
    [] => ()
    [Exp(marks, { def: Eps, .. })] => rem.push(Exp(marks, next))
    _ => rem.push(Seq(pref, ThreadSet(first), next))
  }
}

///|
/// Drops threads that cannot contribute anything an earlier thread does not
/// already cover: two threads with the same future differ only in priority,
/// so the later one can go. Everything after the first `End` at a level is
/// dropped too, since that match has the highest remaining priority. Works
/// in place: every array in the set is owned by the current delta.
///
/// Threads in `threads` all continue with `next` once they finish, which is
/// what makes a thread that has *already* finished — one sitting at `Eps` —
/// equivalent to a thread sitting at `next` itself. Both are keyed by
/// `next.id` so that the pair collapses to one; without that, a sequence
/// whose first part can both finish and continue doubles its thread set on
/// every character.
///
/// The equivalence is used as a dedup key only. Rewriting the finished
/// thread to `Exp(marks, next)` would *look* like the same statement, but
/// the caller wraps the result in `ts_seq(.., next)`, which appends `next`
/// again — so the continuation would be matched twice over. Keeping the
/// thread at `Eps` also leaves `ts_seq` able to collapse a sequence whose
/// first part has come down to a single finished thread.
///
/// One `seen` set is shared across the whole nested thread tree. Equivalent
/// futures can occur under different `Seq` wrappers when a repeated body
/// consumes a variable number of characters; limiting deduplication to each
/// wrapper separately retains one thread per partition of the input and
/// makes the set grow exponentially.
fn remove_duplicates(
  threads : Array[Thread],
  next : Expr,
  seen : @hashset.HashSet[ExprId],
) -> Unit {
  let mut w = 0
  for thread in threads {
    match thread {
      End(_) => {
        threads[w] = thread
        w += 1
        break
      }
      Exp(_, { def: Eps, .. }) =>
        if seen.add_and_check(next.id) {
          threads[w] = thread
          w += 1
        }
      Exp(_, { id, .. }) =>
        if seen.add_and_check(id) {
          threads[w] = thread
          w += 1
        }
      Seq(_, first, next2) => {
        remove_duplicates(first.0, next2, seen)
        // Same collapse rules as `ts_seq`, applied to the surviving threads.
        match first.0 {
          [] => ()
          [Exp(marks, { def: Eps, .. })] => {
            threads[w] = Exp(marks, next2)
            w += 1
          }
          _ => {
            threads[w] = thread
            w += 1
          }
        }
      }
    }
  }
  truncate(threads, w)
}

///|
/// Give every unassigned mark in the set the state's slot. Mutates the
/// arrays in place; see the ownership note on `ThreadSet`.
fn ThreadSet::assign_slot_in_place(self : ThreadSet, slot : Slot) -> Unit {
  guard slot.is_assigned() else { panic() }
  for i, thread in self.0 {
    match thread {
      End(marks) => self.0[i] = End(marks.assign_slot(slot))
      Exp(marks, expr) => self.0[i] = Exp(marks.assign_slot(slot), expr)
      Seq(_, first, _) => first.assign_slot_in_place(slot)
    }
  }
}

///|
/// Visit the marks of every thread, including those nested in `Seq` threads.
fn ThreadSet::each_marks(self : ThreadSet, f : (MarkSlotMap) -> Unit) -> Unit {
  for thread in self.0 {
    match thread {
      End(marks) | Exp(marks, _) => f(marks)
      Seq(_, first, _) => first.each_marks(f)
    }
  }
}
