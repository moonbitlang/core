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
test "String::default implementation" {
  let s : String = String::default()
  inspect(s, content="")
  inspect(s.length(), content="0")
}

///|
test "String iter2 with surrogate pairs" {
  let s = "Hello🙂World"

  // Convert iter2 to array for inspection
  let result = []
  let mut i = 0
  s
  .iter2()
  .each((idx, c) => {
    if i < 3 {
      result.push((idx, c))
    }
    i = i + 1
  })
  inspect(result, content="[(0, 'H'), (1, 'e'), (2, 'l')]")

  // Count characters using iter2
  let mut count = 0
  s.iter2().each((_, _) => count = count + 1)
  inspect(count, content="11") // 5 chars + emoji + 5 chars
}

///|
test "String::offset_of_nth_char_forward with special case" {
  let s = "Hello"
  let result = s.offset_of_nth_char(4) // Last character
  inspect(result, content="Some(4)")
  let result2 = s.offset_of_nth_char(5) // Beyond last character
  inspect(result2, content="None")
}

///|
test "View::pad_start and pad_end no padding" {
  let v = "abc"[1:3] // "bc"
  inspect(v.pad_start(2, 'x'), content="bc")
  inspect(v.pad_end(2, 'y'), content="bc")
}

///|
test "View::compare identical" {
  let str = "abcdef"
  let v = str.view(start_offset=2, end_offset=4)
  inspect(v.compare(v), content="0")
}

///|
test "View::default and hash" {
  let v : StringView = StringView::default()
  inspect(v, content="")
  let v1 = "abc".view()
  let v2 = "abc".view()
  assert_eq(v1.hash(), v2.hash())
}

///|
test "get_char invalid surrogate pair" {
  let s = String::from_array([(0xD800).unsafe_to_char(), 'A'])
  inspect(s.get_char(0), content="None")
  let v = s[:]
  inspect(v.get_char(0), content="None")
}
