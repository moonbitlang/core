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

///|
#deprecated("use `@math.cbtrf` instead")
#coverage.skip
pub fn Float::cbrt(self : Float) -> Float {
  let b1 : UInt = 709958130 // B1 = (127-127.0/3-0.03306235651)*2**23 */
  let b2 : UInt = 642849266 // B2 = (127-127.0/3-24/3-0.03306235651)*2**23 */
  let mut ui : UInt = self.reinterpret_as_uint()
  let mut hx : UInt = ui & 0x7fffffff
  if hx >= 0x7f800000 {
    // cbrt(NaN,INF) is itx
    return self + self
  }

  // rough cbrt to 5 bits
  if hx < 0x00800000 {
    // zero or subnormal?
    if hx == 0 {
      return self
    } // cbrt(+-0) is itx
    ui = (self * (0x1.0p24 : Float)).reinterpret_as_uint()
    hx = ui & 0x7fffffff
    hx = hx / 3 + b2
  } else {
    hx = hx / 3 + b1
  }
  ui = ui & 0x80000000
  ui = ui | hx

  //
  // First step Newton iteration (solving t*t-x/t == 0) to 16 bits.  In
  // double precision so that its terms can be arranged for efficiency
  // without causing overflow or underflow.
  //
  let dx = self.to_double()
  let t = ui.reinterpret_as_float().to_double()
  let r = t * t * t
  let t = t * (dx + dx + r) / (dx + r + r)

  //
  // Second step Newton iteration to 47 bits.  In double precision for
  // efficiency and accuracy.
  //
  let r = t * t * t
  let t = t * (dx + dx + r) / (dx + r + r)

  // rounding to 24 bits is perfect in round-to-nearest mode
  t.to_float()
}

///|
#deprecated("use `@math.hypotf` instead")
#coverage.skip
pub fn Float::hypot(self : Float, y : Float) -> Float {
  let epsilon : Float = 1.1920928955078125e-7
  let x = self.abs()
  let y = y.abs()
  if self.is_inf() || y.is_inf() {
    return infinity
  }
  let (x, y) = if y > x { (y, x) } else { (x, y) }
  if x * epsilon >= y {
    return x
  }
  let rat = y / x
  x * (rat * rat + 1.0).sqrt()
}

///|
#deprecated("use `@math.expf` instead")
#coverage.skip
pub fn Float::exp(self : Float) -> Float {
  let xd = self.to_double()
  let abstop = top12(self) & 0x7ff
  if abstop >= top12(88.0) {
    if self.reinterpret_as_int().reinterpret_as_uint() ==
      neg_infinity.reinterpret_as_int().reinterpret_as_uint() {
      return 0.0
    }
    if abstop >= top12(infinity) {
      return self + self
    }
    if self > 0x1.62e42ep6 {
      return __math_oflowf(0)
    }
    if self < -0x1.9fe368p6 {
      return __math_uflowf(0)
    }
  }
  let z = exp2f_data.invln2_scaled * xd
  let kd = z + exp2f_data.shift
  let ki = kd.reinterpret_as_uint64()
  let kd = kd - exp2f_data.shift
  let r = z - kd
  let t = exp2f_data.tab[(ki % expf_n).to_int()]
  let t = t + (ki << (52 - exp2f_table_bits))
  let s = t.reinterpret_as_double()
  let z = exp2f_data.poly_scaled[0] * r + exp2f_data.poly_scaled[1]
  let r2 = r * r
  let y = exp2f_data.poly_scaled[2] * r + 1
  let y = z * r2 + y
  let y = y * s
  y.to_float()
}

///|
#deprecated("use `@math.expm1f` instead")
#coverage.skip
pub fn Float::expm1(self : Float) -> Float {
  let float_ln2_hi : Float = 6.9314575195e-01 // 0x3f317200
  let float_ln2_lo : Float = 1.4286067653e-06 // 0x35bfbe8e
  let inv_ln2 : Float = 1.4426950216e+00 // 0x3fb8aa3b
  let mut x = self
  let q1 : Float = -3.3333212137e-2 // -0x888868.0p-28
  let q2 : Float = 1.5807170421e-3 //  0xcf3010.0p-33
  let mut hx = x.reinterpret_as_uint()
  let sign = hx >> 31 != 0
  hx = hx & 0x7fffffff

  // filter out huge and non-finite argument
  if hx >= 0x4195b844 {
    // if |x|>=27*ln2
    if hx > 0x7f800000 {
      // NaN
      return x
    }
    if sign {
      return -1.0
    }
    if hx > 0x42b17217 {
      x *= (0x1.0p127 : Float)
      return x
    }
  }
  let mut k : Int = 0
  let mut hi : Float = 0
  let mut lo : Float = 0
  let mut c : Float = 0
  // argument reduction
  if hx > 0x3eb17218 {
    // if  |x| > 0.5 ln2
    if hx < 0x3F851592 {
      // and |x| < 1.5 ln2
      if not(sign) {
        hi = x - float_ln2_hi
        lo = float_ln2_lo
        k = 1
      } else {
        hi = x + float_ln2_hi
        lo = -float_ln2_lo
        k = -1
      }
    } else {
      k = (inv_ln2 * x + (if sign { -0.5 } else { 0.5 })).to_int()
      let t = k.to_float()
      hi = x - t * float_ln2_hi // t*ln2_hi is exact here
      lo = t * float_ln2_lo
    }
    x = hi - lo
    c = hi - x - lo
  } else if hx < 0x33000000 {
    // when |x|<2**-25, return x
    //if hx < 0x00800000 {
    //    force_eval(x * x);
    //}
    return x
  } else {
    k = 0
  }

  // x is now in primary range
  let hfx = (0.5 : Float) * x
  let hxs = x * hfx
  let r1 = (1.0 : Float) + hxs * (q1 + hxs * q2)
  let t = (3.0 : Float) - r1 * hfx
  let mut e = hxs * ((r1 - t) / ((6.0 : Float) - x * t))
  if k == 0 {
    // c is 0
    return x - (x * e - hxs)
  }
  e = x * (e - c) - c
  e -= hxs
  // exp(x) ~ 2^k (x_reduced - e + 1)
  if k == -1 {
    return (0.5 : Float) * (x - e) - 0.5
  }
  if k == 1 {
    if x < -0.25 {
      return -(2.0 : Float) * (e - (x + 0.5))
    }
    return (1.0 : Float) + (2.0 : Float) * (x - e)
  }
  let twopk = ((0x7f + k) << 23).reinterpret_as_float() // 2^k
  if not(k is (0..=56)) {
    // suffice to return exp(x)-1
    let mut y = x - e + 1.0
    if k == 128 {
      y = y * 2.0 * (0x1.0p127 : Float)
    } else {
      y = y * twopk
    }
    return y - 1.0
  }
  let uf = ((0x7f - k) << 23).reinterpret_as_float() // 2^-k
  if k < 23 {
    (x - e + ((1.0 : Float) - uf)) * twopk
  } else {
    (x - (e + uf) + 1.0) * twopk
  }
}

///|
#deprecated("use `@math.sinh` instead")
#coverage.skip
pub fn Float::sinh(self : Float) -> Float {
  let x = self
  let mut h : Float = 0.5
  let mut ix = x.reinterpret_as_uint()
  if ix >> 31 != 0 {
    h = -h
  }
  // |x|
  ix = ix & 0x7fffffff
  let absx = ix.reinterpret_as_float()
  let w = ix

  // |self| < log(FLT_MAX)
  if w < 0x42b17217 {
    let t = absx.expm1()
    if w < 0x3f800000 {
      if w < 0x3f800000U - (12U << 23) {
        return x
      }
      return h * ((2.0 : Float) * t - t * t / (t + 1.0))
    }
    return h * (t + t / (t + 1.0))
  }

  // |self| > logf(FLT_MAX) or nan
  h * k_expo2f(absx) * 2.0
}

///|
#deprecated("use `@math.cosh` instead")
#coverage.skip
pub fn Float::cosh(self : Float) -> Float {
  let mut x = self
  let mut ix = x.reinterpret_as_uint()
  ix = ix & 0x7fffffff
  x = ix.reinterpret_as_float()
  let w = ix

  // |x| < log(2)
  if w < 0x3f317217 {
    if w < 0x3f800000U - (12U << 23) {
      return 1.0
    }
    let t = x.expm1()
    return (1.0 : Float) + t * t / ((2.0 : Float) * (t + 1.0))
  }

  // |x| < log(FLT_MAX)
  if w < 0x42b17217 {
    let t = x.exp()
    return (t + (1.0 : Float) / t) * 0.5
  }

  // |x| > log(FLT_MAX) or nan
  k_expo2f(x)
}

///|
#deprecated("use `@math.tanh` instead")
#coverage.skip
pub fn Float::tanh(self : Float) -> Float {
  let x = self
  let mut ix = x.reinterpret_as_uint()
  let sign = ix >> 31 != 0
  ix = ix & 0x7fffffff
  let x = ix.reinterpret_as_float()
  let w = ix
  let tt = if w > 0x3f0c9f54 {
    // |x| > log(3)/2 ~= 0.5493 or nan
    if w > 0x41200000 {
      // |x| > 10
      (1.0 : Float) + (0.0 : Float) / x
    } else {
      let t = (x * 2.0).expm1()
      (1.0 : Float) - (2.0 : Float) / (t + 2.0)
    }
  } else if w > 0x3e82c578 {
    // |x| > log(5/3)/2 ~= 0.2554
    let t = (x * 2.0).expm1()
    t / (t + 2.0)
  } else if w >= 0x00800000 {
    // |x| >= 0x1p-126
    let t = (x * -2.0).expm1()
    -t / (t + 2.0)
  } else {
    // |x| is subnormal
    x
  }
  if sign {
    -tt
  } else {
    tt
  }
}

///|
#deprecated("use `@math.asinh` instead")
#coverage.skip
pub fn Float::asinh(self : Float) -> Float {
  let x = self
  let u = x.reinterpret_as_uint()
  let i = u & 0x7fffffff
  let sign = u >> 31 != 0
  let ln2 : Float = 0.693147180559945309417232121458176568
  let x = i.reinterpret_as_float()
  let x = if i >= 0x3f800000U + (12U << 23) {
    // |x| >= 0x1p12 or inf or nan
    x.ln() + ln2
  } else if i >= 0x3f800000U + (1U << 23) {
    // |x| >= 2
    (x * 2.0 + (1.0 : Float) / ((x * x + 1.0).sqrt() + x)).ln()
  } else if i >= 0x3f800000U - (12U << 23) {
    // |x| >= 0x1p-12, up to 1.6ulp error in [0.125,0.5]
    (x + x * x / ((x * x + 1.0).sqrt() + 1.0)).ln_1p()
  } else {
    // |x| < 0x1p-12, raise inexact if x!=0
    // x + 0x1.0p120
    x
  }
  if sign {
    -x
  } else {
    x
  }
}

///|
#deprecated("use `@math.acosh` instead")
#coverage.skip
pub fn Float::acosh(self : Float) -> Float {
  let x = self
  let ln2 : Float = 693147180559945309417232121458176568
  let u = x.reinterpret_as_uint()
  let a = u & 0x7fffffffU
  if a < 0x3f800000U + (1U << 23) {
    // |x| < 2, invalid if x < 1 or nan
    // up to 2ulp error in [1,1.125]
    return (x - 1.0 + ((x - 1.0) * (x - 1.0) + (2.0 : Float) * (x - 1.0)).sqrt()).ln_1p()
  }
  if a < 0x3f800000U + (12U << 23) {
    // |x| < 0x1p12
    return (x * 2.0 - (1.0 : Float) / (x + (x * x - 1.0).sqrt())).ln()
  }
  // x >= 0x1p12
  return x.ln() + ln2
}

///|
#deprecated("use `@math.atanh` instead")
#coverage.skip
pub fn Float::atanh(self : Float) -> Float {
  let x = self
  let u = x.reinterpret_as_uint()
  let sign = u >> 31 != 0
  let u = u & 0x7fffffff
  let x = u.reinterpret_as_float()
  let x = if u < 0x3f800000U - (1U << 23) {
    if u < 0x3f800000U - (32U << 23) {
      x
    } else {
      // |x| < 0.5, up to 1.7ulp error
      (x * 2.0 + x * 2.0 * x / ((1.0 : Float) - x)).ln_1p() * 0.5
    }
  } else {
    // avoid overflow
    (x / ((1.0 : Float) - x) * 2.0).ln_1p() * 0.5
  }
  if sign {
    -x
  } else {
    x
  }
}

///|
#deprecated("use `@math.lnf` instead")
#coverage.skip
pub fn Float::ln(self : Float) -> Float {
  let mut ix : UInt = self.reinterpret_as_int().reinterpret_as_uint()
  if ix == 0x3f800000U {
    return 0.0
  }
  if ix - 0x00800000U >= 0x7f800000U - 0x00800000U {
    if ix * 2 == 0 {
      return neg_infinity
    }
    if ix == 0x7f800000U {
      return self
    }
    if (ix & 0x80000000U) != 0 || ix * 2 >= 0xff000000U {
      return not_a_number
    }
    ix = (self * 0x1.0p23).reinterpret_as_int().reinterpret_as_uint()
    ix -= (23 << 23).reinterpret_as_uint()
  }
  let tmp = ix - logf_off
  let i = ((tmp >> (23 - logf_table_bits)) % logf_n).reinterpret_as_int()
  let k = tmp.reinterpret_as_int() >> 23
  let iz = ix - (tmp & 0xff800000U)
  let invc = logf_data.invc[i]
  let logc = logf_data.logc[i]
  let z = iz.reinterpret_as_int().reinterpret_as_float().to_double()
  let r = z * invc - 1
  let y0 = logc + k.to_double() * logf_data.ln2
  let r2 = r * r
  let y = logf_data.poly[1] * r + logf_data.poly[2]
  let y = logf_data.poly[0] * r2 + y
  let y = y * r2 + (y0 + r)
  y.to_float()
}

///|
#deprecated("use `@math.ln_1pf` instead")
#coverage.skip
pub fn Float::ln_1p(self : Float) -> Float {
  let lg1_f : Float = 0.66666662693
  let lg2_f : Float = 0.40000972152
  let lg3_f : Float = 0.28498786688
  let lg4_f : Float = 0.24279078841
  let float_ln2_hi : Float = 6.9314575195e-01 // 0x3f317200
  let float_ln2_lo : Float = 1.4286067653e-06 // 0x35bfbe8e
  let mut ui : UInt = self.reinterpret_as_uint()
  let mut f : Float = 0
  let mut c : Float = 0
  let mut iu : UInt = 0
  let one : Float = 1.0
  let mut k = 1
  if ui < 0x3ed413d0 || ui >> 31 > 0 {
    if ui >= 0xbf800000 {
      if self == -1.0 {
        return self / 0.0
      }
      return (self - self) / 0.0
    }
    if ui << 1 < 0x33800000U << 1 {
      return self
    }
    if ui <= 0xbe95f619 {
      k = 0
      c = 0.0
      f = self
    }
  } else if ui >= 0x7f800000 {
    return self
  }
  if k > 0 {
    ui = (one + self).reinterpret_as_uint()
    iu = ui
    iu += 0x3f800000U - 0x3f3504f3U
    k = (iu >> 23).reinterpret_as_int() - 0x7f
    if k < 25 {
      let fui = ui.reinterpret_as_float()
      c = if k >= 2 { one - (fui - self) } else { self - (fui - 1.0) }
      c /= ui.reinterpret_as_float()
    } else {
      c = 0.0
    }
    iu = (iu & 0x007fffff) + 0x3f3504f3
    ui = iu
    f = ui.reinterpret_as_float() - 1.0
  }
  let s = f / (f + 2.0)
  let z = s * s
  let w = z * z
  let t1 = w * (lg2_f + w * lg4_f)
  let t2 = z * (lg1_f + w * lg3_f)
  let r = t2 + t1
  let hfsq = f * f * 0.5
  let dk = k.to_float()
  s * (hfsq + r) + (dk * float_ln2_lo + c) - hfsq + f + dk * float_ln2_hi
}

///|
#deprecated("use `@math.sinf` instead")
#coverage.skip
pub fn Float::sin(self : Float) -> Float {
  let x = self
  if x.is_nan() || x.is_inf() {
    return not_a_number
  }
  if x == 0.0 {
    return x
  }
  let (x, q) = trig_reduce(x, SIN_SWITCHOVER)
  sin_cos_core(x, q)
}

///|
#deprecated("use `@math.cosf` instead")
#coverage.skip
pub fn Float::cos(self : Float) -> Float {
  let x = self
  if x.is_nan() || x.is_inf() {
    return not_a_number
  }
  if x == 0.0 {
    return 1.0
  }
  let (x, q) = trig_reduce(x, COS_SWITCHOVER)
  sin_cos_core(x, q + 1)
}

///|
#deprecated("use `@math.tanf` instead")
#coverage.skip
pub fn Float::tan(self : Float) -> Float {
  let x = self
  if x.is_nan() || x.is_inf() {
    return not_a_number
  }
  if x == 0.0 {
    return x
  }
  let (x, q) = trig_reduce(x, COS_SWITCHOVER)
  tanf_poly(x, (q & 1) != 0)
}

///|
#deprecated("use `@math.asinf` instead")
#coverage.skip
pub fn Float::asin(self : Float) -> Float {
  let x = self
  let x1p120 = 0x3870000000000000UL.reinterpret_as_double()
  let pio2 : Double = 1.570796326794896558e+00

  // coefficients for R(x^2)
  let ps0 : Float = 1.6666586697e-01
  let ps1 : Float = -4.2743422091e-02
  let ps2 : Float = -8.6563630030e-03
  let qs2 : Float = -7.0662963390e-01
  fn r(z : Float) -> Float {
    let p = z * (ps0 + z * (ps1 + z * ps2))
    let q = z * qs2 + 1.0
    p / q
  }

  let hx = x.reinterpret_as_uint()
  let ix = hx & 0x7fffffff
  if ix >= 0x3f800000 {
    if ix == 0x3f800000 {
      return (x.to_double() * pio2 + x1p120).to_float()
    }
    return not_a_number // asin(|x|>1) is NaN
  }
  if ix < 0x3f000000 {
    if ix is (0x00800000..=0x39800000) {
      return x
    }
    return x + x * r(x * x)
  }
  let z = ((1.0 : Float) - x.abs()) * 0.5
  let s = z.to_double().sqrt()
  let x = (pio2 - 2.0 * (s + s * r(z).to_double())).to_float()
  if hx >> 31 != 0 {
    -x
  } else {
    x
  }
}

///|
#deprecated("use `@math.acosf` instead")
#coverage.skip
pub fn Float::acos(self : Float) -> Float {
  let x = self
  let pio2_hi : Float = 1.5707962513
  let pio2_lo : Float = 7.5497894159e-08
  let ps0 : Float = 1.6666586697e-01
  let ps1 : Float = -4.2743422091e-02
  let ps2 : Float = -8.6563630030e-03
  let qs1 : Float = -7.0662963390e-01
  let one : Float = 1.0
  let two : Float = 2.0
  fn r(z : Float) -> Float {
    let p = z * (ps0 + z * (ps1 + z * ps2))
    let q = z * qs1 + 1.0
    p / q
  }

  let hx = x.reinterpret_as_int()
  let ix = hx & 0x7fffffff
  if ix >= 0x3f800000 {
    if ix == 0x3f800000 {
      if hx >> 31 != 0 {
        return two * pio2_hi + 0x1.0p-120
      }
      return 0.0
    }
    return not_a_number
  }
  if ix < 0x3f000000 {
    if ix <= 0x32800000 {
      return pio2_hi + 0x1.0p-120
    }
    return pio2_hi - (x - (pio2_lo - x * r(x * x)))
  }
  if hx >> 31 != 0 {
    let z = (x + 1.0) * 0.5
    let s = z.sqrt()
    let w = r(z) * s - pio2_lo
    return two * (pio2_hi - (s + w))
  }
  let z = (one - x) * 0.5
  let s = z.sqrt()
  let df = s
  let c = (z - df * df) / (s + df)
  let w = r(z) * s + c
  two * (df + w)
}

///|
#deprecated("use `@math.atanf` instead")
#coverage.skip
pub fn Float::atan(self : Float) -> Float {
  let x = self
  let atanhi : Array[Float] = [
    4.6364760399e-01, 7.8539812565e-01, 9.8279368877e-01, 1.5707962513e+00,
  ]
  let atanlo : Array[Float] = [
    5.0121582440e-09, 3.7748947079e-08, 3.4473217170e-08, 7.5497894159e-08,
  ]
  let a_t : Array[Float] = [
    3.3333328366e-01, -1.9999158382e-01, 1.4253635705e-01, -1.0648017377e-01, 6.1687607318e-02,
  ]
  let ix = x.reinterpret_as_int()
  let sign = ix >> 31
  let ix = ix & 0x7fffffff
  let mut id = 0
  let mut x = x
  let one : Float = 1.0
  let two : Float = 2.0
  if ix >= 0x4c800000 {
    if x.is_nan() {
      return x
    }
    let z = atanhi[3] + 0x1.0p-120
    let z = if sign != 0 { -z } else { z }
    return z
  }
  if ix < 0x3ee00000 {
    if ix < 0x39800000 {
      return x
    }
    id = -1
  } else {
    x = x.abs()
    if ix < 0x3f980000 {
      if ix < 0x3f300000 {
        id = 0
        x = (two * x - one) / (two + x)
      } else {
        id = 1
        x = (x - one) / (x + one)
      }
    } else if ix < 0x401c0000 {
      id = 2
      x = (x - 1.5) / (one + x * 1.5)
    } else {
      id = 3
      x = -one / x
    }
  }
  let z = x * x
  let w = z * z
  let s1 = z * (a_t[0] + w * (a_t[2] + w * a_t[4]))
  let s2 = w * (a_t[1] + w * a_t[3])
  if id < 0 {
    return x - x * (s1 + s2)
  }
  let z = atanhi[id] - (x * (s1 + s2) - atanlo[id] - x)
  if sign != 0 {
    -z
  } else {
    z
  }
}

///|
#deprecated("use `@math.atan2f` instead")
#coverage.skip
pub fn Float::atan2(self : Float, other : Float) -> Float {
  let (y, x) = (self, other)
  if x.is_nan() || y.is_nan() {
    return not_a_number
  }
  let pi : Float = 3.1415927410e+00
  let pi_lo : Float = -8.7422776573e-08
  let zero : Float = 0.0
  let ix = x.reinterpret_as_uint()
  let iy = y.reinterpret_as_uint()
  if ix == 0x3f800000 {
    return y.atan()
  }
  let m = ((iy >> 31) & 1) | ((ix >> 30) & 2)
  let ix = ix & 0x7fffffff
  let iy = iy & 0x7fffffff
  if iy == 0 {
    match m {
      0 | 1 => return y
      2 => return pi
      _ => return -pi
    }
  }
  if ix == 0 {
    let res = if (m & 1) != 0 { -pi / 2 } else { pi / 2 }
    return res
  }
  if ix == 0x7f800000 {
    if iy == 0x7f800000 {
      match m {
        0 => return pi / 4
        1 => return -pi / 4
        2 => return pi * 3.0 / 4
        _ => return -pi * 3.0 / 4
      }
    } else {
      match m {
        0 => return 0.0
        1 => return -0.0
        2 => return pi
        _ => return -pi
      }
    }
  }
  if ix + (26U << 23) < iy || iy == 0x7f800000 {
    let res = if (m & 1) != 0 { -pi / 2 } else { pi / 2 }
    return res
  }
  let z = if (m & 2) != 0 && iy + (26U << 23) < ix {
    zero
  } else {
    (y / x).atan()
  }
  match m {
    0 => z
    1 => -z
    2 => pi - (z - pi_lo)
    _ => z - pi_lo - pi
  }
}
