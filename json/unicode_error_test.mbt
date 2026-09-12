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
test "syntax errors preserve supplementary characters and their positions" {
  let cases : Array[(String, Int)] = [
    ("[true😀]", 5),
    ("{\"a\"😀0}", 4),
    ("{\"a\":true😀}", 9),
    ("{😀}", 1),
    ("{\"a\":0,😀}", 7),
    ("-😀", 1),
    ("1.😀", 2),
    ("1e😀", 2),
    ("1e+😀", 3),
    ("0😀", 1),
    ("12😀", 2),
    ("1.2😀", 3),
    ("1e2😀", 3),
  ]
  for (input, column) in cases {
    match expect_parse_error(input, "expected InvalidChar") {
      InvalidChar(position, ch) => {
        assert_eq(position.line, 1)
        assert_eq(position.column, column)
        assert_eq(ch, '😀')
      }
      _ => fail("expected InvalidChar")
    }
  }
}
