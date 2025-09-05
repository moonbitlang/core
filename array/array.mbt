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
/// Creates a new array containing all elements from an iterator.
///
/// Parameters:
///
/// * `iterator` : An iterator containing elements of type `T`.
///
/// Returns a new array containing all elements from the iterator in the same
/// order.
///
/// Example:
///
/// ```moonbit
///   let iter = Iter::singleton(42)
///   let arr = Array::from_iter(iter)
///   inspect(arr, content="[42]")
/// ```
pub fn[T] Array::from_iter(iter : Iter[T]) -> Array[T] {
  iter.collect()
}

///|
/// Adds all elements from an iterator to the end of the array.
///
/// This function iterates over each element in the provided iterator
/// and adds them to the array using the `push` method.
///
/// # Example
/// ```mbt
///   let u = [1, 2, 3]
///   let v = [4, 5, 6]
///   u.push_iter(v.iter())
///   assert_eq(u, [1, 2, 3, 4, 5, 6])
/// ```
pub fn[T] Array::push_iter(self : Self[T], iter : Iter[T]) -> Unit {
  for x in iter {
    self.push(x)
  }
}

///|
/// Shuffle the array using Knuth shuffle
/// 
/// To use this function, you need to provide a rand function, which takes an integer as it upper bound
/// and returns an integer.
/// *rand n* is expected to returns a uniformly distribution integer between 0 and n - 1
/// # Example
/// 
/// ```moonbit
///   let arr = [1, 2, 3, 4, 5]
///   fn rand(upper : Int) -> Int {
///     let rng = @random.Rand::new()
///     rng.int(limit=upper)
///   }
///   Array::shuffle_in_place(arr, rand=rand)
/// ```
pub fn[T] shuffle_in_place(self : Array[T], rand~ : (Int) -> Int) -> Unit {
  let n = self.length()
  for i = n - 1; i > 0; i = i - 1 {
    let j = rand(i + 1) % (i + 1)
    // for safety, perf is not a concern here
    // TODO: maybe return an error later
    self.swap(i, j)
  }
}

///|
/// Shuffle the array using Knuth shuffle
/// 
/// To use this function, you need to provide a rand function, which takes an integer as it upper bound
/// and returns an integer.
/// *rand n* is expected to returns a uniformly distribution integer between 0 and n - 1
/// # Example
/// 
/// ```mbt
///   let arr = [1, 2, 3, 4, 5]
///   fn rand(upper : Int) -> Int {
///     let rng = @random.Rand::new()
///     rng.int(limit=upper)
///   }
///   let _shuffled = Array::shuffle(arr, rand=rand)
/// ```
pub fn[T] shuffle(self : Array[T], rand~ : (Int) -> Int) -> Array[T] {
  let new_arr = self.copy()
  Array::shuffle_in_place(new_arr, rand~)
  new_arr
}

///|
/// Returns a new array containing the elements of the original array that satisfy the given predicate.
/// 
/// # Arguments
/// 
/// * `self` - The array to filter.
/// * `f` - The predicate function.
/// 
/// # Returns
/// 
pub fn[A, B] filter_map(
  self : Array[A],
  f : (A) -> B? raise?,
) -> Array[B] raise? {
  let result = []
  for x in self {
    if f(x) is Some(x) {
      result.push(x)
    }
  }
  result
}

///|
/// Returns the last element of the array, or `None` if the array is empty.
///
/// Parameters:
///
/// * `array` : The array to get the last element from.
///
/// Returns an optional value containing the last element of the array. The
/// result is `None` if the array is empty, or `Some(x)` where `x` is the last
/// element of the array.
///
/// Example:
///
/// ```moonbit
///   let arr = [1, 2, 3]
///   inspect(arr.last(), content="Some(3)")
///   let empty : Array[Int] = []
///   inspect(empty.last(), content="None")
/// ```
pub fn[A] last(self : Array[A]) -> A? {
  match self {
    [] => None
    [.., last] => Some(last)
  }
}

///|
/// Zips two arrays into a single array of tuples.
///
/// Parameters:
///
/// * `self` : The first array.
/// * `other` : The second array.
///
/// Returns an array of tuples, where each tuple contains corresponding elements
/// from the two input arrays.
///
/// Example:
///
/// ```moonbit
///   let arr1 = [1, 2, 3]
///   let arr2 = ['a', 'b', 'c']
///   inspect(arr1.zip(arr2), content="[(1, 'a'), (2, 'b'), (3, 'c')]")
/// ```
pub fn[A, B] zip(self : Array[A], other : Array[B]) -> Array[(A, B)] {
  let length = if self.length() < other.length() {
    self.length()
  } else {
    other.length()
  }
  let arr = Array::new(capacity=length)
  for i in 0..<length {
    arr.push((self[i], other[i]))
  } else {
    return arr
  }
}

///|
/// Splits an array of pairs into two arrays, separating the first and second elements.
///
/// # Example
/// ```moonbit
///   let arr = [(1, "a"), (2, "b"), (3, "c")]
///   let (nums, strs) = arr.unzip()
///   inspect(nums, content="[1, 2, 3]")
///   inspect(strs, content="[\"a\", \"b\", \"c\"]")
/// ```
pub fn[T1, T2] unzip(self : Array[(T1, T2)]) -> (Array[T1], Array[T2]) {
  let arr1 : Array[T1] = Array::new(capacity=self.length())
  let arr2 : Array[T2] = Array::new(capacity=self.length())
  for pair in self {
    let (x, y) = pair
    arr1.push(x)
    arr2.push(y)
  }
  (arr1, arr2)
}

///|
/// Zips two arrays into a single array by applying a function to each pair of elements.
///
/// Parameters:
///
/// * `l` : The first array.
/// * `r` : The second array.
/// * `merge` : A function that takes two arguments, one from each array, and returns a value.
///
/// Returns an array containing the results of applying the function to each pair of elements.
///
/// Example:
///
/// ```moonbit
///   let arr1 = [1, 2, 3]
///   let arr2 = [4, 5, 6]
///   let add = (a, b) => a + b
///   inspect(@array.zip_with(arr1, arr2, add), content="[5, 7, 9]")
/// ```
pub fn[A, B, C] zip_with(
  l : Array[A],
  r : Array[B],
  merge : (A, B) -> C raise?,
) -> Array[C] raise? {
  let length = if l.length() < r.length() { l.length() } else { r.length() }
  let arr = Array::new(capacity=length)
  for i in 0..<length {
    arr.push(merge(l[i], r[i]))
  } else {
    return arr
  }
}

///|
/// Zips two arrays into an iterator that yields corresponding elements.
///
/// Parameters:
///
/// * `self` : The first array.
/// * `other` : The second array.
///
/// Returns an `Iter2` iterator that produces corresponding elements
/// from both arrays. The iteration continues until the shorter array is exhausted.
///
/// Example:
///
/// ```moonbit
///   let arr1 = [1, 2, 3]
///   let arr2 = ['a', 'b', 'c']
///   inspect(arr1.zip_to_iter2(arr2).to_array(), content="[(1, 'a'), (2, 'b'), (3, 'c')]")
/// ```
pub fn[A, B] zip_to_iter2(self : Array[A], other : Array[B]) -> Iter2[A, B] {
  Iter2::new(yield_ => {
    let length = if self.length() < other.length() {
      self.length()
    } else {
      other.length()
    }
    for i in 0..<length {
      if yield_(self[i], other[i]) is IterEnd {
        break IterEnd
      }
    } else {
      IterContinue
    }
  })
}

///|
pub impl[X : @quickcheck.Arbitrary] @quickcheck.Arbitrary for Array[X] with arbitrary(
  size,
  rs,
) {
  let len = if size == 0 { 0 } else { rs.next_positive_int() % size }
  Array::makei(len, x => X::arbitrary(x, rs))
}

///|
/// Join an array of strings using the provided `separator`.
///
/// Parameters:
///   * `separator` : The string inserted between each element.
///
/// Returns a single concatenated `String`.
/// # Example:
/// ```moonbit
/// let s = "hello world"
/// inspect(s.split(" ").to_array().join(":"), content="hello:world")
/// ```
pub fn[A : @string.ToStringView] Array::join(
  self : Array[A],
  separator : @string.View,
) -> String {
  self[:].join(separator)
}
