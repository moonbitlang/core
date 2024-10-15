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

test "hash" {
  let b1 = @bytes.of(
    [
      b'\x41', b'\x00', b'\x42', b'\x00', b'\x43', b'\x00', b'\x44', b'\x00', b'\x45',
      b'\x00', b'\x46', b'\x00', b'\x47', b'\x00', b'\x48', b'\x00', b'\x49', b'\x00',
    ],
  )
  let b2 = @bytes.of(
    [
      b'\x41', b'\x00', b'\x42', b'\x00', b'\x43', b'\x00', b'\x44', b'\x00', b'\x45',
      b'\x00', b'\x46', b'\x00', b'\x47', b'\x00', b'\x48', b'\x00', b'\x4A', b'\x00',
    ],
  )
  let b3 = @bytes.of(
    [b'\x80', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00'],
  )
  let b4 = @bytes.of(
    [b'\x7f', b'\xff', b'\xff', b'\xff', b'\xff', b'\xff', b'\xff', b'\xff'],
  )
  inspect!(Hash::hash(b1), content="273427599")
  inspect!(Hash::hash(b2), content="2013728637")
  inspect!(Hash::hash(b3), content="-983520567")
  inspect!(Hash::hash(b4), content="-1652773543")
  inspect!(Hash::hash(b1) == Hash::hash(b1), content="true")
  inspect!(Hash::hash(b2) == Hash::hash(b2), content="true")
  inspect!(Hash::hash(b1) == Hash::hash(b2), content="false")
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

test "grouped test for read_int64 function" {
  // Test case 1: Read a 64-bit integer from a Bytes object with offset 0
  let bytes1 = @bytes.of(
    [b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x01'],
  )
  inspect!(@bytes.read_int64(bytes1, 0), content="72057594037927936")

  // Test case 2: Read a 64-bit integer from a Bytes object with offset 1
  let bytes2 = @bytes.of(
    [
      b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x02', b'\x00',
    ],
  )
  inspect!(@bytes.read_int64(bytes2, 1), content="562949953421312")

  // Test case 3: Read a 64-bit integer from a Bytes object with offset 2
  let bytes3 = @bytes.of(
    [
      b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x03', b'\x00',
      b'\x00',
    ],
  )
  inspect!(@bytes.read_int64(bytes3, 2), content="3298534883328")

  // Test case 4: Read a 64-bit integer from a Bytes object with offset 3
  let bytes4 = @bytes.of(
    [
      b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x04', b'\x00',
      b'\x00', b'\x00',
    ],
  )
  inspect!(@bytes.read_int64(bytes4, 3), content="17179869184")

  // Test case 5: Read a 64-bit integer from a Bytes object with offset 4
  let bytes5 = @bytes.of(
    [
      b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x05', b'\x00',
      b'\x00', b'\x00', b'\x00',
    ],
  )
  inspect!(@bytes.read_int64(bytes5, 4), content="83886080")

  // Test case 6: Read a 64-bit integer from a Bytes object with offset 5
  let bytes6 = @bytes.of(
    [
      b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x06', b'\x00',
      b'\x00', b'\x00', b'\x00', b'\x00',
    ],
  )
  inspect!(@bytes.read_int64(bytes6, 5), content="393216")

  // Test case 7: Read a 64-bit integer from a Bytes object with offset 6
  let bytes7 = @bytes.of(
    [
      b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x07', b'\x00',
      b'\x00', b'\x00', b'\x00', b'\x00', b'\x00',
    ],
  )
  inspect!(@bytes.read_int64(bytes7, 6), content="1792")

  // Test case 8: Read a 64-bit integer from a Bytes object with offset 7
  let bytes8 = @bytes.of(
    [
      b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x08', b'\x00',
      b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00',
    ],
  )
  inspect!(@bytes.read_int64(bytes8, 7), content="8")
}

test "read_uint basic functionality" {
  let bytes = @bytes.of([b'\x00', b'\x00', b'\x00', b'\x01'])
  inspect!(@bytes.read_uint(bytes, 0), content="16777216")
  let bytes = @bytes.of([b'\x00', b'\x00', b'\x01', b'\x00'])
  inspect!(@bytes.read_uint(bytes, 0), content="65536")
  let bytes = @bytes.of([b'\x01', b'\x00', b'\x00', b'\x00'])
  inspect!(@bytes.read_uint(bytes, 0), content="1")
}

test "grouped test for read_int function" {
  // Test case 1: Read a 32-bit integer from a Bytes object with offset 0
  let bytes1 = @bytes.of([b'\x00', b'\x00', b'\x00', b'\x01'])
  inspect!(@bytes.read_int(bytes1, 0), content="16777216")

  // Test case 2: Read a 32-bit integer from a Bytes object with offset 1
  let bytes2 = @bytes.of(
    [b'\x00', b'\x00', b'\x00', b'\x02', b'\x00', b'\x00', b'\x00', b'\x03'],
  )
  inspect!(@bytes.read_int(bytes2, 1), content="131072")

  // Test case 3: Read a 32-bit integer from a Bytes object with offset 4
  let bytes3 = @bytes.of(
    [b'\x00', b'\x00', b'\x00', b'\x04', b'\x00', b'\x00', b'\x00', b'\x05'],
  )
  inspect!(@bytes.read_int(bytes3, 4), content="83886080")

  // Test case 4: Read a 32-bit integer from a Bytes object with offset 0, with non-zero bytes
  let bytes4 = @bytes.of([b'\x12', b'\x34', b'\x56', b'\x78'])
  inspect!(@bytes.read_int(bytes4, 0), content="2018915346")

  // Test case 5: Read a 32-bit integer from a Bytes object with offset 0, with negative value
  let bytes5 = @bytes.of([b'\xFF', b'\xFF', b'\xFF', b'\xFF'])
  inspect!(@bytes.read_int(bytes5, 0), content="-1")

  // Test case 6: Read a 32-bit integer from a Bytes object with offset 0, with maximum positive value
  let bytes6 = @bytes.of([b'\x7F', b'\xFF', b'\xFF', b'\xFF'])
  inspect!(@bytes.read_int(bytes6, 0), content="-129")

  // Test case 7: Read a 32-bit integer from a Bytes object with offset 0, with minimum negative value
  let bytes7 = @bytes.of([b'\x80', b'\x00', b'\x00', b'\x00'])
  inspect!(@bytes.read_int(bytes7, 0), content="128")
}

test "read_uint edge cases" {
  let bytes = @bytes.of([b'\xFF', b'\xFF', b'\xFF', b'\xFF'])
  inspect!(@bytes.read_uint(bytes, 0), content="4294967295")
  let bytes = @bytes.of([b'\x00', b'\x00', b'\x00', b'\x00'])
  inspect!(@bytes.read_uint(bytes, 0), content="0")
  let bytes = @bytes.of([b'\x7F', b'\xFF', b'\xFF', b'\xFF'])
  inspect!(@bytes.read_uint(bytes, 0), content="4294967167")
  let bytes = @bytes.of([b'\x80', b'\x00', b'\x00', b'\x00'])
  inspect!(@bytes.read_uint(bytes, 0), content="128")
}

test "grouped test for read_uint64 edge cases" {
  let bytes = @bytes.of(
    [b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00'],
  )
  inspect!(@bytes.read_uint64(bytes, 0), content="0")
  let bytes = @bytes.of(
    [b'\xFF', b'\xFF', b'\xFF', b'\xFF', b'\xFF', b'\xFF', b'\xFF', b'\xFF'],
  )
  inspect!(@bytes.read_uint64(bytes, 0), content="18446744073709551615")
  let bytes = @bytes.of(
    [b'\x01', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00'],
  )
  inspect!(@bytes.read_uint64(bytes, 0), content="1")
  let bytes = @bytes.of(
    [b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x01'],
  )
  inspect!(@bytes.read_uint64(bytes, 0), content="72057594037927936")
}
