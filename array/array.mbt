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
/// test "Array::from_iter" {
///   let iter = Iter::singleton(42)
///   let arr = Array::from_iter(iter)
///   inspect!(arr, content="[42]")
/// }
/// ```
pub fn Array::from_iter[T](iter : Iter[T]) -> Array[T] {
  iter.collect()
}

///|
/// Adds all elements from an iterator to the end of the array.
///
/// This function iterates over each element in the provided iterator
/// and adds them to the array using the `push` method.
///
/// # Example
/// ```
/// let u = [1, 2, 3]
/// let v = [4, 5, 6]
/// u.push_iter(v.iter())
/// assert_eq!(u, [1, 2, 3, 4, 5, 6])
/// ```
pub fn push_iter[T](self : Array[T], iter : Iter[T]) -> Unit {
  for x in iter {
    self.push(x)
  }
}

///|
/// Creates a new array of the specified length, where each element is
/// initialized using an index-based initialization function.
///
/// Parameters:
///
/// * `length` : The length of the new array. If `length` is less than or equal
/// to 0, returns an empty array.
/// * `initializer` : A function that takes an index (starting from 0) and
/// returns a value of type `T`. This function is called for each index to
/// initialize the corresponding element.
///
/// Returns a new array of type `Array[T]` with the specified length, where each
/// element is initialized using the provided function.
///
/// Example:
///
/// ```moonbit
/// test "Array::makei" {
///   let arr = Array::makei(3, fn(i) { i * 2 })
///   inspect!(arr, content="[0, 2, 4]")
/// }
/// ```
pub fn Array::makei[T](length : Int, value : (Int) -> T) -> Array[T] {
  if length <= 0 {
    []
  } else {
    let array = Array::make(length, value(0))
    for i in 1..<length {
      array[i] = value(i)
    }
    array
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
/// ```
/// let arr = [1, 2, 3, 4, 5]
/// fn rand(upper : Int) -> Int {
///   let rng = @random.new()
///   rng.int(limit=upper)
/// }
/// Array::shuffle_in_place(arr, rand=rand)
/// ```
pub fn shuffle_in_place[T](self : Array[T], rand~ : (Int) -> Int) -> Unit {
  let n = self.length()
  for i = n - 1; i > 0; i = i - 1 {
    let j = rand(i + 1) % (i + 1)
    // for safety, perf is not a concern here
    // TODO: maybe return an error later
    self.swap(i, j)
  }
}

test {

}

///|
/// Shuffle the array using Knuth shuffle
/// 
/// To use this function, you need to provide a rand function, which takes an integer as it upper bound
/// and returns an integer.
/// *rand n* is expected to returns a uniformly distribution integer between 0 and n - 1
/// # Example
/// 
/// ```
/// let arr = [1, 2, 3, 4, 5]
/// fn rand(upper : Int) -> Int {
///   let rng = @random.new()
///   rng.int(limit=upper)
/// }
/// let _shuffled = Array::shuffle(arr, rand=rand)
/// ```
pub fn shuffle[T](self : Array[T], rand~ : (Int) -> Int) -> Array[T] {
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
pub fn filter_map[A, B](self : Array[A], f : (A) -> B?) -> Array[B] {
  let result = []
  self.each(fn {
    x =>
      match f(x) {
        None => ()
        Some(x) => result.push(x)
      }
  })
  result
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
/// @alert deprecated "Use `Array::filter_map` instead"
pub fn map_option[A, B](self : Array[A], f : (A) -> B?) -> Array[B] {
  self.filter_map(f)
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
/// test "last" {
///   let arr = [1, 2, 3]
///   inspect!(arr.last(), content="Some(3)")
///   let empty : Array[Int] = []
///   inspect!(empty.last(), content="None")
/// }
/// ```
pub fn last[A](self : Array[A]) -> A? {
  match self {
    [] => None
    [.., last] => Some(last)
  }
}

///|
pub impl[X : @quickcheck.Arbitrary] @quickcheck.Arbitrary for Array[X] with arbitrary(
  size,
  rs
) {
  let len = if size == 0 { 0 } else { rs.next_positive_int() % size }
  Array::makei(len, fn(x) { X::arbitrary(x, rs) })
}
