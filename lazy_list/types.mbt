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
/// Internal cell representation. Kept private so users go through the
/// `head` / `tail` / `iter` accessors and cannot observe (or accidentally
/// force) the underlying `Tail` representation.
priv enum LazyListCell[A] {
  Empty
  Cons(A, tail~ : Tail[A])
}

///|
/// The suspended remainder of a `Cons` cell.
///
/// This is `@lazy.Lazy` — the same states, the same at-most-once
/// guarantee, the same reentrancy check — with one extra state, `Append`.
/// The extra state is what makes `concat` stack-safe, and it has to live
/// *inside* the memoized cell rather than wrap one: `LazyList` allocates a
/// tail per element, so an extra box per cell would be an allocation
/// regression on every traversal, not just on `concat`.
///
/// Why the extra state is needed: over a bare thunk, `concat` can only be
/// written recursively — `xs ++ ys` has to close over a thunk that forces
/// the tail of `xs` and appends `ys` to the *result*, so forcing a
/// left-nested chain `((a ++ b) ++ c) ++ d` recurses once per `++`.
/// `Append` reifies the pending appends as data instead of burying them
/// in a closure, which lets `Tail::force` flatten the chain with a loop.
/// See `Tail::force` and `LazyList::concat`.
priv struct Tail[A] {
  mut state : TailState[A]
}

///|
/// Internal tail state.
///
/// - `Unforced(thunk)`: the ordinary case — the rest of the list is
///   whatever `thunk` returns. It runs at most once.
/// - `Forcing`: `thunk` is running. Detects a reentrant force on the same
///   tail, which would otherwise re-run the thunk and break the
///   at-most-once guarantee. Same rationale as `@lazy.Lazy`'s.
/// - `Append(inner, pending)`: the rest of the list is `inner` followed by
///   every list in `pending`, in order. Built by `concat` / `concat_lazy`,
///   and collapsed to `Forced` by the first `Tail::force`.
/// - `Forced(v)`: already known to be `v`; the thunk reference is dropped
///   so its captures can be reclaimed.
priv enum TailState[A] {
  Unforced(() -> LazyList[A])
  Forcing
  Append(Tail[A], Pending[A])
  Forced(LazyList[A])
}

///|
/// An ordered, immutable sequence of still-suspended lists waiting to be
/// appended. Elements are `Tail`s rather than `LazyList`s so that both
/// `concat` (whose right-hand side is already a head cell) and
/// `concat_lazy` (whose right-hand side is a thunk) can share one
/// representation.
///
/// `Cat` makes joining two of these O(1), which is what keeps the cost of
/// a `concat` independent of how much is already pending: appending to a
/// list that is being consumed at the same time would otherwise copy the
/// whole pending sequence on every step. `Pending::uncons` flattens the
/// `Cat` spine as it walks, in amortized O(1) per element.
///
/// Invariant: `Pending::concat` is the only way a `Cat` is built from the
/// outside, and it never gives one an empty side.
priv enum Pending[A] {
  Nil
  One(Tail[A])
  Cat(Pending[A], Pending[A])
}

///|
/// A persistent linked list with a memoized lazy tail. The head element
/// of each cell is always strict; the tail is computed on first access
/// and cached, so repeated traversals share evaluation work.
///
/// Unlike `Iter[A]`, which is a single-use pull-based iterator, a
/// `LazyList[A]` can be re-traversed any number of times.
///
/// ## Concurrency
///
/// Caching a tail in place is a mutation, so `LazyList[A]` is not
/// thread-safe even though it is persistent. Traversing one from two
/// threads requires external synchronization — the same contract as
/// `@lazy.Lazy`.
struct LazyList[A] {
  cell : LazyListCell[A]
}
