// Copyright 2026 International Digital Economy Academy
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
/// Returns the smallest power of two greater than or equal to `self`.
/// This function will panic if `self` is negative. For values greater than
/// the largest representable power of two (2^30 = 1073741824), it returns
/// the largest representable power of two.
///
/// Example:
/// ```mbt check
/// test {
///   inspect((0).next_power_of_two(), content="1")
///   inspect((1).next_power_of_two(), content="1")
///   inspect((2).next_power_of_two(), content="2")
///   inspect((3).next_power_of_two(), content="4")
///   inspect((8).next_power_of_two(), content="8")
///   inspect((1073741824).next_power_of_two(), content="1073741824")
///   inspect((2000000000).next_power_of_two(), content="1073741824")
/// }
/// ```
pub fn Int::next_power_of_two(self : Int) -> Int {
  guard self >= 0
  if self <= 1 {
    return 1
  }
  // The largest power of 2 that fits in a 32-bit signed integer is 2^30
  let max_power_of_two = 1073741824 // 2^30
  if self > max_power_of_two {
    return max_power_of_two
  }
  // 2147483647 is the largest value of an integer
  (2147483647 >> ((self - 1).clz() - 1)) + 1
}

///|
/// Returns the minimum of two integers.
///
/// Example:
/// ```mbt check
/// test {
///   inspect((1).min(2), content="1")
///   inspect((2).min(1), content="1")
/// }
/// ```
pub fn Int::min(self : Int, other : Int) -> Int {
  if self < other {
    self
  } else {
    other
  }
}

///|
/// Returns the maximum of two integers.
///
/// Example:
/// ```mbt check
/// test {
///   inspect((1).max(2), content="2")
///   inspect((2).max(1), content="2")
/// }
/// ```
pub fn Int::max(self : Int, other : Int) -> Int {
  if self > other {
    self
  } else {
    other
  }
}

///|
/// Clamps the value `self` between `min` and `max`.
///
/// Example:
/// ```mbt check
/// test {
///   inspect((1).clamp(min=0, max=2), content="1")
///   inspect((-1).clamp(min=0, max=2), content="0")
///   inspect((3).clamp(min=0, max=2), content="2")
///   inspect((-1).clamp(min=0, max=2), content="0")
/// }
/// ```
pub fn Int::clamp(self : Int, min~ : Int, max~ : Int) -> Int {
  guard min <= max
  if self < min {
    min
  } else if self > max {
    max
  } else {
    self
  }
}

///|
/// Checks if the integer value represents a UTF-16 leading surrogate.
/// Leading surrogates are in the range 0xD800 to 0xDBFF.
///
/// Example:
/// ```mbt check
/// test {
///   inspect((0xD800).is_leading_surrogate(), content="true")
///   inspect((0xDBFF).is_leading_surrogate(), content="true")
///   inspect((0xDC00).is_leading_surrogate(), content="false")
///   inspect((0x41).is_leading_surrogate(), content="false") // 'A'
/// }
/// ```
pub fn Int::is_leading_surrogate(self : Int) -> Bool {
  0xD800 <= self && self <= 0xDBFF
}

///|
/// Checks if the integer value represents a UTF-16 trailing surrogate.
/// Trailing surrogates are in the range 0xDC00 to 0xDFFF.
///
/// Example:
/// ```mbt check
/// test {
///   inspect((0xDC00).is_trailing_surrogate(), content="true")
///   inspect((0xDFFF).is_trailing_surrogate(), content="true")
///   inspect((0xD800).is_trailing_surrogate(), content="false")
///   inspect((0x41).is_trailing_surrogate(), content="false") // 'A'
/// }
/// ```
pub fn Int::is_trailing_surrogate(self : Int) -> Bool {
  0xDC00 <= self && self <= 0xDFFF
}

///|
/// Checks if the integer value represents any UTF-16 surrogate (leading or trailing).
/// Surrogates are in the range 0xD800 to 0xDFFF.
///
/// Example:
/// ```mbt check
/// test {
///   inspect((0xD800).is_surrogate(), content="true") // leading surrogate
///   inspect((0xDC00).is_surrogate(), content="true") // trailing surrogate
///   inspect((0xDFFF).is_surrogate(), content="true") // trailing surrogate
///   inspect((0x41).is_surrogate(), content="false") // 'A'
///   inspect((0x1F600).is_surrogate(), content="false") // 😀 emoji codepoint
/// }
/// ```
pub fn Int::is_surrogate(self : Int) -> Bool {
  0xD800 <= self && self <= 0xDFFF
}

///|
/// Computes the absolute value of an integer.
///
/// Parameters:
///
/// * `self` : The integer whose absolute value is to be computed.
///
/// Returns the absolute value of the integer.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(Int::abs(42), content="42")
///   inspect(Int::abs(-42), content="42")
///   inspect(Int::abs(0), content="0")
/// }
/// ```
pub fn Int::abs(self : Int) -> Int {
  if self < 0 {
    -self
  } else {
    self
  }
}
