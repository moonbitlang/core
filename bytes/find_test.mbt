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
test "find" {
  debug_inspect(b"hello".find(b"o"), content="Some(4)")
  debug_inspect(b"hello".find(b"l"), content="Some(2)")
  debug_inspect(b"hello".find(b"hello"), content="Some(0)")
  debug_inspect(b"hello".find(b"h"), content="Some(0)")
  debug_inspect(b"hello".find(b""), content="Some(0)")
  debug_inspect(b"hello".find(b"world"), content="None")
  debug_inspect(b"".find(b""), content="Some(0)")
  debug_inspect(b"".find(b"a"), content="None")
  debug_inspect(b"hello hello".find(b"hello"), content="Some(0)")
  debug_inspect(b"aaa".find(b"aa"), content="Some(0)")
  debug_inspect(b"aabaabaaa".find(b"aaa"), content="Some(6)")
}

///|
test "BytesView find edge cases" {
  let target = b"--abcabc--"[2:8]
  debug_inspect(target.find(b""), content="Some(0)")
  debug_inspect(target.find(b"abc"), content="Some(0)")
  debug_inspect(target.find(b"bca"), content="Some(1)")
  debug_inspect(target.find(b"cab"), content="Some(2)")
  debug_inspect(target.find(b"abcabc"), content="Some(0)")
  debug_inspect(target.find(b"abcabcx"), content="None")
  debug_inspect(b""[:].find(b""), content="Some(0)")
  debug_inspect(b""[:].find(b"a"), content="None")
}

///|
test "BytesView find long input" {
  let target = Bytes::makei(64, i => if i == 60 { b'Z' } else { b'a' })
  debug_inspect(target.find(b"Z"), content="Some(60)")
  debug_inspect(target.find(b"aaaaZ"), content="Some(56)")
  debug_inspect(target.find(b"b"), content="None")
  let view = target[3:63]
  debug_inspect(view.find(b"Z"), content="Some(57)")
  debug_inspect(view.find(b"aaaaZ"), content="Some(53)")
}

///|
test "BytesView find dense candidates" {
  let target = Bytes::makei(160, i => if i == 127 { b'b' } else { b'a' })
  let pattern = Bytes::makei(40, i => if i == 39 { b'b' } else { b'a' })
  debug_inspect(target.find(pattern), content="Some(88)")
  debug_inspect(
    target.find(Bytes::makei(40, i => if i == 39 { b'c' } else { b'a' })),
    content="None",
  )
}

///|
test "BytesView find long pattern offset view" {
  let data = Bytes::makei(180, i => {
    if i >= 97 && i < 136 {
      b'a'
    } else if i == 136 {
      b'b'
    } else {
      b'x'
    }
  })
  let view = data[9:170]
  let pattern = Bytes::makei(40, i => if i == 39 { b'b' } else { b'a' })
  debug_inspect(view.find(pattern), content="Some(88)")
}

///|
test "rev_find" {
  debug_inspect(b"hello".rev_find(b"o"), content="Some(4)")
  debug_inspect(b"hello".rev_find(b"l"), content="Some(3)")
  debug_inspect(b"hello".rev_find(b"hello"), content="Some(0)")
  debug_inspect(b"hello".rev_find(b"h"), content="Some(0)")
  debug_inspect(b"hello".rev_find(b""), content="Some(5)")
  debug_inspect(b"hello".rev_find(b"world"), content="None")
  debug_inspect(b"".rev_find(b""), content="Some(0)")
  debug_inspect(b"".rev_find(b"a"), content="None")
  debug_inspect(b"hello hello".rev_find(b"hello"), content="Some(6)")
  debug_inspect(b"aaa".rev_find(b"aa"), content="Some(1)")
  debug_inspect(b"aabaaabaa".find(b"aaa"), content="Some(3)")
}

///|
test "Bytes::from_iter" {
  inspect(
    Bytes::from_iter(([97, 98, 99] : Array[Byte]).iter()),
    content="b\"abc\"",
  )
}
