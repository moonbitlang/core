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
  @json.inspect(suffixes, content=["a🤣b", "🤣b", "b"])
  let suffixes_with_empty = view
    .suffixes(include_empty=true)
    .map(v => v.to_string())
    .collect()
  @json.inspect(suffixes_with_empty, content=["a🤣b", "🤣b", "b", ""])
  let suffixes_no_empty = view
    .suffixes(include_empty=false)
    .map(v => v.to_string())
    .collect()
  @json.inspect(suffixes_no_empty, content=["a🤣b", "🤣b", "b"])
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
  inspect(view.offset_of_nth_char(1), content="Some(1)")
  inspect(view.offset_of_nth_char(3), content="None")
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
test "StringView sub errors" {
  let s = "A😀B"
  inspect(try? s[0:2], content="Err(InvalidIndex)")
  inspect(try? s[0:10], content="Err(IndexOutOfBounds)")
  let view = s[1:-1]
  inspect(try? view[:1], content="Err(InvalidIndex)")
  inspect(try? view[0:10], content="Err(IndexOutOfBounds)")
  let slice = "abcd"[:][1:-1]
  inspect(slice.to_string(), content="bc")
  let tail = "abcd"[-2:]
  inspect(tail.to_string(), content="cd")
  let tail_view = "abcd"[:][-2:]
  inspect(tail_view.to_string(), content="cd")
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
test "String::sub invalid start index" {
  let s = "\u{1F600}A"
  inspect(try? s[1:], content="Err(InvalidIndex)")
}

///|
test "StringView::sub invalid start index" {
  let view = "\u{1F600}A"[:]
  inspect(try? view[1:], content="Err(InvalidIndex)")
}
