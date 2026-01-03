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

///|
/// Calculates the tangent of a number in radians. Handles special cases and edge
/// conditions according to IEEE 754 standards.
///
/// Parameters:
///
/// * `x` : The angle in radians for which to calculate the tangent.
///
/// Returns the tangent of the angle `x`.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@math.tan(0.0), content="0")
///   inspect(@math.tan(0.7853981633974483), content="0.9999999999999999")
///   inspect(@math.tan(4.0), content="1.1578212823495777")
///   inspect(@math.tan(5.0), content="-3.380515006246586")
///   inspect(@math.tan(31415926535897.9323846), content="0.0012091241554056254")
///   inspect(@math.tan(@double.not_a_number), content="NaN")
///   inspect(@math.tan(@double.infinity), content="NaN")
///   inspect(@math.tan(@double.neg_infinity), content="NaN")
/// }
/// ```
pub fn tan(x : Double) -> Double {
  if x.is_inf() || x.is_nan() {
    return @double.not_a_number
  }
  let y = Array::make(2, 0.0)
  let z = 0.0
  if x.abs() <= PI_OVER_4 {
    __kernal_tan(x, z, 1)
  } else {
    let n = rem_pio2(x, y)
    __kernal_tan(y[0], y[1], 1 - ((n & 1) << 1))
  }
}

///|
/// Calculates the arcsine of a number. Handles special cases and edge conditions
/// according to IEEE 754 standards.
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
/// ```mbt check
/// test {
///   inspect(@math.asin(0.0), content="0")
///   inspect(@math.asin(1.0), content="1.5707963267948966")
///   inspect(@math.asin(-1.0), content="-1.5707963267948966")
///   inspect(@math.asin(@double.not_a_number), content="NaN")
///   inspect(@math.asin(@double.infinity), content="NaN")
///   inspect(@math.asin(@double.neg_infinity), content="NaN")
/// }
/// ```
pub fn asin(x : Double) -> Double {
  let huge = 1.0e+300
  let pio4_hi = 7.85398163397448278999e-01
  let pio2_hi = 1.57079632679489655800
  let pio2_lo = 6.12323399573676603587e-17
  let ps0 = 1.66666666666666657415e-01
  let ps1 = -3.25565818622400915405e-01
  let ps2 = 2.01212532134862925881e-01
  let ps3 = -4.00555345006794114027e-02
  let ps4 = 7.91534994289814532176e-04
  let ps5 = 3.47933107596021167570e-05
  let qs1 = -2.40339491173441421878e+00
  let qs2 = 2.02094576023350569471e+00
  let qs3 = -6.88283971605453293030e-01
  let qs4 = 7.70381505559019352791e-02
  let ix = get_high_word(x).reinterpret_as_int() & 0x7fffffff
  let absx = x.abs()
  if absx >= 1.0 {
    if absx == 1.0 {
      return x * pio2_hi + x * pio2_lo
    } else {
      return @double.not_a_number
    }
  } else if absx < 0.5 {
    if ix < 0x3e400000 {
      if huge + x > 1.0 {
        return x
      }
    } else {
      let t = x * x
      let p = t *
        (ps0 + t * (ps1 + t * (ps2 + t * (ps3 + t * (ps4 + t * ps5)))))
      let q = 1.0 + t * (qs1 + t * (qs2 + t * (qs3 + t * qs4)))
      let w = p / q
      return x + x * w
    }
  }
  let w = 1.0 - absx
  let t = w * 0.5
  let p = t * (ps0 + t * (ps1 + t * (ps2 + t * (ps3 + t * (ps4 + t * ps5)))))
  let q = 1.0 + t * (qs1 + t * (qs2 + t * (qs3 + t * qs4)))
  let s = t.sqrt()
  if ix >= 0x3FEF3333 {
    let w = p / q
    let t = pio2_hi - (2.0 * (s + s * w) - pio2_lo)
    return if x > 0.0 { t } else { -t }
  } else {
    let mut w = s
    w = set_low_word(w, 0)
    let c = (t - w * w) / (s + w)
    let r = p / q
    let p = 2.0 * s * r - (pio2_lo - 2.0 * c)
    let q = pio4_hi - 2.0 * w
    let t = pio4_hi - (p - q)
    return if x > 0.0 { t } else { -t }
  }
}

///|
/// Calculates the arccosine of a number.
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
/// ```mbt check
/// test {
///   inspect(@math.acos(0.0), content="1.5707963267948966")
///   inspect(@math.acos(1.0), content="0")
///   inspect(@math.acos(-1.0), content="3.141592653589793")
///   inspect(@math.acos(@double.not_a_number), content="NaN")
///   inspect(@math.acos(@double.infinity), content="NaN")
///   inspect(@math.acos(@double.neg_infinity), content="NaN")
/// }
/// ```
pub fn acos(x : Double) -> Double {
  let one : Double = 1.0
  let pi : Double = 3.14159265358979311600
  let pio2_hi : Double = 1.57079632679489655800
  let pio2_lo : Double = 6.12323399573676603587e-17
  let ps0 : Double = 1.66666666666666657415e-01
  let ps1 : Double = -3.25565818622400915405e-01
  let ps2 : Double = 2.01212532134862925881e-01
  let ps3 : Double = -4.00555345006794114027e-02
  let ps4 : Double = 7.91534994289814532176e-04
  let ps5 : Double = 3.47933107596021167570e-05
  let qs1 : Double = -2.40339491173441421878e+00
  let qs2 : Double = 2.02094576023350569471e+00
  let qs3 : Double = -6.88283971605453293030e-01
  let qs4 : Double = 7.70381505559019352791e-02
  let ix = get_high_word(x).reinterpret_as_int() & 0x7fffffff
  let absx = x.abs()
  if absx >= 1.0 {
    if absx == 1.0 {
      if x > 0 {
        return 0.0
      } else {
        return pi + 2.0 * pio2_lo
      }
    }
    return @double.not_a_number
  }
  if absx < 0.5 {
    if ix <= 0x3c600000 {
      return pio2_hi + pio2_lo
    }
    let z = x * x
    let p = z * (ps0 + z * (ps1 + z * (ps2 + z * (ps3 + z * (ps4 + z * ps5)))))
    let q = one + z * (qs1 + z * (qs2 + z * (qs3 + z * qs4)))
    let r = p / q
    pio2_hi - (x - (pio2_lo - x * r))
  } else if x < 0 {
    let z = (one + x) * 0.5
    let p = z * (ps0 + z * (ps1 + z * (ps2 + z * (ps3 + z * (ps4 + z * ps5)))))
    let q = one + z * (qs1 + z * (qs2 + z * (qs3 + z * qs4)))
    let s = z.sqrt()
    let r = p / q
    let w = r * s - pio2_lo
    pi - 2.0 * (s + w)
  } else {
    let z = (one - x) * 0.5
    let s = z.sqrt()
    let df = s
    let c = (z - df * df) / (s + df)
    let p = z * (ps0 + z * (ps1 + z * (ps2 + z * (ps3 + z * (ps4 + z * ps5)))))
    let q = one + z * (qs1 + z * (qs2 + z * (qs3 + z * qs4)))
    let r = p / q
    let w = r * s + c
    2.0 * (df + w)
  }
}

///|
/// Calculates the arctangent of a number.
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
/// ```mbt check
/// test {
///   inspect(@math.atan(0.0), content="0")
///   inspect(@math.atan(1.0), content="0.7853981633974483")
///   inspect(@math.atan(-1.0), content="-0.7853981633974483")
///   inspect(@math.atan(@double.not_a_number), content="NaN")
///   inspect(@math.atan(@double.infinity), content="1.5707963267948966")
///   inspect(@math.atan(@double.neg_infinity), content="-1.5707963267948966")
/// }
/// ```
pub fn atan(x : Double) -> Double {
  if x.is_nan() || x == 0.0 {
    return x
  }
  let atan_hi : ReadOnlyArray[Double] = [
    4.63647609000806093515e-01, 7.85398163397448278999e-01, 9.82793723247329054082e-01,
    1.57079632679489655800e+00,
  ]
  let atan_lo : ReadOnlyArray[Double] = [
    2.26987774529616870924e-17, 3.06161699786838301793e-17, 1.39033110312309984516e-17,
    6.12323399573676603587e-17,
  ]
  let a_t : ReadOnlyArray[Double] = [
    3.33333333333329318027e-01, -1.99999999998764832476e-01, 1.42857142725034663711e-01,
    -1.11111104054623557880e-01, 9.09088713343650656196e-02, -7.69187620504482999495e-02,
    6.66107313738753120669e-02, -5.83357013379057348645e-02, 4.97687799461593236017e-02,
    -3.65315727442169155270e-02, 1.62858201153657823623e-02,
  ]
  let one = 1.0
  let huge = 1.0e300
  let ix = get_high_word(x).reinterpret_as_int() & 0x7fffffff
  let mut id = 0
  let mut z = 0.0
  let mut w = 0.0
  let mut x = x
  let x_is_neg = x < 0.0
  if ix >= 0x44100000 {
    if x > 0 {
      return atan_hi[3] + atan_lo[3]
    } else {
      return -atan_hi[3] - atan_lo[3]
    }
  }
  if ix < 0x3fdc0000 {
    if ix < 0x3e200000 {
      if huge + x > one {
        return x
      }
    }
    id = -1
  } else {
    x = x.abs()
    if ix < 0x3ff30000 {
      if ix < 0x3fe60000 {
        id = 0
        x = (2.0 * x - one) / (2.0 + x)
      } else {
        id = 1
        x = (x - one) / (x + one)
      }
    } else if ix < 0x40038000 {
      id = 2
      x = (x - 1.5) / (one + 1.5 * x)
    } else {
      id = 3
      x = -1.0 / x
    }
  }
  z = x * x
  w = z * z
  let s1 = z *
    (
      a_t[0] +
      w * (a_t[2] + w * (a_t[4] + w * (a_t[6] + w * (a_t[8] + w * a_t[10]))))
    )
  let s2 = w *
    (a_t[1] + w * (a_t[3] + w * (a_t[5] + w * (a_t[7] + w * a_t[9]))))
  if id < 0 {
    x - x * (s1 + s2)
  } else {
    z = atan_hi[id] - (x * (s1 + s2) - atan_lo[id] - x)
    if x_is_neg {
      -z
    } else {
      z
    }
  }
}

///|
/// Calculates the arctangent of the quotient of two numbers.
///
/// Parameters:
///
/// * `y` : The numerator of the quotient.
/// * `x` : The denominator of the quotient.
///
/// Returns the arctangent of the quotient `y / x`.
///
/// * Returns NaN if y or x is NaN.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@math.atan2(0.0, -1.0), content="3.141592653589793")
///   inspect(@math.atan2(1.0, 0.0), content="1.5707963267948966")
///   inspect(@math.atan2(1.0, 1.0), content="0.7853981633974483")
///   inspect(@math.atan2(@double.not_a_number, 1.0), content="NaN")
///   inspect(@math.atan2(1.0, @double.not_a_number), content="NaN")
///   inspect(@math.atan2(@double.infinity, 1.0), content="1.5707963267948966")
///   inspect(@math.atan2(1.0, @double.infinity), content="0")
///   inspect(@math.atan2(@double.neg_infinity, 1.0), content="-1.5707963267948966")
///   inspect(@math.atan2(1.0, @double.neg_infinity), content="3.141592653589793")
///   inspect(
///     @math.atan2(@double.infinity, @double.infinity),
///     content="0.7853981633974483",
///   )
///   inspect(
///     @math.atan2(@double.neg_infinity, @double.neg_infinity),
///     content="-2.356194490192345",
///   )
///   inspect(
///     @math.atan2(@double.infinity, @double.neg_infinity),
///     content="2.356194490192345",
///   )
///   inspect(
///     @math.atan2(@double.neg_infinity, @double.infinity),
///     content="-0.7853981633974483",
///   )
/// }
/// ```
pub fn atan2(y : Double, x : Double) -> Double {
  if x.is_nan() || y.is_nan() {
    return @double.not_a_number
  }
  let tiny = 1.0e-300
  let zero = 0.0
  let pi_o_4 = 7.8539816339744827900E-01
  let pi_o_2 = 1.5707963267948965580E+00
  let pi = 3.1415926535897931160E+00
  let pi_lo = 1.2246467991473531772E-16
  let hx = get_high_word(x).reinterpret_as_int()
  let hy = get_high_word(y).reinterpret_as_int()
  let ix = hx & 0x7fffffff
  let iy = hy & 0x7fffffff
  if x == 1.0 {
    return atan(y)
  }
  let m = ((hy >> 31) & 1) | ((hx >> 30) & 2)
  if y == 0 {
    match m {
      0 | 1 => return y
      2 => return pi + tiny
      _ => return -pi - tiny
    }
  }
  if x == 0 {
    return if hy < 0 { -pi_o_2 - tiny } else { pi_o_2 + tiny }
  }
  if x.is_inf() {
    if y.is_inf() {
      match m {
        0 => return pi_o_4 + tiny
        1 => return -pi_o_4 - tiny
        2 => return 3.0 * pi_o_4 + tiny
        _ => return -3.0 * pi_o_4 - tiny
      }
    } else {
      match m {
        0 => return zero
        1 => return -zero
        2 => return pi + tiny
        _ => return -pi - tiny
      }
    }
  }
  if y.is_inf() {
    return if hy < 0 { -pi_o_2 - tiny } else { pi_o_2 + tiny }
  }
  let k = (iy - ix) >> 20
  let z = if k > 60 {
    pi_o_2 + 0.5 * pi_lo
  } else if hx < 0 && k < -60 {
    0.0
  } else {
    atan(abs(y / x))
  }
  match m {
    0 => z
    1 => -z
    2 => pi - (z - pi_lo)
    _ => z - pi_lo - pi
  }
}

///|
fn rem_pio2(x : Double, y : Array[Double]) -> Int {
  let hx = get_high_word(x).reinterpret_as_int()
  let ix : Int = hx & 0x7fffffff
  let mut z = 0.0
  if ix <= 0x3fe921fb {
    // |x| <= pi/4, no reduction needed
    y[0] = x
    y[1] = 0.0
    return 0
  }
  if ix < 0x4002d97c {
    // |x| < 3pi/4, special case with n = +-1
    if hx > 0 {
      z = x - PIO2_1
      if ix != 0x3ff921fb {
        // 33+53 bit pi is good enough
        y[0] = z - PIO2_1T
        y[1] = z - y[0] - PIO2_1T
      } else {
        // Near pi/2, use 33+33+53 bit pi
        z = z - PIO2_2
        y[0] = z - PIO2_2T
        y[1] = z - y[0] - PIO2_2T
      }
      return 1
    } else {
      // Negative x
      z = x + PIO2_1
      if ix != 0x3ff921fb {
        // 33+53 bit pi is good enough
        y[0] = z + PIO2_1T
        y[1] = z - y[0] + PIO2_1T
      } else {
        // Near pi/2, use 33+33+53 bit pi
        let z = z + PIO2_2
        y[0] = z + PIO2_2T
        y[1] = z - y[0] + PIO2_2T
      }
      return -1
    }
  }
  if ix <= 0x413921fb {
    // |x| <= 2^19 * (pi/2), medium size
    let t = x.abs()
    let n = (t * INV_PIO2 + HALF).to_int()
    let fn_ = n.to_double()
    let mut r = t - fn_ * PIO2_1
    let mut w = fn_ * PIO2_1T
    if n < 32 && ix != npio2_hw[n - 1] {
      y[0] = r - w
    } else {
      let j = ix >> 20
      y[0] = r - w
      let i = j - ((get_high_word(y[0]) >> 20).reinterpret_as_int() & 0x7ff)
      if i > 16 {
        // 2nd iteration needed, good to 118 bits
        let t = r
        w = fn_ * PIO2_2
        r = t - w
        w = fn_ * PIO2_2T - (t - r - w)
        y[0] = r - w
        let i = j - ((get_high_word(y[0]) >> 20).reinterpret_as_int() & 0x7ff)
        if i > 49 {
          // 3rd iteration needed, 151 bits accuracy
          let t = r
          w = fn_ * PIO2_3
          r = t - w
          w = fn_ * PIO2_3T - (t - r - w)
          y[0] = r - w
        }
      }
    }
    y[1] = r - y[0] - w
    if hx > 0 {
      return n
    } else {
      y[0] = -y[0]
      y[1] = -y[1]
      return -n
    }
  }

  // All other (large) arguments
  if ix >= 0x7ff00000 {
    // x is inf or NaN
    y[0] = x - x
    y[1] = y[0]
    return 0
  }

  // Set z = scalbn(|x|, ilogb(x) - 23)
  z = set_low_word(z, get_low_word(x))
  let e0 = (ix >> 20) - 1046 // e0 = ilogb(z) - 23
  z = set_high_word(z, (ix - (e0 << 20)).reinterpret_as_uint())
  let tx = [0.0, 0.0, 0.0]
  for i in 0..<2 {
    tx[i] = z.to_int().to_double()
    z = (z - tx[i]) * TWO24
  }
  tx[2] = z
  let mut nx = 3
  while tx[nx - 1] == 0.0 {
    nx -= 1
  }
  let n = __kernel_rem_pio2(tx, y, e0, nx, 2)
  if hx > 0 {
    n
  } else {
    y[0] = -y[0]
    y[1] = -y[1]
    -n
  }
}

///|
fn __kernel_rem_pio2(
  x : Array[Double],
  y : Array[Double],
  e0 : Int,
  nx : Int,
  prec : Int,
) -> Int {
  let init_jk : ReadOnlyArray[Int] = [2, 3, 4, 6]
  let two24 : Double = 16777216.0 // 0x41700000, 0x00000000
  let twon24 : Double = 5.96046447753906250000e-08 // 0x3E700000, 0x00000000

  // Declare variables at the beginning, as in the original C code
  let mut jz : Int = 0
  let mut jx : Int = 0
  let mut jv : Int = 0
  let mut jp : Int = 0
  let mut jk : Int = 0
  let mut carry : Int = 0
  let mut n : Int = 0
  let iq : Array[Int] = Array::make(20, 0)
  let mut i : Int = 0
  let mut j : Int = 0
  let mut k : Int = 0
  let mut m : Int = 0
  let mut q0 : Int = 0
  let mut ih : Int = 0
  let mut z : Double = 0
  let mut fw : Double = 0
  let f : Array[Double] = Array::make(20, 0.0)
  let fq : Array[Double] = Array::make(20, 0.0)
  let q : Array[Double] = Array::make(20, 0.0)

  // initialize jk
  jk = init_jk[prec]
  jp = jk

  // determine jx, jv, q0, note that 3 > q0
  jx = nx - 1
  jv = (e0 - 3) / 24
  if jv < 0 {
    jv = 0
  }
  q0 = e0 - 24 * (jv + 1)

  // set up f[0] to f[jx+jk] where f[jx+jk] = ipio2[jv+jk]
  j = jv - jx
  m = jx + jk
  i = 0
  while i <= m {
    f[i] = if j < 0 { 0.0 } else { two_over_pi[j].to_double() }
    i += 1
    j += 1
  }

  // compute q[0], q[1], ... q[jk]
  i = 0
  while i <= jk {
    j = 0
    fw = 0.0
    while j <= jx {
      fw += x[j] * f[jx + i - j]
      j += 1
    }
    q[i] = fw
    i += 1
  }
  jz = jk

  // Use a loop to replace the `goto` logic
  let mut recompute = true
  while recompute {
    recompute = false

    // distill q[] into iq[] reversingly
    i = 0
    j = jz
    z = q[jz]
    while j > 0 {
      fw = (twon24 * z).floor()
      iq[i] = (z - two24 * fw).to_int()
      z = q[j - 1] + fw
      i += 1
      j -= 1
    }

    // compute n
    z = scalbn(z, q0) // actual value of z
    z -= 8.0 * (z * 0.125).floor() // trim off integer >= 8
    n = z.to_int()
    z -= n.to_double()
    ih = 0
    if q0 > 0 {
      // need iq[jz-1] to determine n
      i = iq[jz - 1] >> (24 - q0)
      n += i
      iq[jz - 1] -= i << (24 - q0)
      ih = iq[jz - 1] >> (23 - q0)
    } else if q0 == 0 {
      ih = iq[jz - 1] >> 23
    } else if z >= 0.5 {
      ih = 2
    }
    if ih > 0 {
      // q > 0.5
      n += 1
      carry = 0
      i = 0
      while i < jz {
        j = iq[i]
        if carry == 0 {
          if j != 0 {
            carry = 1
            iq[i] = 0x1000000 - j
          }
        } else {
          iq[i] = 0xffffff - j
        }
        i += 1
      }
      if q0 > 0 {
        // rare case: chance is 1 in 12
        match q0 {
          1 => iq[jz - 1] = iq[jz - 1] & 0x7fffff
          2 => iq[jz - 1] = iq[jz - 1] & 0x3fffff
          _ => ()
        }
      }
      if ih == 2 {
        z = 1.0 - z
        if carry != 0 {
          z -= scalbn(1.0, q0)
        }
      }
    }

    // check if recomputation is needed
    if z == 0.0 {
      j = 0
      i = jz - 1
      while i >= jk {
        j = j | iq[i]
        i -= 1
      }
      if j == 0 {
        // need recomputation
        k = 1
        while iq[jk - k] == 0 {
          k += 1
        }
        i = jz + 1
        while i <= jz + k {
          f[jx + i] = two_over_pi[jv + i].to_double()
          j = 0
          fw = 0.0
          while j <= jx {
            fw += x[j] * f[jx + i - j]
            j += 1
          }
          q[i] = fw
          i += 1
        }
        jz += k
        recompute = true // Continue to recompute
        continue
      }
    } // Skip the rest of the loop and recompute

    // chop off zero terms
    if z == 0.0 {
      jz -= 1
      q0 -= 24
      while iq[jz] == 0 {
        jz -= 1
        q0 -= 24
      }
    } else {
      // break z into 24-bit if necessary
      z = scalbn(z, -q0)
      if z >= two24 {
        fw = (twon24 * z).floor()
        iq[jz] = (z - two24 * fw).to_int()
        jz += 1
        q0 += 24
        iq[jz] = fw.to_int()
      } else {
        iq[jz] = z.to_int()
      }
    }

    // convert integer "bit" chunk to floating-point value
    fw = scalbn(1.0, q0)
    i = jz
    while i >= 0 {
      q[i] = fw * iq[i].to_double()
      fw *= twon24
      i -= 1
    }

    // compute PIo2[0,...,jp] * q[jz,...,0]
    i = jz
    while i >= 0 {
      fw = 0.0
      k = 0
      while k <= jp && k <= jz - i {
        fw += pi_over_2[k] * q[i + k]
        k += 1
      }
      fq[jz - i] = fw
      i -= 1
    }

    // compress fq[] into y[]
    match prec {
      0 => {
        fw = 0.0
        i = jz
        while i >= 0 {
          fw += fq[i]
          i -= 1
        }
        y[0] = if ih == 0 { fw } else { -fw }
      }
      1 | 2 => {
        fw = 0.0
        i = jz
        while i >= 0 {
          fw += fq[i]
          i -= 1
        }
        y[0] = if ih == 0 { fw } else { -fw }
        fw = fq[0] - fw
        i = 1
        while i <= jz {
          fw += fq[i]
          i += 1
        }
        y[1] = if ih == 0 { fw } else { -fw }
      }
      3 => {
        i = jz
        while i > 0 {
          fw = fq[i - 1] + fq[i]
          fq[i] += fq[i - 1] - fw
          fq[i - 1] = fw
          i -= 1
        }
        i = jz
        while i > 1 {
          fw = fq[i - 1] + fq[i]
          fq[i] += fq[i - 1] - fw
          fq[i - 1] = fw
          i -= 1
        }
        fw = 0.0
        i = jz
        while i >= 2 {
          fw += fq[i]
          i -= 1
        }
        if ih == 0 {
          y[0] = fq[0]
          y[1] = fq[1]
          y[2] = fw
        } else {
          y[0] = -fq[0]
          y[1] = -fq[1]
          y[2] = -fw
        }
      }
      _ => ()
    }
  }
  n & 7
}

///|
fn __kernel_sin(x : Double, y : Double, iy : Int) -> Double {
  let s1 = -1.66666666666666324348e-01
  let s2 = 8.33333333332248946124e-03
  let s3 = -1.98412698298579493134e-04
  let s4 = 2.75573137070700676789e-06
  let s5 = -2.50507602534068634195e-08
  let s6 = 1.58969099521155010221e-10
  let mut z = 0.0
  let mut r = 0.0
  let mut v = 0.0
  let ix = get_high_word(x) & 0x7fffffff
  if ix < 0x3e400000 {
    if x.to_int() == 0 {
      return x
    }
  }
  z = x * x
  v = z * x
  r = s2 + z * (s3 + z * (s4 + z * (s5 + z * s6)))
  if iy == 0 {
    x + v * (s1 + z * r)
  } else {
    x - (z * (0.5 * y - v * r) - y - v * s1)
  }
}

///|
fn __kernel_cos(x : Double, y : Double) -> Double {
  let one = 1.00000000000000000000e+00
  let c1 = 4.16666666666666019037e-02
  let c2 = -1.38888888888741095749e-03
  let c3 = 2.48015872894767294178e-05
  let c4 = -2.75573143513906633035e-07
  let c5 = 2.08757232129817482790e-09
  let c6 = -1.13596475577881948265e-11
  let mut a = 0.0
  let mut hz = 0.0
  let mut z = 0.0
  let mut r = 0.0
  let mut qx = 0.0
  let ix = get_high_word(x) & 0x7fffffff
  if ix < 0x3e400000 {
    if x.to_int() == 0 {
      return one
    }
  }
  z = x * x
  r = z * (c1 + z * (c2 + z * (c3 + z * (c4 + z * (c5 + z * c6)))))
  if ix < 0x3fd33333 {
    return one - (0.5 * z - (z * r - x * y))
  } else {
    if ix > 0x3fe90000 {
      qx = 0.28125
    } else {
      qx = ((ix - 0x00200000).to_uint64() << 32).reinterpret_as_double()
    }
    hz = 0.5 * z - qx
    a = one - qx
    return a - (hz - (z * r - x * y))
  }
}

///|
fn __kernal_tan(x : Double, y : Double, iy : Int) -> Double {
  let one = 1.0
  let pio4 = 7.85398163397448278999e-01
  let pio4lo = 3.06161699786838301793e-17
  let mut x = x
  let mut y = y
  let mut z = 0.0
  let mut r = 0.0
  let mut v = 0.0
  let mut w = 0.0
  let mut s = 0.0
  let t : ReadOnlyArray[Double] = [
    3.33333333333334091986e-01, // 3FD55555, 55555563 */
     1.33333333333201242699e-01, // 3FC11111, 1110FE7A */
     5.39682539762260521377e-02, // 3FABA1BA, 1BB341FE */
     2.18694882948595424599e-02, // 3F9664F4, 8406D637 */
     8.86323982359930005737e-03, // 3F8226E3, E96E8493 */
     3.59207910759131235356e-03, // 3F6D6D22, C9560328 */
     1.45620945432529025516e-03, // 3F57DBC8, FEE08315 */
     5.88041240820264096874e-04, // 3F4344D8, F2F26501 */
     2.46463134818469906812e-04, // 3F3026F7, 1A8D1068 */
     7.81794442939557092300e-05, // 3F147E88, A03792A6 */
     7.14072491382608190305e-05, // 3F12B80F, 32F0A7E9 */
     -1.85586374855275456654e-05, // BEF375CB, DB605373 */
     2.59073051863633712884e-05, // 3EFB2A70, 74BF7AD4 */
     1.00000000000000000000e+00, // 3FF00000, 00000000 (one) */
     7.85398163397448278999e-01, // 3FE921FB, 54442D18 (pio4) */
     3.06161699786838301793e-17, // 3C81A626, 33145C07 (pio4lo) */
  ]
  let hx = get_high_word(x).reinterpret_as_int()
  let ix = hx & 0x7fffffff
  if ix < 0x3e300000 {
    if x.to_int() == 0 {
      if (ix | get_low_word(x).reinterpret_as_int() | (iy + 1)) == 0 {
        return one / x.abs()
      } else if iy == 1 {
        return x
      } else {
        w = x + y
        z = w
        z = set_low_word(z, 0)
        v = y - (z - x)
        let a = -one / w
        let mut t = a
        t = set_low_word(t, 0)
        s = one + t * z
        return t + a * (s + t * v)
      }
    }
  }
  if ix >= 0x3fe59428 {
    if hx < 0 {
      x = -x
      y = -y
    }
    z = pio4 - x
    w = pio4lo - y
    x = z + w
    y = 0.0
  }
  z = x * x
  w = z * z
  r = t[1] + w * (t[3] + w * (t[5] + w * (t[7] + w * (t[9] + w * t[11]))))
  v = z *
    (t[2] + w * (t[4] + w * (t[6] + w * (t[8] + w * (t[10] + w * t[12])))))
  s = z * x
  r = y + z * (s * (r + v) + y)
  r += t[0] * s
  w = x + r
  if ix >= 0x3fe59428 {
    v = iy.to_double()
    return (1 - ((hx >> 30) & 2)).to_double() *
      (v - 2.0 * (x - (w * w / (w + v) - r)))
  }
  if iy == 1 {
    w
  } else {
    z = w
    z = set_low_word(z, 0)
    v = r - (z - x)
    let a = -1.0 / w
    let mut t = a
    t = set_low_word(t, 0)
    s = 1.0 + t * z
    t + a * (s + t * v)
  }
}
