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

pub fn iter[T](self : Array[T]) -> Iter[T] {
  Iter::new(
    fn(yield) {
      for i = 0, len = self.length(); i < len; i = i + 1 {
        if yield(self[i]) == IterEnd {
          break IterEnd
        }
      } else {
        IterContinue
      }
    },
  )
}

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
/// ```
pub fn push_iter[T](self : Array[T], iter : Iter[T]) -> Unit {
  iter.each(fn { x => self.push(x) })
}

pub fn copy[T](self : Array[T]) -> Array[T] {
  let len = self.length()
  if len == 0 {
    []
  } else {
    let arr = Array::make(len, self[0])
    Array::unsafe_blit(arr, 0, self, 0, len)
    arr
  }
}

/// @alert deprecated "Use `Array::makei` instead"
pub fn Array::new_with_index[T](length : Int, value : (Int) -> T) -> Array[T] {
  if length <= 0 {
    []
  } else {
    let array = Array::make(length, value(0))
    for i = 1; i < length; i = i + 1 {
      array[i] = value(i)
    }
    array
  }
}

pub fn Array::makei[T](length : Int, value : (Int) -> T) -> Array[T] {
  if length <= 0 {
    []
  } else {
    let array = Array::make(length, value(0))
    for i = 1; i < length; i = i + 1 {
      array[i] = value(i)
    }
    array
  }
}

/// Shuffle the array using Knuth shuffle
/// 
/// To use this function, you need to provide a rand function, which takes an integer as it upper bound
/// and returns an integer.
/// *rand n* is expected to returns a uniformly distribution integer between 0 and n - 1
/// # Example
/// 
/// ```
/// fn rand(upper : Int) -> Int {
///   let rng = @random.RandomInt::new()
///   rng.summon() % upper
/// }
/// Array::shuffle_in_place(arr, ~rand=rand)
/// ```
pub fn Array::shuffle_in_place[T](arr : Array[T], ~rand : (Int) -> Int) -> Unit {
  let n = arr.length()
  for i = n - 1; i > 0; i = i - 1 {
    let j = rand(i + 1) % (i + 1)
    // for safety, perf is not a concern here
    // TODO: maybe return an error later
    arr.swap(i, j)
  }
}

/// Shuffle the array using Knuth shuffle
/// 
/// To use this function, you need to provide a rand function, which takes an integer as it upper bound
/// and returns an integer.
/// *rand n* is expected to returns a uniformly distribution integer between 0 and n - 1
/// # Example
/// 
/// ```
/// fn rand(upper : Int) -> Int {
///   let rng = @random.RandomInt::new()
///   rng.summon() % upper
/// }
/// let shuffled = Array::shuffle(arr, ~rand=rand)
/// ```
pub fn Array::shuffle[T](arr : Array[T], ~rand : (Int) -> Int) -> Array[T] {
  let new_arr = arr.copy()
  Array::shuffle_in_place(new_arr, ~rand)
  new_arr
}

/// Joins the elements of an array into a single string, using the specified separator.
///
/// # Arguments
///
/// * `self` - The array of strings to join.
/// * `sep` - The separator string to insert between each element.
///
/// # Returns
///
/// The joined string.
pub fn join[T : Show](self : Array[T], sep : String) -> String {
  let len = self.length()
  if len == 0 {
    return ""
  }
  let sep_size = sep.length() * (len - 1)
  let self_size = self[0].to_string().length() * (len + 1) // + 1 to avoid allocation in buffer
  let size = sep_size + self_size
  let buf = Buffer::new(size_hint=size + 1) // + 1 to avoid allocation in buffer
  buf.write_string(self[0].to_string())
  for i = 1; i < len; i = i + 1 {
    buf.write_string(sep)
    buf.write_string(self[i].to_string())
  }
  buf.to_string()
}
