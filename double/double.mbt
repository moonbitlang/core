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

pub let not_a_number : Double = 0x7FF8000000000001L.reinterpret_as_double()

pub let infinity : Double = 0x7FF0000000000000L.reinterpret_as_double()

pub let neg_infinity : Double = 0xFFF0000000000000L.reinterpret_as_double()

pub let max_value : Double = 0x7FEFFFFFFFFFFFFFL.reinterpret_as_double()

pub let min_value : Double = 0xFFEFFFFFFFFFFFFFL.reinterpret_as_double()

pub let min_positive : Double = 0x0010000000000000L.reinterpret_as_double()

let sign_mask : Int64 = 0x8000_0000_0000_0000L

pub fn Double::from_int(i : Int) -> Double {
  i.to_double()
}

pub fn abs(self : Double) -> Double {
  if self < 0.0 {
    -self
  } else {
    self
  }
}

pub fn trunc(self : Double) -> Double {
  let u64 = self.reinterpret_as_i64()
  let biased_exp = u64.lsr(52).land(0x7ffL).to_int()
  if biased_exp < 1023 {
    return u64.land(sign_mask).reinterpret_as_double()
  }
  if biased_exp >= 1075 {
    return self
  }
  u64.land(sign_mask.asr(biased_exp - 1012)).reinterpret_as_double()
}

test "trunc" {
  assert_eq!(4503599627370497.0.trunc(), 4503599627370497.0)
  assert_eq!(2251799813685248.5.trunc(), 2251799813685248.0)
  assert_eq!(4.5.trunc(), 4.0)
  assert_eq!(1.5.trunc(), 1.0)
  assert_eq!(1.0.trunc(), 1.0)
  assert_eq!(0.2.trunc(), 0.0)
  assert_eq!(0.0.trunc(), 0.0)
  assert_eq!((-0.0).trunc().reinterpret_as_i64(), sign_mask)
  assert_eq!((-0.2).trunc().reinterpret_as_i64(), sign_mask)
  assert_eq!((-1.0).trunc(), -1.0)
  assert_eq!((-1.5).trunc(), -1.0)
  assert_eq!((-2251799813685248.5).trunc(), -2251799813685248.0)
  assert_eq!((-4503599627370497.0).trunc(), -4503599627370497.0)
}

pub fn ceil(self : Double) -> Double {
  let trunced = self.trunc()
  if self == trunced || self < 0.0 {
    trunced
  } else {
    trunced + 1.0
  }
}

test "ceil" {
  assert_eq!(2251799813685248.5.ceil(), 2251799813685249.0)
  assert_eq!(1.1.ceil(), 2.0)
  assert_eq!(1.0.ceil(), 1.0)
  assert_eq!(0.9.ceil(), 1.0)
  assert_eq!(0.0.ceil(), 0.0)
  assert_eq!((-0.0).ceil().reinterpret_as_i64(), sign_mask)
  assert_eq!((-0.1).ceil().reinterpret_as_i64(), sign_mask)
  assert_eq!((-2251799813685248.5).ceil(), -2251799813685248.0)
}

pub fn floor(self : Double) -> Double {
  let trunced = self.trunc()
  if self == trunced || self > 0.0 {
    trunced
  } else {
    trunced - 1.0
  }
}

test "floor" {
  assert_eq!(2251799813685248.5.floor(), 2251799813685248.0)
  assert_eq!(1.1.floor(), 1.0)
  assert_eq!(1.0.floor(), 1.0)
  assert_eq!(0.9.floor(), 0.0)
  assert_eq!(0.0.floor(), 0.0)
  assert_eq!((-0.0).floor().reinterpret_as_i64(), sign_mask)
  assert_eq!((-0.1).floor(), -1.0)
  assert_eq!((-2251799813685248.5).floor(), -2251799813685249.0)
}

pub fn round(self : Double) -> Double {
  let u64 = self.reinterpret_as_i64()
  let biased_exp = u64.lsr(52).land(0x7ffL).to_int()
  if biased_exp >= 1075 {
    return self
  } else if biased_exp < 1022 {
    return u64.land(sign_mask).reinterpret_as_double()
  } else if biased_exp == 1022 {
    return u64
      .land(sign_mask)
      .lor(0x3FF0_0000_0000_0000L)
      .reinterpret_as_double()
  }
  let trunced = u64
    .land(sign_mask.asr(biased_exp - 1012))
    .reinterpret_as_double()
  if u64.land(sign_mask.lsr(biased_exp - 1011)) == 0L {
    return trunced
  } else if self > 0.0 {
    return trunced + 1.0
  } else {
    return trunced - 1.0
  }
}

test "round" {
  assert_eq!(4503599627370497.5.round(), 4503599627370498.0)
  assert_eq!(2251799813685248.5.round(), 2251799813685249.0)
  assert_eq!(5.5.round(), 6.0)
  assert_eq!(5.2.round(), 5.0)
  assert_eq!(1.1.round(), 1.0)
  assert_eq!(1.0.round(), 1.0)
  assert_eq!(0.9.round(), 1.0)
  assert_eq!(0.5.round(), 1.0)
  assert_eq!(0.4.round(), 0.0)
  assert_eq!(0.0.round(), 0.0)
  assert_eq!((-0.0).round().reinterpret_as_i64(), sign_mask)
  assert_eq!((-0.1).round().reinterpret_as_i64(), sign_mask)
  assert_eq!((-0.5).round(), -1.0)
  assert_eq!((-2251799813685248.5).round(), -2251799813685249.0)
}

/// Returns the sign of the double.
/// - If the double is positive, returns 1.0.
/// - If the double is negative, returns -1.0.
/// - Otherwise, returns the double itself (0.0, -0.0 and NaN).
pub fn signum(self : Double) -> Double {
  if self < 0.0 {
    -1.0
  } else if self > 0.0 {
    1.0
  } else {
    self // handles 0.0, -0.0, NaN
  }
}

// Returns a "not-a-number" value
/// @alert deprecated "Use `@double.not_a_number` instead"
pub fn Double::nan() -> Double {
  not_a_number
}

// Returns positive infinity if sign >= 0, negative infinity if sign < 0.
/// @alert deprecated "Use `@double.infinity` and `@double.neg_infinity` instead"
pub fn Double::inf(sign : Int) -> Double {
  if sign >= 0 {
    infinity
  } else {
    neg_infinity
  }
}

// Returns the smallest positive normal value of Double
/// @alert deprecated "Use `@double.min_positive` instead"
pub fn Double::min_normal() -> Double {
  min_positive
}

// Check whether the double is a "not-a-number" value
pub fn is_nan(self : Double) -> Bool {
  // only NaNs satisfy f != f.
  self != self
}

// Check whether the double is infinity
pub fn is_inf(self : Double) -> Bool {
  self > max_value || self < min_value
}

// Check whether the double is positive infinity
pub fn is_pos_inf(self : Double) -> Bool {
  self > max_value
}

// Check whether the double is negative infinity
pub fn is_neg_inf(self : Double) -> Bool {
  self < min_value
}

test "from_int" {
  assert_eq!(Double::from_int(1), 1.0)
  assert_eq!(Double::from_int(0), 0.0)
  assert_eq!(Double::from_int(100000), 1.0e5)
}

test "abs" {
  let d = -1.0
  assert_eq!(d.abs(), 1.0)
  assert_eq!(1.0.abs(), 1.0)
}

test "signum" {
  let d = -2.0
  assert_eq!(d.signum(), -1.0)
  assert_eq!(1.0.signum(), 1.0)
  assert_eq!(0.0.signum(), 0.0)
  assert_true!(not_a_number.signum().is_nan())
}

test "is_nan" {
  assert_true!(is_nan(not_a_number))
  assert_false!(is_nan(0.0))
  assert_false!(is_nan(12345.678))
  assert_false!(is_nan(infinity))
  assert_false!(is_nan(neg_infinity))
}

test "is_inf" {
  assert_true!(is_inf(infinity))
  assert_true!(is_inf(neg_infinity))
  assert_false!(is_inf(0.0))
  assert_false!(is_inf(12345.678))
}

test "is_pos_inf" {
  assert_true!(is_pos_inf(infinity))
  assert_false!(is_pos_inf(neg_infinity))
  assert_false!(is_pos_inf(0.0))
  assert_false!(is_pos_inf(12345.678))
}

test "is_neg_inf" {
  assert_false!(is_neg_inf(infinity))
  assert_true!(is_neg_inf(neg_infinity))
  assert_false!(is_neg_inf(0.0))
  assert_false!(is_neg_inf(12345.678))
}

test "min equal to neg max" {
  assert_true!(min_value == -max_value)
}

pub impl Hash for Double with hash(self) {
  self.reinterpret_as_i64() |> Hash::hash()
}

pub impl Hash for Double with hash_combine(self, hasher) {
  hasher.combine_double(self)
}

/// @intrinsic %f64.to_string
pub fn to_string(self : Double) -> String {
  @ryu.ryu_to_string(self)
}

pub impl Show for Double with output(self, logger) {
  logger.write_string(self.to_string())
}

pub fn is_close(
  self : Double,
  other : Double,
  ~relative_tolerance : Double = 1.0e-09,
  ~absolute_tolerance : Double = 0.0
) -> Bool {
  if relative_tolerance < 0.0 || absolute_tolerance < 0.0 {
    abort("Tolerances must be non-negative")
  }
  if self == other {
    return true
  }
  if self.is_inf() || other.is_inf() {
    return false
  }
  let diff = (other - self).abs()
  return (
      diff <= (relative_tolerance * other).abs() ||
      diff <= (relative_tolerance * self).abs()
    ) ||
    diff <= absolute_tolerance
}
