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

///-----------------------------------------------------------------------------
/// @intrinsic %string.substring
fn unsafe_substring(str : String, start : Int, end : Int) -> String {
  let len = end - start
  let bytes = Bytes::new(len * 2)
  bytes.blit_from_string(0, str, start, len)
  bytes.sub_string(0, bytes.length())
}

///-----------------------------------------------------------------------------
/// Get substring of the string from [start] to [end] exclusive.
pub fn substring(
  self : String,
  ~start : Int = 0,
  ~end : Int = self.length()
) -> String {
  if start < 0 {
    abort("String::substring: start index is negative")
  }
  if end < 0 {
    abort("String::substring: end index is negative")
  }
  if start > end {
    abort("String::substring: start index is greater than end index")
  }
  if end > self.length() {
    abort(
      "String::substring: end index is greater than the length of the string",
    )
  }
  unsafe_substring(self, start, end)
}
