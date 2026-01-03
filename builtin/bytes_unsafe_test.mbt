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
test "unsafe_write_uint64_le basic functionality" {
  // Test with known value
  let buffer : FixedArray[Byte] = FixedArray::make(8, 0)
  FixedArray::unsafe_write_uint64_le(buffer, 0, 0x0102030405060708UL)

  // Check each byte individually
  inspect(buffer[0], content="b'\\x08'") // 0x08
  inspect(buffer[1], content="b'\\x07'") // 0x07
  inspect(buffer[2], content="b'\\x06'") // 0x06
  inspect(buffer[3], content="b'\\x05'") // 0x05
  inspect(buffer[4], content="b'\\x04'") // 0x04
  inspect(buffer[5], content="b'\\x03'") // 0x03
  inspect(buffer[6], content="b'\\x02'") // 0x02
  inspect(buffer[7], content="b'\\x01'") // 0x01

  // Test with zero
  let zero_buffer : FixedArray[Byte] = FixedArray::make(8, 255) // Fill with 0xFF initially
  FixedArray::unsafe_write_uint64_le(zero_buffer, 0, 0UL)
  for i in 0..=7 {
    inspect(zero_buffer[i], content="b'\\x00'")
  }

  // Test with maximum value
  let max_buffer : FixedArray[Byte] = FixedArray::make(8, 0)
  FixedArray::unsafe_write_uint64_le(max_buffer, 0, 0xFFFFFFFFFFFFFFFFUL)
  for i in 0..=7 {
    inspect(max_buffer[i], content="b'\\xFF'") // All bytes should be 0xFF
  }
}

///|
test "unsafe_write_uint64_be basic functionality" {
  // Test with known value
  let buffer : FixedArray[Byte] = FixedArray::make(8, 0)
  FixedArray::unsafe_write_uint64_be(buffer, 0, 0x0102030405060708UL)

  // Check each byte individually (big-endian order)
  inspect(buffer[0], content="b'\\x01'") // 0x01
  inspect(buffer[1], content="b'\\x02'") // 0x02
  inspect(buffer[2], content="b'\\x03'") // 0x03
  inspect(buffer[3], content="b'\\x04'") // 0x04
  inspect(buffer[4], content="b'\\x05'") // 0x05
  inspect(buffer[5], content="b'\\x06'") // 0x06
  inspect(buffer[6], content="b'\\x07'") // 0x07
  inspect(buffer[7], content="b'\\x08'") // 0x08

  // Test with alternating pattern
  let alt_buffer : FixedArray[Byte] = FixedArray::make(8, 0)
  FixedArray::unsafe_write_uint64_be(alt_buffer, 0, 0xFF00FF00FF00FF00UL)
  inspect(alt_buffer[0], content="b'\\xFF'") // 0xFF
  inspect(alt_buffer[1], content="b'\\x00'") // 0x00
  inspect(alt_buffer[2], content="b'\\xFF'") // 0xFF
  inspect(alt_buffer[3], content="b'\\x00'") // 0x00
  inspect(alt_buffer[4], content="b'\\xFF'") // 0xFF
  inspect(alt_buffer[5], content="b'\\x00'") // 0x00
  inspect(alt_buffer[6], content="b'\\xFF'") // 0xFF
  inspect(alt_buffer[7], content="b'\\x00'") // 0x00
}

///|
test "unsafe_write_uint32_le basic functionality" {
  // Test with known value
  let buffer : FixedArray[Byte] = FixedArray::make(4, 0)
  FixedArray::unsafe_write_uint32_le(buffer, 0, 0x01020304U)

  // Check each byte individually (little-endian order)
  inspect(buffer[0], content="b'\\x04'") // 0x04
  inspect(buffer[1], content="b'\\x03'") // 0x03
  inspect(buffer[2], content="b'\\x02'") // 0x02
  inspect(buffer[3], content="b'\\x01'") // 0x01

  // Test with zero
  let zero_buffer : FixedArray[Byte] = FixedArray::make(4, 255)
  FixedArray::unsafe_write_uint32_le(zero_buffer, 0, 0U)
  for i in 0..=3 {
    inspect(zero_buffer[i], content="b'\\x00'")
  }

  // Test with maximum value
  let max_buffer : FixedArray[Byte] = FixedArray::make(4, 0)
  FixedArray::unsafe_write_uint32_le(max_buffer, 0, 0xFFFFFFFFU)
  for i in 0..=3 {
    inspect(max_buffer[i], content="b'\\xFF'")
  }
}

///|
test "unsafe_write_uint32_be basic functionality" {
  // Test with known value
  let buffer : FixedArray[Byte] = FixedArray::make(4, 0)
  FixedArray::unsafe_write_uint32_be(buffer, 0, 0x01020304U)

  // Check each byte individually (big-endian order)
  inspect(buffer[0], content="b'\\x01'") // 0x01
  inspect(buffer[1], content="b'\\x02'") // 0x02
  inspect(buffer[2], content="b'\\x03'") // 0x03
  inspect(buffer[3], content="b'\\x04'") // 0x04

  // Test with alternating pattern
  let alt_buffer : FixedArray[Byte] = FixedArray::make(4, 0)
  FixedArray::unsafe_write_uint32_be(alt_buffer, 0, 0xFF00FF00U)
  inspect(alt_buffer[0], content="b'\\xFF'") // 0xFF
  inspect(alt_buffer[1], content="b'\\x00'") // 0x00
  inspect(alt_buffer[2], content="b'\\xFF'") // 0xFF
  inspect(alt_buffer[3], content="b'\\x00'") // 0x00
}

///|
test "unsafe_write_uint16_le basic functionality" {
  // Test with known value
  let buffer : FixedArray[Byte] = FixedArray::make(2, 0)
  FixedArray::unsafe_write_uint16_le(buffer, 0, (0x0102 : UInt16))

  // Check each byte individually (little-endian order)
  inspect(buffer[0], content="b'\\x02'") // 0x02
  inspect(buffer[1], content="b'\\x01'") // 0x01

  // Test with zero
  let zero_buffer : FixedArray[Byte] = FixedArray::make(2, 255)
  FixedArray::unsafe_write_uint16_le(zero_buffer, 0, (0 : UInt16))
  inspect(zero_buffer[0], content="b'\\x00'")
  inspect(zero_buffer[1], content="b'\\x00'")

  // Test with maximum value
  let max_buffer : FixedArray[Byte] = FixedArray::make(2, 0)
  FixedArray::unsafe_write_uint16_le(max_buffer, 0, (0xFFFF : UInt16))
  inspect(max_buffer[0], content="b'\\xFF'")
  inspect(max_buffer[1], content="b'\\xFF'")
}

///|
test "unsafe_write_uint16_be basic functionality" {
  // Test with known value
  let buffer : FixedArray[Byte] = FixedArray::make(2, 0)
  FixedArray::unsafe_write_uint16_be(buffer, 0, (0x0102 : UInt16))

  // Check each byte individually (big-endian order)
  inspect(buffer[0], content="b'\\x01'") // 0x01
  inspect(buffer[1], content="b'\\x02'") // 0x02

  // Test with alternating pattern
  let alt_buffer : FixedArray[Byte] = FixedArray::make(2, 0)
  FixedArray::unsafe_write_uint16_be(alt_buffer, 0, (0xFF00 : UInt16))
  inspect(alt_buffer[0], content="b'\\xFF'") // 0xFF
  inspect(alt_buffer[1], content="b'\\x00'") // 0x00
}

///|
test "unsafe write functions with different offsets" {
  // Test writing at different positions in a larger buffer
  let buffer : FixedArray[Byte] = FixedArray::make(16, 0)

  // Write UInt64 at position 0
  FixedArray::unsafe_write_uint64_le(buffer, 0, 0x1111111111111111UL)

  // Write UInt32 at position 8
  FixedArray::unsafe_write_uint32_le(buffer, 8, 0x22222222U)

  // Write UInt16 at position 12
  FixedArray::unsafe_write_uint16_le(buffer, 12, (0x3333 : UInt16))

  // Check the results
  // UInt64 at 0-7 (little-endian)
  for i in 0..=7 {
    inspect(buffer[i], content="b'\\x11'") // 0x11
  }

  // UInt32 at 8-11 (little-endian)  
  for i in 8..=11 {
    inspect(buffer[i], content="b'\\x22'") // 0x22
  }

  // UInt16 at 12-13 (little-endian)
  inspect(buffer[12], content="b'\\x33'") // 0x33
  inspect(buffer[13], content="b'\\x33'") // 0x33

  // Remaining bytes should still be zero
  inspect(buffer[14], content="b'\\x00'")
  inspect(buffer[15], content="b'\\x00'")
}

///|
test "round-trip test: write then read back" {
  // Test that writing and reading back gives the same result
  let buffer : FixedArray[Byte] = FixedArray::make(16, 0)

  // Test UInt64
  let original_64 : UInt64 = 0x123456789ABCDEF0UL
  FixedArray::unsafe_write_uint64_le(buffer, 0, original_64)
  FixedArray::unsafe_write_uint64_be(buffer, 8, original_64)

  // Convert buffer to bytes to read back
  let bytes_data = Bytes::from_array(buffer)
  let read_back_le = bytes_data.unsafe_read_uint64_le(0)
  let read_back_be = bytes_data.unsafe_read_uint64_be(8)
  inspect(read_back_le == original_64, content="true")
  inspect(read_back_be == original_64, content="true")
}

///|
test "round-trip test: UInt32" {
  let buffer : FixedArray[Byte] = FixedArray::make(8, 0)
  let original_32 : UInt = 0x12345678U
  FixedArray::unsafe_write_uint32_le(buffer, 0, original_32)
  FixedArray::unsafe_write_uint32_be(buffer, 4, original_32)
  let bytes_data = Bytes::from_array(buffer)
  let read_back_le = bytes_data.unsafe_read_uint32_le(0)
  let read_back_be = bytes_data.unsafe_read_uint32_be(4)
  inspect(read_back_le == original_32, content="true")
  inspect(read_back_be == original_32, content="true")
}

///|
test "round-trip test: UInt16" {
  let buffer : FixedArray[Byte] = FixedArray::make(4, 0)

  // Temporarily avoiding direct UInt16 comparison due to compiler bug
  // Write a known pattern
  FixedArray::unsafe_write_uint16_le(buffer, 0, (0x1234 : UInt16))
  FixedArray::unsafe_write_uint16_be(buffer, 2, (0x1234 : UInt16))

  // Verify by checking individual bytes
  inspect(buffer[0], content="b'\\x34'") // 0x34 (little-endian)
  inspect(buffer[1], content="b'\\x12'") // 0x12
  inspect(buffer[2], content="b'\\x12'") // 0x12 (big-endian) 
  inspect(buffer[3], content="b'\\x34'") // 0x34
}

///|
test "endianness difference demonstration" {
  // Show the difference between little-endian and big-endian writes
  let le_buffer : FixedArray[Byte] = FixedArray::make(8, 0)
  let be_buffer : FixedArray[Byte] = FixedArray::make(8, 0)
  let value : UInt64 = 0x0102030405060708UL
  FixedArray::unsafe_write_uint64_le(le_buffer, 0, value)
  FixedArray::unsafe_write_uint64_be(be_buffer, 0, value)

  // Little-endian: least significant byte first
  inspect(le_buffer[0], content="b'\\x08'") // 0x08
  inspect(le_buffer[1], content="b'\\x07'") // 0x07
  inspect(le_buffer[7], content="b'\\x01'") // 0x01

  // Big-endian: most significant byte first
  inspect(be_buffer[0], content="b'\\x01'") // 0x01
  inspect(be_buffer[1], content="b'\\x02'") // 0x02
  inspect(be_buffer[7], content="b'\\x08'") // 0x08
}

///|
test "edge cases with boundary values" {
  // Test with powers of 2 and boundary values
  let buffer : FixedArray[Byte] = FixedArray::make(8, 0)

  // Test with 1 (should only set the least significant bit)
  FixedArray::unsafe_write_uint64_le(buffer, 0, 1UL)
  inspect(buffer[0], content="b'\\x01'")
  for i in 1..=7 {
    inspect(buffer[i], content="b'\\x00'")
  }

  // Reset buffer  
  for i in 0..=7 {
    buffer[i] = 0
  }

  // Test with 256 (should set the second byte in little-endian)
  FixedArray::unsafe_write_uint64_le(buffer, 0, 256UL)
  inspect(buffer[0], content="b'\\x00'")
  inspect(buffer[1], content="b'\\x01'")
  for i in 2..=7 {
    inspect(buffer[i], content="b'\\x00'")
  }
}

///|
test "overlapping writes" {
  // Test that overlapping writes work correctly
  let buffer : FixedArray[Byte] = FixedArray::make(12, 0)

  // Write a UInt64 at position 0
  FixedArray::unsafe_write_uint64_le(buffer, 0, 0xFFFFFFFFFFFFFFFFUL)

  // Overwrite part of it with a UInt32 at position 4
  FixedArray::unsafe_write_uint32_le(buffer, 4, 0x00000000U)

  // Check results: first 4 bytes should still be 0xFF, next 4 should be 0x00
  for i in 0..=3 {
    inspect(buffer[i], content="b'\\xFF'") // 0xFF
  }
  for i in 4..=7 {
    inspect(buffer[i], content="b'\\x00'") // 0x00
  }
  for i in 8..=11 {
    inspect(buffer[i], content="b'\\x00'") // Should remain 0 (untouched)
  }
}

///|
test "unsafe_read_uint16 and view reads" {
  let bytes = b"\x34\x12\x78\x56\x9a\xbc"
  inspect(bytes.unsafe_read_uint16_le(0).to_int(), content="4660")
  inspect(bytes.unsafe_read_uint16_be(0).to_int(), content="13330")
  let view = b"\x00\x01\x02\x03\x04\x05\x06\x07\x08"[1:9]
  inspect(view.unsafe_read_uint64_le(0) == 0x0807060504030201UL, content="true")
  inspect(view.unsafe_read_uint64_be(0) == 0x0102030405060708UL, content="true")
  inspect(view.unsafe_read_uint32_le(0) == 0x04030201U, content="true")
  inspect(view.unsafe_read_uint32_be(0) == 0x01020304U, content="true")
  inspect(view.unsafe_read_uint16_le(6).to_int(), content="2055")
  inspect(view.unsafe_read_uint16_be(6).to_int(), content="1800")
}
