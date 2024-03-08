// Copyright 2024 International Digital Economy Academy
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

/// Convert array to list.
/// 
/// # Example
///
/// ```
/// let ls = from_array([1, 2, 3, 4, 5])
/// println(ls) // output: from_array([1, 2, 3, 4, 5])
/// ```
pub fn List::from_array[T](arr : Array[T]) -> List[T] {
  let mut list = List::Nil
  for i = arr.length() - 1; i >= 0; i = i - 1 {
    list = List::Cons(arr[i], list)
  }
  return list
}

test "from_array" {
  let ls = List::[1, 2, 3, 4, 5]
  @assertion.assert_eq(ls, Cons(1, Cons(2, Cons(3, Cons(4, Cons(5, Nil))))))?
}

/// Get the length of the list.
pub fn length[T](self : List[T]) -> Int {
  match self {
    Nil => 0
    Cons(_, tail) => 1 + length(tail)
  }
}

test "length" {
  let ls = from_array([1, 2, 3, 4, 5])
  @assertion.assert_eq(ls.length(), 5)?
}

/// Iterates over the list.
/// 
/// # Example
/// 
/// ```
/// from_array([1, 2, 3, 4, 5]).iter(print) // output: 12345
/// ```
pub fn iter[T](self : List[T], f : (T) -> Unit) {
  match self {
    Nil => ()
    Cons(head, tail) => {
      f(head)
      iter(tail, f)
    }
  }
}

test "iter" {
  let ls = from_array([1, 2, 3, 4, 5])
  let mut i = 0
  let mut failed = false
  ls.iter(fn(x) { i = i + 1; if x != i { failed = true } })
  if failed {
    return Err("iter test failed")
  }
}

/// Iterates over the list with index.
/// 
/// # Example
/// 
/// ```
/// from_array([1, 2, 3, 4, 5]).iteri(fn(i, x) { print("(\(i),\(x)) ") }) 
/// // output: (0,1) (1,2) (2,3) (3,4) (4,5)
/// ```
pub fn iteri[T](self : List[T], f : (Int, T) -> Unit) {
  let mut i = 0
  self.iter(fn(x) { f(i, x); i = i + 1 })
}

test "iteri" {
  let mut v = 0
  let mut failed = false
  let ls = from_array([1, 2, 3, 4, 5])
  ls.iteri(fn(i, x) { if x != v + 1 || i != v { failed = true }; v = v + 1 })
  if failed {
    return Err("iteri test failed")
  }
}

/// Maps the list.
/// 
/// # Example
/// 
/// ```
/// debug(from_array([1, 2, 3, 4, 5]).map(fn(x){ x * 2}))
/// // output: from_array([2, 4, 6, 8, 10])
/// ```
pub fn map[T, U](self : List[T], f : (T) -> U) -> List[U] {
  match self {
    Nil => Nil
    Cons(head, tail) => Cons(f(head), map(tail, f))
  }
}

test "map" {
  let ls = from_array([1, 2, 3, 4, 5])
  let rs = from_array([2, 4, 6, 8, 10])
  @assertion.assert_eq(ls.map(fn(x) { x * 2 }), rs)?
}

/// Maps the list with index.
pub fn mapi[T, U](self : List[T], f : (Int, T) -> U) -> List[U] {
  fn go(xs : List[T], i : Int, f : (Int, T) -> U) -> List[U] {
    match xs {
      Nil => Nil
      Cons(x, xs) => Cons(f(i, x), go(xs, i + 1, f))
    }
  }

  go(self, 0, f)
}

test "mapi" {
  let ls = from_array([1, 2, 3, 4, 5])
  let rs = from_array([1, 3, 5, 7, 9])
  @assertion.assert_eq(ls.mapi(fn(i, x) { i + x }), rs)?
}

/// Convert list to array.
pub fn to_array[T : Default](self : List[T]) -> Array[T] {
  let arr = Array::make(self.length(), T::default())
  self.iteri(fn(i, x) { arr[i] = x })
  return arr
}

test "to array" {
  let list = List::[1, 2, 3, 4, 5]
  let array = to_array(list)
  @assertion.assert_eq(array, [1, 2, 3, 4, 5])?
}

/// Filter the list.
/// 
/// # Example
/// 
/// ```
/// debug(from_array([1, 2, 3, 4, 5]).filter(fn(x){ x % 2 == 0}))
/// // output: from_array([2, 4])
/// ```
pub fn filter[T](self : List[T], f : (T) -> Bool) -> List[T] {
  match self {
    Nil => Nil
    Cons(head, tail) =>
      if f(head) {
        Cons(head, filter(tail, f))
      } else {
        filter(tail, f)
      }
  }
}

test "filter" {
  let ls = from_array([1, 2, 3, 4, 5])
  let rs = from_array([2, 4])
  @assertion.assert_eq(ls.filter(fn(x) { x % 2 == 0 }), rs)?
}

/// Test if all elements of the list satisfy the predicate.
pub fn all[T](self : List[T], f : (T) -> Bool) -> Bool {
  match self {
    Nil => true
    Cons(head, tail) => f(head) && all(tail, f)
  }
}

test "all" {
  let ls = from_array([1, 2, 3, 4, 5])
  @assertion.assert_true(ls.all(fn(x) { x > 0 }))?
  @assertion.assert_false(ls.all(fn(x) { x > 1 }))?
}

/// Test if any element of the list satisfies the predicate.
pub fn any[T](self : List[T], f : (T) -> Bool) -> Bool {
  match self {
    Nil => false
    Cons(head, tail) => f(head) || any(tail, f)
  }
}

test "any" {
  let ls = from_array([1, 2, 3, 4, 5])
  @assertion.assert_true(ls.any(fn(x) { x > 4 }))?
  @assertion.assert_false(ls.any(fn(x) { x > 5 }))?
}

/// Tail of the list.
/// 
/// # Example
/// 
/// ```
/// debug(from_array([1, 2, 3, 4, 5]).tail())
/// // output: from_array([2, 3, 4, 5])
/// ```
pub fn tail[T](self : List[T]) -> List[T] {
  match self {
    Nil => Nil
    Cons(_, tail) => tail
  }
}

test "tail" {
  let ls = from_array([1, 2, 3, 4, 5])
  let rs = from_array([2, 3, 4, 5])
  @assertion.assert_eq(ls.tail(), rs)?
}

/// Get first element of the list.
/// 
/// # Example
/// 
/// ```
/// debug(from_array([1, 2, 3, 4, 5]).head())
/// // output: 1
/// ```
pub fn head[T](self : List[T]) -> T {
  match self {
    Nil => abort("head of empty list")
    Cons(head, _) => head
  }
}

test "head" {
  let ls = from_array([1, 2, 3, 4, 5])
  @assertion.assert_eq(ls.head(), 1)?
}

/// Get first element of the list.
/// 
/// # Example
/// 
/// ```
/// debug(from_array([1, 2, 3, 4, 5]).head())
/// // output: Some(1)
/// debug(from_array([]).head())
/// // output: None
/// ```
pub fn head_option[T](self : List[T]) -> Option[T] {
  match self {
    Nil => None
    Cons(head, _) => Some(head)
  }
}

test "head option" {
  let ls = from_array([1, 2, 3, 4, 5])
  @assertion.assert_eq(ls.head_option(), Some(1))?
  let ls2 : List[Unit] = from_array([])
  @assertion.assert_eq(ls2, Nil)?
}

/// Last element of the list.
/// 
/// # Example
/// 
/// ```
/// debug(from_array([1, 2, 3, 4, 5]).last())
/// // output: 5
/// ```
pub fn last[T](self : List[T]) -> T {
  match self {
    Nil => abort("last of empty list")
    Cons(head, Nil) => head
    Cons(_, tail) => last(tail)
  }
}

test "last" {
  let ls = from_array([1, 2, 3, 4, 5])
  @assertion.assert_eq(ls.last(), 5)?
}

/// Init of the list.
/// 
/// # Example
/// 
/// ```
/// debug(from_array([1, 2, 3, 4, 5]).init_())
/// // output: from_array([1, 2, 3, 4])
/// ```
pub fn init_[T](self : List[T]) -> List[T] {
  match self {
    Nil => Nil
    Cons(_, Nil) => Nil
    Cons(head, tail) => Cons(head, init_(tail))
  }
}

test "init_" {
  let ls = from_array([1, 2, 3, 4, 5])
  let rs = from_array([1, 2, 3, 4])
  @assertion.assert_eq(ls.init_(), rs)?
}

/// Concatenate two lists.
///
/// # Example
///  
/// ```
/// let ls = from_array([1, 2, 3, 4, 5]).concat(from_array([6, 7, 8, 9, 10]))
/// debug(ls) // output: from_array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
/// ```
pub fn concat[T](self : List[T], other : List[T]) -> List[T] {
  match self {
    Nil => other
    Cons(head, tail) => Cons(head, concat(tail, other))
  }
}

test "concat" {
  let ls = from_array([1, 2, 3, 4, 5])
  let rs = from_array([6, 7, 8, 9, 10])
  let ts = from_array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  @assertion.assert_eq(ls.concat(rs), ts)?
}

/// Reverse the list.
/// 
/// # Example
/// 
/// ```
/// debug(from_array([1, 2, 3, 4, 5]).reverse())
/// // output: from_array([5, 4, 3, 2, 1])
/// ```
pub fn reverse[T](self : List[T]) -> List[T] {
  match self {
    Nil => Nil
    Cons(head, tail) => concat(reverse(tail), Cons(head, Nil))
  }
}

test "reverse" {
  let ls = from_array([1, 2, 3, 4, 5])
  @assertion.assert_eq(ls, ls.reverse().reverse())?
}

/// Fold the list.
///
/// # Example
/// 
/// ```
/// let r = from_array([1, 2, 3, 4, 5]).fold(0, fn(acc, x) { acc + x })
/// debug(r) // output: 15
/// ```
pub fn fold[T, U](self : List[T], initial : U, f : (U, T) -> U) -> U {
  match self {
    Nil => initial
    Cons(head, tail) => fold(tail, f(initial, head), f)
  }
}

test "fold" {
  let ls = from_array([1, 2, 3, 4, 5])
  @assertion.assert_eq(ls.fold(0, fn(acc, x) { acc + x }), 15)?
}

/// Zip two lists.
///
/// # Example
/// 
/// ```
/// let r = zip(from_array([1, 2, 3, 4, 5]), from_array([6, 7, 8, 9, 10]))
/// debug(r) // output: from_array([(1, 6), (2, 7), (3, 8), (4, 9), (5, 10)]
/// ```
/// 
/// # Panics
///
/// If the two lists have different lengths, the function will panic.
///
pub fn zip[T, U](self : List[T], other : List[U]) -> List[(T, U)] {
  match (self, other) {
    (Nil, Nil) => Nil
    (Cons(x, xs), Cons(y, ys)) => Cons((x, y), zip(xs, ys))
    _ => abort("zip: lists have different lengths")
  }
}

/// map over the list and concat all results.
///
/// `concat_map(f, ls)` equal to `ls.map(f).fold(Nil, fn(acc, x) { acc.concat(x) })))`
///
/// # Example
/// 
/// ```
/// let ls = from_array([1, 2, 3])
/// let r = ls.concat_map(fn(x) { [x, x * 2] })
/// debug(r) // output: from_array([1, 2, 2, 4, 3, 6])
/// ```
pub fn concat_map[T, U](self : List[T], f : (T) -> List[U]) -> List[U] {
  match self {
    Nil => Nil
    Cons(head, tail) => concat(f(head), concat_map(tail, f))
  }
}

test "concat_map" {
  let ls = from_array([1, 2, 3])
  let rs = from_array([1, 2, 2, 4, 3, 6])
  @assertion.assert_eq(ls.concat_map(fn(x) { from_array([x, x * 2]) }), rs)?
}

/// Get nth element of the list
pub fn nth[T](self : List[T], n : Int) -> T {
  match self {
    Nil => abort("nth: index out of bounds")
    Cons(head, tail) => if n == 0 { head } else { nth(tail, n - 1) }
  }
}

test "nth" {
  let ls = from_array([1, 2, 3, 4, 5])
  @assertion.assert_eq(ls.nth(0), 1)?
  @assertion.assert_eq(ls.nth(1), 2)?
  @assertion.assert_eq(ls.nth(2), 3)?
  @assertion.assert_eq(ls.nth(3), 4)?
  @assertion.assert_eq(ls.nth(4), 5)?
}

/// Get nth element of the list or None if the index is out of bounds
pub fn nth_option[T](self : List[T], n : Int) -> Option[T] {
  match self {
    Nil => None
    Cons(head, tail) =>
      if n == 0 {
        Some(head)
      } else {
        nth_option(tail, n - 1)
      }
  }
}

test "nth_option" {
  let ls = from_array([1, 2, 3, 4, 5])
  @assertion.assert_eq(ls.nth_option(0), Some(1))?
  @assertion.assert_eq(ls.nth_option(1), Some(2))?
  @assertion.assert_eq(ls.nth_option(2), Some(3))?
  @assertion.assert_eq(ls.nth_option(3), Some(4))?
  @assertion.assert_eq(ls.nth_option(4), Some(5))?
  @assertion.assert_eq(ls.nth_option(5), None)?
}

/// Create a list of length n with the given value
///
/// # Example
/// 
/// ```
/// debug(repeat(5, 1)) // output: from_array([1, 1, 1, 1, 1])
/// ```
pub fn repeat[T](n : Int, x : T) -> List[T] {
  if n == 0 {
    Nil
  } else {
    Cons(x, repeat(n - 1, x))
  }
}

test "repeat" {
  let ls = from_array([1, 1, 1, 1, 1])
  @assertion.assert_eq(repeat(5, 1), ls)?
}

/// Insert separator to the list.
/// 
/// # Example
/// 
/// ```
/// let ls = from_array(["1", "2", "3", "4", "5"]).separate_by("|")
/// debug(ls) // output: from_array(["1", "|", "2", "|", "3", "|", "4", "|", "5"])
/// ```
pub fn separate_by[T](self : List[T], separator : T) -> List[T] {
  match self {
    Nil => Nil
    Cons(head, Nil) => Cons(head, Nil)
    Cons(head, tail) =>
      Cons(head, Cons(separator, separate_by(tail, separator)))
  }
}

test "separate_by" {
  let ls = from_array(["1", "|", "2", "|", "3", "|", "4", "|", "5"])
  @assertion.assert_eq(
    from_array(["1", "2", "3", "4", "5"]).separate_by("|"),
    ls,
  )?
}

/// Check if the list is empty.
pub fn is_empty[T](self : List[T]) -> Bool {
  match self {
    Nil => true
    _ => false
  }
}

test "is_empty" {
  let ls = from_array([1, 2, 3, 4, 5])
  @assertion.assert_false(ls.is_empty())?
  @assertion.assert_true((List::Nil : List[Unit]).is_empty())?
}

/// Unzip two lists.
///
/// # Example
///
/// ```
/// let (a,b) = unzip(from_array([(1,2),(3,4),(5,6)]))
/// debug(a) // output: from_array([1, 3, 5])
/// debug(b) // output: from_array([2, 4, 6])
/// ```
pub fn unzip[T, U](list : List[(T, U)]) -> (List[T], List[U]) {
  match list {
    Nil => (Nil, Nil)
    Cons((x, y), xs) => {
      let (xs, ys) = unzip(xs)
      (Cons(x, xs), Cons(y, ys))
    }
  }
}

test "unzip" {
  let ls = from_array([(1, 2), (3, 4), (5, 6)])
  let (a, b) = unzip(ls)
  @assertion.assert_eq(a, from_array([1, 3, 5]))?
  @assertion.assert_eq(b, from_array([2, 4, 6]))?
}

/// flatten a list of lists.
/// 
/// # Example
/// 
/// ```
/// let ls = flatten(from_array([from_array([1,2,3]), from_array([4,5,6]), from_array([7,8,9])]))
/// debug(ls) // output: from_array([1, 2, 3, 4, 5, 6, 7, 8, 9])
/// ```
pub fn flatten[T](list : List[List[T]]) -> List[T] {
  match list {
    Nil => Nil
    Cons(head, tail) => concat(head, flatten(tail))
  }
}

test "flatten" {
  let ls = from_array(
    [from_array([1, 2, 3]), from_array([4, 5, 6]), from_array([7, 8, 9])],
  )
  let rs = from_array([1, 2, 3, 4, 5, 6, 7, 8, 9])
  @assertion.assert_eq(flatten(ls), rs)?
}

/// Get maximum element of the list.
pub fn maximum[T : Compare](self : List[T]) -> T {
  match self {
    Nil => abort("maximum: empty list")
    Cons(x, Nil) => x
    Cons(x, xs) => {
      let y = maximum(xs)
      if x > y {
        x
      } else {
        y
      }
    }
  }
}

test "maximum" {
  let ls = from_array([1, 123, 52, 3, 6, 0, -6, -76])
  @assertion.assert_eq(ls.maximum(), 123)?
}

/// Get minimum element of the list.
pub fn minimum[T : Compare](self : List[T]) -> T {
  match self {
    Nil => abort("minimum: empty list")
    Cons(x, Nil) => x
    Cons(x, xs) => {
      let y = minimum(xs)
      if x < y {
        x
      } else {
        y
      }
    }
  }
}

test "minimum" {
  let ls = from_array([1, 123, 52, 3, 6, 0, -6, -76])
  @assertion.assert_eq(ls.minimum(), -76)?
}

/// Sort the list in ascending order.
///
/// # Example
/// 
/// ```
/// let ls = sort(from_array([1,123,52,3,6,0,-6,-76]))
/// debug(ls) // output: from_array([-76, -6, 0, 1, 3, 6, 52, 123])
/// ```
pub fn sort[T : Compare](self : List[T]) -> List[T] {
  match self {
    Nil => Nil
    Cons(x, xs) => {
      let smaller = filter(xs, fn(y) { y < x })
      let greater = filter(xs, fn(y) { y >= x })
      concat(sort(smaller), Cons(x, sort(greater)))
    }
  }
}

test "sort" {
  let ls = from_array([1, 123, 52, 3, 6, 0, -6, -76])
  let rs = from_array([-76, -6, 0, 1, 3, 6, 52, 123])
  @assertion.assert_eq(ls.sort(), rs)?
}

/// Concatenate two lists.
///
/// `a + b` equal to `a.concat(b)`
pub fn op_add[T](self : List[T], other : List[T]) -> List[T] {
  self.concat(other)
}

/// Check if the list contains the value.
pub fn contain[T : Eq](self : List[T], value : T) -> Bool {
  match self {
    Nil => false
    Cons(x, xs) => if x == value { true } else { contain(xs, value) }
  }
}

test "contain" {
  let ls = from_array([1, 2, 3])
  @assertion.assert_true(ls.contain(1))?
  @assertion.assert_true(ls.contain(2))?
  @assertion.assert_true(ls.contain(3))?
  @assertion.assert_false(ls.contain(0))?
  @assertion.assert_false(ls.contain(4))?
}

/// Produces a collection iteratively.
///
/// # Example
///
/// ```
/// // from_array([0, 1, 2])
/// unfold(0, fn { i => if i == 3 { None } else { Some(i, i + 1) } }) |> debug 
/// ```
pub fn unfold[T, State](
  init : State,
  f : (State) -> Option[(T, State)]
) -> List[T] {
  match f(init) {
    Some(element, new_state) => Cons(element, unfold(new_state, f))
    None => Nil
  }
}

test "unfold" {
  let ls = unfold(0, fn { i => if i == 3 { None } else { Some(i, i + 1) } })
  @assertion.assert_eq(ls, Cons(0, Cons(1, Cons(2, Nil))))?
}

/// Take first n elements of the list.
///
/// # Example
///
/// ```
/// from_array([1, 2, 3, 4, 5]).take(3)
/// ```
pub fn take[T](self : List[T], n : Int) -> List[T] {
  if n <= 0 {
    Nil
  } else {
    unsafeTake(n, self)
  }
}

fn unsafeTake[T](n : Int, xs : List[T]) -> List[T] {
  match (n, xs) {
    (0, _) => Nil
    (1, Cons(x, _)) => Cons(x, Nil)
    (_, Cons(x, xs)) => Cons(x, unsafeTake(n - 1, xs))
    _ => abort("take: index out of bounds")
  }
}

test "take" {
  let ls = from_array([1, 2, 3, 4, 5]).take(3)
  @assertion.assert_eq(ls, Cons(1, Cons(2, Cons(3, Nil))))?
}

/// Drop first n elements of the list.
///
/// # Example
///
/// ```
/// from_array([1, 2, 3, 4, 5]).drop(3)
/// ```
pub fn drop[T](self : List[T], n : Int) -> List[T] {
  if n <= 0 {
    self
  } else {
    unsafeDrop(n, self)
  }
}

fn unsafeDrop[T](n : Int, xs : List[T]) -> List[T] {
  match (n, xs) {
    (0, _) => xs
    (1, Cons(_, xs)) => xs
    (_, Cons(_, xs)) => unsafeDrop(n - 1, xs)
    _ => abort("drop: index out of bounds")
  }
}

test "drop" {
  let ls = from_array([1, 2, 3, 4, 5]).drop(3)
  @assertion.assert_eq(ls, Cons(4, Cons(5, Nil)))?
}

/// Take the longest prefix of a list of elements that satisfies a given predicate.
///
/// # Example
///
/// ```
/// from_array([1, 2, 3, 4]).take_while(fn(x) { x < 3 })
/// ```
pub fn take_while[T](self : List[T], p : (T) -> Bool) -> List[T] {
  match self {
    Nil => Nil
    Cons(x, xs) => if p(x) { Cons(x, xs.take_while(p)) } else { Nil }
  }
}

test "take_while" {
  let ls = take_while(from_array([0, 1, 2, 3, 4]), fn(x) { x < 3 })
  @assertion.assert_eq(ls, Cons(0, Cons(1, Cons(2, Nil))))?
}

/// Drop the longest prefix of a list of elements that satisfies a given predicate.
///
/// # Example
///
/// ```
/// from_array([1, 2, 3, 4]).drop_while(fn(x) { x < 3 })
/// ```
pub fn drop_while[T](self : List[T], p : (T) -> Bool) -> List[T] {
  match self {
    Nil => Nil
    Cons(x, xs) => if p(x) { xs.drop_while(p) } else { Cons(x, xs) }
  }
}

test "drop_while" {
  let ls = drop_while(from_array([0, 1, 2, 3, 4]), fn(x) { x < 3 })
  @assertion.assert_eq(ls, Cons(3, Cons(4, Nil)))?
}

/// Fold a list and return a list of successive reduced values from the left
///
/// # Example
///
/// ```
/// let ls = from_array([1, 2, 3, 4, 5])
/// ls.scan(fn(acc, x) { acc + x }, 0) 
/// ```
pub fn scan[T, E](self : List[T], f : (E, T) -> E, init : E) -> List[E] {
  fn go(f, q : E, ls : List[T]) -> List[E] {
    Cons(
      q,
      match ls {
        Nil => Nil
        Cons(x, xs) => go(f, f(q, x), xs)
      },
    )
  }

  go(f, init, self)
}

test "scan" {
  let ls = from_array([1, 2, 3, 4, 5]).scan(fn(acc, x) { acc + x }, 0)
  @assertion.assert_eq(ls, from_array([0, 1, 3, 6, 10, 15]))?
}

/// Looks up a key in an association list.
///
/// # Example
///
/// ```
/// let ls = from_array([(1, "a"), (2, "b"), (3, "c")])
/// ls.lookup(3) // output: Some("c")
/// ```
pub fn lookup[T : Eq, E](self : List[(T, E)], v : T) -> Option[E] {
  match self {
    Nil => None
    Cons((x, y), xs) => if x == v { Some(y) } else { lookup(xs, v) }
  }
}

test "lookup" {
  let ls = from_array([(1, "a"), (2, "b"), (3, "c")])
  @assertion.assert_eq(ls.lookup(3), Some("c"))?
  @assertion.assert_eq(ls.lookup(4), None)?
}
