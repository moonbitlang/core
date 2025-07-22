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
/// Test that max_value and min_value constants are correct
test "byte constants validation" {
  assert_eq(max_value.to_uint(), 255)
  assert_eq(min_value.to_uint(), 0)
  assert_eq(max_value.to_uint64(), 255UL)
  assert_eq(min_value.to_uint64(), 0UL)
}

///|
/// Test popcnt for power of 2 patterns
test "popcnt power of 2 patterns" {
  inspect(b'\x01'.popcnt(), content="1") // 2^0
  inspect(b'\x02'.popcnt(), content="1") // 2^1  
  inspect(b'\x04'.popcnt(), content="1") // 2^2
  inspect(b'\x08'.popcnt(), content="1") // 2^3
  inspect(b'\x10'.popcnt(), content="1") // 2^4
  inspect(b'\x20'.popcnt(), content="1") // 2^5
  inspect(b'\x40'.popcnt(), content="1") // 2^6
  inspect(b'\x80'.popcnt(), content="1") // 2^7
}

///|
/// Test popcnt for alternating bit patterns
test "popcnt alternating patterns" {
  inspect(b'\x55'.popcnt(), content="4") // 01010101
  inspect(b'\xAA'.popcnt(), content="4") // 10101010
  inspect(b'\x33'.popcnt(), content="4") // 00110011
  inspect(b'\xCC'.popcnt(), content="4") // 11001100
  inspect(b'\x0F'.popcnt(), content="4") // 00001111
  inspect(b'\xF0'.popcnt(), content="4") // 11110000
}

///|
/// Test byte behavior with hex literals and character escapes
test "byte literal formats" {
  assert_eq(b'\x41'.to_uint(), 65) // ASCII 'A'
  assert_eq(b'\x61'.to_uint(), 97) // ASCII 'a'
  assert_eq(b'\x30'.to_uint(), 48) // ASCII '0'
  assert_eq(b'\x0A'.to_uint(), 10) // ASCII newline
  assert_eq(b'\x20'.to_uint(), 32) // ASCII space

  // Test escape sequences work in byte context
  assert_eq(b'\n'.to_uint(), 10)
  assert_eq(b'\t'.to_uint(), 9)
  assert_eq(b'\r'.to_uint(), 13)
}

///|
/// Test mathematical properties of byte operations
test "byte mathematical properties" {
  // Test that min and max values behave as expected
  assert_eq(max_value.to_uint() - min_value.to_uint(), 255)

  // Test symmetry in alternating patterns
  assert_eq(b'\x55'.popcnt(), b'\xAA'.popcnt()) // Both have 4 bits
  assert_eq(b'\x33'.popcnt(), b'\xCC'.popcnt()) // Both have 4 bits
  assert_eq(b'\x0F'.popcnt(), b'\xF0'.popcnt()) // Both have 4 bits

  // Test complement relationship
  let byte_val = b'\x55'
  let complement = (255 - byte_val.to_uint().reinterpret_as_int()).to_byte()
  assert_eq(byte_val.popcnt() + complement.popcnt(), 8)
}

///|
/// Test to_uint64 conversion preserves byte value accurately
test "to_uint64 conversion accuracy" {
  // Test boundary values
  assert_eq(b'\x00'.to_uint64(), 0UL)
  assert_eq(b'\xFF'.to_uint64(), 255UL)

  // Test some middle values
  assert_eq(b'\x10'.to_uint64(), 16UL)
  assert_eq(b'\x80'.to_uint64(), 128UL)
  assert_eq(b'\x7F'.to_uint64(), 127UL)
}
