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
/// Calculates the difference between the Unicode code points of two characters.
///
/// Parameters:
///
/// * `self` : The first character whose code point serves as the minuend.
/// * `other` : The second character whose code point serves as the subtrahend.
///
/// Returns an integer representing the difference between the Unicode code
/// points of the two characters.
///
/// Example:
///
/// ```moonbit
/// test "Char::op_sub" {
///   let a = 'b'
///   let b = 'a'
///   inspect!(a - b, content="1") // Unicode point of 'b' (98) minus 'a' (97)
/// }
/// ```
pub fn Char::op_sub(self : Char, that : Char) -> Int {
  self.to_int() - that.to_int()
}
