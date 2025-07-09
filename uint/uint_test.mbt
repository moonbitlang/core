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
test "UInt to byte" {
  let a = 10U.to_byte()
  inspect(a, content="b'\\x0A'")
  let b = 255U.to_byte()
  inspect(b, content="b'\\xFF'")
  let c = 10UL.to_byte()
  inspect(c, content="b'\\x0A'")
  let d = 255UL.to_byte()
  inspect(d, content="b'\\xFF'")
  let f = 24U >> 16
  let e = f.to_byte()
  inspect(e, content="b'\\x00'")
  let f = 24U >> 64
  let e = f.to_byte()
  inspect(e, content="b'\\x18'")
  // to_byte
  let u = 0xDEADBEEFU
  let b = u.to_byte()
  inspect(b, content="b'\\xEF'")
  let u = 0x87654321U
  let b = u.to_byte()
  inspect(b, content="b'\\x21'")
  let u = 0xFFFFU
  let b = u.to_byte()
  inspect(b, content="b'\\xFF'")
  let u = 0xFFU
  let b = u.to_byte()
  inspect(b, content="b'\\xFF'")
  let u = 0x12345678U
  let b = u.to_byte()
  inspect(b, content="b'\\x78'")
  let u = 0U
  let b = u.to_byte()
  inspect(b, content="b'\\x00'")
}

///|
test "shift" {
  inspect(1U << 2, content="4")
  inspect(4U >> 2, content="1")
  inspect(2U >> 2, content="0")
}

///|
test "default" {
  inspect(@uint.default(), content="0")
}

///|
test "to_le_bytes" {
  let x : UInt = 0x12345678U
  let bytes = x.to_le_bytes()
  inspect(bytes[0].to_int(), content="120") // 0x78
  inspect(bytes[1].to_int(), content="86") // 0x56
  inspect(bytes[2].to_int(), content="52") // 0x34
  inspect(bytes[3].to_int(), content="18") // 0x12
}

///|
test "test UInt::default" {
  inspect(UInt::default(), content="0")
}

///|
test "to_be_bytes" {
  let n = 4294967295U // maximum UInt value
  inspect(n.to_be_bytes(), content="b\"\\xff\\xff\\xff\\xff\"")
}

test "to_be_bytes_comprehensive" {
  // Test zero
  assert_eq(0U.to_be_bytes(), b"\x00\x00\x00\x00")
  
  // Test maximum value
  assert_eq(4294967295U.to_be_bytes(), b"\xFF\xFF\xFF\xFF")
  
  // Test minimum non-zero value
  assert_eq(1U.to_be_bytes(), b"\x00\x00\x00\x01")
  
  // Test powers of 2
  assert_eq(256U.to_be_bytes(), b"\x00\x00\x01\x00")
  assert_eq(65536U.to_be_bytes(), b"\x00\x01\x00\x00")
  assert_eq(16777216U.to_be_bytes(), b"\x01\x00\x00\x00")
  
  // Test specific values
  assert_eq(0x12345678U.to_be_bytes(), b"\x12\x34\x56\x78")
  assert_eq(0xABCDEF00U.to_be_bytes(), b"\xAB\xCD\xEF\x00")
  assert_eq(0x00ABCDEFU.to_be_bytes(), b"\x00\xAB\xCD\xEF")
  
  // Test edge cases
  assert_eq(0x80000000U.to_be_bytes(), b"\x80\x00\x00\x00")
  assert_eq(0x7FFFFFFFU.to_be_bytes(), b"\x7F\xFF\xFF\xFF")
  
  // Test all bytes the same
  assert_eq(0x11111111U.to_be_bytes(), b"\x11\x11\x11\x11")
  assert_eq(0xAAAAAAAAU.to_be_bytes(), b"\xAA\xAA\xAA\xAA")
}

test "to_le_bytes_comprehensive" {
  // Test zero
  assert_eq(0U.to_le_bytes(), b"\x00\x00\x00\x00")
  
  // Test maximum value
  assert_eq(4294967295U.to_le_bytes(), b"\xFF\xFF\xFF\xFF")
  
  // Test minimum non-zero value
  assert_eq(1U.to_le_bytes(), b"\x01\x00\x00\x00")
  
  // Test powers of 2
  assert_eq(256U.to_le_bytes(), b"\x00\x01\x00\x00")
  assert_eq(65536U.to_le_bytes(), b"\x00\x00\x01\x00")
  assert_eq(16777216U.to_le_bytes(), b"\x00\x00\x00\x01")
  
  // Test specific values (note: reversed from big-endian)
  assert_eq(0x12345678U.to_le_bytes(), b"\x78\x56\x34\x12")
  assert_eq(0xABCDEF00U.to_le_bytes(), b"\x00\xEF\xCD\xAB")
  assert_eq(0x00ABCDEFU.to_le_bytes(), b"\xEF\xCD\xAB\x00")
  
  // Test edge cases
  assert_eq(0x80000000U.to_le_bytes(), b"\x00\x00\x00\x80")
  assert_eq(0x7FFFFFFFU.to_le_bytes(), b"\xFF\xFF\xFF\x7F")
  
  // Test all bytes the same
  assert_eq(0x11111111U.to_le_bytes(), b"\x11\x11\x11\x11")
  assert_eq(0xAAAAAAAAU.to_le_bytes(), b"\xAA\xAA\xAA\xAA")
}

test "byte_conversion_roundtrip" {
  // Test that big-endian and little-endian are inverses for some values
  let values = [0U, 1U, 255U, 256U, 65535U, 65536U, 16777215U, 16777216U, 
                0x12345678U, 0xABCDEF00U, 0x80000000U, 0x7FFFFFFFU, 4294967295U]
  
  for value in values {
    let be_bytes = value.to_be_bytes()
    let le_bytes = value.to_le_bytes()
    
    // Big-endian bytes should have most significant byte first
    assert_eq(be_bytes[0], ((value >> 24) & 0xFFU).to_byte())
    assert_eq(be_bytes[1], ((value >> 16) & 0xFFU).to_byte())
    assert_eq(be_bytes[2], ((value >> 8) & 0xFFU).to_byte())
    assert_eq(be_bytes[3], (value & 0xFFU).to_byte())
    
    // Little-endian bytes should have least significant byte first
    assert_eq(le_bytes[0], (value & 0xFFU).to_byte())
    assert_eq(le_bytes[1], ((value >> 8) & 0xFFU).to_byte())
    assert_eq(le_bytes[2], ((value >> 16) & 0xFFU).to_byte())
    assert_eq(le_bytes[3], ((value >> 24) & 0xFFU).to_byte())
  }
}

test "to_int64_comprehensive" {
  // Test zero
  assert_eq(0U.to_int64(), 0L)
  
  // Test small values
  assert_eq(1U.to_int64(), 1L)
  assert_eq(100U.to_int64(), 100L)
  assert_eq(65535U.to_int64(), 65535L)
  
  // Test max value that fits in positive int64
  assert_eq(2147483647U.to_int64(), 2147483647L)
  
  // Test values that would be negative in int64 but positive in uint
  assert_eq(2147483648U.to_int64(), -2147483648L)
  assert_eq(4294967295U.to_int64(), -1L)
  
  // Test edge cases
  assert_eq(0x80000000U.to_int64(), -2147483648L)
  assert_eq(0x7FFFFFFFU.to_int64(), 2147483647L)
  assert_eq(0xFFFFFFFFU.to_int64(), -1L)
}

test "default_function" {
  // Test that default() returns zero
  assert_eq(default(), 0U)
  assert_eq(UInt::default(), 0U)
  
  // Test that default values are equal
  assert_eq(default(), UInt::default())
  assert_eq(default() + 1U, 1U)
  assert_eq(default() * 1000U, 0U)
}

test "constants" {
  // Test min and max values
  assert_eq(min_value, 0U)
  assert_eq(max_value, 4294967295U)
  
  // Test that min_value is actually minimum
  assert_eq(min_value - 1U, max_value) // underflow wraps around
  
  // Test that max_value is actually maximum
  assert_eq(max_value + 1U, min_value) // overflow wraps around
  
  // Test bit patterns
  assert_eq(max_value, 0xFFFFFFFFU)
  assert_eq(min_value, 0x00000000U)
}

test "byte_conversion_edge_cases" {
  // Test single bit patterns
  assert_eq(0x01000000U.to_be_bytes(), b"\x01\x00\x00\x00")
  assert_eq(0x00010000U.to_be_bytes(), b"\x00\x01\x00\x00")
  assert_eq(0x00000100U.to_be_bytes(), b"\x00\x00\x01\x00")
  assert_eq(0x00000001U.to_be_bytes(), b"\x00\x00\x00\x01")
  
  assert_eq(0x01000000U.to_le_bytes(), b"\x00\x00\x00\x01")
  assert_eq(0x00010000U.to_le_bytes(), b"\x00\x00\x01\x00")
  assert_eq(0x00000100U.to_le_bytes(), b"\x00\x01\x00\x00")
  assert_eq(0x00000001U.to_le_bytes(), b"\x01\x00\x00\x00")
  
  // Test alternating bit patterns
  assert_eq(0x55555555U.to_be_bytes(), b"\x55\x55\x55\x55")
  assert_eq(0x55555555U.to_le_bytes(), b"\x55\x55\x55\x55")
  
  // Test byte boundaries
  assert_eq(0xFFFFFF00U.to_be_bytes(), b"\xFF\xFF\xFF\x00")
  assert_eq(0x00FFFFFFU.to_be_bytes(), b"\x00\xFF\xFF\xFF")
  assert_eq(0xFFFF0000U.to_be_bytes(), b"\xFF\xFF\x00\x00")
  assert_eq(0x0000FFFFU.to_be_bytes(), b"\x00\x00\xFF\xFF")
}
