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

// The string engine takes these as a `Profile`; bytes have only one.

///|
/// The bytes of `[[:word:]]`, `\b` and `\B`: ASCII letters, digits and `_`.
pub let word_set : ByteSet = ByteSet::char_range('a', 'z') +
  ByteSet::char_range('A', 'Z') +
  ByteSet::char_range('0', '9') +
  ByteSet::char('_')

///|
/// Category of a byte for look-around, as the string engine's Unicode
/// profile categorizes ASCII. Every byte above `0x7F` is a non-word byte.
fn category(c : Int32) -> Category {
  match c {
    'a'..<='z' | 'A'..<='Z' | '0'..<='9' | '_' => Category::word()
    '\n' => Category::newline() + Category::not_word()
    _ => Category::not_word()
  }
}
