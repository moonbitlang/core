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
/// Parses a string into a `BigInt` using the specified base (2 to 36).
///
/// Returns an error if the input is malformed or the base is invalid.
///
/// # Example
///
/// ```mbt check
/// test {
///   inspect(@string.parse_bigint("12345"), content="12345")
///   inspect(@string.parse_bigint("-ff", base=16), content="-255")
/// }
/// ```
pub fn parse_bigint(str : StringView, base? : Int = 10) -> @bigint.BigInt raise {
  @bigint.parse_bigint(str, base~)
}
