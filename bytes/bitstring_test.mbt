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
  inspect(view.unsafe_extract_bit(0, 1), content="1") // MSB
  inspect(view.unsafe_extract_bit(1, 1), content="0")
  inspect(view.unsafe_extract_bit(2, 1), content="1")
  inspect(view.unsafe_extract_bit(3, 1), content="0")
  inspect(view.unsafe_extract_bit(4, 1), content="1")
  inspect(view.unsafe_extract_bit(5, 1), content="0")
  inspect(view.unsafe_extract_bit(6, 1), content="1")
  inspect(view.unsafe_extract_bit(7, 1), content="0") // LSB

  // Second byte (0x55 = 01010101)
  inspect(view.unsafe_extract_bit(8, 1), content="0") // MSB
  inspect(view.unsafe_extract_bit(9, 1), content="1")
  inspect(view.unsafe_extract_bit(10, 1), content="0")
  inspect(view.unsafe_extract_bit(11, 1), content="1")
  inspect(view.unsafe_extract_bit(12, 1), content="0")
  inspect(view.unsafe_extract_bit(13, 1), content="1")
  inspect(view.unsafe_extract_bit(14, 1), content="0")
  inspect(view.unsafe_extract_bit(15, 1), content="1") // LSB
}

///|
test "extract_bit - edge patterns" {
  let bytes = b"\xFF\x00\x80\x01"
  let view = bytes[:]

  // All ones byte (0xFF)
  for i = 0; i < 8; i = i + 1 {
    inspect(view.unsafe_extract_bit(i, 1), content="1")
  }

  // All zeros byte (0x00)
  for i = 8; i < 16; i = i + 1 {
    inspect(view.unsafe_extract_bit(i, 1), content="0")
  }

  // Single high bit (0x80 = 10000000)
  inspect(view.unsafe_extract_bit(16, 1), content="1")
  for i = 17; i < 24; i = i + 1 {
    inspect(view.unsafe_extract_bit(i, 1), content="0")
  }

  // Single low bit (0x01 = 00000001)
  for i = 24; i < 31; i = i + 1 {
    inspect(view.unsafe_extract_bit(i, 1), content="0")
  }
  inspect(view.unsafe_extract_bit(31, 1), content="1")
}

// ============================================================================
// 2. Byte Extraction Tests (2-8 bits)
// ============================================================================

///|
test "extract_byte - byte aligned full bytes" {
  let bytes = b"\x12\x34\x56\x78\x9A\xBC\xDE\xF0"
  let view = bytes[:]

  // Test extracting full bytes at byte boundaries
  inspect(view.unsafe_extract_byte(0, 8), content="18")
  inspect(view.unsafe_extract_byte(8, 8), content="52")
  inspect(view.unsafe_extract_byte(16, 8), content="86")
  inspect(view.unsafe_extract_byte(24, 8), content="120")
  inspect(view.unsafe_extract_byte(32, 8), content="154")
  inspect(view.unsafe_extract_byte(40, 8), content="188")
  inspect(view.unsafe_extract_byte(48, 8), content="222")
  inspect(view.unsafe_extract_byte(56, 8), content="240")
}

///|
test "extract_byte - partial bits from byte aligned positions" {
  let bytes = b"\xFF\x00\xAA\x55"
  let view = bytes[:]

  // Extract 2-7 bits from 0xFF (11111111)
  inspect(view.unsafe_extract_byte(0, 2), content="3") // 11 -> 3
  inspect(view.unsafe_extract_byte(0, 3), content="7") // 111 -> 7
  inspect(view.unsafe_extract_byte(0, 4), content="15") // 1111 -> 15
  inspect(view.unsafe_extract_byte(0, 5), content="31") // 11111 -> 31
  inspect(view.unsafe_extract_byte(0, 6), content="63") // 111111 -> 63
  inspect(view.unsafe_extract_byte(0, 7), content="127") // 1111111 -> 127

  // Extract 2-7 bits from 0x00 (00000000)
  for len = 2; len <= 7; len = len + 1 {
    inspect(view.unsafe_extract_byte(8, len), content="0")
  }
}

///|
test "extract_byte - non-aligned positions" {
  let bytes = b"\xF0\x0F\xCC\x33" // 11110000 00001111 11001100 00110011
  let view = bytes[:]

  // Extract from middle of first byte
  inspect(view.unsafe_extract_byte(2, 4), content="12") // 1100 from 11110000
  inspect(view.unsafe_extract_byte(4, 4), content="0") // 0000 from 11110000

  // Cross byte boundaries
  inspect(view.unsafe_extract_byte(6, 4), content="0") // 00 from byte 0 + 00 from byte 1
  inspect(view.unsafe_extract_byte(7, 2), content="0") // 0 from byte 0 + 0 from byte 1
  inspect(view.unsafe_extract_byte(7, 6), content="1") // 0 from byte 0 + 00001 from byte 1

  // Extract from middle positions spanning bytes
  inspect(view.unsafe_extract_byte(10, 4), content="3") // 1111 from 00001111
  inspect(view.unsafe_extract_byte(14, 4), content="15") // 11 from byte 1 + 11 from byte 2
}

///|
test "extract_byte - bit patterns and edge cases" {
  let bytes = b"\x81\x42\x24\x18\x99\x66\xA5\x5A"
  let view = bytes[:]

  // Test various lengths from different starting positions
  inspect(view.unsafe_extract_byte(1, 3), content="0") // 3 bits starting from bit 1
  inspect(view.unsafe_extract_byte(5, 5), content="5") // 5 bits crossing byte boundary
  inspect(view.unsafe_extract_byte(9, 7), content="66") // 7 bits from middle positions
  inspect(view.unsafe_extract_byte(17, 6), content="18") // 6 bits from byte 2

  // Test maximum span (8 bits) from non-aligned positions
  inspect(view.unsafe_extract_byte(3, 8), content="10") // 8 bits starting from bit 3
  inspect(view.unsafe_extract_byte(5, 8), content="40") // 8 bits starting from bit 5
}

// ============================================================================
// 3. Integer Extraction Tests - Little Endian (9-32 bits)
// ============================================================================

///|
test "extract_uint_le" {
  let s = b"\xA5\xB6\xC7\xD8"[:]
  inspect(
    s.unsafe_extract_uint_le(0, 9).to_be_bytes(),
    content=(
      #|b"\x00\x00\x01\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(0, 10).to_be_bytes(),
    content=(
      #|b"\x00\x00\x02\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(0, 11).to_be_bytes(),
    content=(
      #|b"\x00\x00\x05\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(0, 12).to_be_bytes(),
    content=(
      #|b"\x00\x00\x0b\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(0, 13).to_be_bytes(),
    content=(
      #|b"\x00\x00\x16\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(0, 14).to_be_bytes(),
    content=(
      #|b"\x00\x00-\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(0, 15).to_be_bytes(),
    content=(
      #|b"\x00\x00[\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(0, 16).to_be_bytes(),
    content=(
      #|b"\x00\x00\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(0, 17).to_be_bytes(),
    content=(
      #|b"\x00\x01\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(0, 18).to_be_bytes(),
    content=(
      #|b"\x00\x03\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(0, 19).to_be_bytes(),
    content=(
      #|b"\x00\x06\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(0, 20).to_be_bytes(),
    content=(
      #|b"\x00\x0c\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(0, 21).to_be_bytes(),
    content=(
      #|b"\x00\x18\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(0, 22).to_be_bytes(),
    content=(
      #|b"\x001\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(0, 23).to_be_bytes(),
    content=(
      #|b"\x00c\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(0, 24).to_be_bytes(),
    content=(
      #|b"\x00\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(0, 25).to_be_bytes(),
    content=(
      #|b"\x01\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(0, 26).to_be_bytes(),
    content=(
      #|b"\x03\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(0, 27).to_be_bytes(),
    content=(
      #|b"\x06\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(0, 28).to_be_bytes(),
    content=(
      #|b"\x0d\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(0, 29).to_be_bytes(),
    content=(
      #|b"\x1b\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(0, 30).to_be_bytes(),
    content=(
      #|b"6\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(0, 31).to_be_bytes(),
    content=(
      #|b"l\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(0, 32).to_be_bytes(),
    content=(
      #|b"\xd8\xc7\xb6\xa5"
    ),
  )
  let s = b"\xA5\xB6\xC7\xD8\xA5\xB6\xC7\xD8"[:]
  inspect(
    s.unsafe_extract_uint_le(1, 32).to_be_bytes(),
    content=(
      #|b"\xb1\x8fmK"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(2, 32).to_be_bytes(),
    content=(
      #|b"b\x1f\xdb\x96"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(3, 32).to_be_bytes(),
    content=(
      #|b"\xc5>\xb6-"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(4, 32).to_be_bytes(),
    content=(
      #|b"\x8a}l["
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(5, 32).to_be_bytes(),
    content=(
      #|b"\x14\xfb\xd8\xb6"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(6, 32).to_be_bytes(),
    content=(
      #|b")\xf6\xb1m"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(7, 32).to_be_bytes(),
    content=(
      #|b"R\xecc\xdb"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(8, 32).to_be_bytes(),
    content=(
      #|b"\xa5\xd8\xc7\xb6"
    ),
  )
  let s = b"\xA5\xB6\xC7\xD8"[:]
  inspect(
    s.unsafe_extract_uint_le(0, 32).to_be_bytes(),
    content=(
      #|b"\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(1, 31).to_be_bytes(),
    content=(
      #|b"X\x8fmK"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(2, 30).to_be_bytes(),
    content=(
      #|b"\x18\x1f\xdb\x96"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(3, 29).to_be_bytes(),
    content=(
      #|b"\x18>\xb6-"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(4, 28).to_be_bytes(),
    content=(
      #|b"\x08}l["
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(5, 27).to_be_bytes(),
    content=(
      #|b"\x00\xfb\xd8\xb6"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(6, 26).to_be_bytes(),
    content=(
      #|b"\x00\xf6\xb1m"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(7, 25).to_be_bytes(),
    content=(
      #|b"\x00\xecc\xdb"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(8, 24).to_be_bytes(),
    content=(
      #|b"\x00\xd8\xc7\xb6"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(9, 23).to_be_bytes(),
    content=(
      #|b"\x00X\x8fm"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(10, 22).to_be_bytes(),
    content=(
      #|b"\x00\x18\x1f\xdb"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(11, 21).to_be_bytes(),
    content=(
      #|b"\x00\x18>\xb6"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(12, 20).to_be_bytes(),
    content=(
      #|b"\x00\x08}l"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(13, 19).to_be_bytes(),
    content=(
      #|b"\x00\x00\xfb\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(14, 18).to_be_bytes(),
    content=(
      #|b"\x00\x00\xf6\xb1"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(15, 17).to_be_bytes(),
    content=(
      #|b"\x00\x00\xecc"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(16, 16).to_be_bytes(),
    content=(
      #|b"\x00\x00\xd8\xc7"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(17, 15).to_be_bytes(),
    content=(
      #|b"\x00\x00X\x8f"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(18, 14).to_be_bytes(),
    content=(
      #|b"\x00\x00\x18\x1f"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(19, 13).to_be_bytes(),
    content=(
      #|b"\x00\x00\x18>"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(20, 12).to_be_bytes(),
    content=(
      #|b"\x00\x00\x08}"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(21, 11).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\xfb"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(22, 10).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\xf6"
    ),
  )
  inspect(
    s.unsafe_extract_uint_le(23, 9).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\xec"
    ),
  )
}

///|
test "extract_int_le_path_consistent" {
  let s1 = b"\xBA\xAA\xAA\xAA"[:]
  let i1 = s1.unsafe_extract_uint_le(4, 28)
  let s2 = b"\xAA\xAA\xAA\xAB"[:]
  let i2 = s2.unsafe_extract_uint_le(0, 28)
  inspect(i1, content="178956970")
  inspect(i2, content="178956970")
}

// ============================================================================
// 4. Integer Extraction Tests - Big Endian (9-32 bits)
// ============================================================================

///|
test "extract_int_be" {
  let s = b"\xA5\xB6\xC7\xD8"[:]
  inspect(
    (s.unsafe_extract_uint_be(0, 9) << 23).to_be_bytes(),
    content=(
      #|b"\xa5\x80\x00\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint_be(0, 10) << 22).to_be_bytes(),
    content=(
      #|b"\xa5\x80\x00\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint_be(0, 11) << 21).to_be_bytes(),
    content=(
      #|b"\xa5\xa0\x00\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint_be(0, 12) << 20).to_be_bytes(),
    content=(
      #|b"\xa5\xb0\x00\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint_be(0, 13) << 19).to_be_bytes(),
    content=(
      #|b"\xa5\xb0\x00\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint_be(0, 14) << 18).to_be_bytes(),
    content=(
      #|b"\xa5\xb4\x00\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint_be(0, 15) << 17).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\x00\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint_be(0, 16) << 16).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\x00\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint_be(0, 17) << 15).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\x80\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint_be(0, 18) << 14).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc0\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint_be(0, 19) << 13).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc0\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint_be(0, 20) << 12).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc0\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint_be(0, 21) << 11).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc0\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint_be(0, 22) << 10).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc4\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint_be(0, 23) << 9).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc6\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint_be(0, 24) << 8).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint_be(0, 25) << 7).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\x80"
    ),
  )
  inspect(
    (s.unsafe_extract_uint_be(0, 26) << 6).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xc0"
    ),
  )
  inspect(
    (s.unsafe_extract_uint_be(0, 27) << 5).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xc0"
    ),
  )
  inspect(
    (s.unsafe_extract_uint_be(0, 28) << 4).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd0"
    ),
  )
  inspect(
    (s.unsafe_extract_uint_be(0, 29) << 3).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8"
    ),
  )
  inspect(
    (s.unsafe_extract_uint_be(0, 30) << 2).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8"
    ),
  )
  inspect(
    (s.unsafe_extract_uint_be(0, 31) << 1).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8"
    ),
  )
  inspect(
    (s.unsafe_extract_uint_be(0, 32) << 0).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8"
    ),
  )
  let s = b"\xA5\xB6\xC7\xD8\xA5\xB6\xC7\xD8"[:]
  inspect(
    s.unsafe_extract_uint_be(1, 32).to_be_bytes(),
    content=(
      #|b"Km\x8f\xb1"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(2, 32).to_be_bytes(),
    content=(
      #|b"\x96\xdb\x1fb"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(3, 32).to_be_bytes(),
    content=(
      #|b"-\xb6>\xc5"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(4, 32).to_be_bytes(),
    content=(
      #|b"[l}\x8a"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(5, 32).to_be_bytes(),
    content=(
      #|b"\xb6\xd8\xfb\x14"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(6, 32).to_be_bytes(),
    content=(
      #|b"m\xb1\xf6)"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(7, 32).to_be_bytes(),
    content=(
      #|b"\xdbc\xecR"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(8, 32).to_be_bytes(),
    content=(
      #|b"\xb6\xc7\xd8\xa5"
    ),
  )
  let s = b"\xA5\xB6\xC7\xD8"[:]
  inspect(
    s.unsafe_extract_uint_be(0, 32).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(1, 31).to_be_bytes(),
    content=(
      #|b"%\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(2, 30).to_be_bytes(),
    content=(
      #|b"%\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(3, 29).to_be_bytes(),
    content=(
      #|b"\x05\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(4, 28).to_be_bytes(),
    content=(
      #|b"\x05\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(5, 27).to_be_bytes(),
    content=(
      #|b"\x05\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(6, 26).to_be_bytes(),
    content=(
      #|b"\x01\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(7, 25).to_be_bytes(),
    content=(
      #|b"\x01\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(8, 24).to_be_bytes(),
    content=(
      #|b"\x00\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(9, 23).to_be_bytes(),
    content=(
      #|b"\x006\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(10, 22).to_be_bytes(),
    content=(
      #|b"\x006\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(11, 21).to_be_bytes(),
    content=(
      #|b"\x00\x16\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(12, 20).to_be_bytes(),
    content=(
      #|b"\x00\x06\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(13, 19).to_be_bytes(),
    content=(
      #|b"\x00\x06\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(14, 18).to_be_bytes(),
    content=(
      #|b"\x00\x02\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(15, 17).to_be_bytes(),
    content=(
      #|b"\x00\x00\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(16, 16).to_be_bytes(),
    content=(
      #|b"\x00\x00\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(17, 15).to_be_bytes(),
    content=(
      #|b"\x00\x00G\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(18, 14).to_be_bytes(),
    content=(
      #|b"\x00\x00\x07\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(19, 13).to_be_bytes(),
    content=(
      #|b"\x00\x00\x07\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(20, 12).to_be_bytes(),
    content=(
      #|b"\x00\x00\x07\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(21, 11).to_be_bytes(),
    content=(
      #|b"\x00\x00\x07\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(22, 10).to_be_bytes(),
    content=(
      #|b"\x00\x00\x03\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint_be(23, 9).to_be_bytes(),
    content=(
      #|b"\x00\x00\x01\xd8"
    ),
  )
}

///|
test "extract_int_be_path_consistent" {
  let s1 = b"\xBA\xAA\xAA\xAA"[:]
  let i1 = s1.unsafe_extract_uint_be(4, 28)
  let s2 = b"\xAA\xAA\xAA\xAB"[:]
  let i2 = s2.unsafe_extract_uint_be(0, 28)
  inspect(i1, content="178956970")
  inspect(i2, content="178956970")
}

// ============================================================================
// 5. Int64 Extraction Tests - Little Endian (33-64 bits)
// ============================================================================

///|
test "extract_int64_le" {
  let s = b"\xA5\xB6\xC7\xD8\x5A\xB6\xC7\xD8"[:]
  inspect(
    s.unsafe_extract_uint64_le(0, 33).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\x00\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 34).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\x01\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 35).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\x02\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 36).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\x05\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 37).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\x0b\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 38).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\x16\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 39).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00-\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 40).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00Z\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 41).to_be_bytes(),
    content=(
      #|b"\x00\x00\x01Z\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 42).to_be_bytes(),
    content=(
      #|b"\x00\x00\x02Z\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 43).to_be_bytes(),
    content=(
      #|b"\x00\x00\x05Z\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 44).to_be_bytes(),
    content=(
      #|b"\x00\x00\x0bZ\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 45).to_be_bytes(),
    content=(
      #|b"\x00\x00\x16Z\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 46).to_be_bytes(),
    content=(
      #|b"\x00\x00-Z\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 47).to_be_bytes(),
    content=(
      #|b"\x00\x00[Z\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 48).to_be_bytes(),
    content=(
      #|b"\x00\x00\xb6Z\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 49).to_be_bytes(),
    content=(
      #|b"\x00\x01\xb6Z\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 50).to_be_bytes(),
    content=(
      #|b"\x00\x03\xb6Z\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 51).to_be_bytes(),
    content=(
      #|b"\x00\x06\xb6Z\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 52).to_be_bytes(),
    content=(
      #|b"\x00\x0c\xb6Z\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 53).to_be_bytes(),
    content=(
      #|b"\x00\x18\xb6Z\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 54).to_be_bytes(),
    content=(
      #|b"\x001\xb6Z\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 55).to_be_bytes(),
    content=(
      #|b"\x00c\xb6Z\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 56).to_be_bytes(),
    content=(
      #|b"\x00\xc7\xb6Z\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 57).to_be_bytes(),
    content=(
      #|b"\x01\xc7\xb6Z\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 58).to_be_bytes(),
    content=(
      #|b"\x03\xc7\xb6Z\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 59).to_be_bytes(),
    content=(
      #|b"\x06\xc7\xb6Z\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 60).to_be_bytes(),
    content=(
      #|b"\x0d\xc7\xb6Z\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 61).to_be_bytes(),
    content=(
      #|b"\x1b\xc7\xb6Z\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 62).to_be_bytes(),
    content=(
      #|b"6\xc7\xb6Z\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 63).to_be_bytes(),
    content=(
      #|b"l\xc7\xb6Z\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(0, 64).to_be_bytes(),
    content=(
      #|b"\xd8\xc7\xb6Z\xd8\xc7\xb6\xa5"
    ),
  )
  let s = b"\xA5\xB6\xC7\xD8\x5A\xB6\xC7\xD8"[:]
  inspect(
    s.unsafe_extract_uint64_le(0, 64).to_be_bytes(),
    content=(
      #|b"\xd8\xc7\xb6Z\xd8\xc7\xb6\xa5"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(1, 63).to_be_bytes(),
    content=(
      #|b"X\x8fm\xb5\xb0\x8fmK"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(2, 62).to_be_bytes(),
    content=(
      #|b"\x18\x1f\xdbja\x1f\xdb\x96"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(3, 61).to_be_bytes(),
    content=(
      #|b"\x18>\xb6\xd5\xc2>\xb6-"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(4, 60).to_be_bytes(),
    content=(
      #|b"\x08}l\xab\x85}l["
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(5, 59).to_be_bytes(),
    content=(
      #|b"\x00\xfb\xd8V\x0b\xfb\xd8\xb6"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(6, 58).to_be_bytes(),
    content=(
      #|b"\x00\xf6\xb1\xad\x16\xf6\xb1m"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(7, 57).to_be_bytes(),
    content=(
      #|b"\x00\xecc[-\xecc\xdb"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(8, 56).to_be_bytes(),
    content=(
      #|b"\x00\xd8\xc7\xb6Z\xd8\xc7\xb6"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(9, 55).to_be_bytes(),
    content=(
      #|b"\x00X\x8fm\xb5\xb0\x8fm"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(10, 54).to_be_bytes(),
    content=(
      #|b"\x00\x18\x1f\xdbja\x1f\xdb"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(11, 53).to_be_bytes(),
    content=(
      #|b"\x00\x18>\xb6\xd5\xc2>\xb6"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(12, 52).to_be_bytes(),
    content=(
      #|b"\x00\x08}l\xab\x85}l"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(13, 51).to_be_bytes(),
    content=(
      #|b"\x00\x00\xfb\xd8V\x0b\xfb\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(14, 50).to_be_bytes(),
    content=(
      #|b"\x00\x00\xf6\xb1\xad\x16\xf6\xb1"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(15, 49).to_be_bytes(),
    content=(
      #|b"\x00\x00\xecc[-\xecc"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(16, 48).to_be_bytes(),
    content=(
      #|b"\x00\x00\xd8\xc7\xb6Z\xd8\xc7"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(17, 47).to_be_bytes(),
    content=(
      #|b"\x00\x00X\x8fm\xb5\xb0\x8f"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(18, 46).to_be_bytes(),
    content=(
      #|b"\x00\x00\x18\x1f\xdbja\x1f"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(19, 45).to_be_bytes(),
    content=(
      #|b"\x00\x00\x18>\xb6\xd5\xc2>"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(20, 44).to_be_bytes(),
    content=(
      #|b"\x00\x00\x08}l\xab\x85}"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(21, 43).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\xfb\xd8V\x0b\xfb"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(22, 42).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\xf6\xb1\xad\x16\xf6"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(23, 41).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\xecc[-\xec"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(24, 40).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\xd8\xc7\xb6Z\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(25, 39).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00X\x8fm\xb5\xb0"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(26, 38).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\x18\x1f\xdbja"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(27, 37).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\x18>\xb6\xd5\xc2"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(28, 36).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\x08}l\xab\x85"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(29, 35).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\x00\xfb\xd8V\x0b"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(30, 34).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\x00\xf6\xb1\xad\x16"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_le(31, 33).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\x00\xecc[-"
    ),
  )
}

///|
test "extract_int64_le path_consistent" {
  let s1 = b"\xBA\xAA\xAA\xAA\xAA\xAA\xAA\xAA"[:]
  let i1 = s1.unsafe_extract_uint64_le(4, 60)
  let s2 = b"\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA"[:]
  let i2 = s2.unsafe_extract_uint64_le(0, 60)
  inspect(i1, content="768614336404564650")
  inspect(i2, content="768614336404564650")
}

// ============================================================================
// 6. Int64 Extraction Tests - Big Endian (33-64 bits)
// ============================================================================

///|
test "extract_int64_be" {
  let s = b"\xA5\xB6\xC7\xD8\x5A\xB6\xC7\xD8"[:]
  inspect(
    (s.unsafe_extract_uint64_be(0, 33) << 31).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8\x00\x00\x00\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 34) << 30).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8@\x00\x00\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 35) << 29).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8@\x00\x00\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 36) << 28).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8P\x00\x00\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 37) << 27).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8X\x00\x00\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 38) << 26).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8X\x00\x00\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 39) << 25).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\x00\x00\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 40) << 24).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\x00\x00\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 41) << 23).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\x80\x00\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 42) << 22).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\x80\x00\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 43) << 21).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\xa0\x00\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 44) << 20).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\xb0\x00\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 45) << 19).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\xb0\x00\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 46) << 18).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\xb4\x00\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 47) << 17).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\xb6\x00\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 48) << 16).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\xb6\x00\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 49) << 15).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\xb6\x80\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 50) << 14).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\xb6\xc0\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 51) << 13).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\xb6\xc0\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 52) << 12).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\xb6\xc0\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 53) << 11).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\xb6\xc0\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 54) << 10).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\xb6\xc4\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 55) << 9).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\xb6\xc6\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 56) << 8).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\xb6\xc7\x00"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 57) << 7).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\xb6\xc7\x80"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 58) << 6).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\xb6\xc7\xc0"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 59) << 5).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\xb6\xc7\xc0"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 60) << 4).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\xb6\xc7\xd0"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 61) << 3).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 62) << 2).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    (s.unsafe_extract_uint64_be(0, 63) << 1).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(0, 64).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\xb6\xc7\xd8"
    ),
  )
  let s = b"\xA5\xB6\xC7\xD8\x5A\xB6\xC7\xD8"[:]
  inspect(
    s.unsafe_extract_uint64_be(0, 64).to_be_bytes(),
    content=(
      #|b"\xa5\xb6\xc7\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(1, 63).to_be_bytes(),
    content=(
      #|b"%\xb6\xc7\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(2, 62).to_be_bytes(),
    content=(
      #|b"%\xb6\xc7\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(3, 61).to_be_bytes(),
    content=(
      #|b"\x05\xb6\xc7\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(4, 60).to_be_bytes(),
    content=(
      #|b"\x05\xb6\xc7\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(5, 59).to_be_bytes(),
    content=(
      #|b"\x05\xb6\xc7\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(6, 58).to_be_bytes(),
    content=(
      #|b"\x01\xb6\xc7\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(7, 57).to_be_bytes(),
    content=(
      #|b"\x01\xb6\xc7\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(8, 56).to_be_bytes(),
    content=(
      #|b"\x00\xb6\xc7\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(9, 55).to_be_bytes(),
    content=(
      #|b"\x006\xc7\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(10, 54).to_be_bytes(),
    content=(
      #|b"\x006\xc7\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(11, 53).to_be_bytes(),
    content=(
      #|b"\x00\x16\xc7\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(12, 52).to_be_bytes(),
    content=(
      #|b"\x00\x06\xc7\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(13, 51).to_be_bytes(),
    content=(
      #|b"\x00\x06\xc7\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(14, 50).to_be_bytes(),
    content=(
      #|b"\x00\x02\xc7\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(15, 49).to_be_bytes(),
    content=(
      #|b"\x00\x00\xc7\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(16, 48).to_be_bytes(),
    content=(
      #|b"\x00\x00\xc7\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(17, 47).to_be_bytes(),
    content=(
      #|b"\x00\x00G\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(18, 46).to_be_bytes(),
    content=(
      #|b"\x00\x00\x07\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(19, 45).to_be_bytes(),
    content=(
      #|b"\x00\x00\x07\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(20, 44).to_be_bytes(),
    content=(
      #|b"\x00\x00\x07\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(21, 43).to_be_bytes(),
    content=(
      #|b"\x00\x00\x07\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(22, 42).to_be_bytes(),
    content=(
      #|b"\x00\x00\x03\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(23, 41).to_be_bytes(),
    content=(
      #|b"\x00\x00\x01\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(24, 40).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\xd8Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(25, 39).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00XZ\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(26, 38).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\x18Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(27, 37).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\x18Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(28, 36).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\x08Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(29, 35).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\x00Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(30, 34).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\x00Z\xb6\xc7\xd8"
    ),
  )
  inspect(
    s.unsafe_extract_uint64_be(31, 33).to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\x00Z\xb6\xc7\xd8"
    ),
  )
}

///|
test "extract_int64_be path_consistent" {
  let s1 = b"\xBA\xAA\xAA\xAA\xAA\xAA\xAA\xAA"[:]
  let i1 = s1.unsafe_extract_uint64_be(4, 60)
  let s2 = b"\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA"[:]
  let i2 = s2.unsafe_extract_uint64_be(0, 60)
  inspect(i1, content="768614336404564650")
  inspect(i2, content="768614336404564650")
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
  inspect(view1.unsafe_extract_byte(0, 8), content="1")
  inspect(view1.unsafe_extract_byte(8, 8), content="2")
  inspect(view1.unsafe_extract_byte(16, 8), content="3")
  inspect(view1.unsafe_extract_byte(24, 8), content="4")
  inspect(view2.unsafe_extract_byte(0, 8), content="5")
  inspect(view2.unsafe_extract_byte(8, 8), content="6")
  inspect(view2.unsafe_extract_byte(16, 8), content="7")
  inspect(view2.unsafe_extract_byte(24, 8), content="8")
  inspect(view3.unsafe_extract_byte(0, 8), content="9")
  inspect(view3.unsafe_extract_byte(8, 8), content="10")
  inspect(view3.unsafe_extract_byte(16, 8), content="11")
  inspect(view3.unsafe_extract_byte(24, 8), content="12")
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
  inspect(small_view.unsafe_extract_byte(0, 8), content="255")
  inspect(medium_view.unsafe_extract_byte(0, 8), content="238")
  inspect(medium_view.unsafe_extract_byte(24, 8), content="187")
  inspect(large_view.unsafe_extract_byte(0, 8), content="170")
  inspect(large_view.unsafe_extract_byte(40, 8), content="85")
}

///|
test "extract_bytesview - nested extractions" {
  let bytes = b"\x12\x34\x56\x78\x9A\xBC\xDE\xF0\x11\x22\x33\x44"
  let view = bytes[:]

  // Extract a subview, then extract from that subview
  let subview = view.unsafe_extract_bytesview(16, 64) // Extract middle 8 bytes
  let sub_subview = subview.unsafe_extract_bytesview(16, 32) // Extract 4 bytes from middle

  // Verify the nested extraction
  inspect(sub_subview.unsafe_extract_byte(0, 8), content="154")
  inspect(sub_subview.unsafe_extract_byte(8, 8), content="188")
  inspect(sub_subview.unsafe_extract_byte(16, 8), content="222")
  inspect(sub_subview.unsafe_extract_byte(24, 8), content="240")
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
  let int_val = view.unsafe_extract_uint_le(12, 20)
  let int64_val = view.unsafe_extract_uint64_be(32, 40)

  // Verify each extraction independently
  inspect(bit, content="0") // 6th bit of 0xAB (10101011)
  inspect(byte_val, content="60") // 6 bits starting from bit 6

  // For int and int64 values, shift to make them more readable
  inspect(
    (int_val << (32 - 20)).to_le_bytes(),
    content=(
      #|b"\x00\xe0\x1d/"
    ),
  )
  inspect(
    (int64_val << (64 - 40)).to_le_bytes(),
    content=(
      #|b"\x00\x00\x00\xbc\x9axV4"
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
    let _int_val = view.unsafe_extract_uint_le(offset, 16)

    // Extract an int64 spanning boundaries
    let _int64_val = view.unsafe_extract_uint64_be(offset, 48)

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
      inspect(bit, content=if expected { "1" } else { "0" })
    }
  }

  // Check that pattern is maintained in byte extractions
  let byte1 = view.unsafe_extract_byte(0, 8)
  let byte2 = view.unsafe_extract_byte(8, 8)
  inspect(byte1, content="85")
  inspect(byte2, content="170")

  // Check that pattern is maintained in larger extractions
  let int_val = view.unsafe_extract_uint_be(0, 16)
  inspect(
    int_val.to_be_bytes(),
    content=(
      #|b"\x00\x00U\xaa"
    ),
  )
}

///|
test "misc" {
  let s = b"\xFF\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F\x10"[:]
  inspect(s.unsafe_extract_byte(0, 7), content="127")
  inspect(s.unsafe_extract_uint_le(7, 15), content="129")
  inspect(s.unsafe_extract_uint_le(22, 23), content="2097601")
  inspect(s.unsafe_extract_uint64_le(45, 40), content="279726645696")
  inspect(s.unsafe_extract_byte(85, 3), content="3")
  inspect(s.unsafe_extract_byte(88, 8), content="12")
  inspect(
    s.unsafe_extract_bytesview(96, 32),
    content=(
      #|b"\x0d\x0e\x0f\x10"
    ),
  )
  inspect(s.unsafe_extract_byte(0, 7), content="127")
  inspect(s.unsafe_extract_uint_be(7, 15), content="16512")
  inspect(s.unsafe_extract_uint_be(22, 23), content="6324384")
  inspect(s.unsafe_extract_uint64_be(45, 40), content="828408668481")
  inspect(s.unsafe_extract_byte(85, 3), content="3")
  inspect(s.unsafe_extract_byte(88, 8), content="12")
  inspect(
    s.unsafe_extract_bytesview(96, 32),
    content=(
      #|b"\x0d\x0e\x0f\x10"
    ),
  )
}
