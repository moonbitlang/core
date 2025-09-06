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
/// Creates an empty list.
///
/// # Example
///
/// ```moonbit
/// let ls : @list.List[Int] = @list.new()
/// assert_eq(ls, @list.empty())
/// ```
#alias(empty)
#as_free_fn
#as_free_fn(empty)
pub fn[A] List::new() -> List[A] {
  Empty
}

///|
/// Prepend an element to the list and create a new list.
/// 
/// This function constructs a new list with the given element as the head
/// and the provided list as the tail.
/// 
/// A more familiar name of this function is `cons`.
///
/// # Example
///
/// ```moonbit
/// let tail = @list.of([2, 3, 4])
/// let ls = @list.cons(1, tail)
/// assert_eq(ls, @list.of([1, 2, 3, 4]))
/// ```
#as_free_fn
#as_free_fn(construct, deprecated="Use cons instead")
pub fn[A] List::cons(head : A, tail : List[A]) -> List[A] {
  More(head, tail~)
}

///|
/// Prepend an element to the front of the list.
/// 
/// Creates a new list with the given element added to the beginning.
///
/// # Example
///
/// ```moonbit
/// let ls = @list.of([2, 3, 4]).prepend(1)
/// assert_eq(ls, @list.of([1, 2, 3, 4]))
/// ```
#alias(add)
pub fn[A] prepend(self : List[A], head : A) -> List[A] {
  More(head, tail=self)
}

///|
/// Show implementation for List.
/// Outputs the list in the format @list.of([element1, element2, ...]).
pub impl[A : Show] Show for List[A] with output(xs, logger) {
  logger.write_iter(xs.iter(), prefix="@list.of([", suffix="])")
}

///|
/// ToJson implementation for List.
/// Converts a list to a JSON array.
pub impl[A : ToJson] ToJson for List[A] with to_json(self) {
  let capacity = self.length()
  guard capacity != 0 else { return [] }
  let jsons = Array::new(capacity~)
  for a in self {
    jsons.push(a.to_json())
  }
  Json::array(jsons)
}

///|
/// Convert a list to JSON.
/// 
/// # Example
///
/// ```moonbit
/// let ls = @list.of([1, 2, 3])
/// let json = ls.to_json()
/// inspect(json, content="Array([Number(1), Number(2), Number(3)])")
/// ```
pub fn[A : ToJson] to_json(self : List[A]) -> Json {
  ToJson::to_json(self)
}

///|
/// FromJson implementation for List.
/// Parses a JSON array into a list.
pub impl[A : @json.FromJson] @json.FromJson for List[A] with from_json(
  json,
  path,
) {
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
/// Parse JSON into a list.
/// 
/// Converts a JSON array into a list of the specified type.
#as_free_fn
pub fn[A : @json.FromJson] List::from_json(
  json : Json,
) -> List[A] raise @json.JsonDecodeError {
  @json.from_json(json)
}

///|
/// Convert array to list.
///
/// # Example
///
/// ```mbt
/// let ls = @list.of([1, 2, 3, 4, 5])
/// assert_eq(ls, @list.from_array([1, 2, 3, 4, 5]))
/// ```
#as_free_fn
pub fn[A] List::from_array(arr : Array[A]) -> List[A] {
  for i = arr.length() - 1, list = Empty; i >= 0; {
    continue i - 1, More(arr[i], tail=list)
  } else {
    list
  }
}

///|
/// Get the length of the list.
pub fn[A] length(self : List[A]) -> Int {
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
/// let arr = []
/// @list.of([1, 2, 3, 4, 5]).each(x => arr.push(x))
/// assert_eq(arr, [1, 2, 3, 4, 5])
/// ```
#locals(f)
pub fn[A] each(self : List[A], f : (A) -> Unit raise?) -> Unit raise? {
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
pub fn[A] eachi(self : List[A], f : (Int, A) -> Unit raise?) -> Unit raise? {
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
/// assert_eq(@list.of([1, 2, 3, 4, 5]).map(x => x * 2), @list.of([2, 4, 6, 8, 10]))
/// ```
pub fn[A, B] map(self : List[A], f : (A) -> B raise?) -> List[B] raise? {
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
/// 
/// Applies a function to each element and its index, creating a new list
/// with the results.
///
/// # Example
///
/// ```moonbit
/// let ls = @list.of([10, 20, 30])
/// let result = ls.mapi((i, x) => x + i)
/// assert_eq(result, @list.of([10, 21, 32]))
/// ```
pub fn[A, B] mapi(self : List[A], f : (Int, A) -> B raise?) -> List[B] raise? {
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
/// assert_eq(@list.of([1, 2, 3, 4, 5]).rev_map(x => x * 2), @list.of([10, 8, 6, 4, 2]))
/// ```
pub fn[A, B] rev_map(self : List[A], f : (A) -> B raise?) -> List[B] raise? {
  loop (Empty, self) {
    (acc, Empty) => acc
    (acc, More(x, tail=xs)) => continue (More(f(x), tail=acc), xs)
  }
}

///|
/// Convert list to array.
/// 
/// Creates a new array containing all elements from the list in the same order.
///
/// # Example
///
/// ```moonbit
/// let ls = @list.of([1, 2, 3, 4, 5])
/// let arr = ls.to_array()
/// assert_eq(arr, [1, 2, 3, 4, 5])
/// ```
pub fn[A] to_array(self : List[A]) -> Array[A] {
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
/// assert_eq(@list.of([1, 2, 3, 4, 5]).filter(x => x % 2 == 0), @list.of([2, 4]))
/// ```
pub fn[A] filter(self : List[A], f : (A) -> Bool raise?) -> List[A] raise? {
  loop self {
    Empty => Empty
    More(head, tail~) =>
      if !f(head) {
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
/// 
/// Returns `true` if every element satisfies the predicate, or if the list is empty.
/// Returns `false` as soon as an element that doesn't satisfy the predicate is found.
///
/// # Example
///
/// ```moonbit
/// let ls = @list.of([2, 4, 6, 8])
/// assert_eq(ls.all(x => x % 2 == 0), true)
/// 
/// let ls2 = @list.of([2, 3, 6, 8])
/// assert_eq(ls2.all(x => x % 2 == 0), false)
/// ```
pub fn[A] all(self : List[A], f : (A) -> Bool raise?) -> Bool raise? {
  loop self {
    Empty => true
    More(head, tail~) => if f(head) { continue tail } else { false }
  }
}

///|
/// Test if any element of the list satisfies the predicate.
/// 
/// Returns `true` as soon as an element that satisfies the predicate is found.
/// Returns `false` if no element satisfies the predicate, or if the list is empty.
///
/// # Example
///
/// ```moonbit
/// let ls = @list.of([1, 3, 5, 6])
/// assert_eq(ls.any(x => x % 2 == 0), true)
/// 
/// let ls2 = @list.of([1, 3, 5, 7])
/// assert_eq(ls2.any(x => x % 2 == 0), false)
/// ```
pub fn[A] any(self : List[A], f : (A) -> Bool raise?) -> Bool raise? {
  loop self {
    Empty => false
    More(head, tail~) => if f(head) { true } else { continue tail }
  }
}

///|
/// Get first element of the list.
#internal(unsafe, "Panic if the list is empty")
pub fn[A] unsafe_head(self : List[A]) -> A {
  match self {
    Empty => abort("head of empty list")
    More(head, tail=_) => head
  }
}

///|
/// Get the tail (all elements except the first) of the list.
/// 
/// **Warning**: This function panics if the list is empty.
/// Use pattern matching or other safe methods for empty lists.
///
/// # Example
///
/// ```moonbit
/// let ls = @list.of([1, 2, 3, 4, 5])
/// let tail = ls.unsafe_tail()
/// assert_eq(tail, @list.of([2, 3, 4, 5]))
/// ```
/// 
/// # Panics
/// 
/// Panics if the list is empty.
pub fn[A] unsafe_tail(self : List[A]) -> List[A] {
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
/// assert_eq(@list.of([1, 2, 3, 4, 5]).head(), Some(1))
/// ```
pub fn[A] head(self : List[A]) -> A? {
  match self {
    Empty => None
    More(head, tail=_) => Some(head)
  }
}

///|
/// Get the last element of the list.
/// 
/// **Warning**: This function panics if the list is empty.
/// Use `last()` for a safe alternative that returns `Option`.
///
/// # Example
///
/// ```moonbit
/// let ls = @list.of([1, 2, 3, 4, 5])
/// assert_eq(ls.unsafe_last(), 5)
/// ```
/// 
/// # Panics
/// 
/// Panics if the list is empty.
#internal(unsafe, "Panic if the list is empty")
pub fn[A] unsafe_last(self : List[A]) -> A {
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
/// assert_eq(@list.of([1, 2, 3, 4, 5]).last(), Some(5))
/// ```
pub fn[A] last(self : List[A]) -> A? {
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
/// let ls = @list.of([1, 2, 3, 4, 5]).concat(@list.of([6, 7, 8, 9, 10]))
/// assert_eq(ls, @list.of([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]))
/// ```
pub fn[A] concat(self : List[A], other : List[A]) -> List[A] {
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
/// let ls = @list.of([1, 2, 3, 4, 5]).rev_concat(@list.of([6, 7, 8, 9, 10]))
/// assert_eq(ls, @list.of([5, 4, 3, 2, 1, 6, 7, 8, 9, 10]))
/// ```
pub fn[A] rev_concat(self : List[A], other : List[A]) -> List[A] {
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
/// assert_eq(@list.of([1, 2, 3, 4, 5]).rev(), @list.of([5, 4, 3, 2, 1]))
/// ```
pub fn[A] rev(self : List[A]) -> List[A] {
  self.rev_concat(Empty)
}

///|
/// Fold the list from left.
///
/// # Example
///
/// ```mbt
/// let r = @list.of([1, 2, 3, 4, 5]).fold(init=0, (acc, x) => acc + x)
/// inspect(r, content="15")
/// ```
pub fn[A, B] fold(
  self : List[A],
  init~ : B,
  f : (B, A) -> B raise?,
) -> B raise? {
  loop (self, init) {
    (Empty, acc) => acc
    (More(head, tail~), acc) => continue (tail, f(acc, head))
  }
}

///|
/// Fold the list from left with index.
/// 
/// Similar to `fold`, but the accumulator function also receives the index
/// of the current element.
///
/// # Example
///
/// ```moonbit
/// let ls = @list.of([10, 20, 30])
/// let result = ls.foldi(init=0, (i, acc, x) => acc + x * i)
/// inspect(result, content="80") // 0*10 + 1*20 + 2*30 = 80
/// ```
pub fn[A, B] foldi(
  self : List[A],
  init~ : B,
  f : (Int, B, A) -> B raise?,
) -> B raise? {
  fn go(
    xs : List[A],
    i : Int,
    f : (Int, B, A) -> B raise?,
    acc : B,
  ) -> B raise? {
    match xs {
      Empty => acc
      More(x, tail=xs) => go(xs, i + 1, f, f(i, acc, x))
    }
  }

  go(self, 0, f, init)
}

///|
/// Zip two lists together into a list of tuples.
/// 
/// Combines elements from two lists pairwise. If the lists have different 
/// lengths, the result will have the length of the shorter list.
///
/// # Example
///
/// ```moonbit
/// let r = @list.zip(@list.of([1, 2, 3, 4, 5]), @list.of([6, 7, 8, 9, 10]))
/// assert_eq(r, @list.from_array([(1, 6), (2, 7), (3, 8), (4, 9), (5, 10)]))
/// 
/// let r2 = @list.zip(@list.of([1, 2]), @list.of([6, 7, 8, 9, 10]))
/// assert_eq(r2, @list.from_array([(1, 6), (2, 7)]))
/// ```
#as_free_fn
pub fn[A, B] List::zip(self : List[A], other : List[B]) -> List[(A, B)] {
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
/// let ls = @list.from_array([1, 2, 3])
/// let r = ls.flat_map(x => @list.from_array([x, x * 2]))
/// assert_eq(r, @list.from_array([1, 2, 2, 4, 3, 6]))
/// ```
pub fn[A, B] flat_map(
  self : List[A],
  f : (A) -> List[B] raise?,
) -> List[B] raise? {
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
/// let ls = @list.of([4, 2, 2, 6, 3, 1])
/// let r = ls.filter_map(x => if (x >= 3) { Some(x) } else { None })
/// assert_eq(r, @list.of([4, 6, 3]))
/// ```
pub fn[A, B] filter_map(self : List[A], f : (A) -> B? raise?) -> List[B] raise? {
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
/// Get the nth element of the list.
/// 
/// **Warning**: This function panics if the index is out of bounds.
/// Use `nth()` for a safe alternative that returns `Option`.
///
/// # Example
///
/// ```moonbit
/// let ls = @list.of([1, 2, 3, 4, 5])
/// assert_eq(ls.unsafe_nth(2), 3)
/// ```
/// 
/// # Panics
/// 
/// Panics if the index is out of bounds.
#internal(unsafe, "Panic if the index is out of bounds")
pub fn[A] unsafe_nth(self : List[A], n : Int) -> A {
  loop (self, n) {
    (Empty, _) => abort("nth: index out of bounds")
    (More(head, tail=_), 0) => head
    (More(_, tail~), n) => continue (tail, n - 1)
  }
}

///|
/// Get the nth element of the list.
/// 
/// Returns `Some(element)` if the index is valid, or `None` if the index
/// is out of bounds.
///
/// # Example
///
/// ```moonbit
/// let ls = @list.of([1, 2, 3, 4, 5])
/// assert_eq(ls.nth(2), Some(3))
/// assert_eq(ls.nth(10), None)
/// ```
pub fn[A] nth(self : List[A], n : Int) -> A? {
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
#as_free_fn
pub fn[A] List::repeat(n : Int, x : A) -> List[A] {
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
pub fn[A] intersperse(self : List[A], separator : A) -> List[A] {
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
/// 
/// Returns `true` if the list contains no elements, `false` otherwise.
///
/// # Example
///
/// ```moonbit
/// let empty_list : @list.List[Int] = @list.empty()
/// assert_eq(empty_list.is_empty(), true)
/// 
/// let non_empty = @list.of([1, 2, 3])
/// assert_eq(non_empty.is_empty(), false)
/// ```
pub fn[A] is_empty(self : List[A]) -> Bool {
  self is Empty
}

///|
/// Unzip two lists.
///
/// # Example
///
/// ```mbt
/// let (a,b) = @list.from_array([(1,2),(3,4),(5,6)]).unzip()
/// assert_eq(a, @list.from_array([1, 3, 5]))
/// assert_eq(b, @list.from_array([2, 4, 6]))
/// ```
pub fn[A, B] unzip(self : List[(A, B)]) -> (List[A], List[B]) {
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
/// let ls = @list.from_array([@list.from_array([1,2,3]), @list.from_array([4,5,6]), @list.from_array([7,8,9])]).flatten()
/// assert_eq(ls, @list.from_array([1, 2, 3, 4, 5, 6, 7, 8, 9]))
/// ```
pub fn[A] flatten(self : List[List[A]]) -> List[A] {
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
/// Get the maximum element of the list.
/// 
/// **Warning**: This function panics if the list is empty.
/// Use `maximum()` for a safe alternative that returns `Option`.
///
/// # Example
///
/// ```moonbit
/// let ls = @list.of([1, 3, 2, 5, 4])
/// assert_eq(ls.unsafe_maximum(), 5)
/// ```
/// 
/// # Panics
/// 
/// Panics if the list is empty.
#internal(unsafe, "Panic if the list is empty")
pub fn[A : Compare] unsafe_maximum(self : List[A]) -> A {
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
/// Get the maximum element of the list.
/// 
/// Returns `Some(element)` with the largest element, or `None` if the list is empty.
/// Elements are compared using the `Compare` trait.
///
/// # Example
///
/// ```moonbit
///   let ls = @list.of([1, 3, 2, 5, 4])
///   assert_eq(ls.maximum(), Some(5))
///   
///   let empty : @list.List[Int] = @list.empty()
///   assert_eq(empty.maximum(), None)
/// ```
pub fn[A : Compare] maximum(self : List[A]) -> A? {
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
/// Get the minimum element of the list.
/// 
/// **Warning**: This function panics if the list is empty.
/// Use `minimum()` for a safe alternative that returns `Option`.
///
/// # Example
///
/// ```moonbit
/// let ls = @list.of([1, 3, 2, 5, 4])
/// assert_eq(ls.unsafe_minimum(), 1)
/// ```
/// 
/// # Panics
/// 
/// Panics if the list is empty.
#internal(unsafe, "Panic if the list is empty")
pub fn[A : Compare] unsafe_minimum(self : List[A]) -> A {
  match self {
    Empty => abort("minimum: empty list")
    More(head, tail~) =>
      loop (tail, head) {
        (Empty, curr_min) => curr_min
        (More(item, tail~), curr_min) =>
          continue (tail, if item < curr_min { item } else { curr_min })
      }
  }
}

///|
/// Get the minimum element of the list.
/// 
/// Returns `Some(element)` with the smallest element, or `None` if the list is empty.
/// Elements are compared using the `Compare` trait.
///
/// # Example
///
/// ```moonbit
/// let ls = @list.of([1, 3, 2, 5, 4])
/// assert_eq(ls.minimum(), Some(1))
/// 
/// let empty : @list.List[Int] = @list.empty()
/// assert_eq(empty.minimum(), None)
/// ```
pub fn[A : Compare] minimum(self : List[A]) -> A? {
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
pub fn[A : Compare] sort(self : List[A]) -> List[A] {
  let arr = self.to_array()
  arr.sort()
  from_array(arr)
}

///|
/// Add implementation for List - concatenates two lists.
/// 
/// The `+` operator for lists performs concatenation.
/// `a + b` is equivalent to `a.concat(b)`.
///
/// # Example
///
/// ```moonbit
/// let a = @list.of([1, 2, 3])
/// let b = @list.of([4, 5, 6])
/// let result = a + b
/// assert_eq(result, @list.of([1, 2, 3, 4, 5, 6]))
/// ```
pub impl[A] Add for List[A] with add(self, other) {
  self.concat(other)
}

///|
/// Check if the list contains the specified value.
/// 
/// Returns `true` if any element in the list is equal to the given value,
/// `false` otherwise.
///
/// # Example
///
/// ```moonbit
/// let ls = @list.of([1, 2, 3, 4, 5])
/// assert_eq(ls.contains(3), true)
/// assert_eq(ls.contains(6), false)
/// ```
pub fn[A : Eq] contains(self : List[A], value : A) -> Bool {
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
#as_free_fn
pub fn[A, S] List::unfold(
  f : (S) -> (A, S)? raise?,
  init~ : S,
) -> List[A] raise? {
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
/// Produces a list iteratively in reverse order.
/// 
/// Similar to `unfold`, but the resulting list will be in reverse order
/// compared to the generation order. This can be more efficient when
/// you don't need to preserve the generation order.
///
/// # Example
///
/// ```moonbit
/// let r = @list.rev_unfold(i => if i == 3 { None } else { Some((i, i + 1)) }, init=0)
/// assert_eq(r, @list.from_array([2, 1, 0]))
/// ```
#as_free_fn
pub fn[A, S] List::rev_unfold(
  f : (S) -> (A, S)? raise?,
  init~ : S,
) -> List[A] raise? {
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
pub fn[A] take(self : List[A], n : Int) -> List[A] {
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
pub fn[A] drop(self : List[A], n : Int) -> List[A] {
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
pub fn[A] take_while(self : List[A], p : (A) -> Bool raise?) -> List[A] raise? {
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
pub fn[A] drop_while(self : List[A], p : (A) -> Bool raise?) -> List[A] raise? {
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
  self : List[A],
  f : (E, A) -> E raise?,
  init~ : E,
) -> List[E] raise? {
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
  self : List[A],
  f : (B, A) -> B raise?,
  init~ : B,
) -> List[B] raise? {
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
pub fn[A : Eq, B] lookup(self : List[(A, B)], v : A) -> B? {
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
pub fn[A] find(self : List[A], f : (A) -> Bool raise?) -> A? raise? {
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
///   let ls = @list.of([1, 2, 3, 4, 5])
///   inspect(ls.find_index(x => x % 2 == 0), content="Some(1)")
///   inspect(ls.find_index(x => x > 10), content="None")
/// ```
///
pub fn[A] List::find_index(
  self : Self[A],
  f : (A) -> Bool raise?,
) -> Int? raise? {
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
pub fn[A] findi(self : List[A], f : (A, Int) -> Bool raise?) -> A? raise? {
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
pub fn[A] remove_at(self : List[A], index : Int) -> List[A] {
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
pub fn[A : Eq] remove(self : List[A], elem : A) -> List[A] {
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
pub fn[A : Eq] is_prefix(self : List[A], prefix : List[A]) -> Bool {
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
pub fn[A : Eq] is_suffix(self : List[A], suffix : List[A]) -> Bool {
  self.rev().is_prefix(suffix.rev())
}

///|
/// Insert separator lists between lists and flatten the result.
/// 
/// Similar to `intersperse`, but works with lists of lists. Inserts the
/// separator list between each list in the input, then flattens everything
/// into a single list.
///
/// # Example
/// ```moonbit
///   let ls = @list.of([
///      @list.of([1, 2, 3]),
///      @list.of([4, 5, 6]),
///      @list.of([7, 8, 9]),
///   ])
///   let r = ls.intercalate(@list.of([0]))
///   assert_eq(r, @list.of([1, 2, 3, 0, 4, 5, 6, 0, 7, 8, 9]))
/// ```
pub fn[A] intercalate(self : List[List[A]], sep : List[A]) -> List[A] {
  self.intersperse(sep).flatten()
}

///|
/// Default implementation for List.
/// 
/// Returns an empty list as the default value.
pub impl[X] Default for List[X] with default() {
  Empty
}

///|
/// Return the default value for a list (empty list).
/// 
/// # Example
///
/// ```moonbit
///   let ls : @list.List[Int] = @list.default()
///   assert_eq(ls.is_empty(), true)
/// ```
pub fn[X] default() -> List[X] {
  Empty
}

///|
/// Create an iterator over the list elements.
/// 
/// Returns an iterator that yields each element of the list in order.
///
/// # Example
///
/// ```moonbit
/// let ls = @list.of([1, 2, 3, 4, 5])
/// let iter = ls.iter()
/// let sum = iter.fold(init=0, (acc, x) => acc + x)
/// inspect(sum, content="15")
/// ```
pub fn[A] iter(self : List[A]) -> Iter[A] {
  Iter::new(yield_ => loop self {
    Empty => IterContinue
    More(head, tail~) => {
      if yield_(head) is IterEnd {
        break IterEnd
      }
      continue tail
    }
  })
}

///|
/// Create an iterator over the list elements with indices.
/// 
/// Returns an iterator that yields pairs of (index, element) for each
/// element in the list.
///
/// # Example
///
/// ```moonbit
/// let ls = @list.of([10, 20, 30])
/// let iter = ls.iter2()
/// inspect(iter, content="[(0, 10), (1, 20), (2, 30)]")
/// ```
pub fn[A] iter2(self : List[A]) -> Iter2[Int, A] {
  Iter2::new(yield_ => loop (self, 0) {
    (Empty, _) => IterEnd
    (More(head, tail~), i) => {
      if yield_(i, head) is IterEnd {
        break IterEnd
      }
      continue (tail, i + 1)
    }
  })
}

///|
/// Convert an iterator into a list, preserving order of elements.
/// 
/// Creates a list from an iterator, maintaining the same order as the iterator.
/// If order is not important, consider using `from_iter_rev` for better performance.
///
/// # Example
///
/// ```moonbit
/// let arr = [1, 2, 3, 4, 5]
/// let iter = arr.iter()
/// let ls = @list.from_iter(iter)
/// assert_eq(ls, @list.of([1, 2, 3, 4, 5]))
/// ```
#as_free_fn
pub fn[A] List::from_iter(iter : Iter[A]) -> List[A] {
  let mut res = Empty
  let mut ptr = Empty
  for x in iter {
    match (res, ptr) {
      (Empty, _) => {
        res = More(x, tail=Empty)
        ptr = res
      }
      (More(_), More(_) as ptr_) => {
        ptr_.tail = More(x, tail=Empty)
        ptr = ptr_.tail
      }
      (_, _) => panic()
    }
  }
  res
}

///|
/// Convert an iterator into a list in reverse order.
/// 
/// Creates a list from an iterator, but the resulting list will have elements
/// in reverse order compared to the iterator. This is more efficient than
/// `from_iter` when order doesn't matter.
///
/// # Example
///
/// ```moonbit
///   let arr = [1, 2, 3, 4, 5]
///   let iter = arr.iter()
///   let ls = @list.from_iter_rev(iter)
///   assert_eq(ls, @list.of([5, 4, 3, 2, 1]))
/// ```
#as_free_fn
pub fn[A] List::from_iter_rev(iter : Iter[A]) -> List[A] {
  iter.fold(init=Empty, (acc, e) => More(e, tail=acc))
}

///|
/// Create a list from a FixedArray.
/// 
/// Converts a FixedArray into a list with the same elements in the same order.
///
/// # Example
///
/// ```moonbit
/// let ls = @list.of([1, 2, 3, 4, 5])
/// assert_eq(ls.to_array(), [1, 2, 3, 4, 5])
/// ```
#as_free_fn
pub fn[A] List::of(arr : FixedArray[A]) -> List[A] {
  for i = arr.length() - 1, list = Empty; i >= 0; {
    continue i - 1, More(arr[i], tail=list)
  } else {
    list
  }
}

///|
/// Arbitrary implementation for quickcheck testing.
/// 
/// Generates random lists for property-based testing with quickcheck.
pub impl[X : @quickcheck.Arbitrary] @quickcheck.Arbitrary for List[X] with arbitrary(
  size,
  rs,
) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> from_array
}

///|
/// Create a list with a single element.
/// 
/// Returns a list containing only the given element.
///
/// # Example
///
/// ```moonbit
///   let ls = @list.singleton(42)
///   assert_eq(ls, @list.of([42]))
///   assert_eq(ls.length(), 1)
/// ```
#as_free_fn
pub fn[A] List::singleton(x : A) -> List[A] {
  More(x, tail=Empty)
}

///|
/// Hash implementation for List.
/// 
/// Computes the hash value for a list by combining the hash values
/// of all its elements.
pub impl[A : Hash] Hash for List[A] with hash_combine(self, hasher) {
  for e in self {
    hasher.combine(e)
  }
}

///|
/// Reverse a list in-place (internal function).
/// 
/// This is an internal helper function that efficiently reverses a list
/// by modifying the existing structure rather than creating a completely new one.
fn[A] reverse_inplace(self : List[A]) -> List[A] {
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
