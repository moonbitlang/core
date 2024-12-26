// Copyright 2024 International Digital Economy Academy
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
pub fn Int64::op_neg(self : Int64) -> Int64 = "%i64_neg"

///|
pub fn Int64::op_add(self : Int64, other : Int64) -> Int64 = "%i64_add"

///|
pub fn Int64::op_sub(self : Int64, other : Int64) -> Int64 = "%i64_sub"

///|
pub fn Int64::op_mul(self : Int64, other : Int64) -> Int64 = "%i64_mul"

///|
pub fn Int64::op_div(self : Int64, other : Int64) -> Int64 = "%i64_div"

///|
pub fn Int64::op_mod(self : Int64, other : Int64) -> Int64 = "%i64_mod"

///|
pub fn Int64::lnot(self : Int64) -> Int64 = "%i64_lnot"

///|
pub fn Int64::land(self : Int64, other : Int64) -> Int64 = "%i64_land"

///|
pub fn Int64::lor(self : Int64, other : Int64) -> Int64 = "%i64_lor"

///|
pub fn Int64::lxor(self : Int64, other : Int64) -> Int64 = "%i64_lxor"

///|
/// @alert deprecated "Use infix operator `<<` instead"
/// @coverage.skip
pub fn Int64::lsl(self : Int64, other : Int) -> Int64 = "%i64_shl"

///|
/// @alert deprecated "Use infix operator `<<` instead"
/// @coverage.skip
pub fn Int64::shl(self : Int64, other : Int) -> Int64 = "%i64_shl"

///|
/// @alert deprecated "Use UInt64 type and infix operator `>>` instead"
/// @coverage.skip
pub fn Int64::lsr(self : Int64, other : Int) -> Int64 = "%u64.shr"

///|
/// @alert deprecated "Use infix operator `>>` instead"
/// @coverage.skip
pub fn Int64::asr(self : Int64, other : Int) -> Int64 = "%i64_shr"

///|
/// @alert deprecated "Use infix operator `>>` instead"
/// @coverage.skip
pub fn Int64::shr(self : Int64, other : Int) -> Int64 = "%i64_shr"

///|
pub fn Int64::op_shl(self : Int64, other : Int) -> Int64 = "%i64_shl"

///|
pub fn Int64::op_shr(self : Int64, other : Int) -> Int64 = "%i64_shr"

///|
pub fn Int64::ctz(self : Int64) -> Int = "%i64_ctz"

///|
pub fn Int64::clz(self : Int64) -> Int = "%i64_clz"

///|
pub fn Int64::popcnt(self : Int64) -> Int = "%i64_popcnt"

///|
pub fn Int64::op_equal(self : Int64, other : Int64) -> Bool = "%i64_eq"

///|
pub fn Int64::compare(self : Int64, other : Int64) -> Int = "%i64_compare"

///|
pub fn Int64::default() -> Int64 = "%i64_default"

///|
pub fn Int64::to_int(self : Int64) -> Int = "%i64_to_i32"

///|
pub fn Int64::to_double(self : Int64) -> Double = "%i64_to_f64"

///|
pub fn Int64::reinterpret_as_double(self : Int64) -> Double = "%i64_to_f64_reinterpret"

///|
pub fn UInt64::reinterpret_as_double(self : UInt64) -> Double = "%i64_to_f64_reinterpret"

///|
pub fn Int64::to_byte(self : Int64) -> Byte = "%i64_to_byte"

///|
pub fn UInt64::trunc_double(val : Double) -> UInt64 = "%f64.to_u64"

///|
pub fn Int64::to_float(self : Int64) -> Float = "%i64.to_f32"

///|
pub fn UInt64::extend_uint(val : UInt) -> UInt64 = "%u32.to_u64"

///|
pub fn Int::to_int64(self : Int) -> Int64 = "%i32_to_i64"

///|
fn Double::unchecked_to_int64(self : Double) -> Int64 = "%f64_to_i64"

///|
/// Converts a double-precision floating-point number to a 64-bit integer.
/// Handles special cases including NaN and numbers outside the valid Int range.
///
/// Parameters:
///
/// * `self` : The double-precision floating-point number to be converted.
///
/// Returns an 64-bit integer value according to the following rules:
///
/// * Returns 0 if the input is NaN
/// * Returns `@int64.max_value` (9223372036854775807L) if the input is greater than or
///   equal to `@int64.max_value`
/// * Returns `@int64.min_value` (-9223372036854775808L) if the input is less than or equal
///   to `@int64.min_value`
/// * Otherwise returns the integer part of the input by truncating towards zero
///
/// Example:
///
/// ```moonbit
/// test "Double::to_int64" {
///   inspect!(42.0.to_int64(), content="42")
///   inspect!((-42.5).to_int64(), content="-42")
///   inspect!((0.0 / 0.0).to_int64(), content="0") // NaN
///   inspect!((1.0 / 0.0).to_int64(), content="9223372036854775807") // Infinity
///   inspect!((-1.0 / 0.0).to_int64(), content="-9223372036854775808") // -Infinity
/// }
/// ```
pub fn Double::to_int64(self : Double) -> Int64 {
  if self != self {
    0
  } else if self >= 9223372036854775807 {
    9223372036854775807L
  } else if self <= -9223372036854775808 {
    -9223372036854775808L
  } else {
    self.unchecked_to_int64()
  }
}

///|
/// @alert deprecated "Use `reinterpret_as_int64` instead"
/// @coverage.skip
pub fn Double::reinterpret_as_i64(self : Double) -> Int64 = "%f64_to_i64_reinterpret"

///|
pub fn Double::reinterpret_as_int64(self : Double) -> Int64 = "%f64_to_i64_reinterpret"

///|
/// @alert deprecated "Use `reinterpret_as_uint64` instead"
/// @coverage.skip
pub fn Double::reinterpret_as_u64(self : Double) -> UInt64 = "%f64_to_i64_reinterpret"

///|
pub fn Double::reinterpret_as_uint64(self : Double) -> UInt64 = "%f64_to_i64_reinterpret"

///|
pub fn Double::convert_uint64(val : UInt64) -> Double = "%u64.to_f64"

///|
/// @alert deprecated "Use `reinterpret_as_uint64` instead"
/// @coverage.skip
pub fn Int64::to_uint64(self : Int64) -> UInt64 = "%i64.to_u64_reinterpret"

///|
pub fn Int64::reinterpret_as_uint64(self : Int64) -> UInt64 = "%i64.to_u64_reinterpret"

///|
/// @alert deprecated "Use `reinterpret_as_int64` instead"
/// @coverage.skip
pub fn UInt64::to_int64(self : UInt64) -> Int64 = "%u64.to_i64_reinterpret"

///|
pub fn UInt64::reinterpret_as_int64(self : UInt64) -> Int64 = "%u64.to_i64_reinterpret"

///|
pub fn UInt64::to_uint(self : UInt64) -> UInt = "%u64.to_u32"

///|
pub fn UInt64::to_int(self : UInt64) -> Int = "%u64.to_i32"

///|
pub fn UInt64::to_double(self : UInt64) -> Double = "%u64.to_f64"

///|
pub fn UInt64::op_add(self : UInt64, other : UInt64) -> UInt64 = "%u64.add"

///|
pub fn UInt64::op_sub(self : UInt64, other : UInt64) -> UInt64 = "%u64.sub"

///|
pub fn UInt64::op_mul(self : UInt64, other : UInt64) -> UInt64 = "%u64.mul"

///|
pub fn UInt64::op_div(self : UInt64, other : UInt64) -> UInt64 = "%u64.div"

///|
pub fn UInt64::op_mod(self : UInt64, other : UInt64) -> UInt64 = "%u64.mod"

///|
pub fn UInt64::compare(self : UInt64, other : UInt64) -> Int = "%u64.compare"

///|
pub fn UInt64::op_equal(self : UInt64, other : UInt64) -> Bool = "%u64.eq"

///|
pub fn UInt64::land(self : UInt64, other : UInt64) -> UInt64 = "%u64.bitand"

///|
pub fn UInt64::lor(self : UInt64, other : UInt64) -> UInt64 = "%u64.bitor"

///|
pub fn UInt64::lxor(self : UInt64, other : UInt64) -> UInt64 = "%u64.bitxor"

///|
pub fn UInt64::lnot(self : UInt64) -> UInt64 = "%u64.bitnot"

///|
/// @alert deprecated "Use infix operator `<<` instead"
/// @coverage.skip
pub fn UInt64::lsl(self : UInt64, shift : Int) -> UInt64 = "%u64.shl"

///|
/// @alert deprecated "Use infix operator `<<` instead"
/// @coverage.skip
pub fn UInt64::shl(self : UInt64, shift : Int) -> UInt64 = "%u64.shl"

///|
/// @alert deprecated "Use infix operator `>>` instead"
/// @coverage.skip
pub fn UInt64::shr(self : UInt64, shift : Int) -> UInt64 = "%u64.shr"

///|
/// @alert deprecated "Use infix operator `>>` instead"
/// @coverage.skip
pub fn UInt64::lsr(self : UInt64, shift : Int) -> UInt64 = "%u64.shr"

///|
pub fn UInt64::op_shl(self : UInt64, shift : Int) -> UInt64 = "%u64.shl"

///|
pub fn UInt64::op_shr(self : UInt64, shift : Int) -> UInt64 = "%u64.shr"

///|
pub fn UInt64::clz(self : UInt64) -> Int = "%u64.clz"

///|
pub fn UInt64::ctz(self : UInt64) -> Int = "%u64.ctz"

///|
pub fn UInt64::popcnt(self : UInt64) -> Int = "%u64.popcnt"

///|
pub fn UInt64::to_float(self : UInt64) -> Float = "%u64.to_f32"
