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
/// Creates an empty list
pub fn[A] new() -> T[A] {
  Empty
}

///|
/// Creates an empty list
pub fn[A] empty() -> T[A] {
  Empty
}

///|
/// Prepend an element to the list and create a new list.
pub fn[A] construct(head : A, tail : T[A]) -> T[A] {
  More(head, tail~)
}

///|
pub fn[A] prepend(self : T[A], head : A) -> T[A] {
  More(head, tail=self)
}

///|
pub fn[A] add(self : T[A], head : A) -> T[A] {
  More(head, tail=self)
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
pub fn[A : ToJson] to_json(self : T[A]) -> Json {
  ToJson::to_json(self)
}

///|
pub impl[A : @json.FromJson] @json.FromJson for T[A] with from_json(json, path) {
  guard json is Array(arr) else {
    raise @json.JsonDecodeError((path, "@list.from_json: expected array"))
  }
  for i = arr.length() - 1, list = Empty; i >= 0; {
    continue i - 1, list.prepend(A::from_json(arr[i], path.add_index(i)))
  } else {
    list
  }
}

///|
pub fn[A : @json.FromJson] from_json(
  json : Json
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
pub fn[A] from_array(arr : Array[A]) -> T[A] {
  for i = arr.length() - 1, list = Empty; i >= 0; {
    continue i - 1, More(arr[i], tail=list)
  } else {
    list
  }
}

///|
/// Get the length of the list.
pub fn[A] length(self : T[A]) -> Int {
  loop (self, 0) {
    (Empty, len) => len
    (More(_, tail=rest), acc) => continue (rest, acc + 1)
  }
}

///|
/// Iterates over the list.
///
/// # Example
///
/// ```mbt
///   let arr = []
///   @list.of([1, 2, 3, 4, 5]).each(x => arr.push(x))
///   assert_eq(arr, [1, 2, 3, 4, 5])
/// ```
#locals(f)
pub fn[A] each(self : T[A], f : (A) -> Unit raise?) -> Unit raise? {
  loop self {
    Empty => ()
    More(head, tail~) => {
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
///   @list.of([1, 2, 3, 4, 5]).eachi((i, x) => arr.push("(\{i},\{x})"))
///   assert_eq(arr, ["(0,1)", "(1,2)", "(2,3)", "(3,4)", "(4,5)"])
/// ```
pub fn[A] eachi(self : T[A], f : (Int, A) -> Unit raise?) -> Unit raise? {
  loop (self, 0) {
    (Empty, _) => ()
    (More(x, tail=xs), i) => {
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
///   assert_eq(@list.of([1, 2, 3, 4, 5]).map(x => x * 2), @list.of([2, 4, 6, 8, 10]))
/// ```
pub fn[A, B] map(self : T[A], f : (A) -> B raise?) -> T[B] raise? {
  match self {
    Empty => Empty
    More(hd, tail~) => {
      let dest = More(f(hd), tail=Empty)
      loop (dest, tail) {
        (_, Empty) => ()
        (More(_) as dest, More(hd, tail~)) => {
          dest.tail = More(f(hd), tail=Empty)
          continue (dest.tail, tail)
        }
        // unreachable
        (Empty, _) => panic()
      }
      dest
    }
  }
}

///|
/// Maps the list with index.
pub fn[A, B] mapi(self : T[A], f : (Int, A) -> B raise?) -> T[B] raise? {
  match self {
    Empty => Empty
    More(hd, tail~) => {
      let dest = More(f(0, hd), tail=Empty)
      loop (1, dest, tail) {
        (_, _, Empty) => ()
        (i, More(_) as dest, More(hd, tail~)) => {
          dest.tail = More(f(i, hd), tail=Empty)
          continue (i + 1, dest.tail, tail)
        }
        // unreachable
        (_, Empty, _) => panic()
      }
      dest
    }
  }
}

///|
/// Maps the list and reverses the result.
///
/// `list.rev_map(f)` is equivalent to `list.map(f).rev()` but more efficient.
///
/// # Example
/// ```mbt
///   assert_eq(@list.of([1, 2, 3, 4, 5]).rev_map(x => x * 2), @list.of([10, 8, 6, 4, 2]))
/// ```
pub fn[A, B] rev_map(self : T[A], f : (A) -> B raise?) -> T[B] raise? {
  loop (Empty, self) {
    (acc, Empty) => acc
    (acc, More(x, tail=xs)) => continue (More(f(x), tail=acc), xs)
  }
}

///|
/// Convert list to array.
pub fn[A] to_array(self : T[A]) -> Array[A] {
  match self {
    Empty => []
    More(x, tail=xs) => {
      let arr = [x]
      loop xs {
        Empty => ()
        More(x, tail=xs) => {
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
///   assert_eq(@list.of([1, 2, 3, 4, 5]).filter(x => x % 2 == 0), @list.of([2, 4]))
/// ```
pub fn[A] filter(self : T[A], f : (A) -> Bool raise?) -> T[A] raise? {
  loop self {
    Empty => Empty
    More(head, tail~) =>
      if not(f(head)) {
        continue tail
      } else {
        let dest = More(head, tail=Empty)
        loop (dest, tail) {
          (_, Empty) => ()
          (More(_) as dest, More(hd, tail~)) =>
            if f(hd) {
              dest.tail = More(hd, tail=Empty)
              continue (dest.tail, tail)
            } else {
              continue (dest, tail)
            }
          (Empty, _) =>
            // unreachable
            panic()
        }
        dest
      }
  }
}

///|
/// Test if all elements of the list satisfy the predicate.
pub fn[A] all(self : T[A], f : (A) -> Bool raise?) -> Bool raise? {
  loop self {
    Empty => true
    More(head, tail~) => if f(head) { continue tail } else { false }
  }
}

///|
/// Test if any element of the list satisfies the predicate.
pub fn[A] any(self : T[A], f : (A) -> Bool raise?) -> Bool raise? {
  loop self {
    Empty => false
    More(head, tail~) => if f(head) { true } else { continue tail }
  }
}

///|
/// Get first element of the list.
#internal(unsafe, "Panic if the list is empty")
pub fn[A] unsafe_head(self : T[A]) -> A {
  match self {
    Empty => abort("head of empty list")
    More(head, tail=_) => head
  }
}

///|
pub fn[A] unsafe_tail(self : T[A]) -> T[A] {
  match self {
    Empty => abort("tail of empty list")
    More(_, tail~) => tail
  }
}

///|
/// Get first element of the list.
///
/// # Example
///
/// ```mbt
///   assert_eq(@list.of([1, 2, 3, 4, 5]).head(), Some(1))
/// ```
pub fn[A] head(self : T[A]) -> A? {
  match self {
    Empty => None
    More(head, tail=_) => Some(head)
  }
}

///|
#internal(unsafe, "Panic if the list is empty")
pub fn[A] unsafe_last(self : T[A]) -> A {
  loop self {
    Empty => abort("last of empty list")
    More(head, tail=Empty) => head
    More(_, tail~) => continue tail
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
pub fn[A] last(self : T[A]) -> A? {
  loop self {
    Empty => None
    More(head, tail=Empty) => Some(head)
    More(_, tail~) => continue tail
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
pub fn[A] concat(self : T[A], other : T[A]) -> T[A] {
  match self {
    Empty => other
    More(hd, tail=Empty) => More(hd, tail=other)
    More(hd, tail~) => {
      let dest = More(hd, tail=Empty)
      loop (dest, tail) {
        (More(_) as dest, Empty) => dest.tail = other
        (More(_) as dest, More(head, tail~)) => {
          dest.tail = More(head, tail=Empty)
          continue (dest.tail, tail)
        }
        // unreachable
        (Empty, _) => panic()
      }
      dest
    }
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
pub fn[A] rev_concat(self : T[A], other : T[A]) -> T[A] {
  loop (self, other) {
    (Empty, other) => other
    (More(head, tail~), other) => continue (tail, More(head, tail=other))
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
pub fn[A] rev(self : T[A]) -> T[A] {
  self.rev_concat(Empty)
}

///|
/// Fold the list from left.
///
/// # Example
///
/// ```mbt
///   let r = @list.of([1, 2, 3, 4, 5]).fold(init=0, (acc, x) => acc + x)
///   assert_eq(r, 15)
/// ```
pub fn[A, B] fold(self : T[A], init~ : B, f : (B, A) -> B raise?) -> B raise? {
  loop (self, init) {
    (Empty, acc) => acc
    (More(head, tail~), acc) => continue (tail, f(acc, head))
  }
}

///|
/// Fold the list from left with index.
pub fn[A, B] foldi(
  self : T[A],
  init~ : B,
  f : (Int, B, A) -> B raise?
) -> B raise? {
  fn go(xs : T[A], i : Int, f : (Int, B, A) -> B raise?, acc : B) -> B raise? {
    match xs {
      Empty => acc
      More(x, tail=xs) => go(xs, i + 1, f, f(i, acc, x))
    }
  }

  go(self, 0, f, init)
}

///|
/// Zip two lists.
/// If the lists have different lengths, it will return a list with shorter length.
///
/// # Example
///
/// ```moonbit
///   let r = @list.zip(@list.of([1, 2, 3, 4, 5]), @list.of([6, 7, 8, 9, 10]))
///   assert_eq(r, @list.from_array([(1, 6), (2, 7), (3, 8), (4, 9), (5, 10)]))
/// ```
pub fn[A, B] T::zip(self : T[A], other : T[B]) -> T[(A, B)] {
  let res = loop (self, other, Empty) {
    (Empty, _, acc) => break acc
    (_, Empty, acc) => break acc
    (More(x, tail=xs), More(y, tail=ys), acc) =>
      continue (xs, ys, More((x, y), tail=acc))
  }
  res.reverse_inplace()
}

///|
/// map over the list and concat all results.
///
/// `flat_map(f, ls)` equal to `ls.map(f).fold(Empty, (acc, x) => acc.concat(x))))`
///
/// # Example
///
/// ```mbt
///   let ls = @list.from_array([1, 2, 3])
///   let r = ls.flat_map(x => @list.from_array([x, x * 2]))
///   assert_eq(r, @list.from_array([1, 2, 2, 4, 3, 6]))
/// ```
pub fn[A, B] flat_map(self : T[A], f : (A) -> T[B] raise?) -> T[B] raise? {
  loop self {
    Empty => Empty
    More(head, tail~) =>
      match f(head) {
        // continue until we have at least one element
        Empty => continue tail
        More(hd, tail=tl) => {
          let dest = More(hd, tail=Empty)
          // copy all the elements of `f(head)` first
          let dest1 = loop (dest, tl) {
            (dest, Empty) => dest
            (More(_) as dest, More(hd, tail~)) => {
              dest.tail = More(hd, tail=Empty)
              continue (dest.tail, tail)
            }
            (Empty, _) => panic()
          }
          // continue looping on the `tail` of `self`
          loop_over_tail~: loop (dest1, tail) {
            (_, Empty) => ()
            (More(_) as dest, More(t_hd, tail=Empty)) => dest.tail = f(t_hd)
            (dest, More(t_hd, tail=t_tl)) =>
              loop (dest, f(t_hd)) {
                (dest, Empty) => continue loop_over_tail~ (dest, t_tl)
                (More(_) as dest, More(hd, tail~)) => {
                  dest.tail = More(hd, tail=Empty)
                  continue (dest.tail, tail)
                }
                (Empty, _) => panic()
              }
          }
          dest
        }
      }
  }
}

///|
/// Map over the list and keep all `value`s for which the mapped result is `Some(value)`.
///
/// # Example
///
/// ```mbt
///   let ls = @list.of([4, 2, 2, 6, 3, 1])
///   let r = ls.filter_map(x => if (x >= 3) { Some(x) } else { None })
///   assert_eq(r, @list.of([4, 6, 3]))
/// ```
pub fn[A, B] filter_map(self : T[A], f : (A) -> B? raise?) -> T[B] raise? {
  loop self {
    Empty => Empty
    More(hd, tail~) =>
      match f(hd) {
        None => continue tail
        Some(head) => {
          let dest = More(head, tail=Empty)
          loop (dest, tail) {
            (_, Empty) => ()
            (More(_) as dest, More(hd, tail~)) =>
              match f(hd) {
                None => continue (dest, tail)
                Some(head) => {
                  dest.tail = More(head, tail=Empty)
                  continue (dest.tail, tail)
                }
              }
            (Empty, _) => panic()
          }
          dest
        }
      }
  }
}

///|
#internal(unsafe, "Panic if the index is out of bounds")
pub fn[A] unsafe_nth(self : T[A], n : Int) -> A {
  loop (self, n) {
    (Empty, _) => abort("nth: index out of bounds")
    (More(head, tail=_), 0) => head
    (More(_, tail~), n) => continue (tail, n - 1)
  }
}

///|
/// Get nth element of the list or None if the index is out of bounds
pub fn[A] nth(self : T[A], n : Int) -> A? {
  loop (self, n) {
    (Empty, _) => None
    (More(head, tail=_), 0) => Some(head)
    (More(_, tail~), n) => continue (tail, n - 1)
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
pub fn[A] repeat(n : Int, x : A) -> T[A] {
  loop (Empty, n) {
    (acc, n) => if n <= 0 { acc } else { continue (More(x, tail=acc), n - 1) }
  }
}

///|
/// Insert separator to the list.
///
/// # Example
///
/// ```mbt
///   let ls = @list.from_array(["1", "2", "3", "4", "5"]).intersperse("|")
///   assert_eq(ls, @list.from_array(["1", "|", "2", "|", "3", "|", "4", "|", "5"]))
/// ```
pub fn[A] intersperse(self : T[A], separator : A) -> T[A] {
  match self {
    Empty => Empty
    More(head, tail=Empty) => More(head, tail=Empty)
    More(head, tail~) => {
      let dest = More(head, tail=Empty)
      loop (dest, tail) {
        (_, Empty) => ()
        (More(_) as dest, More(hd, tail=tl)) => {
          let new_tail = More(hd, tail=Empty)
          dest.tail = More(separator, tail=new_tail)
          continue (new_tail, tl)
        }
        // unreachable
        (Empty, _) => panic()
      }
      dest
    }
  }
}

///|
/// Check if the list is empty.
pub fn[A] is_empty(self : T[A]) -> Bool {
  self is Empty
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
pub fn[A, B] unzip(self : T[(A, B)]) -> (T[A], T[B]) {
  match self {
    Empty => (Empty, Empty)
    More((x, y), tail~) => {
      let xs = More(x, tail=Empty)
      let ys = More(y, tail=Empty)
      loop (tail, xs, ys) {
        (Empty, _, _) => ()
        (More((x, y), tail~), More(_) as xptr, More(_) as yptr) => {
          xptr.tail = More(x, tail=Empty)
          yptr.tail = More(y, tail=Empty)
          continue (tail, xptr.tail, yptr.tail)
        }
        (_, _, _) => abort("unreachable")
      }
      (xs, ys)
    }
  }
}

///|
/// flatten a list of lists.
///
/// # Example
///
/// ```mbt
///   let ls = @list.from_array([@list.from_array([1,2,3]), @list.from_array([4,5,6]), @list.from_array([7,8,9])]).flatten()
///   assert_eq(ls, @list.from_array([1, 2, 3, 4, 5, 6, 7, 8, 9]))
/// ```
pub fn[A] flatten(self : T[T[A]]) -> T[A] {
  loop self {
    Empty => Empty
    More(head, tail~) =>
      match head {
        // continue until we have at least one element
        Empty => continue tail
        More(hd, tail=tl) => {
          let dest = More(hd, tail=Empty)
          // copy all the elements of `head` first
          let dest1 = loop (dest, tl) {
            (dest, Empty) => dest
            (More(_) as dest, More(hd, tail~)) => {
              dest.tail = More(hd, tail=Empty)
              continue (dest.tail, tail)
            }
            (Empty, _) => panic()
          }
          // continue looping on the `tail` of `self`
          loop_over_tail~: loop (dest1, tail) {
            (_, Empty) => ()
            (More(_) as dest, More(t_hd, tail=Empty)) => dest.tail = t_hd
            (dest, More(t_hd, tail=t_tl)) =>
              loop (dest, t_hd) {
                (dest, Empty) => continue loop_over_tail~ (dest, t_tl)
                (More(_) as dest, More(hd, tail~)) => {
                  dest.tail = More(hd, tail=Empty)
                  continue (dest.tail, tail)
                }
                (Empty, _) => panic()
              }
          }
          dest
        }
      }
  }
}

///|
#internal(unsafe, "Panic if the list is empty")
pub fn[A : Compare] unsafe_maximum(self : T[A]) -> A {
  match self {
    Empty => abort("maximum: empty list")
    More(head, tail~) =>
      loop (tail, head) {
        (Empty, curr_max) => curr_max
        (More(item, tail~), curr_max) =>
          continue (tail, if item > curr_max { item } else { curr_max })
      }
  }
}

///|
/// Get maximum element of the list.
/// Returns None if the list is empty.
pub fn[A : Compare] maximum(self : T[A]) -> A? {
  match self {
    Empty => None
    More(head, tail~) =>
      loop (tail, head) {
        (Empty, curr_max) => Some(curr_max)
        (More(item, tail~), curr_max) =>
          continue (tail, if item > curr_max { item } else { curr_max })
      }
  }
}

///|
#internal(unsafe, "Panic if the list is empty")
pub fn[A : Compare] unsafe_minimum(self : T[A]) -> A {
  match self {
    Empty => abort("maximum: empty list")
    More(head, tail~) =>
      loop (tail, head) {
        (Empty, curr_min) => curr_min
        (More(item, tail~), curr_min) =>
          continue (tail, if item < curr_min { item } else { curr_min })
      }
  }
}

///|
/// Get minimum element of the list.
pub fn[A : Compare] minimum(self : T[A]) -> A? {
  match self {
    Empty => None
    More(head, tail~) =>
      loop (tail, head) {
        (Empty, curr_min) => Some(curr_min)
        (More(item, tail~), curr_min) =>
          continue (tail, if item < curr_min { item } else { curr_min })
      }
  }
}

///|
/// Sort the list in ascending order.
///
/// # Example
///
/// ```mbt
///   let ls = @list.from_array([1,123,52,3,6,0,-6,-76]).sort()
///   assert_eq(ls, @list.from_array([-76, -6, 0, 1, 3, 6, 52, 123]))
/// ```
pub fn[A : Compare] sort(self : T[A]) -> T[A] {
  let arr = self.to_array()
  arr.sort()
  from_array(arr)
}

///|
/// Concatenate two lists.
///
/// `a + b` equal to `a.concat(b)`
pub impl[A] Add for T[A] with op_add(self, other) {
  self.concat(other)
}

///|
/// Check if the list contains the value.
pub fn[A : Eq] contains(self : T[A], value : A) -> Bool {
  loop self {
    Empty => false
    More(x, tail=xs) => if x == value { true } else { continue xs }
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
pub fn[A, S] unfold(f : (S) -> (A, S)? raise?, init~ : S) -> T[A] raise? {
  match f(init) {
    None => Empty
    Some((element, new_state)) => {
      let dest = More(element, tail=Empty)
      loop (dest, f(new_state)) {
        (_, None) => ()
        (More(_) as dest, Some((element, new_state))) => {
          dest.tail = More(element, tail=Empty)
          continue (dest.tail, f(new_state))
        }
        (Empty, _) => panic()
      }
      dest
    }
  }
}

///|
pub fn[A, S] rev_unfold(f : (S) -> (A, S)? raise?, init~ : S) -> T[A] raise? {
  loop (f(init), Empty) {
    (None, acc) => acc
    (Some((x, s)), acc) => continue (f(s), More(x, tail=acc))
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
pub fn[A] take(self : T[A], n : Int) -> T[A] {
  if n <= 0 {
    Empty
  } else {
    match self {
      Empty => Empty
      More(head, tail~) => {
        let dest = More(head, tail=Empty)
        loop (dest, tail, n - 1) {
          (_, Empty, _) => ()
          (_, _, 0) => ()
          (More(_) as dest, More(x, tail=xs), n) => {
            dest.tail = More(x, tail=Empty)
            continue (dest.tail, xs, n - 1)
          }
          (Empty, _, _) => panic()
        }
        dest
      }
    }
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
pub fn[A] drop(self : T[A], n : Int) -> T[A] {
  if n <= 0 {
    self
  } else {
    loop (n, self) {
      (_, Empty) => Empty
      (1, More(_, tail=xs)) => xs
      (n, More(_, tail=xs)) => continue (n - 1, xs)
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
///   let r = ls.take_while(x => x < 3)
///   assert_eq(r, @list.of([1, 2]))
/// ```
pub fn[A] take_while(self : T[A], p : (A) -> Bool raise?) -> T[A] raise? {
  match self {
    Empty => Empty
    More(head, tail~) =>
      if p(head) {
        let dest = More(head, tail=Empty)
        loop (dest, tail) {
          (_, Empty) => ()
          (More(_) as dest, More(x, tail=xs)) if p(x) => {
            dest.tail = More(x, tail=Empty)
            continue (dest.tail, xs)
          }
          (More(_), _) => ()
          (Empty, _) => panic()
        }
        dest
      } else {
        Empty
      }
  }
}

///|
/// Drop the longest prefix of a list of elements that satisfies a given predicate.
///
/// # Example
///
/// ```mbt
///   let ls = @list.from_array([1, 2, 3, 4])
///   let r = ls.drop_while(x => x < 3)
///   assert_eq(r, @list.of([3, 4]))
/// ```
pub fn[A] drop_while(self : T[A], p : (A) -> Bool raise?) -> T[A] raise? {
  loop self {
    Empty => Empty
    More(x, tail=xs) => if p(x) { continue xs } else { More(x, tail=xs) }
  }
}

///|
/// Fold a list and return a list of successive reduced values from the left
///
/// # Example
///
/// ```mbt
///   let ls = @list.of([1, 2, 3, 4, 5])
///   let r = ls.scan_left((acc, x) => acc + x, init=0)
///   assert_eq(r, @list.of([0, 1, 3, 6, 10, 15]))
/// ```
pub fn[A, E] scan_left(
  self : T[A],
  f : (E, A) -> E raise?,
  init~ : E
) -> T[E] raise? {
  let dest = More(init, tail=Empty)
  loop (dest, self, init) {
    (_, Empty, _) => ()
    (Empty, _, _) => panic()
    (More(_) as dest, More(x, tail=xs), acc) => {
      dest.tail = More(f(acc, x), tail=Empty)
      continue (dest.tail, xs, f(acc, x))
    }
  }
  dest
}

///|
/// Fold a list and return a list of successive reduced values from the right
///
/// Note that the order of parameters on the accumulating function are reversed.
///
/// # Example
/// ```mbt
///   let ls = @list.of([1, 2, 3, 4, 5])
///   let r = ls.scan_right((acc, x) => acc + x, init=0)
///   assert_eq(r, @list.of([15, 14, 12, 9, 5, 0]))
/// ```
pub fn[A, B] scan_right(
  self : T[A],
  f : (B, A) -> B raise?,
  init~ : B
) -> T[B] raise? {
  self.rev().scan_left(f, init~).reverse_inplace()
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
pub fn[A : Eq, B] lookup(self : T[(A, B)], v : A) -> B? {
  loop self {
    Empty => None
    More((x, y), tail=xs) => if x == v { Some(y) } else { continue xs }
  }
}

///|
/// Find the first element in the list that satisfies f.
///
/// # Example
///
/// ```mbt
///   assert_eq(@list.of([1, 3, 5, 8]).find(element => element % 2 == 0), Some(8))
///   assert_eq(@list.of([1, 3, 5]).find(element => element % 2 == 0), None)
/// ```
pub fn[A] find(self : T[A], f : (A) -> Bool raise?) -> A? raise? {
  loop self {
    Empty => None
    More(element, tail=list) =>
      if f(element) {
        Some(element)
      } else {
        continue list
      }
  }
}

///|
/// Returns the index of the first element in the list that satisfies the
/// predicate function, or `None` if no element satisfies the predicate.
///
/// Parameters:
///
/// * `self` : The input list to search through.
/// * `f` : A function that takes an element of the list and returns a
/// boolean indicating whether the element satisfies the search criteria.
///
/// Returns an `Option` containing the index of the first matching element, or
/// `None` if no element matches.
///
/// Example:
///
/// ```moonbit
///   let ls = of([1, 2, 3, 4, 5])
///   inspect(ls.find_index(x => x % 2 == 0), content="Some(1)")
///   inspect(ls.find_index(x => x > 10), content="None")
/// ```
///
pub fn[A] T::find_index(self : Self[A], f : (A) -> Bool raise?) -> Int? raise? {
  loop (self, 0) {
    (Empty, _) => None
    (More(element, tail=list), idx) =>
      if f(element) {
        Some(idx)
      } else {
        continue (list, idx + 1)
      }
  }
}

///|
/// Find the first element in the list that satisfies f and passes the index as an argument.
///
/// # Example
///
/// ```mbt
///   assert_eq(@list.of([1, 3, 5, 8]).findi((element, index) => (element % 2 == 0) && (index == 3)), Some(8))
///   assert_eq(@list.of([1, 3, 8, 5]).findi((element, index) => (element % 2 == 0) && (index == 3)), None)
/// ```
pub fn[A] findi(self : T[A], f : (A, Int) -> Bool raise?) -> A? raise? {
  loop (self, 0) {
    (list, index) =>
      match list {
        Empty => None
        More(element, tail=list) =>
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
pub fn[A] remove_at(self : T[A], index : Int) -> T[A] {
  match (index, self) {
    (_, Empty) => Empty
    (_..<0, _) => self
    (0, More(_, tail~)) => tail
    (n, More(head, tail~)) => {
      let dest = More(head, tail=Empty)
      loop (dest, tail, n - 1) {
        (_, Empty, _) => ()
        (More(_) as dest, More(_, tail~), 0) => dest.tail = tail
        (More(_) as dest, More(x, tail=xs), n) => {
          dest.tail = More(x, tail=Empty)
          continue (dest.tail, xs, n - 1)
        }
        (Empty, _, _) => panic()
      }
      dest
    }
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
pub fn[A : Eq] remove(self : T[A], elem : A) -> T[A] {
  match self {
    Empty => Empty
    More(head, tail~) if head == elem => tail
    More(head, tail~) => {
      let dest = More(head, tail~)
      loop (dest, tail) {
        (_, Empty) => ()
        (More(_) as dest, More(x, tail=xs)) =>
          if x == elem {
            dest.tail = xs
          } else {
            dest.tail = More(x, tail=Empty)
            continue (dest.tail, xs)
          }
        (Empty, _) => panic()
      }
      dest
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
pub fn[A : Eq] is_prefix(self : T[A], prefix : T[A]) -> Bool {
  loop (self, prefix) {
    (_, Empty) => true
    (Empty, More(_)) => false
    (More(h1, tail=t1), More(h2, tail=t2)) =>
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
pub fn[A] intercalate(self : T[T[A]], sep : T[A]) -> T[A] {
  self.intersperse(sep).flatten()
}

///|
pub impl[X] Default for T[X] with default() {
  Empty
}

///|
/// The empty list
pub fn[X] default() -> T[X] {
  Empty
}

///|
pub fn[A] iter(self : T[A]) -> Iter[A] {
  Iter::new(yield_ => loop self {
    Empty => IterContinue
    More(head, tail~) => {
      if yield_(head) == IterEnd {
        break IterEnd
      }
      continue tail
    }
  })
}

///|
pub fn[A] iter2(self : T[A]) -> Iter2[Int, A] {
  Iter2::new(yield_ => loop (self, 0) {
    (Empty, _) => IterEnd
    (More(head, tail~), i) => {
      if yield_(i, head) == IterEnd {
        break IterEnd
      }
      continue (tail, i + 1)
    }
  })
}

///|
/// Convert the iterator into a list. Preserves order of elements.
/// If the order of elements is not important, use `from_iter_rev` instead.
pub fn[A] from_iter(iter : Iter[A]) -> T[A] {
  iter.fold(init=Empty, (acc, e) => More(e, tail=acc)).reverse_inplace()
}

///|
pub fn[A] from_iter_rev(iter : Iter[A]) -> T[A] {
  iter.fold(init=Empty, (acc, e) => More(e, tail=acc))
}

///|
pub fn[A] of(arr : FixedArray[A]) -> T[A] {
  for i = arr.length() - 1, list = Empty; i >= 0; {
    continue i - 1, More(arr[i], tail=list)
  } else {
    list
  }
}

///|
pub impl[X : @quickcheck.Arbitrary] @quickcheck.Arbitrary for T[X] with arbitrary(
  size,
  rs
) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> from_array
}

///|
pub fn[A] singleton(x : A) -> T[A] {
  More(x, tail=Empty)
}

///|
pub impl[A : Hash] Hash for T[A] with hash_combine(self, hasher) {
  for e in self {
    hasher.combine(e)
  }
}

///|
fn[A] reverse_inplace(self : T[A]) -> T[A] {
  match self {
    Empty | More(_, tail=Empty) => self
    More(head, tail~) =>
      loop (More(head, tail=Empty), tail) {
        (result, Empty) => result
        (result, More(_, tail=xs) as new_result) => {
          new_result.tail = result
          continue (new_result, xs)
        }
      }
  }
}

///|
pub fnalias T::zip
