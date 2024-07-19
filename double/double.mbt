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

let not_a_number : Double = 0x7FF8000000000001L.reinterpret_as_double()

let positive_infinity : Double = 0x7FF0000000000000L.reinterpret_as_double()

let negative_infinity : Double = 0xFFF0000000000000L.reinterpret_as_double()

let max_val : Double = 0x7FEFFFFFFFFFFFFFL.reinterpret_as_double()

let min_val : Double = 0x1L.reinterpret_as_double()

let min_norm : Double = 0x0010000000000000L.reinterpret_as_double()

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
  @test.eq!(4503599627370497.0.trunc(), 4503599627370497.0)
  @test.eq!(2251799813685248.5.trunc(), 2251799813685248.0)
  @test.eq!(4.5.trunc(), 4.0)
  @test.eq!(1.5.trunc(), 1.0)
  @test.eq!(1.0.trunc(), 1.0)
  @test.eq!(0.2.trunc(), 0.0)
  @test.eq!(0.0.trunc(), 0.0)
  @test.eq!((-0.0).trunc().reinterpret_as_i64(), sign_mask)
  @test.eq!((-0.2).trunc().reinterpret_as_i64(), sign_mask)
  @test.eq!((-1.0).trunc(), -1.0)
  @test.eq!((-1.5).trunc(), -1.0)
  @test.eq!((-2251799813685248.5).trunc(), -2251799813685248.0)
  @test.eq!((-4503599627370497.0).trunc(), -4503599627370497.0)
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
  @test.eq!(2251799813685248.5.ceil(), 2251799813685249.0)
  @test.eq!(1.1.ceil(), 2.0)
  @test.eq!(1.0.ceil(), 1.0)
  @test.eq!(0.9.ceil(), 1.0)
  @test.eq!(0.0.ceil(), 0.0)
  @test.eq!((-0.0).ceil().reinterpret_as_i64(), sign_mask)
  @test.eq!((-0.1).ceil().reinterpret_as_i64(), sign_mask)
  @test.eq!((-2251799813685248.5).ceil(), -2251799813685248.0)
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
  @test.eq!(2251799813685248.5.floor(), 2251799813685248.0)
  @test.eq!(1.1.floor(), 1.0)
  @test.eq!(1.0.floor(), 1.0)
  @test.eq!(0.9.floor(), 0.0)
  @test.eq!(0.0.floor(), 0.0)
  @test.eq!((-0.0).floor().reinterpret_as_i64(), sign_mask)
  @test.eq!((-0.1).floor(), -1.0)
  @test.eq!((-2251799813685248.5).floor(), -2251799813685249.0)
}

pub fn round(self : Double) -> Double {
  let u64 = self.reinterpret_as_i64()
  let biased_exp = u64.lsr(52).land(0x7ffL).to_int()
  if biased_exp >= 1075 {
    return self
  } else if biased_exp < 1022 {
    return u64.land(sign_mask).reinterpret_as_double()
  } else if biased_exp == 1022 {
    return u64.land(sign_mask).lor(0x3FF0_0000_0000_0000L).reinterpret_as_double()
  }
  let trunced = u64.land(sign_mask.asr(biased_exp - 1012)).reinterpret_as_double()
  if u64.land(sign_mask.lsr(biased_exp - 1011)) == 0L {
    return trunced
  } else if self > 0.0 {
    return trunced + 1.0
  } else {
    return trunced - 1.0
  }
}

test "round" {
  @test.eq!(4503599627370497.5.round(), 4503599627370498.0)
  @test.eq!(2251799813685248.5.round(), 2251799813685249.0)
  @test.eq!(5.5.round(), 6.0)
  @test.eq!(5.2.round(), 5.0)
  @test.eq!(1.1.round(), 1.0)
  @test.eq!(1.0.round(), 1.0)
  @test.eq!(0.9.round(), 1.0)
  @test.eq!(0.5.round(), 1.0)
  @test.eq!(0.4.round(), 0.0)
  @test.eq!(0.0.round(), 0.0)
  @test.eq!((-0.0).round().reinterpret_as_i64(), sign_mask)
  @test.eq!((-0.1).round().reinterpret_as_i64(), sign_mask)
  @test.eq!((-0.5).round(), -1.0)
  @test.eq!((-2251799813685248.5).round(), -2251799813685249.0)
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
pub fn Double::nan() -> Double {
  not_a_number
}

// Returns positive infinity if sign >= 0, negative infinity if sign < 0.
pub fn Double::inf(sign : Int) -> Double {
  if sign >= 0 {
    positive_infinity
  } else {
    negative_infinity
  }
}

// Returns the largest positive finite value of Double
pub fn Double::max_value() -> Double {
  max_val
}

// Returns the smallest positive nonzero value of Double
pub fn Double::min_value() -> Double {
  min_val
}

// Returns the smallest positive normal value of Double
pub fn Double::min_normal() -> Double {
  min_norm
}

// Check whether the double is a "not-a-number" value
pub fn is_nan(self : Double) -> Bool {
  // only NaNs satisfy f != f.
  self != self
}

// Check whether the double is infinity
pub fn is_inf(self : Double) -> Bool {
  self > max_val || self < -max_val
}

// Check whether the double is positive infinity
pub fn is_pos_inf(self : Double) -> Bool {
  self > max_val
}

// Check whether the double is negative infinity
pub fn is_neg_inf(self : Double) -> Bool {
  self < -max_val
}

test "from_int" {
  @test.eq!(Double::from_int(1), 1.0)
  @test.eq!(Double::from_int(0), 0.0)
  @test.eq!(Double::from_int(100000), 1.0e5)
}

test "abs" {
  let d = -1.0
  @test.eq!(d.abs(), 1.0)
  @test.eq!(1.0.abs(), 1.0)
}

test "signum" {
  let d = -2.0
  @test.eq!(d.signum(), -1.0)
  @test.eq!(1.0.signum(), 1.0)
  @test.eq!(0.0.signum(), 0.0)
  @test.is_true!(not_a_number.signum().is_nan())
}

test "is_nan" {
  @test.is_true!(is_nan(not_a_number))
  @test.is_false!(is_nan(0.0))
  @test.is_false!(is_nan(12345.678))
  @test.is_false!(is_nan(positive_infinity))
  @test.is_false!(is_nan(negative_infinity))
}

test "is_inf" {
  @test.is_true!(is_inf(positive_infinity))
  @test.is_true!(is_inf(negative_infinity))
  @test.is_false!(is_inf(0.0))
  @test.is_false!(is_inf(12345.678))
}

test "is_pos_inf" {
  @test.is_true!(is_pos_inf(positive_infinity))
  @test.is_false!(is_pos_inf(negative_infinity))
  @test.is_false!(is_pos_inf(0.0))
  @test.is_false!(is_pos_inf(12345.678))
}

test "is_neg_inf" {
  @test.is_false!(is_neg_inf(positive_infinity))
  @test.is_true!(is_neg_inf(negative_infinity))
  @test.is_false!(is_neg_inf(0.0))
  @test.is_false!(is_neg_inf(12345.678))
}

test "nan" {
  @test.is_true!(Double::nan().is_nan())
}

test "inf" {
  @test.eq!(Double::inf(1), positive_infinity)
  @test.eq!(Double::inf(0), positive_infinity)
  @test.eq!(Double::inf(-1), negative_infinity)
}

test "max_value" {
  @test.eq!(Double::max_value(), max_val)
}

test "min_value" {
  @test.eq!(Double::min_value(), min_val)
}

test "min_normal" {
  @test.eq!(Double::min_normal(), min_norm)
}

pub fn hash(self : Double) -> Int {
  self.reinterpret_as_i64().hash()
}

pub fn hash_combine(self : Double, hasher : Hasher) -> Unit {
  hasher.combine_double(self)
}
