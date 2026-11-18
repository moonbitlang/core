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
async test "Utf8Reader read_line consumes lines and handles line endings" {
  let source = @io.MemoryReader() <| writer => {
    writer.write(b"first\nsecond\r")
    writer.write(b"\nplain\rreturn\n")
    writer.write(@utf8.encode("最后一行"))
  }
  defer source.close()
  let reader = @io.Utf8Reader(source)
  let lines = []
  while reader.read_line() is Some(line) {
    lines.push(line)
  }
  json_inspect(lines, content=[
    "first", "second", "plain\rreturn", "最后一行",
  ])
  assert_eq(reader.read_line(), None)
}

///|
async test "Utf8Reader read_lines optionally preserves newline delimiters" {
  let source = @io.MemoryReader() <| writer => {
    writer.write(b"lf\ncrlf\r\nplain\r")
  }
  defer source.close()
  let reader = @io.Utf8Reader(source)
  json_inspect(reader.read_lines(include_newline=true), content=[
    "lf\n", "crlf\r\n", "plain\r",
  ])
}

///|
async test "Utf8Reader read_lines handles empty and newline-terminated input" {
  let empty_source = @io.MemoryReader(_ => ())
  defer empty_source.close()
  json_inspect(@io.Utf8Reader(empty_source).read_lines(), content=[])
  let terminated_source = @io.MemoryReader(writer => writer.write(b"one\ntwo\n"))
  defer terminated_source.close()
  json_inspect(@io.Utf8Reader(terminated_source).read_lines(), content=[
    "one", "two",
  ])
}

///|
async test "Utf8Reader read_line rejects malformed UTF-8" {
  let source = @io.MemoryReader(writer => writer.write(b"\xff\n"))
  defer source.close()
  try @io.Utf8Reader(source).read_line() catch {
    err => debug_inspect(err, content="MalformedText")
  } noraise {
    _ => fail("expected malformed text error")
  }
}
