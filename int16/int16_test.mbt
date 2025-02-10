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
test "Int16::to_int" {
  inspect!(Int16::to_int(0), content="0")
  inspect!(Int16::to_int(123), content="123")
  inspect!(Int16::to_int(-123), content="-123")
  inspect!(Int16::to_int(32767), content="32767")
  inspect!(Int16::to_int(-32768), content="-32768")
}

///|
test "Int16::from_int" {
  inspect!(Int::to_int16(0), content="0")
  inspect!(Int::to_int16(123), content="123")
  inspect!(Int::to_int16(-123), content="-123")
  inspect!(Int::to_int16(32767), content="32767")
  inspect!(Int::to_int16(-32768), content="-32768")
  inspect!(Int::to_int16(32768), content="-32768")
  inspect!(Int::to_int16(-32769), content="32767")
  inspect!(Int::to_int16(65535), content="-1")
  inspect!(Int::to_int16(-65536), content="0")
  inspect!(Int::to_int16(65536), content="0")
}

///|
test "Int16::to_byte" {
  inspect!(Int16::to_byte(0), content="b'\\x00'")
  inspect!(Int16::to_byte(123), content="b'\\x7B'")
  inspect!(Int16::to_byte(-123), content="b'\\x85'")
  inspect!(Int16::to_byte(255), content="b'\\xFF'")
  inspect!(Int16::to_byte(-256), content="b'\\x00'")
  inspect!(Int16::to_byte(256), content="b'\\x00'")
  inspect!(Int16::to_byte(-257), content="b'\\xFF'")
}

///|
test "Int16::from_byte" {
  inspect!(Byte::to_int16(0), content="0")
  inspect!(Byte::to_int16(123), content="123")
  inspect!(Byte::to_int16(255), content="255")
}

///|
test "Int16::to_int64" {
  inspect!(Int16::to_int64(0), content="0")
  inspect!(Int16::to_int64(123), content="123")
  inspect!(Int16::to_int64(-123), content="-123")
  inspect!(Int16::to_int64(32767), content="32767")
  inspect!(Int16::to_int64(-32768), content="-32768")
}

///|
test "Int16::from_int64" {
  inspect!(Int::to_int16(0), content="0")
  inspect!(Int::to_int16(123), content="123")
  inspect!(Int::to_int16(-123), content="-123")
  inspect!(Int::to_int16(32767), content="32767")
  inspect!(Int::to_int16(-32768), content="-32768")
  inspect!(Int::to_int16(32768), content="-32768")
  inspect!(Int::to_int16(-32769), content="32767")
  inspect!(Int::to_int16(65535), content="-1")
  inspect!(Int::to_int16(-65536), content="0")
  inspect!(Int::to_int16(65536), content="0")
}

///|
test "Int16::op_add" {
  fn add(a : Int16, b : Int16) -> Int16 {
    a + b
  }

  inspect!(add(1, 2), content="3")
  inspect!(add(0, 0), content="0")
  inspect!(add(32767, 1), content="-32768") // Overflow case
  inspect!(add(-32768, -1), content="32767") // Underflow case
  inspect!(add(16384, 16384), content="-32768") // Large positive numbers
  inspect!(add(-16384, -16384), content="-32768") // Large negative numbers
  inspect!(add(10000, -10000), content="0") // Positive + negative
  inspect!(add(-10000, 10000), content="0") // Negative + positive
  inspect!(add(32767, -32768), content="-1") // Max + min
  inspect!(add(-32768, 32767), content="-1") // Min + max
  inspect!(add(16000, 16000), content="32000") // Overflow in middle range
  inspect!(add(-16000, -16000), content="-32000") // Underflow in middle range
}

///|
test "Int16::op_sub" {
  fn sub(a : Int16, b : Int16) -> Int16 {
    a - b
  }

  inspect!(sub(3, 2), content="1")
  inspect!(sub(0, 0), content="0")
  inspect!(sub(-32768, 1), content="32767") // Underflow case
  inspect!(sub(32767, -1), content="-32768") // Overflow case
  inspect!(sub(16384, -16384), content="-32768") // Large positive difference
  inspect!(sub(-16384, 16384), content="-32768") // Large negative difference
  inspect!(sub(10000, 10000), content="0") // Same numbers
  inspect!(sub(-10000, -10000), content="0") // Same negative numbers
  inspect!(sub(32767, 32767), content="0") // Max - max
  inspect!(sub(-32768, -32768), content="0") // Min - min
  inspect!(sub(0, 32767), content="-32767") // Zero - max
  inspect!(sub(0, -32768), content="-32768") // Zero - min
}

///|
test "Int16::op_mul" {
  fn mul(a : Int16, b : Int16) -> Int16 {
    a * b
  }

  inspect!(mul(0, 0), content="0")
  inspect!(mul(1, 1), content="1")
  inspect!(mul(-1, -1), content="1")
  inspect!(mul(-1, 1), content="-1")
  inspect!(mul(2, 3), content="6")
  inspect!(mul(-2, 3), content="-6")
  inspect!(mul(181, 181), content="32761") // Near max positive result
  inspect!(mul(182, 182), content="-32412") // Overflow case
  inspect!(mul(-181, -181), content="32761") // Near max from negatives
  inspect!(mul(-182, 181), content="32594") // Mixed signs overflow
  inspect!(mul(16384, 2), content="-32768") // Power of 2 overflow
  inspect!(mul(-32768, 1), content="-32768") // Min value * 1
  inspect!(mul(32767, 1), content="32767") // Max value * 1
  inspect!(mul(16383, 2), content="32766") // Just below overflow
}

///|
test "Int16::op_div" {
  fn div(a : Int16, b : Int16) -> Int16 {
    a / b
  }

  inspect!(div(6, 2), content="3")
  inspect!(div(0, 1), content="0")
  inspect!(div(1, 1), content="1")
  inspect!(div(-1, -1), content="1")
  inspect!(div(-1, 1), content="-1")
  inspect!(div(32767, 1), content="32767") // Max value / 1
  inspect!(div(-32768, 1), content="-32768") // Min value / 1
  inspect!(div(-32768, -1), content="-32768") // Min value / -1 (overflow)
  inspect!(div(32767, -1), content="-32767") // Max value / -1
  inspect!(div(12345, 123), content="100") // Larger numbers
  inspect!(div(-12345, 123), content="-100") // Negative dividend
  inspect!(div(12345, -123), content="-100") // Negative divisor
  inspect!(div(-12345, -123), content="100") // Both negative
  inspect!(div(32766, 2), content="16383") // Even division near max
  inspect!(div(-32768, 2), content="-16384") // Even division of min
}

///|
test "Int16::compare" {
  inspect!(Int16::compare(1, 2), content="-1")
  inspect!(Int16::compare(2, 1), content="1")
  inspect!(Int16::compare(1, 1), content="0")
  inspect!(Int16::compare(-1, 1), content="-1")
  inspect!(Int16::compare(1, -1), content="1")
  inspect!(Int16::compare(-1, -1), content="0")
  inspect!(Int16::compare(-2, -1), content="-1")
  inspect!(Int16::compare(-1, -2), content="1")
  inspect!(Int16::compare(32767, 32766), content="1") // Max value comparison
  inspect!(Int16::compare(32766, 32767), content="-1")
  inspect!(Int16::compare(32767, 32767), content="0") // Max value equals
  inspect!(Int16::compare(-32768, -32767), content="-1") // Min value comparison
  inspect!(Int16::compare(-32767, -32768), content="1")
  inspect!(Int16::compare(-32768, -32768), content="0") // Min value equals
  inspect!(Int16::compare(-32768, 32767), content="-1") // Min vs Max
  inspect!(Int16::compare(32767, -32768), content="1") // Max vs Min
  inspect!(Int16::compare(0, 32767), content="-1") // Zero vs Max
  inspect!(Int16::compare(0, -32768), content="1") // Zero vs Min
  inspect!(Int16::compare(0, 0), content="0") // Zero equals
}

///|
test "Int16::hash" {
  inspect!(Int16::hash(1), content="1")
  inspect!(Int16::hash(-1), content="-1")
  inspect!(Int16::hash(32767), content="32767")
  inspect!(Int16::hash(-32768), content="-32768")
  inspect!(Int16::hash(0), content="0")
  inspect!(Int16::hash(12345), content="12345")
  inspect!(Int16::hash(-12345), content="-12345")
}

///|
test "Int16::op_equal" {
  inspect!(Int16::op_equal(1, 2), content="false")
  inspect!(Int16::op_equal(2, 1), content="false")
  inspect!(Int16::op_equal(1, 1), content="true")
  inspect!(Int16::op_equal(-1, 1), content="false")
  inspect!(Int16::op_equal(1, -1), content="false")
  inspect!(Int16::op_equal(-1, -1), content="true")
}
