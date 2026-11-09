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
/// What generated `lexscan` code does with a `Scannable` value: read the input
/// and the checked cursor once, then commit the end of the match.
fn[T : @lexbuf.Scannable] skip_text(target : T, n : Int32) -> Int32 {
  let input = T::scan_input(target)
  let cursor = @lexbuf.__check_scan_cursor(input, T::scan_cursor(target))
  T::set_scan_cursor(target, cursor + n)
  cursor
}

///|
fn[T : @lexbuf.BytesScannable] skip_bytes(target : T, n : Int32) -> Int32 {
  let input = T::scan_input(target)
  let cursor = @lexbuf.__check_bytes_scan_cursor(input, T::scan_cursor(target))
  T::set_scan_cursor(target, cursor + n)
  cursor
}

///|
test "a Scannable value keeps its own cursor" {
  let target = TextCursor::{ input: "xxab\u{1F600}c"[2:], offset: 0, }
  inspect(skip_text(target, 2), content="0")
  inspect(target.offset, content="2")
  inspect(skip_text(target, 2), content="2")
  inspect(target.offset, content="4")
  inspect(skip_text(target, 1), content="4")
  inspect(target.offset, content="5")
}

///|
test "a BytesScannable value keeps its own cursor" {
  let target = BytesCursor::{ input: b"xxabc"[2:], offset: 1, }
  inspect(skip_bytes(target, 2), content="1")
  inspect(target.offset, content="3")
}

///|
test "__check_scan_cursor accepts character boundaries" {
  // "a😀b": a at 0, the pair at 1 and 2, b at 3.
  let input = "xa\u{1F600}b"[1:]
  inspect(@lexbuf.__check_scan_cursor(input, 0), content="0")
  inspect(@lexbuf.__check_scan_cursor(input, 1), content="1")
  inspect(@lexbuf.__check_scan_cursor(input, 3), content="3")
  inspect(@lexbuf.__check_scan_cursor(input, 4), content="4")
  inspect(@lexbuf.__check_scan_cursor("", 0), content="0")
}

///|
test "__check_bytes_scan_cursor accepts every offset in range" {
  let input = b"xabc"[1:]
  inspect(@lexbuf.__check_bytes_scan_cursor(input, 0), content="0")
  inspect(@lexbuf.__check_bytes_scan_cursor(input, 3), content="3")
}

///|
test "panic __check_scan_cursor rejects a negative cursor" {
  @lexbuf.__check_scan_cursor("ab", -1) |> ignore
}

///|
test "panic __check_scan_cursor rejects a cursor past the end" {
  // The input is a slice: offset 2 exists in the string but not in the view.
  @lexbuf.__check_scan_cursor("abc"[:1], 2) |> ignore
}

///|
test "panic __check_scan_cursor rejects a cursor inside a surrogate pair" {
  @lexbuf.__check_scan_cursor("a\u{1F600}", 2) |> ignore
}

///|
test "panic __check_bytes_scan_cursor rejects a negative cursor" {
  @lexbuf.__check_bytes_scan_cursor(b"ab", -1) |> ignore
}

///|
test "panic __check_bytes_scan_cursor rejects a cursor past the end" {
  @lexbuf.__check_bytes_scan_cursor(b"abc"[:1], 2) |> ignore
}
