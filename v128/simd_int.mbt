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
pub impl Show for V128 with fn output(self : V128, logger) {
  logger.write_string("V128(")
  logger.write_string(lo(self).to_string())
  logger.write_string(", ")
  logger.write_string(hi(self).to_string())
  logger.write_string(")")
}

///|
pub fn v128_eq(value : V128, other : V128) -> Bool {
  value == other
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

///|
pub fn i8x16_add(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => u8_lane(value, i) + u8_lane(other, i))
}

///|
pub fn i8x16_sub(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => u8_lane(value, i) - u8_lane(other, i))
}

///|
pub fn i8x16_add_sat_s(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => i8_add_sat_s(u8_lane(value, i), u8_lane(other, i)))
}

///|
pub fn i8x16_add_sat_u(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => i8_add_sat_u(u8_lane(value, i), u8_lane(other, i)))
}

///|
pub fn i8x16_sub_sat_s(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => i8_sub_sat_s(u8_lane(value, i), u8_lane(other, i)))
}

///|
pub fn i8x16_sub_sat_u(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => i8_sub_sat_u(u8_lane(value, i), u8_lane(other, i)))
}

///|
pub fn i8x16_neg(value : V128) -> V128 {
  pack_u8x16_by(i => (0 : Byte) - u8_lane(value, i))
}

///|
pub fn i8x16_abs(value : V128) -> V128 {
  pack_u8x16_by(i => i8_abs(u8_lane(value, i)))
}

///|
pub fn i8x16_min_s(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => i8_min_s(u8_lane(value, i), u8_lane(other, i)))
}

///|
pub fn i8x16_min_u(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => {
    if u8_lane(value, i) < u8_lane(other, i) {
      u8_lane(value, i)
    } else {
      u8_lane(other, i)
    }
  })
}

///|
pub fn i8x16_max_s(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => i8_max_s(u8_lane(value, i), u8_lane(other, i)))
}

///|
pub fn i8x16_max_u(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => {
    if u8_lane(value, i) > u8_lane(other, i) {
      u8_lane(value, i)
    } else {
      u8_lane(other, i)
    }
  })
}

///|
pub fn i8x16_avgr_u(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => i8_avgr_u(u8_lane(value, i), u8_lane(other, i)))
}

///|
pub fn i8x16_popcnt(value : V128) -> V128 {
  pack_u8x16_by(i => u8_lane(value, i).to_uint().popcnt().to_byte())
}

///|
pub fn i16x8_add(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => u16_lane(value, i) + u16_lane(other, i))
}

///|
pub fn i16x8_sub(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => u16_lane(value, i) - u16_lane(other, i))
}

///|
pub fn i16x8_add_sat_s(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => i16_add_sat_s(u16_lane(value, i), u16_lane(other, i)))
}

///|
pub fn i16x8_add_sat_u(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => i16_add_sat_u(u16_lane(value, i), u16_lane(other, i)))
}

///|
pub fn i16x8_sub_sat_s(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => i16_sub_sat_s(u16_lane(value, i), u16_lane(other, i)))
}

///|
pub fn i16x8_sub_sat_u(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => i16_sub_sat_u(u16_lane(value, i), u16_lane(other, i)))
}

///|
pub fn i16x8_mul(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => u16_lane(value, i) * u16_lane(other, i))
}

///|
pub fn i16x8_neg(value : V128) -> V128 {
  pack_u16x8_by(i => (0 : UInt16) - u16_lane(value, i))
}

///|
pub fn i16x8_abs(value : V128) -> V128 {
  pack_u16x8_by(i => i16_abs(u16_lane(value, i)))
}

///|
pub fn i16x8_min_s(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => i16_min_s(u16_lane(value, i), u16_lane(other, i)))
}

///|
pub fn i16x8_min_u(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => {
    if u16_lane(value, i) < u16_lane(other, i) {
      u16_lane(value, i)
    } else {
      u16_lane(other, i)
    }
  })
}

///|
pub fn i16x8_max_s(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => i16_max_s(u16_lane(value, i), u16_lane(other, i)))
}

///|
pub fn i16x8_max_u(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => {
    if u16_lane(value, i) > u16_lane(other, i) {
      u16_lane(value, i)
    } else {
      u16_lane(other, i)
    }
  })
}

///|
pub fn i16x8_avgr_u(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => i16_avgr_u(u16_lane(value, i), u16_lane(other, i)))
}

///|
pub fn i32x4_add(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => u32_lane(value, i) + u32_lane(other, i))
}

///|
pub fn i32x4_sub(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => u32_lane(value, i) - u32_lane(other, i))
}

///|
pub fn i32x4_mul(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => u32_lane(value, i) * u32_lane(other, i))
}

///|
pub fn i32x4_neg(value : V128) -> V128 {
  pack_u32x4_by(i => (0U : UInt) - u32_lane(value, i))
}

///|
pub fn i32x4_abs(value : V128) -> V128 {
  pack_u32x4_by(i => {
    u32_lane(value, i).reinterpret_as_int().abs().reinterpret_as_uint()
  })
}

///|
pub fn i32x4_min_s(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => {
    if u32_lane(value, i).reinterpret_as_int() <
      u32_lane(other, i).reinterpret_as_int() {
      u32_lane(value, i)
    } else {
      u32_lane(other, i)
    }
  })
}

///|
pub fn i32x4_min_u(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => {
    if u32_lane(value, i) < u32_lane(other, i) {
      u32_lane(value, i)
    } else {
      u32_lane(other, i)
    }
  })
}

///|
pub fn i32x4_max_s(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => {
    if u32_lane(value, i).reinterpret_as_int() >
      u32_lane(other, i).reinterpret_as_int() {
      u32_lane(value, i)
    } else {
      u32_lane(other, i)
    }
  })
}

///|
pub fn i32x4_max_u(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => {
    if u32_lane(value, i) > u32_lane(other, i) {
      u32_lane(value, i)
    } else {
      u32_lane(other, i)
    }
  })
}

///|
pub fn i64x2_add(value : V128, other : V128) -> V128 {
  make(lo(value) + lo(other), hi(value) + hi(other))
}

///|
pub fn i64x2_sub(value : V128, other : V128) -> V128 {
  make(lo(value) - lo(other), hi(value) - hi(other))
}

///|
pub fn i64x2_mul(value : V128, other : V128) -> V128 {
  make(lo(value) * lo(other), hi(value) * hi(other))
}

///|
pub fn i64x2_neg(value : V128) -> V128 {
  make(0UL - lo(value), 0UL - hi(value))
}

///|
pub fn i64x2_abs(value : V128) -> V128 {
  pack_u64x2_by(i => {
    u64_lane(value, i).reinterpret_as_int64().abs().reinterpret_as_uint64()
  })
}

///|
pub fn i8x16_shl(value : V128, shift : Int) -> V128 {
  let shift = shift % 8
  pack_u8x16_by(i => (u8_lane(value, i).to_uint() << shift).to_byte())
}

///|
pub fn i8x16_shr_u(value : V128, shift : Int) -> V128 {
  let shift = shift % 8
  pack_u8x16_by(i => (u8_lane(value, i).to_uint() >> shift).to_byte())
}

///|
pub fn i8x16_shr_s(value : V128, shift : Int) -> V128 {
  let shift = shift % 8
  pack_u8x16_by(i => (i8_signed(u8_lane(value, i)) >> shift).to_byte())
}

///|
pub fn i16x8_shl(value : V128, shift : Int) -> V128 {
  let shift = shift % 16
  pack_u16x8_by(i => (u16_lane(value, i).to_uint() << shift).to_uint16())
}

///|
pub fn i16x8_shr_u(value : V128, shift : Int) -> V128 {
  let shift = shift % 16
  pack_u16x8_by(i => (u16_lane(value, i).to_uint() >> shift).to_uint16())
}

///|
pub fn i16x8_shr_s(value : V128, shift : Int) -> V128 {
  let shift = shift % 16
  pack_u16x8_by(i => (i16_signed(u16_lane(value, i)) >> shift).to_uint16())
}

///|
pub fn i32x4_shl(value : V128, shift : Int) -> V128 {
  let shift = shift % 32
  pack_u32x4_by(i => u32_lane(value, i) << shift)
}

///|
pub fn i32x4_shr_u(value : V128, shift : Int) -> V128 {
  let shift = shift % 32
  pack_u32x4_by(i => u32_lane(value, i) >> shift)
}

///|
pub fn i32x4_shr_s(value : V128, shift : Int) -> V128 {
  let shift = shift % 32
  pack_u32x4_by(i => {
    (u32_lane(value, i).reinterpret_as_int() >> shift).reinterpret_as_uint()
  })
}

///|
pub fn i64x2_shl(value : V128, shift : Int) -> V128 {
  let shift = shift % 64
  make(lo(value) << shift, hi(value) << shift)
}

///|
pub fn i64x2_shr_u(value : V128, shift : Int) -> V128 {
  let shift = shift % 64
  make(lo(value) >> shift, hi(value) >> shift)
}

///|
pub fn i64x2_shr_s(value : V128, shift : Int) -> V128 {
  let shift = shift % 64
  pack_u64x2_by(i => {
    (u64_lane(value, i).reinterpret_as_int64() >> shift).reinterpret_as_uint64()
  })
}

///|
pub fn i8x16_eq(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => bool_to_u8_mask(u8_lane(value, i) == u8_lane(other, i)))
}

///|
pub fn i8x16_ne(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => bool_to_u8_mask(u8_lane(value, i) != u8_lane(other, i)))
}

///|
pub fn i8x16_lt_s(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => {
    bool_to_u8_mask(i8_signed(u8_lane(value, i)) < i8_signed(u8_lane(other, i)))
  })
}

///|
pub fn i8x16_lt_u(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => bool_to_u8_mask(u8_lane(value, i) < u8_lane(other, i)))
}

///|
pub fn i8x16_le_s(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => {
    bool_to_u8_mask(
      i8_signed(u8_lane(value, i)) <= i8_signed(u8_lane(other, i)),
    )
  })
}

///|
pub fn i8x16_le_u(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => bool_to_u8_mask(u8_lane(value, i) <= u8_lane(other, i)))
}

///|
pub fn i8x16_gt_s(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => {
    bool_to_u8_mask(i8_signed(u8_lane(value, i)) > i8_signed(u8_lane(other, i)))
  })
}

///|
pub fn i8x16_gt_u(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => bool_to_u8_mask(u8_lane(value, i) > u8_lane(other, i)))
}

///|
pub fn i8x16_ge_s(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => {
    bool_to_u8_mask(
      i8_signed(u8_lane(value, i)) >= i8_signed(u8_lane(other, i)),
    )
  })
}

///|
pub fn i8x16_ge_u(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => bool_to_u8_mask(u8_lane(value, i) >= u8_lane(other, i)))
}

///|
pub fn i16x8_eq(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => bool_to_u16_mask(u16_lane(value, i) == u16_lane(other, i)))
}

///|
pub fn i16x8_ne(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => bool_to_u16_mask(u16_lane(value, i) != u16_lane(other, i)))
}

///|
pub fn i16x8_lt_s(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => {
    bool_to_u16_mask(
      i16_signed(u16_lane(value, i)) < i16_signed(u16_lane(other, i)),
    )
  })
}

///|
pub fn i16x8_lt_u(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => bool_to_u16_mask(u16_lane(value, i) < u16_lane(other, i)))
}

///|
pub fn i16x8_le_s(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => {
    bool_to_u16_mask(
      i16_signed(u16_lane(value, i)) <= i16_signed(u16_lane(other, i)),
    )
  })
}

///|
pub fn i16x8_le_u(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => bool_to_u16_mask(u16_lane(value, i) <= u16_lane(other, i)))
}

///|
pub fn i16x8_gt_s(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => {
    bool_to_u16_mask(
      i16_signed(u16_lane(value, i)) > i16_signed(u16_lane(other, i)),
    )
  })
}

///|
pub fn i16x8_gt_u(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => bool_to_u16_mask(u16_lane(value, i) > u16_lane(other, i)))
}

///|
pub fn i16x8_ge_s(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => {
    bool_to_u16_mask(
      i16_signed(u16_lane(value, i)) >= i16_signed(u16_lane(other, i)),
    )
  })
}

///|
pub fn i16x8_ge_u(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => bool_to_u16_mask(u16_lane(value, i) >= u16_lane(other, i)))
}

///|
pub fn i32x4_eq(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => bool_to_u32_mask(u32_lane(value, i) == u32_lane(other, i)))
}

///|
pub fn i32x4_ne(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => bool_to_u32_mask(u32_lane(value, i) != u32_lane(other, i)))
}

///|
pub fn i32x4_lt_s(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => {
    bool_to_u32_mask(
      u32_lane(value, i).reinterpret_as_int() <
      u32_lane(other, i).reinterpret_as_int(),
    )
  })
}

///|
pub fn i32x4_lt_u(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => bool_to_u32_mask(u32_lane(value, i) < u32_lane(other, i)))
}

///|
pub fn i32x4_le_s(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => {
    bool_to_u32_mask(
      u32_lane(value, i).reinterpret_as_int() <=
      u32_lane(other, i).reinterpret_as_int(),
    )
  })
}

///|
pub fn i32x4_le_u(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => bool_to_u32_mask(u32_lane(value, i) <= u32_lane(other, i)))
}

///|
pub fn i32x4_gt_s(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => {
    bool_to_u32_mask(
      u32_lane(value, i).reinterpret_as_int() >
      u32_lane(other, i).reinterpret_as_int(),
    )
  })
}

///|
pub fn i32x4_gt_u(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => bool_to_u32_mask(u32_lane(value, i) > u32_lane(other, i)))
}

///|
pub fn i32x4_ge_s(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => {
    bool_to_u32_mask(
      u32_lane(value, i).reinterpret_as_int() >=
      u32_lane(other, i).reinterpret_as_int(),
    )
  })
}

///|
pub fn i32x4_ge_u(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => bool_to_u32_mask(u32_lane(value, i) >= u32_lane(other, i)))
}

///|
pub fn i64x2_eq(value : V128, other : V128) -> V128 {
  pack_u64x2_by(i => bool_to_u64_mask(u64_lane(value, i) == u64_lane(other, i)))
}

///|
pub fn i64x2_ne(value : V128, other : V128) -> V128 {
  pack_u64x2_by(i => bool_to_u64_mask(u64_lane(value, i) != u64_lane(other, i)))
}

///|
pub fn i64x2_lt_s(value : V128, other : V128) -> V128 {
  pack_u64x2_by(i => {
    bool_to_u64_mask(
      u64_lane(value, i).reinterpret_as_int64() <
      u64_lane(other, i).reinterpret_as_int64(),
    )
  })
}

///|
pub fn i64x2_le_s(value : V128, other : V128) -> V128 {
  pack_u64x2_by(i => {
    bool_to_u64_mask(
      u64_lane(value, i).reinterpret_as_int64() <=
      u64_lane(other, i).reinterpret_as_int64(),
    )
  })
}

///|
pub fn i64x2_gt_s(value : V128, other : V128) -> V128 {
  pack_u64x2_by(i => {
    bool_to_u64_mask(
      u64_lane(value, i).reinterpret_as_int64() >
      u64_lane(other, i).reinterpret_as_int64(),
    )
  })
}

///|
pub fn i64x2_ge_s(value : V128, other : V128) -> V128 {
  pack_u64x2_by(i => {
    bool_to_u64_mask(
      u64_lane(value, i).reinterpret_as_int64() >=
      u64_lane(other, i).reinterpret_as_int64(),
    )
  })
}

///|
pub fn i8x16_all_true(value : V128) -> Bool {
  for i in 0..<16 {
    if u8_lane(value, i) == 0 {
      return false
    }
  }
  true
}

///|
pub fn i16x8_all_true(value : V128) -> Bool {
  for i in 0..<8 {
    if u16_lane(value, i) == 0 {
      return false
    }
  }
  true
}

///|
pub fn i32x4_all_true(value : V128) -> Bool {
  for i in 0..<4 {
    if u32_lane(value, i) == 0 {
      return false
    }
  }
  true
}

///|
pub fn i64x2_all_true(value : V128) -> Bool {
  lo(value) != 0UL && hi(value) != 0UL
}

///|
pub fn i8x16_bitmask(value : V128) -> Int {
  let mut result = 0
  for i in 0..<16 {
    result = result | (((u8_lane(value, i).to_int() >> 7) & 1) << i)
  }
  result
}

///|
pub fn i16x8_bitmask(value : V128) -> Int {
  let mut result = 0
  for i in 0..<8 {
    result = result | (((u16_lane(value, i).to_int() >> 15) & 1) << i)
  }
  result
}

///|
pub fn i32x4_bitmask(value : V128) -> Int {
  let mut result = 0
  for i in 0..<4 {
    result = result |
      ((u32_lane(value, i).reinterpret_as_int() >> 31) & (1 << i))
  }
  result
}

///|
pub fn i64x2_bitmask(value : V128) -> Int {
  let mut result = 0
  for i in 0..<2 {
    result = result | ((u64_lane(value, i) >> 63).to_int() << i)
  }
  result
}
