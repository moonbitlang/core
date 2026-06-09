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
