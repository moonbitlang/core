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

//
// origin: FreeBSD /usr/src/lib/msun/src/e_sinh.c
// origin: FreeBSD /usr/src/lib/msun/src/e_cosh.c
// origin: FreeBSD /usr/src/lib/msun/src/e_tanh.c
// origin: FreeBSD /usr/src/lib/msun/src/s_asinh.c
// origin: FreeBSD /usr/src/lib/msun/src/e_acosh.c
// origin: FreeBSD /usr/src/lib/msun/src/e_atanh.c
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
#deprecated("use `@math.sinh` instead")
#coverage.skip
pub fn Double::sinh(self : Double) -> Double {
  if self.is_nan() || self.is_inf() {
    return self
  }
  let ix = get_high_word(self).reinterpret_as_int() & 0x7fffffff
  let abs_x = self.abs()
  let shuge = 1.0e307
  let h = if self < 0.0 { -0.5 } else { 0.5 }
  if ix < 0x40360000 {
    if ix < 0x3e300000 {
      if shuge + self > 1.0 {
        return self
      }
    }
    let t = abs_x.expm1()
    if ix < 0x3ff00000 {
      return h * (2.0 * t - t * t / (t + 1.0))
    }
    return h * (t + t / (t + 1.0))
  }
  if ix < 0x40862E42 {
    return h * abs_x.exp()
  }
  if abs_x.reinterpret_as_uint64() < 0x408633ce8fb9f87d {
    let w = Double::exp(0.5 * abs_x)
    let t = h * w
    return t * w
  }
  self * shuge
}

///|
#deprecated("use `@math.cosh` instead")
#coverage.skip
pub fn Double::cosh(self : Double) -> Double {
  if self.is_nan() {
    return self
  }
  if self.is_inf() {
    return infinity
  }
  let ix = get_high_word(self).reinterpret_as_int() & 0x7fffffff
  if ix < 0x3fd62e43 {
    let t = self.abs().expm1()
    let w = 1.0 + t
    if ix < 0x3c800000 {
      return w
    }
    return 1.0 + t * t / (w + w)
  }
  if ix < 0x40360000 {
    let t = self.abs().exp()
    return 0.5 * t + 0.5 / t
  }
  if ix < 0x40862E42 {
    return 0.5 * self.abs().exp()
  }
  let lx = get_low_word(self).reinterpret_as_int()
  if ix < 0x408633ce || (ix == 0x408633ce && lx <= 0x8fb9f87d) {
    let w = Double::exp(0.5 * self.abs())
    let t = 0.5 * w
    return t * w
  }
  infinity
}

///|
#deprecated("use `@math.tanh` instead")
#coverage.skip
pub fn Double::tanh(self : Double) -> Double {
  if self.is_nan() {
    return self
  }
  if self.is_pos_inf() {
    return 1.0
  }
  if self.is_neg_inf() {
    return -1.0
  }
  let ix = get_high_word(self).reinterpret_as_int() & 0x7fffffff
  let tiny = 1.0e-300
  let z = if ix < 0x40360000 {
    if ix < 0x3c800000 {
      self * (1.0 + self)
    } else if ix >= 0x3ff00000 {
      let t = (2.0 * self.abs()).expm1()
      1.0 - 2.0 / (t + 2.0)
    } else {
      let t = (-2.0 * self.abs()).expm1()
      -t / (t + 2.0)
    }
  } else {
    1.0 - tiny
  }
  if self >= 0.0 {
    z
  } else {
    -z
  }
}

///|
#deprecated("use `@math.asinh` instead")
#coverage.skip
pub fn Double::asinh(self : Double) -> Double {
  if self.is_nan() || self.is_inf() {
    return self
  }
  let one : Double = 1.0
  let ln2 : Double = 6.93147180559945286227e-01
  let huge : Double = 1.0e300
  let hx = get_high_word(self).reinterpret_as_int()
  let ix = hx & 0x7fffffff
  if ix < 0x3e300000 {
    if huge + self > one {
      return self
    }
  }
  let w : Double = if ix > 0x41b00000 {
    self.abs().ln() + ln2
  } else if ix > 0x40000000 {
    let t = self.abs()
    (2.0 * t + one / ((self * self + one).sqrt() + t)).ln()
  } else {
    let t = self * self
    (self.abs() + t / (one + (one + t).sqrt())).ln_1p()
  }
  if hx > 0 {
    w
  } else {
    -w
  }
}

///|
#deprecated("use `@math.acosh` instead")
#coverage.skip
pub fn Double::acosh(self : Double) -> Double {
  let one = 1.0
  let hx = get_high_word(self).reinterpret_as_int()
  if self < 1.0 || self.is_nan() {
    return not_a_number
  } else if self == 1.0 {
    return 0.0
  } else if self.is_pos_inf() {
    return infinity
  } else if hx >= 0x41b00000 {
    return self.ln() + ln2
  } else if hx > 0x40000000 {
    let t = self * self
    return (2.0 * self - one / (self + (t - one).sqrt())).ln()
  } else {
    let t = self - one
    return (t + (2.0 * t + t * t).sqrt()).ln_1p()
  }
}

///|
#deprecated("use `@math.atanh` instead")
#coverage.skip
pub fn Double::atanh(self : Double) -> Double {
  let hx : Int = get_high_word(self).reinterpret_as_int()
  let ix = hx & 0x7fffffff
  if self.abs() > 1.0 {
    return not_a_number
  }
  if self == 1.0 {
    return infinity
  }
  if self == -1.0 {
    return neg_infinity
  }
  if ix < 0x3e300000 && 1.0e300 + self > 0.0 {
    return self
  }
  let self = self.abs()
  let t = if self <= 0.5 {
    let t = self + self
    0.5 * (t + t * self / (1.0 - self)).ln_1p()
  } else {
    0.5 * ((self + self) / (1.0 - self)).ln_1p()
  }
  if hx >= 0 {
    t
  } else {
    -t
  }
}
