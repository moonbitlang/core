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
test "split_at on BMP text splits exactly" {
  let (p, q) = "hello world".split_at(5)
  inspect(p, content="hello")
  inspect(q, content=" world")
  let (p2, q2) = "abc".split_at(0)
  inspect(p2, content="")
  inspect(q2, content="abc")
  let (p3, q3) = "abc".split_at(3)
  inspect(p3, content="abc")
  inspect(q3, content="")
}

///|
test "split_at snaps down off a surrogate pair" {
  let s = "ab😀cd" // 😀 occupies units 2 and 3
  let (p, q) = s.split_at(3)
  inspect(p, content="ab")
  inspect(q, content="😀cd")
  let (p2, q2) = s.split_at(2)
  inspect(p2, content="ab")
  inspect(q2, content="😀cd")
  let (p3, q3) = s.split_at(4)
  inspect(p3, content="ab😀")
  inspect(q3, content="cd")
}

///|
test "split_at is lossless at every offset including out-of-range" {
  let s = "a😀b😁😂c"
  for at in -2..<=(s.length() + 2) {
    let (p, q) = s.split_at(at)
    assert_eq(p.to_owned() + q.to_owned(), s)
    if at >= 0 {
      assert_true(p.length() <= at)
    }
  }
}

///|
test "split_at treats unpaired surrogates as boundaries" {
  let lone = "😀".unsafe_substring(start=1, end=2)
  let s = "a" + lone + "b"
  let (p, q) = s.split_at(1)
  inspect(p.length(), content="1")
  inspect(q.length(), content="2")
  assert_eq(p.to_owned() + q.to_owned(), s)
}

///|
test "StringView::split_at uses view-relative offsets and stays in window" {
  let v = "xx ab😀cd yy".view(start_offset=3, end_offset=9) // "ab😀cd"
  let (p, q) = v.split_at(3)
  inspect(p, content="ab")
  inspect(q, content="😀cd")
  let (p2, q2) = v.split_at(100)
  inspect(p2, content="ab😀cd")
  inspect(q2, content="")
  assert_eq(p.to_owned() + q.to_owned(), v.to_owned())
}
