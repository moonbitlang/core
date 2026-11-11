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
test "byte.to_string" {
  let b1 = b'\x00'
  let b2 = b'\x0F'
  let b3 = b'\xFF'
  inspect(b1, content="0")
  inspect(b2, content="15")
  inspect(b3, content="255")
}

///|
test "byte_compare" {
  let b1 = b'\x00'
  let b2 = b'\x0F'
  let b3 = b'\xFF'
  assert_true(b1.compare(b1) == 0)
  assert_true(b1.compare(b2) < 0)
  assert_true(b2.compare(b1) > 0)
  assert_true(b2.compare(b3) < 0)
  assert_true(b3.compare(b2) > 0)
  assert_true(b3.compare(b3) == 0)
}

///|
test "byte_equal" {
  let b1 = b'\x00'
  let b2 = b'\x0F'
  let b3 = b'\xFF'
  assert_true(b1 == b1)
  assert_true(b1 != b2)
  assert_true(b2 != b1)
  assert_true(b2 == b2)
  assert_true(b2 != b3)
  assert_true(b3 != b2)
  assert_true(b3 == b3)
}

///|
test "byte_lsl" {
  @test.assert_eq(b'\xFF' << 8, b'\x00')
  @test.assert_eq((b'\xFF' << 8).to_int(), 0)
}

///|
test "byte_lsr" {
  @test.assert_eq(b'\xFF' >> 8, b'\x00')
  @test.assert_eq((0xFFF).to_byte() >> 8, b'\x00')
}

///|
test "byte_lxor" {
  @test.assert_eq(b'\xFF' ^ b'\xFF', b'\x00')
  @test.assert_eq(b'\xFF' ^ b'\x0F', b'\xF0')
  @test.assert_eq(b'\x0F' ^ b'\xFF', b'\xF0')
}

///|
test "byte_lor" {
  @test.assert_eq(b'\xFF' | b'\xFF', b'\xFF')
  @test.assert_eq(b'\xFF' | b'\x0F', b'\xFF')
  @test.assert_eq(b'\x0F' | b'\xFF', b'\xFF')
}

///|
test "byte_land" {
  @test.assert_eq(b'\xFF' & b'\xFF', b'\xFF')
  @test.assert_eq(b'\xFF' & b'\x0F', b'\x0F')
  @test.assert_eq(b'\x0F' & b'\xFF', b'\x0F')
}

///|
test "byte_shr" {
  inspect(b'\x01' >> 1, content="0")
  inspect(b'\x02' >> 1, content="1")
  inspect(b'\x04' >> 2, content="1")
  inspect(b'\x00' >> 1, content="0")
  inspect(b'\xFF' >> 0, content="255")
  inspect(b'\xFF' >> 8, content="0")
  inspect(b'\x10' >> 3, content="2")
  inspect(b'\x20' >> 4, content="2")
  inspect(b'\x40' >> 5, content="2")
  inspect(b'\x80' >> 6, content="2")
  inspect(b'\x08' >> 2, content="2")
  inspect(b'\x02' >> 1, content="1")
}

///|
test "byte_shl" {
  // Test for the smallest possible shift count
  inspect(b'\x01' << 0, content="1")

  // Test for the largest possible shift count within the range of Int
  inspect(b'\x01' << 7, content="128")

  // Test for the largest possible shift count that causes overflow
  inspect(b'\x01' << 8, content="0")

  // Test for a negative shift count
  inspect(b'\x01' << -1, content="0")
  // Random byte value and shift count
  inspect(b'\x05' << 2, content="20")

  // Another random byte value and shift count
  inspect(b'\x0A' << 3, content="80")

  // Random byte value and shift count
  inspect(b'\x10' << 4, content="0")

  // Random byte value and shift count
  inspect(b'\x20' << 5, content="0")

  // Random byte value and shift count
  inspect(b'\x40' << 6, content="0")

  // Random byte value and shift count
  inspect(b'\x80' << 7, content="0")
  // Test for zero byte with various shift counts
  inspect(b'\x00' << 0, content="0")
  inspect(b'\x00' << 1, content="0")
  inspect(b'\x00' << 7, content="0")
  inspect(b'\x00' << 8, content="0")
  inspect(b'\x00' << -1, content="0")
  // Test for maximum byte value with various shift counts
  inspect(b'\xFF' << 0, content="255")
  inspect(b'\xFF' << 1, content="254")
  inspect(b'\xFF' << 7, content="128")
  inspect(b'\xFF' << 8, content="0")
  inspect(b'\xFF' << -1, content="0")
}

///|
test "byte_add" {
  inspect(b'\x01' + b'\x02', content="3")
  inspect(b'\x05' + b'\x05', content="10")
  inspect(b'\x0A' + b'\x0A', content="20")
  inspect(b'\x00' + b'\x00', content="0")
  inspect(b'\xFF' + b'\x01', content="0")
  inspect(b'\x7F' + b'\x01', content="128")
  inspect(b'\x10' + b'\x20', content="48")
  inspect(b'\x3A' + b'\x4B', content="133")
  inspect(b'\x5C' + b'\x6D', content="201")
  inspect(b'\x7E' + b'\x7F', content="253")
  inspect(b'\x8A' + b'\x9B', content="37")
  inspect(b'\xB0' + b'\xC1', content="113")
}

///|
test "byte_sub" {
  // Test for the smallest possible byte values
  inspect(b'\x00' - b'\x00', content="0")
  inspect(b'\x00' - b'\x01', content="255") // Underflow case
  inspect(b'\x01' - b'\x00', content="1")

  // Test for the largest possible byte values
  inspect(b'\xFF' - b'\x00', content="255")
  inspect(b'\xFF' - b'\xFF', content="0")
  inspect(b'\xFF' - b'\x01', content="254")
  // Random byte values
  inspect(b'\x3F' - b'\x2A', content="21")
  inspect(b'\x7A' - b'\x4B', content="47")
  inspect(b'\xB5' - b'\x8C', content="41")
  inspect(b'\x12' - b'\x34', content="222") // Underflow case
  inspect(b'\x9A' - b'\x78', content="34")
  inspect(b'\x4D' - b'\x6E', content="223") // Underflow case
  // Test cases where the result should underflow
  inspect(b'\x00' - b'\x01', content="255")
  inspect(b'\x05' - b'\x0A', content="251")
  inspect(b'\x10' - b'\x20', content="240")
  inspect(b'\x80' - b'\xFF', content="129")
  inspect(b'\x0F' - b'\x10', content="255")
}

///|
test "byte_mul" {
  inspect(Byte(8) * 16, content="128")
  inspect(Byte(3) * 200, content="88")
}

///|
test "byte_div" {
  inspect(Byte(80) / 8, content="10")
  inspect(Byte(10) / 3, content="3")
}

///|
test "byte_mod" {
  inspect(Byte(80) % 8, content="0")
  inspect(Byte(42) % 17, content="8")
}

///|
test "byte comparisons and lnot" {
  let a = b"\x01"[0]
  let b = b"\x02"[0]
  inspect(Eq::not_equal(a, b), content="true")
  inspect(Compare::op_lt(a, b), content="true")
  inspect(Compare::op_le(b, b), content="true")
  inspect(Compare::op_gt(b, a), content="true")
  inspect(Compare::op_ge(b, b), content="true")
  inspect(b'\x0F'.lnot(), content="240")
}
