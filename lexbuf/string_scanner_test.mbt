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
test "StringScanner starts at a character boundary" {
  let data = "ab\u{1F600}c"
  inspect(@lexbuf.StringScanner(data).cursor, content="0")
  inspect(@lexbuf.StringScanner(data, cursor=2).cursor, content="2")
  inspect(@lexbuf.StringScanner(data, cursor=4).cursor, content="4")
  inspect(@lexbuf.StringScanner(data, cursor=5).cursor, content="5")
  inspect(@lexbuf.StringScanner(""[:]).cursor, content="0")
}

///|
test "StringScanner cursor is relative to a sliced view" {
  let scanner = @lexbuf.StringScanner("xxabc"[2:], cursor=1)
  let word = lexscan scanner {
    re"^b+" as word => word.to_owned()
    _ => "-"
  }
  inspect(word, content="b")
  inspect(scanner.cursor, content="2")
}

///|
test "StringScanner::__unsafe_set_cursor sets the cursor" {
  let scanner = @lexbuf.StringScanner("abc")
  scanner.__unsafe_set_cursor(3)
  inspect(scanner.cursor, content="3")
}
