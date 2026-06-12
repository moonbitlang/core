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
  let suffixes = view.suffixes().map(v => v.to_owned()).collect()
  @json.json_inspect(suffixes, content=["a🤣b", "🤣b", "b"])
  let suffixes_with_empty = view
    .suffixes(include_empty=true)
    .map(v => v.to_owned())
    .collect()
  @json.json_inspect(suffixes_with_empty, content=["a🤣b", "🤣b", "b", ""])
  let suffixes_no_empty = view
    .suffixes(include_empty=false)
    .map(v => v.to_owned())
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
test "StringView::code_units" {
  let view = "ZA😀BY"[1:-1]
  let units = view.code_units()
  inspect(units.length(), content="4")
  inspect(units.unsafe_get(0), content="65")
  inspect(units.unsafe_get(1), content="55357")
  inspect(units.unsafe_get(2), content="56832")
  inspect(units.unsafe_get(3), content="66")
  let mut sum = 0
  for unit in units {
    sum += unit.to_int()
  }
  inspect(sum, content="112320")
}

///|
test "StringView core operations" {
  let view = "ab😀c".view(start_offset=1)
  inspect(view.char_length(), content="3")
  inspect(view.char_length_eq(3), content="true")
  inspect(view.char_length_ge(4), content="false")
  let buf = StringBuilder()
  let it = view.iter2()
  while it.next() is Some((i, ch)) {
    buf.write_string("\{i}:\{ch};")
  }
  inspect(buf.to_string(), content="0:b;1:😀;2:c;")
  let from_arr = StringView::from_array(['x', 'y'])
  inspect(from_arr.to_owned(), content="xy")
  let from_iter = StringView::from_iter(['m', 'n'].iter())
  inspect(from_iter.to_owned(), content="mn")
  let make_view = StringView::make(3, 'a')
  inspect(make_view.to_owned(), content="aaa")
  inspect(StringView::default(), content="")
  inspect(("hi"[:] + "!").to_owned(), content="hi!")
  debug_inspect(view.offset_of_nth_char(1), content="Some(1)")
  debug_inspect(view.offset_of_nth_char(3), content="None")
}

///|
test "StringView::all and any" {
  let view = "Za😀b!"[1:-1]
  inspect(""[0:0].all(c => c == 'x'), content="true")
  inspect(""[0:0].any(c => c == 'x'), content="false")
  inspect(view.all(c => c == 'a' || c == '😀' || c == 'b'), content="true")
  inspect(view.all(c => c.is_ascii_lowercase()), content="false")
  inspect(view.every(c => c == 'a' || c == '😀' || c == 'b'), content="true")
  inspect(view.any(c => c == '😀'), content="true")
  inspect(view.any(c => c.is_ascii_digit()), content="false")
  inspect(view.exists(c => c == 'b'), content="true")

  let mut any_calls = 0
  inspect(
    view.any(c => {
      any_calls += 1
      c == '😀'
    }),
    content="true",
  )
  inspect(any_calls, content="2")

  let mut all_calls = 0
  inspect(
    view.all(c => {
      all_calls += 1
      c != '😀'
    }),
    content="false",
  )
  inspect(all_calls, content="2")
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
  inspect(slice.to_owned(), content="bc")
  let tail = "abcd"[-2:]
  inspect(tail.to_owned(), content="cd")
  let tail_view = "abcd"[:][-2:]
  inspect(tail_view.to_owned(), content="cd")
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
  debug_inspect(
    view.iter2().to_array(),
    content=(
      #|[(0, 'a'), (1, 'b'), (2, 'c')]
    ),
  )
  inspect(view == "ab", content="false")
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
  inspect(s[6:].to_owned(), content="world")
  inspect(s[:5].to_owned(), content="hello")
  inspect(s[6:11].to_owned(), content="world")
}

///|
test "StringView::to_string full view returns backing string unchanged" {
  let s = "hello"
  let v = s[:]
  // When the view covers the whole backing string, no copy is made.
  @test.assert_eq(v.to_owned(), s)
}

///|
test "StringView::to_string empty view" {
  let v = "abc"[1:1]
  inspect(v.to_owned(), content="")
  @test.assert_eq(v.to_owned().length(), 0)
}

///|
test "StringView::to_string multibyte" {
  // BMP-out chars are 2 UTF-16 code units; slice by code units.
  let s = "hi \u{1F600}!"
  inspect(s[3:5].to_owned(), content="\u{1F600}")
}

///|
test "StringView::to_string is independent of data()" {
  // `data` returns the whole backing string; `to_string` returns just the
  // slice.
  let s = "hello world"
  let v = s[6:]
  @test.assert_eq(v.data(), "hello world")
  @test.assert_eq(v.to_owned(), "world")
}

///|
test "String::get_view" {
  let s = "Hello🤣World"
  debug_inspect(
    s.get_view().map(v => v.to_owned()),
    content=(
      #|Some("Hello🤣World")
    ),
  )
  debug_inspect(
    s.get_view(end=5).map(v => v.to_owned()),
    content=(
      #|Some("Hello")
    ),
  )
  debug_inspect(
    s.get_view(start=-5).map(v => v.to_owned()),
    content=(
      #|Some("World")
    ),
  )
  debug_inspect(
    s.get_view(start=0, end=0).map(v => v.to_owned()),
    content=(
      #|Some("")
    ),
  )
  // Out of bounds.
  debug_inspect(s.get_view(start=100), content="None")
  debug_inspect(s.get_view(end=100), content="None")
  debug_inspect(s.get_view(start=3, end=2), content="None")
  // Splitting a surrogate pair.
  debug_inspect(s.get_view(end=6), content="None")
  debug_inspect(s.get_view(start=6), content="None")
}

///|
test "StringView::get_view" {
  let s = "Hello🤣World"
  let view = s[1:-1] // "ello🤣Worl"
  debug_inspect(
    view.get_view().map(v => v.to_owned()),
    content=(
      #|Some("ello🤣Worl")
    ),
  )
  debug_inspect(
    view.get_view(end=4).map(v => v.to_owned()),
    content=(
      #|Some("ello")
    ),
  )
  debug_inspect(
    view.get_view(start=-2).map(v => v.to_owned()),
    content=(
      #|Some("rl")
    ),
  )
  // Out of bounds relative to the sub-view.
  debug_inspect(view.get_view(start=100), content="None")
  debug_inspect(view.get_view(end=100), content="None")
  // Splitting a surrogate pair.
  debug_inspect(view.get_view(end=5), content="None")
  // Pattern-match composition: the optional form is matchable.
  guard s.get_view(end=5) is Some("Hello")
}

///|
test "StringView::equal_to_string" {
  let s = "say hello to everyone"
  // Sub-view of "hello" matches the owned string.
  inspect(
    s.view(start_offset=4, end_offset=9).equal_to_string("hello"),
    content="true",
  )
  // Same length, different content.
  inspect(
    s.view(start_offset=4, end_offset=9).equal_to_string("world"),
    content="false",
  )
  // Length mismatch short-circuits.
  inspect(
    s.view(start_offset=4, end_offset=9).equal_to_string("hell"),
    content="false",
  )
  inspect(
    s.view(start_offset=4, end_offset=9).equal_to_string("hello!"),
    content="false",
  )
  // Empty view vs empty string.
  inspect(""[:].equal_to_string(""), content="true")
  // Full view of the same backing string takes the physical-equal fast path.
  inspect(s[:].equal_to_string(s), content="true")
  // Multi-byte (surrogate pair) content compares correctly.
  let smile = "Hello🤣World"
  inspect(smile[:].equal_to_string("Hello🤣World"), content="true")
  inspect(smile[5:7].equal_to_string("🤣"), content="true")
}

///|
/// `Show::output` for `StringView` must agree with `Show::to_string` and write
/// the raw view contents (no quoting/escaping), matching the behavior of
/// `Show` for `String`.
test "StringView Show output matches to_string" {
  fn via_output(v : StringView) {
    let sb = StringBuilder()
    sb.write_object(v)
    sb.to_string()
  }

  let cases = [
    "", "hello", "quote\"and\\back", "line1\nline2", "Hello🤣World",
  ]
  for case in cases {
    let v = case[:]
    @test.assert_eq(via_output(v), Show::to_string(v))
    @test.assert_eq(via_output(v), case)
  }
  // Sub-view also produces raw, unescaped contents.
  let s = "ab\"cd"
  inspect(s[1:4], content="b\"c")
}
