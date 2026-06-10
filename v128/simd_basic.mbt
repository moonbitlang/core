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
pub impl Eq for V128 with fn equal(self : V128, other : V128) -> Bool {
  lo(self) == lo(other) && hi(self) == hi(other)
}

///|
pub impl Eq for V128 with fn not_equal(self : V128, other : V128) -> Bool {
  lo(self) != lo(other) || hi(self) != hi(other)
}

///|
fn u64_hex(value : UInt64) -> String {
  let digits = value.to_string(radix=16)
  let buf = StringBuilder::new()
  buf.write_string("0x")
  for _ in digits.length()..<16 {
    buf.write_char('0')
  }
  buf.write_string(digits)
  buf.to_string()
}

///|
/// Prints the two 64-bit words in zero-padded hex so every byte lane is
/// visible; lane 0 is the lowest byte of the first word.
pub impl Show for V128 with fn output(self : V128, logger) {
  logger.write_string("V128(")
  logger.write_string(u64_hex(lo(self)))
  logger.write_string(", ")
  logger.write_string(u64_hex(hi(self)))
  logger.write_string(")")
}

///|
/// Shows the two 64-bit words in the same zero-padded hex form as `Show`.
pub impl @debug.Debug for V128 with fn to_repr(self) {
  @debug.Repr::opaque_(
    "V128",
    @debug.Repr::tuple([
      @debug.Repr::literal(u64_hex(lo(self))),
      @debug.Repr::literal(u64_hex(hi(self))),
    ]),
  )
}

///|
pub fn i8x16_const(
  a0 : Byte,
  a1 : Byte,
  a2 : Byte,
  a3 : Byte,
  a4 : Byte,
  a5 : Byte,
  a6 : Byte,
  a7 : Byte,
  a8 : Byte,
  a9 : Byte,
  a10 : Byte,
  a11 : Byte,
  a12 : Byte,
  a13 : Byte,
  a14 : Byte,
  a15 : Byte,
) -> V128 {
  make(
    a0.to_uint64() |
    (a1.to_uint64() << 8) |
    (a2.to_uint64() << 16) |
    (a3.to_uint64() << 24) |
    (a4.to_uint64() << 32) |
    (a5.to_uint64() << 40) |
    (a6.to_uint64() << 48) |
    (a7.to_uint64() << 56),
    a8.to_uint64() |
    (a9.to_uint64() << 8) |
    (a10.to_uint64() << 16) |
    (a11.to_uint64() << 24) |
    (a12.to_uint64() << 32) |
    (a13.to_uint64() << 40) |
    (a14.to_uint64() << 48) |
    (a15.to_uint64() << 56),
  )
}

///|
pub fn i16x8_const(
  a0 : UInt16,
  a1 : UInt16,
  a2 : UInt16,
  a3 : UInt16,
  a4 : UInt16,
  a5 : UInt16,
  a6 : UInt16,
  a7 : UInt16,
) -> V128 {
  make(
    a0.to_uint64() |
    (a1.to_uint64() << 16) |
    (a2.to_uint64() << 32) |
    (a3.to_uint64() << 48),
    a4.to_uint64() |
    (a5.to_uint64() << 16) |
    (a6.to_uint64() << 32) |
    (a7.to_uint64() << 48),
  )
}

///|
pub fn i32x4_const(a0 : UInt, a1 : UInt, a2 : UInt, a3 : UInt) -> V128 {
  make(
    a0.to_uint64() | (a1.to_uint64() << 32),
    a2.to_uint64() | (a3.to_uint64() << 32),
  )
}

///|
pub fn i64x2_const(a0 : UInt64, a1 : UInt64) -> V128 {
  make(a0, a1)
}

///|
pub fn f32x4_const(a0 : Float, a1 : Float, a2 : Float, a3 : Float) -> V128 {
  i32x4_const(
    a0.reinterpret_as_uint(),
    a1.reinterpret_as_uint(),
    a2.reinterpret_as_uint(),
    a3.reinterpret_as_uint(),
  )
}

///|
pub fn f64x2_const(a0 : Double, a1 : Double) -> V128 {
  i64x2_const(a0.reinterpret_as_uint64(), a1.reinterpret_as_uint64())
}

///|
pub fn i8x16_splat(value : Byte) -> V128 {
  pack_u8x16_by(_ => value)
}

///|
pub fn i16x8_splat(value : UInt16) -> V128 {
  pack_u16x8_by(_ => value)
}

///|
pub fn i32x4_splat(value : UInt) -> V128 {
  pack_u32x4_by(_ => value)
}

///|
pub fn i64x2_splat(value : UInt64) -> V128 {
  make(value, value)
}

///|
pub fn f32x4_splat(value : Float) -> V128 {
  f32x4_const(value, value, value, value)
}

///|
pub fn f64x2_splat(value : Double) -> V128 {
  f64x2_const(value, value)
}

///|
pub fn i8x16_extract_lane_u(value : V128, lane : Int) -> UInt {
  u8_lane(value, lane).to_uint()
}

///|
pub fn i8x16_extract_lane_s(value : V128, lane : Int) -> UInt {
  i8_signed(u8_lane(value, lane)).reinterpret_as_uint()
}

///|
pub fn i16x8_extract_lane_u(value : V128, lane : Int) -> UInt {
  u16_lane(value, lane).to_uint()
}

///|
pub fn i16x8_extract_lane_s(value : V128, lane : Int) -> UInt {
  i16_signed(u16_lane(value, lane)).reinterpret_as_uint()
}

///|
pub fn i32x4_extract_lane(value : V128, lane : Int) -> UInt {
  u32_lane(value, lane)
}

///|
pub fn i64x2_extract_lane(value : V128, lane : Int) -> UInt64 {
  u64_lane(value, lane)
}

///|
pub fn f32x4_extract_lane(value : V128, lane : Int) -> Float {
  Float::reinterpret_from_uint(u32_lane(value, lane))
}

///|
pub fn f64x2_extract_lane(value : V128, lane : Int) -> Double {
  u64_lane(value, lane).reinterpret_as_double()
}

///|
pub fn i8x16_replace_lane(value : V128, lane : Int, replacement : UInt) -> V128 {
  pack_u8x16_by(i => {
    if i == lane {
      replacement.to_byte()
    } else {
      u8_lane(value, i)
    }
  })
}

///|
pub fn i16x8_replace_lane(value : V128, lane : Int, replacement : UInt) -> V128 {
  pack_u16x8_by(i => {
    if i == lane {
      replacement.to_uint16()
    } else {
      u16_lane(value, i)
    }
  })
}

///|
pub fn i32x4_replace_lane(value : V128, lane : Int, replacement : UInt) -> V128 {
  pack_u32x4_by(i => if i == lane { replacement } else { u32_lane(value, i) })
}

///|
pub fn i64x2_replace_lane(
  value : V128,
  lane : Int,
  replacement : UInt64,
) -> V128 {
  pack_u64x2_by(i => if i == lane { replacement } else { u64_lane(value, i) })
}

///|
pub fn f32x4_replace_lane(
  value : V128,
  lane : Int,
  replacement : Float,
) -> V128 {
  i32x4_replace_lane(value, lane, replacement.reinterpret_as_uint())
}

///|
pub fn f64x2_replace_lane(
  value : V128,
  lane : Int,
  replacement : Double,
) -> V128 {
  i64x2_replace_lane(value, lane, replacement.reinterpret_as_uint64())
}

///|
pub fn v128_not(value : V128) -> V128 {
  make(lo(value).lnot(), hi(value).lnot())
}

///|
pub fn v128_and_(value : V128, other : V128) -> V128 {
  make(lo(value) & lo(other), hi(value) & hi(other))
}

///|
pub fn v128_or_(value : V128, other : V128) -> V128 {
  make(lo(value) | lo(other), hi(value) | hi(other))
}

///|
pub fn v128_xor(value : V128, other : V128) -> V128 {
  make(lo(value) ^ lo(other), hi(value) ^ hi(other))
}

///|
pub fn v128_andnot(value : V128, other : V128) -> V128 {
  v128_and_(value, v128_not(other))
}

///|
pub fn v128_bitselect(value : V128, other : V128, mask : V128) -> V128 {
  v128_or_(v128_and_(value, mask), v128_andnot(other, mask))
}

///|
pub fn v128_any_true(value : V128) -> Bool {
  lo(value) != 0UL || hi(value) != 0UL
}
