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
/// Lane-wise wrapping addition over sixteen 8-bit integer lanes.
#intrinsic("%v128.i8x16_add")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i8x16_add(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => u8_lane(value, i) + u8_lane(other, i))
}

///|
/// Lane-wise wrapping subtraction over sixteen 8-bit integer lanes.
#intrinsic("%v128.i8x16_sub")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i8x16_sub(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => u8_lane(value, i) - u8_lane(other, i))
}

///|
/// Lane-wise signed saturating addition over sixteen 8-bit integer lanes.
#intrinsic("%v128.i8x16_add_sat_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i8x16_add_sat_s(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => i8_add_sat_s(u8_lane(value, i), u8_lane(other, i)))
}

///|
/// Lane-wise unsigned saturating addition over sixteen 8-bit integer lanes.
#intrinsic("%v128.i8x16_add_sat_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i8x16_add_sat_u(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => i8_add_sat_u(u8_lane(value, i), u8_lane(other, i)))
}

///|
/// Lane-wise signed saturating subtraction over sixteen 8-bit integer lanes.
#intrinsic("%v128.i8x16_sub_sat_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i8x16_sub_sat_s(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => i8_sub_sat_s(u8_lane(value, i), u8_lane(other, i)))
}

///|
/// Lane-wise unsigned saturating subtraction over sixteen 8-bit integer lanes.
#intrinsic("%v128.i8x16_sub_sat_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i8x16_sub_sat_u(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => i8_sub_sat_u(u8_lane(value, i), u8_lane(other, i)))
}

///|
/// Lane-wise negation over sixteen 8-bit integer lanes.
#intrinsic("%v128.i8x16_neg")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i8x16_neg(value : V128) -> V128 {
  pack_u8x16_by(i => (0 : Byte) - u8_lane(value, i))
}

///|
/// Lane-wise absolute value over sixteen 8-bit integer lanes.
#intrinsic("%v128.i8x16_abs")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i8x16_abs(value : V128) -> V128 {
  pack_u8x16_by(i => i8_abs(u8_lane(value, i)))
}

///|
/// Lane-wise signed minimum over sixteen 8-bit integer lanes.
#intrinsic("%v128.i8x16_min_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i8x16_min_s(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => i8_min_s(u8_lane(value, i), u8_lane(other, i)))
}

///|
/// Lane-wise unsigned minimum over sixteen 8-bit integer lanes.
#intrinsic("%v128.i8x16_min_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
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
/// Lane-wise signed maximum over sixteen 8-bit integer lanes.
#intrinsic("%v128.i8x16_max_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i8x16_max_s(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => i8_max_s(u8_lane(value, i), u8_lane(other, i)))
}

///|
/// Lane-wise unsigned maximum over sixteen 8-bit integer lanes.
#intrinsic("%v128.i8x16_max_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
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
/// Lane-wise unsigned rounding average `(a + b + 1) >> 1` over sixteen 8-bit integer lanes.
#intrinsic("%v128.i8x16_avgr_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i8x16_avgr_u(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => i8_avgr_u(u8_lane(value, i), u8_lane(other, i)))
}

///|
/// Lane-wise population count (set bits per byte).
#intrinsic("%v128.i8x16_popcnt")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i8x16_popcnt(value : V128) -> V128 {
  pack_u8x16_by(i => u8_lane(value, i).to_uint().popcnt().to_byte())
}

///|
/// Lane-wise wrapping addition over eight 16-bit integer lanes.
#intrinsic("%v128.i16x8_add")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_add(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => u16_lane(value, i) + u16_lane(other, i))
}

///|
/// Lane-wise wrapping subtraction over eight 16-bit integer lanes.
#intrinsic("%v128.i16x8_sub")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_sub(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => u16_lane(value, i) - u16_lane(other, i))
}

///|
/// Lane-wise signed saturating addition over eight 16-bit integer lanes.
#intrinsic("%v128.i16x8_add_sat_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_add_sat_s(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => i16_add_sat_s(u16_lane(value, i), u16_lane(other, i)))
}

///|
/// Lane-wise unsigned saturating addition over eight 16-bit integer lanes.
#intrinsic("%v128.i16x8_add_sat_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_add_sat_u(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => i16_add_sat_u(u16_lane(value, i), u16_lane(other, i)))
}

///|
/// Lane-wise signed saturating subtraction over eight 16-bit integer lanes.
#intrinsic("%v128.i16x8_sub_sat_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_sub_sat_s(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => i16_sub_sat_s(u16_lane(value, i), u16_lane(other, i)))
}

///|
/// Lane-wise unsigned saturating subtraction over eight 16-bit integer lanes.
#intrinsic("%v128.i16x8_sub_sat_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_sub_sat_u(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => i16_sub_sat_u(u16_lane(value, i), u16_lane(other, i)))
}

///|
/// Lane-wise wrapping multiplication over eight 16-bit integer lanes.
#intrinsic("%v128.i16x8_mul")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_mul(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => u16_lane(value, i) * u16_lane(other, i))
}

///|
/// Lane-wise negation over eight 16-bit integer lanes.
#intrinsic("%v128.i16x8_neg")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_neg(value : V128) -> V128 {
  pack_u16x8_by(i => (0 : UInt16) - u16_lane(value, i))
}

///|
/// Lane-wise absolute value over eight 16-bit integer lanes.
#intrinsic("%v128.i16x8_abs")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_abs(value : V128) -> V128 {
  pack_u16x8_by(i => i16_abs(u16_lane(value, i)))
}

///|
/// Lane-wise signed minimum over eight 16-bit integer lanes.
#intrinsic("%v128.i16x8_min_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_min_s(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => i16_min_s(u16_lane(value, i), u16_lane(other, i)))
}

///|
/// Lane-wise unsigned minimum over eight 16-bit integer lanes.
#intrinsic("%v128.i16x8_min_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
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
/// Lane-wise signed maximum over eight 16-bit integer lanes.
#intrinsic("%v128.i16x8_max_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_max_s(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => i16_max_s(u16_lane(value, i), u16_lane(other, i)))
}

///|
/// Lane-wise unsigned maximum over eight 16-bit integer lanes.
#intrinsic("%v128.i16x8_max_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
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
/// Lane-wise unsigned rounding average `(a + b + 1) >> 1` over eight 16-bit integer lanes.
#intrinsic("%v128.i16x8_avgr_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_avgr_u(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => i16_avgr_u(u16_lane(value, i), u16_lane(other, i)))
}

///|
/// Lane-wise wrapping addition over four 32-bit integer lanes.
#intrinsic("%v128.i32x4_add")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i32x4_add(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => u32_lane(value, i) + u32_lane(other, i))
}

///|
/// Lane-wise wrapping subtraction over four 32-bit integer lanes.
#intrinsic("%v128.i32x4_sub")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i32x4_sub(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => u32_lane(value, i) - u32_lane(other, i))
}

///|
/// Lane-wise wrapping multiplication over four 32-bit integer lanes.
#intrinsic("%v128.i32x4_mul")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i32x4_mul(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => u32_lane(value, i) * u32_lane(other, i))
}

///|
/// Lane-wise negation over four 32-bit integer lanes.
#intrinsic("%v128.i32x4_neg")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i32x4_neg(value : V128) -> V128 {
  pack_u32x4_by(i => (0U : UInt) - u32_lane(value, i))
}

///|
/// Lane-wise absolute value over four 32-bit integer lanes.
#intrinsic("%v128.i32x4_abs")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i32x4_abs(value : V128) -> V128 {
  pack_u32x4_by(i => {
    u32_lane(value, i).reinterpret_as_int().abs().reinterpret_as_uint()
  })
}

///|
/// Lane-wise signed minimum over four 32-bit integer lanes.
#intrinsic("%v128.i32x4_min_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
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
/// Lane-wise unsigned minimum over four 32-bit integer lanes.
#intrinsic("%v128.i32x4_min_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
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
/// Lane-wise signed maximum over four 32-bit integer lanes.
#intrinsic("%v128.i32x4_max_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
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
/// Lane-wise unsigned maximum over four 32-bit integer lanes.
#intrinsic("%v128.i32x4_max_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
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
/// Lane-wise wrapping addition over two 64-bit integer lanes.
#intrinsic("%v128.i64x2_add")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i64x2_add(value : V128, other : V128) -> V128 {
  make(lo(value) + lo(other), hi(value) + hi(other))
}

///|
/// Lane-wise wrapping subtraction over two 64-bit integer lanes.
#intrinsic("%v128.i64x2_sub")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i64x2_sub(value : V128, other : V128) -> V128 {
  make(lo(value) - lo(other), hi(value) - hi(other))
}

///|
/// Lane-wise wrapping multiplication over two 64-bit integer lanes.
#intrinsic("%v128.i64x2_mul")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i64x2_mul(value : V128, other : V128) -> V128 {
  make(lo(value) * lo(other), hi(value) * hi(other))
}

///|
/// Lane-wise negation over two 64-bit integer lanes.
#intrinsic("%v128.i64x2_neg")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i64x2_neg(value : V128) -> V128 {
  make(0UL - lo(value), 0UL - hi(value))
}

///|
/// Lane-wise absolute value over two 64-bit integer lanes.
#intrinsic("%v128.i64x2_abs")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i64x2_abs(value : V128) -> V128 {
  pack_u64x2_by(i => {
    u64_lane(value, i).reinterpret_as_int64().abs().reinterpret_as_uint64()
  })
}
