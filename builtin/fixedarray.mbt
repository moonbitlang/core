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
/// @intrinsic %iter.from_array
pub fn FixedArray::iter[T](self : FixedArray[T]) -> Iter[T] {
  Iter::new(fn(yield_) {
    for v in self {
      guard let IterContinue = yield_(v) else { x => break x }

    } else {
      IterContinue
    }
  })
}

///|
pub fn FixedArray::iter2[T](self : FixedArray[T]) -> Iter2[Int, T] {
  Iter2::new(fn(yield_) {
    for i, v in self {
      guard let IterContinue = yield_(i, v) else { x => break x }

    } else {
      IterContinue
    }
  })
}

///|
pub fn FixedArray::default[X]() -> FixedArray[X] {
  []
}

///|
/// Fill the array with a given value.
///
/// # Example
/// ```
/// let fa : FixedArray[Int] = [0, 0, 0, 0, 0]
/// fa.fill(3)
/// assert_eq!(fa[0], 3)
/// ```
pub fn FixedArray::fill[T](self : FixedArray[T], value : T) -> Unit {
  for i in 0..<self.length() {
    self[i] = value
  }
}

///|
pub fn compare[T : Compare](self : FixedArray[T], other : FixedArray[T]) -> Int {
  let len_self = self.length()
  let len_other = other.length()
  if len_self < len_other {
    -1
  } else if len_self > len_other {
    1
  } else {
    for i in 0..<len_self {
      let cmp = self.unsafe_get(i).compare(other.unsafe_get(i))
      if cmp != 0 {
        break cmp
      }
    } else {
      0
    }
  }
}
