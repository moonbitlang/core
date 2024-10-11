// Copyright 2024 International Digital Economy Academy
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

test "byte.to_string" {
  let b1 = b'\x00'
  let b2 = b'\x0F'
  let b3 = b'\xFF'
  inspect!(b1, content="b'\\x00'")
  inspect!(b2, content="b'\\x0F'")
  inspect!(b3, content="b'\\xFF'")
}

test "byte_compare" {
  let b1 = b'\x00'
  let b2 = b'\x0F'
  let b3 = b'\xFF'
  assert_true!(b1.compare(b1) == 0)
  assert_true!(b1.compare(b2) < 0)
  assert_true!(b2.compare(b1) > 0)
  assert_true!(b2.compare(b3) < 0)
  assert_true!(b3.compare(b2) > 0)
  assert_true!(b3.compare(b3) == 0)
}

test "byte_op_equal" {
  let b1 = b'\x00'
  let b2 = b'\x0F'
  let b3 = b'\xFF'
  assert_true!(b1.op_equal(b1))
  assert_true!(b1.op_equal(b2) |> not)
  assert_true!(b2.op_equal(b1) |> not)
  assert_true!(b2.op_equal(b2))
  assert_true!(b2.op_equal(b3) |> not)
  assert_true!(b3.op_equal(b2) |> not)
  assert_true!(b3.op_equal(b3))
}

test "byte_lsl" {
  assert_eq!(b'\xFF' << 8, b'\x00')
  assert_eq!((b'\xFF' << 8).to_int(), 0)
}

test "byte_lsr" {
  assert_eq!(b'\xFF' >> 8, b'\x00')
  assert_eq!((0xFFF).to_byte() >> 8, b'\x00')
}

test "byte_lxor" {
  assert_eq!(b'\xFF' ^ b'\xFF', b'\x00')
  assert_eq!(b'\xFF' ^ b'\x0F', b'\xF0')
  assert_eq!(b'\x0F' ^ b'\xFF', b'\xF0')
}

test "byte_lor" {
  assert_eq!(b'\xFF' | b'\xFF', b'\xFF')
  assert_eq!(b'\xFF' | b'\x0F', b'\xFF')
  assert_eq!(b'\x0F' | b'\xFF', b'\xFF')
}

test "byte_land" {
  assert_eq!(b'\xFF' & b'\xFF', b'\xFF')
  assert_eq!(b'\xFF' & b'\x0F', b'\x0F')
  assert_eq!(b'\x0F' & b'\xFF', b'\x0F')
}

test "byte_shr" {
  inspect!(b'\x01' >> 1, content="b'\\x00'")
  inspect!(b'\x02' >> 1, content="b'\\x01'")
  inspect!(b'\x04' >> 2, content="b'\\x01'")
  inspect!(b'\x00' >> 1, content="b'\\x00'")
  inspect!(b'\xFF' >> 0, content="b'\\xFF'")
  inspect!(b'\xFF' >> 8, content="b'\\x00'")
  inspect!(b'\x10' >> 3, content="b'\\x02'")
  inspect!(b'\x20' >> 4, content="b'\\x02'")
  inspect!(b'\x40' >> 5, content="b'\\x02'")
  inspect!(b'\x80' >> 6, content="b'\\x02'")
  inspect!(b'\x08' >> 2, content="b'\\x02'")
  inspect!(b'\x02' >> 1, content="b'\\x01'")
}

test "byte_shl" {
  // Test for the smallest possible shift count
  inspect!(b'\x01' << 0, content="b'\\x01'")

  // Test for the largest possible shift count within the range of Int
  inspect!(b'\x01' << 7, content="b'\\x80'")

  // Test for the largest possible shift count that causes overflow
  inspect!(b'\x01' << 8, content="b'\\x00'")

  // Test for a negative shift count
  inspect!(b'\x01' << -1, content="b'\\x00'")
  // Random byte value and shift count
  inspect!(b'\x05' << 2, content="b'\\x14'")

  // Another random byte value and shift count
  inspect!(b'\x0A' << 3, content="b'\\x50'")

  // Random byte value and shift count
  inspect!(b'\x10' << 4, content="b'\\x00'")

  // Random byte value and shift count
  inspect!(b'\x20' << 5, content="b'\\x00'")

  // Random byte value and shift count
  inspect!(b'\x40' << 6, content="b'\\x00'")

  // Random byte value and shift count
  inspect!(b'\x80' << 7, content="b'\\x00'")
  // Test for zero byte with various shift counts
  inspect!(b'\x00' << 0, content="b'\\x00'")
  inspect!(b'\x00' << 1, content="b'\\x00'")
  inspect!(b'\x00' << 7, content="b'\\x00'")
  inspect!(b'\x00' << 8, content="b'\\x00'")
  inspect!(b'\x00' << -1, content="b'\\x00'")
  // Test for maximum byte value with various shift counts
  inspect!(b'\xFF' << 0, content="b'\\xFF'")
  inspect!(b'\xFF' << 1, content="b'\\xFE'")
  inspect!(b'\xFF' << 7, content="b'\\x80'")
  inspect!(b'\xFF' << 8, content="b'\\x00'")
  inspect!(b'\xFF' << -1, content="b'\\x00'")
}

test "byte_op_add" {
  inspect!(b'\x01' + b'\x02', content="b'\\x03'")
  inspect!(b'\x05' + b'\x05', content="b'\\x0A'")
  inspect!(b'\x0A' + b'\x0A', content="b'\\x14'")
  inspect!(b'\x00' + b'\x00', content="b'\\x00'")
  inspect!(b'\xFF' + b'\x01', content="b'\\x00'")
  inspect!(b'\x7F' + b'\x01', content="b'\\x80'")
  inspect!(b'\x10' + b'\x20', content="b'\\x30'")
  inspect!(b'\x3A' + b'\x4B', content="b'\\x85'")
  inspect!(b'\x5C' + b'\x6D', content="b'\\xC9'")
  inspect!(b'\x7E' + b'\x7F', content="b'\\xFD'")
  inspect!(b'\x8A' + b'\x9B', content="b'\\x25'")
  inspect!(b'\xB0' + b'\xC1', content="b'\\x71'")
}

test "byte_op_sub" {
  // Test for the smallest possible byte values
  inspect!(b'\x00' - b'\x00', content="b'\\x00'")
  inspect!(b'\x00' - b'\x01', content="b'\\xFF'") // Underflow case
  inspect!(b'\x01' - b'\x00', content="b'\\x01'")

  // Test for the largest possible byte values
  inspect!(b'\xFF' - b'\x00', content="b'\\xFF'")
  inspect!(b'\xFF' - b'\xFF', content="b'\\x00'")
  inspect!(b'\xFF' - b'\x01', content="b'\\xFE'")
  // Random byte values
  inspect!(b'\x3F' - b'\x2A', content="b'\\x15'")
  inspect!(b'\x7A' - b'\x4B', content="b'\\x2F'")
  inspect!(b'\xB5' - b'\x8C', content="b'\\x29'")
  inspect!(b'\x12' - b'\x34', content="b'\\xDE'") // Underflow case
  inspect!(b'\x9A' - b'\x78', content="b'\\x22'")
  inspect!(b'\x4D' - b'\x6E', content="b'\\xDF'") // Underflow case
  // Test cases where the result should underflow
  inspect!(b'\x00' - b'\x01', content="b'\\xFF'")
  inspect!(b'\x05' - b'\x0A', content="b'\\xFB'")
  inspect!(b'\x10' - b'\x20', content="b'\\xF0'")
  inspect!(b'\x80' - b'\xFF', content="b'\\x81'")
  inspect!(b'\x0F' - b'\x10', content="b'\\xFF'")
}
