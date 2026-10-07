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

// origin: FreeBSD /usr/src/lib/msun/src/e_logf.c
// origin: FreeBSD /usr/src/lib/msun/src/s_log1pf.c
//
// Conversion to float by Ian Lance Taylor, Cygnus Support, ian@cygnus.com.
//
//
// ====================================================
// Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
//
// Developed at SunPro, a Sun Microsystems, Inc. business.
// Permission to use, copy, modify, and distribute this
// software is freely granted, provided that this notice
// is preserved.
// ====================================================
//

///|
/// Calculates the natural logarithm of a double-precision floating-point number.
///
/// Parameters:
///
/// * `x`: The input number.
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
/// ```mbt check
/// test {
///   inspect(@math.ln(2.0), content="0.6931471805599453")
///   inspect(@math.ln(1.0), content="0")
///   inspect(@math.ln(-1.0), content="NaN")
///   inspect(@math.ln(0.0), content="-Infinity")
/// }
/// ```
pub fn ln(x : Double) -> Double {
  let l1 = 6.666666666666735130e-01 // 3FE55555 55555593
  let l2 = 3.999999999940941908e-01 // 3FD99999 9997FA04
  let l3 = 2.857142874366239149e-01 // 3FD24924 94229359
  let l4 = 2.222219843214978396e-01 // 3FCC71C5 1D8E78AF
  let l5 = 1.818357216161805012e-01 // 3FC74664 96CB03DE
  let l6 = 1.531383769920937332e-01 // 3FC39A09 D078C69F
  let l7 = 1.479819860511658591e-01 // 3FC2F112 DF3E5244
  if x < 0.0 {
    return @double.not_a_number
  } else if x.is_nan() || x.is_inf() {
    return x
  } else if x == 0.0 {
    return @double.neg_infinity
  }
  let (f1, ki) = frexp(x)
  let (f, k) = if f1 < SQRT2 / 2.0 {
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
  k * LN2_HI - (hfsq - (s * (hfsq + r) + k * LN2_LO) - f)
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
/// ```mbt check
/// test {
///   inspect(@math.log2(2.0), content="1")
///   inspect(@math.log2(0.5), content="-1")
///   inspect(@math.log2(3.0), content="1.584962500721156")
/// }
/// ```
pub fn log2(x : Double) -> Double {
  // origin: FreeBSD /usr/src/lib/msun/src/e_log2.c
  //
  // Reduce x to 2^k * (1+f) and evaluate log(1+f) as in `ln`, then combine
  // and scale in extra precision:
  //    log2(x) = log(1+f)/log(2) + k
  let ivln2hi = 1.44269504072144627571e+00 // 3ff71547 65200000
  let ivln2lo = 1.67517131648865118353e-10 // 3de705fc 2eefa200
  let lg1 = 6.666666666666735130e-01 // 3FE55555 55555593
  let lg2 = 3.999999999940941908e-01 // 3FD99999 9997FA04
  let lg3 = 2.857142874366239149e-01 // 3FD24924 94229359
  let lg4 = 2.222219843214978396e-01 // 3FCC71C5 1D8E78AF
  let lg5 = 1.818357216161805012e-01 // 3FC74664 96CB03DE
  let lg6 = 1.531383769920937332e-01 // 3FC39A09 D078C69F
  let lg7 = 1.479819860511658591e-01 // 3FC2F112 DF3E5244
  let mut x = x
  let mut hx = get_high_word(x)
  let mut k = 0
  if hx < 0x00100000U || hx >> 31 != 0 {
    if x == 0.0 {
      return @double.neg_infinity // log(+-0) = -inf
    }
    if hx >> 31 != 0 {
      return @double.not_a_number // log(-#) = NaN
    }
    // subnormal number, scale x up
    k -= 54
    x = x * 0x1.0p54
    hx = get_high_word(x)
  } else if hx >= 0x7ff00000U {
    return x // log(+inf) = +inf, log(NaN) = NaN
  }
  // reduce x into [sqrt(2)/2, sqrt(2)); only the high word is compared, so
  // the split actually falls at 0x3fe6a09e_00000000, just below sqrt(2)/2
  hx += 0x3ff00000U - 0x3fe6a09eU
  k += (hx >> 20).reinterpret_as_int() - 0x3ff
  hx = (hx & 0x000fffffU) + 0x3fe6a09eU
  x = set_high_word(x, hx)
  let f = x - 1.0
  let hfsq = 0.5 * f * f
  let s = f / (2.0 + f)
  let z = s * s
  let w = z * z
  let t1 = w * (lg2 + w * (lg4 + w * lg6))
  let t2 = z * (lg1 + w * (lg3 + w * (lg5 + w * lg7)))
  let r = t2 + t1
  // hi + lo = f - hfsq + s*(hfsq+r) ~ log(1+f). hi is f - hfsq with its low
  // word cleared (at most 21 significant bits) and ivln2hi has 32, so
  // hi * ivln2hi is exact; lo and ivln2lo carry the bits cut from each factor.
  let hi = set_low_word(f - hfsq, 0U)
  let lo = f - hi - hfsq + s * (hfsq + r)
  let val_hi = hi * ivln2hi
  let val_lo = (lo + hi) * ivln2lo + lo * ivln2hi
  // Add k to val_hi, folding the rounding error of that sum into val_lo so
  // the bits k pushes out of val_hi are not lost.
  let y = k.to_double()
  let w = y + val_hi
  let val_lo = val_lo + (y - w + val_hi)
  val_lo + w
}

///|
/// Calculates the base-10 logarithm of a double-precision floating-point number.
///
/// Parameters:
///
/// * `x` : The double-precision floating-point number to calculate the
/// logarithm of.
///
/// Returns a double-precision floating-point number representing the base-10
/// logarithm of the input.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@math.log10(0.1), content="-1")
///   inspect(@math.log10(1.0), content="0")
///   inspect(@math.log10(10.0), content="1")
///   inspect(@math.log10(100.0), content="2")
///   inspect(@math.log10(15.0), content="1.1760912590556813")
/// }
/// ```
pub fn log10(x : Double) -> Double {
  // origin: FreeBSD /usr/src/lib/msun/src/e_log10.c
  //
  // Reduce x to 2^k * (1+f) and evaluate log(1+f) as in `ln`, then combine
  // and scale in extra precision:
  //    log10(x) = log(1+f)/log(10) + k*log10(2)
  let ivln10hi = 4.34294481878168880939e-01 // 3fdbcb7b 15200000
  let ivln10lo = 2.50829467116452752298e-11 // 3dbb9438 ca9aadd5
  let log10_2hi = 3.01029995663611771306e-01 // 3FD34413 509F6000
  let log10_2lo = 3.69423907715893078616e-13 // 3D59FEF3 11F12B36
  let lg1 = 6.666666666666735130e-01 // 3FE55555 55555593
  let lg2 = 3.999999999940941908e-01 // 3FD99999 9997FA04
  let lg3 = 2.857142874366239149e-01 // 3FD24924 94229359
  let lg4 = 2.222219843214978396e-01 // 3FCC71C5 1D8E78AF
  let lg5 = 1.818357216161805012e-01 // 3FC74664 96CB03DE
  let lg6 = 1.531383769920937332e-01 // 3FC39A09 D078C69F
  let lg7 = 1.479819860511658591e-01 // 3FC2F112 DF3E5244
  let mut x = x
  let mut hx = get_high_word(x)
  let mut k = 0
  if hx < 0x00100000U || hx >> 31 != 0 {
    if x == 0.0 {
      return @double.neg_infinity // log(+-0) = -inf
    }
    if hx >> 31 != 0 {
      return @double.not_a_number // log(-#) = NaN
    }
    // subnormal number, scale x up
    k -= 54
    x = x * 0x1.0p54
    hx = get_high_word(x)
  } else if hx >= 0x7ff00000U {
    return x // log(+inf) = +inf, log(NaN) = NaN
  }
  // reduce x into [sqrt(2)/2, sqrt(2)); only the high word is compared, so
  // the split actually falls at 0x3fe6a09e_00000000, just below sqrt(2)/2
  hx += 0x3ff00000U - 0x3fe6a09eU
  k += (hx >> 20).reinterpret_as_int() - 0x3ff
  hx = (hx & 0x000fffffU) + 0x3fe6a09eU
  x = set_high_word(x, hx)
  let f = x - 1.0
  let hfsq = 0.5 * f * f
  let s = f / (2.0 + f)
  let z = s * s
  let w = z * z
  let t1 = w * (lg2 + w * (lg4 + w * lg6))
  let t2 = z * (lg1 + w * (lg3 + w * (lg5 + w * lg7)))
  let r = t2 + t1
  // hi + lo = f - hfsq + s*(hfsq+r) ~ log(1+f). hi is f - hfsq with its low
  // word cleared (at most 21 significant bits) and ivln10hi has 32, so
  // hi * ivln10hi is exact; lo and ivln10lo carry the bits cut from each factor.
  let hi = set_low_word(f - hfsq, 0U)
  let lo = f - hi - hfsq + s * (hfsq + r)
  // val_hi + val_lo ~ log10(1+f) + k*log10(2)
  let val_hi = hi * ivln10hi
  let dk = k.to_double()
  let y = dk * log10_2hi
  let val_lo = dk * log10_2lo + (lo + hi) * ivln10lo + lo * ivln10hi
  // Add y to val_hi, folding the rounding error of that sum into val_lo.
  let w = y + val_hi
  let val_lo = val_lo + (y - w + val_hi)
  val_lo + w
}

///|
/// Calculates ln(1 + x) accurately even when x is close to zero.
///
/// Parameters:
///
/// * `x` : The number to which 1 is added before calculating the logarithm.
///
/// Returns the natural logarithm of 1 + `x`.
///
/// Special Cases:
///
/// * Returns `NaN` if `x` is `NaN` or less than -1.
/// * Returns `-Infinity` if `x` is -1.
/// * Returns `+Infinity` if `x` is `+Infinity`.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@math.ln_1p(0.0), content="0")
///   inspect(@math.ln_1p(1.0), content="0.6931471805599453")
///   inspect(@math.ln_1p(2.0), content="1.0986122886681096")
///   inspect(@math.ln_1p(@double.not_a_number), content="NaN")
///   inspect(@math.ln_1p(-1.0), content="-Infinity")
///   inspect(@math.ln_1p(-2.0), content="NaN")
///   inspect(@math.ln_1p(@double.infinity), content="Infinity")
///   inspect(@math.ln_1p(@double.neg_infinity), content="NaN")
/// }
/// ```
pub fn ln_1p(x : Double) -> Double {
  if x < -1.0 || x.is_nan() {
    return @double.not_a_number
  }
  if x == -1.0 {
    return @double.neg_infinity
  }
  if x.is_inf() {
    return @double.infinity
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
  let hx = get_high_word(x).reinterpret_as_int()
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
      if two54 + x > zero && ax < 0x3c900000 {
        return x
      } else {
        return x - x * x * 0.5
      }
    }
    if hx > 0 || hx <= 0xbfd2bec3 {
      k = 0
      f = x
      hu = 1
    }
  }
  if k != 0 {
    if hx < 0x43400000 {
      u = 1.0 + x
      hu = get_high_word(u).reinterpret_as_int()
      k = (hu >> 20) - 1023
      c = if k > 0 { 1.0 - (u - x) } else { x - (u - 1.0) }
      c /= u
    } else {
      u = x
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
