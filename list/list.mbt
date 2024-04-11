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
/// let ls = List::[1, 2, 3, 4, 5]
/// println(ls) // output: List::[1, 2, 3, 4, 5]
/// ```
pub fn List::from_array[T](arr : Array[T]) -> List[T] {
  for i = arr.length() - 1, list = List::Nil; i >= 0; {
    continue i - 1, List::Cons(arr[i], list)
  } else {
    list
  }
}

test "from_array" {
  let ls = List::[1, 2, 3, 4, 5]
  @assertion.assert_eq(ls, Cons(1, Cons(2, Cons(3, Cons(4, Cons(5, Nil))))))?
  @assertion.assert_eq(List::[1, 2], Cons(1, Cons(2, Nil)))?
}

/// Get the length of the list.
pub fn length[T](self : List[T]) -> Int {
  loop self, 0 {
    Nil, len => len
    Cons(_, rest), acc => continue rest, acc + 1
  }
}

test "length" {
  let ls = List::[1, 2, 3, 4, 5]
  @assertion.assert_eq(ls.length(), 5)?
}

/// Iterates over the list.
/// 
/// # Example
/// 
/// ```
/// List::[1, 2, 3, 4, 5].iter(print) // output: 12345
/// ```
pub fn iter[T](self : List[T], f : (T) -> Unit) -> Unit {
  loop self {
    Nil => ()
    Cons(head, tail) => {
      f(head)
      continue tail
    }
  }
}

test "iter" {
  let ls = List::[1, 2, 3, 4, 5]
  let mut i = 0
  let mut failed = false
  ls.iter(
    fn(x) {
      i = i + 1
      if x != i {
        failed = true
      }
    },
  )
  @assertion.assert_false(failed)?
}

/// Iterates over the list with index.
/// 
/// # Example
/// 
/// ```
/// List::[1, 2, 3, 4, 5].iteri(fn(i, x) { print("(\(i),\(x)) ") }) 
/// // output: (0,1) (1,2) (2,3) (3,4) (4,5)
/// ```
pub fn iteri[T](self : List[T], f : (Int, T) -> Unit) -> Unit {
  loop self, 0 {
    Nil, _ => ()
    Cons(x, xs), i => {
      f(i, x)
      continue xs, i + 1
    }
  }
}

test "iteri" {
  let mut v = 0
  let mut failed = false
  let ls = List::[1, 2, 3, 4, 5]
  ls.iteri(
    fn(i, x) {
      if x != v + 1 || i != v {
        failed = true
      }
      v = v + 1
    },
  )
  @assertion.assert_false(failed)?
}

/// Maps the list.
/// 
/// # Example
/// 
/// ```
/// debug(List::[1, 2, 3, 4, 5].map(fn(x){ x * 2}))
/// // output: List::[2, 4, 6, 8, 10]
/// ```
pub fn map[T, U](self : List[T], f : (T) -> U) -> List[U] {
  match self {
    Nil => Nil
    Cons(head, tail) => Cons(f(head), map(tail, f))
  }
}

test "map" {
  let ls = List::[1, 2, 3, 4, 5]
  let rs = List::[2, 4, 6, 8, 10]
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
  let ls = List::[1, 2, 3, 4, 5]
  let rs = List::[1, 3, 5, 7, 9]
  @assertion.assert_eq(ls.mapi(fn(i, x) { i + x }), rs)?
}

/// Convert list to array.
pub fn to_array[T](self : List[T]) -> Array[T] {
  match self {
    Nil => []
    Cons(head, _) => {
      let arr = Array::make(self.length(), head)
      self.iteri(fn(i, x) { arr[i] = x })
      arr
    }
  }
}

test "to_array" {
  let list = List::[1, 2, 3, 4, 5]
  let empty : List[Int] = Nil
  let array = to_array(list)
  let earray = to_array(empty)
  @assertion.assert_eq(array, [1, 2, 3, 4, 5])?
  @assertion.assert_eq(earray, [])?
}

/// Filter the list.
/// 
/// # Example
/// 
/// ```
/// debug(List::[1, 2, 3, 4, 5].filter(fn(x){ x % 2 == 0}))
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
  let ls = List::[1, 2, 3, 4, 5]
  let rs = List::[2, 4]
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
  let ls = List::[1, 2, 3, 4, 5]
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
  let ls = List::[1, 2, 3, 4, 5]
  @assertion.assert_true(ls.any(fn(x) { x > 4 }))?
  @assertion.assert_false(ls.any(fn(x) { x > 5 }))?
}

/// Tail of the list.
/// 
/// # Example
/// 
/// ```
/// debug(List::[1, 2, 3, 4, 5].tail())
/// // output: from_array([2, 3, 4, 5])
/// ```
pub fn tail[T](self : List[T]) -> List[T] {
  match self {
    Nil => Nil
    Cons(_, tail) => tail
  }
}

test "tail" {
  let ls = List::[1, 2, 3, 4, 5]
  let rs = List::[2, 3, 4, 5]
  let el : List[Int] = Nil
  @assertion.assert_eq(ls.tail(), rs)?
  @assertion.assert_eq(el.tail(), Nil)?
}

/// Get first element of the list.
/// 
/// # Example
/// 
/// ```
/// debug(List::[1, 2, 3, 4, 5].head_exn())
/// // output: 1
/// ```
/// @alert unsafe "Panic if the list is empty"
pub fn head_exn[T](self : List[T]) -> T {
  match self {
    Nil => abort("head of empty list")
    Cons(head, _) => head
  }
}

test "head_exn" {
  let ls = List::[1, 2, 3, 4, 5]
  @assertion.assert_eq(ls.head_exn(), 1)?
}

/// Get first element of the list.
/// 
/// # Example
/// 
/// ```
/// debug(List::[1, 2, 3, 4, 5].head())
/// // output: Some(1)
/// debug(from_array([]).head())
/// // output: None
/// ```
pub fn head[T](self : List[T]) -> Option[T] {
  match self {
    Nil => None
    Cons(head, _) => Some(head)
  }
}

test "head" {
  let ls = List::[1, 2, 3, 4, 5]
  let el : List[Unit] = List::[]
  @assertion.assert_eq(ls.head(), Some(1))?
  @assertion.assert_eq(el.head(), None)?
}

/// Last element of the list.
/// 
/// # Example
/// 
/// ```
/// debug(List::[1, 2, 3, 4, 5].last())
/// // output: 5
/// ```
/// @alert unsafe "Panic if the list is empty"
pub fn last[T](self : List[T]) -> T {
  loop self {
    Nil => abort("last of empty list")
    Cons(head, Nil) => head
    Cons(_, tail) => continue tail
  }
}

test "last" {
  let ls = List::[1, 2, 3, 4, 5]
  @assertion.assert_eq(ls.last(), 5)?
}

/// Init of the list.
/// 
/// # Example
/// 
/// ```
/// debug(List::[1, 2, 3, 4, 5].init_())
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
  let ls = List::[1, 2, 3, 4, 5]
  let rs = List::[1, 2, 3, 4]
  let el : List[Int] = Nil
  @assertion.assert_eq(ls.init_(), rs)?
  @assertion.assert_eq(el.init_(), Nil)?
}

/// Concatenate two lists.
///
/// # Example
///  
/// ```
/// let ls = List::[1, 2, 3, 4, 5].concat(from_array([6, 7, 8, 9, 10]))
/// debug(ls) // output: from_array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
/// ```
pub fn concat[T](self : List[T], other : List[T]) -> List[T] {
  match self {
    Nil => other
    Cons(head, tail) => Cons(head, concat(tail, other))
  }
}

test "concat" {
  let ls = List::[1, 2, 3, 4, 5]
  let rs = List::[6, 7, 8, 9, 10]
  let ts = List::[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  @assertion.assert_eq(ls.concat(rs), ts)?
}

/// Reverse the list.
/// 
/// # Example
/// 
/// ```
/// debug(List::[1, 2, 3, 4, 5].reverse())
/// // output: from_array([5, 4, 3, 2, 1])
/// ```
pub fn reverse[T](self : List[T]) -> List[T] {
  loop self, (Nil : List[T]) {
    xs, ys =>
      match (xs, ys) {
        (Nil, acc) => acc
        (Cons(x, xs), acc) => continue xs, Cons(x, acc)
      }
  }
}

test "reverse" {
  let ls = List::[1, 2, 3, 4, 5]
  let rs = List::[5, 4, 3, 2, 1]
  @assertion.assert_eq(rs.reverse(), ls)?
  @assertion.assert_eq(ls, ls.reverse().reverse())?
}

/// Fold the list from left.
///
/// # Example
/// 
/// ```
/// let r = List::[1, 2, 3, 4, 5].fold_left(~init=0, fn(acc, x) { acc + x })
/// debug(r) // output: 15
/// ```
pub fn fold_left[T, U](self : List[T], f : (U, T) -> U, ~init : U) -> U {
  match self {
    Nil => init
    Cons(head, tail) => tail.fold_left(f, ~init=f(init, head))
  }
}

test "fold_left" {
  let ls = List::[1, 2, 3, 4, 5]
  @assertion.assert_eq(ls.fold_left(fn(acc, x) { acc + x }, ~init=0), 15)?
}

/// Fold the list from right.
/// 
/// # Example
/// ```
/// let r = List::[1, 2, 3, 4, 5].fold_right(fn(x, acc) { x + acc }, ~init=0)
/// ```
pub fn fold_right[T, U](self : List[T], f : (T, U) -> U, ~init : U) -> U {
  match self {
    Nil => init
    Cons(head, tail) => f(head, tail.fold_right(f, ~init))
  }
}

test "fold_right" {
  let ls = List::["1", "2", "3", "4", "5"]
  @assertion.assert_eq(ls.fold_right(fn(x, acc) { x + acc }, ~init=""), "12345")?
}

/// Fold the list from left with index.
pub fn fold_lefti[T, U](self : List[T], f : (Int, U, T) -> U, ~init : U) -> U {
  fn go(xs : List[T], i : Int, f : (Int, U, T) -> U, acc : U) -> U {
    match xs {
      Nil => acc
      Cons(x, xs) => go(xs, i + 1, f, f(i, acc, x))
    }
  }

  go(self, 0, f, init)
}

test "fold_lefti" {
  let ls = List::[1, 2, 3, 4, 5]
  @assertion.assert_eq(
    ls.fold_lefti(fn(i, acc, x) { acc + i * x }, ~init=0),
    40,
  )?
}

/// Fold the list from right with index.
pub fn fold_righti[T, U](self : List[T], f : (Int, T, U) -> U, ~init : U) -> U {
  fn go(xs : List[T], i : Int, f : (Int, T, U) -> U, acc : U) -> U {
    match xs {
      Nil => acc
      Cons(x, xs) => f(i, x, go(xs, i + 1, f, acc))
    }
  }

  go(self, 0, f, init)
}

test "fold_righti" {
  let ls = List::[1, 2, 3, 4, 5]
  @assertion.assert_eq(
    ls.fold_righti(fn(i, x, acc) { x * i + acc }, ~init=0),
    40,
  )?
}

/// Zip two lists.
///
/// # Example
/// 
/// ```
/// let r = zip(List::[1, 2, 3, 4, 5], from_array([6, 7, 8, 9, 10]))
/// debug(r) // output: from_array([(1, 6), (2, 7), (3, 8), (4, 9), (5, 10)]
/// ```
/// 
/// @alert unsafe "Panic if the two lists have different lengths."
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
  let ls = List::[1, 2, 3]
  let rs = List::[1, 2, 2, 4, 3, 6]
  @assertion.assert_eq(ls.concat_map(fn(x) { List::[x, x * 2] }), rs)?
}

/// Get nth element of the list
/// @alert unsafe "Panic if the index is out of bounds"
pub fn nth_exn[T](self : List[T], n : Int) -> T {
  loop self, n {
    Nil, _ => abort("nth: index out of bounds")
    Cons(head, _), 0 => head
    Cons(_, tail), n => continue tail, n - 1
  }
}

test "nth_exn" {
  let ls = List::[1, 2, 3, 4, 5]
  @assertion.assert_eq(ls.nth_exn(0), 1)?
  @assertion.assert_eq(ls.nth_exn(1), 2)?
  @assertion.assert_eq(ls.nth_exn(2), 3)?
  @assertion.assert_eq(ls.nth_exn(3), 4)?
  @assertion.assert_eq(ls.nth_exn(4), 5)?
}

/// Get nth element of the list or None if the index is out of bounds
pub fn nth[T](self : List[T], n : Int) -> Option[T] {
  loop self, n {
    Nil, _ => None
    Cons(head, _), 0 => Some(head)
    Cons(_, tail), n => continue tail, n - 1
  }
}

test "nth" {
  let ls = List::[1, 2, 3, 4, 5]
  @assertion.assert_eq(ls.nth(0), Some(1))?
  @assertion.assert_eq(ls.nth(1), Some(2))?
  @assertion.assert_eq(ls.nth(2), Some(3))?
  @assertion.assert_eq(ls.nth(3), Some(4))?
  @assertion.assert_eq(ls.nth(4), Some(5))?
  @assertion.assert_eq(ls.nth(5), None)?
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
  let ls = List::[1, 1, 1, 1, 1]
  @assertion.assert_eq(repeat(5, 1), ls)?
}

/// Insert separator to the list.
/// 
/// # Example
/// 
/// ```
/// let ls = from_array(["1", "2", "3", "4", "5"]).intersperse("|")
/// debug(ls) // output: from_array(["1", "|", "2", "|", "3", "|", "4", "|", "5"])
/// ```
pub fn intersperse[T](self : List[T], separator : T) -> List[T] {
  match self {
    Nil => Nil
    Cons(head, Nil) => Cons(head, Nil)
    Cons(head, tail) =>
      Cons(head, Cons(separator, intersperse(tail, separator)))
  }
}

test "intersperse" {
  let ls = List::["1", "|", "2", "|", "3", "|", "4", "|", "5"]
  let el : List[String] = Nil
  @assertion.assert_eq(List::["1", "2", "3", "4", "5"].intersperse("|"), ls)?
  @assertion.assert_eq(el.intersperse("|"), Nil)?
}

/// Check if the list is empty.
pub fn is_empty[T](self : List[T]) -> Bool {
  match self {
    Nil => true
    _ => false
  }
}

test "is_empty" {
  let ls = List::[1, 2, 3, 4, 5]
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
  let ls = List::[(1, 2), (3, 4), (5, 6)]
  let (a, b) = unzip(ls)
  @assertion.assert_eq(a, List::[1, 3, 5])?
  @assertion.assert_eq(b, List::[2, 4, 6])?
}

/// flatten a list of lists.
/// 
/// # Example
/// 
/// ```
/// let ls = flatten(from_array([from_array([1,2,3]), from_array([4,5,6]), from_array([7,8,9])]))
/// debug(ls) // output: from_array([1, 2, 3, 4, 5, 6, 7, 8, 9])
/// ```
pub fn flatten[T](self : List[List[T]]) -> List[T] {
  match self {
    Nil => Nil
    Cons(head, tail) => concat(head, flatten(tail))
  }
}

test "flatten" {
  let ls = List::[List::[1, 2, 3], List::[4, 5, 6], List::[7, 8, 9]]
  let rs = List::[1, 2, 3, 4, 5, 6, 7, 8, 9]
  @assertion.assert_eq(flatten(ls), rs)?
}

/// Get maximum element of the list.
/// @alert unsafe "Panic if the list is empty"
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
  let ls = List::[1, 123, 52, 3, 6, 0, -6, -76]
  @assertion.assert_eq(ls.maximum(), 123)?
}

/// Get minimum element of the list.
/// @alert unsafe "Panic if the list is empty"
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
  let ls = List::[1, 123, 52, 3, 6, 0, -6, -76]
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
  let ls = List::[1, 123, 52, 3, 6, 0, -6, -76]
  let rs = List::[-76, -6, 0, 1, 3, 6, 52, 123]
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
  loop self {
    Nil => false
    Cons(x, xs) => if x == value { true } else { continue xs }
  }
}

test "contain" {
  let ls = List::[1, 2, 3]
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
  f : (State) -> Option[(T, State)],
  ~init : State
) -> List[T] {
  match f(init) {
    Some((element, new_state)) => Cons(element, unfold(~init=new_state, f))
    None => Nil
  }
}

test "unfold" {
  let ls = unfold(
    ~init=0,
    fn { i => if i == 3 { None } else { Some((i, i + 1)) } },
  )
  @assertion.assert_eq(ls, Cons(0, Cons(1, Cons(2, Nil))))?
}

/// Take first n elements of the list.
///
/// # Example
///
/// ```
/// List::[1, 2, 3, 4, 5].take(3)
/// ```
pub fn take[T](self : List[T], n : Int) -> List[T] {
  if n <= 0 {
    Nil
  } else {
    unsafe_take(n, self)
  }
}

fn unsafe_take[T](n : Int, xs : List[T]) -> List[T] {
  match (n, xs) {
    (1, Cons(x, _)) => Cons(x, Nil)
    (_, Cons(x, xs)) => Cons(x, unsafe_take(n - 1, xs))
    _ => abort("take: index out of bounds")
  }
}

test "take" {
  let ls = List::[1, 2, 3, 4, 5].take(3)
  @assertion.assert_eq(ls, Cons(1, Cons(2, Cons(3, Nil))))?
  @assertion.assert_eq(ls.take(-1), Nil)?
  @assertion.assert_eq(ls.take(0), Nil)?
}

/// Drop first n elements of the list.
///
/// # Example
///
/// ```
/// List::[1, 2, 3, 4, 5].drop(3)
/// ```
pub fn drop[T](self : List[T], n : Int) -> List[T] {
  if n <= 0 {
    self
  } else {
    unsafe_drop(n, self)
  }
}

fn unsafe_drop[T](n : Int, xs : List[T]) -> List[T] {
  match (n, xs) {
    (1, Cons(_, xs)) => xs
    (_, Cons(_, xs)) => unsafe_drop(n - 1, xs)
    (x, _) => abort("drop: index out of bounds" + x.to_string())
  }
}

test "drop" {
  let ls = List::[1, 2, 3, 4, 5].drop(3)
  @assertion.assert_eq(ls, Cons(4, Cons(5, Nil)))?
  @assertion.assert_eq(ls.drop(-10), ls)?
  @assertion.assert_eq(ls.drop(0), ls)?
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
  let ls = take_while(List::[0, 1, 2, 3, 4], fn(x) { x < 3 })
  let ls2 : List[Int] = take_while(Nil, fn(_e) { true })
  @assertion.assert_eq(ls, Cons(0, Cons(1, Cons(2, Nil))))?
  @assertion.assert_eq(ls2, Nil)?
}

/// Drop the longest prefix of a list of elements that satisfies a given predicate.
///
/// # Example
///
/// ```
/// from_array([1, 2, 3, 4]).drop_while(fn(x) { x < 3 })
/// ```
pub fn drop_while[T](self : List[T], p : (T) -> Bool) -> List[T] {
  loop self {
    Nil => Nil
    Cons(x, xs) => if p(x) { continue xs } else { Cons(x, xs) }
  }
}

test "drop_while" {
  let ls = drop_while(List::[0, 1, 2, 3, 4], fn(x) { x < 3 })
  let ls2 : List[Int] = drop_while(Nil, fn(_e) { true })
  @assertion.assert_eq(ls, Cons(3, Cons(4, Nil)))?
  @assertion.assert_eq(ls2, Nil)?
}

/// Fold a list and return a list of successive reduced values from the left
///
/// # Example
///
/// ```
/// let ls = List::[1, 2, 3, 4, 5]
/// ls.scan_left(fn(acc, x) { acc + x }, ~init=0) 
/// ```
pub fn scan_left[T, E](self : List[T], f : (E, T) -> E, ~init : E) -> List[E] {
  Cons(
    init,
    match self {
      Nil => Nil
      Cons(x, xs) => xs.scan_left(f, ~init=f(init, x))
    },
  )
}

test "scan_left" {
  let ls = List::[1, 2, 3, 4, 5].scan_left(fn(acc, x) { acc + x }, ~init=0)
  let ls2 = List::[1, 2, 3, 4].scan_left(fn(acc, x) { acc - x }, ~init=100)
  @assertion.assert_eq(ls, List::[0, 1, 3, 6, 10, 15])?
  @assertion.assert_eq(ls2, List::[100, 99, 97, 94, 90])?
}

/// Fold a list and return a list of successive reduced values from the right
/// 
/// Note that the order of parameters on the accumulating function are reversed.
/// 
/// # Example
/// ```
/// let ls = List::[1, 2, 3, 4, 5]
/// ls.scan_right(fn(x, acc) { acc + x }, ~init=0)
/// ```
pub fn scan_right[T, E](self : List[T], f : (T, E) -> E, ~init : E) -> List[E] {
  match self {
    Nil => Cons(init, Nil)
    Cons(x, xs) => {
      let qs = xs.scan_right(f, ~init)
      Cons(f(x, qs.head_exn()), qs)
    }
  }
}

test "scan_right" {
  let ls = List::[1, 2, 3, 4].scan_right(fn(x, acc) { x + acc }, ~init=0)
  let ls2 = List::[1, 2, 3, 4].scan_right(fn(x, acc) { x - acc }, ~init=100)
  @assertion.assert_eq(ls, List::[10, 9, 7, 4, 0])?
  @assertion.assert_eq(ls2, List::[98, -97, 99, -96, 100])?
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
  loop self {
    Nil => None
    Cons((x, y), xs) => if x == v { Some(y) } else { continue xs }
  }
}

test "lookup" {
  let ls = List::[(1, "a"), (2, "b"), (3, "c")]
  @assertion.assert_eq(ls.lookup(3), Some("c"))?
  @assertion.assert_eq(ls.lookup(4), None)?
}

/// Find the first element in the list that satisfies f.
///
/// # Example
///
/// ```
/// println(List::[1, 3, 5, 8].find(fn(element) -> Bool { element % 2 == 0}))
/// // output: Some(8)
/// ```
pub fn find[T](self : List[T], f : (T) -> Bool) -> Option[T] {
  loop self {
    Nil => None
    Cons(element, list) =>
      if f(element) {
        Some(element)
      } else {
        continue list
      }
  }
}

test "find" {
  @assertion.assert_eq(
    List::[1, 3, 5, 8].find(fn(element) -> Bool { element % 2 == 0 }),
    Some(8),
  )?
  @assertion.assert_eq(
    List::[1, 3, 5, 7].find(fn(element) -> Bool { element % 2 == 0 }),
    None,
  )?
}

/// Find the first element in the list that satisfies f and passes the index as an argument.
///
/// # Example
///
/// ```
/// println(List::[1, 3, 5, 8].findi(fn(element) -> Bool { (element % 2 == 0) && (i == 3) }))
/// // output: Some(8)
///
/// println(List::[1, 3, 8, 5].findi(fn(element) -> Bool { (element % 2 == 0) && (i == 3) }))
/// // output: None
/// ```
pub fn findi[T](self : List[T], f : (T, Int) -> Bool) -> Option[T] {
  loop self, 0 {
    list, index =>
      match list {
        Nil => None
        Cons(element, list) =>
          if f(element, index) {
            Some(element)
          } else {
            continue list, index + 1
          }
      }
  }
}

test "findi" {
  @assertion.assert_eq(
    List::[1, 3, 5, 8].findi(
      fn(element, i) -> Bool { element % 2 == 0 && i == 3 },
    ),
    Some(8),
  )?
  @assertion.assert_eq(
    List::[1, 3, 8, 5].findi(
      fn(element, i) -> Bool { element % 2 == 0 && i == 3 },
    ),
    None,
  )?
}

/// Removes the element at the specified index in the list.
/// 
/// # Example
/// 
/// ```
/// println(List::[1, 2, 3, 4, 5].remove_at(2))
/// // output: from_array([1, 2, 4, 5])
/// ```
pub fn remove_at[T](self : List[T], index : Int) -> List[T] {
  match (index, self) {
    (0, Cons(_, tail)) => tail
    (_, Cons(head, tail)) => Cons(head, remove_at(tail, index - 1))
    (_, Nil) => Nil
    // abort("remove_at: index out of bounds")
  }
}

test "remove_at" {
  let ls = List::[1, 2, 3, 4, 5]
  let rs = List::[1, 2, 4, 5]
  @assertion.assert_eq(ls.remove_at(2), rs)?
  @assertion.assert_eq(ls.remove_at(0), List::[2, 3, 4, 5])?
  @assertion.assert_eq(
    List::["a", "b", "c", "d", "e"].remove_at(2),
    List::["a", "b", "d", "e"],
  )?
  @assertion.assert_eq(
    List::["a", "b", "c", "d", "e"].remove_at(5),
    List::["a", "b", "c", "d", "e"],
  )?
}

/// Removes the first occurrence of the specified element from the list, if it is present.
/// 
/// # Example
/// 
/// ```
/// println(List::[1, 2, 3, 4, 5].remove(3))
/// // output: from_array([1, 2, 4, 5])
/// ```
pub fn remove[T : Eq](self : List[T], elem : T) -> List[T] {
  match self {
    Nil => Nil
    Cons(head, tail) =>
      if head == elem {
        tail
      } else {
        Cons(head, remove(tail, elem))
      }
  }
}

test "remove" {
  @assertion.assert_eq(List::[1, 2, 3, 4, 5].remove(3), List::[1, 2, 4, 5])?
  @assertion.assert_eq(
    List::["a", "b", "c", "d", "e"].remove("c"),
    List::["a", "b", "d", "e"],
  )?
  @assertion.assert_eq(
    List::["a", "b", "c", "d", "e"].remove("f"),
    List::["a", "b", "c", "d", "e"],
  )?
}

/// Returns true if list starts with prefix.
///
/// # Example
/// 
/// ```
/// println(List::[1, 2, 3, 4, 5].is_prefix(List::[1, 2, 3]))
/// // output: true
/// ```
pub fn is_prefix[T : Eq](self : List[T], prefix : List[T]) -> Bool {
  match (self, prefix) {
    (_, Nil) => true
    (Nil, Cons(_)) => false
    (Cons(h1, t1), Cons(h2, t2)) => h1 == h2 && t1.is_prefix(t2)
  }
}

test "is_prefix" {
  @assertion.assert_true(List::[1, 2, 3, 4, 5].is_prefix(List::[1, 2, 3]))?
  @assertion.assert_false(List::[1, 2, 3, 4, 5].is_prefix(List::[3, 2, 3]))?
  @assertion.assert_false(List::Nil.is_prefix(List::[1, 2, 3]))?
}

/// Compares two lists for equality.
///
/// # Example
///
/// ```
/// println(List::[1, 2, 3].equal(List::[1, 2, 3]))
/// // output: true
/// ```
pub fn equal[T : Eq](self : List[T], other : List[T]) -> Bool {
  match (self, other) {
    (Nil, Nil) => true
    (Cons(h, t), Cons(h1, t1)) => h == h1 && t.equal(t1)
    _ => false
  }
}

test "equal" {
  @assertion.assert_true(List::[1, 2, 3].equal(List::[1, 2, 3]))?
  @assertion.assert_false(List::[1, 2, 3].equal(List::[1, 3, 3]))?
  @assertion.assert_false(List::Nil.equal(List::[1]))?
}

/// Returns true if list ends with suffix.
///
/// # Example
///
/// ```
/// println(List::[1, 2, 3, 4, 5].is_suffix(List::[3, 4, 5]))
/// // output: true
/// ```
pub fn is_suffix[T : Eq](self : List[T], suffix : List[T]) -> Bool {
  self.reverse().is_prefix(suffix.reverse())
}

test "is_suffix" {
  @assertion.assert_true(List::[1, 2, 3, 4, 5].is_suffix(List::[3, 4, 5]))?
  @assertion.assert_false(List::[1, 2, 3, 4, 5].is_suffix(List::[3, 4, 6]))?
}

/// Similar to intersperse but with a list of values.
/// 
/// # Example 
/// ```
/// let ls = List::[
///    List::[1, 2, 3],
///    List::[4, 5, 6],
///    List::[7, 8, 9],
/// ]
/// ls.intercalate(List::[0])
/// ```
pub fn intercalate[T](self : List[List[T]], sep : List[T]) -> List[T] {
  self.intersperse(sep).flatten()
}

test "intercalate" {
  let ls = List::[List::[1, 2, 3], List::[4, 5, 6], List::[7, 8, 9]]
  @assertion.assert_eq(
    ls.intercalate(List::[0]),
    List::[1, 2, 3, 0, 4, 5, 6, 0, 7, 8, 9],
  )?
}

/// The empty list
pub fn List::default[X]() -> List[X] {
  Nil
}

test "default" {
  let ls : List[Int] = List::default()
  @assertion.assert_eq(ls, Nil)?
}
