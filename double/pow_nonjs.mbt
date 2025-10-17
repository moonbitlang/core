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
let pow_bp : FixedArray[Double] = [1.0, 1.5]

///|
let pow_dp_h : FixedArray[Double] = [0.0, 5.84962487220764160156e-01]

///|
let pow_dp_l : FixedArray[Double] = [0.0, 1.35003920212974897128e-08]

///|
const ZERO = 0.0

///|
const ONE = 1.0

///|
const TWO = 2.0

///|
const POW_two53 = 9007199254740992.0

///|
const POW_huge = 1.0e300

///|
const POW_tiny = 1.0e-300

// poly coefs for (3/2)*(log(x)-2s-2/3*s**3

///|
const POW_L1 = 5.99999999999994648725e-01

///|
const POW_L2 = 4.28571428578550184252e-01

///|
const POW_L3 = 3.33333329818377432918e-01

///|
const POW_L4 = 2.72728123808534006489e-01

///|
const POW_L5 = 2.30660745775561754067e-01

///|
const POW_L6 = 2.06975017800338417784e-01

///|
const POW_P1 = 1.66666666666666019037e-01

///|
const POW_P2 = -2.77777777770155933842e-03

///|
const POW_P3 = 6.61375632143793436117e-05

///|
const POW_P4 = -1.65339022054652515390e-06

///|
const POW_P5 = 4.13813679705723846039e-08

///|
const POW_lg2 = 6.93147180559945286227e-01

///|
const POW_lg2_h = 6.93147182464599609375e-01

///|
const POW_lg2_l = -1.90465429995776804525e-09

///|
/// -(1024-log2(ovfl+.5ulp))
const POW_ovt = 8.0085662595372944372e-0017

///|
/// 2/(3ln2)
const POW_cp = 9.61796693925975554329e-01

///|
const POW_cp_h = 9.61796700954437255859e-01

///|
const POW_cp_l = -7.02846165095275826516e-09

///|
/// 1/ln2
const POW_ivln2 = 1.44269504088896338700e+00

///|
const POW_ivln2_h = 1.44269502162933349609e+00

///|
const POW_ivln2_l = 1.92596299112661746887e-08

///|
/// Calculates the power of a number by raising the base to the specified
/// exponent. Handles special cases and edge conditions according to IEEE 754
/// standards.
///
/// Parameters:
///
/// * `base` : The base number to be raised to a power.
/// * `exponent` : The power to raise the base number to.
///
/// Returns the result of raising `base` to the power of `exponent`.
///
/// Example:
///
/// ```moonbit
///   let x = 2.0
///   inspect(x.pow(3.0), content="8")
///   inspect(x.pow(0.5), content="1.4142135623730951")
///   inspect(x.pow(0.0), content="1")
///   inspect((-1.0).pow(2.0), content="1")
///   inspect(0.0.pow(0.0), content="1")
///   inspect(@double.infinity.pow(-1.0), content="0")
/// ```
#as_free_fn
pub fn Double::pow(self : Double, other : Double) -> Double {
  fn set_low_word(d : Double, v : UInt) -> Double {
    let bits : UInt64 = d.reinterpret_as_uint64()
    let bits = bits & 0xFFFF_FFFF_0000_0000
    let bits = bits | v.to_uint64()
    bits.reinterpret_as_double()
  }

  fn set_high_word(d : Double, v : UInt) -> Double {
    let bits : UInt64 = d.reinterpret_as_uint64()
    let bits = bits & 0x0000_0000_FFFF_FFFF
    let bits = bits | (v.to_uint64() << 32)
    bits.reinterpret_as_double()
  }

  fn get_high_word(x : Double) -> UInt {
    (x.reinterpret_as_uint64() >> 32).to_uint()
  }

  fn get_low_word(x : Double) -> UInt {
    x.reinterpret_as_uint64().to_uint()
  }

  let x = self
  let y = other
  // double z, ax, z_h, z_l, p_h, p_l;
  let mut z : Double = 0.0
  let mut ax : Double = 0.0
  let mut z_h : Double = 0.0
  let mut z_l : Double = 0.0
  let mut p_h : Double = 0.0
  let mut p_l : Double = 0.0
  // double y1, t1, t2, r, s, t, u, v, w
  let mut y1 : Double = 0.0
  let mut t1 : Double = 0.0
  let mut t2 : Double = 0.0
  let mut r : Double = 0.0
  let mut s : Double = 0.0
  let mut t : Double = 0.0
  let mut u : Double = 0.0
  let mut v : Double = 0.0
  let mut w : Double = 0.0
  // int i, j, k, yisint, n
  let mut i : Int = 0
  let mut j : Int = 0
  let mut k : Int = 0
  let mut yisint : Int = 0
  let mut n : Int = 0
  // int hx, hy, ix, iy;
  // unsigned lx, ly;
  //
  // EXTRACT_WORDS(hx, lx, x);
  // EXTRACT_WORDS(hy, ly, y);
  // ix = hx & 0x7fffffff;
  // iy = hy & 0x7fffffff;
  let hx : Int = (x.reinterpret_as_uint64() >> 32).to_int()
  let lx : UInt = (x.reinterpret_as_uint64() & 0xFFFFFFFF).to_uint()
  let hy : Int = (y.reinterpret_as_uint64() >> 32).to_int()
  let ly : UInt = (y.reinterpret_as_uint64() & 0xFFFFFFFF).to_uint()
  let mut ix : Int = hx & 0x7FFFFFFF
  let iy : Int = hy & 0x7FFFFFFF
  // y==zero: x**0 = 1
  if (iy.reinterpret_as_uint() | ly) == 0 {
    return ONE
  }
  // +-NaN return x+y
  if ix > 0x7FF00000 ||
    (ix == 0x7FF00000 && lx != 0) ||
    iy > 0x7FF00000 ||
    (iy == 0x7FF00000 && ly != 0) {
    return x + y
  }
  // determine if y is an odd int when x < 0
  // yisint = 0 ... y is not an integer
  // yisint = 1 ... y is an odd int
  // yisint = 2 ... y is an even int
  if hx < 0 {
    if iy >= 0x43400000 {
      yisint = 2 // even integer y
    } else if iy >= 0x3ff00000 {
      k = (iy >> 20) - 0x3ff // exponent
      if k > 20 {
        j = (ly >> (52 - k)).reinterpret_as_int()
        if j << (52 - k) == ly.reinterpret_as_int() {
          yisint = 2 - (j & 1)
        }
      } else if ly == 0 {
        j = iy >> (20 - k)
        if j << (20 - k) == iy {
          yisint = 2 - (j & 1)
        }
      }
    }
  }
  // special value of y
  if ly == 0 {
    if iy == 0x7ff00000 { // y is +-inf
      if ((ix.reinterpret_as_uint() - 0x3ff00000) | lx) == 0 {
        return y - y // inf**+-1 is NaN
      } else if ix >= 0x3ff00000 { // (|x|>1)**+-inf = inf,0
        return if hy >= 0 { y } else { ZERO }
      } else { // (|x|<1)**-,+inf = inf,0
        return if hy < 0 { -y } else { ZERO }
      }
    }
    if iy == 0x3ff00000 { // y is  +-1
      if hy < 0 {
        return ONE / x
      } else {
        return x
      }
    }
    if hy == 0x40000000 { // y is 2
      return x * x
    }
    if hy == 0x3fe00000 { // y is 0.5
      if hx >= 0 { // x >= +0
        return x.sqrt()
      }
    }
  }
  ax = x.abs()
  // special value of x
  if lx == 0 {
    if ix == 0x7ff00000 || ix == 0 || ix == 0x3ff00000 {
      z = ax // x is +-0,+-inf,+-1 */
      if hy < 0 {
        z = ONE / z // z = (1/|x|)
      }
      if hx < 0 {
        if ((ix - 0x3ff00000) | yisint) == 0 {
          // (-1)**non-int is NaN
          z = not_a_number
        } else if yisint == 1 {
          z = -z // (x<0)**odd = -(|x|**odd)
        }
      }
      return z
    }
  }
  n = (hx >> 31) + 1
  // (x<0)**(non-int) is NaN
  if (n | yisint) == 0 {
    return not_a_number
  }
  s = ONE // s (sign of result -ve**odd) = -1 else = 1
  if (n | (yisint - 1)) == 0 {
    s = -ONE // (-ve)**(odd int)
  }
  // |y| is huge
  if iy > 0x41e00000 { // if |y| > 2**31 */
    if iy > 0x43f00000 { // if |y| > 2**64, must o/uflow */
      if ix <= 0x3fefffff {
        return if hy < 0 { POW_huge * POW_huge } else { POW_tiny * POW_tiny }
      }
      if ix >= 0x3ff00000 {
        return if hy > 0 { POW_huge * POW_huge } else { POW_tiny * POW_tiny }
      }
    }
    // over/underflow if x is not close to one */
    if ix < 0x3fefffff {
      return if hy < 0 {
        s * POW_huge * POW_huge
      } else {
        s * POW_tiny * POW_tiny
      }
    }
    if ix > 0x3ff00000 {
      return if hy > 0 {
        s * POW_huge * POW_huge
      } else {
        s * POW_tiny * POW_tiny
      }
    }
    // now |1-x| is tiny <= 2**-20, suffice to compute
    // log(x) by x-x^2/2+x^3/3-x^4/4 */
    t = ax - ONE // t has 20 trailing zeros */
    w = t * t * (0.5 - t * (0.3333333333333333333333 - t * 0.25))
    u = POW_ivln2_h * t // POW_ivln2_h has 21 sig. bits */
    v = t * POW_ivln2_l - w * POW_ivln2
    t1 = u + v
    t1 = set_low_word(t1, 0)
    t2 = v - (t1 - u)
  } else {
    n = 0
    // take care subnormal number
    if ix < 0x00100000 {
      ax *= POW_two53
      n -= 53
      ix = get_high_word(ax).reinterpret_as_int()
    }
    n += (ix >> 20) - 0x3ff
    j = ix & 0x000fffff
    // determine interval
    ix = j | 0x3ff00000 // normalize ix
    if j <= 0x3988E {
      k = 0 // |x|<sqrt(3/2)
    } else if j < 0xBB67A {
      k = 1 // |x|<sqrt(3)
    } else {
      k = 0
      n += 1
      ix -= 0x00100000
    }
    ax = set_high_word(ax, ix.reinterpret_as_uint())
    // compute ss = s_h+s_l = (x-1)/(x+1) or (x-1.5)/(x+1.5)
    u = ax - pow_bp[k] // bp[0]=1.0, bp[1]=1.5
    v = ONE / (ax + pow_bp[k])
    let ss : Double = u * v
    let mut s_h : Double = ss
    s_h = set_low_word(s_h, 0)
    // t_h=ax+bp[k] High
    let mut t_h : Double = ZERO
    t_h = set_high_word(
      t_h,
      ((ix.reinterpret_as_uint() >> 1) | 0x20000000) +
      0x00080000 +
      (k.reinterpret_as_uint() << 18),
    )
    let mut t_l : Double = ax - (t_h - pow_bp[k])
    let s_l : Double = v * (u - s_h * t_h - s_h * t_l)
    // compute log(ax)
    let mut s2 : Double = ss * ss
    r = s2 *
      s2 *
      (
        POW_L1 +
        s2 *
        (POW_L2 + s2 * (POW_L3 + s2 * (POW_L4 + s2 * (POW_L5 + s2 * POW_L6))))
      )
    r += s_l * (s_h + ss)
    s2 = s_h * s_h
    t_h = 3.0 + s2 + r
    t_h = set_low_word(t_h, 0)
    t_l = r - (t_h - 3.0 - s2)
    // u+v = ss*(1+...)
    u = s_h * t_h
    v = s_l * t_h + t_l * ss
    // 2/(3log2)*(ss+...)
    p_h = u + v
    p_h = set_low_word(p_h, 0)
    p_l = v - (p_h - u)
    z_h = POW_cp_h * p_h // cp_h+cp_l = 2/(3*log2)
    z_l = POW_cp_l * p_h + p_l * POW_cp + pow_dp_l[k]
    // log2(ax) = (ss+..)*2/(3*log2) = n + dp_h + z_h + z_l
    t = n.to_double()
    t1 = z_h + z_l + pow_dp_h[k] + t
    t1 = set_low_word(t1, 0)
    t2 = z_l - (t1 - t - pow_dp_h[k] - z_h)
  }
  // split up y into y1+y2 and compute (y1+y2)*(t1+t2)
  y1 = y
  y1 = set_low_word(y1, 0)
  p_l = (y - y1) * t1 + y * t2
  p_h = y1 * t1
  z = p_l + p_h
  j = get_high_word(z).reinterpret_as_int()
  i = get_low_word(z).reinterpret_as_int()
  if j >= 0x40900000 { // z >= 1024
    if ((j - 0x40900000) | i) != 0 { // if z > 1024
      return s * POW_huge * POW_huge // overflow
    } else if p_l + POW_ovt > z - p_h {
      return s * POW_huge * POW_huge // overflow
    }
  } else if (j & 0x7fffffff) >= 0x4090cc00 { // z <= -1075
    if ((j - 0xc090cc00) | i) != 0 { // z < -1075
      return s * POW_tiny * POW_tiny // underflow
    } else if p_l <= z - p_h {
      return s * POW_tiny * POW_tiny // underflow
    }
  }
  //
  // compute 2**(p_h+p_l)
  //
  i = j & 0x7fffffff
  k = (i >> 20) - 0x3ff
  n = 0
  if i > 0x3fe00000 { // if |z| > 0.5, set n = [z+0.5]
    n = j + (0x00100000 >> (k + 1))
    k = ((n & 0x7fffffff) >> 20) - 0x3ff // new k for n
    t = ZERO
    t = set_high_word(t, (n & (0x000fffff >> k).lnot()).reinterpret_as_uint())
    n = ((n & 0x000fffff) | 0x00100000) >> (20 - k)
    if j < 0 {
      n = -n
    }
    p_h -= t
  }
  t = p_l + p_h
  t = set_low_word(t, 0)
  u = t * POW_lg2_h
  v = (p_l - (t - p_h)) * POW_lg2 + t * POW_lg2_l
  z = u + v
  w = v - (z - u)
  t = z * z
  t1 = z -
    t * (POW_P1 + t * (POW_P2 + t * (POW_P3 + t * (POW_P4 + t * POW_P5))))
  r = z * t1 / (t1 - TWO - (w + z * w))
  z = ONE - (r - z)
  j = get_high_word(z).reinterpret_as_int()
  j += (n.reinterpret_as_uint() << 20).reinterpret_as_int()
  if j >> 20 <= 0 {
    z = scalbn(z, n)
  } else { // subnormal output */
    let tmp = get_high_word(z).reinterpret_as_int()
    z = set_high_word(
      z,
      (tmp + (n.reinterpret_as_uint() << 20).reinterpret_as_int()).reinterpret_as_uint(),
    )
  }
  return s * z
}
