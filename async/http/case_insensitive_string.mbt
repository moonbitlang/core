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
/// String type with case insensitive comparison (in the ASCII sense).
/// This type is implicitly convertible from `String` & string literal.
pub(all) struct CaseInsensitiveString(String) derive(@json.ToJson)

///|
pub impl Eq for CaseInsensitiveString with fn equal(x, y) {
  Compare::compare(x, y) == 0
}

///|
pub impl Compare for CaseInsensitiveString with fn compare(x, y) {
  x.0.compare_ignore_ascii_case(y.0)
}

///|
pub impl @debug.Debug for CaseInsensitiveString with fn to_repr(self) {
  @debug.Debug::to_repr(self.0)
}

///|
pub impl Show for CaseInsensitiveString with fn to_string(self) {
  self.0
}

///|
pub extend CaseInsensitiveString with Show::{to_string}

///|
pub impl Hash for CaseInsensitiveString with fn hash_combine(self, hasher) {
  for code in self.0.code_units() {
    let code = match code {
      'A'..<='Z' => code + ('a' - 'A')
      _ => code
    }
    hasher.combine_uint(code.to_uint())
  }
}
