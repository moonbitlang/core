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

test "parse_int64_invalid_base" {
  @assertion.assert_eq(parse_int64("12345", base=1), Err(base_err))?
  @assertion.assert_eq(parse_int64("12345", base=37), Err(base_err))?
  @assertion.assert_eq(parse_int64("12345", base=-1), Err(base_err))?
  @assertion.assert_eq(parse_int64("12345", base=100), Err(base_err))?
}

test "parse_int64_uncovered_lines" {
  let tests : Array[(String, Int, Result[Int64, String])] = [
    // Test cases for uncovered lines in strconv/int.mbt:69
    ("A", 16, Ok(10L)),
    ("a", 16, Ok(10L)),
    ("Z", 36, Ok(35L)),
    ("z", 36, Ok(35L)),
    ("G", 16, Err(syntax_err)),
    ("g", 16, Err(syntax_err)),
    ("@", 16, Err(syntax_err)),
    ("`", 16, Err(syntax_err)),
    ("[", 16, Err(syntax_err)),
    ("{", 16, Err(syntax_err)),
  ]
  for i = 0; i < tests.length(); i = i + 1 {
    let t = tests[i]
    @assertion.assert_eq(parse_int64(t.0, base=t.1), t.2)?
  }
}
