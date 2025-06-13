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

///|
const HELLO : Bytes = "你好"

///|
test "bytes literal" {
  inspect("ABC", content="ABC")
  let b : Bytes = "你好"
  inspect(
    b + "utf8" + HELLO,
    content=
      #|b"\xe4\xbd\xa0\xe5\xa5\xbd\x75\x74\x66\x38\xe4\xbd\xa0\xe5\xa5\xbd"
    ,
  )
  // match ("你好,utf8" : Bytes) {
  //   // [_,_,_, .. rest] => inspect(rest, content="utf8")
  //   [ ] => ...
  //   _ => inspect("not hello,utf8", content="not hello,utf8")
  // }
  inspect(
    b"\x41\x42\x43",
    content=
      #|b"\x41\x42\x43"
    ,
  )
}

///|
test "from_array" {
  let b = @bytes.of([b'\x41', b'\x00', b'\x42', b'\x00', b'\x43', b'\x00'])
  inspect(
    b,
    content=
      #|b"\x41\x00\x42\x00\x43\x00"
    ,
  )
}

///|
test "from_array literal" {
  let b = @bytes.of([65, 0, 66, 0, 67, 0])
  inspect(
    b,
    content=
      #|b"\x41\x00\x42\x00\x43\x00"
    ,
  )
}

///|
test "from array literal" {
  let b1 = @bytes.of([
    b'\x41', b'\x00', b'\x42', b'\x00', b'\x43', b'\x00', b'\x44', b'\x00', b'\x45',
    b'\x00', b'\x46', b'\x00', b'\x47', b'\x00', b'\x48', b'\x00', b'\x49', b'\x00',
  ])
  let b2 = @bytes.of([
    65, 0, 66, 0, 67, 0, 68, 0, 69, 0, 70, 0, 71, 0, 72, 0, 73, 0,
  ])
  assert_eq(b1, b2)
}

///|
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
  inspect(b1.hash(), content="273427599")
  inspect(b2.hash(), content="2013728637")
  inspect(b3.hash(), content="-983520567")
  inspect(b4.hash(), content="-1652773543")
  inspect(b1.hash() == b1.hash(), content="true")
  inspect(b2.hash() == b2.hash(), content="true")
  inspect(b1.hash() == b2.hash(), content="false")
}

///|
test "to_array" {
  let b = @bytes.of([b'A', b'B', b'C'])
  inspect(b.to_array(), content="[b'\\x41', b'\\x42', b'\\x43']")
}

///|
test "from_iter multiple elements" {
  inspect(
    @bytes.from_iter([b'\x00', b'\x01', b'\x02'].iter()).to_array(),
    content="[b'\\x00', b'\\x01', b'\\x02']",
  )
}

///|
test "from_iter single element" {
  inspect(@bytes.from_iter([b'\x00'].iter()).to_array(), content="[b'\\x00']")
}

///|
test "from_iter empty iterator" {
  inspect(@bytes.from_iter(Iter::empty()).to_array(), content="[]")
}

///|
test "iter" {
  let buf = StringBuilder::new(size_hint=5)
  b"abcde".iter().each(fn { x => buf.write_string(x.to_string()) })
  inspect(buf, content="b'\\x61'b'\\x62'b'\\x63'b'\\x64'b'\\x65'")
  buf.reset()
  b"abcde".iter().take(2).each(fn { x => buf.write_string(x.to_string()) })
  inspect(buf, content="b'\\x61'b'\\x62'")
}

///|
test "iter2" {
  let buf = StringBuilder::new(size_hint=5)
  let keys = []
  b"abcde"
  .iter2()
  .each(fn(i, x) {
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
  let empty = @bytes.default()
  inspect(empty.length(), content="0")
}

///|
test "to_fixedarray with Some length" {
  let bytes = b"hello"
  let arr = bytes.to_fixedarray(len=3)
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
  let bytes = Bytes::of(arr)
  inspect(
    bytes,
    content=
      #|b"\x61\x62\x63"
    ,
  )
}

///|
test "Bytes::from_iter with multiple elements" {
  let iter = [b'a', b'b', b'c'].iter()
  let bytes = Bytes::from_iter(iter)
  inspect(
    bytes,
    content=
      #|b"\x61\x62\x63"
    ,
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
/// Test ByteSource trait for Bytes, FixedArray[Byte], and Array[Byte]
test "ByteSource trait for Bytes" {
  let bytes : Bytes = b"\x10\x20\x30"
  let value = bytes.get(1)
  inspect(value, content="Some(b'\\x20')")
}

///|
test "ByteSource trait for FixedArray[Byte]" {
  let arr : FixedArray[Byte] = [b'\x01', b'\x02', b'\x03']
  let value = arr.get(2)
  inspect(value, content="Some(b'\\x03')")
}

///|
test "ByteSource trait for Array[Byte]" {
  let arr : Array[Byte] = [b'\x05', b'\x06', b'\x07']
  let value = arr.get(0)
  inspect(value, content="Some(b'\\x05')")
}

///|
/// Test Bytes::blit_from with Bytes as source
test "Bytes::blit_from with Bytes source" {
  let src : Bytes = b"\xAA\xBB\xCC"
  let dst : Bytes = b"\x00\x00\x00"
  let result = dst.blit_from(src, dest_index=1, src_index=0, len=2)
  inspect(
    result,
    content=
      #|b"\x00\xaa\xbb"
    ,
  )
}

///|
/// Test Bytes::blit_from with FixedArray[Byte] as source
test "Bytes::blit_from with FixedArray[Byte] source" {
  let src : FixedArray[Byte] = [b'\x11', b'\x22', b'\x33']
  let dst : Bytes = b"\x00\x00\x00"
  let result = dst.blit_from(src, dest_index=0, src_index=1, len=2)
  inspect(
    result,
    content=
      #|b"\x22\x33\x00"
    ,
  )
}

///|
/// Test Bytes::blit_from with Array[Byte] as source
test "Bytes::blit_from with Array[Byte] source" {
  let src : Array[Byte] = [b'\x44', b'\x55', b'\x66']
  let dst : Bytes = b"\x00\x00\x00"
  let result = dst.blit_from(src, dest_index=0, src_index=0, len=3)
  inspect(
    result,
    content=
      #|b"\x44\x55\x66"
    ,
  )
}
