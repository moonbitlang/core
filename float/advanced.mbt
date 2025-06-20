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
fn top12(x : Float) -> UInt {
  x.reinterpret_as_int().reinterpret_as_uint() >> 20
}

///|
fn __math_xflowf(sign : UInt, y : Float) -> Float {
  return (if sign != 0 { -y } else { y }) * y
}

///|
fn __math_oflowf(sign : UInt) -> Float {
  return __math_xflowf(sign, 0x1.0p97)
}

///|
fn __math_uflowf(sign : UInt) -> Float {
  return __math_xflowf(sign, 0x1.0p-95)
}

///|
let exp2f_table_bits = 5

///|
priv struct Exp2fData {
  tab : FixedArray[UInt64]
  shift : Double
  invln2_scaled : Double
  poly_scaled : FixedArray[Double]
}

///|
let expf_n : UInt64 = (1 << exp2f_table_bits).to_int64().reinterpret_as_uint64()

///|
let exp2f_data_n : Double = (1 << exp2f_table_bits).to_double()

///|
let exp2f_data : Exp2fData = {
  tab: [
    0x3ff0000000000000, 0x3fefd9b0d3158574, 0x3fefb5586cf9890f, 0x3fef9301d0125b51,
    0x3fef72b83c7d517b, 0x3fef54873168b9aa, 0x3fef387a6e756238, 0x3fef1e9df51fdee1,
    0x3fef06fe0a31b715, 0x3feef1a7373aa9cb, 0x3feedea64c123422, 0x3feece086061892d,
    0x3feebfdad5362a27, 0x3feeb42b569d4f82, 0x3feeab07dd485429, 0x3feea47eb03a5585,
    0x3feea09e667f3bcd, 0x3fee9f75e8ec5f74, 0x3feea11473eb0187, 0x3feea589994cce13,
    0x3feeace5422aa0db, 0x3feeb737b0cdc5e5, 0x3feec49182a3f090, 0x3feed503b23e255d,
    0x3feee89f995ad3ad, 0x3feeff76f2fb5e47, 0x3fef199bdd85529c, 0x3fef3720dcef9069,
    0x3fef5818dcfba487, 0x3fef7c97337b9b5f, 0x3fefa4afa2a490da, 0x3fefd0765b6e4540,
  ],
  shift: 0x1.8p+52,
  invln2_scaled: 0x1.71547652b82fep+0 * exp2f_data_n,
  poly_scaled: [
    0x1.c6af84b912394p-5 / exp2f_data_n / exp2f_data_n / exp2f_data_n,
    0x1.ebfce50fac4f3p-3 / exp2f_data_n / exp2f_data_n,
    0x1.62e42ff0c52d6p-1 / exp2f_data_n,
  ],
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
let logf_off = 0x3f330000U

///|
let logf_table_bits = 4

///|
let logf_n : UInt = 1U << logf_table_bits

///|
priv struct LogfData {
  invc : Array[Double]
  logc : Array[Double]
  ln2 : Double
  poly : Array[Double]
}

///|
let logf_data : LogfData = {
  invc: [
    0x1.661ec79f8f3bep+0, 0x1.571ed4aaf883dp+0, 0x1.49539f0f010bp+0, 0x1.3c995b0b80385p+0,
    0x1.30d190c8864a5p+0, 0x1.25e227b0b8eap+0, 0x1.1bb4a4a1a343fp+0, 0x1.12358f08ae5bap+0,
    0x1.0953f419900a7p+0, 0x1.0p+0, 0x1.e608cfd9a47acp-1, 0x1.ca4b31f026aap-1, 0x1.b2036576afce6p-1,
    0x1.9c2d163a1aa2dp-1, 0x1.886e6037841edp-1, 0x1.767dcf5534862p-1,
  ],
  logc: [
    -0x1.57bf7808caadep-2, -0x1.2bef0a7c06ddbp-2, -0x1.01eae7f513a67p-2, -0x1.b31d8a68224e9p-3,
    -0x1.6574f0ac07758p-3, -0x1.1aa2bc79c81p-3, -0x1.a4e76ce8c0e5ep-4, -0x1.1973c5a611cccp-4,
    -0x1.252f438e10c1ep-5, 0x0.0p+0, 0x1.aa5aa5df25984p-5, 0x1.c5e53aa362eb4p-4,
    0x1.526e57720db08p-3, 0x1.bc2860d22477p-3, 0x1.1058bc8a07ee1p-2, 0x1.4043057b6ee09p-2,
  ],
  ln2: 0x1.62e42fefa39efp-1,
  poly: [-0x1.00ea348b88334p-2, 0x1.5575b0be00b6ap-2, -0x1.ffffef20a4123p-2],
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
