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
// origin: FreeBSD /usr/src/lib/msun/src/e_rem_pio2.c
// origin: FreeBSD /usr/src/lib/msun/src/e_sin.c
// origin: FreeBSD /usr/src/lib/msun/src/e_cos.c
// origin: FreeBSD /usr/src/lib/msun/src/e_tan.c
// origin: FreeBSD /usr/src/lib/msun/src/e_asin.c
// origin: FreeBSD /usr/src/lib/msun/src/e_acos.c
// origin: FreeBSD /usr/src/lib/msun/src/s_atan.c
// origin: FreeBSD /usr/src/lib/msun/src/e_atan2.c
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
let two_over_pi : FixedArray[Int] = [
  0xA2F983, 0x6E4E44, 0x1529FC, 0x2757D1, 0xF534DD, 0xC0DB62, 0x95993C, 0x439041,
  0xFE5163, 0xABDEBB, 0xC561B7, 0x246E3A, 0x424DD2, 0xE00649, 0x2EEA09, 0xD1921C,
  0xFE1DEB, 0x1CB129, 0xA73EE8, 0x8235F5, 0x2EBB44, 0x84E99C, 0x7026B4, 0x5F7E41,
  0x3991D6, 0x398353, 0x39F49C, 0x845F8B, 0xBDF928, 0x3B1FF8, 0x97FFDE, 0x05980F,
  0xEF2F11, 0x8B5A0A, 0x6D1F6D, 0x367ECF, 0x27CB09, 0xB74F46, 0x3F669E, 0x5FEA2D,
  0x7527BA, 0xC7EBE5, 0xF17B3D, 0x0739F7, 0x8A5292, 0xEA6BFB, 0x5FB11F, 0x8D5D08,
  0x560330, 0x46FC7B, 0x6BABF0, 0xCFBC20, 0x9AF436, 0x1DA9E3, 0x91615E, 0xE61B08,
  0x659985, 0x5F14A0, 0x68408D, 0xFFD880, 0x4D7327, 0x310606, 0x1556CA, 0x73A8C9,
  0x60E27B, 0xC08C6B,
]

///|
let pi_over_2 : FixedArray[Double] = [
  1.57079625129699707031e+00, // 0x3FF921FB, 0x40000000 */
   7.54978941586159635335e-08, // 0x3E74442D, 0x00000000 */
   5.39030252995776476554e-15, // 0x3CF84698, 0x80000000 */
   3.28200341580791294123e-22, // 0x3B78CC51, 0x60000000 */
   1.27065575308067607349e-29, // 0x39F01B83, 0x80000000 */
   1.22933308981111328932e-36, // 0x387A2520, 0x40000000 */
   2.73370053816464559624e-44, // 0x36E38222, 0x80000000 */
   2.16741683877804819444e-51, // 0x3569F31D, 0x00000000 */
]

///|
fn set_low_word(d : Double, v : UInt) -> Double {
  let bits : UInt64 = d.reinterpret_as_uint64()
  let bits = bits & 0xFFFF_FFFF_0000_0000
  let bits = bits | v.to_uint64()
  bits.reinterpret_as_double()
}

///|
fn get_high_word(x : Double) -> UInt {
  (x.reinterpret_as_uint64() >> 32).to_uint()
}

///|
fn get_low_word(x : Double) -> UInt {
  x.reinterpret_as_uint64().to_uint()
}

///|
fn __kernel_rem_pio2(
  x : Array[Double],
  y : Array[Double],
  e0 : Int,
  nx : Int,
  prec : Int,
) -> Int {
  let init_jk = [2, 3, 4, 6]
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
  let t = [
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
