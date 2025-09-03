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
test "create buffer from bytes" {
  let bytes = b"1\x002\x003\x00"
  let buf = @buffer.from_bytes(bytes)
  inspect(buf, content="123")
}

///|
test "create buffer from array" {
  let arr = [b'4', b'\x00', b'5', b'\x00', b'6', b'\x00']
  let buf = @buffer.from_array(arr)
  inspect(buf, content="456")
}

///|
test "create buffer from iterator" {
  let iter = [b'5', b'\x00', b'6', b'\x00', b'7', b'\x00'].iter()
  let buf = @buffer.from_iter(iter)
  inspect(buf, content="567")
  let iter = [].iter()
  let buf = @buffer.from_iter(iter)
  inspect(buf, content="")
  let iter = b"0\x00".iter()
  let buf = @buffer.from_iter(iter)
  inspect(buf, content="0")
}

///|
test "length method" {
  let buf = @buffer.new(size_hint=100)
  inspect(buf.length(), content="0")
  buf.write_string("Test")
  inspect(buf.length(), content="8")
}

///|
test "is_empty method" {
  let buf = @buffer.new(size_hint=100)
  inspect(buf.is_empty(), content="true")
  buf.write_string("Test")
  inspect(buf.is_empty(), content="false")
}

///|
test "expect method with matching content" {
  let buf = @buffer.new(size_hint=100)
  buf.write_string("Test")
  inspect(buf, content="Test")
}

///|
test "grow_if_necessary method" {
  let buf = @buffer.new(size_hint=10)
  buf.write_string(
    "This is a test string that is longer than the initial capacity",
  )
  assert_true(buf.to_bytes().length() >= 60)
}

///|
test "write_substring method" {
  let buf = @buffer.new(size_hint=10)
  buf.write_substring("Hello, World!", 7, 5)
  inspect(buf, content="World")
}

///|
test "write_byte method" {
  let buf = @buffer.new(size_hint=10)
  buf.write_byte(b'A')
  buf.write_byte(b'\x00')
  inspect(buf, content="A")
}

///|
test "to_bytes method" {
  let buf = @buffer.new(size_hint=10)
  buf.write_string("Test")
  let bytes = buf.to_bytes()
  inspect(bytes.length(), content="8") // Each character in "Test" is 2 bytes
}

///|
test "write_bytes" {
  let buf = @buffer.new(size_hint=4)
  buf.write_bytes(b"1\x002\x003\x004\x00")
  buf.write_bytes(b"5\x006\x007\x008\x00")
  inspect(buf, content="12345678")
}

///|
test "write_uint64_le method" {
  let buf = @buffer.new(size_hint=16)
  buf.write_uint64_le(0xdeadbeefaabbccdd)
  buf.write_uint64_le(0xfacefeedaabbccdd)
  inspect(
    buf.to_bytes(),
    content=(
      #|b"\xdd\xcc\xbb\xaa\xef\xbe\xad\xde\xdd\xcc\xbb\xaa\xed\xfe\xce\xfa"
    ),
  )
}

///|
test "write_uint64_be method" {
  let buf = @buffer.new(size_hint=16)
  buf.write_uint64_be(0xdeadbeefaabbccdd)
  buf.write_uint64_be(0xfacefeedaabbccdd)
  inspect(
    buf.to_bytes(),
    content=(
      #|b"\xde\xad\xbe\xef\xaa\xbb\xcc\xdd\xfa\xce\xfe\xed\xaa\xbb\xcc\xdd"
    ),
  )
}

///|
test "write_int64_le method" {
  let buf = @buffer.new(size_hint=16)
  buf.write_int64_le(-2)
  buf.write_int64_le(0xdeadbeeffacefeed)
  inspect(
    buf.to_bytes(),
    content=(
      #|b"\xfe\xff\xff\xff\xff\xff\xff\xff\xed\xfe\xce\xfa\xef\xbe\xad\xde"
    ),
  )
}

///|
test "write_int64_be method" {
  let buf = @buffer.new(size_hint=16)
  buf.write_int64_be(-2)
  buf.write_int64_be(0xdeadbeef)
  inspect(
    buf.to_bytes(),
    content=(
      #|b"\xff\xff\xff\xff\xff\xff\xff\xfe\x00\x00\x00\x00\xde\xad\xbe\xef"
    ),
  )
}

///|
test "write_uint_le method" {
  let buf = @buffer.new(size_hint=8)
  buf.write_uint_le(0xdeadbeef)
  buf.write_uint_le(0xdeadc0de)
  inspect(
    buf.to_bytes(),
    content=(
      #|b"\xef\xbe\xad\xde\xde\xc0\xad\xde"
    ),
  )
}

///|
test "write_uint_be method" {
  let buf = @buffer.new(size_hint=8)
  buf.write_uint_be(0xdeadbeef)
  buf.write_uint_be(0xdeadc0de)
  inspect(
    buf.to_bytes(),
    content=(
      #|b"\xde\xad\xbe\xef\xde\xad\xc0\xde"
    ),
  )
}

///|
test "write_int_le method" {
  let buf = @buffer.new(size_hint=8)
  buf.write_int_le(-2)
  buf.write_int_le(0xdeadbeef)
  inspect(
    buf.to_bytes(),
    content=(
      #|b"\xfe\xff\xff\xff\xef\xbe\xad\xde"
    ),
  )
}

///|
test "write_int_be method" {
  let buf = @buffer.new(size_hint=8)
  buf.write_int_be(-2)
  buf.write_int_be(0xdeadbeef)
  inspect(
    buf.to_bytes(),
    content=(
      #|b"\xff\xff\xff\xfe\xde\xad\xbe\xef"
    ),
  )
}

///|
test "write_double_le method" {
  let buf = @buffer.new(size_hint=16)
  buf.write_double_le(-2)
  buf.write_double_le(3.14)
  inspect(
    buf.to_bytes(),
    content=(
      #|b"\x00\x00\x00\x00\x00\x00\x00\xc0\x1f\x85\xeb\x51\xb8\x1e\x09\x40"
    ),
  )
}

///|
test "write_double_be method" {
  let buf = @buffer.new(size_hint=16)
  buf.write_double_be(-2)
  buf.write_double_be(3.14)
  inspect(
    buf.to_bytes(),
    content=(
      #|b"\xc0\x00\x00\x00\x00\x00\x00\x00\x40\x09\x1e\xb8\x51\xeb\x85\x1f"
    ),
  )
}

///|
test "write_float_le method" {
  let buf = @buffer.new(size_hint=8)
  buf.write_float_le(-2)
  buf.write_float_le(3.14)
  inspect(
    buf.to_bytes(),
    content=(
      #|b"\x00\x00\x00\xc0\xc3\xf5\x48\x40"
    ),
  )
}

///|
test "write_float_be method" {
  let buf = @buffer.new(size_hint=8)
  buf.write_float_be(-2)
  buf.write_float_be(3.14)
  inspect(
    buf.to_bytes(),
    content=(
      #|b"\xc0\x00\x00\x00\x40\x48\xf5\xc3"
    ),
  )
}

///|
test "write_iter" {
  let bytes = b"hello"
  let buf = @buffer.new()
  buf.write_iter(bytes.iter())
  inspect(
    buf.contents(),
    content=(
      #|b"\x68\x65\x6c\x6c\x6f"
    ),
  )
  let bytes_view = bytes[1:3]
  buf.write_iter(bytes_view.iter())
  inspect(
    buf.contents(),
    content=(
      #|b"\x68\x65\x6c\x6c\x6f\x65\x6c"
    ),
  )
}

///|
test "write_bytesview" {
  let buf = @buffer.new(size_hint=4)
  buf.write_bytesview(b"Test"[1:3])
  inspect(
    buf.contents(),
    content=(
      #|b"\x65\x73"
    ),
  )
}

///|
test "write_stringview" {
  let buf = @buffer.new()
  buf.write_string_utf16le("hello"[1:3])
  inspect(
    buf.contents(),
    content=(
      #|b"\x65\x00\x6c\x00"
    ),
  )
}

///|
test "write_char_utf8" {
  let buf = @buffer.new(size_hint=10)
  buf.write_char_utf8('A')
  buf.write_char_utf8('α')
  buf.write_char_utf8('啊')
  buf.write_char_utf8('😦')
  inspect(
    buf.to_bytes(),
    content=(
      #|b"\x41\xce\xb1\xe5\x95\x8a\xf0\x9f\x98\xa6"
    ),
  )
}

///|
test "write_char" {
  let buf = @buffer.new(size_hint=10)
  buf.write_char('A')
  buf.write_char('α')
  buf.write_char('啊')
  buf.write_char('😦')
  inspect(
    buf.to_bytes(),
    content=(
      #|b"\x41\x00\xb1\x03\x4a\x55\x3d\xd8\x26\xde"
    ),
  )
}

///|
test "write_char_utf16le" {
  let buf = @buffer.new(size_hint=10)
  buf.write_char_utf16le('A')
  buf.write_char_utf16le('α')
  buf.write_char_utf16le('啊')
  buf.write_char_utf16le('😦')
  inspect(
    buf.to_bytes(),
    content=(
      #|b"\x41\x00\xb1\x03\x4a\x55\x3d\xd8\x26\xde"
    ),
  )
}

///|
test "write_char_utf16be" {
  let buf = @buffer.new(size_hint=10)
  buf.write_char_utf16be('A')
  buf.write_char_utf16be('α')
  buf.write_char_utf16be('啊')
  buf.write_char_utf16be('😦')
  inspect(
    buf.to_bytes(),
    content=(
      #|b"\x00\x41\x03\xb1\x55\x4a\xd8\x3d\xde\x26"
    ),
  )
}

///|
const BOM : Char = '\u{FEFF}'

///|
test "write_bom_utf8" {
  let buf = @buffer.new()
  buf.write_char_utf8(BOM)
  inspect(
    buf.to_bytes(),
    content=(
      #|b"\xef\xbb\xbf"
    ),
  )
}

///|
test "write_bom_utf16le" {
  let buf = @buffer.new()
  buf.write_char_utf16le(BOM)
  inspect(
    buf.to_bytes(),
    content=(
      #|b"\xff\xfe"
    ),
  )
}

///|
test "write_bom_utf16be" {
  let buf = @buffer.new()
  buf.write_char_utf16be(BOM)
  inspect(
    buf.to_bytes(),
    content=(
      #|b"\xfe\xff"
    ),
  )
}
