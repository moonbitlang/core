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
test "View::unsafe_extract_byte" {
  let bytes = b"\x01\x02\x03\x04"
  let view = bytes[:]

  // Test extracting bytes at different offsets with bit positions
  inspect(view.unsafe_extract_byte(0, 8), content="b'\\x01'")
  inspect(view.unsafe_extract_byte(8, 8), content="b'\\x02'")
  inspect(view.unsafe_extract_byte(16, 8), content="b'\\x03'")
  inspect(view.unsafe_extract_byte(24, 8), content="b'\\x04'")
}

///|
test "View::unsafe_extract_int_le existing functionality" {
  let bytes = b"\x01\x02\x03\x04"
  let view = bytes[:]

  // Test 16-bit little-endian: 0x0201 = 513
  inspect(view.unsafe_extract_int_le(0, 16), content="513")

  // Test 24-bit little-endian: 0x030201 = 197121  
  inspect(view.unsafe_extract_int_le(0, 24), content="197121")

  // Test 32-bit little-endian: 0x04030201 = 67305985
  inspect(view.unsafe_extract_int_le(0, 32), content="67305985")
}

///|
test "View::unsafe_extract_int_be new functionality" {
  let bytes = b"\x01\x02\x03\x04"
  let view = bytes[:]

  // Test 16-bit big-endian: 0x0102 = 258
  inspect(view.unsafe_extract_int_be(0, 16), content="258")

  // Test 24-bit big-endian: 0x010203 = 66051
  inspect(view.unsafe_extract_int_be(0, 24), content="66051")

  // Test 32-bit big-endian: 0x01020304 = 16909060
  inspect(view.unsafe_extract_int_be(0, 32), content="16909060")
}

///|
test "View::unsafe_extract_int64_le new functionality" {
  let bytes = b"\x01\x02\x03\x04\x05\x06\x07\x08"
  let view = bytes[:]

  // Test different sizes of little-endian extraction
  inspect(view.unsafe_extract_int64_le(0, 16), content="513")
  inspect(view.unsafe_extract_int64_le(0, 24), content="197121")
  inspect(view.unsafe_extract_int64_le(0, 32), content="67305985")
  inspect(view.unsafe_extract_int64_le(0, 40), content="21542142465")
  inspect(view.unsafe_extract_int64_le(0, 48), content="6618611909121")
  inspect(view.unsafe_extract_int64_le(0, 56), content="1976943448883713")
  inspect(view.unsafe_extract_int64_le(0, 64), content="578437695752307201")
}

///|
test "View::unsafe_extract_int64_be new functionality" {
  let bytes = b"\x01\x02\x03\x04\x05\x06\x07\x08"
  let view = bytes[:]

  // Test different sizes of big-endian extraction
  inspect(view.unsafe_extract_int64_be(0, 16), content="258")
  inspect(view.unsafe_extract_int64_be(0, 24), content="66051")
  inspect(view.unsafe_extract_int64_be(0, 32), content="16909060")
  inspect(view.unsafe_extract_int64_be(0, 40), content="4328719365")
  inspect(view.unsafe_extract_int64_be(0, 48), content="1108152157446")
  inspect(view.unsafe_extract_int64_be(0, 56), content="283686952306183")
  inspect(view.unsafe_extract_int64_be(0, 64), content="72623859790382856")
}

///|
test "Bytes wrapper functions" {
  let bytes = b"\x01\x02\x03\x04\x05\x06\x07\x08"

  // Test Bytes::unsafe_extract_byte
  inspect(bytes.unsafe_extract_byte(0, 8), content="b'\\x01'")
  inspect(bytes.unsafe_extract_byte(8, 8), content="b'\\x02'")

  // Test Bytes::unsafe_extract_int_be
  inspect(bytes.unsafe_extract_int_be(0, 16), content="258")
  inspect(bytes.unsafe_extract_int_be(0, 32), content="16909060")

  // Test Bytes::unsafe_extract_int64_le
  inspect(bytes.unsafe_extract_int64_le(0, 32), content="67305985")
  inspect(bytes.unsafe_extract_int64_le(0, 64), content="578437695752307201")

  // Test Bytes::unsafe_extract_int64_be
  inspect(bytes.unsafe_extract_int64_be(0, 32), content="16909060")
  inspect(bytes.unsafe_extract_int64_be(0, 64), content="72623859790382856")
}

///|
test "compatibility with existing View functions" {
  let bytes = b"\x01\x02\x03\x04"
  let view = bytes[:]

  // Compare results with existing to_int functions
  assert_eq(view.unsafe_extract_int_le(0, 32), view.to_int_le())
  assert_eq(view.unsafe_extract_int_be(0, 32), view.to_int_be())
}

///|
test "compatibility with existing View functions for int64" {
  let bytes = b"\x01\x02\x03\x04\x05\x06\x07\x08"
  let view = bytes[:]

  // Compare results with existing to_int64 functions  
  assert_eq(view.unsafe_extract_int64_le(0, 64), view.to_int64_le())
  assert_eq(view.unsafe_extract_int64_be(0, 64), view.to_int64_be())
}

///|
test "endianness verification" {
  // Create a specific pattern to verify endianness
  let bytes = b"\x12\x34\x56\x78"
  let view = bytes[:]

  // Little-endian: least significant byte first
  // 0x78563412 = 2018915346
  inspect(view.unsafe_extract_int_le(0, 32), content="2018915346")

  // Big-endian: most significant byte first  
  // 0x12345678 = 305419896
  inspect(view.unsafe_extract_int_be(0, 32), content="305419896")
}

///|
test "mixed endianness in int64" {
  let bytes = b"\x12\x34\x56\x78\x9A\xBC\xDE\xF0"
  let view = bytes[:]

  // Verify that the byte order is correctly handled
  let le_result = view.unsafe_extract_int64_le(0, 64)
  let be_result = view.unsafe_extract_int64_be(0, 64)

  // They should be different unless the data is palindromic
  if le_result == be_result {
    fail(
      "Little-endian and big-endian results should be different for this data",
    )
  }
  inspect(le_result, content="-1090226688147180526")
  inspect(be_result, content="1311768467463790320")
}
