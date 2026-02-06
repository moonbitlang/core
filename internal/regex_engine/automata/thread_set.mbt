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
/// A collection of execution threads stored in a Treap-based rope structure.
///
/// `ThreadSet` maintains an ordered set of `Thread` instances representing all active
/// execution paths in the automaton. The order matters because it encodes matching
/// priorities - the first thread to reach an `End` state produces the match result.
///
/// # Data Structure
///
/// Uses a Treap (randomized binary search tree) to efficiently:
/// - Maintain thread ordering while allowing efficient insertion/merging
/// - Track metadata (`ThreadSetNodeInfo`) to optimize operations
/// - Support efficient operations like `flat_map`, `merge`, and iteration
///
/// Each node tracks `no_match`: true if no thread in the subtree has reached `End` state.
/// This allows quick pruning of subtrees that cannot contribute to matches.
///
/// # Key Operations
///
/// - `merge`/`+`: Combines two thread sets while preserving order
/// - `flat_map`: Applies a function that may expand each thread to multiple threads
/// - `find_first_match`: Finds the first successful match (if any)
/// - `remove_matches`: Removes all threads in `End` state from the collection
/// - `remove_duplicates`: Eliminates redundant threads with same state
/// - `split_at_first_match`: Separates threads before/after first match
///
/// # Usage in Automaton
///
/// During execution, each `State` contains a `ThreadSet` collection representing all
/// possible execution paths from that state. When computing the derivative with
/// respect to input, threads are transformed and may split into multiple threads.
priv enum ThreadSet {
  Empty
  Node(
    i~ : ThreadSetNodeInfo,
    l~ : ThreadSet,
    t~ : Thread,
    r~ : ThreadSet,
    p~ : Int
  )
}

///|
#valtype
priv struct ThreadSetNodeInfo {
  // No match inside this subtree
  no_match : Bool
}

///|
fn ThreadSet::is_empty(self : ThreadSet) -> Bool {
  self is Empty
}

///|
fn ThreadSet::is_singleton(self : ThreadSet) -> Bool {
  self is Node(l=Empty, r=Empty, ..)
}

///|
fn ThreadSet::first(self : ThreadSet) -> Thread? {
  match self {
    Empty => None
    Node(l=Empty, t~, ..) => Some(t)
    Node(l~, ..) => l.first()
  }
}

///|
fn ThreadSet::choose(self : ThreadSet) -> Thread {
  match self {
    Node(l=Empty, t~, r=Empty, ..) => t
    _ => panic()
  }
}

///|
fn ThreadSet::no_match(self : ThreadSet) -> Bool {
  match self {
    Empty => true
    Node(i~, ..) => i.no_match
  }
}

///|
fn ThreadSet::make_node(
  l : ThreadSet,
  t : Thread,
  r : ThreadSet,
  p~ : Int,
) -> ThreadSet {
  let i = ThreadSetNodeInfo::{
    no_match: !(t is End(_)) && l.no_match() && r.no_match(),
  }
  Node(i~, t~, l~, r~, p~)
}

///|
let rand_state : Ref[Int] = { val: 0 }

///|
fn rand_int() -> Int {
  rand_state.val = rand_state.val * 1664525 + 1013904223
  rand_state.val
}

///|
fn ThreadSet::singleton(t : Thread) -> ThreadSet {
  ThreadSet::make_node(Empty, t, Empty, p=rand_int())
}

///|
fn ThreadSet::merge(l : ThreadSet, r : ThreadSet) -> ThreadSet {
  match (l, r) {
    (Empty, r) => r
    (l, Empty) => l
    (Node(..) as l, Node(..) as r) =>
      if l.p > r.p {
        ThreadSet::make_node(l.l, l.t, ThreadSet::merge(l.r, r), p=l.p)
      } else {
        ThreadSet::make_node(ThreadSet::merge(l, r.l), r.t, r.r, p=r.p)
      }
  }
}

///|
impl Add for ThreadSet with add(self, other) {
  ThreadSet::merge(self, other)
}

///|
fn ThreadSet::flat_map(
  self : ThreadSet,
  f : (Thread) -> ThreadSet,
) -> ThreadSet {
  match self {
    Empty => Empty
    Node(l~, t~, r~, ..) => {
      let l2 = l.flat_map(f)
      let t2 = f(t)
      let r2 = r.flat_map(f)
      l2 + t2 + r2
    }
  }
}

///|
fn ThreadSet::find_first_match(self : ThreadSet) -> MarkSlotMap? {
  match self {
    Empty => None
    Node(i={ no_match: true }, ..) => None
    Node(l=Empty, t=End(marks), ..) => Some(marks)
    Node(l~, t~, r~, ..) =>
      match l.find_first_match() {
        Some(marks) => Some(marks)
        None =>
          match t {
            End(marks) => Some(marks)
            Exp(_) | Seq(_) => r.find_first_match()
          }
      }
  }
}

///|
fn ThreadSet::remove_matches(self : ThreadSet) -> ThreadSet {
  match self {
    Empty => Empty
    Node(i={ no_match: true }, ..) => self
    Node(l~, t~, r~, p~, ..) =>
      match t {
        End(_) => l.remove_matches() + r.remove_matches()
        Exp(_) | Seq(_) =>
          ThreadSet::make_node(l.remove_matches(), t, r.remove_matches(), p~)
      }
  }
}

///|
fn ThreadSet::split_at_first_match(self : ThreadSet) -> (ThreadSet, ThreadSet) {
  match self {
    Empty => (Empty, Empty)
    Node(i={ no_match: true }, ..) => (self, Empty)
    Node(l=Empty | Node(i={ no_match: true }, ..) as l, t=End(_), r~, ..) =>
      (l, r)
    Node(
      l=Empty
      | Node(i={ no_match: true }, ..) as l,
      t=Exp(_)
      | Seq(_) as t,
      r~,
      p~,
      ..
    ) => {
      let (r1, r2) = r.split_at_first_match()
      (ThreadSet::make_node(l, t, r1, p~), r2)
    }
    Node(l=Node(i={ no_match: false }, ..) as l, t~, r~, p~, ..) => {
      let (l1, l2) = l.split_at_first_match()
      (l1, ThreadSet::make_node(l2, t, r, p~))
    }
  }
}

///|
fn ThreadSet::remove_duplicates(self : ThreadSet, next : Expr) -> ThreadSet {
  let seen = @hashset.HashSet::new()
  let mut result = ts_empty
  for thread in self {
    match thread {
      End(_) => {
        result += ts_one(thread)
        break
      }
      Exp(marks, { def: Eps, .. }) =>
        if !seen.contains(next.id) {
          seen.add(next.id)
          result += ts_exp(marks, next)
        }
      Exp(_, { id, .. }) =>
        if !seen.contains(id) {
          seen.add(id)
          result += ts_one(thread)
        }
      Seq(pref, first, next) => {
        let first_dedup = first.remove_duplicates(next)
        result += ts_seq(pref, first_dedup, next)
      }
    }
  }
  result
}

///|
fn ThreadSet::assign_slot(desc : ThreadSet, slot : Slot) -> ThreadSet {
  guard slot.is_assigned() else { panic() }
  desc.map(thread => {
    match thread {
      End(marks) => End(marks.assign_slot(slot))
      Exp(marks, expr) => Exp(marks.assign_slot(slot), expr)
      Seq(pref, first, next) => Seq(pref, first.assign_slot(slot), next)
    }
  })
}

///|
fn ThreadSet::iter(self : ThreadSet) -> Iter[Thread] {
  let mut node = self
  let parents = []
  Iter::new(() => {
    loop node {
      Node(t=thread, l=Empty, r=right, ..) => {
        node = right
        Some(thread)
      }
      Node(t=thread, l=left, r=right, ..) => {
        parents.push((thread, right))
        continue left
      }
      Empty if parents.pop() is Some((thread, right)) => {
        node = right
        Some(thread)
      }
      Empty => None
    }
  })
}

///|
fn ThreadSet::iter_marks(self : ThreadSet) -> Iter[MarkSlotMap] {
  self
  .iter()
  .flat_map(thread => {
    match thread {
      End(marks) | Exp(marks, _) => Iter::singleton(marks)
      Seq(_pref, first, _next) => first.iter_marks()
    }
  })
}

///|
fn ThreadSet::map(self : ThreadSet, f : (Thread) -> Thread) -> ThreadSet {
  match self {
    Empty => Empty
    Node(l~, t~, r~, p~, ..) => {
      let l2 = l.map(f)
      let b2 = f(t)
      let r2 = r.map(f)
      ThreadSet::make_node(l2, b2, r2, p~)
    }
  }
}

///|
let ts_empty : ThreadSet = Empty

///|
fn ts_one(t : Thread) -> ThreadSet {
  ThreadSet::singleton(t)
}

///|
fn ts_end(marks : MarkSlotMap) -> ThreadSet {
  ts_one(End(marks))
}

///|
fn ts_exp(marks : MarkSlotMap, expr : Expr) -> ThreadSet {
  ts_one(Exp(marks, expr))
}

///|
fn ts_seq(
  pref : @shared_types.Preference,
  first : ThreadSet,
  next : Expr,
) -> ThreadSet {
  if first.is_empty() {
    ts_empty
  } else if first.is_singleton() &&
    first.choose() is Exp(marks, { def: Eps, .. }) {
    ts_exp(marks, next)
  } else {
    ts_one(Seq(pref, first, next))
  }
}

///|
impl Eq for ThreadSet with equal(self, other) {
  let it1 = self.iter()
  let it2 = other.iter()
  loop (it1.next(), it2.next()) {
    (None, None) => true
    (None, Some(_)) | (Some(_), None) => false
    (Some(b1), Some(b2)) =>
      if b1 == b2 {
        continue (it1.next(), it2.next())
      } else {
        false
      }
  }
}

///|
impl Hash for ThreadSet with hash_combine(self, hasher) {
  for thread in self {
    hasher.combine(thread)
  }
}
