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
async test "text file" {
  let path = "_build/basic_text_file_test"
  @fs.write_text(path, "abcd")
  defer @fs.remove(path)
  inspect(@fs.read_text(path), content="abcd")
}

///|
async test "read text file as lines" {
  let path = "_build/read_lines_text_file_test"
  @fs.write_text(path, "first\nsecond\r\nplain\rreturn\nlast")
  defer @fs.remove(path)
  json_inspect(@fs.read_lines(path), content=[
    "first", "second", "plain\rreturn", "last",
  ])
  json_inspect(@fs.read_lines(path, include_newline=true), content=[
    "first\n", "second\r\n", "plain\rreturn\n", "last",
  ])
  let file = @fs.open(path, mode=ReadOnly)
  defer file.close()
  guard file.text.read_line() is Some(first) else {
    fail("expected first line")
  }
  inspect(first, content="first")
  json_inspect(file.text.read_lines(), content=[
    "second", "plain\rreturn", "last",
  ])
}
