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

// =====================================================================
// `Tail` — the suspended remainder of a cell: `@lazy.Lazy` plus a
// suspended-append state. Internal; see `types.mbt` for why the append
// state has to live inside the memoized cell rather than wrap one.
// =====================================================================

///|
/// A tail whose value is already known. No thunk is allocated.
#owned(value)
fn[A] Tail::ready(value : LazyList[A]) -> Tail[A] {
  { state: Forced(value), }
}

///|
/// A tail computed by `thunk`, which runs at most once.
#owned(thunk)
fn[A] Tail::delay(thunk : () -> LazyList[A]) -> Tail[A] {
  { state: Unforced(thunk), }
}

///|
/// `self.append(pending)` is the tail denoting `self` followed by every
/// list in `pending`. O(1) — nothing is forced, and the pending lists are
/// recorded as data so that `force` can flatten them iteratively.
///
/// `pending` must be non-empty; callers hand back the tail unchanged
/// rather than wrap it in an append that has nothing to append.
#owned(pending)
fn[A] Tail::append(self : Tail[A], pending : Pending[A]) -> Tail[A] {
  { state: Append(self, pending), }
}

///|
/// The tail's value if it is already known, without running anything.
/// A suspended append reports `None`: its head cell is not determined
/// until the append is flattened.
fn[A] Tail::peek(self : Tail[A]) -> LazyList[A]? {
  match self.state {
    Forced(v) => Some(v)
    _ => None
  }
}

///|
/// Forces the tail to a head cell, memoizing the result. Reentrant
/// forces are detected and aborted, for the reason `@lazy.Lazy::force`
/// gives: the inner force would silently re-run the thunk and break the
/// at-most-once guarantee.
///
/// The `Append` case is the reason this type is not just `@lazy.Lazy`.
/// `Append(inner, ps)` denotes `inner` followed by `ps`, and `inner` may
/// itself be an `Append` — which is exactly the shape a left-nested chain
/// of `concat`s builds. Instead of recursing into `inner`, walk down to
/// the innermost non-append tail while accumulating everything still to
/// be appended, force that single thunk, and re-attach the accumulated
/// appends with `append_pending`. Stack use is therefore constant in the
/// nesting depth.
///
/// Only the entry node is memoized. The intermediate `Append` nodes the
/// walk passes through are left alone (and become garbage unless the
/// caller retained the corresponding lists), which is what keeps a full
/// traversal linear: the collected `Pending` is handed to the *result*
/// cell instead of being re-nested once per level.
fn[A] Tail::force(self : Tail[A]) -> LazyList[A] {
  match self.state {
    Forced(v) => v
    Forcing => abort("LazyList: reentrant force on the same tail")
    Unforced(thunk) => {
      self.state = Forcing
      let v = thunk()
      self.state = Forced(v)
      v
    }
    Append(inner, pending) => {
      self.state = Forcing
      let (base, rest) = for cur = inner, rest = pending {
        match cur.state {
          // `cur` denotes `next` followed by `ps`, and the whole denotes
          // `cur` followed by `rest`, so `ps` goes in front of what we
          // already owe.
          Append(next, ps) => continue next, ps.concat(rest)
          // Not an append, so this force cannot walk any further down.
          _ => break (cur.force(), rest)
        }
      }
      let value = base.append_pending(rest)
      self.state = Forced(value)
      value
    }
  }
}

///|
/// Appends `pending` after the head cell `self`, returning a head cell.
/// Empty segments are skipped in a loop, so a long run of empty lists
/// costs O(1) stack.
fn[A] LazyList::append_pending(
  self : LazyList[A],
  pending : Pending[A],
) -> LazyList[A] {
  for cur = self, rest = pending {
    match cur.cell {
      // A head is available: whatever is still pending moves onto its
      // tail, still suspended.
      Cons(x, tail~) =>
        break if rest is Nil {
          cur
        } else {
          { cell: Cons(x, tail=tail.append(rest)), }
        }
      // This segment contributed no head; move on to the next one.
      Empty =>
        match rest.uncons() {
          None => break cur
          Some((t, more)) => continue t.force(), more
        }
    }
  }
}

///|
/// `self` followed by `other`. O(1): the join is recorded as a `Cat` node
/// and flattened only as `uncons` walks past it.
#owned(other)
fn[A] Pending::concat(self : Pending[A], other : Pending[A]) -> Pending[A] {
  match (self, other) {
    (Nil, _) => other
    (_, Nil) => self
    _ => Cat(self, other)
  }
}

///|
/// Splits off the first pending list, or `None` if there is none.
///
/// Rotates the left spine of the `Cat` tree to the right as it walks, so
/// consuming a pending sequence once — each remainder handed on to the
/// next `uncons` — steps over every `Cat` node at most once, i.e. O(1)
/// amortized per element. The amortization is the usual ephemeral one:
/// re-consuming a retained earlier remainder replays its rotations.
/// Iterative, so an arbitrarily deep tree costs O(1) stack.
fn[A] Pending::uncons(self : Pending[A]) -> (Tail[A], Pending[A])? {
  for cur = self {
    match cur {
      Nil => break None
      One(t) => break Some((t, Nil))
      Cat(One(t), b) => break Some((t, b))
      Cat(Cat(x, y), b) => continue Cat(x, Cat(y, b))
      // Unreachable: neither `Pending::concat` nor the rotation above
      // builds a `Cat` with an empty side. Handled rather than asserted
      // because an empty side means exactly "nothing to append here".
      Cat(Nil, b) => continue b
    }
  }
}
