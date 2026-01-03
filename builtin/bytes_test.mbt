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
const HELLO_WORLD = b"H\x00e\x00l\x00l\x00o\x00,\x00 \x00W\x00o\x00r\x00l\x00d\x00!\x00"

///|
test "json repr" {
  @json.inspect(b"hello", content="hello")
  @json.inspect(
    b"\x00\x01\x02\x03",
    content=(
      #|\x00\x01\x02\x03
    ),
  )
}

///|
test "to_string" {
  assert_eq(HELLO_WORLD.to_unchecked_string(), "Hello, World!")
}

///|
#warnings("-deprecated")
test "to_fixedarray with len" {
  let bytes = b"abcd"
  let arr = bytes.to_fixedarray(len=3)
  assert_eq(arr.length(), 3)
  assert_eq(arr[0], b'a')
  assert_eq(arr[2], b'c')
}

///|
test "sub_string" {
  assert_eq(HELLO_WORLD.to_unchecked_string(offset=0, length=5 * 2), "Hello")
}

///|
test "blit_from_string" {
  let bytes = FixedArray::make(10, Byte::default())
  let str = "Hello"
  bytes.blit_from_string(0, str, 0, str.length())
  assert_eq(Bytes::from_array(bytes).to_unchecked_string(), str)
}

///|
test "set_utf8_char (ASCII)" {
  let arr = FixedArray::makei(4, _ => b'\x00')
  let char = 'A'
  let len = arr.set_utf8_char(0, char)
  let bytes = Bytes::from_array(arr)
  assert_eq(len, 1)
  inspect(
    bytes,
    content=(
      #|b"A\x00\x00\x00"
    ),
  )
}

///|
test "set_utf8_char (CJK)" {
  let arr = FixedArray::makei(4, _ => b'\x00')
  let char = '拼'
  let len = arr.set_utf8_char(0, char)
  let bytes = Bytes::from_array(arr)
  assert_eq(len, 3)
  inspect(
    bytes,
    content=(
      #|b"\xe6\x8b\xbc\x00"
    ),
  )
}

///|
test "set_utf8_char (0x600)" {
  let arr = FixedArray::makei(4, _ => b'\x00')
  let char = '؀'
  inspect(char.to_int(), content="1536")
  let len = arr.set_utf8_char(0, char)
  let bytes = Bytes::from_array(arr)
  assert_eq(len, 2)
  inspect(
    bytes,
    content=(
      #|b"\xd8\x80\x00\x00"
    ),
  )
}

///|
test "set_utf8_char (Emoji)" {
  let arr = FixedArray::makei(4, _ => b'\x00')
  let char = '🙅'
  let len = arr.set_utf8_char(0, char)
  let bytes = Bytes::from_array(arr)
  assert_eq(len, 4)
  inspect(
    bytes,
    content=(
      #|b"\xf0\x9f\x99\x85"
    ),
  )
}

///|
test "set_utf16le_char" {
  let arr = FixedArray::makei(4, _ => b'\x00')
  let char = 'A'
  let len = arr.set_utf16le_char(0, char)
  let bytes = Bytes::from_array(arr)
  assert_eq(len, 2)
  assert_eq(bytes.to_unchecked_string(offset=0, length=2), "A")
  inspect(
    bytes,
    content=(
      #|b"A\x00\x00\x00"
    ),
  )
}

///|
test "set_utf16le_char (surrogate pair)" {
  let arr = FixedArray::makei(4, _ => b'\x00')
  let char = '🉑'
  let len = arr.set_utf16le_char(0, char)
  let bytes = Bytes::from_array(arr)
  assert_eq(len, 4)
  assert_eq(bytes.to_unchecked_string(offset=0, length=4), "🉑")
  inspect(
    bytes,
    content=(
      #|b"<\xd8Q\xde"
    ),
  )
}

///|
test "set_utf16be_char" {
  let arr = FixedArray::makei(4, _ => b'\x00')
  let char = 'A'
  let len = arr.set_utf16be_char(0, char)
  let bytes = Bytes::from_array(arr)
  assert_eq(len, 2)
  inspect(
    bytes,
    content=(
      #|b"\x00A\x00\x00"
    ),
  )
  let arr = FixedArray::make(2, b'\x00')
  let _ = arr.set_utf16be_char(0, '中') // Unicode U+4E2D
  inspect(arr[0], content="b'\\x4E'")
  inspect(arr[1], content="b'\\x2D'")
  let arr = FixedArray::make(4, b'\x00')
  let _ = arr.set_utf16be_char(0, '😃') // Unicode U+1F603
  inspect(arr[0], content="b'\\xD8'")
  inspect(arr[1], content="b'\\x3D'")
  inspect(arr[2], content="b'\\xDE'")
  inspect(arr[3], content="b'\\x03'")
}

///|
test "equal" {
  let copy_bytes = FixedArray::make(HELLO_WORLD.length(), Byte::default())
  copy_bytes.blit_from_bytes(0, HELLO_WORLD, 0, HELLO_WORLD.length())
  let copy_bytes = Bytes::from_array(copy_bytes)
  assert_eq(HELLO_WORLD, copy_bytes)
  assert_not_eq(HELLO_WORLD, Bytes::new(10))
}

///|
test "fixedarray_byte_blit_from_string" {
  let arr : FixedArray[Byte] = FixedArray::make(10, Byte::default())
  let str = "Hello"
  arr.blit_from_string(0, str, 0, str.length())
  inspect(
    arr,
    content="[b'\\x48', b'\\x00', b'\\x65', b'\\x00', b'\\x6C', b'\\x00', b'\\x6C', b'\\x00', b'\\x6F', b'\\x00']",
  )
}

///|
test "fixedarray_byte_blit_from_bytes" {
  let arr : FixedArray[Byte] = FixedArray::make(5, Byte::default())
  let bytes = b"Hello"
  arr.blit_from_bytes(0, bytes, 0, bytes.length())
  inspect(arr, content="[b'\\x48', b'\\x65', b'\\x6C', b'\\x6C', b'\\x6F']")
}

///|
test "Bytes::equal with differing bytes" {
  let arr1 = Array::make(3, b'\x00')
  arr1[0] = 0x01
  arr1[1] = 0x02
  arr1[2] = 0x03
  let arr2 = Array::make(3, b'\x00')
  arr2[0] = 0x01
  arr2[1] = 0x02
  arr2[2] = 0x04
  let bytes1 = Bytes::from_array(arr1)
  let bytes2 = Bytes::from_array(arr2)
  inspect(Bytes::equal(bytes1, bytes2), content="false")
}

///|
test "Bytes::to_fixedarray with len" {
  let bytes = b"hello"
  let arr = bytes[:3].to_fixedarray()
  inspect(arr, content="[b'\\x68', b'\\x65', b'\\x6C']")
}

///|
test "Bytes::iter2" {
  let iter = b"ab".iter2()
  inspect(iter, content="[(0, b'\\x61'), (1, b'\\x62')]")
}

///|
test "Bytes::add and repeat" {
  inspect(
    b"ab" + b"cd",
    content=(
      #|b"abcd"
    ),
  )
  inspect(
    b"xy".repeat(1),
    content=(
      #|b"xy"
    ),
  )
}

///|
test "Bytes::rev_find none" {
  inspect(b"abc".rev_find(b"x"), content="None")
}

///|
test "blit_from_bytesview basic case" {
  let arr = FixedArray::make(4, b'\x00')
  let view = b"\x01\x02\x03"[1:] // view contains "\x02\x03"
  arr.blit_from_bytesview(1, view)
  inspect(arr, content="[b'\\x00', b'\\x02', b'\\x03', b'\\x00']")
}

///|
test "panic FixedArray::set_utf8_char/invalid_code_point" {
  let buf = FixedArray::make(4, b'\x00')
  // Creating a character with code point greater than 0x10FFFF (1114111)
  let invalid_char = (0x110001).unsafe_to_char()
  // This should trigger the "Char out of range" panic
  let _ = buf.set_utf8_char(0, invalid_char)

}

///|
test "set_utf16be_char with surrogate pairs" {
  let buf = FixedArray::make(4, b'\x00')
  // Test surrogate pair encoding for a supplementary plane character (U+10437)
  let c = '\u{10437}'
  let len = buf.set_utf16be_char(0, c)
  inspect(len, content="4")
  // Check the generated bytes for correct UTF-16BE encoding
  // High surrogate: D801, Low surrogate: DC37
  inspect(buf[0], content="b'\\xD8'")
  inspect(buf[1], content="b'\\x01'")
  inspect(buf[2], content="b'\\xDC'")
  inspect(buf[3], content="b'\\x37'")
}

///|
test "panic set_utf16be_char with out of range code point" {
  let buf = FixedArray::make(4, b'\x00')
  ignore(buf.set_utf16be_char(0, (0x110000).unsafe_to_char()))
}

///|
test "Bytes::makei with non-positive length" {
  let bytes = Bytes::makei(0, _i => b'\x00')
  inspect(bytes, content="b\"\"")
  let bytes2 = Bytes::makei(-1, _i => b'\x00')
  inspect(bytes2, content="b\"\"")
}

///|
test "Bytes::make with non-positive length" {
  let bytes = Bytes::make(0, b'\x00')
  inspect(bytes, content="b\"\"")
  let bytes2 = Bytes::make(-1, b'\x00')
  inspect(bytes2, content="b\"\"")
}

///|
test "@builtin.Bytes::compare/basic" {
  // Basic comparison of different bytes
  let a = b"\x01\x02\x03"
  let b = b"\x01\x02\x04"
  inspect(a.compare(b), content="-1") // a < b
  inspect(b.compare(a), content="1") // b > a
  inspect(a.compare(a), content="0") // a = a
}

///|
test "@builtin.Bytes::compare/different_lengths" {
  // Compare sequences of different lengths
  let a = b"\x01\x02"
  let b = b"\x01\x02\x03"
  inspect(a.compare(b), content="-1") // shorter sequence is less
  inspect(b.compare(a), content="1") // longer sequence is greater
}

///|
test "@builtin.Bytes::compare/empty" {
  // Edge cases with empty sequences
  let empty = b""
  let non_empty = b"\x00"
  inspect(empty.compare(empty), content="0") // empty equals empty
  inspect(empty.compare(non_empty), content="-1") // empty is less than non-empty
  inspect(non_empty.compare(empty), content="1") // non-empty is greater than empty
}

///|
test "Bytes find and rev_find" {
  let target = b"abcabc"
  let pattern = b"abc"
  inspect(target.find(pattern[:]), content="Some(0)")
  inspect(target.rev_find(pattern[:]), content="Some(3)")
  inspect(target.find(b"zzz"[:]), content="None")
  inspect(target[:].find(b"bca"[:]), content="Some(1)")
  inspect(target[:].rev_find(b"bca"[:]), content="Some(1)")
}

///|
test "BytesView::to_array" {
  let view = b"hi"[:]
  inspect(view.to_array(), content="[b'\\x68', b'\\x69']")
}
