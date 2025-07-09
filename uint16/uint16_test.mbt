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
test "UInt16::to_int" {
  inspect(UInt16::to_int(0), content="0")
  inspect(UInt16::to_int(123), content="123")
  inspect(UInt16::to_int(65535), content="65535")
}

///|
test "UInt16::from_int" {
  inspect(Int::to_uint16(0), content="0")
  inspect(Int::to_uint16(123), content="123")
  inspect(Int::to_uint16(65535), content="65535")
  inspect(Int::to_uint16(-1), content="65535")
  inspect(Int::to_uint16(-123), content="65413")
  inspect(Int::to_uint16(65536), content="0")
  inspect(Int::to_uint16(65537), content="1")
  inspect(Int::to_uint16(131071), content="65535")
  inspect(Int::to_uint16(-65536), content="0")
  inspect(Int::to_uint16(-65537), content="65535")
}

///|
test "UInt16::to_byte" {
  inspect(UInt16::to_byte(0), content="b'\\x00'")
  inspect(UInt16::to_byte(123), content="b'\\x7B'")
  inspect(UInt16::to_byte(65535), content="b'\\xFF'")
}

///|
test "UInt16::from_byte" {
  inspect(Byte::to_uint16(0), content="0")
  inspect(Byte::to_uint16(123), content="123")
  inspect(Byte::to_uint16(255), content="255")
}

///|
test "UInt16::to_int64" {
  inspect(UInt16::to_int64(0), content="0")
  inspect(UInt16::to_int64(123), content="123")
  inspect(UInt16::to_int64(65535), content="65535")
}

///|
test "UInt16::from_int64" {
  inspect(Int::to_uint16(0), content="0")
  inspect(Int::to_uint16(123), content="123")
  inspect(Int::to_uint16(65535), content="65535")
  inspect(Int::to_uint16(-1), content="65535")
  inspect(Int::to_uint16(-123), content="65413")
  inspect(Int::to_uint16(65536), content="0")
  inspect(Int::to_uint16(65537), content="1")
  inspect(Int::to_uint16(131071), content="65535")
  inspect(Int::to_uint16(-65536), content="0")
  inspect(Int::to_uint16(-65537), content="65535")
  inspect(Int::to_uint16(1000000), content="16960") // Large positive number wraps around
  inspect(Int::to_uint16(-1000000), content="48576") // Large negative number wraps around
  inspect(Int::to_uint16(32768), content="32768") // Half of max value
  inspect(Int::to_uint16(49152), content="49152") // 3/4 of max value
  inspect(Int::to_uint16(16384), content="16384") // 1/4 of max value
  inspect((65535 : UInt16) + 1, content="0") // Max value + 1 wraps to 0
}

///|
test "UInt16::op_add" {
  fn add(a : UInt16, b : UInt16) -> UInt16 {
    a + b
  }

  inspect(add(0, 0), content="0")
  inspect(add(1, 1), content="2")
  inspect(add(100, 200), content="300")
  inspect(add(65535, 1), content="0") // Wraps around to 0
  inspect(add(65535, 2), content="1") // Wraps around to 1
  inspect(add(32768, 32768), content="0") // Adding two large numbers wraps
  inspect(add(50000, 20000), content="4464") // Overflow case
  inspect(add(65000, 1000), content="464") // Another overflow
  inspect(add(16384, 16384), content="32768") // Adding quarter max values
  inspect(add(0, 65535), content="65535") // Adding 0 to max
}

///|
test "UInt16::op_sub" {
  fn sub(a : UInt16, b : UInt16) -> UInt16 {
    a - b
  }

  inspect(sub(0, 0), content="0")
  inspect(sub(2, 1), content="1")
  inspect(sub(300, 200), content="100")
  inspect(sub(0, 1), content="65535") // Underflow wraps to max value
  inspect(sub(0, 2), content="65534") // Underflow wraps to max-1
  inspect(sub(65535, 65535), content="0") // Max minus itself
  inspect(sub(32768, 16384), content="16384") // Half max minus quarter max
  inspect(sub(1000, 2000), content="64536") // Underflow case
  inspect(sub(50000, 60000), content="55536") // Another underflow
  inspect(sub(65535, 1), content="65534") // Max minus 1
  inspect(sub(32768, 32768), content="0") // Equal large numbers
}

///|
test "UInt16::op_mul" {
  fn mul(a : UInt16, b : UInt16) -> UInt16 {
    a * b
  }

  inspect(mul(0, 0), content="0")
  inspect(mul(1, 1), content="1")
  inspect(mul(2, 3), content="6")
  inspect(mul(100, 100), content="10000")
  inspect(mul(256, 256), content="0") // Overflow wraps to 0
  inspect(mul(1000, 100), content="34464") // Overflow case
  inspect(mul(65535, 2), content="65534") // Max value * 2 wraps
  inspect(mul(32768, 2), content="0") // Half max * 2 wraps to 0
  inspect(mul(255, 255), content="65025") // Near max result
  inspect(mul(16384, 4), content="0") // Quarter max * 4 wraps
  inspect(mul(65535, 65535), content="1") // Max * max wraps to 1
}

///|
test "UInt16::op_div" {
  fn div(a : UInt16, b : UInt16) -> UInt16 {
    a / b
  }

  inspect(div(0, 1), content="0")
  inspect(div(1, 1), content="1")
  inspect(div(6, 2), content="3")
  inspect(div(65535, 1), content="65535") // Max value / 1
  inspect(div(65535, 2), content="32767") // Max value / 2
  inspect(div(65535, 65535), content="1") // Max value / itself
  inspect(div(32768, 2), content="16384") // Half max / 2
  inspect(div(60000, 1000), content="60") // Large number division
  inspect(div(65534, 2), content="32767") // Even division near max
  inspect(div(10000, 100), content="100") // Clean division
  inspect(div(65535, 10), content="6553") // Max value / 10
}

///|
test "UInt16::compare" {
  inspect(UInt16::compare(1, 2), content="-1")
  inspect(UInt16::compare(2, 1), content="1")
  inspect(UInt16::compare(1, 1), content="0")
  inspect(UInt16::compare(0, 1), content="-1")
  inspect(UInt16::compare(1, 0), content="1")
  inspect(UInt16::compare(0, 0), content="0")
  inspect(UInt16::compare(65535, 65534), content="1") // Max value comparison
  inspect(UInt16::compare(65534, 65535), content="-1")
  inspect(UInt16::compare(65535, 65535), content="0") // Max value equals
  inspect(UInt16::compare(32768, 32767), content="1") // Half max comparison
  inspect(UInt16::compare(32767, 32768), content="-1")
  inspect(UInt16::compare(32768, 32768), content="0") // Half max equals
  inspect(UInt16::compare(0, 65535), content="-1") // Min vs Max
  inspect(UInt16::compare(65535, 0), content="1") // Max vs Min
  inspect(UInt16::compare(1000, 2000), content="-1") // Mid-range values
  inspect(UInt16::compare(2000, 1000), content="1")
  inspect(UInt16::compare(50000, 50000), content="0") // Large equal values
  inspect(UInt16::compare(50000, 40000), content="1") // Large different values
  inspect(UInt16::compare(40000, 50000), content="-1")
}

///|
test "UInt16::hash" {
  inspect(UInt16::hash(0), content="0")
  inspect(UInt16::hash(123), content="123")
  inspect(UInt16::hash(65535), content="65535")
}

///|
test "UInt16::op_equal" {
  inspect(UInt16::op_equal(1, 2), content="false")
  inspect(UInt16::op_equal(2, 1), content="false")
  inspect(UInt16::op_equal(1, 1), content="true")
  inspect(UInt16::op_equal(0, 1), content="false")
  inspect(UInt16::op_equal(1, 0), content="false")
  inspect(UInt16::op_equal(0, 0), content="true")
}

///|
test "UInt16::op_shl" {
  fn shl(a : UInt16, b : Int) -> UInt16 {
    a << b
  }

  inspect(shl(0, 0), content="0")
  inspect(shl(1, 0), content="1")
  inspect(shl(1, 1), content="2")
  inspect(shl(1, 2), content="4")
  inspect(shl(1, 3), content="8")
  inspect(shl(1, 4), content="16")
  inspect(shl(1, 5), content="32")
  inspect(shl(1, 6), content="64")
  inspect(shl(1, 7), content="128")
  inspect(shl(1, 8), content="256")
  inspect(shl(1, 9), content="512")
  inspect(shl(1, 10), content="1024")
  inspect(shl(1, 11), content="2048")
  inspect(shl(1, 12), content="4096")
  inspect(shl(1, 13), content="8192")
  inspect(shl(1, 14), content="16384")
  inspect(shl(1, 15), content="32768")
  inspect(shl(1, 16), content="0")
}

///|
test "UInt16::op_shr" {
  fn shr(a : UInt16, b : Int) -> UInt16 {
    a >> b
  }

  inspect(shr(0, 0), content="0")
  inspect(shr(8, 3), content="1")
  inspect(shr(65535, 1), content="32767") // Right shift max value by 1
  inspect(shr(65535, 15), content="1") // Right shift max value by 15
  inspect(shr(65535, 16), content="0") // Right shift max value by 16 (all bits)
  inspect(shr(32768, 1), content="16384") // Half max right shift by 1
  inspect(shr(1024, 4), content="64") // 1024 >> 4 = 64
  inspect(shr(65280, 8), content="255") // Shift byte boundary
  inspect(shr(49152, 2), content="12288") // 3/4 max >> 2
  inspect(shr(4096, 12), content="1") // Large shift
}

///|
test "UInt16::op_mod comprehensive testing" {
  fn mod(a : UInt16, b : UInt16) -> UInt16 {
    a % b
  }

  inspect(mod(0, 1), content="0")
  inspect(mod(1, 1), content="0")
  inspect(mod(5, 3), content="2")
  inspect(mod(65535, 2), content="1") // Max value mod 2
  inspect(mod(65535, 3), content="0") // Max value mod 3
  inspect(mod(65535, 10), content="5") // Max value mod 10
  inspect(mod(32768, 7), content="1") // Half max mod 7
  inspect(mod(10000, 13), content="3") // 10000 % 13 = 3, not 10
  inspect(mod(65534, 2), content="0") // Even number mod 2
  inspect(mod(1000, 7), content="6") // Mid range mod
  inspect(mod(65535, 65535), content="0") // Max mod itself
  inspect(mod(65534, 65535), content="65534") // Just less than divisor
}

///|
test "UInt16 bitwise operations comprehensive testing" {
  // Test BitOr (lor)
  fn test_or(a : UInt16, b : UInt16) -> UInt16 {
    a | b
  }

  inspect(test_or(0, 0), content="0")
  inspect(test_or(1, 2), content="3")
  inspect(test_or(65535, 0), content="65535")
  inspect(test_or(32768, 16384), content="49152") // Two high bits
  inspect(test_or(255, 65280), content="65535") // Low byte | high byte
  inspect(test_or(4369, 8738), content="13107") // Mixed bits: 4369 | 8738 = 13107

  // Test BitAnd (land)
  fn test_and(a : UInt16, b : UInt16) -> UInt16 {
    a & b
  }

  inspect(test_and(0, 0), content="0")
  inspect(test_and(65535, 65535), content="65535")
  inspect(test_and(65535, 0), content="0")
  inspect(test_and(255, 65535), content="255") // Low byte & all
  inspect(test_and(32768, 49152), content="32768") // Overlapping high bits
  inspect(test_and(4369, 8738), content="0") // Mixed bits: 4369 & 8738 = 0

  // Test BitXOr (lxor)
  fn test_xor(a : UInt16, b : UInt16) -> UInt16 {
    a ^ b
  }

  inspect(test_xor(0, 0), content="0")
  inspect(test_xor(65535, 65535), content="0")
  inspect(test_xor(65535, 0), content="65535")
  inspect(test_xor(255, 65280), content="65535") // Low ^ high
  inspect(test_xor(32768, 16384), content="49152") // Different bits
  inspect(test_xor(4369, 8738), content="13107") // Mixed XOR: 4369 ^ 8738 = 13107
}

///|
test "UInt16 conversion functions comprehensive testing" {
  // Test to_uint
  let a : UInt16 = 0
  let result_a = a.to_uint()
  inspect(result_a, content="0")
  let b : UInt16 = 123
  let result_b = b.to_uint()
  inspect(result_b, content="123")
  let c : UInt16 = 65535
  let result_c = c.to_uint()
  inspect(result_c, content="65535")

  // Test to_uint64
  let d : UInt16 = 0
  let result_d = d.to_uint64()
  inspect(result_d, content="0")
  let e : UInt16 = 1000
  let result_e = e.to_uint64()
  inspect(result_e, content="1000")
  let f : UInt16 = 65535
  let result_f = f.to_uint64()
  inspect(result_f, content="65535")
}

///|
test "UInt16 to_json comprehensive testing" {
  let a : UInt16 = 0
  let json_a = a.to_json()
  inspect(json_a, content="Number(0)")
  let b : UInt16 = 123
  let json_b = b.to_json()
  inspect(json_b, content="Number(123)")
  let c : UInt16 = 65535
  let json_c = c.to_json()
  inspect(json_c, content="Number(65535)")
  let d : UInt16 = 32768
  let json_d = d.to_json()
  inspect(json_d, content="Number(32768)")
}
