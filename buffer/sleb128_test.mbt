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
fn[A : Signed] @buffer.Buffer::test_signed(self : Self, x : A) -> Unit {
  self.reset()
  self.write_sleb128(x)
}

///|
test "write_sleb128 Int" {
  let buffer = @buffer.new()
  buffer.test_signed(0)
  inspect(
    buffer.to_bytes(),
    content=(
      #|b"\x00"
    ),
  )
  buffer.test_signed(-1)
  inspect(
    buffer.to_bytes(),
    content=(
      #|b"\x7f"
    ),
  )
  buffer.test_signed(-64)
  inspect(
    buffer.to_bytes(),
    content=(
      #|b"\x40"
    ),
  )
  buffer.test_signed(@int.min_value)
  inspect(
    buffer.to_bytes(),
    content=(
      #|b"\x80\x80\x80\x80\x78"
    ),
  )
  buffer.test_signed(128)
  assert_eq(buffer.to_bytes(), b"\x80\x01")
  buffer.test_signed(129)
  assert_eq(buffer.to_bytes(), b"\x81\x01")
  buffer.test_signed(16383)
  assert_eq(buffer.to_bytes(), b"\xff\x7f")
  buffer.test_signed(16384)
  assert_eq(buffer.to_bytes(), b"\x80\x80\x01")
  buffer.test_signed(2097151)
  assert_eq(buffer.to_bytes(), b"\xff\xff\x7f")
}

///|
test "write_sleb128 Int64" {
  let buffer = @buffer.new()
  buffer.write_sleb128(0L)
  assert_eq(buffer.to_bytes(), b"\x00")
  buffer.reset()
  buffer.write_sleb128(127L)
  assert_eq(buffer.to_bytes(), b"\x7f")
  buffer.reset()
  buffer.write_sleb128(128L)
  assert_eq(buffer.to_bytes(), b"\x80\x01")
  buffer.reset()
  buffer.write_sleb128(129L)
  assert_eq(buffer.to_bytes(), b"\x81\x01")
  buffer.reset()
  buffer.write_sleb128(16383L)
  assert_eq(buffer.to_bytes(), b"\xff\x7f")
  buffer.reset()
  buffer.write_sleb128(16384L)
  assert_eq(buffer.to_bytes(), b"\x80\x80\x01")
  buffer.reset()
  buffer.write_sleb128(2097151L)
  assert_eq(buffer.to_bytes(), b"\xff\xff\x7f")
}

///|
test "write_uleb128 Int" {
  let buffer = @buffer.new()
  // Test zero
  buffer.write_uleb128(0)
  assert_eq(buffer.to_bytes(), b"\x00")
  buffer.reset()

  // Test single byte values (0-127)
  buffer.write_uleb128(1)
  assert_eq(buffer.to_bytes(), b"\x01")
  buffer.reset()
  buffer.write_uleb128(127)
  assert_eq(buffer.to_bytes(), b"\x7f")
  buffer.reset()

  // Test two byte values (128-16383)
  buffer.write_uleb128(128)
  assert_eq(buffer.to_bytes(), b"\x80\x01")
  buffer.reset()
  buffer.write_uleb128(129)
  assert_eq(buffer.to_bytes(), b"\x81\x01")
  buffer.reset()
  buffer.write_uleb128(16383)
  assert_eq(buffer.to_bytes(), b"\xff\x7f")
  buffer.reset()

  // Test three byte values (16384-2097151)
  buffer.write_uleb128(16384)
  assert_eq(buffer.to_bytes(), b"\x80\x80\x01")
  buffer.reset()
  buffer.write_uleb128(2097151)
  assert_eq(buffer.to_bytes(), b"\xff\xff\x7f")
  buffer.reset()

  // Test four byte values (2097152-268435455)
  buffer.write_uleb128(2097152)
  assert_eq(buffer.to_bytes(), b"\x80\x80\x80\x01")
  buffer.reset()
  buffer.write_uleb128(268435455)
  assert_eq(buffer.to_bytes(), b"\xff\xff\xff\x7f")
  buffer.reset()

  // Test five byte values (268435456+)
  buffer.write_uleb128(268435456)
  assert_eq(buffer.to_bytes(), b"\x80\x80\x80\x80\x01")
  buffer.reset()
}

///|
test "write_uleb128 Int64" {
  let buffer = @buffer.new()
  // Test zero
  buffer.write_uleb128(0L)
  assert_eq(buffer.to_bytes(), b"\x00")
  buffer.reset()

  // Test single byte values (0-127)
  buffer.write_uleb128(1L)
  assert_eq(buffer.to_bytes(), b"\x01")
  buffer.reset()
  buffer.write_uleb128(127L)
  assert_eq(buffer.to_bytes(), b"\x7f")
  buffer.reset()

  // Test two byte values (128-16383)
  buffer.write_uleb128(128L)
  assert_eq(buffer.to_bytes(), b"\x80\x01")
  buffer.reset()
  buffer.write_uleb128(129L)
  assert_eq(buffer.to_bytes(), b"\x81\x01")
  buffer.reset()
  buffer.write_uleb128(16383L)
  assert_eq(buffer.to_bytes(), b"\xff\x7f")
  buffer.reset()

  // Test three byte values (16384-2097151)
  buffer.write_uleb128(16384L)
  assert_eq(buffer.to_bytes(), b"\x80\x80\x01")
  buffer.reset()
  buffer.write_uleb128(2097151L)
  assert_eq(buffer.to_bytes(), b"\xff\xff\x7f")
  buffer.reset()

  // Test larger values that fit in Int64
  buffer.write_uleb128(4294967295L) // 2^32 - 1
  assert_eq(buffer.to_bytes(), b"\xff\xff\xff\xff\x0f")
  buffer.reset()
  buffer.write_uleb128(549755813887L) // 2^39 - 1  
  assert_eq(buffer.to_bytes(), b"\xff\xff\xff\xff\xff\x0f")
  buffer.reset()
  buffer.write_uleb128(70368744177663L) // 2^46 - 1
  assert_eq(buffer.to_bytes(), b"\xff\xff\xff\xff\xff\xff\x0f")
  buffer.reset()

  // Test maximum positive Int64 value
  buffer.write_uleb128(9223372036854775807L) // 2^63 - 1
  assert_eq(buffer.to_bytes(), b"\xff\xff\xff\xff\xff\xff\xff\xff\x7f")
  buffer.reset()
}

///|
test "write_uleb128_edge_cases" {
  let buffer = @buffer.new()

  // Test boundary values for each byte length
  buffer.write_uleb128(0)
  assert_eq(buffer.to_bytes(), b"\x00")
  buffer.reset()
  buffer.write_uleb128(0x7f) // 127 (max 1 byte)
  assert_eq(buffer.to_bytes(), b"\x7f")
  buffer.reset()
  buffer.write_uleb128(0x80) // 128 (min 2 byte)
  assert_eq(buffer.to_bytes(), b"\x80\x01")
  buffer.reset()
  buffer.write_uleb128(0x3fff) // 16383 (max 2 byte)
  assert_eq(buffer.to_bytes(), b"\xff\x7f")
  buffer.reset()
  buffer.write_uleb128(0x4000) // 16384 (min 3 byte)
  assert_eq(buffer.to_bytes(), b"\x80\x80\x01")
  buffer.reset()
  buffer.write_uleb128(0x1fffff) // 2097151 (max 3 byte)
  assert_eq(buffer.to_bytes(), b"\xff\xff\x7f")
  buffer.reset()
  buffer.write_uleb128(0x200000) // 2097152 (min 4 byte)
  assert_eq(buffer.to_bytes(), b"\x80\x80\x80\x01")
  buffer.reset()
  buffer.write_uleb128(0xfffffff) // 268435455 (max 4 byte)
  assert_eq(buffer.to_bytes(), b"\xff\xff\xff\x7f")
  buffer.reset()
  buffer.write_uleb128(0x10000000) // 268435456 (min 5 byte)
  assert_eq(buffer.to_bytes(), b"\x80\x80\x80\x80\x01")
  buffer.reset()
}

///|
test "write_uleb128_consecutive_writes" {
  let buffer = @buffer.new()

  // Test writing multiple values consecutively
  buffer.write_uleb128(1)
  buffer.write_uleb128(127)
  buffer.write_uleb128(128)
  buffer.write_uleb128(16384)
  let expected = b"\x01\x7f\x80\x01\x80\x80\x01"
  assert_eq(buffer.to_bytes(), expected)
}

///|
test "write_sleb128_negative_values" {
  let buffer = @buffer.new()

  // Test negative values for SLEB128
  buffer.write_sleb128(-1)
  assert_eq(buffer.to_bytes(), b"\x7f")
  buffer.reset()
  buffer.write_sleb128(-64)
  assert_eq(buffer.to_bytes(), b"\x40")
  buffer.reset()
  buffer.write_sleb128(-65)
  assert_eq(buffer.to_bytes(), b"\xbf\x7f")
  buffer.reset()
  buffer.write_sleb128(-128)
  assert_eq(buffer.to_bytes(), b"\x80\x7f")
  buffer.reset()
  buffer.write_sleb128(-129)
  assert_eq(buffer.to_bytes(), b"\xff\x7e")
  buffer.reset()
}

///|
test "write_sleb128_negative_Int64" {
  let buffer = @buffer.new()

  // Test negative Int64 values for SLEB128
  buffer.write_sleb128(-1L)
  assert_eq(buffer.to_bytes(), b"\x7f")
  buffer.reset()
  buffer.write_sleb128(-64L)
  assert_eq(buffer.to_bytes(), b"\x40")
  buffer.reset()
  buffer.write_sleb128(-65L)
  assert_eq(buffer.to_bytes(), b"\xbf\x7f")
  buffer.reset()
  buffer.write_sleb128(-128L)
  assert_eq(buffer.to_bytes(), b"\x80\x7f")
  buffer.reset()
  buffer.write_sleb128(-129L)
  assert_eq(buffer.to_bytes(), b"\xff\x7e")
  buffer.reset()

  // Test large negative values
  buffer.write_sleb128(-9223372036854775808L) // Int64 minimum
  assert_eq(buffer.to_bytes(), b"\x80\x80\x80\x80\x80\x80\x80\x80\x80\x7f")
  buffer.reset()
}
