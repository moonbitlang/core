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
/// Convert char array to string.
///
/// ```mbt check
/// test {
///   let s = String::from_array(['H', 'e', 'l', 'l', 'o'])
///   assert_eq(s, "Hello")
/// }
/// ```
///
/// Do not convert large data to `Array[Char]` and build a string with `String::from_array`.
///
/// For efficiency considerations, it's recommended to use `Buffer` instead.
#deprecated
pub fn from_array(chars : ArrayView[Char]) -> String {
  String::from_array(chars)
}

///|
/// Convert char iterator to string,
#deprecated
pub fn from_iter(iter : Iter[Char]) -> String {
  String::from_iter(iter)
}

///|
/// Convert char iterator to string,
#deprecated
pub fn from_iterator(iter : Iter[Char]) -> String {
  String::from_iter(iter)
}

///|
/// same as `String::default`
pub fn default() -> String {
  ""
}
