// Copyright 2024 International Digital Economy Academy
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

test "basic1" {
  let bs = b"\x00\x01\x02\x03\x04\x05"
  let bv1 = bs[1:4]
  let bv2 = bs[:]
  let bv3 = bs[1:]
  let bv4 = bs[:4]
  inspect!(bv1, content="b\"\\x01\\x02\\x03\"")
  inspect!(bv2, content="b\"\\x00\\x01\\x02\\x03\\x04\\x05\"")
  inspect!(bv3, content="b\"\\x01\\x02\\x03\\x04\\x05\"")
  inspect!(bv4, content="b\"\\x00\\x01\\x02\\x03\"")
}

test "basic2" {
  let bs = b"\x00\x01\x02\x03\x04\x05\x06\x07"
  let bv = bs[1:7]
  let bv1 = bv[1:4]
  let bv2 = bv[:4]
  let bv3 = bv[1:]
  let bv4 = bv[:]
  inspect!(bv, content="b\"\\x01\\x02\\x03\\x04\\x05\\x06\"")
  inspect!(bv1, content="b\"\\x02\\x03\\x04\"")
  inspect!(bv2, content="b\"\\x01\\x02\\x03\\x04\"")
  inspect!(bv3, content="b\"\\x02\\x03\\x04\\x05\\x06\"")
  inspect!(bv4, content="b\"\\x01\\x02\\x03\\x04\\x05\\x06\"")
}

test "basic3" {
  let bs = b"\x00"
  let bv = bs[0:0]
  inspect!(bv, content="b\"\"")
}

test "panic invalid index1" {
  let bs = b"\x00\x01\x02\x03\x04\x05"
  let _ = bs[-1:]

}

test "panic invalid index2" {
  let bs = b"\x00\x01\x02\x03\x04\x05"
  let _ = bs[:7]

}

test "panic invalid index3" {
  let bs = b"\x00\x01\x02\x03\x04\x05"
  let _ = bs[3:2]

}

test "panic invalid index4" {
  let bs = b"\x00\x01\x02\x03\x04\x05"[:]
  let _ = bs[-1:]

}

test "panic invalid index5" {
  let bs = b"\x00\x01\x02\x03\x04\x05"[:]
  let _ = bs[7:]

}

test "panic invalid index6" {
  let bs = b"\x00\x01\x02\x03\x04\x05"[:1]
  let _ = bs[:2]

}

test "iter" {
  let bs = b"\x00\x01\x02\x03\x04\x05"
  let bv = bs[:]
  inspect!(
    bv.iter().to_array(),
    content="[b'\\x00', b'\\x01', b'\\x02', b'\\x03', b'\\x04', b'\\x05']",
  )
}
