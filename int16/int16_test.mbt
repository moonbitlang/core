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
test "Int16::to_int" {
  inspect(Int16::to_int(0), content="0")
  inspect(Int16::to_int(123), content="123")
  inspect(Int16::to_int(-123), content="-123")
  inspect(Int16::to_int(32767), content="32767")
  inspect(Int16::to_int(-32768), content="-32768")
}

///|
test "Int16::from_int" {
  inspect(Int16::from_int(0), content="0")
  inspect(Int16::from_int(123), content="123")
  inspect(Int16::from_int(-123), content="-123")
  inspect(Int16::from_int(32767), content="32767")
  inspect(Int16::from_int(-32768), content="-32768")
  inspect(Int16::from_int(32768), content="-32768")
  inspect(Int16::from_int(-32769), content="32767")
  inspect(Int16::from_int(65535), content="-1")
  inspect(Int16::from_int(-65536), content="0")
  inspect(Int16::from_int(65536), content="0")
}

///|
test "Int16::to_byte" {
  inspect(Int16::to_byte(0), content="b'\\x00'")
  inspect(Int16::to_byte(123), content="b'\\x7B'")
  inspect(Int16::to_byte(-123), content="b'\\x85'")
  inspect(Int16::to_byte(255), content="b'\\xFF'")
  inspect(Int16::to_byte(-256), content="b'\\x00'")
  inspect(Int16::to_byte(256), content="b'\\x00'")
  inspect(Int16::to_byte(-257), content="b'\\xFF'")
}

///|
test "Int16::from_byte" {
  inspect(Int16::from_byte(0), content="0")
  inspect(Int16::from_byte(123), content="123")
  inspect(Int16::from_byte(255), content="255")
}

///|
test "Int16::to_int64" {
  inspect(Int16::to_int64(0), content="0")
  inspect(Int16::to_int64(123), content="123")
  inspect(Int16::to_int64(-123), content="-123")
  inspect(Int16::to_int64(32767), content="32767")
  inspect(Int16::to_int64(-32768), content="-32768")
}

///|
test "Int16::from_int64" {
  inspect(Int16::from_int64(0), content="0")
  inspect(Int16::from_int64(123), content="123")
  inspect(Int16::from_int64(-123), content="-123")
  inspect(Int16::from_int64(32767), content="32767")
  inspect(Int16::from_int64(-32768), content="-32768")
  inspect(Int16::from_int64(32768), content="-32768")
  inspect(Int16::from_int64(-32769), content="32767")
  inspect(Int16::from_int64(65535), content="-1")
  inspect(Int16::from_int64(-65536), content="0")
  inspect(Int16::from_int64(65536), content="0")
}

///|
test "Int16::add" {
  let add = (a : Int16, b : Int16) => a + b
  inspect(add(1, 2), content="3")
  inspect(add(0, 0), content="0")
  inspect(add(32767, 1), content="-32768") // Overflow case
  inspect(add(-32768, -1), content="32767") // Underflow case
  inspect(add(16384, 16384), content="-32768") // Large positive numbers
  inspect(add(-16384, -16384), content="-32768") // Large negative numbers
  inspect(add(10000, -10000), content="0") // Positive + negative
  inspect(add(-10000, 10000), content="0") // Negative + positive
  inspect(add(32767, -32768), content="-1") // Max + min
  inspect(add(-32768, 32767), content="-1") // Min + max
  inspect(add(16000, 16000), content="32000") // Overflow in middle range
  inspect(add(-16000, -16000), content="-32000") // Underflow in middle range
}

///|
test "Int16::sub" {
  let sub = (a : Int16, b : Int16) => a - b
  inspect(sub(3, 2), content="1")
  inspect(sub(0, 0), content="0")
  inspect(sub(-32768, 1), content="32767") // Underflow case
  inspect(sub(32767, -1), content="-32768") // Overflow case
  inspect(sub(16384, -16384), content="-32768") // Large positive difference
  inspect(sub(-16384, 16384), content="-32768") // Large negative difference
  inspect(sub(10000, 10000), content="0") // Same numbers
  inspect(sub(-10000, -10000), content="0") // Same negative numbers
  inspect(sub(32767, 32767), content="0") // Max - max
  inspect(sub(-32768, -32768), content="0") // Min - min
  inspect(sub(0, 32767), content="-32767") // Zero - max
  inspect(sub(0, -32768), content="-32768") // Zero - min
}

///|
test "Int16::mul" {
  let mul = (a : Int16, b : Int16) => a * b
  inspect(mul(0, 0), content="0")
  inspect(mul(1, 1), content="1")
  inspect(mul(-1, -1), content="1")
  inspect(mul(-1, 1), content="-1")
  inspect(mul(2, 3), content="6")
  inspect(mul(-2, 3), content="-6")
  inspect(mul(181, 181), content="32761") // Near max positive result
  inspect(mul(182, 182), content="-32412") // Overflow case
  inspect(mul(-181, -181), content="32761") // Near max from negatives
  inspect(mul(-182, 181), content="32594") // Mixed signs overflow
  inspect(mul(16384, 2), content="-32768") // Power of 2 overflow
  inspect(mul(-32768, 1), content="-32768") // Min value * 1
  inspect(mul(32767, 1), content="32767") // Max value * 1
  inspect(mul(16383, 2), content="32766") // Just below overflow
}

///|
test "Int16::div" {
  let div = (a : Int16, b : Int16) => a / b
  inspect(div(6, 2), content="3")
  inspect(div(0, 1), content="0")
  inspect(div(1, 1), content="1")
  inspect(div(-1, -1), content="1")
  inspect(div(-1, 1), content="-1")
  inspect(div(32767, 1), content="32767") // Max value / 1
  inspect(div(-32768, 1), content="-32768") // Min value / 1
  // inspect(div(-32768, -1), content="-32768") // Min value / -1 (this is a UB, overflow)
  inspect(div(32767, -1), content="-32767") // Max value / -1
  inspect(div(12345, 123), content="100") // Larger numbers
  inspect(div(-12345, 123), content="-100") // Negative dividend
  inspect(div(12345, -123), content="-100") // Negative divisor
  inspect(div(-12345, -123), content="100") // Both negative
  inspect(div(32766, 2), content="16383") // Even division near max
  inspect(div(-32768, 2), content="-16384") // Even division of min
}

///|
test "Int16::compare" {
  inspect(Int16::compare(1, 2), content="-1")
  inspect(Int16::compare(2, 1), content="1")
  inspect(Int16::compare(1, 1), content="0")
  inspect(Int16::compare(-1, 1), content="-1")
  inspect(Int16::compare(1, -1), content="1")
  inspect(Int16::compare(-1, -1), content="0")
  inspect(Int16::compare(-2, -1), content="-1")
  inspect(Int16::compare(-1, -2), content="1")
  inspect(Int16::compare(32767, 32766), content="1") // Max value comparison
  inspect(Int16::compare(32766, 32767), content="-1")
  inspect(Int16::compare(32767, 32767), content="0") // Max value equals
  inspect(Int16::compare(-32768, -32767), content="-1") // Min value comparison
  inspect(Int16::compare(-32767, -32768), content="1")
  inspect(Int16::compare(-32768, -32768), content="0") // Min value equals
  inspect(Int16::compare(-32768, 32767), content="-1") // Min vs Max
  inspect(Int16::compare(32767, -32768), content="1") // Max vs Min
  inspect(Int16::compare(0, 32767), content="-1") // Zero vs Max
  inspect(Int16::compare(0, -32768), content="1") // Zero vs Min
  inspect(Int16::compare(0, 0), content="0") // Zero equals
}

///|
test "Int16::hash" {
  inspect(Hasher::new(seed=0)..combine(1).finalize(), content="-205818221")
  inspect(Hasher::new(seed=0)..combine(-1).finalize(), content="67608159")
  inspect(Hasher::new(seed=0)..combine(32767).finalize(), content="929308064")
  inspect(Hasher::new(seed=0)..combine(-32768).finalize(), content="-841328155")
  inspect(Hasher::new(seed=0)..combine(0).finalize(), content="148298089")
  inspect(Hasher::new(seed=0)..combine(12345).finalize(), content="-393624961")
  inspect(Hasher::new(seed=0)..combine(-12345).finalize(), content="1221658118")
}

///|
test "Int16::equal" {
  inspect(Int16::equal(1, 2), content="false")
  inspect(Int16::equal(2, 1), content="false")
  inspect(Int16::equal(1, 1), content="true")
  inspect(Int16::equal(-1, 1), content="false")
  inspect(Int16::equal(1, -1), content="false")
  inspect(Int16::equal(-1, -1), content="true")
}

///|
test "Int16::shl" {
  let shl = (a : Int16, b : Int) => a << b
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
  inspect(shl(1, 15), content="-32768")
  inspect(shl(1, 16), content="0")
  inspect(shl(-1, 0), content="-1")
  inspect(shl(-1, 1), content="-2")
  inspect(shl(-1, 2), content="-4")
  inspect(shl(-1, 3), content="-8")
  inspect(shl(-1, 4), content="-16")
  inspect(shl(-1, 5), content="-32")
  inspect(shl(-1, 6), content="-64")
  inspect(shl(-1, 7), content="-128")
  inspect(shl(-1, 8), content="-256")
  inspect(shl(-1, 9), content="-512")
  inspect(shl(-1, 10), content="-1024")
  inspect(shl(-1, 11), content="-2048")
  inspect(shl(-1, 12), content="-4096")
  inspect(shl(-1, 13), content="-8192")
  inspect(shl(-1, 14), content="-16384")
  inspect(shl(-1, 15), content="-32768")
  inspect(shl(-1, 16), content="0")
  inspect(shl(32767, 0), content="32767")
  inspect(shl(32767, 1), content="-2")
  inspect(shl(32767, 2), content="-4")
  inspect(shl(32767, 3), content="-8")
  inspect(shl(32767, 4), content="-16")
  inspect(shl(32767, 5), content="-32")
  inspect(shl(32767, 6), content="-64")
  inspect(shl(32767, 7), content="-128")
  inspect(shl(32767, 8), content="-256")
  inspect(shl(32767, 9), content="-512")
  inspect(shl(32767, 10), content="-1024")
  inspect(shl(32767, 11), content="-2048")
  inspect(shl(32767, 12), content="-4096")
  inspect(shl(32767, 13), content="-8192")
  inspect(shl(32767, 14), content="-16384")
  inspect(shl(32767, 15), content="-32768")
  inspect(shl(32767, 16), content="0")
  inspect(shl(-32768, 0), content="-32768")
  inspect(shl(-32768, 1), content="0")
}

///|
test "Int16::shr" {
  let shr = (a : Int16, b : Int) => a >> b
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
  inspect(shr(-1, 0), content="-1")
  inspect(shr(-2, 1), content="-1")
  inspect(shr(-4, 2), content="-1")
  inspect(shr(-8, 3), content="-1")
  inspect(shr(-16, 4), content="-1")
  inspect(shr(-32, 5), content="-1")
  inspect(shr(-64, 6), content="-1")
  inspect(shr(-128, 7), content="-1")
  inspect(shr(-256, 8), content="-1")
  inspect(shr(-512, 9), content="-1")
  inspect(shr(-1024, 10), content="-1")
  inspect(shr(-2048, 11), content="-1")
  inspect(shr(-4096, 12), content="-1")
  inspect(shr(-8192, 13), content="-1")
  inspect(shr(-16384, 14), content="-1")
  inspect(shr(-32768, 15), content="-1")
  inspect(shr(32767, 0), content="32767")
  inspect(shr(-32768, 0), content="-32768")
  inspect(shr(32767, 1), content="16383")
  inspect(shr(32767, 2), content="8191")
  inspect(shr(32767, 3), content="4095")
  inspect(shr(32767, 4), content="2047")
  inspect(shr(32767, 5), content="1023")
  inspect(shr(32767, 6), content="511")
  inspect(shr(32767, 7), content="255")
  inspect(shr(32767, 8), content="127")
  inspect(shr(32767, 9), content="63")
  inspect(shr(32767, 10), content="31")
  inspect(shr(32767, 11), content="15")
  inspect(shr(32767, 12), content="7")
  inspect(shr(32767, 13), content="3")
  inspect(shr(32767, 14), content="1")
  inspect(shr(32767, 15), content="0")
  inspect(shr(-32768, 1), content="-16384")
  inspect(shr(-32768, 2), content="-8192")
  inspect(shr(-32768, 3), content="-4096")
  inspect(shr(-32768, 4), content="-2048")
  inspect(shr(-32768, 5), content="-1024")
  inspect(shr(-32768, 6), content="-512")
  inspect(shr(-32768, 7), content="-256")
  inspect(shr(-32768, 8), content="-128")
  inspect(shr(-32768, 9), content="-64")
  inspect(shr(-32768, 10), content="-32")
  inspect(shr(-32768, 11), content="-16")
  inspect(shr(-32768, 12), content="-8")
  inspect(shr(-32768, 13), content="-4")
  inspect(shr(-32768, 14), content="-2")
  inspect(shr(-32768, 15), content="-1")
  inspect(shr(-32768, 16), content="-1")
  inspect(shr(32767, 16), content="0")
  inspect(shr(-32768, 16), content="-1")
  inspect(shr(0, 16), content="0")
}

///|
test "Int16::lor" {
  let lor = (a : Int16, b : Int16) => a | b
  inspect(lor(0, 0), content="0")
  inspect(lor(1, 0), content="1")
  inspect(lor(0, 1), content="1")
  inspect(lor(1, 1), content="1")
  inspect(lor(0, 32767), content="32767")
  inspect(lor(32767, 0), content="32767")
  inspect(lor(32767, 32767), content="32767")
  inspect(lor(-32768, -32768), content="-32768")
  inspect(lor(-32768, 32767), content="-1")
  inspect(lor(32767, -32768), content="-1")
  inspect(lor(32767, 16384), content="32767")
  inspect(lor(16384, 32767), content="32767")
  inspect(lor(1000, 2000), content="2040")
  inspect(lor(2000, 1000), content="2040")
  inspect(lor(-1000, -2000), content="-968")
  inspect(lor(-2000, -1000), content="-968")
}

///|
test "Int16::land" {
  let land = (a : Int16, b : Int16) => a & b
  inspect(land(0, 0), content="0")
  inspect(land(1, 0), content="0")
  inspect(land(0, 1), content="0")
  inspect(land(1, 1), content="1")
  inspect(land(0, 32767), content="0")
  inspect(land(32767, 0), content="0")
  inspect(land(32767, 32767), content="32767")
  inspect(land(-32768, -32768), content="-32768")
  inspect(land(-32768, 32767), content="0")
  inspect(land(32767, -32768), content="0")
  inspect(land(32767, 16384), content="16384")
  inspect(land(16384, 32767), content="16384")
  inspect(land(1000, 2000), content="960")
  inspect(land(2000, 1000), content="960")
  inspect(land(-1000, -2000), content="-2032")
  inspect(land(-2000, -1000), content="-2032")
}

///|
test "Int16::lxor" {
  let lxor = (a : Int16, b : Int16) => a ^ b
  inspect(lxor(0, 0), content="0")
  inspect(lxor(1, 0), content="1")
  inspect(lxor(0, 1), content="1")
  inspect(lxor(1, 1), content="0")
  inspect(lxor(32767, 32767), content="0")
  inspect(lxor(32767, 0), content="32767")
  inspect(lxor(0, 32767), content="32767")
}

///|
test "Int16::mod" {
  let mod = (a : Int16, b : Int16) => a % b
  inspect(mod(10, 3), content="1")
  inspect(mod(10, 2), content="0")
  inspect(mod(10, 10), content="0")
  inspect(mod(10, 11), content="10")
  inspect(mod(10, -3), content="1")
  inspect(mod(-10, 3), content="-1")
  inspect(mod(-10, -3), content="-1")
  inspect(mod(32767, 10000), content="2767")
  inspect(mod(32767, -10000), content="2767")
  inspect(mod(-32768, 10000), content="-2768")
  inspect(mod(-32768, -10000), content="-2768")
  inspect(mod(0, 1), content="0")
  inspect(mod(1, 1), content="0")
}

///|
test "Int16::neg" {
  let neg = (a : Int16) => -a
  inspect(neg(10), content="-10")
  inspect(neg(-10), content="10")
  inspect(neg(0), content="0")
  inspect(neg(32767), content="-32767")
  inspect(neg(-32768), content="-32768")
  assert_eq(neg(@int16.min_value), @int16.min_value)
}

///|
test "Int16::abs" {
  let abs = (a : Int16) => a.abs()
  inspect(abs(10), content="10")
  inspect(abs(-10), content="10")
  inspect(abs(0), content="0")
  inspect(abs(32767), content="32767")
  inspect(abs(-32768), content="-32768")
  assert_eq(abs(@int16.min_value), @int16.min_value)
}

///|
test "Int16::to_json" {
  inspect(Int16::to_json(0), content="Number(0)")
  inspect(Int16::to_json(1), content="Number(1)")
  inspect(Int16::to_json(32767), content="Number(32767)")
  inspect(Int16::to_json(-32768), content="Number(-32768)")
}

///|
test "Int16::reinterpret_as_uint16" {
  inspect((-1 : Int16).reinterpret_as_uint16(), content="65535")
  inspect((0 : Int16).reinterpret_as_uint16(), content="0")
  inspect((1 : Int16).reinterpret_as_uint16(), content="1")
}

///|
test "Show for Int16" {
  inspect((0 : Int16).to_string(), content="0")
  inspect((32767 : Int16).to_string(), content="32767")
  inspect((-32768 : Int16).to_string(), content="-32768")
  inspect((-32766 : Int16), content="-32766")
}

///|
test "Show for Int16 - hexadecimal (radix=16)" {
  inspect((0 : Int16).to_string(radix=16), content="0")
  inspect((15 : Int16).to_string(radix=16), content="f")
  inspect((16 : Int16).to_string(radix=16), content="10")
  inspect((255 : Int16).to_string(radix=16), content="ff")
  inspect((256 : Int16).to_string(radix=16), content="100")
  inspect((4095 : Int16).to_string(radix=16), content="fff")
  inspect((32767 : Int16).to_string(radix=16), content="7fff")
  inspect((-1 : Int16).to_string(radix=16), content="-1")
  inspect((-255 : Int16).to_string(radix=16), content="-ff")
  inspect((-32768 : Int16).to_string(radix=16), content="-8000")
}

///|
test "Show for Int16 - binary (radix=2)" {
  inspect((0 : Int16).to_string(radix=2), content="0")
  inspect((1 : Int16).to_string(radix=2), content="1")
  inspect((7 : Int16).to_string(radix=2), content="111")
  inspect((255 : Int16).to_string(radix=2), content="11111111")
  inspect((32767 : Int16).to_string(radix=2), content="111111111111111")
  inspect((-1 : Int16).to_string(radix=2), content="-1")
  inspect((-32768 : Int16).to_string(radix=2), content="-1000000000000000")
}

///|
test "Show for Int16 - octal (radix=8)" {
  inspect((0 : Int16).to_string(radix=8), content="0")
  inspect((7 : Int16).to_string(radix=8), content="7")
  inspect((8 : Int16).to_string(radix=8), content="10")
  inspect((511 : Int16).to_string(radix=8), content="777")
  inspect((32767 : Int16).to_string(radix=8), content="77777")
  inspect((-8 : Int16).to_string(radix=8), content="-10")
  inspect((-32768 : Int16).to_string(radix=8), content="-100000")
}

///|
test "Show for Int16 - base 36 (radix=36)" {
  inspect((0 : Int16).to_string(radix=36), content="0")
  inspect((35 : Int16).to_string(radix=36), content="z")
  inspect((36 : Int16).to_string(radix=36), content="10")
  inspect((1295 : Int16).to_string(radix=36), content="zz")
  inspect((32767 : Int16).to_string(radix=36), content="pa7")
  inspect((-36 : Int16).to_string(radix=36), content="-10")
  inspect((-32768 : Int16).to_string(radix=36), content="-pa8")
}

///|
test "Int16 not_equal and hash" {
  inspect(Eq::not_equal((1 : Int16), (2 : Int16)), content="true")
  let hasher = Hasher::new(seed=0)
  hasher.combine((42 : Int16))
  inspect(hasher.finalize() != 0, content="true")
}

///|
test "Int16 int64 conversions" {
  let val : Int16 = (123 : Int16)
  let as64 = val.to_int64()
  let back = Int16::from_int64(as64)
  inspect(back.to_int(), content="123")
}
