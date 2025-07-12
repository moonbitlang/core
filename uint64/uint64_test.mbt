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

test "uint64_to_be_bytes_comprehensive" {
  // Test zero
  assert_eq(0UL.to_be_bytes(), b"\x00\x00\x00\x00\x00\x00\x00\x00")
  
  // Test maximum value
  assert_eq(18446744073709551615UL.to_be_bytes(), b"\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF")
  
  // Test minimum non-zero value
  assert_eq(1UL.to_be_bytes(), b"\x00\x00\x00\x00\x00\x00\x00\x01")
  
  // Test powers of 2
  assert_eq(256UL.to_be_bytes(), b"\x00\x00\x00\x00\x00\x00\x01\x00")
  assert_eq(65536UL.to_be_bytes(), b"\x00\x00\x00\x00\x00\x01\x00\x00")
  assert_eq(16777216UL.to_be_bytes(), b"\x00\x00\x00\x00\x01\x00\x00\x00")
  assert_eq(4294967296UL.to_be_bytes(), b"\x00\x00\x00\x01\x00\x00\x00\x00")
  assert_eq(1099511627776UL.to_be_bytes(), b"\x00\x00\x01\x00\x00\x00\x00\x00")
  assert_eq(281474976710656UL.to_be_bytes(), b"\x00\x01\x00\x00\x00\x00\x00\x00")
  assert_eq(72057594037927936UL.to_be_bytes(), b"\x01\x00\x00\x00\x00\x00\x00\x00")
  
  // Test specific values
  assert_eq(0x123456789ABCDEF0UL.to_be_bytes(), b"\x12\x34\x56\x78\x9A\xBC\xDE\xF0")
  assert_eq(0xFEDCBA0987654321UL.to_be_bytes(), b"\xFE\xDC\xBA\x09\x87\x65\x43\x21")
  
  // Test edge cases
  assert_eq(0x8000000000000000UL.to_be_bytes(), b"\x80\x00\x00\x00\x00\x00\x00\x00")
  assert_eq(0x7FFFFFFFFFFFFFFFUL.to_be_bytes(), b"\x7F\xFF\xFF\xFF\xFF\xFF\xFF\xFF")
  
  // Test all bytes the same
  assert_eq(0x1111111111111111UL.to_be_bytes(), b"\x11\x11\x11\x11\x11\x11\x11\x11")
  assert_eq(0xAAAAAAAAAAAAAAAAUL.to_be_bytes(), b"\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA")
}

test "uint64_to_le_bytes_comprehensive" {
  // Test zero
  assert_eq(0UL.to_le_bytes(), b"\x00\x00\x00\x00\x00\x00\x00\x00")
  
  // Test maximum value
  assert_eq(18446744073709551615UL.to_le_bytes(), b"\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF")
  
  // Test minimum non-zero value
  assert_eq(1UL.to_le_bytes(), b"\x01\x00\x00\x00\x00\x00\x00\x00")
  
  // Test powers of 2 (note: reversed from big-endian)
  assert_eq(256UL.to_le_bytes(), b"\x00\x01\x00\x00\x00\x00\x00\x00")
  assert_eq(65536UL.to_le_bytes(), b"\x00\x00\x01\x00\x00\x00\x00\x00")
  assert_eq(16777216UL.to_le_bytes(), b"\x00\x00\x00\x01\x00\x00\x00\x00")
  assert_eq(4294967296UL.to_le_bytes(), b"\x00\x00\x00\x00\x01\x00\x00\x00")
  assert_eq(1099511627776UL.to_le_bytes(), b"\x00\x00\x00\x00\x00\x01\x00\x00")
  assert_eq(281474976710656UL.to_le_bytes(), b"\x00\x00\x00\x00\x00\x00\x01\x00")
  assert_eq(72057594037927936UL.to_le_bytes(), b"\x00\x00\x00\x00\x00\x00\x00\x01")
  
  // Test specific values (note: reversed from big-endian)
  assert_eq(0x123456789ABCDEF0UL.to_le_bytes(), b"\xF0\xDE\xBC\x9A\x78\x56\x34\x12")
  assert_eq(0xFEDCBA0987654321UL.to_le_bytes(), b"\x21\x43\x65\x87\x09\xBA\xDC\xFE")
  
  // Test edge cases
  assert_eq(0x8000000000000000UL.to_le_bytes(), b"\x00\x00\x00\x00\x00\x00\x00\x80")
  assert_eq(0x7FFFFFFFFFFFFFFFUL.to_le_bytes(), b"\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x7F")
  
  // Test all bytes the same
  assert_eq(0x1111111111111111UL.to_le_bytes(), b"\x11\x11\x11\x11\x11\x11\x11\x11")
  assert_eq(0xAAAAAAAAAAAAAAAAUL.to_le_bytes(), b"\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA")
}

test "uint64_byte_conversion_verification" {
  // Test that big-endian and little-endian are consistent
  let values = [
    0UL, 1UL, 255UL, 256UL, 65535UL, 65536UL, 16777215UL, 16777216UL,
    4294967295UL, 4294967296UL, 1099511627775UL, 1099511627776UL,
    281474976710655UL, 281474976710656UL, 72057594037927935UL, 72057594037927936UL,
    0x123456789ABCDEF0UL, 0xFEDCBA0987654321UL, 0x8000000000000000UL, 0x7FFFFFFFFFFFFFFFUL,
    18446744073709551615UL
  ]
  
  for value in values {
    let be_bytes = value.to_be_bytes()
    let le_bytes = value.to_le_bytes()
    
    // Big-endian bytes should have most significant byte first
    assert_eq(be_bytes[0], ((value >> 56) & 0xFFUL).to_byte())
    assert_eq(be_bytes[1], ((value >> 48) & 0xFFUL).to_byte())
    assert_eq(be_bytes[2], ((value >> 40) & 0xFFUL).to_byte())
    assert_eq(be_bytes[3], ((value >> 32) & 0xFFUL).to_byte())
    assert_eq(be_bytes[4], ((value >> 24) & 0xFFUL).to_byte())
    assert_eq(be_bytes[5], ((value >> 16) & 0xFFUL).to_byte())
    assert_eq(be_bytes[6], ((value >> 8) & 0xFFUL).to_byte())
    assert_eq(be_bytes[7], (value & 0xFFUL).to_byte())
    
    // Little-endian bytes should have least significant byte first
    assert_eq(le_bytes[0], (value & 0xFFUL).to_byte())
    assert_eq(le_bytes[1], ((value >> 8) & 0xFFUL).to_byte())
    assert_eq(le_bytes[2], ((value >> 16) & 0xFFUL).to_byte())
    assert_eq(le_bytes[3], ((value >> 24) & 0xFFUL).to_byte())
    assert_eq(le_bytes[4], ((value >> 32) & 0xFFUL).to_byte())
    assert_eq(le_bytes[5], ((value >> 40) & 0xFFUL).to_byte())
    assert_eq(le_bytes[6], ((value >> 48) & 0xFFUL).to_byte())
    assert_eq(le_bytes[7], ((value >> 56) & 0xFFUL).to_byte())
  }
}

test "uint64_byte_conversion_edge_cases" {
  // Test single bit patterns
  assert_eq(0x0100000000000000UL.to_be_bytes(), b"\x01\x00\x00\x00\x00\x00\x00\x00")
  assert_eq(0x0001000000000000UL.to_be_bytes(), b"\x00\x01\x00\x00\x00\x00\x00\x00")
  assert_eq(0x0000010000000000UL.to_be_bytes(), b"\x00\x00\x01\x00\x00\x00\x00\x00")
  assert_eq(0x0000000100000000UL.to_be_bytes(), b"\x00\x00\x00\x01\x00\x00\x00\x00")
  assert_eq(0x0000000001000000UL.to_be_bytes(), b"\x00\x00\x00\x00\x01\x00\x00\x00")
  assert_eq(0x0000000000010000UL.to_be_bytes(), b"\x00\x00\x00\x00\x00\x01\x00\x00")
  assert_eq(0x0000000000000100UL.to_be_bytes(), b"\x00\x00\x00\x00\x00\x00\x01\x00")
  assert_eq(0x0000000000000001UL.to_be_bytes(), b"\x00\x00\x00\x00\x00\x00\x00\x01")
  
  // Test corresponding little-endian patterns
  assert_eq(0x0100000000000000UL.to_le_bytes(), b"\x00\x00\x00\x00\x00\x00\x00\x01")
  assert_eq(0x0001000000000000UL.to_le_bytes(), b"\x00\x00\x00\x00\x00\x00\x01\x00")
  assert_eq(0x0000010000000000UL.to_le_bytes(), b"\x00\x00\x00\x00\x00\x01\x00\x00")
  assert_eq(0x0000000100000000UL.to_le_bytes(), b"\x00\x00\x00\x00\x01\x00\x00\x00")
  assert_eq(0x0000000001000000UL.to_le_bytes(), b"\x00\x00\x00\x01\x00\x00\x00\x00")
  assert_eq(0x0000000000010000UL.to_le_bytes(), b"\x00\x00\x01\x00\x00\x00\x00\x00")
  assert_eq(0x0000000000000100UL.to_le_bytes(), b"\x00\x01\x00\x00\x00\x00\x00\x00")
  assert_eq(0x0000000000000001UL.to_le_bytes(), b"\x01\x00\x00\x00\x00\x00\x00\x00")
  
  // Test alternating bit patterns
  assert_eq(0x5555555555555555UL.to_be_bytes(), b"\x55\x55\x55\x55\x55\x55\x55\x55")
  assert_eq(0x5555555555555555UL.to_le_bytes(), b"\x55\x55\x55\x55\x55\x55\x55\x55")
  
  // Test byte boundaries
  assert_eq(0xFFFFFFFFFFFFFF00UL.to_be_bytes(), b"\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x00")
  assert_eq(0x00FFFFFFFFFFFFFFUL.to_be_bytes(), b"\x00\xFF\xFF\xFF\xFF\xFF\xFF\xFF")
  assert_eq(0xFFFFFFFFFFFF0000UL.to_be_bytes(), b"\xFF\xFF\xFF\xFF\xFF\xFF\x00\x00")
  assert_eq(0x0000FFFFFFFFFFFFUL.to_be_bytes(), b"\x00\x00\xFF\xFF\xFF\xFF\xFF\xFF")
  
  // Test 32-bit boundary
  assert_eq(0xFFFFFFFF00000000UL.to_be_bytes(), b"\xFF\xFF\xFF\xFF\x00\x00\x00\x00")
  assert_eq(0x00000000FFFFFFFFUL.to_be_bytes(), b"\x00\x00\x00\x00\xFF\xFF\xFF\xFF")
}

test "uint64_byte_conversion_consistency" {
  // Test that endianness is properly handled
  let test_value = 0x123456789ABCDEF0UL
  let be_bytes = test_value.to_be_bytes()
  let le_bytes = test_value.to_le_bytes()
  
  // The bytes should be completely reversed
  for i in 0..<8 {
    assert_eq(be_bytes[i], le_bytes[7 - i])
  }
  
  // Test with another value
  let test_value2 = 0xFEDCBA0987654321UL
  let be_bytes2 = test_value2.to_be_bytes()
  let le_bytes2 = test_value2.to_le_bytes()
  
  for i in 0..<8 {
    assert_eq(be_bytes2[i], le_bytes2[7 - i])
  }
}

test "uint64_byte_conversion_mathematical_properties" {
  // Test that byte conversion preserves mathematical properties
  let a = 0x123456789ABCDEF0UL
  let b = 0x0FEDCBA987654321UL
  
  // Test that XOR is preserved in byte representation
  let xor_result = a.lxor(b)
  let a_be = a.to_be_bytes()
  let b_be = b.to_be_bytes()
  let xor_be = xor_result.to_be_bytes()
  
  for i in 0..<8 {
    assert_eq(xor_be[i], a_be[i].lxor(b_be[i]))
  }
  
  // Test the same with little-endian
  let a_le = a.to_le_bytes()
  let b_le = b.to_le_bytes()
  let xor_le = xor_result.to_le_bytes()
  
  for i in 0..<8 {
    assert_eq(xor_le[i], a_le[i].lxor(b_le[i]))
  }
}

test "uint64_byte_conversion_special_values" {
  // Test powers of 256
  assert_eq(256UL.to_be_bytes(), b"\x00\x00\x00\x00\x00\x00\x01\x00")
  assert_eq((256UL * 256UL).to_be_bytes(), b"\x00\x00\x00\x00\x00\x01\x00\x00")
  assert_eq((256UL * 256UL * 256UL).to_be_bytes(), b"\x00\x00\x00\x00\x01\x00\x00\x00")
  
  // Test common bit patterns
  assert_eq(0x0F0F0F0F0F0F0F0FUL.to_be_bytes(), b"\x0F\x0F\x0F\x0F\x0F\x0F\x0F\x0F")
  assert_eq(0xF0F0F0F0F0F0F0F0UL.to_be_bytes(), b"\xF0\xF0\xF0\xF0\xF0\xF0\xF0\xF0")
  
  // Test values that are powers of 2 minus 1
  assert_eq(0x00000000000000FFUL.to_be_bytes(), b"\x00\x00\x00\x00\x00\x00\x00\xFF")
  assert_eq(0x000000000000FFFFUL.to_be_bytes(), b"\x00\x00\x00\x00\x00\x00\xFF\xFF")
  assert_eq(0x0000000000FFFFFFUL.to_be_bytes(), b"\x00\x00\x00\x00\x00\xFF\xFF\xFF")
  assert_eq(0x00000000FFFFFFFFUL.to_be_bytes(), b"\x00\x00\x00\x00\xFF\xFF\xFF\xFF")
}