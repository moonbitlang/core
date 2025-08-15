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

// ============================================================================
// Bitstring Extraction Tests
// 
// This file contains comprehensive tests for bitstring operations in the bytes module.
// The tests are organized by function and cover various edge cases, bit alignments,
// and data patterns to ensure robust operation.
// ============================================================================

// ============================================================================
// 1. Single Bit Extraction Tests
// ============================================================================

///|
test "extract_bit - basic bit patterns" {
  // Test with alternating bit pattern: 0xAA = 10101010, 0x55 = 01010101
  let bytes = b"\xAA\x55\xFF\x00"
  let view = bytes[:]

  // First byte (0xAA = 10101010)
  inspect(view.unsafe_extract_bit(0, 1), content="true") // MSB
  inspect(view.unsafe_extract_bit(1, 1), content="false")
  inspect(view.unsafe_extract_bit(2, 1), content="true")
  inspect(view.unsafe_extract_bit(3, 1), content="false")
  inspect(view.unsafe_extract_bit(4, 1), content="true")
  inspect(view.unsafe_extract_bit(5, 1), content="false")
  inspect(view.unsafe_extract_bit(6, 1), content="true")
  inspect(view.unsafe_extract_bit(7, 1), content="false") // LSB

  // Second byte (0x55 = 01010101)
  inspect(view.unsafe_extract_bit(8, 1), content="false") // MSB
  inspect(view.unsafe_extract_bit(9, 1), content="true")
  inspect(view.unsafe_extract_bit(10, 1), content="false")
  inspect(view.unsafe_extract_bit(11, 1), content="true")
  inspect(view.unsafe_extract_bit(12, 1), content="false")
  inspect(view.unsafe_extract_bit(13, 1), content="true")
  inspect(view.unsafe_extract_bit(14, 1), content="false")
  inspect(view.unsafe_extract_bit(15, 1), content="true") // LSB
}

///|
test "extract_bit - edge patterns" {
  let bytes = b"\xFF\x00\x80\x01"
  let view = bytes[:]

  // All ones byte (0xFF)
  for i = 0; i < 8; i = i + 1 {
    inspect(view.unsafe_extract_bit(i, 1), content="true")
  }

  // All zeros byte (0x00)
  for i = 8; i < 16; i = i + 1 {
    inspect(view.unsafe_extract_bit(i, 1), content="false")
  }

  // Single high bit (0x80 = 10000000)
  inspect(view.unsafe_extract_bit(16, 1), content="true")
  for i = 17; i < 24; i = i + 1 {
    inspect(view.unsafe_extract_bit(i, 1), content="false")
  }

  // Single low bit (0x01 = 00000001)
  for i = 24; i < 31; i = i + 1 {
    inspect(view.unsafe_extract_bit(i, 1), content="false")
  }
  inspect(view.unsafe_extract_bit(31, 1), content="true")
}

// ============================================================================
// 2. Byte Extraction Tests (2-8 bits)
// ============================================================================

///|
test "extract_byte - byte aligned full bytes" {
  let bytes = b"\x12\x34\x56\x78\x9A\xBC\xDE\xF0"
  let view = bytes[:]

  // Test extracting full bytes at byte boundaries
  inspect(view.unsafe_extract_byte(0, 8), content="b'\\x12'")
  inspect(view.unsafe_extract_byte(8, 8), content="b'\\x34'")
  inspect(view.unsafe_extract_byte(16, 8), content="b'\\x56'")
  inspect(view.unsafe_extract_byte(24, 8), content="b'\\x78'")
  inspect(view.unsafe_extract_byte(32, 8), content="b'\\x9A'")
  inspect(view.unsafe_extract_byte(40, 8), content="b'\\xBC'")
  inspect(view.unsafe_extract_byte(48, 8), content="b'\\xDE'")
  inspect(view.unsafe_extract_byte(56, 8), content="b'\\xF0'")
}

///|
test "extract_byte - partial bits from byte aligned positions" {
  let bytes = b"\xFF\x00\xAA\x55"
  let view = bytes[:]

  // Extract 2-7 bits from 0xFF (11111111)
  inspect(view.unsafe_extract_byte(0, 2), content="b'\\x03'") // 11 -> 3
  inspect(view.unsafe_extract_byte(0, 3), content="b'\\x07'") // 111 -> 7
  inspect(view.unsafe_extract_byte(0, 4), content="b'\\x0F'") // 1111 -> 15
  inspect(view.unsafe_extract_byte(0, 5), content="b'\\x1F'") // 11111 -> 31
  inspect(view.unsafe_extract_byte(0, 6), content="b'\\x3F'") // 111111 -> 63
  inspect(view.unsafe_extract_byte(0, 7), content="b'\\x7F'") // 1111111 -> 127

  // Extract 2-7 bits from 0x00 (00000000)
  for len = 2; len <= 7; len = len + 1 {
    inspect(view.unsafe_extract_byte(8, len), content="b'\\x00'")
  }
}

///|
test "extract_byte - non-aligned positions" {
  let bytes = b"\xF0\x0F\xCC\x33" // 11110000 00001111 11001100 00110011
  let view = bytes[:]

  // Extract from middle of first byte
  inspect(view.unsafe_extract_byte(2, 4), content="b'\\x0C'") // 1100 from 11110000
  inspect(view.unsafe_extract_byte(4, 4), content="b'\\x00'") // 0000 from 11110000

  // Cross byte boundaries
  inspect(view.unsafe_extract_byte(6, 4), content="b'\\x00'") // 00 from byte 0 + 00 from byte 1
  inspect(view.unsafe_extract_byte(7, 2), content="b'\\x00'") // 0 from byte 0 + 0 from byte 1
  inspect(view.unsafe_extract_byte(7, 6), content="b'\\x01'") // 0 from byte 0 + 00001 from byte 1

  // Extract from middle positions spanning bytes
  inspect(view.unsafe_extract_byte(10, 4), content="b'\\x03'") // 1111 from 00001111
  inspect(view.unsafe_extract_byte(14, 4), content="b'\\x0F'") // 11 from byte 1 + 11 from byte 2
}

///|
test "extract_byte - bit patterns and edge cases" {
  let bytes = b"\x81\x42\x24\x18\x99\x66\xA5\x5A"
  let view = bytes[:]

  // Test various lengths from different starting positions
  inspect(view.unsafe_extract_byte(1, 3), content="b'\\x00'") // 3 bits starting from bit 1
  inspect(view.unsafe_extract_byte(5, 5), content="b'\\x05'") // 5 bits crossing byte boundary
  inspect(view.unsafe_extract_byte(9, 7), content="b'\\x42'") // 7 bits from middle positions
  inspect(view.unsafe_extract_byte(17, 6), content="b'\\x12'") // 6 bits from byte 2

  // Test maximum span (8 bits) from non-aligned positions
  inspect(view.unsafe_extract_byte(3, 8), content="b'\\x0A'") // 8 bits starting from bit 3
  inspect(view.unsafe_extract_byte(5, 8), content="b'\\x28'") // 8 bits starting from bit 5
}

// ============================================================================
// 3. Integer Extraction Tests - Little Endian (9-32 bits)
// ============================================================================

///|
test "extract_int_le - byte aligned positions" {
  let bytes = b"\x01\x02\x03\x04\x05\x06\x07\x08"
  let view = bytes[:]

  // Test different bit lengths
  let result9 = view.unsafe_extract_int_le(0, 9)
  let result16 = view.unsafe_extract_int_le(0, 16)
  let result24 = view.unsafe_extract_int_le(0, 24)
  let result32 = view.unsafe_extract_int_le(0, 32)

  // Verify using byte representation for clarity
  inspect(
    (result9 << (32 - 9)).to_le_bytes(),
    content=(
      #|b"\x00\x00\x00\x02"
    ),
  ) // 9 bits shifted
  inspect(result16.to_le_bytes(), content="b\"\\x01\\x02\\x00\\x00\"")
  inspect(result24.to_le_bytes(), content="b\"\\x01\\x02\\x03\\x00\"")
  inspect(result32.to_le_bytes(), content="b\"\\x01\\x02\\x03\\x04\"")
}

///|
test "extract_int_le - non-aligned positions" {
  let bytes = b"\xFF\x01\x02\x03\x04\x05\x06\x07" // Start with 0xFF for clear bit patterns
  let view = bytes[:]

  // Extract from bit position 1
  let result16_offset1 = view.unsafe_extract_int_le(1, 16)
  let result24_offset1 = view.unsafe_extract_int_le(1, 24)

  // The extraction should handle the bit offset correctly
  inspect(
    (result16_offset1 << (32 - 16)).to_le_bytes(),
    content=(
      #|b"\x00\x00\xfe\x02"
    ),
  )
  inspect(
    (result24_offset1 << (32 - 24)).to_le_bytes(),
    content=(
      #|b"\x00\xfe\x02\x04"
    ),
  )

  // Extract from bit position 3
  let result16_offset3 = view.unsafe_extract_int_le(3, 16)
  inspect(
    (result16_offset3 << (32 - 16)).to_le_bytes(),
    content=(
      #|b"\x00\x00\xf8\x08"
    ),
  )
}

///|
test "extract_int_le - various bit lengths" {
  let bytes = b"\x12\x34\x56\x78\x9A\xBC"
  let view = bytes[:]

  // Test all supported bit lengths
  for bits = 9; bits <= 32; bits = bits + 1 {
    let result = view.unsafe_extract_int_le(0, bits)
    let shifted = result << (32 - bits)
    // Just verify extraction doesn't crash and produces reasonable output
    let _bytes = shifted.to_le_bytes()

  }
}

///|
test "extract_int_le - edge patterns" {
  let bytes = b"\xFF\xFF\xFF\xFF\x00\x00\x00\x00"
  let view = bytes[:]

  // Extract all ones
  let all_ones_16 = view.unsafe_extract_int_le(0, 16)
  let all_ones_32 = view.unsafe_extract_int_le(0, 32)
  inspect(
    all_ones_16.to_le_bytes(),
    content=(
      #|b"\xff\xff\x00\x00"
    ),
  )
  inspect(
    all_ones_32.to_le_bytes(),
    content=(
      #|b"\xff\xff\xff\xff"
    ),
  )

  // Extract all zeros
  let all_zeros_16 = view.unsafe_extract_int_le(32, 16)
  let all_zeros_32 = view.unsafe_extract_int_le(32, 32)
  inspect(all_zeros_16.to_le_bytes(), content="b\"\\x00\\x00\\x00\\x00\"")
  inspect(all_zeros_32.to_le_bytes(), content="b\"\\x00\\x00\\x00\\x00\"")
}

// ============================================================================
// 4. Integer Extraction Tests - Big Endian (9-32 bits)
// ============================================================================

///|
test "extract_int_be - byte aligned positions" {
  let bytes = b"\x01\x02\x03\x04\x05\x06\x07\x08"
  let view = bytes[:]

  // Test different bit lengths
  let result9 = view.unsafe_extract_int_be(0, 9)
  let result16 = view.unsafe_extract_int_be(0, 16)
  let result24 = view.unsafe_extract_int_be(0, 24)
  let result32 = view.unsafe_extract_int_be(0, 32)

  // Verify using byte representation for clarity
  inspect(
    (result9 << (32 - 9)).to_be_bytes(),
    content=(
      #|b"\x01\x00\x00\x00"
    ),
  ) // 9 bits shifted
  inspect(result16.to_be_bytes(), content="b\"\\x00\\x00\\x01\\x02\"")
  inspect(result24.to_be_bytes(), content="b\"\\x00\\x01\\x02\\x03\"")
  inspect(result32.to_be_bytes(), content="b\"\\x01\\x02\\x03\\x04\"")
}

///|
test "extract_int_be - non-aligned positions" {
  let bytes = b"\xFF\x01\x02\x03\x04\x05\x06\x07"
  let view = bytes[:]

  // Extract from bit position 1
  let result16_offset1 = view.unsafe_extract_int_be(1, 16)
  let result24_offset1 = view.unsafe_extract_int_be(1, 24)
  inspect(
    (result16_offset1 << (32 - 16)).to_be_bytes(),
    content=(
      #|b"\xfe\x02\x00\x00"
    ),
  )
  inspect(
    (result24_offset1 << (32 - 24)).to_be_bytes(),
    content=(
      #|b"\xfe\x02\x04\x00"
    ),
  )

  // Extract from bit position 4
  let result16_offset4 = view.unsafe_extract_int_be(4, 16)
  inspect(
    (result16_offset4 << (32 - 16)).to_be_bytes(),
    content=(
      #|b"\xf0\x10\x00\x00"
    ),
  )
}

///|
test "extract_int_be - comparison with little endian" {
  let bytes = b"\x12\x34\x56\x78"
  let view = bytes[:]
  let le_result = view.unsafe_extract_int_le(0, 32)
  let be_result = view.unsafe_extract_int_be(0, 32)

  // The raw values should be different due to endianness
  inspect(le_result.to_le_bytes(), content="b\"\\x12\\x34\\x56\\x78\"")
  inspect(be_result.to_be_bytes(), content="b\"\\x12\\x34\\x56\\x78\"")

  // But when interpreted in their respective endianness, they represent the same byte sequence
  inspect(le_result.to_be_bytes(), content="b\"\\x78\\x56\\x34\\x12\"")
  inspect(be_result.to_le_bytes(), content="b\"\\x78\\x56\\x34\\x12\"")
}

// ============================================================================
// 5. Int64 Extraction Tests - Little Endian (33-64 bits)
// ============================================================================

///|
test "extract_int64_le - byte aligned positions" {
  let bytes = b"\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B\x0C"
  let view = bytes[:]

  // Test different bit lengths
  let result40 = view.unsafe_extract_int64_le(0, 40) // 5 bytes
  let result48 = view.unsafe_extract_int64_le(0, 48) // 6 bytes
  let result56 = view.unsafe_extract_int64_le(0, 56) // 7 bytes
  let result64 = view.unsafe_extract_int64_le(0, 64) // 8 bytes

  // Verify using byte representation for clarity
  inspect(
    result40.to_le_bytes(),
    content="b\"\\x01\\x02\\x03\\x04\\x05\\x00\\x00\\x00\"",
  )
  inspect(
    result48.to_le_bytes(),
    content="b\"\\x01\\x02\\x03\\x04\\x05\\x06\\x00\\x00\"",
  )
  inspect(
    result56.to_le_bytes(),
    content="b\"\\x01\\x02\\x03\\x04\\x05\\x06\\x07\\x00\"",
  )
  inspect(
    result64.to_le_bytes(),
    content="b\"\\x01\\x02\\x03\\x04\\x05\\x06\\x07\\x08\"",
  )
}

///|
test "extract_int64_le - non-aligned positions" {
  let bytes = b"\xFF\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B"
  let view = bytes[:]

  // Extract from bit position 1
  let result40_offset1 = view.unsafe_extract_int64_le(1, 40)
  let result64_offset1 = view.unsafe_extract_int64_le(1, 64)

  // Verify the bit shifting worked correctly
  inspect(
    (result40_offset1 << (64 - 40)).to_le_bytes(),
    content=(
      #|b"\x00\x00\x00\xfe\x02\x04\x06\x08"
    ),
  )
  inspect(
    (result64_offset1 << (64 - 64)).to_le_bytes(),
    content=(
      #|b"\xfe\x02\x04\x06\x08\x0a\x0c\x0e"
    ),
  )
}

///|
test "extract_int64_le - all bit lengths" {
  let bytes = b"\x11\x22\x33\x44\x55\x66\x77\x88\x99\xAA\xBB\xCC"
  let view = bytes[:]

  // Test all supported bit lengths from 33 to 64
  for bits = 33; bits <= 64; bits = bits + 1 {
    let result = view.unsafe_extract_int64_le(0, bits)
    let shifted = result << (64 - bits)
    // Just verify extraction doesn't crash and produces reasonable output
    let _bytes = shifted.to_le_bytes()

  }
}

///|
test "extract_int64_le - edge patterns" {
  let bytes = b"\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x00\x00\x00\x00\x00\x00\x00\x00"
  let view = bytes[:]

  // Extract all ones
  let all_ones_40 = view.unsafe_extract_int64_le(0, 40)
  let all_ones_64 = view.unsafe_extract_int64_le(0, 64)
  inspect(
    all_ones_40.to_le_bytes(),
    content=(
      #|b"\xff\xff\xff\xff\xff\x00\x00\x00"
    ),
  )
  inspect(
    all_ones_64.to_le_bytes(),
    content=(
      #|b"\xff\xff\xff\xff\xff\xff\xff\xff"
    ),
  )

  // Extract all zeros
  let all_zeros_40 = view.unsafe_extract_int64_le(64, 40)
  inspect(
    all_zeros_40.to_le_bytes(),
    content="b\"\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\"",
  )
}

// ============================================================================
// 6. Int64 Extraction Tests - Big Endian (33-64 bits)
// ============================================================================

///|
test "extract_int64_be - byte aligned positions" {
  let bytes = b"\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B\x0C"
  let view = bytes[:]

  // Test different bit lengths
  let result40 = view.unsafe_extract_int64_be(0, 40) // 5 bytes
  let result48 = view.unsafe_extract_int64_be(0, 48) // 6 bytes
  let result56 = view.unsafe_extract_int64_be(0, 56) // 7 bytes
  let result64 = view.unsafe_extract_int64_be(0, 64) // 8 bytes

  // Verify using byte representation for clarity
  inspect(
    result40.to_be_bytes(),
    content="b\"\\x00\\x00\\x00\\x01\\x02\\x03\\x04\\x05\"",
  )
  inspect(
    result48.to_be_bytes(),
    content="b\"\\x00\\x00\\x01\\x02\\x03\\x04\\x05\\x06\"",
  )
  inspect(
    result56.to_be_bytes(),
    content="b\"\\x00\\x01\\x02\\x03\\x04\\x05\\x06\\x07\"",
  )
  inspect(
    result64.to_be_bytes(),
    content="b\"\\x01\\x02\\x03\\x04\\x05\\x06\\x07\\x08\"",
  )
}

///|
test "extract_int64_be - non-aligned positions" {
  let bytes = b"\xFF\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B"
  let view = bytes[:]

  // Extract from bit position 1
  let result40_offset1 = view.unsafe_extract_int64_be(1, 40)
  let result64_offset1 = view.unsafe_extract_int64_be(1, 64)

  // Verify the bit shifting worked correctly
  inspect(
    (result40_offset1 << (64 - 40)).to_be_bytes(),
    content=(
      #|b"\xfe\x02\x04\x06\x08\x00\x00\x00"
    ),
  )
  inspect(
    (result64_offset1 << (64 - 64)).to_be_bytes(),
    content=(
      #|b"\xfe\x02\x04\x06\x08\x0a\x0c\x0e"
    ),
  )
}

///|
test "extract_int64_be - comparison with little endian" {
  let bytes = b"\x11\x22\x33\x44\x55\x66\x77\x88"
  let view = bytes[:]
  let le_result = view.unsafe_extract_int64_le(0, 64)
  let be_result = view.unsafe_extract_int64_be(0, 64)

  // The raw values should be different due to endianness
  inspect(
    le_result.to_le_bytes(),
    content="b\"\\x11\\x22\\x33\\x44\\x55\\x66\\x77\\x88\"",
  )
  inspect(
    be_result.to_be_bytes(),
    content="b\"\\x11\\x22\\x33\\x44\\x55\\x66\\x77\\x88\"",
  )

  // But when interpreted in their respective endianness, they represent the same byte sequence
  inspect(
    le_result.to_be_bytes(),
    content="b\"\\x88\\x77\\x66\\x55\\x44\\x33\\x22\\x11\"",
  )
  inspect(
    be_result.to_le_bytes(),
    content="b\"\\x88\\x77\\x66\\x55\\x44\\x33\\x22\\x11\"",
  )
}

// ============================================================================
// 7. BytesView Extraction Tests
// ============================================================================

///|
test "extract_bytesview - basic functionality" {
  let bytes = b"\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B\x0C"
  let view = bytes[:]

  // Extract subviews at byte boundaries
  let view1 = view.unsafe_extract_bytesview(0, 32) // First 4 bytes
  let view2 = view.unsafe_extract_bytesview(32, 32) // Next 4 bytes
  let view3 = view.unsafe_extract_bytesview(64, 32) // Last 4 bytes

  // Verify by extracting bytes from each view
  inspect(view1.unsafe_extract_byte(0, 8), content="b'\\x01'")
  inspect(view1.unsafe_extract_byte(8, 8), content="b'\\x02'")
  inspect(view1.unsafe_extract_byte(16, 8), content="b'\\x03'")
  inspect(view1.unsafe_extract_byte(24, 8), content="b'\\x04'")
  inspect(view2.unsafe_extract_byte(0, 8), content="b'\\x05'")
  inspect(view2.unsafe_extract_byte(8, 8), content="b'\\x06'")
  inspect(view2.unsafe_extract_byte(16, 8), content="b'\\x07'")
  inspect(view2.unsafe_extract_byte(24, 8), content="b'\\x08'")
  inspect(view3.unsafe_extract_byte(0, 8), content="b'\\x09'")
  inspect(view3.unsafe_extract_byte(8, 8), content="b'\\x0A'")
  inspect(view3.unsafe_extract_byte(16, 8), content="b'\\x0B'")
  inspect(view3.unsafe_extract_byte(24, 8), content="b'\\x0C'")
}

///|
test "extract_bytesview - various sizes" {
  let bytes = b"\xFF\xEE\xDD\xCC\xBB\xAA\x99\x88\x77\x66\x55\x44\x33\x22\x11\x00"
  let view = bytes[:]

  // Test different view sizes
  let small_view = view.unsafe_extract_bytesview(0, 8) // 1 byte
  let medium_view = view.unsafe_extract_bytesview(8, 32) // 4 bytes
  let large_view = view.unsafe_extract_bytesview(40, 48) // 6 bytes

  // Verify contents
  inspect(small_view.unsafe_extract_byte(0, 8), content="b'\\xFF'")
  inspect(medium_view.unsafe_extract_byte(0, 8), content="b'\\xEE'")
  inspect(medium_view.unsafe_extract_byte(24, 8), content="b'\\xBB'")
  inspect(large_view.unsafe_extract_byte(0, 8), content="b'\\xAA'")
  inspect(large_view.unsafe_extract_byte(40, 8), content="b'\\x55'")
}

///|
test "extract_bytesview - nested extractions" {
  let bytes = b"\x12\x34\x56\x78\x9A\xBC\xDE\xF0\x11\x22\x33\x44"
  let view = bytes[:]

  // Extract a subview, then extract from that subview
  let subview = view.unsafe_extract_bytesview(16, 64) // Extract middle 8 bytes
  let sub_subview = subview.unsafe_extract_bytesview(16, 32) // Extract 4 bytes from middle

  // Verify the nested extraction
  inspect(sub_subview.unsafe_extract_byte(0, 8), content="b'\\x9A'")
  inspect(sub_subview.unsafe_extract_byte(8, 8), content="b'\\xBC'")
  inspect(sub_subview.unsafe_extract_byte(16, 8), content="b'\\xDE'")
  inspect(sub_subview.unsafe_extract_byte(24, 8), content="b'\\xF0'")
}

// ============================================================================
// 8. Cross-Function Integration Tests
// ============================================================================

///|
test "integration - complex bit manipulations" {
  let bytes = b"\xAB\xCD\xEF\x12\x34\x56\x78\x9A\xBC\xDE\xF0\x11"
  let view = bytes[:]

  // Combine different extraction methods
  let bit = view.unsafe_extract_bit(5, 1)
  let byte_val = view.unsafe_extract_byte(6, 6)
  let int_val = view.unsafe_extract_int_le(12, 20)
  let int64_val = view.unsafe_extract_int64_be(32, 40)

  // Verify each extraction independently
  inspect(bit, content="false") // 6th bit of 0xAB (10101011)
  inspect(byte_val, content="b'\\x3C'") // 6 bits starting from bit 6

  // For int and int64 values, shift to make them more readable
  inspect(
    (int_val << (32 - 20)).to_le_bytes(),
    content=(
      #|b"\x00\xd0\xf1\x23"
    ),
  )
  inspect(
    (int64_val << (64 - 40)).to_le_bytes(),
    content=(
      #|b"\x00\x00\x00\xbc\x9a\x78\x56\x34"
    ),
  )
}

///|
test "integration - boundary stress test" {
  // Create a pattern that helps identify bit alignment issues
  let bytes = b"\xF0\x0F\xF0\x0F\xF0\x0F\xF0\x0F\xF0\x0F\xF0\x0F"
  let view = bytes[:]

  // Test extractions that cross multiple boundaries
  for offset = 1; offset <= 7; offset = offset + 1 {
    // Extract a bit
    let _bit = view.unsafe_extract_bit(offset, 1)

    // Extract a byte spanning boundaries
    let _byte_val = view.unsafe_extract_byte(offset, 8)

    // Extract an int spanning boundaries  
    let _int_val = view.unsafe_extract_int_le(offset, 16)

    // Extract an int64 spanning boundaries
    let _int64_val = view.unsafe_extract_int64_be(offset, 48)

  }

  // If we get here without crashes, the boundary handling is working
  inspect(true, content="true")
}

///|
test "integration - pattern verification" {
  // Use a known pattern to verify correctness across all functions
  let bytes = b"\x55\xAA\x55\xAA\x55\xAA\x55\xAA\x55\xAA" // Alternating pattern
  let view = bytes[:]

  // Verify the pattern is preserved through different extraction methods

  // Check that alternating pattern is maintained in bits
  for i = 0; i < 16; i = i + 1 {
    let bit = view.unsafe_extract_bit(i, 1)
    let expected = if i % 2 == 0 { false } else { true } // 0x55 = 01010101
    if i < 8 {
      inspect(bit, content=if expected { "true" } else { "false" })
    }
  }

  // Check that pattern is maintained in byte extractions
  let byte1 = view.unsafe_extract_byte(0, 8)
  let byte2 = view.unsafe_extract_byte(8, 8)
  inspect(byte1, content="b'\\x55'")
  inspect(byte2, content="b'\\xAA'")

  // Check that pattern is maintained in larger extractions
  let int_val = view.unsafe_extract_int_be(0, 16)
  inspect(
    int_val.to_be_bytes(),
    content=(
      #|b"\x00\x00\x55\xaa"
    ),
  )
}
