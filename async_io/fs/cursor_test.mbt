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
async test "sequential read/write have separated cursor" {
  let path = "_build/read_write_cursor_test"
  @fs.write_text(path, "abcd", sync=Full)
  defer @fs.remove(path)
  let file = @fs.open(path, mode=ReadWrite)
  defer file.close()
  file.write(b"AB")
  // the read cursor should not be modified by the `write` operation above
  json_inspect(file.read_exactly(2), content="AB")
}

///|
async test "append mode only affect writing" {
  let path = "_build/append_cursor_test"
  @fs.write_text(path, "abcd", sync=Full)
  defer @fs.remove(path)
  let file = @fs.open(path, append=true, mode=ReadWrite)
  defer file.close()
  // the read cursor should not be affected by `append`
  json_inspect(file.read_exactly(2), content="ab")
  // writing should append to EOF automatically
  file.write(b"ef")
  // read cursor is unaffected by append write
  json_inspect(file.read_exactly(2), content="cd")
  json_inspect(file.read_exactly(2), content="ef")
}

///|
async test "append mode file does not support random access write" {
  let path = "_build/append_random_access_test"
  @fs.write_text(path, "abcd", sync=Full)
  defer @fs.remove(path)
  let file = @fs.open(path, append=true, mode=ReadWrite)
  defer file.close()
  // random access read is not affected
  json_inspect(file.read_exactly_at(2, position=2), content="cd")
  // random access write is forbidden for append-mode file
  debug_inspect(
    @test_util.expect_error_async(() => file.write_at(b"CD", position=2)),
    content=(
      #|Failure("`write_at` is not supported on non-regular file or file opened in append mode")
    ),
  )
}
