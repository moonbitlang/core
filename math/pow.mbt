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

// origin: FreeBSD /usr/src/lib/msun/src/e_powf.c */
//
// Conversion to float by Ian Lance Taylor, Cygnus Support, ian@cygnus.com.
//
// ====================================================
// Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
//
// Developed at SunPro, a Sun Microsystems, Inc. business.
// Permission to use, copy, modify, and distribute this
// software is freely granted, provided that this notice
// is preserved.
// ====================================================
///

///|
/// Calculates the power of a floating-point number raised to another
/// floating-point number.
///
/// Parameters:
///
/// * `base` : The base number to be raised to a power.
/// * `exponent` : The power to which the base number is raised.
///
/// Returns the result of raising `base` to the power of `exponent`.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@math.powf(2.0, 3.0), content="8")
///   inspect(@math.powf(4.0, 0.5), content="2")
///   inspect(@math.powf(1.0, -1.0), content="1")
/// }
/// ```
pub fn powf(base : Float, exponent : Float) -> Float {
  let huge : Float = 1.0e30
  let tiny : Float = 1.0e-30
  let cp : Float = 9.6179670095e-01 // 0x3f76384f =2/(3ln2) */
  let cp_h : Float = 9.6191406250e-01 // 0x3f764000 =12b cp */
  let cp_l : Float = -1.1736857402e-04 // 0xb8f623c6 =tail of cp_h */
  let lg2 : Float = 6.9314718246e-01 // 0x3f317218 */
  let lg2_h : Float = 6.93145752e-01 // 0x3f317200 */
  let lg2_l : Float = 1.4286067653e-06 // 0x35bfbe8c */
  let ovt : Float = 8.0085662595e-08 // -(2**-28)/(log(2)**2) */
  let ivln2 : Float = 1.4426950216e+00 // 0x3f317218 */
  let ivln2_h : Float = 1.4426879883e+00 // 0x3f317218 */
  let ivln2_l : Float = 7.0526075433e-06 // 0x35bfbe8c */
  let l1 : Float = 6.0000002384e-01 // 0x3f19999a */
  let l2 : Float = 4.2857143283e-01 // 0x3edb6db7 */
  let l3 : Float = 3.3333334327e-01 // 0x3eaaaaab */
  let l4 : Float = 2.7272811532e-01 // 0x3e8ba305 */
  let l5 : Float = 2.3066075146e-01 // 0x3e6c3255 */
  let l6 : Float = 2.0697501302e-01 // 0x3e53f142 */
  let p1 : Float = 1.6666667163e-01 // 0x3e2aaaab */
  let p2 : Float = -2.7777778450e-03 // 0xbb360b61 */
  let p3 : Float = 6.6137559770e-05 // 0x388ab355 */
  let p4 : Float = -1.6533901999e-06 // 0xb5ddea0e */
  let p5 : Float = 4.1381369442e-08 // 0x3331bb4c */
  let mut z : Float = 0
  let mut ax : Float = 0
  let mut z_h : Float = 0
  let mut z_l : Float = 0
  let mut p_h : Float = 0
  let mut p_l : Float = 0
  let mut y1 : Float = 0
  let mut t1 : Float = 0
  let mut t2 : Float = 0
  let mut r : Float = 0
  let mut s : Float = 0
  let mut sn : Float = 0
  let mut t : Float = 0
  let mut u : Float = 0
  let mut v : Float = 0
  let mut w : Float = 0
  let mut i : Int = 0
  let mut j : Int = 0
  let mut k : Int = 0
  let mut yisint : Int = 0
  let mut n : Int = 0
  let mut hx : Int = 0
  let mut hy : Int = 0
  let mut ix : Int = 0
  let mut iy : Int = 0
  let mut i_s : Int = 0
  let (x, y) = (base, exponent)
  let bp : Array[Float] = [1.0, 1.5]
  let dp_h : Array[Float] = [0.0, 5.84960938e-01] // 0x3f15c000 */
  let dp_l : Array[Float] = [0.0, 1.56322085e-06] // 0x35d1cfdc */
  let two24 : Float = 16777216.0
  hx = x.reinterpret_as_int()
  hy = y.reinterpret_as_int()
  ix = hx & 0x7fffffff
  iy = hy & 0x7fffffff

  // x**0 = 1, even if x is NaN
  if iy == 0 {
    return 1.0
  }

  // 1**y = 1, even if y is NaN
  if hx == 0x3f800000 {
    return 1.0
  }

  // NaN if either arg is NaN
  if ix > 0x7f800000 || iy > 0x7f800000 {
    return x + y
  }

  // determine if y is an odd int when x < 0
  // yisint = 0       ... y is not an integer
  // yisint = 1       ... y is an odd int
  // yisint = 2       ... y is an even int
  //
  yisint = 0
  if hx < 0 {
    if iy >= 0x4b800000 {
      yisint = 2 // even integer y
    } else if iy >= 0x3f800000 {
      k = (iy >> 23) - 0x7f // exponent
      j = iy >> (23 - k)
      if j << (23 - k) == iy {
        yisint = 2 - (j & 1)
      }
    }
  }

  // special value of y
  if iy == 0x7f800000 {
    if ix == 0x3f800000 {
      // (-1)**+-inf is 1
      return 1.0
    } else if ix > 0x3f800000 {
      // (|x|>1)**+-inf = inf,0
      return if hy >= 0 { y } else { 0.0 }
    } else {
      // (|x|<1)**+-inf = 0,inf
      return if hy >= 0 { 0.0 } else { -y }
    }
  }
  if iy == 0x3f800000 {
    // y is +-1
    return if hy >= 0 { x } else { (1.0 : Float) / x }
  }
  if hy == 0x40000000 {
    // y is 2
    return x * x
  }

  // y is  0.5
  if hy == 0x3f000000 && hx >= 0 {
    // x >= +0
    return x.sqrt()
  }
  ax = x.abs()
  // special value of x
  if ix == 0x7f800000 || ix == 0 || ix == 0x3f800000 {
    // x is +-0,+-inf,+-1
    z = ax
    if hy < 0 {
      // z = (1/|x|)
      z = (1.0 : Float) / z
    }
    if hx < 0 {
      if ((ix - 0x3f800000) | yisint) == 0 {
        z = (z - z) / (z - z) // (-1)**non-int is NaN
      } else if yisint == 1 {
        z = -z
      }
    } // (x<0)**odd = -(|x|**odd)
    return z
  }
  sn = 1.0 // sign of result
  if hx < 0 {
    if yisint == 0 {
      // (x<0)**(non-int) is NaN
      return @float.not_a_number
    }
    if yisint == 1 {
      // (x<0)**(odd int)
      sn = -1.0
    }
  }

  // |y| is huge
  if iy > 0x4d000000 {
    // if |y| > 2**27
    // over/underflow if x is not close to one
    if ix < 0x3f7ffff8 {
      return if hy < 0 { sn * huge * huge } else { sn * tiny * tiny }
    }
    if ix > 0x3f800007 {
      return if hy > 0 { sn * huge * huge } else { sn * tiny * tiny }
    }

    // now |1-x| is tiny <= 2**-20, suffice to compute
    // log(x) by x-x^2/2+x^3/3-x^4/4
    t = ax - 1.0 // t has 20 trailing zeros
    w = t * t * ((0.5 : Float) - t * ((0.333333333333 : Float) - t * 0.25))
    u = ivln2_h * t // IVLN2_H has 16 sig. bits
    v = t * ivln2_l - w * ivln2
    t1 = u + v
    i_s = t1.reinterpret_as_int()
    t1 = Float::reinterpret_from_int(i_s & 0xfffff000)
    t2 = v - (t1 - u)
  } else {
    let mut s2 : Float = 0
    let mut s_h : Float = 0
    let mut s_l : Float = 0
    let mut t_h : Float = 0
    let mut t_l : Float = 0
    n = 0
    // take care subnormal number
    if ix < 0x00800000 {
      ax *= two24
      n -= 24
      ix = ax.reinterpret_as_int()
    }
    n += (ix >> 23) - 0x7f
    j = ix & 0x007fffff
    // determine interval
    ix = j | 0x3f800000 // normalize ix
    if j <= 0x1cc471 {
      // |x|<sqrt(3/2)
      k = 0
    } else if j < 0x5db3d7 {
      // |x|<sqrt(3)
      k = 1
    } else {
      k = 0
      n += 1
      ix -= 0x00800000
    }
    ax = Float::reinterpret_from_int(ix)

    // compute s = s_h+s_l = (x-1)/(x+1) or (x-1.5)/(x+1.5)
    u = ax - bp[k]
    v = (1.0 : Float) / (ax + bp[k])
    s = u * v
    s_h = s
    i_s = s_h.reinterpret_as_int()
    s_h = Float::reinterpret_from_int(i_s & 0xfffff000)
    // t_h=ax+bp[k] High
    i_s = (((ix.reinterpret_as_uint() >> 1) & 0xfffff000) | 0x20000000).reinterpret_as_int()
    t_h = Float::reinterpret_from_uint(
      i_s.reinterpret_as_uint() + 0x00400000 + (k.reinterpret_as_uint() << 21),
    )
    t_l = ax - (t_h - bp[k])
    s_l = v * (u - s_h * t_h - s_h * t_l)
    // compute log(ax) */
    s2 = s * s
    r = s2 * s2 * (l1 + s2 * (l2 + s2 * (l3 + s2 * (l4 + s2 * (l5 + s2 * l6)))))
    r += s_l * (s_h + s)
    s2 = s_h * s_h
    t_h = (3.0 : Float) + s2 + r
    i_s = t_h.reinterpret_as_int()
    t_h = Float::reinterpret_from_int(i_s & 0xfffff000)
    t_l = r - (t_h - 3.0 - s2)
    // u+v = s*(1+...)
    u = s_h * t_h
    v = s_l * t_h + t_l * s
    // 2/(3log2)*(s+...)
    p_h = u + v
    i_s = p_h.reinterpret_as_int()
    p_h = Float::reinterpret_from_int(i_s & 0xfffff000)
    p_l = v - (p_h - u)
    z_h = cp_h * p_h // cp_h+cp_l = 2/(3*log2)
    z_l = cp_l * p_h + p_l * cp + dp_l[k]
    // log2(ax) = (s+..)*2/(3*log2) = n + dp_h + z_h + z_l
    t = Float::from_int(n)
    t1 = z_h + z_l + dp_h[k] + t
    i_s = t1.reinterpret_as_int()
    t1 = Float::reinterpret_from_int(i_s & 0xfffff000)
    t2 = z_l - (t1 - t - dp_h[k] - z_h)
  }

  // split up y into y1+y2 and compute (y1+y2)*(t1+t2)
  i_s = y.reinterpret_as_int()
  y1 = Float::reinterpret_from_int(i_s & 0xfffff000)
  p_l = (y - y1) * t1 + y * t2
  p_h = y1 * t1
  z = p_l + p_h
  j = z.reinterpret_as_int()
  if j > 0x43000000 {
    // if z > 128
    return sn * huge * huge // overflow
  } else if j == 0x43000000 {
    // if z == 128
    if p_l + ovt > z - p_h {
      return sn * huge * huge
    }
  } else if ( // overflow
      j & 0x7fffffff
    ) >
    0x43160000 {
    // z < -150
    return sn * tiny * tiny // underflow
    // z == -150
  } else if j.reinterpret_as_uint() == 0xc3160000 && p_l <= z - p_h {
    return sn * tiny * tiny
  } // underflow

  //
  // compute 2**(p_h+p_l)
  //
  i = j & 0x7fffffff
  k = (i >> 23) - 0x7f
  n = 0
  if i > 0x3f000000 {
    // if |z| > 0.5, set n = [z+0.5]
    n = j + (0x00800000 >> (k + 1))
    k = ((n & 0x7fffffff) >> 23) - 0x7f // new k for n
    t = Float::reinterpret_from_int(n & (0x007fffff >> k).lnot())
    n = ((n & 0x007fffff) | 0x00800000) >> (23 - k)
    if j < 0 {
      n = -n
    }
    p_h -= t
  }
  t = p_l + p_h
  i_s = t.reinterpret_as_int()
  t = Float::reinterpret_from_int(i_s & 0xffff8000)
  u = t * lg2_h
  v = (p_l - (t - p_h)) * lg2 + t * lg2_l
  z = u + v
  w = v - (z - u)
  t = z * z
  t1 = z - t * (p1 + t * (p2 + t * (p3 + t * (p4 + t * p5))))
  r = z * t1 / (t1 - 2.0) - (w + z * w)
  z = (1.0 : Float) - (r - z)
  j = z.reinterpret_as_int()
  j += n << 23
  if j >> 23 <= 0 {
    // subnormal output
    z = scalbnf(z, n)
  } else {
    z = Float::reinterpret_from_int(j)
  }
  sn * z
}
