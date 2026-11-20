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

// `moonbitlang/core/v128` has been renamed to `moonbitlang/core/simd`.
// Every definition below is a deprecated re-export of its `@simd`
// counterpart.

// Construction, lanes and bitwise operations

///|
#deprecated("use `@simd.i8x16_const` instead")
#doc(hidden)
pub using @simd {i8x16_const}

///|
#deprecated("use `@simd.i16x8_const` instead")
#doc(hidden)
pub using @simd {i16x8_const}

///|
#deprecated("use `@simd.i32x4_const` instead")
#doc(hidden)
pub using @simd {i32x4_const}

///|
#deprecated("use `@simd.i64x2_const` instead")
#doc(hidden)
pub using @simd {i64x2_const}

///|
#deprecated("use `@simd.f32x4_const` instead")
#doc(hidden)
pub using @simd {f32x4_const}

///|
#deprecated("use `@simd.f64x2_const` instead")
#doc(hidden)
pub using @simd {f64x2_const}

///|
#deprecated("use `@simd.i8x16_splat` instead")
#doc(hidden)
pub using @simd {i8x16_splat}

///|
#deprecated("use `@simd.i16x8_splat` instead")
#doc(hidden)
pub using @simd {i16x8_splat}

///|
#deprecated("use `@simd.i32x4_splat` instead")
#doc(hidden)
pub using @simd {i32x4_splat}

///|
#deprecated("use `@simd.i64x2_splat` instead")
#doc(hidden)
pub using @simd {i64x2_splat}

///|
#deprecated("use `@simd.f32x4_splat` instead")
#doc(hidden)
pub using @simd {f32x4_splat}

///|
#deprecated("use `@simd.f64x2_splat` instead")
#doc(hidden)
pub using @simd {f64x2_splat}

///|
#deprecated("use `@simd.i8x16_extract_lane_u` instead")
#doc(hidden)
pub using @simd {i8x16_extract_lane_u}

///|
#deprecated("use `@simd.i8x16_extract_lane_s` instead")
#doc(hidden)
pub using @simd {i8x16_extract_lane_s}

///|
#deprecated("use `@simd.i16x8_extract_lane_u` instead")
#doc(hidden)
pub using @simd {i16x8_extract_lane_u}

///|
#deprecated("use `@simd.i16x8_extract_lane_s` instead")
#doc(hidden)
pub using @simd {i16x8_extract_lane_s}

///|
#deprecated("use `@simd.i32x4_extract_lane` instead")
#doc(hidden)
pub using @simd {i32x4_extract_lane}

///|
#deprecated("use `@simd.i64x2_extract_lane` instead")
#doc(hidden)
pub using @simd {i64x2_extract_lane}

///|
#deprecated("use `@simd.f32x4_extract_lane` instead")
#doc(hidden)
pub using @simd {f32x4_extract_lane}

///|
#deprecated("use `@simd.f64x2_extract_lane` instead")
#doc(hidden)
pub using @simd {f64x2_extract_lane}

///|
#deprecated("use `@simd.i8x16_replace_lane` instead")
#doc(hidden)
pub using @simd {i8x16_replace_lane}

///|
#deprecated("use `@simd.i16x8_replace_lane` instead")
#doc(hidden)
pub using @simd {i16x8_replace_lane}

///|
#deprecated("use `@simd.i32x4_replace_lane` instead")
#doc(hidden)
pub using @simd {i32x4_replace_lane}

///|
#deprecated("use `@simd.i64x2_replace_lane` instead")
#doc(hidden)
pub using @simd {i64x2_replace_lane}

///|
#deprecated("use `@simd.f32x4_replace_lane` instead")
#doc(hidden)
pub using @simd {f32x4_replace_lane}

///|
#deprecated("use `@simd.f64x2_replace_lane` instead")
#doc(hidden)
pub using @simd {f64x2_replace_lane}

///|
#deprecated("use `@simd.v128_not` instead")
#doc(hidden)
pub using @simd {v128_not}

///|
#deprecated("use `@simd.v128_and_` instead")
#doc(hidden)
pub using @simd {v128_and_}

///|
#deprecated("use `@simd.v128_or_` instead")
#doc(hidden)
pub using @simd {v128_or_}

///|
#deprecated("use `@simd.v128_xor` instead")
#doc(hidden)
pub using @simd {v128_xor}

///|
#deprecated("use `@simd.v128_andnot` instead")
#doc(hidden)
pub using @simd {v128_andnot}

///|
#deprecated("use `@simd.v128_bitselect` instead")
#doc(hidden)
pub using @simd {v128_bitselect}

///|
#deprecated("use `@simd.v128_any_true` instead")
#doc(hidden)
pub using @simd {v128_any_true}

// Floating-point operations

///|
#deprecated("use `@simd.f32x4_abs` instead")
#doc(hidden)
pub using @simd {f32x4_abs}

///|
#deprecated("use `@simd.f32x4_neg` instead")
#doc(hidden)
pub using @simd {f32x4_neg}

///|
#deprecated("use `@simd.f32x4_sqrt` instead")
#doc(hidden)
pub using @simd {f32x4_sqrt}

///|
#deprecated("use `@simd.f32x4_ceil` instead")
#doc(hidden)
pub using @simd {f32x4_ceil}

///|
#deprecated("use `@simd.f32x4_floor` instead")
#doc(hidden)
pub using @simd {f32x4_floor}

///|
#deprecated("use `@simd.f32x4_trunc` instead")
#doc(hidden)
pub using @simd {f32x4_trunc}

///|
#deprecated("use `@simd.f32x4_nearest` instead")
#doc(hidden)
pub using @simd {f32x4_nearest}

///|
#deprecated("use `@simd.f32x4_add` instead")
#doc(hidden)
pub using @simd {f32x4_add}

///|
#deprecated("use `@simd.f32x4_sub` instead")
#doc(hidden)
pub using @simd {f32x4_sub}

///|
#deprecated("use `@simd.f32x4_mul` instead")
#doc(hidden)
pub using @simd {f32x4_mul}

///|
#deprecated("use `@simd.f32x4_div` instead")
#doc(hidden)
pub using @simd {f32x4_div}

///|
#deprecated("use `@simd.f32x4_min` instead")
#doc(hidden)
pub using @simd {f32x4_min}

///|
#deprecated("use `@simd.f32x4_max` instead")
#doc(hidden)
pub using @simd {f32x4_max}

///|
#deprecated("use `@simd.f32x4_pmin` instead")
#doc(hidden)
pub using @simd {f32x4_pmin}

///|
#deprecated("use `@simd.f32x4_pmax` instead")
#doc(hidden)
pub using @simd {f32x4_pmax}

///|
#deprecated("use `@simd.f32x4_relaxed_min` instead")
#doc(hidden)
pub using @simd {f32x4_relaxed_min}

///|
#deprecated("use `@simd.f32x4_relaxed_max` instead")
#doc(hidden)
pub using @simd {f32x4_relaxed_max}

///|
#deprecated("use `@simd.f32x4_relaxed_madd` instead")
#doc(hidden)
pub using @simd {f32x4_relaxed_madd}

///|
#deprecated("use `@simd.f32x4_relaxed_nmadd` instead")
#doc(hidden)
pub using @simd {f32x4_relaxed_nmadd}

///|
#deprecated("use `@simd.f32x4_eq` instead")
#doc(hidden)
pub using @simd {f32x4_eq}

///|
#deprecated("use `@simd.f32x4_ne` instead")
#doc(hidden)
pub using @simd {f32x4_ne}

///|
#deprecated("use `@simd.f32x4_lt` instead")
#doc(hidden)
pub using @simd {f32x4_lt}

///|
#deprecated("use `@simd.f32x4_le` instead")
#doc(hidden)
pub using @simd {f32x4_le}

///|
#deprecated("use `@simd.f32x4_gt` instead")
#doc(hidden)
pub using @simd {f32x4_gt}

///|
#deprecated("use `@simd.f32x4_ge` instead")
#doc(hidden)
pub using @simd {f32x4_ge}

///|
#deprecated("use `@simd.f32x4_convert_i32x4_s` instead")
#doc(hidden)
pub using @simd {f32x4_convert_i32x4_s}

///|
#deprecated("use `@simd.f32x4_convert_i32x4_u` instead")
#doc(hidden)
pub using @simd {f32x4_convert_i32x4_u}

///|
#deprecated("use `@simd.f32x4_demote_f64x2_zero` instead")
#doc(hidden)
pub using @simd {f32x4_demote_f64x2_zero}

///|
#deprecated("use `@simd.i32x4_trunc_sat_f32x4_s` instead")
#doc(hidden)
pub using @simd {i32x4_trunc_sat_f32x4_s}

///|
#deprecated("use `@simd.i32x4_trunc_sat_f32x4_u` instead")
#doc(hidden)
pub using @simd {i32x4_trunc_sat_f32x4_u}

///|
#deprecated("use `@simd.i32x4_relaxed_trunc_f32x4_s` instead")
#doc(hidden)
pub using @simd {i32x4_relaxed_trunc_f32x4_s}

///|
#deprecated("use `@simd.i32x4_relaxed_trunc_f32x4_u` instead")
#doc(hidden)
pub using @simd {i32x4_relaxed_trunc_f32x4_u}

///|
#deprecated("use `@simd.f64x2_abs` instead")
#doc(hidden)
pub using @simd {f64x2_abs}

///|
#deprecated("use `@simd.f64x2_neg` instead")
#doc(hidden)
pub using @simd {f64x2_neg}

///|
#deprecated("use `@simd.f64x2_sqrt` instead")
#doc(hidden)
pub using @simd {f64x2_sqrt}

///|
#deprecated("use `@simd.f64x2_ceil` instead")
#doc(hidden)
pub using @simd {f64x2_ceil}

///|
#deprecated("use `@simd.f64x2_floor` instead")
#doc(hidden)
pub using @simd {f64x2_floor}

///|
#deprecated("use `@simd.f64x2_trunc` instead")
#doc(hidden)
pub using @simd {f64x2_trunc}

///|
#deprecated("use `@simd.f64x2_nearest` instead")
#doc(hidden)
pub using @simd {f64x2_nearest}

///|
#deprecated("use `@simd.f64x2_add` instead")
#doc(hidden)
pub using @simd {f64x2_add}

///|
#deprecated("use `@simd.f64x2_sub` instead")
#doc(hidden)
pub using @simd {f64x2_sub}

///|
#deprecated("use `@simd.f64x2_mul` instead")
#doc(hidden)
pub using @simd {f64x2_mul}

///|
#deprecated("use `@simd.f64x2_div` instead")
#doc(hidden)
pub using @simd {f64x2_div}

///|
#deprecated("use `@simd.f64x2_min` instead")
#doc(hidden)
pub using @simd {f64x2_min}

///|
#deprecated("use `@simd.f64x2_max` instead")
#doc(hidden)
pub using @simd {f64x2_max}

///|
#deprecated("use `@simd.f64x2_pmin` instead")
#doc(hidden)
pub using @simd {f64x2_pmin}

///|
#deprecated("use `@simd.f64x2_pmax` instead")
#doc(hidden)
pub using @simd {f64x2_pmax}

///|
#deprecated("use `@simd.f64x2_relaxed_min` instead")
#doc(hidden)
pub using @simd {f64x2_relaxed_min}

///|
#deprecated("use `@simd.f64x2_relaxed_max` instead")
#doc(hidden)
pub using @simd {f64x2_relaxed_max}

///|
#deprecated("use `@simd.f64x2_relaxed_madd` instead")
#doc(hidden)
pub using @simd {f64x2_relaxed_madd}

///|
#deprecated("use `@simd.f64x2_relaxed_nmadd` instead")
#doc(hidden)
pub using @simd {f64x2_relaxed_nmadd}

///|
#deprecated("use `@simd.f64x2_eq` instead")
#doc(hidden)
pub using @simd {f64x2_eq}

///|
#deprecated("use `@simd.f64x2_ne` instead")
#doc(hidden)
pub using @simd {f64x2_ne}

///|
#deprecated("use `@simd.f64x2_lt` instead")
#doc(hidden)
pub using @simd {f64x2_lt}

///|
#deprecated("use `@simd.f64x2_le` instead")
#doc(hidden)
pub using @simd {f64x2_le}

///|
#deprecated("use `@simd.f64x2_gt` instead")
#doc(hidden)
pub using @simd {f64x2_gt}

///|
#deprecated("use `@simd.f64x2_ge` instead")
#doc(hidden)
pub using @simd {f64x2_ge}

///|
#deprecated("use `@simd.f64x2_convert_low_i32x4_s` instead")
#doc(hidden)
pub using @simd {f64x2_convert_low_i32x4_s}

///|
#deprecated("use `@simd.f64x2_convert_low_i32x4_u` instead")
#doc(hidden)
pub using @simd {f64x2_convert_low_i32x4_u}

///|
#deprecated("use `@simd.f64x2_promote_low_f32x4` instead")
#doc(hidden)
pub using @simd {f64x2_promote_low_f32x4}

///|
#deprecated("use `@simd.i32x4_trunc_sat_f64x2_s_zero` instead")
#doc(hidden)
pub using @simd {i32x4_trunc_sat_f64x2_s_zero}

///|
#deprecated("use `@simd.i32x4_trunc_sat_f64x2_u_zero` instead")
#doc(hidden)
pub using @simd {i32x4_trunc_sat_f64x2_u_zero}

///|
#deprecated("use `@simd.i32x4_relaxed_trunc_f64x2_s_zero` instead")
#doc(hidden)
pub using @simd {i32x4_relaxed_trunc_f64x2_s_zero}

///|
#deprecated("use `@simd.i32x4_relaxed_trunc_f64x2_u_zero` instead")
#doc(hidden)
pub using @simd {i32x4_relaxed_trunc_f64x2_u_zero}

// Integer arithmetic

///|
#deprecated("use `@simd.i8x16_add` instead")
#doc(hidden)
pub using @simd {i8x16_add}

///|
#deprecated("use `@simd.i8x16_sub` instead")
#doc(hidden)
pub using @simd {i8x16_sub}

///|
#deprecated("use `@simd.i8x16_add_sat_s` instead")
#doc(hidden)
pub using @simd {i8x16_add_sat_s}

///|
#deprecated("use `@simd.i8x16_add_sat_u` instead")
#doc(hidden)
pub using @simd {i8x16_add_sat_u}

///|
#deprecated("use `@simd.i8x16_sub_sat_s` instead")
#doc(hidden)
pub using @simd {i8x16_sub_sat_s}

///|
#deprecated("use `@simd.i8x16_sub_sat_u` instead")
#doc(hidden)
pub using @simd {i8x16_sub_sat_u}

///|
#deprecated("use `@simd.i8x16_neg` instead")
#doc(hidden)
pub using @simd {i8x16_neg}

///|
#deprecated("use `@simd.i8x16_abs` instead")
#doc(hidden)
pub using @simd {i8x16_abs}

///|
#deprecated("use `@simd.i8x16_min_s` instead")
#doc(hidden)
pub using @simd {i8x16_min_s}

///|
#deprecated("use `@simd.i8x16_min_u` instead")
#doc(hidden)
pub using @simd {i8x16_min_u}

///|
#deprecated("use `@simd.i8x16_max_s` instead")
#doc(hidden)
pub using @simd {i8x16_max_s}

///|
#deprecated("use `@simd.i8x16_max_u` instead")
#doc(hidden)
pub using @simd {i8x16_max_u}

///|
#deprecated("use `@simd.i8x16_avgr_u` instead")
#doc(hidden)
pub using @simd {i8x16_avgr_u}

///|
#deprecated("use `@simd.i8x16_popcnt` instead")
#doc(hidden)
pub using @simd {i8x16_popcnt}

///|
#deprecated("use `@simd.i16x8_add` instead")
#doc(hidden)
pub using @simd {i16x8_add}

///|
#deprecated("use `@simd.i16x8_sub` instead")
#doc(hidden)
pub using @simd {i16x8_sub}

///|
#deprecated("use `@simd.i16x8_add_sat_s` instead")
#doc(hidden)
pub using @simd {i16x8_add_sat_s}

///|
#deprecated("use `@simd.i16x8_add_sat_u` instead")
#doc(hidden)
pub using @simd {i16x8_add_sat_u}

///|
#deprecated("use `@simd.i16x8_sub_sat_s` instead")
#doc(hidden)
pub using @simd {i16x8_sub_sat_s}

///|
#deprecated("use `@simd.i16x8_sub_sat_u` instead")
#doc(hidden)
pub using @simd {i16x8_sub_sat_u}

///|
#deprecated("use `@simd.i16x8_mul` instead")
#doc(hidden)
pub using @simd {i16x8_mul}

///|
#deprecated("use `@simd.i16x8_neg` instead")
#doc(hidden)
pub using @simd {i16x8_neg}

///|
#deprecated("use `@simd.i16x8_abs` instead")
#doc(hidden)
pub using @simd {i16x8_abs}

///|
#deprecated("use `@simd.i16x8_min_s` instead")
#doc(hidden)
pub using @simd {i16x8_min_s}

///|
#deprecated("use `@simd.i16x8_min_u` instead")
#doc(hidden)
pub using @simd {i16x8_min_u}

///|
#deprecated("use `@simd.i16x8_max_s` instead")
#doc(hidden)
pub using @simd {i16x8_max_s}

///|
#deprecated("use `@simd.i16x8_max_u` instead")
#doc(hidden)
pub using @simd {i16x8_max_u}

///|
#deprecated("use `@simd.i16x8_avgr_u` instead")
#doc(hidden)
pub using @simd {i16x8_avgr_u}

///|
#deprecated("use `@simd.i32x4_add` instead")
#doc(hidden)
pub using @simd {i32x4_add}

///|
#deprecated("use `@simd.i32x4_sub` instead")
#doc(hidden)
pub using @simd {i32x4_sub}

///|
#deprecated("use `@simd.i32x4_mul` instead")
#doc(hidden)
pub using @simd {i32x4_mul}

///|
#deprecated("use `@simd.i32x4_neg` instead")
#doc(hidden)
pub using @simd {i32x4_neg}

///|
#deprecated("use `@simd.i32x4_abs` instead")
#doc(hidden)
pub using @simd {i32x4_abs}

///|
#deprecated("use `@simd.i32x4_min_s` instead")
#doc(hidden)
pub using @simd {i32x4_min_s}

///|
#deprecated("use `@simd.i32x4_min_u` instead")
#doc(hidden)
pub using @simd {i32x4_min_u}

///|
#deprecated("use `@simd.i32x4_max_s` instead")
#doc(hidden)
pub using @simd {i32x4_max_s}

///|
#deprecated("use `@simd.i32x4_max_u` instead")
#doc(hidden)
pub using @simd {i32x4_max_u}

///|
#deprecated("use `@simd.i64x2_add` instead")
#doc(hidden)
pub using @simd {i64x2_add}

///|
#deprecated("use `@simd.i64x2_sub` instead")
#doc(hidden)
pub using @simd {i64x2_sub}

///|
#deprecated("use `@simd.i64x2_mul` instead")
#doc(hidden)
pub using @simd {i64x2_mul}

///|
#deprecated("use `@simd.i64x2_neg` instead")
#doc(hidden)
pub using @simd {i64x2_neg}

///|
#deprecated("use `@simd.i64x2_abs` instead")
#doc(hidden)
pub using @simd {i64x2_abs}

// Integer comparisons

///|
#deprecated("use `@simd.i8x16_eq` instead")
#doc(hidden)
pub using @simd {i8x16_eq}

///|
#deprecated("use `@simd.i8x16_ne` instead")
#doc(hidden)
pub using @simd {i8x16_ne}

///|
#deprecated("use `@simd.i8x16_lt_s` instead")
#doc(hidden)
pub using @simd {i8x16_lt_s}

///|
#deprecated("use `@simd.i8x16_lt_u` instead")
#doc(hidden)
pub using @simd {i8x16_lt_u}

///|
#deprecated("use `@simd.i8x16_le_s` instead")
#doc(hidden)
pub using @simd {i8x16_le_s}

///|
#deprecated("use `@simd.i8x16_le_u` instead")
#doc(hidden)
pub using @simd {i8x16_le_u}

///|
#deprecated("use `@simd.i8x16_gt_s` instead")
#doc(hidden)
pub using @simd {i8x16_gt_s}

///|
#deprecated("use `@simd.i8x16_gt_u` instead")
#doc(hidden)
pub using @simd {i8x16_gt_u}

///|
#deprecated("use `@simd.i8x16_ge_s` instead")
#doc(hidden)
pub using @simd {i8x16_ge_s}

///|
#deprecated("use `@simd.i8x16_ge_u` instead")
#doc(hidden)
pub using @simd {i8x16_ge_u}

///|
#deprecated("use `@simd.i16x8_eq` instead")
#doc(hidden)
pub using @simd {i16x8_eq}

///|
#deprecated("use `@simd.i16x8_ne` instead")
#doc(hidden)
pub using @simd {i16x8_ne}

///|
#deprecated("use `@simd.i16x8_lt_s` instead")
#doc(hidden)
pub using @simd {i16x8_lt_s}

///|
#deprecated("use `@simd.i16x8_lt_u` instead")
#doc(hidden)
pub using @simd {i16x8_lt_u}

///|
#deprecated("use `@simd.i16x8_le_s` instead")
#doc(hidden)
pub using @simd {i16x8_le_s}

///|
#deprecated("use `@simd.i16x8_le_u` instead")
#doc(hidden)
pub using @simd {i16x8_le_u}

///|
#deprecated("use `@simd.i16x8_gt_s` instead")
#doc(hidden)
pub using @simd {i16x8_gt_s}

///|
#deprecated("use `@simd.i16x8_gt_u` instead")
#doc(hidden)
pub using @simd {i16x8_gt_u}

///|
#deprecated("use `@simd.i16x8_ge_s` instead")
#doc(hidden)
pub using @simd {i16x8_ge_s}

///|
#deprecated("use `@simd.i16x8_ge_u` instead")
#doc(hidden)
pub using @simd {i16x8_ge_u}

///|
#deprecated("use `@simd.i32x4_eq` instead")
#doc(hidden)
pub using @simd {i32x4_eq}

///|
#deprecated("use `@simd.i32x4_ne` instead")
#doc(hidden)
pub using @simd {i32x4_ne}

///|
#deprecated("use `@simd.i32x4_lt_s` instead")
#doc(hidden)
pub using @simd {i32x4_lt_s}

///|
#deprecated("use `@simd.i32x4_lt_u` instead")
#doc(hidden)
pub using @simd {i32x4_lt_u}

///|
#deprecated("use `@simd.i32x4_le_s` instead")
#doc(hidden)
pub using @simd {i32x4_le_s}

///|
#deprecated("use `@simd.i32x4_le_u` instead")
#doc(hidden)
pub using @simd {i32x4_le_u}

///|
#deprecated("use `@simd.i32x4_gt_s` instead")
#doc(hidden)
pub using @simd {i32x4_gt_s}

///|
#deprecated("use `@simd.i32x4_gt_u` instead")
#doc(hidden)
pub using @simd {i32x4_gt_u}

///|
#deprecated("use `@simd.i32x4_ge_s` instead")
#doc(hidden)
pub using @simd {i32x4_ge_s}

///|
#deprecated("use `@simd.i32x4_ge_u` instead")
#doc(hidden)
pub using @simd {i32x4_ge_u}

///|
#deprecated("use `@simd.i64x2_eq` instead")
#doc(hidden)
pub using @simd {i64x2_eq}

///|
#deprecated("use `@simd.i64x2_ne` instead")
#doc(hidden)
pub using @simd {i64x2_ne}

///|
#deprecated("use `@simd.i64x2_lt_s` instead")
#doc(hidden)
pub using @simd {i64x2_lt_s}

///|
#deprecated("use `@simd.i64x2_le_s` instead")
#doc(hidden)
pub using @simd {i64x2_le_s}

///|
#deprecated("use `@simd.i64x2_gt_s` instead")
#doc(hidden)
pub using @simd {i64x2_gt_s}

///|
#deprecated("use `@simd.i64x2_ge_s` instead")
#doc(hidden)
pub using @simd {i64x2_ge_s}

// Integer extension, narrowing, extended multiplication and dot products

///|
#deprecated("use `@simd.i16x8_extend_low_i8x16_s` instead")
#doc(hidden)
pub using @simd {i16x8_extend_low_i8x16_s}

///|
#deprecated("use `@simd.i16x8_extend_high_i8x16_s` instead")
#doc(hidden)
pub using @simd {i16x8_extend_high_i8x16_s}

///|
#deprecated("use `@simd.i16x8_extend_low_i8x16_u` instead")
#doc(hidden)
pub using @simd {i16x8_extend_low_i8x16_u}

///|
#deprecated("use `@simd.i16x8_extend_high_i8x16_u` instead")
#doc(hidden)
pub using @simd {i16x8_extend_high_i8x16_u}

///|
#deprecated("use `@simd.i32x4_extend_low_i16x8_s` instead")
#doc(hidden)
pub using @simd {i32x4_extend_low_i16x8_s}

///|
#deprecated("use `@simd.i32x4_extend_high_i16x8_s` instead")
#doc(hidden)
pub using @simd {i32x4_extend_high_i16x8_s}

///|
#deprecated("use `@simd.i32x4_extend_low_i16x8_u` instead")
#doc(hidden)
pub using @simd {i32x4_extend_low_i16x8_u}

///|
#deprecated("use `@simd.i32x4_extend_high_i16x8_u` instead")
#doc(hidden)
pub using @simd {i32x4_extend_high_i16x8_u}

///|
#deprecated("use `@simd.i64x2_extend_low_i32x4_s` instead")
#doc(hidden)
pub using @simd {i64x2_extend_low_i32x4_s}

///|
#deprecated("use `@simd.i64x2_extend_high_i32x4_s` instead")
#doc(hidden)
pub using @simd {i64x2_extend_high_i32x4_s}

///|
#deprecated("use `@simd.i64x2_extend_low_i32x4_u` instead")
#doc(hidden)
pub using @simd {i64x2_extend_low_i32x4_u}

///|
#deprecated("use `@simd.i64x2_extend_high_i32x4_u` instead")
#doc(hidden)
pub using @simd {i64x2_extend_high_i32x4_u}

///|
#deprecated("use `@simd.i8x16_relaxed_laneselect` instead")
#doc(hidden)
pub using @simd {i8x16_relaxed_laneselect}

///|
#deprecated("use `@simd.i16x8_relaxed_laneselect` instead")
#doc(hidden)
pub using @simd {i16x8_relaxed_laneselect}

///|
#deprecated("use `@simd.i32x4_relaxed_laneselect` instead")
#doc(hidden)
pub using @simd {i32x4_relaxed_laneselect}

///|
#deprecated("use `@simd.i64x2_relaxed_laneselect` instead")
#doc(hidden)
pub using @simd {i64x2_relaxed_laneselect}

///|
#deprecated("use `@simd.i8x16_narrow_i16x8_s` instead")
#doc(hidden)
pub using @simd {i8x16_narrow_i16x8_s}

///|
#deprecated("use `@simd.i8x16_narrow_i16x8_u` instead")
#doc(hidden)
pub using @simd {i8x16_narrow_i16x8_u}

///|
#deprecated("use `@simd.i16x8_narrow_i32x4_s` instead")
#doc(hidden)
pub using @simd {i16x8_narrow_i32x4_s}

///|
#deprecated("use `@simd.i16x8_narrow_i32x4_u` instead")
#doc(hidden)
pub using @simd {i16x8_narrow_i32x4_u}

///|
#deprecated("use `@simd.i16x8_extmul_low_i8x16_s` instead")
#doc(hidden)
pub using @simd {i16x8_extmul_low_i8x16_s}

///|
#deprecated("use `@simd.i16x8_extmul_high_i8x16_s` instead")
#doc(hidden)
pub using @simd {i16x8_extmul_high_i8x16_s}

///|
#deprecated("use `@simd.i16x8_extmul_low_i8x16_u` instead")
#doc(hidden)
pub using @simd {i16x8_extmul_low_i8x16_u}

///|
#deprecated("use `@simd.i16x8_extmul_high_i8x16_u` instead")
#doc(hidden)
pub using @simd {i16x8_extmul_high_i8x16_u}

///|
#deprecated("use `@simd.i32x4_extmul_low_i16x8_s` instead")
#doc(hidden)
pub using @simd {i32x4_extmul_low_i16x8_s}

///|
#deprecated("use `@simd.i32x4_extmul_high_i16x8_s` instead")
#doc(hidden)
pub using @simd {i32x4_extmul_high_i16x8_s}

///|
#deprecated("use `@simd.i32x4_extmul_low_i16x8_u` instead")
#doc(hidden)
pub using @simd {i32x4_extmul_low_i16x8_u}

///|
#deprecated("use `@simd.i32x4_extmul_high_i16x8_u` instead")
#doc(hidden)
pub using @simd {i32x4_extmul_high_i16x8_u}

///|
#deprecated("use `@simd.i64x2_extmul_low_i32x4_s` instead")
#doc(hidden)
pub using @simd {i64x2_extmul_low_i32x4_s}

///|
#deprecated("use `@simd.i64x2_extmul_high_i32x4_s` instead")
#doc(hidden)
pub using @simd {i64x2_extmul_high_i32x4_s}

///|
#deprecated("use `@simd.i64x2_extmul_low_i32x4_u` instead")
#doc(hidden)
pub using @simd {i64x2_extmul_low_i32x4_u}

///|
#deprecated("use `@simd.i64x2_extmul_high_i32x4_u` instead")
#doc(hidden)
pub using @simd {i64x2_extmul_high_i32x4_u}

///|
#deprecated("use `@simd.i16x8_q15mulr_sat_s` instead")
#doc(hidden)
pub using @simd {i16x8_q15mulr_sat_s}

///|
#deprecated("use `@simd.i16x8_relaxed_q15mulr_s` instead")
#doc(hidden)
pub using @simd {i16x8_relaxed_q15mulr_s}

///|
#deprecated("use `@simd.i16x8_extadd_pairwise_i8x16_s` instead")
#doc(hidden)
pub using @simd {i16x8_extadd_pairwise_i8x16_s}

///|
#deprecated("use `@simd.i16x8_extadd_pairwise_i8x16_u` instead")
#doc(hidden)
pub using @simd {i16x8_extadd_pairwise_i8x16_u}

///|
#deprecated("use `@simd.i32x4_extadd_pairwise_i16x8_s` instead")
#doc(hidden)
pub using @simd {i32x4_extadd_pairwise_i16x8_s}

///|
#deprecated("use `@simd.i32x4_extadd_pairwise_i16x8_u` instead")
#doc(hidden)
pub using @simd {i32x4_extadd_pairwise_i16x8_u}

///|
#deprecated("use `@simd.i16x8_relaxed_dot_i8x16_i7x16_s` instead")
#doc(hidden)
pub using @simd {i16x8_relaxed_dot_i8x16_i7x16_s}

///|
#deprecated("use `@simd.i32x4_dot_i16x8_s` instead")
#doc(hidden)
pub using @simd {i32x4_dot_i16x8_s}

///|
#deprecated("use `@simd.i32x4_relaxed_dot_i8x16_i7x16_add_s` instead")
#doc(hidden)
pub using @simd {i32x4_relaxed_dot_i8x16_i7x16_add_s}

// Shifts, all-true and bitmask

///|
#deprecated("use `@simd.i8x16_shl` instead")
#doc(hidden)
pub using @simd {i8x16_shl}

///|
#deprecated("use `@simd.i8x16_shr_u` instead")
#doc(hidden)
pub using @simd {i8x16_shr_u}

///|
#deprecated("use `@simd.i8x16_shr_s` instead")
#doc(hidden)
pub using @simd {i8x16_shr_s}

///|
#deprecated("use `@simd.i16x8_shl` instead")
#doc(hidden)
pub using @simd {i16x8_shl}

///|
#deprecated("use `@simd.i16x8_shr_u` instead")
#doc(hidden)
pub using @simd {i16x8_shr_u}

///|
#deprecated("use `@simd.i16x8_shr_s` instead")
#doc(hidden)
pub using @simd {i16x8_shr_s}

///|
#deprecated("use `@simd.i32x4_shl` instead")
#doc(hidden)
pub using @simd {i32x4_shl}

///|
#deprecated("use `@simd.i32x4_shr_u` instead")
#doc(hidden)
pub using @simd {i32x4_shr_u}

///|
#deprecated("use `@simd.i32x4_shr_s` instead")
#doc(hidden)
pub using @simd {i32x4_shr_s}

///|
#deprecated("use `@simd.i64x2_shl` instead")
#doc(hidden)
pub using @simd {i64x2_shl}

///|
#deprecated("use `@simd.i64x2_shr_u` instead")
#doc(hidden)
pub using @simd {i64x2_shr_u}

///|
#deprecated("use `@simd.i64x2_shr_s` instead")
#doc(hidden)
pub using @simd {i64x2_shr_s}

///|
#deprecated("use `@simd.i8x16_all_true` instead")
#doc(hidden)
pub using @simd {i8x16_all_true}

///|
#deprecated("use `@simd.i16x8_all_true` instead")
#doc(hidden)
pub using @simd {i16x8_all_true}

///|
#deprecated("use `@simd.i32x4_all_true` instead")
#doc(hidden)
pub using @simd {i32x4_all_true}

///|
#deprecated("use `@simd.i64x2_all_true` instead")
#doc(hidden)
pub using @simd {i64x2_all_true}

///|
#deprecated("use `@simd.i8x16_bitmask` instead")
#doc(hidden)
pub using @simd {i8x16_bitmask}

///|
#deprecated("use `@simd.i16x8_bitmask` instead")
#doc(hidden)
pub using @simd {i16x8_bitmask}

///|
#deprecated("use `@simd.i32x4_bitmask` instead")
#doc(hidden)
pub using @simd {i32x4_bitmask}

///|
#deprecated("use `@simd.i64x2_bitmask` instead")
#doc(hidden)
pub using @simd {i64x2_bitmask}

// Swizzles, shuffles, loads and stores

///|
#deprecated("use `@simd.i8x16_swizzle` instead")
#doc(hidden)
pub using @simd {i8x16_swizzle}

///|
#deprecated("use `@simd.i8x16_relaxed_swizzle` instead")
#doc(hidden)
pub using @simd {i8x16_relaxed_swizzle}

///|
#deprecated("use `@simd.i8x16_shuffle` instead")
#doc(hidden)
pub using @simd {i8x16_shuffle}

///|
#deprecated("use `@simd.v128_load` instead")
#doc(hidden)
pub using @simd {v128_load}

///|
#deprecated("use `@simd.v128_load_i16x8` instead")
#doc(hidden)
pub using @simd {v128_load_i16x8}

///|
#deprecated("use `@simd.v128_load8x8_s` instead")
#doc(hidden)
pub using @simd {v128_load8x8_s}

///|
#deprecated("use `@simd.v128_load8x8_u` instead")
#doc(hidden)
pub using @simd {v128_load8x8_u}

///|
#deprecated("use `@simd.v128_load16x4_s` instead")
#doc(hidden)
pub using @simd {v128_load16x4_s}

///|
#deprecated("use `@simd.v128_load16x4_u` instead")
#doc(hidden)
pub using @simd {v128_load16x4_u}

///|
#deprecated("use `@simd.v128_load32x2_s` instead")
#doc(hidden)
pub using @simd {v128_load32x2_s}

///|
#deprecated("use `@simd.v128_load32x2_u` instead")
#doc(hidden)
pub using @simd {v128_load32x2_u}

///|
#deprecated("use `@simd.v128_load8_splat` instead")
#doc(hidden)
pub using @simd {v128_load8_splat}

///|
#deprecated("use `@simd.v128_load16_splat` instead")
#doc(hidden)
pub using @simd {v128_load16_splat}

///|
#deprecated("use `@simd.v128_load32_splat` instead")
#doc(hidden)
pub using @simd {v128_load32_splat}

///|
#deprecated("use `@simd.v128_load64_splat` instead")
#doc(hidden)
pub using @simd {v128_load64_splat}

///|
#deprecated("use `@simd.v128_load32_zero` instead")
#doc(hidden)
pub using @simd {v128_load32_zero}

///|
#deprecated("use `@simd.v128_load64_zero` instead")
#doc(hidden)
pub using @simd {v128_load64_zero}

///|
#deprecated("use `@simd.v128_load8_lane` instead")
#doc(hidden)
pub using @simd {v128_load8_lane}

///|
#deprecated("use `@simd.v128_load16_lane` instead")
#doc(hidden)
pub using @simd {v128_load16_lane}

///|
#deprecated("use `@simd.v128_load32_lane` instead")
#doc(hidden)
pub using @simd {v128_load32_lane}

///|
#deprecated("use `@simd.v128_load64_lane` instead")
#doc(hidden)
pub using @simd {v128_load64_lane}

///|
#deprecated("use `@simd.v128_store` instead")
#doc(hidden)
pub using @simd {v128_store}

///|
#deprecated("use `@simd.v128_store8_lane` instead")
#doc(hidden)
pub using @simd {v128_store8_lane}

///|
#deprecated("use `@simd.v128_store16_lane` instead")
#doc(hidden)
pub using @simd {v128_store16_lane}

///|
#deprecated("use `@simd.v128_store32_lane` instead")
#doc(hidden)
pub using @simd {v128_store32_lane}

///|
#deprecated("use `@simd.v128_store64_lane` instead")
#doc(hidden)
pub using @simd {v128_store64_lane}
