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
  debug_inspect(b"hello".find("o"), content="Some(4)")
  debug_inspect(b"hello".find("l"), content="Some(2)")
  debug_inspect(b"hello".find("hello"), content="Some(0)")
  debug_inspect(b"hello".find("h"), content="Some(0)")
  debug_inspect(b"hello".find(""), content="Some(0)")
  debug_inspect(b"hello".find("world"), content="None")
  debug_inspect(b"".find(""), content="Some(0)")
  debug_inspect(b"".find("a"), content="None")
  debug_inspect(b"hello hello".find("hello"), content="Some(0)")
  debug_inspect(b"aaa".find("aa"), content="Some(0)")
  debug_inspect(b"aabaabaaa".find("aaa"), content="Some(6)")
}

///|
test "rev_find" {
  debug_inspect(b"hello".rev_find("o"), content="Some(4)")
  debug_inspect(b"hello".rev_find("l"), content="Some(3)")
  debug_inspect(b"hello".rev_find("hello"), content="Some(0)")
  debug_inspect(b"hello".rev_find("h"), content="Some(0)")
  debug_inspect(b"hello".rev_find(""), content="Some(5)")
  debug_inspect(b"hello".rev_find("world"), content="None")
  debug_inspect(b"".rev_find(""), content="Some(0)")
  debug_inspect(b"".rev_find("a"), content="None")
  debug_inspect(b"hello hello".rev_find("hello"), content="Some(6)")
  debug_inspect(b"aaa".rev_find("aa"), content="Some(1)")
  debug_inspect(b"aabaaabaa".find("aaa"), content="Some(3)")
}

///|
test "Bytes::from_iter" {
  inspect(
    Bytes::from_iter(([97, 98, 99] : Array[Byte]).iter()),
    content="b\"abc\"",
  )
}
