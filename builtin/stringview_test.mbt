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
test "StringView::suffixes" {
  let str = "za🤣b"
  let start = str.offset_of_nth_char(1).unwrap()
  let view = str.view(start_offset=start)
  let suffixes = view.suffixes().map(v => v.to_string()).collect()
  @json.json_inspect(suffixes, content=["a🤣b", "🤣b", "b"])
  let suffixes_with_empty = view
    .suffixes(include_empty=true)
    .map(v => v.to_string())
    .collect()
  @json.json_inspect(suffixes_with_empty, content=["a🤣b", "🤣b", "b", ""])
  let suffixes_no_empty = view
    .suffixes(include_empty=false)
    .map(v => v.to_string())
    .collect()
  @json.json_inspect(suffixes_no_empty, content=["a🤣b", "🤣b", "b"])
}

///|
test "code_unit_at" {
  let s = "Hello, 世界!😀"
  assert_true(s[:].code_unit_at(0) is 'H')
  assert_true(s[:].code_unit_at(7) is '世')
  assert_true(s[:].code_unit_at(8) is '界')
  assert_true(s[:].code_unit_at(0) is ('A'..='Z'))
  inspect(s[:].code_unit_at(0), content="72") // 'H'
  inspect(s[:].code_unit_at(7), content="19990") // '世'
  inspect(s[:].code_unit_at(8), content="30028") // '界'
  inspect(s[:].code_unit_at(10), content="55357") // High surrogate of '😀'
  inspect(s[:].code_unit_at(11), content="56832") // Low surrogate of '😀'
  let view = s[7:] // "世界!😀"
  inspect(view.code_unit_at(0), content="19990") // '世'
  inspect(view.code_unit_at(1), content="30028") // '界'
  inspect(view.code_unit_at(3), content="55357") // High surrogate of '😀'
  inspect(view.code_unit_at(4), content="56832") // Low surrogate of '😀'
}

///|
test "unsafe_get" {
  let s = "Hello, 世界!😀"
  inspect(s[:].unsafe_get(0), content="72") // 'H'
  inspect(s[:].unsafe_get(7), content="19990") // '世'
  inspect(s[:].unsafe_get(8), content="30028") // '界'
  inspect(s[:].unsafe_get(10), content="55357") // High surrogate of '😀'
  inspect(s[:].unsafe_get(11), content="56832") // Low surrogate of '😀'
  let view = s[7:] // "世界!😀"
  inspect(view.unsafe_get(0), content="19990") // '世'
  inspect(view.unsafe_get(1), content="30028") // '界'
  inspect(view.unsafe_get(3), content="55357") // High surrogate of '😀'
  inspect(view.unsafe_get(4), content="56832") // Low surrogate of '😀'
}

///|
test "StringView core operations" {
  let view = "ab😀c".view(start_offset=1)
  inspect(view.char_length(), content="3")
  inspect(view.char_length_eq(3), content="true")
  inspect(view.char_length_ge(4), content="false")
  let buf = StringBuilder::new()
  let it = view.iter2()
  while it.next() is Some((i, ch)) {
    buf.write_string("\{i}:\{ch};")
  }
  inspect(buf.to_string(), content="0:b;1:😀;2:c;")
  let from_arr = StringView::from_array(['x', 'y'])
  inspect(from_arr.to_string(), content="xy")
  let from_iter = StringView::from_iter(['m', 'n'].iter())
  inspect(from_iter.to_string(), content="mn")
  let make_view = StringView::make(3, 'a')
  inspect(make_view.to_string(), content="aaa")
  inspect(StringView::default(), content="")
  inspect(("hi"[:] + "!"[:]).to_string(), content="hi!")
  debug_inspect(view.offset_of_nth_char(1), content="Some(1)")
  debug_inspect(view.offset_of_nth_char(3), content="None")
}

///|
test "StringView comparisons" {
  let base = "hello"
  let v1 = base[:]
  let v2 = base[:]
  inspect(v1 == v2, content="true")
  let short = "hell"[:]
  inspect(v1.compare(short), content="1")
  let v3 = String::from_array(['h', 'e', 'l', 'l', 'o'])[:]
  inspect(v1 == v3, content="true")
  let v4 = "jello"[:]
  inspect(v1 == v4, content="false")
  inspect(v1.compare(v4), content="-1")
}

///|
test "StringView sub valid cases" {
  let slice = "abcd"[:][1:-1]
  inspect(slice.to_string(), content="bc")
  let tail = "abcd"[-2:]
  inspect(tail.to_string(), content="cd")
  let tail_view = "abcd"[:][-2:]
  inspect(tail_view.to_string(), content="cd")
}

///|
test "panic String::sub invalid index" {
  ignore("A😀B"[0:2])
}

///|
test "panic String::sub index out of bounds" {
  ignore("A😀B"[0:10])
}

///|
test "panic StringView::sub invalid index" {
  let s = "A😀B"
  let view = s[1:-1]
  ignore(view[:1])
}

///|
test "panic StringView::sub index out of bounds" {
  let s = "A😀B"
  let view = s[1:-1]
  ignore(view[0:10])
}

///|
test "panic StringView::at out of bounds" {
  ignore("abc"[:].at(10))
}

///|
test "panic StringView::view invalid range" {
  ignore("abc"[:].view(start_offset=2, end_offset=1))
}

///|
test "panic String::view invalid range" {
  ignore("abc".view(start_offset=2, end_offset=1))
}

///|
test "StringView iter2 and eq length mismatch" {
  let view = "abc"[:]
  inspect(view.iter2().to_string(), content="[(0, 'a'), (1, 'b'), (2, 'c')]")
  inspect(view == "ab"[:], content="false")
}

///|
test "StringView compare physical equal" {
  let s = "abc"
  let left = s[:]
  let right = s[:]
  inspect(left.compare(right), content="0")
}

///|
test "panic String::sub invalid start index" {
  let s = "\u{1F600}A"
  ignore(s[1:])
}

///|
test "panic StringView::sub invalid start index" {
  let view = "\u{1F600}A"[:]
  ignore(view[1:])
}

///|
test "StringView::to_string basic" {
  let s = "hello world"
  inspect(s[6:].to_string(), content="world")
  inspect(s[:5].to_string(), content="hello")
  inspect(s[6:11].to_string(), content="world")
}

///|
test "StringView::to_string full view returns backing string unchanged" {
  let s = "hello"
  let v = s[:]
  // When the view covers the whole backing string, no copy is made.
  assert_eq(v.to_string(), s)
}

///|
test "StringView::to_string empty view" {
  let v = "abc"[1:1]
  inspect(v.to_string(), content="")
  assert_eq(v.to_string().length(), 0)
}

///|
test "StringView::to_string multibyte" {
  // BMP-out chars are 2 UTF-16 code units; slice by code units.
  let s = "hi \u{1F600}!"
  inspect(s[3:5].to_string(), content="\u{1F600}")
}

///|
test "StringView::to_string is independent of data()" {
  // `data` returns the whole backing string; `to_string` returns just the
  // slice.
  let s = "hello world"
  let v = s[6:]
  assert_eq(v.data(), "hello world")
  assert_eq(v.to_string(), "world")
}
