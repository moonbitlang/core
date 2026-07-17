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
test "clamped_view on BMP text behaves like plain slicing" {
  let s = "hello world"
  inspect(s.clamped_view(end=5), content="hello")
  inspect(s.clamped_view(start=6), content="world")
  inspect(s.clamped_view(start=3, end=8), content="lo wo")
  inspect(s.clamped_view(), content="hello world")
}

///|
test "clamped_view snaps surrogate-splitting offsets inward" {
  let s = "ab😀cd" // 😀 occupies units 2 and 3
  inspect(s.clamped_view(end=3), content="ab")
  inspect(s.clamped_view(start=3), content="cd")
  inspect(s.clamped_view(end=4), content="ab😀")
  inspect(s.clamped_view(start=2), content="😀cd")
  inspect(s.clamped_view(start=3, end=3), content="")
  // never contains content outside the requested range
  inspect(s.clamped_view(start=1, end=3), content="b")
}

///|
test "clamped_view clamps out-of-range and inverted offsets" {
  let s = "ab😀cd"
  inspect(s.clamped_view(end=100), content="ab😀cd")
  inspect(s.clamped_view(start=-5), content="ab😀cd")
  inspect(s.clamped_view(start=100), content="")
  inspect(s.clamped_view(start=4, end=2), content="")
  inspect("".clamped_view(end=10), content="")
}

///|
test "clamped_view passes unpaired surrogates through unchanged" {
  // A lone trailing surrogate is a boundary: nothing to snap around.
  let lone = "😀".unsafe_substring(start=1, end=2)
  let s = "a" + lone + "b"
  inspect(s.clamped_view(end=2).length(), content="2")
  inspect(s.clamped_view(start=1).length(), content="2")
  inspect(s.clamped_view(start=1, end=2).length(), content="1")
}

///|
test "clamped_view chunking loop reassembles the original" {
  let s = "😀😁😂😃 mixed 😄 text 😅"
  let parts = StringBuilder()
  let mut pos = 0
  while pos < s.length() {
    let chunk = s.clamped_view(start=pos, end=pos + 4)
    parts.write_view(chunk)
    pos += chunk.length()
  }
  inspect(parts.to_string() == s, content="true")
}

///|
test "StringView::clamped_view uses view-relative offsets" {
  let v = "xx ab😀cd".view(start_offset=3) // "ab😀cd", 😀 at units 2-3
  inspect(v.clamped_view(end=3), content="ab")
  inspect(v.clamped_view(start=3), content="cd")
  inspect(v.clamped_view(start=3, end=3), content="")
  inspect(v.clamped_view(end=100), content="ab😀cd")
  // nested truncation
  inspect(v.clamped_view(start=1).clamped_view(end=2), content="b")
}
