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
  Empty
}

///|
/// Prepends an element with a strict tail. The tail is treated as already
/// forced — useful when you have an existing `LazyList` value to put behind
/// the head.
///
/// # Example
///
/// ```mbt check
/// test {
///   let xs = @lazy_list.cons(1, @lazy_list.cons(2, @lazy_list.empty()))
///   inspect(xs, content="@lazy_list.from_array([1, 2])")
/// }
/// ```
#as_free_fn
pub fn[A] LazyList::cons(head : A, tail : LazyList[A]) -> LazyList[A] {
  Cons(head, tail=@lazy.Lazy::ready(tail))
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
  Cons(head, tail=@lazy.Lazy(tail))
}

///|
/// Creates a lazy list with a single element.
#as_free_fn
pub fn[A] LazyList::singleton(value : A) -> LazyList[A] {
  Cons(value, tail=@lazy.Lazy::ready(Empty))
}

///|
/// An infinite lazy list of the same value repeated forever. Use `take`
/// or `take_while` to consume only a finite prefix.
///
/// # Example
///
/// ```mbt check
/// test {
///   debug_inspect(@lazy_list.repeat(7).take(3).to_array(), content="[7, 7, 7]")
/// }
/// ```
#as_free_fn
pub fn[A] LazyList::repeat(value : A) -> LazyList[A] {
  LazyList::lazy_cons(value, () => LazyList::repeat(value))
}

///|
/// An infinite lazy list `seed, f(seed), f(f(seed)), ...`.
///
/// # Example
///
/// ```mbt check
/// test {
///   let powers = @lazy_list.iterate(1, x => x * 2)
///   debug_inspect(powers.take(5).to_array(), content="[1, 2, 4, 8, 16]")
/// }
/// ```
#as_free_fn
pub fn[A] LazyList::iterate(seed : A, f : (A) -> A) -> LazyList[A] {
  LazyList::lazy_cons(seed, () => LazyList::iterate(f(seed), f))
}

///|
/// Builds a lazy list by repeatedly applying `f` to a state. `f` returns
/// `Some((value, next_state))` to emit a value and continue, or `None`
/// to stop.
///
/// # Example
///
/// ```mbt check
/// test {
///   let xs = @lazy_list.unfold(init=0, n => {
///     if n < 3 {
///       Some((n * n, n + 1))
///     } else {
///       None
///     }
///   })
///   debug_inspect(xs.to_array(), content="[0, 1, 4]")
/// }
/// ```
#as_free_fn
pub fn[A, S] LazyList::unfold(f : (S) -> (A, S)?, init~ : S) -> LazyList[A] {
  match f(init) {
    None => Empty
    Some((x, next)) =>
      LazyList::lazy_cons(x, () => LazyList::unfold(f, init=next))
  }
}

///|
/// Builds a lazy list from an array view. All cells are pre-forced since
/// the array is already in memory; this is effectively a strict copy that
/// happens to be re-traversable.
#as_free_fn
pub fn[A] LazyList::from_array(arr : ArrayView[A]) -> LazyList[A] {
  let mut acc : LazyList[A] = Empty
  for i = arr.length() - 1; i >= 0; i = i - 1 {
    acc = LazyList::cons(arr[i], acc)
  }
  acc
}

///|
/// Builds a lazy list from a strict `@list.List`. Cells are produced
/// lazily — useful as a cheap upgrade path that defers traversal.
#as_free_fn
pub fn[A] LazyList::from_list(list : @list.List[A]) -> LazyList[A] {
  match list {
    Empty => Empty
    More(x, tail~) => LazyList::lazy_cons(x, () => LazyList::from_list(tail))
  }
}

///|
/// Builds a lazy list from a pull-based `Iter`. Each tail forces a single
/// `iter.next()` call and memoizes the result, so re-traversing the
/// returned `LazyList` does not re-pull from the underlying iterator.
///
/// # Example
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
    None => Empty
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
  self is Empty
}

///|
/// Returns the head element if any. Does not force the tail.
pub fn[A] LazyList::head(self : LazyList[A]) -> A? {
  match self {
    Empty => None
    Cons(x, ..) => Some(x)
  }
}

///|
/// Returns the tail (forcing one cell) if the list is non-empty.
pub fn[A] LazyList::tail(self : LazyList[A]) -> LazyList[A]? {
  match self {
    Empty => None
    Cons(_, tail~) => Some(tail.force())
  }
}

///|
/// Counts the elements. Forces the entire spine; never returns on an
/// infinite list.
pub fn[A] LazyList::length(self : LazyList[A]) -> Int {
  let mut cur = self
  let mut n = 0
  while cur is Cons(_, tail~) {
    n += 1
    cur = tail.force()
  }
  n
}

///|
/// Returns the element at index `i` (0-based), or `None` if out of range.
/// Forces only as far as needed. Negative indexes return `None` without
/// forcing any tail.
pub fn[A] LazyList::nth(self : LazyList[A], i : Int) -> A? {
  if i < 0 {
    return None
  }
  let mut cur = self
  let mut k = i
  while cur is Cons(x, tail~) {
    if k == 0 {
      return Some(x)
    }
    k -= 1
    cur = tail.force()
  }
  None
}

// =====================================================================
// Lazy transformations.
// =====================================================================

///|
/// Lazily applies `f` to every element. `f` runs the first time a given
/// cell of the result is forced, and the mapped value is then memoized.
pub fn[A, B] LazyList::map(self : LazyList[A], f : (A) -> B) -> LazyList[B] {
  match self {
    Empty => Empty
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
  while cur is Cons(x, tail~) {
    if pred(x) {
      let t = tail
      return LazyList::lazy_cons(x, () => t.force().filter(pred))
    }
    cur = tail.force()
  }
  Empty
}

///|
/// Returns the first `n` elements as a lazy list. If `n <= 0`, returns
/// the empty list. Safe to call on infinite lists. Forces exactly the
/// cells of the prefix — no look-ahead.
pub fn[A] LazyList::take(self : LazyList[A], n : Int) -> LazyList[A] {
  if n <= 0 {
    return Empty
  }
  match self {
    Empty => Empty
    Cons(x, tail~) =>
      if n == 1 {
        LazyList::cons(x, Empty)
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
  while k > 0 && cur is Cons(_, tail~) {
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
  match self {
    Empty => Empty
    Cons(x, tail~) =>
      if pred(x) {
        LazyList::lazy_cons(x, () => tail.force().take_while(pred))
      } else {
        Empty
      }
  }
}

///|
/// Skips elements while `pred` holds, returning the rest.
pub fn[A] LazyList::drop_while(
  self : LazyList[A],
  pred : (A) -> Bool,
) -> LazyList[A] {
  let mut cur = self
  while cur is Cons(x, tail~) && pred(x) {
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
  match self {
    Empty => other
    Cons(x, tail~) => LazyList::lazy_cons(x, () => tail.force().concat(other))
  }
}

///|
/// Variant of `concat` whose second argument is itself a thunk; used
/// internally to chain lazy lists without forcing them prematurely.
fn[A] LazyList::concat_lazy(
  self : LazyList[A],
  other_thunk : () -> LazyList[A],
) -> LazyList[A] {
  match self {
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
  while cur is Cons(x, tail~) {
    match f(x) {
      Cons(y, tail=ys) => {
        let outer_tail = tail
        return LazyList::lazy_cons(y, () => {
          ys.force().concat_lazy(() => outer_tail.force().flat_map(f))
        })
      }
      Empty => cur = tail.force()
    }
  }
  Empty
}

///|
/// Element-wise pairs two lazy lists, stopping at the shorter one. When
/// resuming the lazy tail, the left side is forced first; if it is empty
/// the right side is left untouched.
pub fn[A, B] LazyList::zip(
  self : LazyList[A],
  other : LazyList[B],
) -> LazyList[(A, B)] {
  match (self, other) {
    (Cons(x, tail=tx), Cons(y, tail=ty)) =>
      LazyList::lazy_cons((x, y), () => {
        match tx.force() {
          Empty => Empty
          nx => nx.zip(ty.force())
        }
      })
    _ => Empty
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
  while cur is Cons(x, tail~) {
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
  while cur is Cons(x, tail~) {
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
/// Materializes the lazy list as a strict `@list.List`. Forces the
/// entire spine.
pub fn[A] LazyList::to_list(self : LazyList[A]) -> @list.List[A] {
  @list.from_array(self.to_array())
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
    match advance() {
      Empty => None
      Cons(head, tail~) => {
        advance = () => tail.force()
        Some(head)
      }
    }
  })
}

// =====================================================================
// Trait implementations.
// =====================================================================

///|
pub impl[A : Eq] Eq for LazyList[A] with equal(self, other) -> Bool {
  if physical_equal(self, other) {
    return true
  }
  let mut a = self
  let mut b = other
  for ;; {
    match (a, b) {
      (Empty, Empty) => return true
      (Cons(x, tail=xs), Cons(y, tail=ys)) =>
        if x != y {
          return false
        } else {
          a = xs.force()
          b = ys.force()
        }
      _ => return false
    }
  }
}

///|
/// Show implementation. Forces the entire spine; do not call on infinite
/// lists.
pub impl[A : Show] Show for LazyList[A] with output(self, logger) {
  logger.write_iter(self.iter(), prefix="@lazy_list.from_array([", suffix="])")
}

///|
/// ToJson implementation. Forces the entire spine; do not call on
/// infinite lists.
pub impl[A : ToJson] ToJson for LazyList[A] with to_json(self) {
  let arr = self.to_array()
  let jsons = Array::new(capacity=arr.length())
  for a in arr {
    jsons.push(a.to_json())
  }
  Json::array(jsons)
}

///|
/// Convert a lazy list to JSON.
pub fn[A : ToJson] LazyList::to_json(self : LazyList[A]) -> Json {
  ToJson::to_json(self)
}
