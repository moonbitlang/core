// Copyright 2025 International Digital Economy Academy
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

// ported from https://github.com/golang/go/blob/master/src/math/log.go

//
// origin: FreeBSD /usr/src/lib/msun/src/s_log1p.c
// ====================================================
// Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
//
// Developed at SunSoft, a Sun Microsystems, Inc. business.
// Permission to use, copy, modify, and distribute this
// software is freely granted, provided that this notice
// is preserved.
// ====================================================
//

///|
let sqrt2 = 1.41421356237309504880168872420969807856967187537694807317667974

///|
let ln2 = 0.693147180559945309417232121458176568075500134360255254120680009

///|
let ln2_hi = 6.93147180369123816490e-01 // 3fe62e42 fee00000

///|
let ln2_lo = 1.90821492927058770002e-10 // 3dea39ef 35793c76

///|
let l1 = 6.666666666666735130e-01 // 3FE55555 55555593

///|
let l2 = 3.999999999940941908e-01 // 3FD99999 9997FA04

///|
let l3 = 2.857142874366239149e-01 // 3FD24924 94229359

///|
let l4 = 2.222219843214978396e-01 // 3FCC71C5 1D8E78AF

///|
let l5 = 1.818357216161805012e-01 // 3FC74664 96CB03DE

///|
let l6 = 1.531383769920937332e-01 // 3FC39A09 D078C69F

///|
let l7 = 1.479819860511658591e-01 // 3FC2F112 DF3E5244

///|
fn normalize(f : Double) -> (Double, Int) {
  if f.abs() < min_positive {
    return (f * (1L << 52).to_double(), -52)
  }
  (f, 0)
}

///|
fn frexp(f : Double) -> (Double, Int) {
  if f == 0.0 || f.is_inf() || f.is_nan() {
    return (f, 0)
  }
  let (norm_f, exp) = normalize(f)
  let u = norm_f.reinterpret_as_uint64()
  let exp = exp + ((u >> 52) & 0x7FF).to_int() - 1022
  let frac = ((u & (0x7FFUL << 52).lnot()) | (1022UL << 52)).reinterpret_as_double()
  return (frac, exp)
}

///|
/// Calculates the natural logarithm of a double-precision floating-point number.
///
/// Parameters:
///
/// * `self`: The input number.
///
/// Returns the natural logarithm of the input number, with the following special
/// cases:
///
/// * Returns NaN if the input is NaN or negative
/// * Returns negative infinity if the input is zero
/// * Returns the input if it is positive infinity
///
/// Example:
///
/// ```moonbit
///   inspect(2.0.ln(), content="0.6931471805599453")
///   inspect(1.0.ln(), content="0")
///   inspect((-1.0).ln(), content="NaN")
///   inspect(0.0.ln(), content="-Infinity")
/// ```
pub fn Double::ln(self : Double) -> Double {
  if self < 0.0 {
    return not_a_number
  } else if self.is_nan() || self.is_inf() {
    return self
  } else if self == 0.0 {
    return neg_infinity
  }
  let (f1, ki) = frexp(self)
  let (f, k) = if f1 < sqrt2 / 2.0 {
    (f1 * 2.0 - 1.0, (ki - 1).to_double())
  } else {
    (f1 - 1.0, ki.to_double())
  }
  let s = f / (2.0 + f)
  let s2 = s * s
  let s4 = s2 * s2
  let t1 = s2 * (l1 + s4 * (l3 + s4 * (l5 + s4 * l7)))
  let t2 = s4 * (l2 + s4 * (l4 + s4 * l6))
  let r = t1 + t2
  let hfsq = 0.5 * f * f
  k * ln2_hi - (hfsq - (s * (hfsq + r) + k * ln2_lo) - f)
}

///|
/// Calculates the base-2 logarithm of a double-precision floating-point number.
///
/// Parameters:
///
/// * `x` : A double-precision floating-point number.
///
/// Returns the base-2 logarithm of the input number.
///
/// Example:
///
/// ```moonbit
///   inspect(2.0.log2(), content="1")
///   inspect(0.5.log2(), content="-1")
///   inspect(3.0.log2(), content="1.584962500721156")
/// ```
pub fn Double::log2(self : Double) -> Double {
  let (f, e) = frexp(self)
  if f == 0.5 {
    return e.to_double() - 1.0
  }
  ln(f) / ln2 + e.to_double()
}

///|
/// Calculates the base-10 logarithm of a double-precision floating-point number.
///
/// Parameters:
///
/// * `self` : The double-precision floating-point number to calculate the
/// logarithm of.
///
/// Returns a double-precision floating-point number representing the base-10
/// logarithm of the input.
///
/// Example:
///
/// ```moonbit
///   inspect(0.1.log10(), content="-1")
///   inspect(1.0.log10(), content="0")
///   inspect(10.0.log10(), content="1")
///   inspect(100.0.log10(), content="2")
///   inspect(15.0.log10(), content="1.1760912590556813")
/// ```
pub fn Double::log10(self : Double) -> Double {
  if self < 0.0 {
    return not_a_number
  } else if self.is_nan() || self.is_inf() {
    return self
  } else if self == 0.0 {
    return neg_infinity
  }
  let ivln10 = 4.34294481903251816668e-01
  let log10_2hi = 3.01029995663611771306e-01
  let log10_2lo = 3.69423907715893078616e-13
  let (f, e) = frexp(self)
  let (f, e) = if e >= 1 {
    (f * 2.0, (e - 1).to_double())
  } else {
    (f, e.to_double())
  }
  let z = e * log10_2lo + ivln10 * f.ln()
  z + e * log10_2hi
}

///|
/// Calculates ln(1 + x) accurately even when x is close to zero.
///
/// Parameters:
///
/// * `self` : The number to which 1 is added before calculating the logarithm.
///
/// Returns the natural logarithm of 1 + `self`.
///
/// Special Cases:
///
/// * Returns `NaN` if `self` is `NaN` or less than -1.
/// * Returns `-Infinity` if `self` is -1.
/// * Returns `+Infinity` if `self` is `+Infinity`.
///
/// Example:
///
/// ```moonbit
///   inspect(0.0.ln_1p(), content="0")
///   inspect(1.0.ln_1p(), content="0.6931471805599453")
///   inspect(2.0.ln_1p(), content="1.0986122886681096")
///   inspect(@double.not_a_number.ln_1p(), content="NaN")
///   inspect((-1.0).ln_1p(), content="-Infinity")
///   inspect((-2.0).ln_1p(), content="NaN")
///   inspect(@double.infinity.ln_1p(), content="Infinity")
///   inspect(@double.neg_infinity.ln_1p(), content="NaN")
/// ```
pub fn Double::ln_1p(self : Double) -> Double {
  if self < -1.0 || self.is_nan() {
    return not_a_number
  }
  if self == -1.0 {
    return neg_infinity
  }
  if self.is_inf() {
    return infinity
  }
  let ln2_hi = 6.93147180369123816490e-01
  let ln2_lo = 1.90821492927058770002e-10
  let two54 = 1.80143985094819840000e+16
  let lp1 = 6.666666666666735130e-01
  let lp2 = 3.999999999940941908e-01
  let lp3 = 2.857142874366239149e-01
  let lp4 = 2.222219843214978396e-01
  let lp5 = 1.818357216161805012e-01
  let lp6 = 1.531383769920937332e-01
  let zero = 0.0
  let lp7 = 1.479819860511658591e-01
  let hx = get_high_word(self).reinterpret_as_int()
  let ax = hx & 0x7fffffff
  let mut f = 0.0
  let mut c = 0.0
  let mut s = 0.0
  let mut z = 0.0
  let mut r = 0.0
  let mut u = 0.0
  let mut hu = 0
  let mut k = 1
  if hx < 0x3FDA827A {
    if ax < 0x3e200000 {
      if two54 + self > zero && ax < 0x3c900000 {
        return self
      } else {
        return self - self * self * 0.5
      }
    }
    if hx > 0 || hx <= 0xbfd2bec3 {
      k = 0
      f = self
      hu = 1
    }
  }
  if k != 0 {
    if hx < 0x43400000 {
      u = 1.0 + self
      hu = get_high_word(u).reinterpret_as_int()
      k = (hu >> 20) - 1023
      c = if k > 0 { 1.0 - (u - self) } else { self - (u - 1.0) }
      c /= u
    } else {
      u = self
      hu = get_high_word(u).reinterpret_as_int()
      k = (hu >> 20) - 1023
      c = 0.0
    }
    hu = hu & 0x000fffff
    if hu < 0x6a09e {
      u = set_high_word(u, hu.reinterpret_as_uint() | 0x3ff00000)
    } else {
      k += 1
      u = set_high_word(u, hu.reinterpret_as_uint() | 0x3fe00000)
      hu = (0x00100000 - hu) >> 2
    }
    f = u - 1.0
  }
  let hfsq = 0.5 * f * f
  if hu == 0 {
    if f == zero {
      if k == 0 {
        return zero
      } else {
        c += k.to_double() * ln2_lo
        return k.to_double() * ln2_hi + c
      }
    }
    r = hfsq * (1.0 - 0.66666666666666666 * f)
    if k == 0 {
      return f - r
    } else {
      return k.to_double() * ln2_hi - (r - (k.to_double() * ln2_lo + c) - f)
    }
  }
  s = f / (2.0 + f)
  z = s * s
  r = z *
    (lp1 + z * (lp2 + z * (lp3 + z * (lp4 + z * (lp5 + z * (lp6 + z * lp7))))))
  if k == 0 {
    return f - (hfsq - s * (hfsq + r))
  } else {
    return k.to_double() * ln2_hi -
      (hfsq - (s * (hfsq + r) + (k.to_double() * ln2_lo + c)) - f)
  }
}

///|
test "log2 log10" {
  // log2
  assert_eq(3.0.log2(), 1.584962500721156)
  assert_eq(2.0.log2(), 1.0)
  assert_eq(1.0.log2(), 0.0)
  assert_eq(0.5.log2(), -1.0)
  assert_eq(0.25.log2(), -2.0)
  assert_eq(0.1.log2(), -3.321928094887362)

  // log10
  assert_eq(0.2.log10(), -0.6989700043360187)
  assert_eq(0.1.log10(), -1)
  assert_eq(1.0.log10(), 0.0)
  assert_eq(10.0.log10(), 1.0)
  assert_eq(100.0.log10(), 2.0)
  assert_eq(1000.0.log10(), 3.0)
  assert_eq(3.0.log10(), 0.47712125471966244)
  assert_eq(11.0.log10(), 1.041392685158225)
  assert_eq(15.0.log10(), 1.1760912590556813)
}

///|
test "ln" {
  assert_true(not_a_number.ln().is_nan())
  assert_true(infinity.ln().is_pos_inf())
  assert_true(neg_infinity.ln().is_nan())
  assert_true((-1.0).ln().is_nan())
  assert_true(0.0.ln().is_neg_inf())
  assert_true((-0.0).ln().is_neg_inf())
  assert_eq(50.0.ln(), 3.912023005428146)
  assert_eq(2.0.ln(), 0.6931471805599453)
  assert_eq(1.1125369292536007e-308.ln(), -709.0895657128241)
  assert_eq(5.562684646268003e-309.ln(), -709.782712893384)
  assert_true(
    match frexp(0.0) {
      (0.0, 0) => true
      _ => false
    },
  )
  assert_true(
    match frexp(infinity) {
      (f, 0) => if f.is_pos_inf() { true } else { false }
      _ => false
    },
  )
  assert_true(
    match frexp(not_a_number) {
      (f, 0) => if f.is_nan() { true } else { false }
      _ => false
    },
  )
}

///|
test "ln_1p" {
  assert_true(not_a_number.ln_1p().is_nan())
  assert_true(infinity.ln_1p().is_pos_inf())
  assert_true(neg_infinity.ln_1p().is_nan())
  assert_true((-1.0).ln_1p().is_neg_inf())
  assert_eq(0.0.ln_1p(), 0.0)
}
