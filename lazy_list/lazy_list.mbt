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
// Internal helpers (not exported).
// =====================================================================

///|
/// Strict-tail cons. Private — exposed indirectly through `lazy_cons`
/// and as the building block for the transform combinators.
fn[A] cons(head : A, tail : LazyList[A]) -> LazyList[A] {
  { cell: Cons(head, tail=@lazy.Lazy::ready(tail)) }
}

// =====================================================================
// Constructors.
// =====================================================================

///|
/// Creates an empty lazy list.
///
/// # Example
///
/// ```mbt check
/// test {
///   let xs : @lazy_list.LazyList[Int] = @lazy_list.empty()
///   inspect(xs.is_empty(), content="true")
/// }
/// ```
#as_free_fn
pub fn[A] LazyList::empty() -> LazyList[A] {
  { cell: Empty }
}

///|
/// Prepends an element with a lazy, memoized tail. This is the primary
/// builder for streams whose continuation should not be evaluated until
/// it is observed. The tail thunk is invoked at most once.
///
/// # Example
///
/// ```mbt check
/// test {
///   fn nat_from(n : Int) -> @lazy_list.LazyList[Int] {
///     @lazy_list.lazy_cons(n, () => nat_from(n + 1))
///   }
///   let xs = nat_from(0).take(4).to_array()
///   debug_inspect(xs, content="[0, 1, 2, 3]")
/// }
/// ```
#as_free_fn
pub fn[A] LazyList::lazy_cons(
  head : A,
  tail : () -> LazyList[A],
) -> LazyList[A] {
  { cell: Cons(head, tail=@lazy.Lazy(tail)) }
}

///|
/// Builds a lazy list from a pull-based `Iter`. Each tail forces a single
/// `iter.next()` call and memoizes the result, so re-traversing the
/// returned `LazyList` does not re-pull from the underlying iterator.
///
/// This is the canonical way to wrap any source (an array, a strict
/// list, a generator) into a re-traversable lazy list:
///
/// ```mbt check
/// test {
///   let xs = @lazy_list.from_iter([1, 2, 3].iter())
///   debug_inspect(xs.to_array(), content="[1, 2, 3]")
///   // The lazy list is re-traversable.
///   debug_inspect(xs.to_array(), content="[1, 2, 3]")
/// }
/// ```
#as_free_fn
pub fn[A] LazyList::from_iter(iter : Iter[A]) -> LazyList[A] {
  match iter.next() {
    None => LazyList::empty()
    Some(x) => LazyList::lazy_cons(x, () => LazyList::from_iter(iter))
  }
}

// =====================================================================
// Queries.
// =====================================================================

///|
/// Returns `true` for an empty lazy list. This check is O(1) and forces
/// nothing — the head cell is always known.
pub fn[A] LazyList::is_empty(self : LazyList[A]) -> Bool {
  self.cell is Empty
}

///|
/// Returns the head element if any. Does not force the tail.
pub fn[A] LazyList::head(self : LazyList[A]) -> A? {
  match self.cell {
    Empty => None
    Cons(x, ..) => Some(x)
  }
}

///|
/// Returns the tail (forcing one cell) if the list is non-empty.
pub fn[A] LazyList::tail(self : LazyList[A]) -> LazyList[A]? {
  match self.cell {
    Empty => None
    Cons(_, tail~) => Some(tail.force())
  }
}

// =====================================================================
// Lazy transformations.
// =====================================================================

///|
/// Maps `f` over every element. The head element of each output cell is
/// produced eagerly when that cell is forced (matching the head-strict /
/// tail-lazy semantics of `LazyList`); the next cell is produced only
/// when its tail is in turn forced.
pub fn[A, B] LazyList::map(self : LazyList[A], f : (A) -> B) -> LazyList[B] {
  match self.cell {
    Empty => LazyList::empty()
    Cons(x, tail~) => LazyList::lazy_cons(f(x), () => tail.force().map(f))
  }
}

///|
/// Lazily keeps elements that satisfy `pred`. Skipping non-matching
/// elements forces the source up to the next match (or to the end).
pub fn[A] LazyList::filter(
  self : LazyList[A],
  pred : (A) -> Bool,
) -> LazyList[A] {
  let mut cur = self
  while cur.cell is Cons(x, tail~) {
    if pred(x) {
      let t = tail
      return LazyList::lazy_cons(x, () => t.force().filter(pred))
    }
    cur = tail.force()
  }
  LazyList::empty()
}

///|
/// Returns the first `n` elements as a lazy list. If `n <= 0`, returns
/// the empty list. Safe to call on infinite lists. Forces exactly the
/// cells of the prefix — no look-ahead.
pub fn[A] LazyList::take(self : LazyList[A], n : Int) -> LazyList[A] {
  if n <= 0 {
    return LazyList::empty()
  }
  match self.cell {
    Empty => LazyList::empty()
    Cons(x, tail~) =>
      if n == 1 {
        cons(x, LazyList::empty())
      } else {
        LazyList::lazy_cons(x, () => tail.force().take(n - 1))
      }
  }
}

///|
/// Drops the first `n` elements. Forces up to `n` cells of the source.
pub fn[A] LazyList::drop(self : LazyList[A], n : Int) -> LazyList[A] {
  let mut cur = self
  let mut k = n
  while k > 0 && cur.cell is Cons(_, tail~) {
    cur = tail.force()
    k -= 1
  }
  cur
}

///|
/// Yields elements while `pred` holds, then stops. Forces source cells
/// up to and including the first failing element.
pub fn[A] LazyList::take_while(
  self : LazyList[A],
  pred : (A) -> Bool,
) -> LazyList[A] {
  match self.cell {
    Empty => LazyList::empty()
    Cons(x, tail~) =>
      if pred(x) {
        LazyList::lazy_cons(x, () => tail.force().take_while(pred))
      } else {
        LazyList::empty()
      }
  }
}

///|
/// Skips elements while `pred` holds, returning the rest. `pred` is
/// called eagerly during the skip; a raising `pred` propagates here.
///
/// (Contrast with `map` / `filter` / `take_while` / `flat_map`, whose
/// callbacks also run inside lazy thunks. `@lazy.Lazy` thunks are
/// non-raising by design — see `@lazy`'s rationale — so those
/// combinators cannot accept a raising callback. `drop_while` only runs
/// `pred` during the strict skip phase, so it can.)
pub fn[A] LazyList::drop_while(
  self : LazyList[A],
  pred : (A) -> Bool raise?,
) -> LazyList[A] raise? {
  let mut cur = self
  while cur.cell is Cons(x, tail~) && pred(x) {
    cur = tail.force()
  }
  cur
}

///|
/// Concatenates two lazy lists. The right-hand side is not forced until
/// the left-hand side has been fully consumed.
pub fn[A] LazyList::concat(
  self : LazyList[A],
  other : LazyList[A],
) -> LazyList[A] {
  match self.cell {
    Empty => other
    Cons(x, tail~) => LazyList::lazy_cons(x, () => tail.force().concat(other))
  }
}

///|
/// Variant of `concat` whose second argument is itself a thunk; used
/// internally by `flat_map` to chain lazy lists without forcing them
/// prematurely.
fn[A] LazyList::concat_lazy(
  self : LazyList[A],
  other_thunk : () -> LazyList[A],
) -> LazyList[A] {
  match self.cell {
    Empty => other_thunk()
    Cons(x, tail~) =>
      LazyList::lazy_cons(x, () => tail.force().concat_lazy(other_thunk))
  }
}

///|
/// Maps each element to a lazy list and flattens the result. Skips empty
/// inner lists iteratively so a long run of empty mappings does not
/// blow the stack.
pub fn[A, B] LazyList::flat_map(
  self : LazyList[A],
  f : (A) -> LazyList[B],
) -> LazyList[B] {
  let mut cur = self
  while cur.cell is Cons(x, tail~) {
    match f(x).cell {
      Cons(y, tail=ys) => {
        let outer_tail = tail
        return LazyList::lazy_cons(y, () => {
          ys.force().concat_lazy(() => outer_tail.force().flat_map(f))
        })
      }
      Empty => cur = tail.force()
    }
  }
  LazyList::empty()
}

///|
/// Element-wise pairs two lazy lists, stopping at the shorter one.
///
/// `zip` is asymmetric in which side it forces first: the left tail is
/// forced before the right. If the left side ends first the right
/// remains untouched. If the right side ends first the left will have
/// been forced one cell past the boundary before `zip` can observe the
/// termination — this is unavoidable without a look-ahead protocol.
pub fn[A, B] LazyList::zip(
  self : LazyList[A],
  other : LazyList[B],
) -> LazyList[(A, B)] {
  match (self.cell, other.cell) {
    (Cons(x, tail=tx), Cons(y, tail=ty)) =>
      LazyList::lazy_cons((x, y), () => {
        match tx.force().cell {
          Empty => LazyList::empty()
          Cons(_) => tx.force().zip(ty.force())
        }
      })
    _ => LazyList::empty()
  }
}

// =====================================================================
// Strict consumers.
// =====================================================================

///|
/// Applies `f` to every element in order. Forces the entire spine.
pub fn[A] LazyList::each(
  self : LazyList[A],
  f : (A) -> Unit raise?,
) -> Unit raise? {
  let mut cur = self
  while cur.cell is Cons(x, tail~) {
    f(x)
    cur = tail.force()
  }
}

///|
/// Left fold. Forces the entire spine.
pub fn[A, B] LazyList::fold(
  self : LazyList[A],
  init~ : B,
  f : (B, A) -> B raise?,
) -> B raise? {
  let mut cur = self
  let mut acc = init
  while cur.cell is Cons(x, tail~) {
    acc = f(acc, x)
    cur = tail.force()
  }
  acc
}

///|
/// Materializes the lazy list as an array. Forces the entire spine.
pub fn[A] LazyList::to_array(self : LazyList[A]) -> Array[A] {
  let arr = []
  self.each(x => arr.push(x))
  arr
}

///|
/// Bridges the lazy list back to a pull-based `Iter`. The returned
/// iterator does not consume the lazy list — re-call `iter()` to get
/// a fresh traversal.
///
/// Each `next()` call forces at most one cell of the source: pulling
/// only the first element of `lazy_cons(x, () => ...)` will not run
/// the tail thunk.
pub fn[A] LazyList::iter(self : LazyList[A]) -> Iter[A] {
  let mut advance : () -> LazyList[A] = () => self
  Iter::new(() => {
    match advance().cell {
      Empty => None
      Cons(head, tail~) => {
        advance = () => tail.force()
        Some(head)
      }
    }
  })
}
