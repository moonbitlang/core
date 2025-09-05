// Copyright 2025 International Digital Economy Academy
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
#deprecated("use `@list` instead")
pub fn[A] add(self : T[A], head : A) -> T[A] {
  Cons(head, self)
}

///|
pub impl[A : Show] Show for T[A] with output(xs, logger) {
  logger.write_iter(xs.iter(), prefix="@list.of([", suffix="])")
}

///|
pub impl[A : ToJson] ToJson for T[A] with to_json(self) {
  let capacity = self.length()
  guard capacity != 0 else { return [] }
  let jsons = Array::new(capacity~)
  for a in self {
    jsons.push(a.to_json())
  }
  Json::array(jsons)
}

///|
#deprecated("use `@list` instead")
pub fn[A : ToJson] to_json(self : T[A]) -> Json {
  ToJson::to_json(self)
}

///|
pub impl[A : @json.FromJson] @json.FromJson for T[A] with from_json(json, path) {
  guard json is Array(arr) else {
    raise @json.JsonDecodeError((path, "@immut/list.from_json: expected array"))
  }
  for i = arr.length() - 1, list = Nil; i >= 0; {
    continue i - 1, list.add(A::from_json(arr[i], path.add_index(i)))
  } else {
    list
  }
}

///|
#deprecated("use `@list` instead")
pub fn[A : @json.FromJson] from_json(
  json : Json,
) -> T[A] raise @json.JsonDecodeError {
  @json.from_json(json)
}

///|
/// Convert array to list.
///
/// # Example
///
/// ```mbt
///   let ls = @list.of([1, 2, 3, 4, 5])
///   assert_eq(ls, @list.from_array([1, 2, 3, 4, 5]))
/// ```
#deprecated("use `@list` instead")
pub fn[A] from_array(arr : Array[A]) -> T[A] {
  for i = arr.length() - 1, list = Nil; i >= 0; {
    continue i - 1, Cons(arr[i], list)
  } else {
    list
  }
}

///|
/// Get the length of the list.
#deprecated("use `@list` instead")
pub fn[A] length(self : T[A]) -> Int {
  loop (self, 0) {
    (Nil, len) => len
    (Cons(_, rest), acc) => continue (rest, acc + 1)
  }
}

///|
/// Iterates over the list.
///
/// # Example
///
/// ```mbt
///   let arr = []
///   @list.of([1, 2, 3, 4, 5]).each((x) => { arr.push(x) })
///   assert_eq(arr, [1, 2, 3, 4, 5])
/// ```
#deprecated("use `@list` instead")
pub fn[A] each(self : T[A], f : (A) -> Unit raise?) -> Unit raise? {
  loop self {
    Nil => ()
    Cons(head, tail) => {
      f(head)
      continue tail
    }
  }
}

///|
/// Iterates over the list with index.
///
/// # Example
///
/// ```mbt
///   let arr = []
///   @list.of([1, 2, 3, 4, 5]).eachi((i, x) => { arr.push("(\{i},\{x})") })
///   assert_eq(arr, ["(0,1)", "(1,2)", "(2,3)", "(3,4)", "(4,5)"])
/// ```
#deprecated("use `@list` instead")
pub fn[A] eachi(self : T[A], f : (Int, A) -> Unit raise?) -> Unit raise? {
  loop (self, 0) {
    (Nil, _) => ()
    (Cons(x, xs), i) => {
      f(i, x)
      continue (xs, i + 1)
    }
  }
}

///|
/// Maps the list.
///
/// # Example
///
/// ```mbt
///   assert_eq(@list.of([1, 2, 3, 4, 5]).map((x) => { x * 2}), @list.of([2, 4, 6, 8, 10]))
/// ```
#deprecated("use `@list` instead")
pub fn[A, B] map(self : T[A], f : (A) -> B) -> T[B] {
  match self {
    Nil => Nil
    Cons(head, tail) => Cons(f(head), tail.map(f))
  }
}

///|
/// Maps the list with index.
#deprecated("use `@list` instead")
pub fn[A, B] mapi(self : T[A], f : (Int, A) -> B raise?) -> T[B] raise? {
  fn go(xs : T[A], i : Int, f : (Int, A) -> B raise?) -> T[B] raise? {
    match xs {
      Nil => Nil
      Cons(x, xs) => Cons(f(i, x), go(xs, i + 1, f))
    }
  }

  go(self, 0, f)
}

///|
/// Maps the list and reverses the result.
///
/// `list.rev_map(f)` is equivalent to `list.map(f).rev()` but more efficient.
///
/// # Example
/// ```mbt
///   assert_eq(@list.of([1, 2, 3, 4, 5]).rev_map((x) => { x * 2 }), @list.of([10, 8, 6, 4, 2]))
/// ```
#deprecated("use `@list` instead")
pub fn[A, B] rev_map(self : T[A], f : (A) -> B raise?) -> T[B] raise? {
  loop (Nil, self) {
    (acc, Nil) => acc
    (acc, Cons(x, xs)) => continue (Cons(f(x), acc), xs)
  }
}

///|
/// Convert list to array.
#deprecated("use `@list` instead")
pub fn[A] to_array(self : T[A]) -> Array[A] {
  match self {
    Nil => []
    Cons(x, xs) => {
      let arr = [x]
      loop xs {
        Nil => ()
        Cons(x, xs) => {
          arr.push(x)
          continue xs
        }
      }
      arr
    }
  }
}

///|
/// Filter the list.
///
/// # Example
///
/// ```mbt
///   assert_eq(@list.of([1, 2, 3, 4, 5]).filter((x) => { x % 2 == 0}), @list.of([2, 4]))
/// ```
#deprecated("use `@list` instead")
pub fn[A] filter(self : T[A], f : (A) -> Bool raise?) -> T[A] raise? {
  match self {
    Nil => Nil
    Cons(head, tail) =>
      if f(head) {
        Cons(head, tail.filter(f))
      } else {
        tail.filter(f)
      }
  }
}

///|
/// Test if all elements of the list satisfy the predicate.
#deprecated("use `@list` instead")
pub fn[A] all(self : T[A], f : (A) -> Bool raise?) -> Bool raise? {
  loop self {
    Nil => true
    Cons(head, tail) => if f(head) { continue tail } else { false }
  }
}

///|
/// Test if any element of the list satisfies the predicate.
#deprecated("use `@list` instead")
pub fn[A] any(self : T[A], f : (A) -> Bool raise?) -> Bool raise? {
  match self {
    Nil => false
    Cons(head, tail) => f(head) || tail.any(f)
  }
}

///|
/// Tail of the list.
///
/// # Example
///
/// ```mbt
///   assert_eq(@list.of([1, 2, 3, 4, 5]).tail(), @list.of([2, 3, 4, 5]))
/// ```
#deprecated("use `@list` instead")
pub fn[A] tail(self : T[A]) -> T[A] {
  match self {
    Nil => Nil
    Cons(_, tail) => tail
  }
}

///|
/// Get first element of the list.
#internal(unsafe, "Panic if the list is empty")
#deprecated("use `@list` instead")
pub fn[A] unsafe_head(self : T[A]) -> A {
  match self {
    Nil => abort("head of empty list")
    Cons(head, _) => head
  }
}

///|
#coverage.skip
#deprecated("use `@list` instead")
pub fn[A] head_exn(self : T[A]) -> A {
  self.unsafe_head()
}

///|
/// Get first element of the list.
///
/// # Example
///
/// ```mbt
///   assert_eq(@list.of([1, 2, 3, 4, 5]).head(), Some(1))
/// ```
#deprecated("use `@list` instead")
pub fn[A] head(self : T[A]) -> A? {
  match self {
    Nil => None
    Cons(head, _) => Some(head)
  }
}

///|
#internal(unsafe, "Panic if the list is empty")
#deprecated("use `@list` instead")
pub fn[A] unsafe_last(self : T[A]) -> A {
  loop self {
    Nil => abort("last of empty list")
    Cons(head, Nil) => head
    Cons(_, tail) => continue tail
  }
}

///|
/// Last element of the list.
///
/// # Example
///
/// ```mbt
///   assert_eq(@list.of([1, 2, 3, 4, 5]).last(), Some(5))
/// ```
#deprecated("use `@list` instead")
pub fn[A] last(self : T[A]) -> A? {
  loop self {
    Nil => None
    Cons(head, Nil) => Some(head)
    Cons(_, tail) => continue tail
  }
}

///|
/// Concatenate two lists.
///
/// # Example
///
/// ```mbt
///   let ls = @list.of([1, 2, 3, 4, 5]).concat(@list.of([6, 7, 8, 9, 10]))
///   assert_eq(ls, @list.of([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]))
/// ```
#deprecated("use `@list` instead")
pub fn[A] concat(self : T[A], other : T[A]) -> T[A] {
  match self {
    Nil => other
    Cons(head, tail) => Cons(head, tail.concat(other))
  }
}

///|
/// Reverse the first list and concatenate it with the second.
///
/// # Example
///
/// ```mbt
///   let ls = @list.of([1, 2, 3, 4, 5]).rev_concat(@list.of([6, 7, 8, 9, 10]))
///   assert_eq(ls, @list.of([5, 4, 3, 2, 1, 6, 7, 8, 9, 10]))
/// ```
#deprecated("use `@list` instead")
pub fn[A] rev_concat(self : T[A], other : T[A]) -> T[A] {
  loop (self, other) {
    (Nil, other) => other
    (Cons(head, tail), other) => continue (tail, Cons(head, other))
  }
}

///|
/// Reverse the list.
///
/// # Example
///
/// ```mbt
///   assert_eq(@list.of([1, 2, 3, 4, 5]).rev(), @list.of([5, 4, 3, 2, 1]))
/// ```
#deprecated("use `@list` instead")
pub fn[A] rev(self : T[A]) -> T[A] {
  self.rev_concat(Nil)
}

///|
/// Fold the list from left.
///
/// # Example
///
/// ```mbt
///   let r = @list.of([1, 2, 3, 4, 5]).fold(init=0, (acc, x) => { acc + x })
///   inspect(r, content="15")
/// ```
#deprecated("use `@list` instead")
pub fn[A, B] fold(self : T[A], init~ : B, f : (B, A) -> B raise?) -> B raise? {
  match self {
    Nil => init
    Cons(head, tail) => tail.fold(f, init=f(init, head))
  }
}

///|
/// Fold the list from right.
///
/// # Example
/// ```mbt
///   let r = @list.of([1, 2, 3, 4, 5]).rev_fold((x, acc) => { x + acc }, init=0)
///   inspect(r, content="15")
/// ```
#deprecated("use `@list` instead")
pub fn[A, B] rev_fold(
  self : T[A],
  init~ : B,
  f : (A, B) -> B raise?,
) -> B raise? {
  let xs = self.to_array()
  let mut acc = init
  for x in xs.rev_iter() {
    acc = f(x, acc)
  }
  acc
}

///|
/// Fold the list from left.
///
/// # Example
///
/// ```mbt
///   let r = @list.of([1, 2, 3, 4, 5]).fold(init=0, (acc, x) => { acc + x })
///   inspect(r, content="15")
/// ```
#coverage.skip
#deprecated("use `@list` instead")
pub fn[A, B] fold_left(
  self : T[A],
  f : (B, A) -> B raise?,
  init~ : B,
) -> B raise? {
  self.fold(init~, f)
}

///|
#coverage.skip
#deprecated("use `@list.rev_fold` instead")
pub fn[A, B] fold_right(
  self : T[A],
  f : (A, B) -> B raise?,
  init~ : B,
) -> B raise? {
  match self {
    Nil => init
    Cons(head, tail) => f(head, tail.rev_fold(f, init~))
  }
}

///|
/// Fold the list from left with index.
#deprecated("use `@list` instead")
pub fn[A, B] foldi(
  self : T[A],
  init~ : B,
  f : (Int, B, A) -> B raise?,
) -> B raise? {
  fn go(xs : T[A], i : Int, f : (Int, B, A) -> B raise?, acc : B) -> B raise? {
    match xs {
      Nil => acc
      Cons(x, xs) => go(xs, i + 1, f, f(i, acc, x))
    }
  }

  go(self, 0, f, init)
}

///|
/// Fold the list from right with index.
#deprecated("use `@list` instead")
pub fn[A, B] rev_foldi(
  self : T[A],
  init~ : B,
  f : (Int, A, B) -> B raise?,
) -> B raise? {
  fn go(xs : T[A], i : Int, f : (Int, A, B) -> B raise?, acc : B) -> B raise? {
    match xs {
      Nil => acc
      Cons(x, xs) => f(i, x, go(xs, i + 1, f, acc))
    }
  }

  go(self, 0, f, init)
}

///|
/// Fold the list from left with index.
#deprecated("use `@list.foldi` instead")
pub fn[A, B] fold_lefti(
  self : T[A],
  f : (Int, B, A) -> B raise?,
  init~ : B,
) -> B raise? {
  fn go(xs : T[A], i : Int, f : (Int, B, A) -> B raise?, acc : B) -> B raise? {
    match xs {
      Nil => acc
      Cons(x, xs) => go(xs, i + 1, f, f(i, acc, x))
    }
  }

  go(self, 0, f, init)
}

///|
/// Fold the list from right with index.
#deprecated("use `@list.rev_foldi` instead")
pub fn[A, B] fold_righti(
  self : T[A],
  f : (Int, A, B) -> B raise?,
  init~ : B,
) -> B raise? {
  fn go(xs : T[A], i : Int, f : (Int, A, B) -> B raise?, acc : B) -> B raise? {
    match xs {
      Nil => acc
      Cons(x, xs) => f(i, x, go(xs, i + 1, f, acc))
    }
  }

  go(self, 0, f, init)
}

///|
/// Zip two lists.
/// If the lists have different lengths, it will return None.
///
/// # Example
///
/// ```mbt
///   let r = @list.of([1, 2, 3, 4, 5]).zip(@list.of([6, 7, 8, 9, 10]))
///   assert_eq(r, Some(@list.from_array([(1, 6), (2, 7), (3, 8), (4, 9), (5, 10)])))
/// ```
#deprecated("use `@list` instead")
pub fn[A, B] zip(self : T[A], other : T[B]) -> T[(A, B)]? {
  let mut acc = Nil
  let res = loop (self, other) {
    (Nil, Nil) => break Some(acc)
    (Cons(x, xs), Cons(y, ys)) => {
      acc = Cons((x, y), acc)
      continue (xs, ys)
    }
    (_, _) => break None
  }
  res.map(T::rev)
}

///|
/// map over the list and concat all results.
///
/// `concat_map(f, ls)` equal to `ls.map(f).fold(Nil, (acc, x) => { acc.concat(x) })))`
///
/// # Example
///
/// ```mbt
///   let ls = @list.from_array([1, 2, 3])
///   let r = ls.flat_map((x) => { @list.from_array([x, x * 2]) })
///   assert_eq(r, @list.from_array([1, 2, 2, 4, 3, 6]))
/// ```
#deprecated("use `@list` instead")
pub fn[A, B] concat_map(self : T[A], f : (A) -> T[B]) -> T[B] {
  self.flat_map(f)
}

///|
/// map over the list and concat all results.
///
/// `flat_map(f, ls)` equal to `ls.map(f).fold(Nil, (acc, x) => { acc.concat(x) })))`
///
/// # Example
///
/// ```mbt
///   let ls = @list.from_array([1, 2, 3])
///   let r = ls.flat_map((x) => { @list.from_array([x, x * 2]) })
///   assert_eq(r, @list.from_array([1, 2, 2, 4, 3, 6]))
/// ```
#deprecated("use `@list` instead")
pub fn[A, B] flat_map(self : T[A], f : (A) -> T[B] raise?) -> T[B] raise? {
  match self {
    Nil => Nil
    Cons(head, tail) => f(head).concat(tail.flat_map(f))
  }
}

///|
/// Map over the list and keep all `value`s for which the mapped result is `Some(value)`.
///
/// # Example
///
/// ```mbt
///   let ls = @list.of([4, 2, 2, 6, 3, 1])
///   let r = ls.filter_map((x) => { if (x >= 3) { Some(x) } else { None } })
///   assert_eq(r, @list.of([4, 6, 3]))
/// ```
#deprecated("use `@list` instead")
pub fn[A, B] filter_map(self : T[A], f : (A) -> B?) -> T[B] {
  loop (Nil, self) {
    (acc, Nil) => acc.rev()
    (acc, Cons(x, xs)) =>
      match f(x) {
        Some(v) => continue (acc.add(v), xs)
        None => continue (acc, xs)
      }
  }
}

///|
#internal(unsafe, "Panic if the index is out of bounds")
#deprecated("use `@list` instead")
pub fn[A] unsafe_nth(self : T[A], n : Int) -> A {
  loop (self, n) {
    (Nil, _) => abort("nth: index out of bounds")
    (Cons(head, _), 0) => head
    (Cons(_, tail), n) => continue (tail, n - 1)
  }
}

///|
#deprecated("use `@list` instead")
pub fn[A] nth_exn(self : T[A], n : Int) -> A {
  self.unsafe_nth(n)
}

///|
/// Get nth element of the list or None if the index is out of bounds
#deprecated("use `@list` instead")
pub fn[A] nth(self : T[A], n : Int) -> A? {
  loop (self, n) {
    (Nil, _) => None
    (Cons(head, _), 0) => Some(head)
    (Cons(_, tail), n) => continue (tail, n - 1)
  }
}

///|
/// Create a list of length n with the given value
///
/// # Example
///
/// ```mbt
///   assert_eq(@list.repeat(5, 1), @list.from_array([1, 1, 1, 1, 1]))
/// ```
#deprecated("use `@list` instead")
pub fn[A] repeat(n : Int, x : A) -> T[A] {
  if n == 0 {
    Nil
  } else {
    Cons(x, repeat(n - 1, x))
  }
}

///|
/// Insert separator to the list.
///
/// # Example
///
/// ```mbt
///   let ls = (@list.from_array(["1", "2", "3", "4", "5"])).intersperse("|")
///   assert_eq(ls, @list.from_array(["1", "|", "2", "|", "3", "|", "4", "|", "5"]))
/// ```
#deprecated("use `@list` instead")
pub fn[A] intersperse(self : T[A], separator : A) -> T[A] {
  match self {
    Nil => Nil
    Cons(head, Nil) => Cons(head, Nil)
    Cons(head, tail) => Cons(head, Cons(separator, tail.intersperse(separator)))
  }
}

///|
/// Check if the list is empty.
#deprecated("use `@list` instead")
pub fn[A] is_empty(self : T[A]) -> Bool {
  self is Nil
}

///|
/// Unzip two lists.
///
/// # Example
///
/// ```mbt
///   let (a,b) = @list.from_array([(1,2),(3,4),(5,6)]).unzip()
///   assert_eq(a, @list.from_array([1, 3, 5]))
///   assert_eq(b, @list.from_array([2, 4, 6]))
/// ```
#deprecated("use `@list` instead")
pub fn[A, B] unzip(self : T[(A, B)]) -> (T[A], T[B]) {
  let mut xs = Nil
  let mut ys = Nil
  // implemented with loop to avoid stack overflow
  loop self.rev() {
    Nil => break (xs, ys)
    Cons((x, y), tail) => {
      xs = Cons(x, xs)
      ys = Cons(y, ys)
      continue tail
    }
  }
}

///|
/// flatten a list of lists.
///
/// # Example
///
/// ```mbt
///   let ls = (@list.from_array([@list.from_array([1,2,3]), @list.from_array([4,5,6]), @list.from_array([7,8,9])])).flatten()
///   assert_eq(ls, @list.from_array([1, 2, 3, 4, 5, 6, 7, 8, 9]))
/// ```
#deprecated("use `@list` instead")
pub fn[A] flatten(self : T[T[A]]) -> T[A] {
  match self {
    Nil => Nil
    Cons(head, tail) => head.concat(tail.flatten())
  }
}

///|
#internal(unsafe, "Panic if the list is empty")
#deprecated("use `@list` instead")
pub fn[A : Compare] unsafe_maximum(self : T[A]) -> A {
  match self {
    Nil => abort("maximum: empty list")
    Cons(x, Nil) => x
    Cons(x, xs) => {
      let y = xs.unsafe_maximum()
      if x > y {
        x
      } else {
        y
      }
    }
  }
}

///|
/// Get maximum element of the list.
/// Returns None if the list is empty.
#deprecated("use `@list` instead")
pub fn[A : Compare] maximum(self : T[A]) -> A? {
  match self {
    Nil => None
    Cons(x, Nil) => Some(x)
    Cons(x, xs) =>
      match xs.maximum() {
        None => Some(x)
        Some(y) => Some(if x > y { x } else { y })
      }
  }
}

///|
#internal(unsafe, "Panic if the list is empty")
#deprecated("use `@list` instead")
pub fn[A : Compare] unsafe_minimum(self : T[A]) -> A {
  match self {
    Nil => abort("minimum: empty list")
    Cons(x, Nil) => x
    Cons(x, xs) => {
      let y = xs.unsafe_minimum()
      if x < y {
        x
      } else {
        y
      }
    }
  }
}

///|
/// Get minimum element of the list.
#deprecated("use `@list` instead")
pub fn[A : Compare] minimum(self : T[A]) -> A? {
  match self {
    Nil => None
    Cons(x, Nil) => Some(x)
    Cons(x, xs) =>
      match xs.minimum() {
        None => Some(x)
        Some(y) => Some(if x < y { x } else { y })
      }
  }
}

///|
/// Sort the list in ascending order.
///
/// # Example
///
/// ```mbt
///   let ls = (@list.from_array([1,123,52,3,6,0,-6,-76])).sort()
///   assert_eq(ls, @list.from_array([-76, -6, 0, 1, 3, 6, 52, 123]))
/// ```
#deprecated("use `@list` instead")
pub fn[A : Compare] sort(self : T[A]) -> T[A] {
  match self {
    Nil => Nil
    Cons(x, xs) => {
      let smaller = xs.filter(y => y < x)
      let greater = xs.filter(y => y >= x)
      smaller.sort().concat(Cons(x, greater.sort()))
    }
  }
}

///|
/// Concatenate two lists.
///
/// `a + b` equal to `a.concat(b)`
pub impl[A] Add for T[A] with add(self, other) {
  self.concat(other)
}

///|
/// Check if the list contains the value.
#deprecated("use `@list` instead")
pub fn[A : Eq] contains(self : T[A], value : A) -> Bool {
  loop self {
    Nil => false
    Cons(x, xs) => if x == value { true } else { continue xs }
  }
}

///|
/// Produces a collection iteratively.
///
/// # Example
///
/// ```mbt
///   let r = @list.unfold(init=0, i => if i == 3 { None } else { Some((i, i + 1)) })
///   assert_eq(r, @list.from_array([0, 1, 2]))
/// ```
#deprecated("use `@list` instead")
pub fn[A, S] unfold(f : (S) -> (A, S)? raise?, init~ : S) -> T[A] raise? {
  match f(init) {
    Some((element, new_state)) => Cons(element, unfold(init=new_state, f))
    None => Nil
  }
}

///|
/// Take first n elements of the list.
/// If the list is shorter than n, return the whole list.
///
/// # Example
///
/// ```mbt
///   let ls = @list.of([1, 2, 3, 4, 5])
///   let r = ls.take(3)
///   assert_eq(r, @list.of([1, 2, 3]))
/// ```
#deprecated("use `@list` instead")
pub fn[A] take(self : T[A], n : Int) -> T[A] {
  fn go(n, t) {
    match (n, t) {
      (_, Nil) => Nil
      (1, Cons(x, _)) => Cons(x, Nil)
      (n, Cons(x, xs)) => Cons(x, go(n - 1, xs))
    }
  }

  if n <= 0 {
    Nil
  } else {
    go(n, self)
  }
}

///|
/// Drop first n elements of the list.
/// If the list is shorter than n, return an empty list.
///
/// # Example
///
/// ```mbt
///   let ls = @list.of([1, 2, 3, 4, 5])
///   let r = ls.drop(3)
///   assert_eq(r, @list.of([4, 5]))
/// ```
#deprecated("use `@list` instead")
pub fn[A] drop(self : T[A], n : Int) -> T[A] {
  if n <= 0 {
    self
  } else {
    loop (n, self) {
      (_, Nil) => Nil
      (1, Cons(_, xs)) => xs
      (n, Cons(_, xs)) => continue (n - 1, xs)
    }
  }
}

///|
/// Take the longest prefix of a list of elements that satisfies a given predicate.
///
/// # Example
///
/// ```mbt
///   let ls = @list.from_array([1, 2, 3, 4])
///   let r = ls.take_while((x) => { x < 3 })
///   assert_eq(r, @list.of([1, 2]))
/// ```
#deprecated("use `@list` instead")
pub fn[A] take_while(self : T[A], p : (A) -> Bool) -> T[A] {
  match self {
    Nil => Nil
    Cons(x, xs) => if p(x) { Cons(x, xs.take_while(p)) } else { Nil }
  }
}

///|
/// Drop the longest prefix of a list of elements that satisfies a given predicate.
///
/// # Example
///
/// ```mbt
///   let ls = @list.from_array([1, 2, 3, 4])
///   let r = ls.drop_while((x) => { x < 3 })
///   assert_eq(r, @list.of([3, 4]))
/// ```
#deprecated("use `@list` instead")
pub fn[A] drop_while(self : T[A], p : (A) -> Bool raise?) -> T[A] raise? {
  loop self {
    Nil => Nil
    Cons(x, xs) => if p(x) { continue xs } else { Cons(x, xs) }
  }
}

///|
/// Fold a list and return a list of successive reduced values from the left
///
/// # Example
///
/// ```mbt
///   let ls = @list.of([1, 2, 3, 4, 5])
///   let r = ls.scan_left((acc, x) => { acc + x }, init=0)
///   assert_eq(r, @list.of([0, 1, 3, 6, 10, 15]))
/// ```
#deprecated("use `@list` instead")
pub fn[A, E] scan_left(
  self : T[A],
  f : (E, A) -> E raise?,
  init~ : E,
) -> T[E] raise? {
  Cons(
    init,
    match self {
      Nil => Nil
      Cons(x, xs) => xs.scan_left(f, init=f(init, x))
    },
  )
}

///|
/// Fold a list and return a list of successive reduced values from the right
///
/// Note that the order of parameters on the accumulating function are reversed.
///
/// # Example
/// ```mbt
///   let ls = @list.of([1, 2, 3, 4, 5])
///   let r = ls.scan_right((x, acc) => { acc + x }, init=0)
///   assert_eq(r, @list.of([15, 14, 12, 9, 5, 0]))
/// ```
#deprecated("use `@list` instead")
pub fn[A, B] scan_right(
  self : T[A],
  f : (A, B) -> B raise?,
  init~ : B,
) -> T[B] raise? {
  match self {
    Nil => Cons(init, Nil)
    Cons(x, xs) => {
      let qs = xs.scan_right(f, init~)
      Cons(f(x, qs.unsafe_head()), qs)
    }
  }
}

///|
/// Looks up a key in an association list.
///
/// # Example
///
/// ```mbt
///   let ls = @list.from_array([(1, "a"), (2, "b"), (3, "c")])
///   assert_eq(ls.lookup(3), Some("c"))
/// ```
#deprecated("use `@list` instead")
pub fn[A : Eq, B] lookup(self : T[(A, B)], v : A) -> B? {
  loop self {
    Nil => None
    Cons((x, y), xs) => if x == v { Some(y) } else { continue xs }
  }
}

///|
/// Find the first element in the list that satisfies f.
///
/// # Example
///
/// ```mbt
///   assert_eq(@list.of([1, 3, 5, 8]).find((element) => { element % 2 == 0}), Some(8))
///   assert_eq(@list.of([1, 3, 5]).find((element) => { element % 2 == 0}), None)
/// ```
#deprecated("use `@list` instead")
pub fn[A] find(self : T[A], f : (A) -> Bool raise?) -> A? raise? {
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

///|
/// Find the first element in the list that satisfies f and passes the index as an argument.
///
/// # Example
///
/// ```mbt
///   assert_eq(@list.of([1, 3, 5, 8]).findi((element, index) => { (element % 2 == 0) && (index == 3) }), Some(8))
///   assert_eq(@list.of([1, 3, 8, 5]).findi((element, index) => { (element % 2 == 0) && (index == 3) }), None)
/// ```
#deprecated("use `@list` instead")
pub fn[A] findi(self : T[A], f : (A, Int) -> Bool raise?) -> A? raise? {
  loop (self, 0) {
    (list, index) =>
      match list {
        Nil => None
        Cons(element, list) =>
          if f(element, index) {
            Some(element)
          } else {
            continue (list, index + 1)
          }
      }
  }
}

///|
/// Removes the element at the specified index in the list.
///
/// # Example
///
/// ```mbt
///   assert_eq(@list.of([1, 2, 3, 4, 5]).remove_at(2), @list.of([1, 2, 4, 5]))
/// ```
#deprecated("use `@list` instead")
pub fn[A] remove_at(self : T[A], index : Int) -> T[A] {
  match (index, self) {
    (0, Cons(_, tail)) => tail
    (_, Cons(head, tail)) => Cons(head, tail.remove_at(index - 1))
    (_, Nil) => Nil
    // abort("remove_at: index out of bounds")
  }
}

///|
/// Removes the first occurrence of the specified element from the list, if it is present.
///
/// # Example
///
/// ```mbt
///   assert_eq(@list.of([1, 2, 3, 4, 5]).remove(3), @list.of([1, 2, 4, 5]))
/// ```
#deprecated("use `@list` instead")
pub fn[A : Eq] remove(self : T[A], elem : A) -> T[A] {
  match self {
    Nil => Nil
    Cons(head, tail) =>
      if head == elem {
        tail
      } else {
        Cons(head, tail.remove(elem))
      }
  }
}

///|
/// Returns true if list starts with prefix.
///
/// # Example
///
/// ```mbt
///   assert_eq(@list.of([1, 2, 3, 4, 5]).is_prefix(@list.of([1, 2, 3])), true)
/// ```
#deprecated("use `@list` instead")
pub fn[A : Eq] is_prefix(self : T[A], prefix : T[A]) -> Bool {
  loop (self, prefix) {
    (_, Nil) => true
    (Nil, Cons(_)) => false
    (Cons(h1, t1), Cons(h2, t2)) =>
      if h1 == h2 {
        continue (t1, t2)
      } else {
        false
      }
  }
}

///|
/// Returns true if list ends with suffix.
///
/// # Example
///
/// ```mbt
///   assert_eq(@list.of([1, 2, 3, 4, 5]).is_suffix(@list.of([3, 4, 5])), true)
/// ```
#deprecated("use `@list` instead")
pub fn[A : Eq] is_suffix(self : T[A], suffix : T[A]) -> Bool {
  self.rev().is_prefix(suffix.rev())
}

///|
/// Similar to intersperse but with a list of values.
///
/// # Example
/// ```mbt
///   let ls = @list.of([
///      @list.of([1, 2, 3]),
///      @list.of([4, 5, 6]),
///      @list.of([7, 8, 9]),
///   ])
///   let r = ls.intercalate(@list.of([0]))
///   assert_eq(r, @list.of([1, 2, 3, 0, 4, 5, 6, 0, 7, 8, 9]))
/// ```
#deprecated("use `@list` instead")
pub fn[A] intercalate(self : T[T[A]], sep : T[A]) -> T[A] {
  self.intersperse(sep).flatten()
}

///|
pub impl[X] Default for T[X] with default() {
  Nil
}

///|
/// The empty list
#deprecated("use `@list` instead")
pub fn[X] default() -> T[X] {
  Nil
}

///|
#deprecated("use `@list` instead")
pub fn[A] iter(self : T[A]) -> Iter[A] {
  Iter::new(yield_ => loop self {
    Nil => IterContinue
    Cons(head, tail) => {
      if yield_(head) is IterEnd {
        break IterEnd
      }
      continue tail
    }
  })
}

///|
#deprecated("use `@list` instead")
pub fn[A] iter2(self : T[A]) -> Iter2[Int, A] {
  Iter2::new(yield_ => loop (self, 0) {
    (Nil, _) => IterEnd
    (Cons(head, tail), i) => {
      if yield_(i, head) is IterEnd {
        break IterEnd
      }
      continue (tail, i + 1)
    }
  })
}

///|
/// Convert the iterator into a list. Preserves order of elements.
/// This function is tail-recursive, but consumes 2*n memory. 
/// If the order of elements is not important, use `from_iter_rev` instead.
#deprecated("use `@list` instead")
pub fn[A] from_iter(iter : Iter[A]) -> T[A] {
  iter.fold(init=Nil, (acc, e) => Cons(e, acc)).rev()
}

///|
#deprecated("use `@list` instead")
pub fn[A] from_iter_rev(iter : Iter[A]) -> T[A] {
  iter.fold(init=Nil, (acc, e) => Cons(e, acc))
}

///|
#deprecated("use `@list` instead")
pub fn[A] of(arr : FixedArray[A]) -> T[A] {
  for i = arr.length() - 1, list = Nil; i >= 0; {
    continue i - 1, Cons(arr[i], list)
  } else {
    list
  }
}

///|
pub impl[X : @quickcheck.Arbitrary] @quickcheck.Arbitrary for T[X] with arbitrary(
  size,
  rs,
) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> from_array
}

///|
#deprecated("use `@list` instead")
pub fn[A] singleton(x : A) -> T[A] {
  Cons(x, Nil)
}

///|
pub impl[A : Hash] Hash for T[A] with hash_combine(self, hasher) {
  for e in self {
    hasher.combine(e)
  }
}

///|
/// Compares two lists based on shortlex order.
///
/// First compares elements pairwise until a difference is found.
/// If lists have different lengths and all shared elements are equal,
/// the shorter list is considered less than the longer one.
///
/// Parameters:
///
/// * `self` : The first list to compare.
/// * `other` : The second list to compare.
///
/// Returns an integer that indicates the relative order:
///
/// * A negative value if `self` is less than `other`
/// * Zero if `self` equals `other`
/// * A positive value if `self` is greater than `other`
///
/// Example:
///
/// ```moonbit
///   let list1 = @list.of([1, 2, 3])
///   let list2 = @list.of([1, 2, 4])
///   let list3 = @list.of([1, 2])
///   inspect(list1.compare(list2), content="-1") // list1 < list2
///   inspect(list1.compare(list3), content="1") // list2 > list1
///   inspect(list3.compare(list1), content="-1") // list1 > list3 (longer)
///   inspect(list1.compare(list1), content="0") // list1 = list1
/// ```
pub impl[A : Compare] Compare for T[A] with compare(self, other) {
  loop (self, other) {
    (Nil, Nil) => 0
    (Nil, Cons(_, _)) => -1
    (Cons(_, _), Nil) => 1
    (Cons(x, xs), Cons(y, ys)) => {
      let cmp = x.compare(y)
      if cmp != 0 {
        break cmp
      } else {
        continue (xs, ys)
      }
    }
  }
}
