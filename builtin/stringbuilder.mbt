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
/// Writes the string representation of a object to the StringBuilder.
pub fn StringBuilder::write_object[T : Show](
  self : StringBuilder,
  obj : T
) -> Unit {
  obj.output(self)
}

///|
/// Writes characters from an iterator to the StringBuilder. 
///
/// Parameters:
///
/// * `self` : The StringBuilder to write to.
/// * `iter` : An iterator yielding characters to write.
///
/// Example:
///
/// ```moonbit
/// test "write_iter" {
///   let sb = StringBuilder::new()
///   let chars = "Hello🤣".iter()
///   sb.write_iter(chars)
///   assert_eq!(sb.to_string(), "Hello🤣")
/// }
/// ```
pub fn StringBuilder::write_iter(
  self : StringBuilder,
  iter : Iter[Char]
) -> Unit {
  for ch in iter {
    self.write_char(ch)
  }
}
