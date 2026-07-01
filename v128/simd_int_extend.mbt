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
fn narrow_i16_to_i8_s(value : UInt16) -> Byte {
  let value = i16_signed(value)
  if value > 127 {
    0x7f
  } else if value < -128 {
    0x80
  } else {
    value.to_byte()
  }
}

///|
fn narrow_i16_to_i8_u(value : UInt16) -> Byte {
  let signed = i16_signed(value)
  if signed < 0 {
    0
  } else if signed > 255 {
    0xff
  } else {
    signed.to_byte()
  }
}

///|
fn narrow_i32_to_i16_s(value : UInt) -> UInt16 {
  let signed = value.reinterpret_as_int()
  if signed > 32767 {
    0x7fff
  } else if signed < -32768 {
    0x8000
  } else {
    signed.to_uint16()
  }
}

///|
fn narrow_i32_to_i16_u(value : UInt) -> UInt16 {
  let signed = value.reinterpret_as_int()
  if signed < 0 {
    0
  } else if signed > 65535 {
    0xffff
  } else {
    signed.to_uint16()
  }
}

///|
fn i16_q15mulr_sat_s(value : UInt16, other : UInt16) -> UInt16 {
  let rounded = (i16_signed(value) * i16_signed(other) + 0x4000) >> 15
  if rounded > 32767 {
    0x7fff
  } else if rounded < -32768 {
    0x8000
  } else {
    rounded.to_uint16()
  }
}

///|
fn i16_pair_dot(value : V128, other : V128, pair : Int) -> UInt {
  (i16_signed(u16_lane(value, pair * 2)) * i16_signed(u16_lane(other, pair * 2)) +
  i16_signed(u16_lane(value, pair * 2 + 1)) *
  i16_signed(u16_lane(other, pair * 2 + 1))).reinterpret_as_uint()
}

///|
/// Sign-extends the low half of the source lanes into eight 16-bit integer lanes.
#intrinsic("%v128.i16x8_extend_low_i8x16_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_extend_low_i8x16_s(value : V128) -> V128 {
  pack_u16x8_by(i => i8_signed(u8_lane(value, i)).to_uint16())
}

///|
/// Sign-extends the high half of the source lanes into eight 16-bit integer lanes.
#intrinsic("%v128.i16x8_extend_high_i8x16_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_extend_high_i8x16_s(value : V128) -> V128 {
  pack_u16x8_by(i => i8_signed(u8_lane(value, i + 8)).to_uint16())
}

///|
/// Zero-extends the low half of the source lanes into eight 16-bit integer lanes.
#intrinsic("%v128.i16x8_extend_low_i8x16_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_extend_low_i8x16_u(value : V128) -> V128 {
  pack_u16x8_by(i => u8_lane(value, i).to_uint16())
}

///|
/// Zero-extends the high half of the source lanes into eight 16-bit integer lanes.
#intrinsic("%v128.i16x8_extend_high_i8x16_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_extend_high_i8x16_u(value : V128) -> V128 {
  pack_u16x8_by(i => u8_lane(value, i + 8).to_uint16())
}

///|
/// Sign-extends the low half of the source lanes into four 32-bit integer lanes.
#intrinsic("%v128.i32x4_extend_low_i16x8_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i32x4_extend_low_i16x8_s(value : V128) -> V128 {
  pack_u32x4_by(i => i16_signed(u16_lane(value, i)).reinterpret_as_uint())
}

///|
/// Sign-extends the high half of the source lanes into four 32-bit integer lanes.
#intrinsic("%v128.i32x4_extend_high_i16x8_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i32x4_extend_high_i16x8_s(value : V128) -> V128 {
  pack_u32x4_by(i => i16_signed(u16_lane(value, i + 4)).reinterpret_as_uint())
}

///|
/// Zero-extends the low half of the source lanes into four 32-bit integer lanes.
#intrinsic("%v128.i32x4_extend_low_i16x8_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i32x4_extend_low_i16x8_u(value : V128) -> V128 {
  pack_u32x4_by(i => u16_lane(value, i).to_uint())
}

///|
/// Zero-extends the high half of the source lanes into four 32-bit integer lanes.
#intrinsic("%v128.i32x4_extend_high_i16x8_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i32x4_extend_high_i16x8_u(value : V128) -> V128 {
  pack_u32x4_by(i => u16_lane(value, i + 4).to_uint())
}

///|
/// Sign-extends the low half of the source lanes into two 64-bit integer lanes.
#intrinsic("%v128.i64x2_extend_low_i32x4_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i64x2_extend_low_i32x4_s(value : V128) -> V128 {
  pack_u64x2_by(i => {
    u32_lane(value, i).reinterpret_as_int().to_int64().reinterpret_as_uint64()
  })
}

///|
/// Sign-extends the high half of the source lanes into two 64-bit integer lanes.
#intrinsic("%v128.i64x2_extend_high_i32x4_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i64x2_extend_high_i32x4_s(value : V128) -> V128 {
  pack_u64x2_by(i => {
    u32_lane(value, i + 2)
    .reinterpret_as_int()
    .to_int64()
    .reinterpret_as_uint64()
  })
}

///|
/// Zero-extends the low half of the source lanes into two 64-bit integer lanes.
#intrinsic("%v128.i64x2_extend_low_i32x4_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i64x2_extend_low_i32x4_u(value : V128) -> V128 {
  pack_u64x2_by(i => u32_lane(value, i).to_uint64())
}

///|
/// Zero-extends the high half of the source lanes into two 64-bit integer lanes.
#intrinsic("%v128.i64x2_extend_high_i32x4_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i64x2_extend_high_i32x4_u(value : V128) -> V128 {
  pack_u64x2_by(i => u32_lane(value, i + 2).to_uint64())
}

///|
/// Relaxed lane-wise select over sixteen 8-bit integer lanes using each mask lane's high bit.
#intrinsic("%v128.i8x16_relaxed_laneselect")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i8x16_relaxed_laneselect(
  value : V128,
  other : V128,
  mask : V128,
) -> V128 {
  pack_u8x16_by(i => {
    if (u8_lane(mask, i) & 0x80) != 0 {
      u8_lane(value, i)
    } else {
      u8_lane(other, i)
    }
  })
}

///|
/// Relaxed lane-wise select over eight 16-bit integer lanes using each mask lane's high bit.
#intrinsic("%v128.i16x8_relaxed_laneselect")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_relaxed_laneselect(
  value : V128,
  other : V128,
  mask : V128,
) -> V128 {
  pack_u16x8_by(i => {
    if (u16_lane(mask, i) & 0x8000) != 0 {
      u16_lane(value, i)
    } else {
      u16_lane(other, i)
    }
  })
}

///|
/// Relaxed lane-wise select over four 32-bit integer lanes using each mask lane's high bit.
#intrinsic("%v128.i32x4_relaxed_laneselect")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i32x4_relaxed_laneselect(
  value : V128,
  other : V128,
  mask : V128,
) -> V128 {
  pack_u32x4_by(i => {
    if (u32_lane(mask, i) & 0x80000000) != 0 {
      u32_lane(value, i)
    } else {
      u32_lane(other, i)
    }
  })
}

///|
/// Relaxed lane-wise select over two 64-bit integer lanes using each mask lane's high bit.
#intrinsic("%v128.i64x2_relaxed_laneselect")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i64x2_relaxed_laneselect(
  value : V128,
  other : V128,
  mask : V128,
) -> V128 {
  pack_u64x2_by(i => {
    if (u64_lane(mask, i) & 0x8000000000000000UL) != 0UL {
      u64_lane(value, i)
    } else {
      u64_lane(other, i)
    }
  })
}

///|
/// Narrows two vectors into sixteen 8-bit integer lanes with signed saturation, low operand first.
#intrinsic("%v128.i8x16_narrow_i16x8_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i8x16_narrow_i16x8_s(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => {
    if i < 8 {
      narrow_i16_to_i8_s(u16_lane(value, i))
    } else {
      narrow_i16_to_i8_s(u16_lane(other, i - 8))
    }
  })
}

///|
/// Narrows two vectors into sixteen 8-bit integer lanes with unsigned saturation, low operand first.
#intrinsic("%v128.i8x16_narrow_i16x8_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i8x16_narrow_i16x8_u(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => {
    if i < 8 {
      narrow_i16_to_i8_u(u16_lane(value, i))
    } else {
      narrow_i16_to_i8_u(u16_lane(other, i - 8))
    }
  })
}

///|
/// Narrows two vectors into eight 16-bit integer lanes with signed saturation, low operand first.
#intrinsic("%v128.i16x8_narrow_i32x4_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_narrow_i32x4_s(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => {
    if i < 4 {
      narrow_i32_to_i16_s(u32_lane(value, i))
    } else {
      narrow_i32_to_i16_s(u32_lane(other, i - 4))
    }
  })
}

///|
/// Narrows two vectors into eight 16-bit integer lanes with unsigned saturation, low operand first.
#intrinsic("%v128.i16x8_narrow_i32x4_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_narrow_i32x4_u(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => {
    if i < 4 {
      narrow_i32_to_i16_u(u32_lane(value, i))
    } else {
      narrow_i32_to_i16_u(u32_lane(other, i - 4))
    }
  })
}

///|
/// Multiplies the low half of the source lanes (signed, widening) into eight 16-bit integer lanes.
#intrinsic("%v128.i16x8_extmul_low_i8x16_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_extmul_low_i8x16_s(value : V128, other : V128) -> V128 {
  i16x8_mul(i16x8_extend_low_i8x16_s(value), i16x8_extend_low_i8x16_s(other))
}

///|
/// Multiplies the high half of the source lanes (signed, widening) into eight 16-bit integer lanes.
#intrinsic("%v128.i16x8_extmul_high_i8x16_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_extmul_high_i8x16_s(value : V128, other : V128) -> V128 {
  i16x8_mul(i16x8_extend_high_i8x16_s(value), i16x8_extend_high_i8x16_s(other))
}

///|
/// Multiplies the low half of the source lanes (unsigned, widening) into eight 16-bit integer lanes.
#intrinsic("%v128.i16x8_extmul_low_i8x16_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_extmul_low_i8x16_u(value : V128, other : V128) -> V128 {
  i16x8_mul(i16x8_extend_low_i8x16_u(value), i16x8_extend_low_i8x16_u(other))
}

///|
/// Multiplies the high half of the source lanes (unsigned, widening) into eight 16-bit integer lanes.
#intrinsic("%v128.i16x8_extmul_high_i8x16_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_extmul_high_i8x16_u(value : V128, other : V128) -> V128 {
  i16x8_mul(i16x8_extend_high_i8x16_u(value), i16x8_extend_high_i8x16_u(other))
}

///|
/// Multiplies the low half of the source lanes (signed, widening) into four 32-bit integer lanes.
#intrinsic("%v128.i32x4_extmul_low_i16x8_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i32x4_extmul_low_i16x8_s(value : V128, other : V128) -> V128 {
  i32x4_mul(i32x4_extend_low_i16x8_s(value), i32x4_extend_low_i16x8_s(other))
}

///|
/// Multiplies the high half of the source lanes (signed, widening) into four 32-bit integer lanes.
#intrinsic("%v128.i32x4_extmul_high_i16x8_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i32x4_extmul_high_i16x8_s(value : V128, other : V128) -> V128 {
  i32x4_mul(i32x4_extend_high_i16x8_s(value), i32x4_extend_high_i16x8_s(other))
}

///|
/// Multiplies the low half of the source lanes (unsigned, widening) into four 32-bit integer lanes.
#intrinsic("%v128.i32x4_extmul_low_i16x8_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i32x4_extmul_low_i16x8_u(value : V128, other : V128) -> V128 {
  i32x4_mul(i32x4_extend_low_i16x8_u(value), i32x4_extend_low_i16x8_u(other))
}

///|
/// Multiplies the high half of the source lanes (unsigned, widening) into four 32-bit integer lanes.
#intrinsic("%v128.i32x4_extmul_high_i16x8_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i32x4_extmul_high_i16x8_u(value : V128, other : V128) -> V128 {
  i32x4_mul(i32x4_extend_high_i16x8_u(value), i32x4_extend_high_i16x8_u(other))
}

///|
/// Multiplies the low half of the source lanes (signed, widening) into two 64-bit integer lanes.
#intrinsic("%v128.i64x2_extmul_low_i32x4_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i64x2_extmul_low_i32x4_s(value : V128, other : V128) -> V128 {
  pack_u64x2_by(i => {
    (u32_lane(value, i).reinterpret_as_int().to_int64() *
    u32_lane(other, i).reinterpret_as_int().to_int64()).reinterpret_as_uint64()
  })
}

///|
/// Multiplies the high half of the source lanes (signed, widening) into two 64-bit integer lanes.
#intrinsic("%v128.i64x2_extmul_high_i32x4_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i64x2_extmul_high_i32x4_s(value : V128, other : V128) -> V128 {
  pack_u64x2_by(i => {
    (u32_lane(value, i + 2).reinterpret_as_int().to_int64() *
    u32_lane(other, i + 2).reinterpret_as_int().to_int64()).reinterpret_as_uint64()
  })
}

///|
/// Multiplies the low half of the source lanes (unsigned, widening) into two 64-bit integer lanes.
#intrinsic("%v128.i64x2_extmul_low_i32x4_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i64x2_extmul_low_i32x4_u(value : V128, other : V128) -> V128 {
  pack_u64x2_by(i => {
    u32_lane(value, i).to_uint64() * u32_lane(other, i).to_uint64()
  })
}

///|
/// Multiplies the high half of the source lanes (unsigned, widening) into two 64-bit integer lanes.
#intrinsic("%v128.i64x2_extmul_high_i32x4_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i64x2_extmul_high_i32x4_u(value : V128, other : V128) -> V128 {
  pack_u64x2_by(i => {
    u32_lane(value, i + 2).to_uint64() * u32_lane(other, i + 2).to_uint64()
  })
}

///|
/// Lane-wise signed Q15 fixed-point multiply with rounding and saturation.
#intrinsic("%v128.i16x8_q15mulr_sat_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_q15mulr_sat_s(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => i16_q15mulr_sat_s(u16_lane(value, i), u16_lane(other, i)))
}

///|
/// Relaxed signed Q15 fixed-point multiply with rounding.
#intrinsic("%v128.i16x8_relaxed_q15mulr_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_relaxed_q15mulr_s(value : V128, other : V128) -> V128 {
  i16x8_q15mulr_sat_s(value, other)
}

///|
/// Sign-extends adjacent lane pairs and adds each pair into eight 16-bit integer lanes.
#intrinsic("%v128.i16x8_extadd_pairwise_i8x16_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_extadd_pairwise_i8x16_s(value : V128) -> V128 {
  pack_u16x8_by(i => {
    (i8_signed(u8_lane(value, i * 2)) + i8_signed(u8_lane(value, i * 2 + 1))).to_uint16()
  })
}

///|
/// Zero-extends adjacent lane pairs and adds each pair into eight 16-bit integer lanes.
#intrinsic("%v128.i16x8_extadd_pairwise_i8x16_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_extadd_pairwise_i8x16_u(value : V128) -> V128 {
  pack_u16x8_by(i => {
    u8_lane(value, i * 2).to_uint16() + u8_lane(value, i * 2 + 1).to_uint16()
  })
}

///|
/// Sign-extends adjacent lane pairs and adds each pair into four 32-bit integer lanes.
#intrinsic("%v128.i32x4_extadd_pairwise_i16x8_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i32x4_extadd_pairwise_i16x8_s(value : V128) -> V128 {
  pack_u32x4_by(i => {
    (i16_signed(u16_lane(value, i * 2)) + i16_signed(u16_lane(value, i * 2 + 1))).reinterpret_as_uint()
  })
}

///|
/// Zero-extends adjacent lane pairs and adds each pair into four 32-bit integer lanes.
#intrinsic("%v128.i32x4_extadd_pairwise_i16x8_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i32x4_extadd_pairwise_i16x8_u(value : V128) -> V128 {
  pack_u32x4_by(i => {
    u16_lane(value, i * 2).to_uint() + u16_lane(value, i * 2 + 1).to_uint()
  })
}

///|
/// Relaxed dot product of signed 8-bit by 7-bit lanes into 16-bit lanes.
///
/// No `#intrinsic` annotation: the existing intrinsic
/// `%v128.i16x8_relaxed_dot_s_i8x16` does not follow the spec/function
/// naming convention (`i16x8.relaxed_dot_i8x16_i7x16_s`) and is slated to
/// be renamed in the compiler. Until then this runs via the portable
/// fallback below, which is correct on every backend.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i16x8_relaxed_dot_i8x16_i7x16_s(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => {
    (i8_signed(u8_lane(value, i * 2)) * i8_signed(u8_lane(other, i * 2)) +
    i8_signed(u8_lane(value, i * 2 + 1)) * i8_signed(u8_lane(other, i * 2 + 1))).to_uint16()
  })
}

///|
/// Multiplies adjacent pairs of signed 16-bit lanes and sums each pair into a 32-bit lane.
#intrinsic("%v128.i32x4_dot_i16x8_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i32x4_dot_i16x8_s(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => i16_pair_dot(value, other, i))
}

///|
/// Relaxed dot product of signed 8-bit by 7-bit lanes, accumulated into 32-bit lanes.
///
/// No `#intrinsic` annotation: the existing intrinsic
/// `%v128.i32x4_relaxed_dot_add_s_i16x8` is misnamed. Its `_i16x8` suffix
/// describes the intermediate vector, not the i8x16/i7x16 inputs, and the
/// NEON lowering followed the name and multiplied the inputs as i16 lanes
/// (vmull_s16) instead of i8 lanes (vmull_s8), producing wrong results.
/// Omit the annotation until the compiler's intrinsic name and lowering are
/// fixed; the portable fallback below is correct on every backend.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn i32x4_relaxed_dot_i8x16_i7x16_add_s(
  value : V128,
  other : V128,
  accumulator : V128,
) -> V128 {
  i32x4_add(
    i32x4_extadd_pairwise_i16x8_s(i16x8_relaxed_dot_i8x16_i7x16_s(value, other)),
    accumulator,
  )
}
