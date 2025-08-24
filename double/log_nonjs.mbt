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
#deprecated("use `@math.ln` instead")
#coverage.skip
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
#deprecated("use `@math.log2` instead")
#coverage.skip
pub fn Double::log2(self : Double) -> Double {
  let (f, e) = frexp(self)
  if f == 0.5 {
    return e.to_double() - 1.0
  }
  Double::ln(f) / ln2 + e.to_double()
}

///|
#deprecated("use `@math.log10` instead")
#coverage.skip
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
#deprecated("use `@math.ln_1p` instead")
#coverage.skip
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
