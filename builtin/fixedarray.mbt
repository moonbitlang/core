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
/// @intrinsic %iter.from_array
pub fn iter[T](self : FixedArray[T]) -> Iter[T] {
  Iter::new(fn(yield_) {
    for v in self {
      guard let IterContinue = yield_(v) else { x => break x }

    } else {
      IterContinue
    }
  })
}

///|
pub fn iter2[T](self : FixedArray[T]) -> Iter2[Int, T] {
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
pub fn fill[T](self : FixedArray[T], value : T) -> Unit {
  for i in 0..<self.length() {
    self[i] = value
  }
}
