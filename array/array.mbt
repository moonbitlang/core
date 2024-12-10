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

///|
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
pub fn Array::shuffle_in_place[T](arr : Array[T], rand~ : (Int) -> Int) -> Unit {
  let n = arr.length()
  for i = n - 1; i > 0; i = i - 1 {
    let j = rand(i + 1) % (i + 1)
    // for safety, perf is not a concern here
    // TODO: maybe return an error later
    arr.swap(i, j)
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
pub fn Array::shuffle[T](arr : Array[T], rand~ : (Int) -> Int) -> Array[T] {
  let new_arr = arr.copy()
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
pub fn map_option[A, B](self : Array[A], f : (A) -> B?) -> Array[B] {
  let result = []
  self.each(
    fn {
      x =>
        match f(x) {
          None => ()
          Some(x) => result.push(x)
        }
    },
  )
  result
}

///|
/// Returns the last element of the array.
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
