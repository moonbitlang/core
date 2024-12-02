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

test "to_string" {
  let bytes = Bytes::of_string("Hello, World!")
  assert_eq!(bytes.to_unchecked_string(), "Hello, World!")
}

test "of_string" {
  let str = "Hello, World!"
  let bytes = Bytes::of_string(str)
  assert_eq!(bytes.length(), str.length() * 2)
}

test "sub_string" {
  let bytes = Bytes::of_string("Hello, World!")
  assert_eq!(bytes.to_unchecked_string(offset=0, length=5 * 2), "Hello")
  // assert_eq(bytes.sub_string(10, 5 * 2), "World")?
}

test "blit_from_string" {
  let bytes = FixedArray::make(10, Byte::default())
  let str = "Hello"
  bytes.blit_from_string(0, str, 0, str.length())
  assert_eq!(bytes.to_unchecked_string(offset=0, length=str.length() * 2), str)
}

test "copy" {
  let bytes = Bytes::of_string("Hello, World!")
  let copy_bytes = bytes.copy()
  assert_eq!(copy_bytes.to_unchecked_string(), bytes.to_unchecked_string())
}

test "set_utf8_char (ASCII)" {
  let arr = FixedArray::makei(4, fn { _ => b'\x00' })
  let char = 'A'
  let len = arr.set_utf8_char(0, char)
  let bytes = @bytes.from_fixedarray(arr)
  assert_eq!(len, 1)
  inspect!(
    bytes,
    content=
      #|b"\x41\x00\x00\x00"
    ,
  )
}

test "set_utf8_char (CJK)" {
  let arr = FixedArray::makei(4, fn { _ => b'\x00' })
  let char = '拼'
  let len = arr.set_utf8_char(0, char)
  let bytes = @bytes.from_fixedarray(arr)
  assert_eq!(len, 3)
  inspect!(
    bytes,
    content=
      #|b"\xe6\x8b\xbc\x00"
    ,
  )
}

test "set_utf8_char (0x600)" {
  let arr = FixedArray::makei(4, fn { _ => b'\x00' })
  let char = '؀'
  inspect!(char.to_int(), content="1536")
  let len = arr.set_utf8_char(0, char)
  let bytes = @bytes.from_fixedarray(arr)
  assert_eq!(len, 2)
  inspect!(
    bytes,
    content=
      #|b"\xd8\x80\x00\x00"
    ,
  )
}

test "set_utf8_char (Emoji)" {
  let arr = FixedArray::makei(4, fn { _ => b'\x00' })
  let char = '🙅'
  let len = arr.set_utf8_char(0, char)
  let bytes = @bytes.from_fixedarray(arr)
  assert_eq!(len, 4)
  inspect!(
    bytes,
    content=
      #|b"\xf0\x9f\x99\x85"
    ,
  )
}

test "set_utf16le_char" {
  let arr = FixedArray::makei(4, fn { _ => b'\x00' })
  let char = 'A'
  let len = arr.set_utf16le_char(0, char)
  let bytes = @bytes.from_fixedarray(arr)
  assert_eq!(len, 2)
  assert_eq!(bytes.to_unchecked_string(offset=0, length=2), "A")
  inspect!(
    bytes,
    content=
      #|b"\x41\x00\x00\x00"
    ,
  )
}

test "set_utf16le_char (surrogate pair)" {
  let arr = FixedArray::makei(4, fn { _ => b'\x00' })
  let char = '🉑'
  let len = arr.set_utf16le_char(0, char)
  let bytes = @bytes.from_fixedarray(arr)
  assert_eq!(len, 4)
  assert_eq!(bytes.to_unchecked_string(offset=0, length=4), "🉑")
  inspect!(
    bytes,
    content=
      #|b"\x3c\xd8\x51\xde"
    ,
  )
}

test "set_utf16be_char" {
  let arr = FixedArray::makei(4, fn { _ => b'\x00' })
  let char = 'A'
  let len = arr.set_utf16be_char(0, char)
  let bytes = @bytes.from_fixedarray(arr)
  assert_eq!(len, 2)
  inspect!(
    bytes,
    content=
      #|b"\x00\x41\x00\x00"
    ,
  )
}

test "op_equal" {
  let bytes = Bytes::of_string("Hello, World!")
  let copy_bytes = bytes.copy()
  assert_eq!(bytes, copy_bytes)
  assert_not_eq!(bytes, Bytes::new(10))
}

test "fixedarray_byte_blit_from_string" {
  let arr : FixedArray[Byte] = FixedArray::make(10, Byte::default())
  let str = "Hello"
  arr.blit_from_string(0, str, 0, str.length())
  inspect!(
    arr,
    content="[b'\\x48', b'\\x00', b'\\x65', b'\\x00', b'\\x6C', b'\\x00', b'\\x6C', b'\\x00', b'\\x6F', b'\\x00']",
  )
}

test "fixedarray_byte_blit_from_bytes" {
  let arr : FixedArray[Byte] = FixedArray::make(5, Byte::default())
  let bytes = b"Hello"
  arr.blit_from_bytes(0, bytes, 0, bytes.length())
  inspect!(arr, content="[b'\\x48', b'\\x65', b'\\x6C', b'\\x6C', b'\\x6F']")
}
