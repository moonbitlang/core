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
test "UInt16 surrogate checks" {
  let leading = UInt16(0xD800)
  let trailing = UInt16(0xDFFF)
  let normal = UInt16(0x0041)
  inspect(leading.is_leading_surrogate(), content="true")
  inspect(trailing.is_trailing_surrogate(), content="true")
  inspect(leading.is_surrogate(), content="true")
  inspect(trailing.is_surrogate(), content="true")
  inspect(normal.is_surrogate(), content="false")
}

///|
test "UInt16 to_char" {
  let a = UInt16('A')
  assert_true(a.to_char() is Some('A'))
  inspect(a.to_char().unwrap(), content="A")
  assert_true(UInt16(0xD800).to_char() is None)
}

///|
test "UInt16 arithmetic and bit ops" {
  let a = UInt16(0x0010)
  let b = UInt16(0x0003)
  inspect((a + b).to_int(), content="19")
  inspect((a - b).to_int(), content="13")
  inspect((a * b).to_int(), content="48")
  inspect((a / b).to_int(), content="5")
  inspect((a % b).to_int(), content="1")
  inspect((a << 1).to_int(), content="32")
  inspect((a >> 2).to_int(), content="4")
  inspect((a | b).to_int(), content="19")
  inspect((a & b).to_int(), content="0")
  inspect((a ^ b).to_int(), content="19")
  inspect(a.lnot().to_int(), content="65519")
  inspect(UInt16(0x0000).lnot().to_int(), content="65535")
  inspect(UInt16(0xFFFF).lnot().to_int(), content="0")
  inspect(a.lnot().lnot().to_int(), content="16")
  inspect(a == b, content="false")
  inspect(a != b, content="true")
}

///|
test "UInt16 compare and conversions" {
  let a = UInt16(0x0010)
  let b = UInt16(0x000F)
  inspect(a.compare(b), content="1")
  inspect(b.compare(a), content="-1")
  inspect(a.to_uint(), content="16")
  inspect(a.to_uint64(), content="16")
  inspect((Default::default() : UInt16).to_int(), content="0")
  @json.json_inspect(@json.ToJson::to_json(a), content=16)
}

///|
test "UInt16 hash combine" {
  let hasher = Hasher(seed=0)
  hasher.combine(UInt16(0x00FF))
  inspect(hasher.finalize() != 0, content="true")
}

///|
test "UInt16 not_equal" {
  inspect(Eq::not_equal(UInt16(0x0001), UInt16(0x0002)), content="true")
}

///|
/// Reference bit counts over the low `width` bits, one bit at a time.
fn naive_bit_counts(x : Int32, width : Int32) -> (Int32, Int32, Int32) {
  let mut clz = 0
  for i = width - 1; i >= 0 && ((x >> i) & 1) == 0; i = i - 1 {
    clz += 1
  }
  let mut ctz = 0
  while ctz < width && ((x >> ctz) & 1) == 0 {
    ctz += 1
  }
  let mut popcnt = 0
  for i in 0..<width {
    popcnt += (x >> i) & 1
  }
  (clz, ctz, popcnt)
}

///|
test "UInt16 clz/ctz/popcnt match a bitwise reference for every value" {
  for i in 0..<65536 {
    let x = i.to_uint16()
    assert_eq((x.clz(), x.ctz(), x.popcnt()), naive_bit_counts(i, 16))
  }
}

///|
test "Byte clz/ctz/popcnt match a bitwise reference for every value" {
  for i in 0..<256 {
    let x = i.to_byte()
    assert_eq((x.clz(), x.ctz(), x.popcnt()), naive_bit_counts(i, 8))
  }
}

///|
test "UInt16 to_double, min, max, clamp" {
  for i in [0, 1, 255, 32767, 32768, 65535] {
    assert_eq(i.to_uint16().to_double(), i.to_double())
  }
  inspect(UInt16(65535).min(UInt16(32768)), content="32768")
  inspect(UInt16(65535).max(UInt16(32768)), content="65535")
  inspect(UInt16(7).clamp(min=UInt16(7), max=UInt16(7)), content="7")
  inspect(
    UInt16(65535).clamp(min=UInt16(0), max=UInt16(65534)),
    content="65534",
  )
}

///|
test "Byte min, max, clamp compare unsigned" {
  inspect(b'\x80'.min(b'\x7F').to_int(), content="127")
  inspect(b'\x80'.max(b'\x7F').to_int(), content="128")
  inspect(b'\xFF'.clamp(min=b'\x80', max=b'\xFE').to_int(), content="254")
}

///|
test "Bool to_byte" {
  inspect(true.to_byte(), content="b'\\x01'")
  inspect(false.to_byte(), content="b'\\x00'")
}
