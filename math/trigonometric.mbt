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
pub const PI = 0x3.243F6A8885A308CA8A54

///|
#deprecated("Use `PI` instead")
pub let pi = 0x3.243F6A8885A308CA8A54

///|
pub fnalias Double::(sin, cos, tan, atan, asin, acos, atan2)

///|
const SIN_SWITCHOVER : Float = 201.15625

///|
const COS_SWITCHOVER : Float = 142.90625

///|
fn mulh(a : UInt, b : UInt) -> UInt {
  let a = a.to_uint64()
  let b = b.to_uint64()
  let res = a * b
  (res >> 32).to_uint()
}

///|
fn mul(a : UInt, b : UInt) -> (UInt, UInt) {
  let a = a.to_uint64()
  let b = b.to_uint64()
  let res = a * b
  ((res >> 32).to_uint(), res.to_uint())
}

///|
fn trig_reduce(x : Float, switch_over : Float) -> (Float, Int) {
  if x.abs() <= switch_over {
    let mut j : Float = 0.0
    let mut r : Float = 0.0
    j = x * (0x3f22f983).reinterpret_as_float() +
      (0x4b40_0000).reinterpret_as_float()
    j = (j.reinterpret_as_int() - 0x4b40_0000).to_float()
    r = x - j * (0x3fc90f80).reinterpret_as_float()
    r = r - j * (0x37354440).reinterpret_as_float()
    r = r - j * (0x2c34611a).reinterpret_as_float()
    return (r, j.to_int())
  }
  let xispos = x > 0.0
  let mut exp : Int = ((x.reinterpret_as_int() >> 23) & 0xff) - 126
  let ix = ((x.reinterpret_as_uint() & 0x007fffff) << 8) | 0x80000000
  let ind = exp >> 5
  exp = exp & 0x1f
  let two_over_pi : Array[UInt] = [
    0x00000000, 0x28be60db, 0x9391054a, 0x7f09d5f4, 0x7d4d3770, 0x36d8a566, 0x4f10e410,
    0000000000,
  ]
  let mut hi = two_over_pi[ind]
  let mut mi = two_over_pi[ind + 1]
  let mut lo = two_over_pi[ind + 2]
  let tp = two_over_pi[ind + 3]
  if exp > 0 {
    hi = (hi << exp) | (mi >> (32 - exp))
    mi = (mi << exp) | (lo >> (32 - exp))
    lo = (lo << exp) | (tp >> (32 - exp))
  }
  let phi = 0U
  let (h, l) = mul(ix, lo)
  let plo = phi + l
  let phi = h + (if plo < l { 1 } else { 0 })
  let (h, l) = mul(ix, mi)
  let mut plo = phi + l
  let phi = h + (if plo < l { 1 } else { 0 })
  let l = ix * hi
  let mut phi = phi + l
  let mut q : Int = (phi >> 30).reinterpret_as_int()
  phi = phi & 0x3fffffff
  if (phi & 0x2000_0000) != 0 {
    phi = phi - 0x4000_0000
    q = q + 1
  }
  let s : UInt = phi & 0x8000_0000
  if phi >= 0x8000_0000 {
    phi = phi.lnot()
    plo = 0U - plo
    //phi += (plo == 0).to_uint()
    phi += if plo == 0 { 1 } else { 0 }
  }
  exp = 0
  while phi < 0x8000_0000 {
    phi = (phi << 1) | (plo >> 31)
    plo = plo << 1
    exp = exp - 1
  }
  phi = mulh(phi, 0xc90f_daa2)
  if phi < 0x8000_0000 {
    phi = phi << 1
    exp = exp - 1
  }
  let mut r = s +
    ((exp + 128) << 23).reinterpret_as_uint() +
    (phi >> 8) +
    (if (phi & 0xff) > 0x7e { 1 } else { 0 })
  if not(xispos) {
    r = r ^ 0x8000_0000
    q = -q
  }
  let r = r.reinterpret_as_float()
  return (r, q)
}

///|
fn sinf_poly(x : Float) -> Float {
  let s = x * x
  let mut r = (0x3640_5000).reinterpret_as_float()
  r = r * s - (0x3950_3486).reinterpret_as_float()
  r = r * s + (0x3c08_88c1).reinterpret_as_float()
  r = r * s - (0x3e2a_aaab).reinterpret_as_float()
  let t = x * s
  r = r * t + x
  r
}

///|
fn cosf_poly(x : Float) -> Float {
  let s = x * x
  let mut r = (0x37cd_4000).reinterpret_as_float()
  r = r * s - (0x3ab6_077d).reinterpret_as_float()
  r = r * s + (0x3d2a_aaa8).reinterpret_as_float()
  r = r * s - (0x3f00_0000).reinterpret_as_float()
  r = r * s + (0x3f80_0000).reinterpret_as_float()
  r
}

///|
fn sin_cos_core(x : Float, q : Int) -> Float {
  let mut r = if (q & 1) != 0 { cosf_poly(x) } else { sinf_poly(x) }
  if (q & 2) != 0 {
    r = -r
  }
  r
}

///|
fn tanf_poly(x : Float, odd : Bool) -> Float {
  let x = x.to_double()
  let coef : FixedArray[Double] = [
    0.333331395030791399758, // 0x15554d3418c99f.0p-54 */
     0.133392002712976742718, // 0x1112fd38999f72.0p-55 */
     0.0533812378445670393523, // 0x1b54c91d865afe.0p-57 */
     0.0245283181166547278873, // 0x191df3908c33ce.0p-58 */
     0.00297435743359967304927, // 0x185dadfcecf44e.0p-61 */
     0.00946564784943673166728, // 0x1362b9bf971bcd.0p-59 */
  ]
  let z = x * x
  let mut r = coef[4] + z * coef[5]
  let t = coef[2] + z * coef[3]
  let w = z * z
  let s = z * x
  let u = coef[0] + z * coef[1]
  r = x + s * u + s * w * (t + w * r)
  (if odd { -1.0 / r } else { r }).to_float()
}

///|
/// Calculates the sine of a floating-point number in radians.
///
/// Parameters:
///
/// * `x` : The angle in radians for which to calculate the sine.
///
/// Returns the sine of the angle `x`.
///
/// Example:
///
/// ```moonbit
///   inspect(sinf(0), content="0")
///   inspect(sinf(2), content="0.9092974066734314")
///   inspect(sinf(-5), content="0.9589242935180664")
///   inspect(sinf(@float.not_a_number), content="NaN")
///   inspect(sinf(@float.infinity), content="NaN")
///   inspect(sinf(@float.neg_infinity), content="NaN")
/// ```
pub fn sinf(x : Float) -> Float {
  if x.is_nan() || x.is_inf() {
    return @float.not_a_number
  }
  if x == 0.0 {
    return x
  }
  let (x, q) = trig_reduce(x, SIN_SWITCHOVER)
  sin_cos_core(x, q)
}

///|
/// Calculates the cosine of a floating-point number in radians.
///
/// Parameters:
///
/// * `x` : The angle in radians for which to calculate the cosine.
///
/// Returns the cosine of the angle `x`.
///
/// Example:
///
/// ```moonbit
///   inspect(cosf(0), content="1")
///   inspect(cosf(2), content="-0.41614681482315063")
///   inspect(cosf(-5), content="0.28366217017173767")
///   inspect(cosf(@float.not_a_number), content="NaN")
///   inspect(cosf(@float.infinity), content="NaN")
///   inspect(cosf(@float.neg_infinity), content="NaN")
/// ```
pub fn cosf(x : Float) -> Float {
  if x.is_nan() || x.is_inf() {
    return @float.not_a_number
  }
  if x == 0.0 {
    return 1.0
  }
  let (x, q) = trig_reduce(x, COS_SWITCHOVER)
  sin_cos_core(x, q + 1)
}

///|
/// Calculates the tangent of a floating-point number in radians.
///
/// Parameters:
///
/// * `x` : The angle in radians for which to calculate the tangent.
///
/// Returns the tangent of the angle `x`.
///
/// Example:
///
/// ```moonbit
///   inspect(tanf(0), content="0")
///   inspect(tanf(2), content="-2.18503999710083")
///   inspect(tanf(-5), content="3.3805150985717773")
///   inspect(tanf(@float.not_a_number), content="NaN")
///   inspect(tanf(@float.infinity), content="NaN")
///   inspect(tanf(@float.neg_infinity), content="NaN")
/// ```
pub fn tanf(x : Float) -> Float {
  if x.is_nan() || x.is_inf() {
    return @float.not_a_number
  }
  if x == 0.0 {
    return x
  }
  let (x, q) = trig_reduce(x, COS_SWITCHOVER)
  tanf_poly(x, (q & 1) != 0)
}

///|
/// Calculates the arcsine of a floating-point number.
///
/// Parameters:
///
/// * `x` : The number for which to calculate the arcsine.
///
/// Returns the arcsine of the number `x`.
///
/// * Returns NaN if the input is NaN.
/// * Returns NaN if the input is less than -1 or greater than 1.
///
/// Example:
///
/// ```moonbit
///   inspect(asinf(0), content="0")
///   inspect(asinf(1), content="1.5707963705062866")
///   inspect(asinf(-1), content="-1.5707963705062866")
///   inspect(asinf(@float.not_a_number), content="NaN")
///   inspect(asinf(@float.infinity), content="NaN")
///   inspect(asinf(@float.neg_infinity), content="NaN")
/// ```
pub fn asinf(x : Float) -> Float {
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
    return @float.not_a_number // asin(|x|>1) is NaN
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
  if (hx >> 31) != 0 {
    -x
  } else {
    x
  }
}

///|
/// Calculates the arccosine of a floating-point number.
///
/// Parameters:
///
/// * `x` : The number for which to calculate the arccosine.
///
/// Returns the arccosine of the number `x`.
///
/// * Returns NaN if the input is NaN.
/// * Returns NaN if the input is less than -1 or greater than 1.
///
/// Example:
///
/// ```moonbit
///   inspect(acosf(0), content="1.570796251296997")
///   inspect(acosf(1), content="0")
///   inspect(acosf(-1), content="3.141592502593994")
///   inspect(acosf(@float.not_a_number), content="NaN")
///   inspect(acosf(@float.infinity), content="NaN")
///   inspect(acosf(@float.neg_infinity), content="NaN")
/// ```
pub fn acosf(x : Float) -> Float {
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
      if (hx >> 31) != 0 {
        return two * pio2_hi + 0x1.0p-120
      }
      return 0.0
    }
    return @float.not_a_number
  }
  if ix < 0x3f000000 {
    if ix <= 0x32800000 {
      return pio2_hi + 0x1.0p-120
    }
    return pio2_hi - (x - (pio2_lo - x * r(x * x)))
  }
  if (hx >> 31) != 0 {
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
/// Calculates the arctangent of a floating-point number.
///
/// Parameters:
///
/// * `x` : The number for which to calculate the arctangent.
///
/// Returns the arctangent of the number `x`.
///
/// Example:
///
/// * Returns NaN if the input is NaN.
///
/// ```moonbit
///   inspect(atanf(0), content="0")
///   inspect(atanf(1), content="0.7853981852531433")
///   inspect(atanf(-1), content="-0.7853981852531433")
///   inspect(atanf(@float.not_a_number), content="NaN")
///   inspect(atanf(@float.infinity), content="1.570796251296997")
///   inspect(atanf(@float.neg_infinity), content="-1.570796251296997")
/// ```
pub fn atanf(x : Float) -> Float {
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
/// Calculates the arctangent of the quotient of two floating-point numbers.
///
/// Parameters:
///
/// * `y` : The numerator of the quotient.
/// * `x` : The denominator of the quotient.
///
/// Returns the arctangent of the quotient `self / x`.
///
/// * Returns NaN if self or x is NaN.
///
/// Example:
///
/// ```moonbit
///   inspect(atan2f(0.0, -1.0), content="3.1415927410125732")
///   inspect(atan2f(1.0, 0.0), content="1.5707963705062866")
///   inspect(atan2f(1.0, 1.0), content="0.7853981852531433")
///   inspect(atan2f(@float.not_a_number, 1.0), content="NaN")
///   inspect(atan2f(1.0, @float.not_a_number), content="NaN")
///   inspect(atan2f(@float.infinity, 1.0), content="1.570796251296997")
///   inspect(atan2f(1.0, @float.infinity), content="0")
///   inspect(atan2f(@float.neg_infinity, 1.0), content="-1.570796251296997")
///   inspect(atan2f(1.0, @float.neg_infinity), content="3.1415927410125732")
///   inspect(atan2f(@float.infinity, @float.infinity), content="0.7853981852531433")
///   inspect(atan2f(@float.neg_infinity, @float.neg_infinity), content="-2.356194496154785")
///   inspect(atan2f(@float.infinity, @float.neg_infinity), content="2.356194496154785")
///   inspect(atan2f(@float.neg_infinity, @float.infinity), content="-0.7853981852531433")
/// ```
pub fn atan2f(y : Float, x : Float) -> Float {
  if x.is_nan() || y.is_nan() {
    return @float.not_a_number
  }
  let pi : Float = 3.1415927410e+00
  let pi_lo : Float = -8.7422776573e-08
  let zero : Float = 0.0
  let ix = x.reinterpret_as_uint()
  let iy = y.reinterpret_as_uint()
  if ix == 0x3f800000 {
    return atanf(y)
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
    atanf(y / x)
  }
  match m {
    0 => z
    1 => -z
    2 => pi - (z - pi_lo)
    _ => z - pi_lo - pi
  }
}
