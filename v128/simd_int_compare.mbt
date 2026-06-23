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
/// Lane-wise equality comparison over sixteen 8-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i8x16_eq")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i8x16_eq(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => bool_to_u8_mask(u8_lane(value, i) == u8_lane(other, i)))
}

///|
/// Lane-wise inequality comparison over sixteen 8-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i8x16_ne")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i8x16_ne(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => bool_to_u8_mask(u8_lane(value, i) != u8_lane(other, i)))
}

///|
/// Lane-wise less-than comparison (signed) over sixteen 8-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i8x16_lt_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i8x16_lt_s(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => {
    bool_to_u8_mask(i8_signed(u8_lane(value, i)) < i8_signed(u8_lane(other, i)))
  })
}

///|
/// Lane-wise less-than comparison (unsigned) over sixteen 8-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i8x16_lt_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i8x16_lt_u(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => bool_to_u8_mask(u8_lane(value, i) < u8_lane(other, i)))
}

///|
/// Lane-wise less-than-or-equal comparison (signed) over sixteen 8-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i8x16_le_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i8x16_le_s(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => {
    bool_to_u8_mask(
      i8_signed(u8_lane(value, i)) <= i8_signed(u8_lane(other, i)),
    )
  })
}

///|
/// Lane-wise less-than-or-equal comparison (unsigned) over sixteen 8-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i8x16_le_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i8x16_le_u(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => bool_to_u8_mask(u8_lane(value, i) <= u8_lane(other, i)))
}

///|
/// Lane-wise greater-than comparison (signed) over sixteen 8-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i8x16_gt_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i8x16_gt_s(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => {
    bool_to_u8_mask(i8_signed(u8_lane(value, i)) > i8_signed(u8_lane(other, i)))
  })
}

///|
/// Lane-wise greater-than comparison (unsigned) over sixteen 8-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i8x16_gt_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i8x16_gt_u(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => bool_to_u8_mask(u8_lane(value, i) > u8_lane(other, i)))
}

///|
/// Lane-wise greater-than-or-equal comparison (signed) over sixteen 8-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i8x16_ge_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i8x16_ge_s(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => {
    bool_to_u8_mask(
      i8_signed(u8_lane(value, i)) >= i8_signed(u8_lane(other, i)),
    )
  })
}

///|
/// Lane-wise greater-than-or-equal comparison (unsigned) over sixteen 8-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i8x16_ge_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i8x16_ge_u(value : V128, other : V128) -> V128 {
  pack_u8x16_by(i => bool_to_u8_mask(u8_lane(value, i) >= u8_lane(other, i)))
}

///|
/// Lane-wise equality comparison over eight 16-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i16x8_eq")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i16x8_eq(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => bool_to_u16_mask(u16_lane(value, i) == u16_lane(other, i)))
}

///|
/// Lane-wise inequality comparison over eight 16-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i16x8_ne")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i16x8_ne(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => bool_to_u16_mask(u16_lane(value, i) != u16_lane(other, i)))
}

///|
/// Lane-wise less-than comparison (signed) over eight 16-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i16x8_lt_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i16x8_lt_s(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => {
    bool_to_u16_mask(
      i16_signed(u16_lane(value, i)) < i16_signed(u16_lane(other, i)),
    )
  })
}

///|
/// Lane-wise less-than comparison (unsigned) over eight 16-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i16x8_lt_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i16x8_lt_u(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => bool_to_u16_mask(u16_lane(value, i) < u16_lane(other, i)))
}

///|
/// Lane-wise less-than-or-equal comparison (signed) over eight 16-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i16x8_le_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i16x8_le_s(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => {
    bool_to_u16_mask(
      i16_signed(u16_lane(value, i)) <= i16_signed(u16_lane(other, i)),
    )
  })
}

///|
/// Lane-wise less-than-or-equal comparison (unsigned) over eight 16-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i16x8_le_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i16x8_le_u(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => bool_to_u16_mask(u16_lane(value, i) <= u16_lane(other, i)))
}

///|
/// Lane-wise greater-than comparison (signed) over eight 16-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i16x8_gt_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i16x8_gt_s(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => {
    bool_to_u16_mask(
      i16_signed(u16_lane(value, i)) > i16_signed(u16_lane(other, i)),
    )
  })
}

///|
/// Lane-wise greater-than comparison (unsigned) over eight 16-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i16x8_gt_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i16x8_gt_u(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => bool_to_u16_mask(u16_lane(value, i) > u16_lane(other, i)))
}

///|
/// Lane-wise greater-than-or-equal comparison (signed) over eight 16-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i16x8_ge_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i16x8_ge_s(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => {
    bool_to_u16_mask(
      i16_signed(u16_lane(value, i)) >= i16_signed(u16_lane(other, i)),
    )
  })
}

///|
/// Lane-wise greater-than-or-equal comparison (unsigned) over eight 16-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i16x8_ge_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i16x8_ge_u(value : V128, other : V128) -> V128 {
  pack_u16x8_by(i => bool_to_u16_mask(u16_lane(value, i) >= u16_lane(other, i)))
}

///|
/// Lane-wise equality comparison over four 32-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i32x4_eq")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i32x4_eq(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => bool_to_u32_mask(u32_lane(value, i) == u32_lane(other, i)))
}

///|
/// Lane-wise inequality comparison over four 32-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i32x4_ne")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i32x4_ne(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => bool_to_u32_mask(u32_lane(value, i) != u32_lane(other, i)))
}

///|
/// Lane-wise less-than comparison (signed) over four 32-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i32x4_lt_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i32x4_lt_s(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => {
    bool_to_u32_mask(
      u32_lane(value, i).reinterpret_as_int() <
      u32_lane(other, i).reinterpret_as_int(),
    )
  })
}

///|
/// Lane-wise less-than comparison (unsigned) over four 32-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i32x4_lt_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i32x4_lt_u(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => bool_to_u32_mask(u32_lane(value, i) < u32_lane(other, i)))
}

///|
/// Lane-wise less-than-or-equal comparison (signed) over four 32-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i32x4_le_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i32x4_le_s(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => {
    bool_to_u32_mask(
      u32_lane(value, i).reinterpret_as_int() <=
      u32_lane(other, i).reinterpret_as_int(),
    )
  })
}

///|
/// Lane-wise less-than-or-equal comparison (unsigned) over four 32-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i32x4_le_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i32x4_le_u(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => bool_to_u32_mask(u32_lane(value, i) <= u32_lane(other, i)))
}

///|
/// Lane-wise greater-than comparison (signed) over four 32-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i32x4_gt_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i32x4_gt_s(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => {
    bool_to_u32_mask(
      u32_lane(value, i).reinterpret_as_int() >
      u32_lane(other, i).reinterpret_as_int(),
    )
  })
}

///|
/// Lane-wise greater-than comparison (unsigned) over four 32-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i32x4_gt_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i32x4_gt_u(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => bool_to_u32_mask(u32_lane(value, i) > u32_lane(other, i)))
}

///|
/// Lane-wise greater-than-or-equal comparison (signed) over four 32-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i32x4_ge_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i32x4_ge_s(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => {
    bool_to_u32_mask(
      u32_lane(value, i).reinterpret_as_int() >=
      u32_lane(other, i).reinterpret_as_int(),
    )
  })
}

///|
/// Lane-wise greater-than-or-equal comparison (unsigned) over four 32-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i32x4_ge_u")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i32x4_ge_u(value : V128, other : V128) -> V128 {
  pack_u32x4_by(i => bool_to_u32_mask(u32_lane(value, i) >= u32_lane(other, i)))
}

///|
/// Lane-wise equality comparison over two 64-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i64x2_eq")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i64x2_eq(value : V128, other : V128) -> V128 {
  pack_u64x2_by(i => bool_to_u64_mask(u64_lane(value, i) == u64_lane(other, i)))
}

///|
/// Lane-wise inequality comparison over two 64-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i64x2_ne")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i64x2_ne(value : V128, other : V128) -> V128 {
  pack_u64x2_by(i => bool_to_u64_mask(u64_lane(value, i) != u64_lane(other, i)))
}

///|
/// Lane-wise less-than comparison (signed) over two 64-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i64x2_lt_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i64x2_lt_s(value : V128, other : V128) -> V128 {
  pack_u64x2_by(i => {
    bool_to_u64_mask(
      u64_lane(value, i).reinterpret_as_int64() <
      u64_lane(other, i).reinterpret_as_int64(),
    )
  })
}

///|
/// Lane-wise less-than-or-equal comparison (signed) over two 64-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i64x2_le_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i64x2_le_s(value : V128, other : V128) -> V128 {
  pack_u64x2_by(i => {
    bool_to_u64_mask(
      u64_lane(value, i).reinterpret_as_int64() <=
      u64_lane(other, i).reinterpret_as_int64(),
    )
  })
}

///|
/// Lane-wise greater-than comparison (signed) over two 64-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i64x2_gt_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i64x2_gt_s(value : V128, other : V128) -> V128 {
  pack_u64x2_by(i => {
    bool_to_u64_mask(
      u64_lane(value, i).reinterpret_as_int64() >
      u64_lane(other, i).reinterpret_as_int64(),
    )
  })
}

///|
/// Lane-wise greater-than-or-equal comparison (signed) over two 64-bit integer lanes; each lane is all-ones when true, zero otherwise.
#intrinsic("%v128.i64x2_ge_s")
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
#as_free_fn
pub fn V128::i64x2_ge_s(value : V128, other : V128) -> V128 {
  pack_u64x2_by(i => {
    bool_to_u64_mask(
      u64_lane(value, i).reinterpret_as_int64() >=
      u64_lane(other, i).reinterpret_as_int64(),
    )
  })
}
