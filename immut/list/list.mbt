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

pub enum T[A] {
  Nil
  Cons(A, T[A])
} derive(Eq)

pub impl[A : Show] Show for T[A] with output(xs, logger) {
  logger.write_string("@list.of([")
  xs.eachi(
    fn(i, x) {
      if i > 0 {
        logger.write_string(", ")
      }
      x.output(logger)
    },
  )
  logger.write_string("])")
}

pub fn T::to_string[A : Show](xs : T[A]) -> String {
  Show::to_string(xs)
}

/// Convert array to list.
///
/// # Example
///
/// ```
/// let ls = @immut/list.of([1, 2, 3, 4, 5])
/// println(ls) // output: [1, 2, 3, 4, 5]
/// ```
pub fn T::from_array[A](arr : Array[A]) -> T[A] {
  for i = arr.length() - 1, list = Nil; i >= 0; {
    continue i - 1, Cons(arr[i], list)
  } else {
    list
  }
}

/// Get the length of the list.
pub fn length[A](self : T[A]) -> Int {
  loop self, 0 {
    Nil, len => len
    Cons(_, rest), acc => continue rest, acc + 1
  }
}

/// Iterates over the list.
///
/// # Example
///
/// ```
/// @immut/list.of([1, 2, 3, 4, 5]).each(print) 
/// ```
pub fn each[A](self : T[A], f : (A) -> Unit) -> Unit {
  loop self {
    Nil => ()
    Cons(head, tail) => {
      f(head)
      continue tail
    }
  }
}

/// Iterates over the list with index.
///
/// # Example
///
/// ```
/// @immut/list.of([1, 2, 3, 4, 5]).eachi(fn(i, x) { print("(\(i),\(x)) ") })
/// // output: (0,1) (1,2) (2,3) (3,4) (4,5)
/// ```
pub fn eachi[A](self : T[A], f : (Int, A) -> Unit) -> Unit {
  loop self, 0 {
    Nil, _ => ()
    Cons(x, xs), i => {
      f(i, x)
      continue xs, i + 1
    }
  }
}

/// Maps the list.
///
/// # Example
///
/// ```
/// debug(@immut/list.of([1, 2, 3, 4, 5]).map(fn(x){ x * 2}))
/// // output: of([2, 4, 6, 8, 10])
/// ```
pub fn map[A, B](self : T[A], f : (A) -> B) -> T[B] {
  match self {
    Nil => Nil
    Cons(head, tail) => Cons(f(head), map(tail, f))
  }
}

/// Maps the list with index.
pub fn mapi[A, B](self : T[A], f : (Int, A) -> B) -> T[B] {
  fn go(xs : T[A], i : Int, f : (Int, A) -> B) -> T[B] {
    match xs {
      Nil => Nil
      Cons(x, xs) => Cons(f(i, x), go(xs, i + 1, f))
    }
  }

  go(self, 0, f)
}

/// Convert list to array.
pub fn to_array[A](self : T[A]) -> Array[A] {
  match self {
    Nil => []
    Cons(head, _) => {
      let arr = Array::make(self.length(), head)
      self.eachi(fn(i, x) { arr[i] = x })
      arr
    }
  }
}

/// Filter the list.
///
/// # Example
///
/// ```
/// debug(of([1, 2, 3, 4, 5]).filter(fn(x){ x % 2 == 0}))
/// // output: from_array([2, 4])
/// ```
pub fn filter[A](self : T[A], f : (A) -> Bool) -> T[A] {
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

/// Test if all elements of the list satisfy the predicate.
pub fn all[A](self : T[A], f : (A) -> Bool) -> Bool {
  match self {
    Nil => true
    Cons(head, tail) => f(head) && all(tail, f)
  }
}

/// Test if any element of the list satisfies the predicate.
pub fn any[A](self : T[A], f : (A) -> Bool) -> Bool {
  match self {
    Nil => false
    Cons(head, tail) => f(head) || any(tail, f)
  }
}

/// Tail of the list.
///
/// # Example
///
/// ```
/// debug(of([1, 2, 3, 4, 5]).tail())
/// // output: from_array([2, 3, 4, 5])
/// ```
pub fn tail[A](self : T[A]) -> T[A] {
  match self {
    Nil => Nil
    Cons(_, tail) => tail
  }
}

/// Get first element of the list.
///
/// # Example
///
/// ```
/// debug(of([1, 2, 3, 4, 5]).head_exn())
/// // output: 1
/// ```
/// @alert unsafe "Panic if the list is empty"
pub fn head_exn[A](self : T[A]) -> A {
  match self {
    Nil => abort("head of empty list")
    Cons(head, _) => head
  }
}

/// Get first element of the list.
///
/// # Example
///
/// ```
/// debug(of([1, 2, 3, 4, 5]).head())
/// // output: Some(1)
/// debug(from_array([]).head())
/// // output: None
/// ```
pub fn head[A](self : T[A]) -> A? {
  match self {
    Nil => None
    Cons(head, _) => Some(head)
  }
}

/// Last element of the list.
///
/// # Example
///
/// ```
/// debug(of([1, 2, 3, 4, 5]).last())
/// // output: 5
/// ```
/// @alert unsafe "Panic if the list is empty"
pub fn last[A](self : T[A]) -> A {
  loop self {
    Nil => abort("last of empty list")
    Cons(head, Nil) => head
    Cons(_, tail) => continue tail
  }
}

/// Init of the list.
///
/// # Example
///
/// ```
/// debug(of([1, 2, 3, 4, 5]).init_())
/// // output: from_array([1, 2, 3, 4])
/// ```
pub fn init_[A](self : T[A]) -> T[A] {
  match self {
    Nil => Nil
    Cons(_, Nil) => Nil
    Cons(head, tail) => Cons(head, init_(tail))
  }
}

/// Concatenate two lists.
///
/// # Example
///
/// ```
/// let ls = of([1, 2, 3, 4, 5]).concat(from_array([6, 7, 8, 9, 10]))
/// debug(ls) // output: from_array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
/// ```
pub fn concat[A](self : T[A], other : T[A]) -> T[A] {
  match self {
    Nil => other
    Cons(head, tail) => Cons(head, concat(tail, other))
  }
}

/// Reverse the list.
///
/// # Example
///
/// ```
/// debug(@list.of([1, 2, 3, 4, 5]).rev())
/// // output: from_array([5, 4, 3, 2, 1])
/// ```
pub fn rev[A](self : T[A]) -> T[A] {
  loop self, (Nil : T[A]) {
    xs, ys =>
      match (xs, ys) {
        (Nil, acc) => acc
        (Cons(x, xs), acc) => continue xs, Cons(x, acc)
      }
  }
}

/// Fold the list from left.
///
/// # Example
///
/// ```
/// let r = of([1, 2, 3, 4, 5]).fold_left(~init=0, fn(acc, x) { acc + x })
/// debug(r) // output: 15
/// ```
pub fn fold_left[A, B](self : T[A], f : (B, A) -> B, ~init : B) -> B {
  match self {
    Nil => init
    Cons(head, tail) => tail.fold_left(f, init=f(init, head))
  }
}

/// Fold the list from right.
///
/// # Example
/// ```
/// let r = of([1, 2, 3, 4, 5]).fold_right(fn(x, acc) { x + acc }, ~init=0)
/// ```
pub fn fold_right[A, B](self : T[A], f : (A, B) -> B, ~init : B) -> B {
  match self {
    Nil => init
    Cons(head, tail) => f(head, tail.fold_right(f, ~init))
  }
}

/// Fold the list from left with index.
pub fn fold_lefti[A, B](self : T[A], f : (Int, B, A) -> B, ~init : B) -> B {
  fn go(xs : T[A], i : Int, f : (Int, B, A) -> B, acc : B) -> B {
    match xs {
      Nil => acc
      Cons(x, xs) => go(xs, i + 1, f, f(i, acc, x))
    }
  }

  go(self, 0, f, init)
}

/// Fold the list from right with index.
pub fn fold_righti[A, B](self : T[A], f : (Int, A, B) -> B, ~init : B) -> B {
  fn go(xs : T[A], i : Int, f : (Int, A, B) -> B, acc : B) -> B {
    match xs {
      Nil => acc
      Cons(x, xs) => f(i, x, go(xs, i + 1, f, acc))
    }
  }

  go(self, 0, f, init)
}

/// Zip two lists.
///
/// # Example
///
/// ```
/// let r = zip(of([1, 2, 3, 4, 5]), from_array([6, 7, 8, 9, 10]))
/// debug(r) // output: from_array([(1, 6), (2, 7), (3, 8), (4, 9), (5, 10)]
/// ```
///
/// @alert unsafe "Panic if the two lists have different lengths."
pub fn zip[A, B](self : T[A], other : T[B]) -> T[(A, B)] {
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
pub fn concat_map[A, B](self : T[A], f : (A) -> T[B]) -> T[B] {
  match self {
    Nil => Nil
    Cons(head, tail) => concat(f(head), concat_map(tail, f))
  }
}

/// Get nth element of the list
/// @alert unsafe "Panic if the index is out of bounds"
pub fn nth_exn[A](self : T[A], n : Int) -> A {
  loop self, n {
    Nil, _ => abort("nth: index out of bounds")
    Cons(head, _), 0 => head
    Cons(_, tail), n => continue tail, n - 1
  }
}

/// Get nth element of the list or None if the index is out of bounds
pub fn nth[A](self : T[A], n : Int) -> A? {
  loop self, n {
    Nil, _ => None
    Cons(head, _), 0 => Some(head)
    Cons(_, tail), n => continue tail, n - 1
  }
}

/// Create a list of length n with the given value
///
/// # Example
///
/// ```
/// debug(repeat(5, 1)) // output: from_array([1, 1, 1, 1, 1])
/// ```
pub fn repeat[A](n : Int, x : A) -> T[A] {
  if n == 0 {
    Nil
  } else {
    Cons(x, repeat(n - 1, x))
  }
}

/// Insert separator to the list.
///
/// # Example
///
/// ```
/// let ls = from_array(["1", "2", "3", "4", "5"]).intersperse("|")
/// debug(ls) // output: from_array(["1", "|", "2", "|", "3", "|", "4", "|", "5"])
/// ```
pub fn intersperse[A](self : T[A], separator : A) -> T[A] {
  match self {
    Nil => Nil
    Cons(head, Nil) => Cons(head, Nil)
    Cons(head, tail) =>
      Cons(head, Cons(separator, intersperse(tail, separator)))
  }
}

/// Check if the list is empty.
pub fn is_empty[A](self : T[A]) -> Bool {
  match self {
    Nil => true
    _ => false
  }
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
pub fn unzip[A, B](list : T[(A, B)]) -> (T[A], T[B]) {
  match list {
    Nil => (Nil, Nil)
    Cons((x, y), xs) => {
      let (xs, ys) = unzip(xs)
      (Cons(x, xs), Cons(y, ys))
    }
  }
}

/// flatten a list of lists.
///
/// # Example
///
/// ```
/// let ls = flatten(from_array([from_array([1,2,3]), from_array([4,5,6]), from_array([7,8,9])]))
/// debug(ls) // output: from_array([1, 2, 3, 4, 5, 6, 7, 8, 9])
/// ```
pub fn flatten[A](self : T[T[A]]) -> T[A] {
  match self {
    Nil => Nil
    Cons(head, tail) => concat(head, flatten(tail))
  }
}

/// Get maximum element of the list.
/// @alert unsafe "Panic if the list is empty"
pub fn maximum[A : Compare](self : T[A]) -> A {
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

/// Get minimum element of the list.
/// @alert unsafe "Panic if the list is empty"
pub fn minimum[A : Compare](self : T[A]) -> A {
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

/// Sort the list in ascending order.
///
/// # Example
///
/// ```
/// let ls = sort(from_array([1,123,52,3,6,0,-6,-76]))
/// debug(ls) // output: from_array([-76, -6, 0, 1, 3, 6, 52, 123])
/// ```
pub fn sort[A : Compare](self : T[A]) -> T[A] {
  match self {
    Nil => Nil
    Cons(x, xs) => {
      let smaller = filter(xs, fn(y) { y < x })
      let greater = filter(xs, fn(y) { y >= x })
      concat(sort(smaller), Cons(x, sort(greater)))
    }
  }
}

/// Concatenate two lists.
///
/// `a + b` equal to `a.concat(b)`
pub fn op_add[A](self : T[A], other : T[A]) -> T[A] {
  self.concat(other)
}

/// Check if the list contains the value.
pub fn contains[A : Eq](self : T[A], value : A) -> Bool {
  loop self {
    Nil => false
    Cons(x, xs) => if x == value { true } else { continue xs }
  }
}

/// Produces a collection iteratively.
///
/// # Example
///
/// ```
/// // from_array([0, 1, 2])
/// unfold(0, fn { i => if i == 3 { None } else { Some(i, i + 1) } }) |> debug
/// ```
pub fn unfold[A, S](f : (S) -> (A, S)?, ~init : S) -> T[A] {
  match f(init) {
    Some((element, new_state)) => Cons(element, unfold(init=new_state, f))
    None => Nil
  }
}

/// Take first n elements of the list.
///
/// # Example
///
/// ```
/// of([1, 2, 3, 4, 5]).take(3)
/// ```
pub fn take[A](self : T[A], n : Int) -> T[A] {
  if n <= 0 {
    Nil
  } else {
    unsafe_take(n, self)
  }
}

fn unsafe_take[A](n : Int, xs : T[A]) -> T[A] {
  match (n, xs) {
    (1, Cons(x, _)) => Cons(x, Nil)
    (_, Cons(x, xs)) => Cons(x, unsafe_take(n - 1, xs))
    _ => abort("take: index out of bounds")
  }
}

/// Drop first n elements of the list.
///
/// # Example
///
/// ```
/// of([1, 2, 3, 4, 5]).drop(3)
/// ```
pub fn drop[A](self : T[A], n : Int) -> T[A] {
  if n <= 0 {
    self
  } else {
    unsafe_drop(n, self)
  }
}

fn unsafe_drop[A](n : Int, xs : T[A]) -> T[A] {
  match (n, xs) {
    (1, Cons(_, xs)) => xs
    (_, Cons(_, xs)) => unsafe_drop(n - 1, xs)
    (x, _) => abort("drop: index out of bounds" + x.to_string())
  }
}

/// Take the longest prefix of a list of elements that satisfies a given predicate.
///
/// # Example
///
/// ```
/// from_array([1, 2, 3, 4]).take_while(fn(x) { x < 3 })
/// ```
pub fn take_while[A](self : T[A], p : (A) -> Bool) -> T[A] {
  match self {
    Nil => Nil
    Cons(x, xs) => if p(x) { Cons(x, xs.take_while(p)) } else { Nil }
  }
}

/// Drop the longest prefix of a list of elements that satisfies a given predicate.
///
/// # Example
///
/// ```
/// from_array([1, 2, 3, 4]).drop_while(fn(x) { x < 3 })
/// ```
pub fn drop_while[A](self : T[A], p : (A) -> Bool) -> T[A] {
  loop self {
    Nil => Nil
    Cons(x, xs) => if p(x) { continue xs } else { Cons(x, xs) }
  }
}

/// Fold a list and return a list of successive reduced values from the left
///
/// # Example
///
/// ```
/// let ls = of([1, 2, 3, 4, 5])
/// ls.scan_left(fn(acc, x) { acc + x }, ~init=0)
/// ```
pub fn scan_left[A, E](self : T[A], f : (E, A) -> E, ~init : E) -> T[E] {
  Cons(
    init,
    match self {
      Nil => Nil
      Cons(x, xs) => xs.scan_left(f, init=f(init, x))
    },
  )
}

/// Fold a list and return a list of successive reduced values from the right
///
/// Note that the order of parameters on the accumulating function are reversed.
///
/// # Example
/// ```
/// let ls = of([1, 2, 3, 4, 5])
/// ls.scan_right(fn(x, acc) { acc + x }, ~init=0)
/// ```
pub fn scan_right[A, B](self : T[A], f : (A, B) -> B, ~init : B) -> T[B] {
  match self {
    Nil => Cons(init, Nil)
    Cons(x, xs) => {
      let qs = xs.scan_right(f, ~init)
      Cons(f(x, qs.head_exn()), qs)
    }
  }
}

/// Looks up a key in an association list.
///
/// # Example
///
/// ```
/// let ls = from_array([(1, "a"), (2, "b"), (3, "c")])
/// ls.lookup(3) // output: Some("c")
/// ```
pub fn lookup[A : Eq, B](self : T[(A, B)], v : A) -> B? {
  loop self {
    Nil => None
    Cons((x, y), xs) => if x == v { Some(y) } else { continue xs }
  }
}

/// Find the first element in the list that satisfies f.
///
/// # Example
///
/// ```
/// println(of([1, 3, 5, 8]).find(fn(element) -> Bool { element % 2 == 0}))
/// // output: Some(8)
/// ```
pub fn find[A](self : T[A], f : (A) -> Bool) -> A? {
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

/// Find the first element in the list that satisfies f and passes the index as an argument.
///
/// # Example
///
/// ```
/// println(of([1, 3, 5, 8]).findi(fn(element) -> Bool { (element % 2 == 0) && (i == 3) }))
/// // output: Some(8)
///
/// println(of([1, 3, 8, 5]).findi(fn(element) -> Bool { (element % 2 == 0) && (i == 3) }))
/// // output: None
/// ```
pub fn findi[A](self : T[A], f : (A, Int) -> Bool) -> A? {
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

/// Removes the element at the specified index in the list.
///
/// # Example
///
/// ```
/// println(of([1, 2, 3, 4, 5]).remove_at(2))
/// // output: from_array([1, 2, 4, 5])
/// ```
pub fn remove_at[A](self : T[A], index : Int) -> T[A] {
  match (index, self) {
    (0, Cons(_, tail)) => tail
    (_, Cons(head, tail)) => Cons(head, remove_at(tail, index - 1))
    (_, Nil) => Nil
    // abort("remove_at: index out of bounds")
  }
}

/// Removes the first occurrence of the specified element from the list, if it is present.
///
/// # Example
///
/// ```
/// println(of([1, 2, 3, 4, 5]).remove(3))
/// // output: from_array([1, 2, 4, 5])
/// ```
pub fn remove[A : Eq](self : T[A], elem : A) -> T[A] {
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

/// Returns true if list starts with prefix.
///
/// # Example
///
/// ```
/// println(of([1, 2, 3, 4, 5]).is_prefix(of([1, 2, 3])))
/// // output: true
/// ```
pub fn is_prefix[A : Eq](self : T[A], prefix : T[A]) -> Bool {
  match (self, prefix) {
    (_, Nil) => true
    (Nil, Cons(_)) => false
    (Cons(h1, t1), Cons(h2, t2)) => h1 == h2 && t1.is_prefix(t2)
  }
}

/// Compares two lists for equality.
///
/// # Example
///
/// ```
/// println(of([1, 2, 3]).equal(of([1, 2, 3])))
/// // output: true
/// ```
pub fn equal[A : Eq](self : T[A], other : T[A]) -> Bool {
  match (self, other) {
    (Nil, Nil) => true
    (Cons(h, t), Cons(h1, t1)) => h == h1 && t.equal(t1)
    _ => false
  }
}

/// Returns true if list ends with suffix.
///
/// # Example
///
/// ```
/// println(of([1, 2, 3, 4, 5]).is_suffix(of([3, 4, 5])))
/// // output: true
/// ```
pub fn is_suffix[A : Eq](self : T[A], suffix : T[A]) -> Bool {
  self.rev().is_prefix(suffix.rev())
}

/// Similar to intersperse but with a list of values.
///
/// # Example
/// ```
/// let ls = List::[
///    of([1, 2, 3]),
///    of([4, 5, 6]),
///    of([7, 8, 9]),
/// ]
/// ls.intercalate(of([0]))
/// ```
pub fn intercalate[A](self : T[T[A]], sep : T[A]) -> T[A] {
  self.intersperse(sep).flatten()
}

/// The empty list
pub fn T::default[X]() -> T[X] {
  Nil
}

pub fn iter[A](self : T[A]) -> Iter[A] {
  Iter::new(
    fn(yield) {
      loop self {
        Nil => IterContinue
        Cons(head, tail) => {
          if yield(head) == IterEnd {
            break IterEnd
          }
          continue tail
        }
      }
    },
  )
}

pub fn T::of[A](arr : FixedArray[A]) -> T[A] {
  for i = arr.length() - 1, list = Nil; i >= 0; {
    continue i - 1, Cons(arr[i], list)
  } else {
    list
  }
}

test "panic unsafe_drop" {
  unsafe_drop(5, of([1, 2, 3, 4])) |> ignore
}

test "panic unsafe_take" {
  unsafe_take(5, of([1, 2, 3, 4])) |> ignore
}
