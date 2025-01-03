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
extern "js" fn MyInt64::from_double(value : Double) -> MyInt64 =
  #|(a) => {
  #|  if (isNaN(a)) {
  #|    return { hi: 0, lo: 0 };
  #|  }
  #|  if (a >= 9223372036854775807) {
  #|    return { hi: 0x7fffffff, lo: 0xffffffff };
  #|  }
  #|  if (a <= -9223372036854775808) {
  #|    return { hi: -2147483648, lo: 0 };
  #|  }
  #|  let neg = false;
  #|  if (a < 0) {
  #|    neg = true;
  #|    a = -a;
  #|  }
  #|  let hi = (a * (1 / 0x100000000)) | 0;
  #|  let lo = a >>> 0;
  #|  if (neg) {
  #|    if (lo === 0) {
  #|      hi = ~hi + 1;
  #|    } else {
  #|      hi = ~hi;
  #|      lo = ~lo + 1;
  #|    }
  #|  }
  #|  return { hi, lo };
  #|}

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
  MyInt64::from_double(self).to_int64()
}

///|
extern "js" fn MyInt64::from_double_unsigned(value : Double) -> MyInt64 =
  #|(a) => {
  #|  if (isNaN(a)) {
  #|    return { hi: 0, lo: 0 };
  #|  }
  #|  if (a >= 18446744073709551615) {
  #|    return { hi: 0xffffffff, lo: 0xffffffff };
  #|  }
  #|  if (a <= 0) {
  #|    return { hi: 0, lo: 0 };
  #|  }
  #|  let hi = (a * (1 / 0x100000000)) | 0;
  #|  let lo = a >>> 0;
  #|  return { hi, lo };
  #|}

///|
/// Converts a double-precision floating-point number to an unsigned 64-bit
/// integer, handling special cases and value ranges.
///
/// Parameters:
///
/// * `value` : The double-precision floating-point number to be converted.
///
/// Returns an unsigned 64-bit integer value according to the following rules:
///
/// * Returns 0 if the input is NaN
/// * Returns `UInt64::max_value` (18446744073709551615UL) if the input is
/// greater than or equal to `UInt64::max_value`
/// * Returns 0UL if the input is less than or equal to 0
/// * Otherwise returns the integer part of the input by truncating towards zero
///
/// Example:
///
/// ```moonbit
/// test "Double::to_uint64" {
///   inspect!(42.0.to_uint64(), content="42")
///   inspect!((-42.5).to_uint64(), content="0")
///   inspect!((0.0 / 0.0).to_uint64(), content="0") // NaN
///   inspect!((1.0 / 0.0).to_uint64(), content="18446744073709551615") // Infinity
/// }
/// ```
pub fn Double::to_uint64(self : Double) -> UInt64 {
  MyInt64::from_double_unsigned(self).to_uint64()
}
