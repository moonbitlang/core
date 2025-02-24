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
/// Compares and returns the maximum of two values.
///
/// Returns the second argument if the comparison determines them to be equal.
///
/// # Examples
///
/// ```
/// assert_eq!(@math.maximum(1, 2), 2)
/// assert_eq!(@math.maximum(2, 2), 2)
/// ```
pub fn maximum[T : Compare](x : T, y : T) -> T {
  if x > y {
    x
  } else {
    y
  }
}

///|
/// Compares and returns the minimum of two values.
///
/// Returns the first argument if the comparison determines them to be equal.
///
/// # Examples
///
/// ```
/// assert_eq!(@math.minimum(1, 2), 1)
/// assert_eq!(@math.minimum(2, 2), 2)
/// ```
pub fn minimum[T : Compare](x : T, y : T) -> T {
  if x > y {
    y
  } else {
    x
  }
}

///|
/// Calculates the cube root of a number.
///
/// # Examples
///
/// ```
/// assert_eq!(@math.cbrt(1), 1)
/// assert_eq!(@math.cbrt(27), 3)
/// assert_eq!(@math.cbrt(125), 5)
/// assert_eq!(@math.cbrt(1000), 10)
/// ```
pub fn cbrt(x : Double) -> Double {
  x.cbrt()
}

///|
/// Returns the hypotenuse of a right-angled triangle whose legs are `x` and `y`.
///
/// # Examples
///
/// ```
/// assert_eq!(@math.hypot(3, 4), 5)
/// assert_eq!(@math.hypot(5, 12), 13)
/// assert_eq!(@math.hypot(8, 15), 17)
/// ```
pub fn hypot(x : Double, y : Double) -> Double {
  x.hypot(y)
}
