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

//
// origin: FreeBSD /usr/src/lib/msun/src/s_expm1.c
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
fn top12(x : Float) -> UInt {
  x.reinterpret_as_uint() >> 20
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
let expf_n : UInt64 = (1 << exp2f_table_bits).to_uint64()

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
/// Calculates the exponential function e^x for a given floating-point number.
///
/// Parameters:
///
/// * `x` : A floating-point number for which to calculate e^x.
///
/// Returns the value of e raised to the power of x (e^x).
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@math.expf(0), content="1")
///   inspect(@math.expf(1), content="2.7182817459106445")
///   inspect(@math.expf(@float.neg_infinity), content="0")
/// }
/// ```
pub fn expf(x : Float) -> Float {
  let xd = x.to_double()
  let abstop = top12(x) & 0x7ff
  if abstop >= top12(88.0) {
    if x.reinterpret_as_uint() == @float.neg_infinity.reinterpret_as_uint() {
      return 0.0
    }
    if abstop >= top12(@float.infinity) {
      return x + x
    }
    if x > 0x1.62e42ep6 {
      return __math_oflowf(0)
    }
    if x < -0x1.9fe368p6 {
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
  Float::from_double(y)
}

///|
/// Calculates exp(x) - 1 accurately even when x is close to zero.
///
/// Parameters:
///
/// * `x` : The exponent.
///
/// Returns e raised to the power of `x`, minus 1.
///
/// Special Cases:
///
/// * Returns NaN if `x` is NaN.
/// * Returns -1 if `x` is negative infinity.
/// * Returns `Infinity` if `x` is positive infinity.
///
/// Example
///
/// ```mbt check
/// test {
///   inspect(@math.expm1f(0), content="0")
///   inspect(@math.expm1f(1), content="1.7182817459106445")
///   inspect(@math.expm1f(-1), content="-0.6321205496788025")
///   inspect(@math.expm1f(@float.not_a_number), content="NaN")
///   inspect(@math.expm1f(@float.infinity), content="Infinity")
///   inspect(@math.expm1f(@float.neg_infinity), content="-1")
/// }
/// ```
pub fn expm1f(x : Float) -> Float {
  let float_ln2_hi : Float = 6.9314575195e-01 // 0x3f317200
  let float_ln2_lo : Float = 1.4286067653e-06 // 0x35bfbe8e
  let inv_ln2 : Float = 1.4426950216e+00 // 0x3fb8aa3b
  let mut x = x
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
      if !sign {
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
      hi = x - Float::from_int(k) * float_ln2_hi // t*ln2_hi is exact here
      lo = Float::from_int(k) * float_ln2_lo
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
  let twopk = Float::reinterpret_from_int((0x7f + k) << 23) // 2^k
  if !(k is (0..=56)) {
    // suffice to return exp(x)-1
    let mut y = x - e + 1.0
    if k == 128 {
      y = y * 2.0 * (0x1.0p127 : Float)
    } else {
      y = y * twopk
    }
    return y - 1.0
  }
  let uf = Float::reinterpret_from_int((0x7f - k) << 23) // 2^-k
  if k < 23 {
    (x - e + ((1.0 : Float) - uf)) * twopk
  } else {
    (x - (e + uf) + 1.0) * twopk
  }
}
