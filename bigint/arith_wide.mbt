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

// Word-level and vector-level arithmetic primitives.
//
// Every routine here operates on full 64-bit words (limbs) with base B = 2^64,
// so a "carry" is a whole word rather than the high half of a 32-bit product.
//
// The enabling primitive is `%u64.mul_wide`, which the native backend lowers to
// a single `unsigned __int128` multiply. Without it, a 64x64->128 product would
// cost four 32-bit multiplies plus the reassembly, which is exactly what the
// 32-bit-limb representation already pays.

///|
/// Result of a 64x64 -> 128 unsigned multiplication.
///
/// Must be `#valtype`: native writes the two halves into separate C locals,
/// while wasm1 can carry the pair as an unboxed value type. wasm-gc does not
/// compile this file because it cannot represent that result efficiently.
#valtype
priv struct UMul {
  lo : UInt64
  hi : UInt64
}

///|
/// `hi * 2^64 + lo == a * b`
///
/// The body is the portable 32x32 schoolbook fallback; on the native backend
/// `#intrinsic` replaces it with the backend's wide multiply when available.
/// Native uses `moonbit_umul_wide`; wasm1 currently executes this fallback.
#intrinsic("%u64.mul_wide")
fn umul_wide(a : UInt64, b : UInt64) -> UMul {
  let mask = 0xffffffffUL
  let alo = a & mask
  let ahi = a >> 32
  let blo = b & mask
  let bhi = b >> 32
  let ll = alo * blo
  let lh = alo * bhi
  let hl = ahi * blo
  let mid = (ll >> 32) + (lh & mask) + (hl & mask)
  let hi = ahi * bhi + (lh >> 32) + (hl >> 32) + (mid >> 32)
  { lo: a * b, hi, }
}

///|
/// A quotient/remainder pair from a 128-by-64 division.
#valtype
priv struct DivMod {
  q : UInt64
  r : UInt64
}

// Word primitives

///|
/// `hi * 2^64 + lo == x * y + c`. Cannot overflow: the maximum is
/// (2^64-1)^2 + (2^64-1) = 2^128 - 2^64.
fn mul_add_www(x : UInt64, y : UInt64, c : UInt64) -> UMul {
  let m = umul_wide(x, y)
  let lo = m.lo + c
  { lo, hi: m.hi + (lo < m.lo).to_uint64(), }
}

///|
/// Number of leading zero bits, as an `Int`.
fn nlz(x : UInt64) -> Int {
  x.clz()
}

///|
/// `q, r = (u1 * 2^64 + u0) / v`, requiring `u1 < v` and `v != 0`.
///
/// Hacker's Delight `divlu`: a 128/64 division synthesized from four 64/64
/// hardware divisions on 32-bit half-words. This is the slow path, used only to
/// build the reciprocal below (once per big division), never in an inner loop.
fn div_ww_slow(u1 : UInt64, u0 : UInt64, v : UInt64) -> DivMod {
  let b = 1UL << 32
  let s = nlz(v)
  let v = v << s
  let vn1 = v >> 32
  let vn0 = v & 0xffffffffUL
  // `u1 << 64 - s` is undefined for s == 0, so special-case it.
  let un32 = if s == 0 { u1 } else { (u1 << s) | (u0 >> (64 - s)) }
  let un10 = u0 << s
  let un1 = un10 >> 32
  let un0 = un10 & 0xffffffffUL
  let mut q1 = un32 / vn1
  let mut rhat = un32 - q1 * vn1
  while q1 >= b || q1 * vn0 > b * rhat + un1 {
    q1 -= 1
    rhat += vn1
    if rhat >= b {
      break
    }
  }
  let un21 = un32 * b + un1 - q1 * v
  let mut q0 = un21 / vn1
  rhat = un21 - q0 * vn1
  while q0 >= b || q0 * vn0 > b * rhat + un0 {
    q0 -= 1
    rhat += vn1
    if rhat >= b {
      break
    }
  }
  { q: (q1 << 32) | q0, r: (un21 * b + un0 - q0 * v) >> s, }
}

///|
/// `floor((2^128 - 1) / d) - 2^64` for a normalized `d` (top bit set).
///
/// This is the Möller-Granlund 2/1 reciprocal. Computed once per division, so
/// the slow software 128/64 path is fine here.
fn reciprocal_word(d : UInt64) -> UInt64 {
  div_ww_slow(d.lnot(), 0xffff_ffff_ffff_ffffUL, d).q
}

///|
/// `q, r = (u1 * 2^64 + u0) / d` using a precomputed reciprocal `v`.
///
/// Requires `d` normalized (top bit set) and `u1 < d`. Möller-Granlund
/// "Improved division by invariant integers", Algorithm 4. Two wide multiplies
/// and a couple of conditional fixups replace a hardware 128/64 divide.
fn div2by1(u1 : UInt64, u0 : UInt64, d : UInt64, v : UInt64) -> DivMod {
  let m = umul_wide(v, u1)
  // (q1, q0) = m + (u1, u0)
  let q0 = m.lo + u0
  let q1 = m.hi + u1 + (q0 < m.lo).to_uint64()
  let q1 = q1 + 1
  let mut r = u0 - q1 * d
  let mut q1 = q1
  if r > q0 {
    q1 -= 1
    r += d
  }
  if r >= d {
    q1 += 1
    r -= d
  }
  { q: q1, r, }
}

///|
/// True when `(x1, x2) > (y1, y2)` as 128-bit values.
fn greater_than(x1 : UInt64, x2 : UInt64, y1 : UInt64, y2 : UInt64) -> Bool {
  x1 > y1 || (x1 == y1 && x2 > y2)
}

// Vector primitives
//
// Each takes explicit offsets and a length so callers can operate on slices of
// a shared buffer without allocating views.

///|
/// `z[zi..zi+n] = x[xi..xi+n] + y[yi..yi+n]`, returns the carry out (0 or 1).
fn add_vv(
  z : FixedArray[UInt64],
  zi : Int,
  x : FixedArray[UInt64],
  xi : Int,
  y : FixedArray[UInt64],
  yi : Int,
  n : Int,
) -> UInt64 {
  for i in 0..<n; c = 0UL {
    let a = x.unsafe_get(xi + i)
    let s = a + y.unsafe_get(yi + i)
    let c1 = (s < a).to_uint64()
    let t = s + c
    z.unsafe_set(zi + i, t)
    continue c1 + (t < s).to_uint64()
  } nobreak {
    c
  }
}

///|
/// `z[zi..zi+n] = x[xi..xi+n] - y[yi..yi+n]`, returns the borrow out (0 or 1).
fn sub_vv(
  z : FixedArray[UInt64],
  zi : Int,
  x : FixedArray[UInt64],
  xi : Int,
  y : FixedArray[UInt64],
  yi : Int,
  n : Int,
) -> UInt64 {
  for i in 0..<n; c = 0UL {
    let a = x.unsafe_get(xi + i)
    let b = y.unsafe_get(yi + i)
    let d = a - b
    let c1 = (a < b).to_uint64()
    let t = d - c
    z.unsafe_set(zi + i, t)
    continue c1 + (d < c).to_uint64()
  } nobreak {
    c
  }
}

///|
/// `z[zi..zi+n] = x[xi..xi+n] + y`, returns the carry out.
fn add_vw(
  z : FixedArray[UInt64],
  zi : Int,
  x : FixedArray[UInt64],
  xi : Int,
  y : UInt64,
  n : Int,
) -> UInt64 {
  for i in 0..<n; c = y {
    if c == 0 {
      // Carry died; the rest is a straight copy.
      if !(physical_equal(z, x) && zi == xi) {
        for j in i..<n {
          z.unsafe_set(zi + j, x.unsafe_get(xi + j))
        }
      }
      return 0
    }
    let a = x.unsafe_get(xi + i)
    let s = a + c
    z.unsafe_set(zi + i, s)
    continue (s < a).to_uint64()
  } nobreak {
    c
  }
}

///|
/// `z[zi..zi+n] = x[xi..xi+n] - y`, returns the borrow out.
fn sub_vw(
  z : FixedArray[UInt64],
  zi : Int,
  x : FixedArray[UInt64],
  xi : Int,
  y : UInt64,
  n : Int,
) -> UInt64 {
  for i in 0..<n; c = y {
    if c == 0 {
      if !(physical_equal(z, x) && zi == xi) {
        for j in i..<n {
          z.unsafe_set(zi + j, x.unsafe_get(xi + j))
        }
      }
      return 0
    }
    let a = x.unsafe_get(xi + i)
    let d = a - c
    z.unsafe_set(zi + i, d)
    continue (a < c).to_uint64()
  } nobreak {
    c
  }
}

///|
/// `z[zi..zi+n] = x[xi..xi+n] * y + r`, returns the high carry word.
///
/// This is the n-by-1 multiply used by `mul_single_limb` and by the Knuth-D
/// "multiply and subtract" step.
fn mul_add_vww(
  z : FixedArray[UInt64],
  zi : Int,
  x : FixedArray[UInt64],
  xi : Int,
  y : UInt64,
  r : UInt64,
  n : Int,
) -> UInt64 {
  for i in 0..<n; c = r {
    let m = mul_add_www(x.unsafe_get(xi + i), y, c)
    z.unsafe_set(zi + i, m.lo)
    continue m.hi
  } nobreak {
    c
  }
}

///|
/// `z[zi..zi+n] += x[xi..xi+n] * m`, returns the carry out.
///
/// The schoolbook multiply inner loop. Each step computes
/// `x[i]*m + z[i] + carry`, which is at most
/// (2^64-1)^2 + 2*(2^64-1) = 2^128 - 1, so the running carry is a full word and
/// never overflows.
fn add_mul_vvw(
  z : FixedArray[UInt64],
  zi : Int,
  x : FixedArray[UInt64],
  xi : Int,
  m : UInt64,
  n : Int,
) -> UInt64 {
  for i in 0..<n; c = 0UL {
    let p = umul_wide(x.unsafe_get(i + xi), m)
    let zv = z.unsafe_get(zi + i)
    let t0 = p.lo + zv
    let cc0 = (t0 < p.lo).to_uint64()
    let t1 = t0 + c
    let cc1 = (t1 < t0).to_uint64()
    z.unsafe_set(zi + i, t1)
    continue p.hi + cc0 + cc1
  } nobreak {
    c
  }
}

// Multiplication over limb vectors
//
// The scratch layout uses explicit base offsets into one shared array.

///|
/// `z[zi .. zi+an+bn) = x[xi..xi+an) * y[yi..yi+bn)`.
///
/// `z` need not be zeroed. The first row writes rather than accumulates, and a
/// row skipped for a zero multiplier still stores its (zero) carry, so no read
/// ever sees a word this call has not written. Karatsuba relies on that: its
/// `z` is scratch space still holding earlier partial products.
fn basic_mul(
  z : FixedArray[UInt64],
  zi : Int,
  x : FixedArray[UInt64],
  xi : Int,
  an : Int,
  y : FixedArray[UInt64],
  yi : Int,
  bn : Int,
) -> Unit {
  z.unsafe_set(zi + an, mul_add_vww(z, zi, x, xi, y.unsafe_get(yi), 0, an))
  for j in 1..<bn {
    let m = y.unsafe_get(yi + j)
    if m != 0 {
      z.unsafe_set(zi + j + an, add_mul_vvw(z, zi + j, x, xi, m, an))
    } else {
      z.unsafe_set(zi + j + an, 0)
    }
  }
}

///|
/// The largest `k <= n` of the form `t << i` with `t <= threshold`. Splitting
/// at `k` makes every level of the recursion divide evenly, which is what lets
/// the scratch layout below be a fixed size.
fn karatsuba_len(n : Int, threshold : Int) -> Int {
  let mut n = n
  let mut i = 0
  while n > threshold {
    n = n >> 1
    i += 1
  }
  n << i
}

///|
/// `z[zi..zi+n) += x[xi..xi+n)`, with the carry absorbed by the following
/// `n/2` words.
fn karatsuba_add(
  z : FixedArray[UInt64],
  zi : Int,
  x : FixedArray[UInt64],
  xi : Int,
  n : Int,
) -> Unit {
  let c = add_vv(z, zi, z, zi, x, xi, n)
  if c != 0 {
    ignore(add_vw(z, zi + n, z, zi + n, c, n >> 1))
  }
}

///|
/// `z[zi..zi+n) -= x[xi..xi+n)`, with the borrow absorbed by the following
/// `n/2` words.
fn karatsuba_sub(
  z : FixedArray[UInt64],
  zi : Int,
  x : FixedArray[UInt64],
  xi : Int,
  n : Int,
) -> Unit {
  let c = sub_vv(z, zi, z, zi, x, xi, n)
  if c != 0 {
    ignore(sub_vw(z, zi + n, z, zi + n, c, n >> 1))
  }
}

///|
/// `z[zi..zi+2n) = x[xi..xi+n) * y[yi..yi+n)`.
///
/// `z` must have `6*n` words available from `zi`; the low `2n` receive the
/// product and the rest is scratch. Callers get `n` from `karatsuba_len`, which
/// guarantees the halving stays exact.
///
/// This identity needs one subtraction product rather than the textbook
/// `(xh+xl)*(yh+yl)`, so no intermediate can carry past `n` words:
///
///   xd = x1 - x0,  yd = y0 - y1
///   x*y = z2*B^2 + (xd*yd + z2 + z0)*B + z0    with z0 = x0*y0, z2 = x1*y1
fn karatsuba(
  z : FixedArray[UInt64],
  zi : Int,
  x : FixedArray[UInt64],
  xi : Int,
  y : FixedArray[UInt64],
  yi : Int,
  n : Int,
) -> Unit {
  if n % 2 != 0 || n < KARATSUBA_THRESHOLD || n < 2 {
    basic_mul(z, zi, x, xi, n, y, yi, n)
    return
  }
  let n2 = n >> 1
  // z = [ .. | .. | xd*yd | yd:xd | x1*y1 | x0*y0 ]  (0, n, 2n, 3n, 4n, 6n)
  karatsuba(z, zi, x, xi, y, yi, n2) // z0 = x0*y0
  karatsuba(z, zi + n, x, xi + n2, y, yi + n2, n2) // z2 = x1*y1

  // |x1-x0| and |y0-y1|, carrying the sign of their product in `s`.
  let mut s = 1
  let xd = zi + 2 * n
  if sub_vv(z, xd, x, xi + n2, x, xi, n2) != 0 {
    s = -s
    ignore(sub_vv(z, xd, x, xi, x, xi + n2, n2))
  }
  let yd = xd + n2
  if sub_vv(z, yd, y, yi, y, yi + n2, n2) != 0 {
    s = -s
    ignore(sub_vv(z, yd, y, yi + n2, y, yi, n2))
  }
  let p = zi + 3 * n
  karatsuba(z, p, z, xd, z, yd, n2)

  // Stash z2:z0 above p's result; the recursion is done, so z[4n..6n) is free.
  let r = zi + 4 * n
  z.unsafe_blit(r, z, zi, 2 * n)
  karatsuba_add(z, zi + n2, z, r, n) // + z0 << n2
  karatsuba_add(z, zi + n2, z, r + n, n) // + z2 << n2
  if s > 0 {
    karatsuba_add(z, zi + n2, z, p, n)
  } else {
    karatsuba_sub(z, zi + n2, z, p, n)
  }
}

///|
/// `z[i..zn) += x[0..xn)`.
fn add_at(
  z : FixedArray[UInt64],
  zn : Int,
  x : FixedArray[UInt64],
  xn : Int,
  i : Int,
) -> Unit {
  if xn == 0 {
    return
  }
  let c = add_vv(z, i, z, i, x, 0, xn)
  if c != 0 {
    let j = i + xn
    if j < zn {
      ignore(add_vw(z, j, z, j, c, zn - j))
    }
  }
}

///|
/// `q[0..n] = x[0..n] / d`, returns `x[0..n] % d`.
///
/// `s` must be `nlz(d)`, `dn` must be `d << s`, and `rec`
/// `reciprocal_word(dn)`; hoisting them out lets a caller amortize the
/// reciprocal across repeated divisions by the same `d` (decimal printing does
/// exactly this).
///
/// `q` may alias `x`: step `i` reads `x[i]` and `x[i-1]` before writing `q[i]`,
/// and later steps only look further down.
fn div_w(
  q : FixedArray[UInt64],
  x : FixedArray[UInt64],
  n : Int,
  dn : UInt64,
  rec : UInt64,
  s : Int,
) -> UInt64 {
  let mut r = 0UL
  if s == 0 {
    for i = n - 1; i >= 0; i = i - 1 {
      let dm = div2by1(r, x.unsafe_get(i), dn, rec)
      q.unsafe_set(i, dm.q)
      r = dm.r
    }
    return r
  }
  // Divide `x << s` by `d << s` without materializing the shifted dividend:
  // limb i of the shifted value is `(x[i] << s) | (x[i-1] >> (64-s))`, and the
  // bits shifted off the top become the initial remainder.
  let t = 64 - s
  r = x.unsafe_get(n - 1) >> t
  for i = n - 1; i >= 0; i = i - 1 {
    let cur = x.unsafe_get(i)
    let lower = if i > 0 { x.unsafe_get(i - 1) } else { 0UL }
    let dm = div2by1(r, (cur << s) | (lower >> t), dn, rec)
    q.unsafe_set(i, dm.q)
    r = dm.r
  }
  r >> s
}

// Montgomery arithmetic

///|
/// `-m^-1 mod 2^64`, the Montgomery constant. Requires `m` odd.
///
/// Newton-Raphson on the 2-adic inverse (Dumas, "On Newton-Raphson Iteration
/// for Multiplicative Inverses Modulo Prime Powers"): each round doubles the
/// number of correct low bits, so six rounds cover 64.
fn mont_k0(m0 : UInt64) -> UInt64 {
  let mut k0 = 2UL - m0
  let mut t = m0 - 1
  let mut i = 1
  while i < 64 {
    t = t * t
    k0 = k0 * (t + 1)
    i = i << 1
  }
  0UL - k0
}

///|
/// `out[0..n) = x * y * R^-1 mod m` where `R = 2^(64n)` and `k = -m^-1 mod 2^64`.
///
/// `x`, `y` and `m` are each exactly `n` limbs; `t` is `2n` words of scratch.
/// Interleaved multiply-and-reduce (CIOS) keeps the intermediate within `2n`
/// words and requires no division.
///
/// `out` must not alias `x`, `y` or `m`.
fn montgomery(
  out : FixedArray[UInt64],
  x : FixedArray[UInt64],
  y : FixedArray[UInt64],
  m : FixedArray[UInt64],
  k : UInt64,
  n : Int,
  t : FixedArray[UInt64],
) -> Unit {
  // Only the low half needs clearing; t[n..2n) is written as the loop advances.
  for i in 0..<n {
    t.unsafe_set(i, 0)
  }
  for i in 0..<n; c = 0UL {
    let c2 = add_mul_vvw(t, i, x, 0, y.unsafe_get(i), n)
    // Choose the multiple of m that zeroes limb i.
    let c3 = add_mul_vvw(t, i, m, 0, t.unsafe_get(i) * k, n)
    let cx = c + c2
    let cy = cx + c3
    t.unsafe_set(n + i, cy)
    continue if cx < c2 || cy < c3 { 1 } else { 0 }
  } nobreak {
    // The result is t[n..2n), one conditional subtraction away from reduced.
    if c != 0 {
      ignore(sub_vv(out, 0, t, n, m, 0, n))
    } else {
      out.unsafe_blit(0, t, n, n)
    }
  }
}

///|
/// `z[0..n] = x[0..n] << s` for `0 < s < 64`, returns the bits shifted out.
fn shl_vu(
  z : FixedArray[UInt64],
  x : FixedArray[UInt64],
  s : Int,
  n : Int,
) -> UInt64 {
  if n == 0 {
    return 0
  }
  let t = 64 - s
  let c = x.unsafe_get(n - 1) >> t
  for i = n - 1; i > 0; i = i - 1 {
    z.unsafe_set(i, (x.unsafe_get(i) << s) | (x.unsafe_get(i - 1) >> t))
  }
  z.unsafe_set(0, x.unsafe_get(0) << s)
  c
}

///|
/// `z[0..n] = x[0..n] >> s` for `0 < s < 64`, returns the bits shifted out
/// (in the high end of the word).
fn shr_vu(
  z : FixedArray[UInt64],
  x : FixedArray[UInt64],
  s : Int,
  n : Int,
) -> UInt64 {
  if n == 0 {
    return 0
  }
  let t = 64 - s
  let c = x.unsafe_get(0) << t
  for i in 0..<(n - 1) {
    z.unsafe_set(i, (x.unsafe_get(i) >> s) | (x.unsafe_get(i + 1) << t))
  }
  z.unsafe_set(n - 1, x.unsafe_get(n - 1) >> s)
  c
}
