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
  inspect(b"hello".find(b"o"), content="Some(4)")
  inspect(b"hello".find(b"l"), content="Some(2)")
  inspect(b"hello".find(b"hello"), content="Some(0)")
  inspect(b"hello".find(b"h"), content="Some(0)")
  inspect(b"hello".find(b""), content="Some(0)")
  inspect(b"hello".find(b"world"), content="None")
  inspect(b"".find(b""), content="Some(0)")
  inspect(b"".find(b"a"), content="None")
  inspect(b"hello hello".find(b"hello"), content="Some(0)")
  inspect(b"aaa".find(b"aa"), content="Some(0)")
  inspect(b"aabaabaaa".find(b"aaa"), content="Some(6)")
}

///|
test "rev_find" {
  inspect(b"hello".rev_find(b"o"), content="Some(4)")
  inspect(b"hello".rev_find(b"l"), content="Some(3)")
  inspect(b"hello".rev_find(b"hello"), content="Some(0)")
  inspect(b"hello".rev_find(b"h"), content="Some(0)")
  inspect(b"hello".rev_find(b""), content="Some(5)")
  inspect(b"hello".rev_find(b"world"), content="None")
  inspect(b"".rev_find(b""), content="Some(0)")
  inspect(b"".rev_find(b"a"), content="None")
  inspect(b"hello hello".rev_find(b"hello"), content="Some(6)")
  inspect(b"aaa".rev_find(b"aa"), content="Some(1)")
  inspect(b"aabaaabaa".find(b"aaa"), content="Some(3)")
}

///|
test "Bytes::from_iter" {
  inspect(
    Bytes::from_iter(([97, 98, 99] : Array[Byte]).iter()),
    content="b\"abc\"",
  )
}
