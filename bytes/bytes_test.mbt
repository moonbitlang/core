// Copyright 2025 International Digital Economy Academy
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

test "bytes literal" {
  inspect!(
    b"ABC",
    content=
      #|b"\x41\x42\x43"
    ,
  )
  inspect!(
    b"\x41\x42\x43",
    content=
      #|b"\x41\x42\x43"
    ,
  )
}

test "from_array" {
  let b = @bytes.of([b'\x41', b'\x00', b'\x42', b'\x00', b'\x43', b'\x00'])
  inspect!(
    b,
    content=
      #|b"\x41\x00\x42\x00\x43\x00"
    ,
  )
}

test "from_array literal" {
  let b = @bytes.of([65, 0, 66, 0, 67, 0])
  inspect!(
    b,
    content=
      #|b"\x41\x00\x42\x00\x43\x00"
    ,
  )
}

test "from array literal" {
  let b1 = @bytes.of([
    b'\x41', b'\x00', b'\x42', b'\x00', b'\x43', b'\x00', b'\x44', b'\x00', b'\x45',
    b'\x00', b'\x46', b'\x00', b'\x47', b'\x00', b'\x48', b'\x00', b'\x49', b'\x00',
  ])
  let b2 = @bytes.of([
    65, 0, 66, 0, 67, 0, 68, 0, 69, 0, 70, 0, 71, 0, 72, 0, 73, 0,
  ])
  assert_eq!(b1, b2)
}

test "hash" {
  let b1 = @bytes.of([
    b'\x41', b'\x00', b'\x42', b'\x00', b'\x43', b'\x00', b'\x44', b'\x00', b'\x45',
    b'\x00', b'\x46', b'\x00', b'\x47', b'\x00', b'\x48', b'\x00', b'\x49', b'\x00',
  ])
  let b2 = @bytes.of([
    b'\x41', b'\x00', b'\x42', b'\x00', b'\x43', b'\x00', b'\x44', b'\x00', b'\x45',
    b'\x00', b'\x46', b'\x00', b'\x47', b'\x00', b'\x48', b'\x00', b'\x4A', b'\x00',
  ])
  let b3 = @bytes.of([
    b'\x80', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00',
  ])
  let b4 = @bytes.of([
    b'\x7f', b'\xff', b'\xff', b'\xff', b'\xff', b'\xff', b'\xff', b'\xff',
  ])
  inspect!(b1.hash(), content="273427599")
  inspect!(b2.hash(), content="2013728637")
  inspect!(b3.hash(), content="-983520567")
  inspect!(b4.hash(), content="-1652773543")
  inspect!(b1.hash() == b1.hash(), content="true")
  inspect!(b2.hash() == b2.hash(), content="true")
  inspect!(b1.hash() == b2.hash(), content="false")
}

test "to_array" {
  let b = @bytes.of([b'A', b'B', b'C'])
  inspect!(b.to_array(), content="[b'\\x41', b'\\x42', b'\\x43']")
}

test "from_iter multiple elements" {
  inspect!(
    Bytes::from_iter([b'\x00', b'\x01', b'\x02'].iter()).to_array(),
    content="[b'\\x00', b'\\x01', b'\\x02']",
  )
}

test "from_iter single element" {
  inspect!(Bytes::from_iter([b'\x00'].iter()).to_array(), content="[b'\\x00']")
}

test "from_iter empty iterator" {
  inspect!(Bytes::from_iter(Iter::empty()).to_array(), content="[]")
}

test "iter" {
  let buf = StringBuilder::new(size_hint=5)
  b"abcde".iter().each(fn { x => buf.write_string(x.to_string()) })
  inspect!(buf, content="b'\\x61'b'\\x62'b'\\x63'b'\\x64'b'\\x65'")
  buf.reset()
  b"abcde".iter().take(2).each(fn { x => buf.write_string(x.to_string()) })
  inspect!(buf, content="b'\\x61'b'\\x62'")
}
