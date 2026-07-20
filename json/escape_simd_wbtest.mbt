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
test "need_escape SIMD blocks and scalar tail" {
  let cases : Array[(String, Bool, Bool)] = [
    ("", false, false),
    ("0123456", false, false),
    ("01234567", false, false),
    ("012345678", false, false),
    ("0123456\"", false, true),
    ("01234567\\", false, true),
    ("012345678901234\n", false, true),
    ("01234567/89", false, false),
    ("01234567/89", true, true),
    ("0123456😀", false, false),
  ]
  for case in cases {
    let (str, escape_slash, expected) = case
    @debug.assert_eq(need_escape(str, escape_slash), expected)
  }
}
