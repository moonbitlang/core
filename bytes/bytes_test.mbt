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
const HELLO : Bytes = "你好"

///|
test "bytes literal" {
  inspect("ABC", content="ABC")
  let b : Bytes = "你好"
  inspect(
    b + "utf8" + HELLO,
    content=(
      #|b"\xe4\xbd\xa0\xe5\xa5\xbdutf8\xe4\xbd\xa0\xe5\xa5\xbd"
    ),
  )
  // match ("你好,utf8" : Bytes) {
  //   // [_,_,_, .. rest] => inspect(rest, content="utf8")
  //   [ ] => ...
  //   _ => inspect("not hello,utf8", content="not hello,utf8")
  // }
  inspect(
    b"\x41\x42\x43",
    content=(
      #|b"ABC"
    ),
  )
}

///|
test "from_array" {
  let b = Bytes::from_array([
    b'\x41', b'\x00', b'\x42', b'\x00', b'\x43', b'\x00',
  ])
  inspect(
    b,
    content=(
      #|b"A\x00B\x00C\x00"
    ),
  )
}

///|
test "from_array literal" {
  let b = Bytes::from_array([65, 0, 66, 0, 67, 0])
  inspect(
    b,
    content=(
      #|b"A\x00B\x00C\x00"
    ),
  )
}

///|
test "from array literal" {
  let b1 = Bytes::from_array([
    b'\x41', b'\x00', b'\x42', b'\x00', b'\x43', b'\x00', b'\x44', b'\x00', b'\x45',
    b'\x00', b'\x46', b'\x00', b'\x47', b'\x00', b'\x48', b'\x00', b'\x49', b'\x00',
  ])
  let b2 = Bytes::from_array([
    65, 0, 66, 0, 67, 0, 68, 0, 69, 0, 70, 0, 71, 0, 72, 0, 73, 0,
  ])
  assert_eq(b1, b2)
}

///|
test "hash" {
  let b1 = Bytes::from_array([
    b'\x41', b'\x00', b'\x42', b'\x00', b'\x43', b'\x00', b'\x44', b'\x00', b'\x45',
    b'\x00', b'\x46', b'\x00', b'\x47', b'\x00', b'\x48', b'\x00', b'\x49', b'\x00',
  ])
  let b2 = Bytes::from_array([
    b'\x41', b'\x00', b'\x42', b'\x00', b'\x43', b'\x00', b'\x44', b'\x00', b'\x45',
    b'\x00', b'\x46', b'\x00', b'\x47', b'\x00', b'\x48', b'\x00', b'\x4A', b'\x00',
  ])
  let b3 = Bytes::from_array([
    b'\x80', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00',
  ])
  let b4 = Bytes::from_array([
    b'\x7f', b'\xff', b'\xff', b'\xff', b'\xff', b'\xff', b'\xff', b'\xff',
  ])
  inspect(Hasher::new(seed=0)..combine(b1).finalize(), content="-892426428")
  inspect(Hasher::new(seed=0)..combine(b2).finalize(), content="404189")
  inspect(Hasher::new(seed=0)..combine(b3).finalize(), content="-1666368731")
  inspect(Hasher::new(seed=0)..combine(b4).finalize(), content="1297183151")
  inspect(b1.hash() == b1.hash(), content="true")
  inspect(b2.hash() == b2.hash(), content="true")
  inspect(b1.hash() == b2.hash(), content="false")
}

///|
test "to_array" {
  let b = Bytes::from_array([b'A', b'B', b'C'])
  inspect(b.to_array(), content="[b'\\x41', b'\\x42', b'\\x43']")
}

///|
test "from_iter multiple elements" {
  inspect(
    Bytes::from_iter([b'\x00', b'\x01', b'\x02'].iter()).to_array(),
    content="[b'\\x00', b'\\x01', b'\\x02']",
  )
}

///|
test "from_iter single element" {
  inspect(Bytes::from_iter([b'\x00'].iter()).to_array(), content="[b'\\x00']")
}

///|
test "from_iter empty iterator" {
  inspect(Bytes::from_iter(Iter::empty()).to_array(), content="[]")
}

///|
test "iter" {
  let buf = StringBuilder::new(size_hint=5)
  b"abcde".iter().each(x => buf.write_string(x.to_string()))
  inspect(buf, content="b'\\x61'b'\\x62'b'\\x63'b'\\x64'b'\\x65'")
  buf.reset()
  b"abcde".iter().take(2).each(x => buf.write_string(x.to_string()))
  inspect(buf, content="b'\\x61'b'\\x62'")
}

///|
test "iter2" {
  let buf = StringBuilder::new(size_hint=5)
  let keys = []
  b"abcde"
  .iter2()
  .each((i, x) => {
    buf.write_string(x.to_string())
    keys.push(i)
  })
  inspect(buf, content="b'\\x61'b'\\x62'b'\\x63'b'\\x64'b'\\x65'")
  inspect(keys, content="[0, 1, 2, 3, 4]")
}

///|
test "to_fixedarray with no length specified" {
  let bytes = b"hello"
  let arr = bytes.to_fixedarray()
  inspect(arr, content="[b'\\x68', b'\\x65', b'\\x6C', b'\\x6C', b'\\x6F']")
  inspect(arr.length(), content="5")
}

///|
test "test empty bytes" {
  let empty = Bytes::default()
  inspect(empty.length(), content="0")
}

///|
test "to_fixedarray with Some length" {
  let bytes = b"hello"
  let arr = bytes[:3].to_fixedarray()
  inspect(arr, content="[b'\\x68', b'\\x65', b'\\x6C']")
  inspect(arr.length(), content="3")
}

///|
test "default_empty_bytes" {
  let empty = Bytes::default()
  inspect(empty, content="b\"\"")
  inspect(empty.length(), content="0")
}

///|
test "Bytes::of with different byte values" {
  let arr : FixedArray[Byte] = [b'a', b'b', b'c']
  let bytes = Bytes::from_array(arr)
  inspect(
    bytes,
    content=(
      #|b"abc"
    ),
  )
}

///|
test "Bytes::from_iter with multiple elements" {
  let iter = [b'a', b'b', b'c'].iter()
  let bytes = Bytes::from_iter(iter)
  inspect(
    bytes,
    content=(
      #|b"abc"
    ),
  )
}

///|
test "Fixed::blit_from_bytesview" {
  let arr = FixedArray::make(4, b'\x00')
  let view = b"\x01\x02\x03"[1:]
  arr.blit_from_bytesview(1, view)
  inspect(arr, content="[b'\\x00', b'\\x02', b'\\x03', b'\\x00']")
}

///|
test "panic Fixed::blit_from_bytesview 1" {
  let arr = FixedArray::make(2, b'\x00')
  let view = b"\x01\x02\x03"[1:]
  ignore(arr.blit_from_bytesview(1, view))
}

///|
test "panic Fixed::blit_from_bytesview 2" {
  let arr = FixedArray::make(2, b'\x00')
  let view = b"\x01\x02\x03"[1:]
  ignore(arr.blit_from_bytesview(-1, view))
}

///|
test "bytes pattern match" {
  let bytes : Bytes = "Hello, world!你好"
  guard bytes is [.. b"Hello", ..] else { fail("") }
  guard bytes is [.. _x, .. "你好"] && _x is [.. "Hello, world!", ..] else {
    fail("")
  }
  guard bytes is [.., .. "你好"] else { fail("") }
  // CR: ZYU: it's weird this works but below does not work
  // guard bytes is [.. _ , .. "你好"] else { fail("") }
}

///|
test "Bytes::get" {
  let bytes = b"\x01\x02\x03"
  let byte = bytes.get(1)
  inspect(byte, content="Some(b'\\x02')")
}

///|
test "Bytes::get out of bounds" {
  let bytes = b"\x01\x02\x03"
  let byte = bytes.get(3)
  inspect(byte, content="None")
}

///|
test "Bytes::repeat basic" {
  inspect(
    b"a".repeat(5),
    content=(
      #|b"aaaaa"
    ),
  )
  inspect(
    b"ab".repeat(3),
    content=(
      #|b"ababab"
    ),
  )
  inspect(
    b"".repeat(10),
    content=(
      #|b""
    ),
  )
  inspect(
    b"xyz".repeat(0),
    content=(
      #|b""
    ),
  )
  inspect(
    b"xyz".repeat(-2),
    content=(
      #|b""
    ),
  )
}

///|
test "Bytes::repeat large doubling" {
  // Ensure exponential copy fills correctly
  let base = b"abc"
  let r = base.repeat(8) // 24 bytes
  inspect(
    r,
    content=(
      #|b"abcabcabcabcabcabcabcabc"
    ),
  )
  inspect(r.length(), content="24")
}

///|
test "BytesView::to_fixedarray" {
  let bytes = b"hello world"
  let view = bytes[0:5]
  let arr = view.to_fixedarray()
  inspect(arr, content="[b'\\x68', b'\\x65', b'\\x6C', b'\\x6C', b'\\x6F']")
  inspect(arr.length(), content="5")
}

///|
test "BytesView::to_fixedarray with different ranges" {
  let bytes = b"abcdefgh"
  let view1 = bytes[2:6]
  let arr1 = view1.to_fixedarray()
  inspect(
    arr1,
    content=(
      #|[b'\x63', b'\x64', b'\x65', b'\x66']
    ),
  )
  let view2 = bytes[0:0]
  let arr2 = view2.to_fixedarray()
  inspect(arr2, content="[]")
  let view3 = bytes[7:]
  let arr3 = view3.to_fixedarray()
  inspect(arr3, content="[b'\\x68']")
}

///|
test "BytesView::to_array" {
  let bytes = b"hello"
  let view = bytes[1:4]
  let arr = view.to_array()
  inspect(arr, content="[b'\\x65', b'\\x6C', b'\\x6C']")
  inspect(arr.length(), content="3")
}

///|
test "BytesView::to_array with edge cases" {
  let bytes = b"testing"

  // Full range
  let view1 = bytes[:]
  let arr1 = view1.to_array()
  inspect(arr1.length(), content="7")
  inspect(arr1[0], content="b'\\x74'")
  inspect(arr1[6], content="b'\\x67'")

  // Empty view
  let view2 = bytes[3:3]
  let arr2 = view2.to_array()
  inspect(arr2, content="[]")

  // Single byte
  let view3 = bytes[2:3]
  let arr3 = view3.to_array()
  inspect(arr3, content="[b'\\x73']")
}
