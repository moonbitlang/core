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
  inspect(shr(1, 0), content="1")
  inspect(shr(2, 1), content="1")
  inspect(shr(4, 2), content="1")
  inspect(shr(8, 3), content="1")
  inspect(shr(16, 4), content="1")
  inspect(shr(32, 5), content="1")
  inspect(shr(64, 6), content="1")
  inspect(shr(128, 7), content="1")
  inspect(shr(256, 8), content="1")
  inspect(shr(512, 9), content="1")
  inspect(shr(1024, 10), content="1")
  inspect(shr(2048, 11), content="1")
  inspect(shr(4096, 12), content="1")
  inspect(shr(8192, 13), content="1")
  inspect(shr(16384, 14), content="1")
  inspect(shr(32768, 15), content="1")
  inspect(shr(0, 16), content="0")
}

///|
test "UInt16::lor" {
  fn lor(a : UInt16, b : UInt16) -> UInt16 {
    a | b
  }

  inspect(lor(0, 0), content="0")
  inspect(lor(1, 0), content="1")
  inspect(lor(0, 1), content="1")
  inspect(lor(1, 1), content="1")
  inspect(lor(0, 65535), content="65535")
  inspect(lor(65535, 0), content="65535")
  inspect(lor(65535, 65535), content="65535")
  inspect(lor(32768, 32768), content="32768")
  inspect(lor(32768, 16384), content="49152")
  inspect(lor(16384, 32768), content="49152")
  inspect(lor(16384, 16384), content="16384")
  inspect(lor(1000, 2000), content="2040")
  inspect(lor(2000, 1000), content="2040")
  inspect(lor(50000, 50000), content="50000")
  inspect(lor(50000, 40000), content="57168")
  inspect(lor(40000, 50000), content="57168")
}

///|
test "UInt16::land" {
  fn land(a : UInt16, b : UInt16) -> UInt16 {
    a & b
  }

  inspect(land(0, 0), content="0")
  inspect(land(1, 0), content="0")
  inspect(land(0, 1), content="0")
  inspect(land(1, 1), content="1")
  inspect(land(65535, 65535), content="65535")
  inspect(land(65535, 0), content="0")
  inspect(land(0, 65535), content="0")
  inspect(land(32768, 32768), content="32768")
  inspect(land(32768, 16384), content="0")
  inspect(land(16384, 32768), content="0")
  inspect(land(1000, 2000), content="960")
  inspect(land(2000, 1000), content="960")
  inspect(land(50000, 50000), content="50000")
  inspect(land(50000, 40000), content="32832")
  inspect(land(40000, 50000), content="32832")
}

///|
test "UInt16::lxor" {
  fn lxor(a : UInt16, b : UInt16) -> UInt16 {
    a ^ b
  }

  inspect(lxor(0, 0), content="0")
  inspect(lxor(1, 0), content="1")
  inspect(lxor(0, 1), content="1")
  inspect(lxor(1, 1), content="0")
  inspect(lxor(65535, 65535), content="0")
  inspect(lxor(65535, 0), content="65535")
  inspect(lxor(0, 65535), content="65535")
  inspect(lxor(32768, 32768), content="0")
  inspect(lxor(32768, 16384), content="49152")
  inspect(lxor(16384, 32768), content="49152")
  inspect(lxor(1000, 2000), content="1080")
  inspect(lxor(2000, 1000), content="1080")
  inspect(lxor(50000, 50000), content="0")
  inspect(lxor(50000, 40000), content="24336")
  inspect(lxor(40000, 50000), content="24336")
}

///|
test "UInt16::op_mod" {
  fn mod(a : UInt16, b : UInt16) -> UInt16 {
    a % b
  }

  inspect(mod(10, 3), content="1")
  inspect(mod(10, 2), content="0")
  inspect(mod(10, 10), content="0")
  inspect(mod(10, 11), content="10")
  inspect(mod(0, 1), content="0")
  inspect(mod(1, 1), content="0")
  inspect(mod(65535, 10000), content="5535")
  inspect(mod(65535, 2), content="1")
  inspect(mod(65535, 65535), content="0")
  inspect(mod(32768, 10000), content="2768")
  inspect(mod(50000, 10000), content="0")
  inspect(mod(50000, 9999), content="5")
  inspect(mod(1234, 1000), content="234")
  inspect(mod(1234, 1235), content="1234")
}

///|
test "UInt16::to_json" {
  inspect(UInt16::to_json(0), content="Number(0)")
  inspect(UInt16::to_json(1), content="Number(1)")
  inspect(UInt16::to_json(66), content="Number(66)")
  inspect(UInt16::to_json(65535), content="Number(65535)")
}

///|
test "UInt16::to_uint" {
  inspect(UInt16::to_uint(0), content="0")
  inspect(UInt16::to_uint(1), content="1")
  inspect(UInt16::to_uint(65535), content="65535")
  inspect(UInt16::to_uint(32768), content="32768")
  inspect(UInt16::to_uint(12345), content="12345")
}

///|
test "UInt16::to_uint64" {
  inspect(UInt16::to_uint64(0), content="0")
  inspect(UInt16::to_uint64(1), content="1")
  inspect(UInt16::to_uint64(65535), content="65535")
  inspect(UInt16::to_uint64(32768), content="32768")
  inspect(UInt16::to_uint64(12345), content="12345")
}
