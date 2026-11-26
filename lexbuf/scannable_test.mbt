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
priv struct TextCursor {
  input : StringView
  mut offset : Int32
}

///|
impl @lexbuf.Scannable for TextCursor with fn scan_input(self) {
  self.input
}

///|
impl @lexbuf.Scannable for TextCursor with fn scan_cursor(self) {
  self.offset
}

///|
impl @lexbuf.Scannable for TextCursor with fn set_scan_cursor(self, cursor) {
  self.offset = cursor
}

///|
priv struct BytesCursor {
  input : BytesView
  mut offset : Int32
}

///|
impl @lexbuf.BytesScannable for BytesCursor with fn scan_input(self) {
  self.input
}

///|
impl @lexbuf.BytesScannable for BytesCursor with fn scan_cursor(self) {
  self.offset
}

///|
impl @lexbuf.BytesScannable for BytesCursor with fn set_scan_cursor(
  self,
  cursor,
) {
  self.offset = cursor
}

///|
fn[T : @lexbuf.Scannable] scan_text(target : T) -> Unit {
  lexscan target {
    re"^ab" => ()
    re"^." => ()
    _ => ()
  }
}

///|
fn[T : @lexbuf.BytesScannable] scan_bytes(target : T) -> Unit {
  lexscan target {
    reb"^.." => ()
    reb"^." => ()
    _ => ()
  }
}

///|
fn scan_text_at(input : StringView, offset : Int32) -> Int32 {
  let target = TextCursor::{ input, offset, }
  scan_text(target)
  target.offset
}

///|
fn scan_bytes_at(input : BytesView, offset : Int32) -> Int32 {
  let target = BytesCursor::{ input, offset, }
  scan_bytes(target)
  target.offset
}

///|
test "a Scannable value keeps its own cursor" {
  let target = TextCursor::{ input: "xxab\u{1F600}c"[2:], offset: 0, }
  scan_text(target)
  inspect(target.offset, content="2")
  scan_text(target)
  inspect(target.offset, content="4")
  scan_text(target)
  inspect(target.offset, content="5")
}

///|
test "a BytesScannable value keeps its own cursor" {
  let target = BytesCursor::{ input: b"xxabc"[2:], offset: 1, }
  scan_bytes(target)
  inspect(target.offset, content="3")
}

///|
test "text lexscan accepts character boundaries" {
  // "a😀b": a at 0, the pair at 1 and 2, b at 3.
  let input = "xa\u{1F600}b"[1:]
  inspect(scan_text_at(input, 0), content="1")
  inspect(scan_text_at(input, 1), content="3")
  inspect(scan_text_at(input, 3), content="4")
  inspect(scan_text_at(input, 4), content="4")
  inspect(scan_text_at("", 0), content="0")
  // An empty slice whose backing string starts later.
  inspect(scan_text_at("abc"[2:2], 0), content="0")
}

///|
test "byte lexscan accepts every offset in range" {
  let input = b"xabc"[1:]
  inspect(scan_bytes_at(input, 0), content="2")
  inspect(scan_bytes_at(input, 1), content="3")
  inspect(scan_bytes_at(input, 2), content="3")
  inspect(scan_bytes_at(input, 3), content="3")
  inspect(scan_bytes_at(b"", 0), content="0")
  inspect(scan_bytes_at(b"abc"[2:2], 0), content="0")
}

///|
test "panic text lexscan rejects a negative cursor" {
  scan_text_at("ab", -1) |> ignore
}

///|
test "panic text lexscan rejects a cursor past the end" {
  // The input is a slice: offset 2 exists in the string but not in the view.
  scan_text_at("abc"[:1], 2) |> ignore
}

///|
test "panic text lexscan rejects a cursor inside a surrogate pair" {
  scan_text_at("a\u{1F600}", 2) |> ignore
}

///|
test "panic text lexscan rejects a cursor inside a pair of a slice" {
  // "a😀": a at 0, the pair at 1 and 2.
  scan_text_at("xa\u{1F600}"[1:], 2) |> ignore
}

///|
test "panic text lexscan rejects a cursor past an empty slice" {
  scan_text_at("abc"[2:2], 1) |> ignore
}

///|
test "panic byte lexscan rejects a negative cursor" {
  scan_bytes_at(b"ab", -1) |> ignore
}

///|
test "panic byte lexscan rejects a cursor past the end" {
  scan_bytes_at(b"abc"[:1], 2) |> ignore
}

///|
test "StringScanner is Scannable" {
  let scanner = @lexbuf.StringScanner("xxab\u{1F600}c"[2:])
  scan_text(scanner)
  inspect(scanner.cursor, content="2")
  scan_text(scanner)
  inspect(scanner.cursor, content="4")
  // lexscan on it still works and continues from the cursor set above.
  let rest = lexscan scanner {
    re"^c" => "c"
    _ => "-"
  }
  inspect(rest, content="c")
  inspect(scanner.cursor, content="5")
}

///|
test "BytesScanner is BytesScannable" {
  let scanner = @lexbuf.BytesScanner(b"xxabc"[2:])
  scan_bytes(scanner)
  inspect(scanner.cursor, content="2")
}

///|
test "StringScanner set_scan_cursor accepts every character boundary" {
  // "a😀b": a at 0, the pair at 1 and 2, b at 3.
  let scanner = @lexbuf.StringScanner("xa\u{1F600}b"[1:])
  for cursor in [4, 3, 1, 0] {
    @lexbuf.Scannable::set_scan_cursor(scanner, cursor)
    assert_eq(scanner.cursor, cursor)
  }
  let empty = @lexbuf.StringScanner("abc"[2:2])
  @lexbuf.Scannable::set_scan_cursor(empty, 0)
  inspect(empty.cursor, content="0")
}

///|
test "BytesScanner set_scan_cursor accepts every offset in range" {
  let scanner = @lexbuf.BytesScanner(b"xabc"[1:])
  for cursor in [3, 0, 2] {
    @lexbuf.BytesScannable::set_scan_cursor(scanner, cursor)
    assert_eq(scanner.cursor, cursor)
  }
  let empty = @lexbuf.BytesScanner(b"abc"[2:2])
  @lexbuf.BytesScannable::set_scan_cursor(empty, 0)
  inspect(empty.cursor, content="0")
}

///|
test "panic StringScanner set_scan_cursor rejects a negative cursor" {
  let scanner = @lexbuf.StringScanner("ab")
  @lexbuf.Scannable::set_scan_cursor(scanner, -1)
}

///|
test "panic StringScanner set_scan_cursor rejects a pair inside a slice" {
  // "a😀": a at 0, the pair at 1 and 2.
  let scanner = @lexbuf.StringScanner("xa\u{1F600}"[1:])
  @lexbuf.Scannable::set_scan_cursor(scanner, 2)
}

///|
test "panic BytesScanner set_scan_cursor rejects a cursor past the end" {
  let scanner = @lexbuf.BytesScanner(b"abc"[:1])
  @lexbuf.BytesScannable::set_scan_cursor(scanner, 2)
}

///|
test "panic StringScanner set_scan_cursor rejects a cursor past the end" {
  let scanner = @lexbuf.StringScanner("abc"[:1])
  @lexbuf.Scannable::set_scan_cursor(scanner, 2)
}

///|
test "panic StringScanner set_scan_cursor rejects a cursor inside a pair" {
  let scanner = @lexbuf.StringScanner("a\u{1F600}")
  @lexbuf.Scannable::set_scan_cursor(scanner, 2)
}

///|
test "panic BytesScanner set_scan_cursor rejects a negative cursor" {
  let scanner = @lexbuf.BytesScanner(b"ab")
  @lexbuf.BytesScannable::set_scan_cursor(scanner, -1)
}
