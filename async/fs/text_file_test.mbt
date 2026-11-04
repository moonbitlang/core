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
async test "write_text append keeps existing content" {
  let path = "_build/write_text_append_test"
  @fs.write_text(path, "first\n")
  defer @fs.remove(path)
  // `append=true` used to truncate the file before appending
  @fs.write_text(path, "second\n", append=true)
  inspect(
    @fs.read_text(path),
    content=(
      #|first
      #|second
      #|
    ),
  )
  @fs.write_binary(path, b"third\n", append=true)
  inspect(
    @fs.read_text(path),
    content=(
      #|first
      #|second
      #|third
      #|
    ),
  )
  // without `append`, the default still truncates
  @fs.write_text(path, "fourth\n")
  inspect(@fs.read_text(path), content="fourth\n")
}

///|
async test "write_text append creates missing file" {
  let path = "_build/write_text_append_create_test"
  @fs.remove(path) catch {
    _ => ()
  }
  @fs.write_binary(path, b"abc", append=true)
  defer @fs.remove(path)
  inspect(@fs.read_text(path), content="abc")
}
