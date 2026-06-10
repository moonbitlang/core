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
fn pack_f32x4_by(f : (Int) -> Float) -> V128 {
  pack_u32x4_by(i => f(i).reinterpret_as_uint())
}

///|
fn pack_f64x2_by(f : (Int) -> Double) -> V128 {
  pack_u64x2_by(i => f(i).reinterpret_as_uint64())
}

///|
fn f32x4_map(value : V128, f : (Float) -> Float) -> V128 {
  pack_f32x4_by(i => f(f32x4_extract_lane(value, i)))
}

///|
fn f64x2_map(value : V128, f : (Double) -> Double) -> V128 {
  pack_f64x2_by(i => f(f64x2_extract_lane(value, i)))
}

///|
fn f32x4_zip(value : V128, other : V128, f : (Float, Float) -> Float) -> V128 {
  pack_f32x4_by(i => {
    f(f32x4_extract_lane(value, i), f32x4_extract_lane(other, i))
  })
}

///|
fn f64x2_zip(
  value : V128,
  other : V128,
  f : (Double, Double) -> Double,
) -> V128 {
  pack_f64x2_by(i => {
    f(f64x2_extract_lane(value, i), f64x2_extract_lane(other, i))
  })
}

///|
fn f32x4_compare(
  value : V128,
  other : V128,
  f : (Float, Float) -> Bool,
) -> V128 {
  pack_u32x4_by(i => {
    bool_to_u32_mask(
      f(f32x4_extract_lane(value, i), f32x4_extract_lane(other, i)),
    )
  })
}

///|
fn f64x2_compare(
  value : V128,
  other : V128,
  f : (Double, Double) -> Bool,
) -> V128 {
  pack_u64x2_by(i => {
    bool_to_u64_mask(
      f(f64x2_extract_lane(value, i), f64x2_extract_lane(other, i)),
    )
  })
}

///|
fn f32_nearest_even(value : Float) -> Float {
  if value.is_nan() || value.is_inf() || value == 0.0F {
    value
  } else {
    let down = value.floor()
    let up = value.ceil()
    let down_delta = value - down
    let up_delta = up - value
    if down_delta < up_delta {
      down
    } else if down_delta > up_delta {
      up
    } else if (down / 2.0F).trunc() * 2.0F == down {
      down
    } else {
      up
    }
  }
}

///|
fn f64_nearest_even(value : Double) -> Double {
  if value.is_nan() || value.is_inf() || value == 0.0 {
    value
  } else {
    let down = value.floor()
    let up = value.ceil()
    let down_delta = value - down
    let up_delta = up - value
    if down_delta < up_delta {
      down
    } else if down_delta > up_delta {
      up
    } else if (down / 2.0).trunc() * 2.0 == down {
      down
    } else {
      up
    }
  }
}

///|
/// Wasm `min` semantics: NaN in either operand propagates, and
/// `min(-0.0, +0.0)` is `-0.0`.
fn f32_min(value : Float, other : Float) -> Float {
  if value.is_nan() {
    value
  } else if other.is_nan() {
    other
  } else if value == other {
    Float::reinterpret_from_uint(
      value.reinterpret_as_uint() | other.reinterpret_as_uint(),
    )
  } else if value < other {
    value
  } else {
    other
  }
}

///|
/// Wasm `max` semantics: NaN in either operand propagates, and
/// `max(-0.0, +0.0)` is `+0.0`.
fn f32_max(value : Float, other : Float) -> Float {
  if value.is_nan() {
    value
  } else if other.is_nan() {
    other
  } else if value == other {
    Float::reinterpret_from_uint(
      value.reinterpret_as_uint() & other.reinterpret_as_uint(),
    )
  } else if value > other {
    value
  } else {
    other
  }
}

///|
fn f64_min(value : Double, other : Double) -> Double {
  if value.is_nan() {
    value
  } else if other.is_nan() {
    other
  } else if value == other {
    (value.reinterpret_as_uint64() | other.reinterpret_as_uint64()).reinterpret_as_double()
  } else if value < other {
    value
  } else {
    other
  }
}

///|
fn f64_max(value : Double, other : Double) -> Double {
  if value.is_nan() {
    value
  } else if other.is_nan() {
    other
  } else if value == other {
    (value.reinterpret_as_uint64() & other.reinterpret_as_uint64()).reinterpret_as_double()
  } else if value > other {
    value
  } else {
    other
  }
}

///|
/// Wasm `pmin(z1, z2)` is `z2 < z1 ? z2 : z1`: the first operand wins on
/// ties and NaN.
fn f32_pmin(value : Float, other : Float) -> Float {
  if other < value {
    other
  } else {
    value
  }
}

///|
fn f32_pmax(value : Float, other : Float) -> Float {
  if value < other {
    other
  } else {
    value
  }
}

///|
fn f64_pmin(value : Double, other : Double) -> Double {
  if other < value {
    other
  } else {
    value
  }
}

///|
fn f64_pmax(value : Double, other : Double) -> Double {
  if value < other {
    other
  } else {
    value
  }
}

///|
fn f32_trunc_sat_s(value : Float) -> UInt {
  value.to_int().reinterpret_as_uint()
}

///|
fn f32_trunc_sat_u(value : Float) -> UInt {
  value.to_double().to_uint()
}

///|
fn f64_trunc_sat_s(value : Double) -> UInt {
  value.to_int().reinterpret_as_uint()
}

///|
fn f64_trunc_sat_u(value : Double) -> UInt {
  value.to_uint()
}

///|
pub fn f32x4_abs(value : V128) -> V128 {
  f32x4_map(value, fn(x) { x.abs() })
}

///|
pub fn f32x4_neg(value : V128) -> V128 {
  f32x4_map(value, fn(x) { -x })
}

///|
pub fn f32x4_sqrt(value : V128) -> V128 {
  f32x4_map(value, fn(x) { x.sqrt() })
}

///|
pub fn f32x4_ceil(value : V128) -> V128 {
  f32x4_map(value, fn(x) { x.ceil() })
}

///|
pub fn f32x4_floor(value : V128) -> V128 {
  f32x4_map(value, fn(x) { x.floor() })
}

///|
pub fn f32x4_trunc(value : V128) -> V128 {
  f32x4_map(value, fn(x) { x.trunc() })
}

///|
pub fn f32x4_nearest(value : V128) -> V128 {
  f32x4_map(value, f32_nearest_even)
}

///|
pub fn f32x4_add(value : V128, other : V128) -> V128 {
  f32x4_zip(value, other, fn(x, y) { x + y })
}

///|
pub fn f32x4_sub(value : V128, other : V128) -> V128 {
  f32x4_zip(value, other, fn(x, y) { x - y })
}

///|
pub fn f32x4_mul(value : V128, other : V128) -> V128 {
  f32x4_zip(value, other, fn(x, y) { x * y })
}

///|
pub fn f32x4_div(value : V128, other : V128) -> V128 {
  f32x4_zip(value, other, fn(x, y) { x / y })
}

///|
pub fn f32x4_min(value : V128, other : V128) -> V128 {
  f32x4_zip(value, other, f32_min)
}

///|
pub fn f32x4_max(value : V128, other : V128) -> V128 {
  f32x4_zip(value, other, f32_max)
}

///|
pub fn f32x4_pmin(value : V128, other : V128) -> V128 {
  f32x4_zip(value, other, f32_pmin)
}

///|
pub fn f32x4_pmax(value : V128, other : V128) -> V128 {
  f32x4_zip(value, other, f32_pmax)
}

///|
pub fn f32x4_relaxed_min(value : V128, other : V128) -> V128 {
  f32x4_min(value, other)
}

///|
pub fn f32x4_relaxed_max(value : V128, other : V128) -> V128 {
  f32x4_max(value, other)
}

///|
pub fn f32x4_relaxed_madd(value : V128, other : V128, addend : V128) -> V128 {
  pack_f32x4_by(i => {
    f32x4_extract_lane(value, i) * f32x4_extract_lane(other, i) +
    f32x4_extract_lane(addend, i)
  })
}

///|
pub fn f32x4_relaxed_nmadd(value : V128, other : V128, addend : V128) -> V128 {
  pack_f32x4_by(i => {
    f32x4_extract_lane(addend, i) -
    f32x4_extract_lane(value, i) * f32x4_extract_lane(other, i)
  })
}

///|
pub fn f32x4_eq(value : V128, other : V128) -> V128 {
  f32x4_compare(value, other, fn(x, y) { x == y })
}

///|
pub fn f32x4_ne(value : V128, other : V128) -> V128 {
  f32x4_compare(value, other, fn(x, y) { x != y })
}

///|
pub fn f32x4_lt(value : V128, other : V128) -> V128 {
  f32x4_compare(value, other, fn(x, y) { x < y })
}

///|
pub fn f32x4_le(value : V128, other : V128) -> V128 {
  f32x4_compare(value, other, fn(x, y) { x <= y })
}

///|
pub fn f32x4_gt(value : V128, other : V128) -> V128 {
  f32x4_compare(value, other, fn(x, y) { x > y })
}

///|
pub fn f32x4_ge(value : V128, other : V128) -> V128 {
  f32x4_compare(value, other, fn(x, y) { x >= y })
}

///|
pub fn f32x4_convert_i32x4_s(value : V128) -> V128 {
  pack_f32x4_by(i => Float::from_int(u32_lane(value, i).reinterpret_as_int()))
}

///|
pub fn f32x4_convert_i32x4_u(value : V128) -> V128 {
  pack_f32x4_by(i => Float::from_uint(u32_lane(value, i)))
}

///|
pub fn f32x4_demote_f64x2_zero(value : V128) -> V128 {
  f32x4_const(
    Float::from_double(f64x2_extract_lane(value, 0)),
    Float::from_double(f64x2_extract_lane(value, 1)),
    0.0F,
    0.0F,
  )
}

///|
pub fn i32x4_trunc_sat_f32x4_s(value : V128) -> V128 {
  pack_u32x4_by(i => f32_trunc_sat_s(f32x4_extract_lane(value, i)))
}

///|
pub fn i32x4_trunc_sat_f32x4_u(value : V128) -> V128 {
  pack_u32x4_by(i => f32_trunc_sat_u(f32x4_extract_lane(value, i)))
}

///|
pub fn i32x4_relaxed_trunc_f32x4_s(value : V128) -> V128 {
  i32x4_trunc_sat_f32x4_s(value)
}

///|
pub fn i32x4_relaxed_trunc_f32x4_u(value : V128) -> V128 {
  i32x4_trunc_sat_f32x4_u(value)
}

///|
pub fn f64x2_abs(value : V128) -> V128 {
  f64x2_map(value, fn(x) { x.abs() })
}

///|
pub fn f64x2_neg(value : V128) -> V128 {
  f64x2_map(value, fn(x) { -x })
}

///|
pub fn f64x2_sqrt(value : V128) -> V128 {
  f64x2_map(value, fn(x) { x.sqrt() })
}

///|
pub fn f64x2_ceil(value : V128) -> V128 {
  f64x2_map(value, fn(x) { x.ceil() })
}

///|
pub fn f64x2_floor(value : V128) -> V128 {
  f64x2_map(value, fn(x) { x.floor() })
}

///|
pub fn f64x2_trunc(value : V128) -> V128 {
  f64x2_map(value, fn(x) { x.trunc() })
}

///|
pub fn f64x2_nearest(value : V128) -> V128 {
  f64x2_map(value, f64_nearest_even)
}

///|
pub fn f64x2_add(value : V128, other : V128) -> V128 {
  f64x2_zip(value, other, fn(x, y) { x + y })
}

///|
pub fn f64x2_sub(value : V128, other : V128) -> V128 {
  f64x2_zip(value, other, fn(x, y) { x - y })
}

///|
pub fn f64x2_mul(value : V128, other : V128) -> V128 {
  f64x2_zip(value, other, fn(x, y) { x * y })
}

///|
pub fn f64x2_div(value : V128, other : V128) -> V128 {
  f64x2_zip(value, other, fn(x, y) { x / y })
}

///|
pub fn f64x2_min(value : V128, other : V128) -> V128 {
  f64x2_zip(value, other, f64_min)
}

///|
pub fn f64x2_max(value : V128, other : V128) -> V128 {
  f64x2_zip(value, other, f64_max)
}

///|
pub fn f64x2_pmin(value : V128, other : V128) -> V128 {
  f64x2_zip(value, other, f64_pmin)
}

///|
pub fn f64x2_pmax(value : V128, other : V128) -> V128 {
  f64x2_zip(value, other, f64_pmax)
}

///|
pub fn f64x2_relaxed_min(value : V128, other : V128) -> V128 {
  f64x2_min(value, other)
}

///|
pub fn f64x2_relaxed_max(value : V128, other : V128) -> V128 {
  f64x2_max(value, other)
}

///|
pub fn f64x2_relaxed_madd(value : V128, other : V128, addend : V128) -> V128 {
  pack_f64x2_by(i => {
    f64x2_extract_lane(value, i) * f64x2_extract_lane(other, i) +
    f64x2_extract_lane(addend, i)
  })
}

///|
pub fn f64x2_relaxed_nmadd(value : V128, other : V128, addend : V128) -> V128 {
  pack_f64x2_by(i => {
    f64x2_extract_lane(addend, i) -
    f64x2_extract_lane(value, i) * f64x2_extract_lane(other, i)
  })
}

///|
pub fn f64x2_eq(value : V128, other : V128) -> V128 {
  f64x2_compare(value, other, fn(x, y) { x == y })
}

///|
pub fn f64x2_ne(value : V128, other : V128) -> V128 {
  f64x2_compare(value, other, fn(x, y) { x != y })
}

///|
pub fn f64x2_lt(value : V128, other : V128) -> V128 {
  f64x2_compare(value, other, fn(x, y) { x < y })
}

///|
pub fn f64x2_le(value : V128, other : V128) -> V128 {
  f64x2_compare(value, other, fn(x, y) { x <= y })
}

///|
pub fn f64x2_gt(value : V128, other : V128) -> V128 {
  f64x2_compare(value, other, fn(x, y) { x > y })
}

///|
pub fn f64x2_ge(value : V128, other : V128) -> V128 {
  f64x2_compare(value, other, fn(x, y) { x >= y })
}

///|
pub fn f64x2_convert_low_i32x4_s(value : V128) -> V128 {
  pack_f64x2_by(i => Double::from_int(u32_lane(value, i).reinterpret_as_int()))
}

///|
pub fn f64x2_convert_low_i32x4_u(value : V128) -> V128 {
  pack_f64x2_by(i => Double::convert_uint(u32_lane(value, i)))
}

///|
pub fn f64x2_promote_low_f32x4(value : V128) -> V128 {
  pack_f64x2_by(i => f32x4_extract_lane(value, i).to_double())
}

///|
pub fn i32x4_trunc_sat_f64x2_s_zero(value : V128) -> V128 {
  i32x4_const(
    f64_trunc_sat_s(f64x2_extract_lane(value, 0)),
    f64_trunc_sat_s(f64x2_extract_lane(value, 1)),
    0,
    0,
  )
}

///|
pub fn i32x4_trunc_sat_f64x2_u_zero(value : V128) -> V128 {
  i32x4_const(
    f64_trunc_sat_u(f64x2_extract_lane(value, 0)),
    f64_trunc_sat_u(f64x2_extract_lane(value, 1)),
    0,
    0,
  )
}

///|
pub fn i32x4_relaxed_trunc_f64x2_s_zero(value : V128) -> V128 {
  i32x4_trunc_sat_f64x2_s_zero(value)
}

///|
pub fn i32x4_relaxed_trunc_f64x2_u_zero(value : V128) -> V128 {
  i32x4_trunc_sat_f64x2_u_zero(value)
}
