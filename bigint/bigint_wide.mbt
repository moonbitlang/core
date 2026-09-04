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

// A sign-magnitude arbitrary-precision integer over 64-bit limbs.
//
// Native and wasm1 use `FixedArray[UInt64]` limbs with base 2^64. wasm-gc
// retains 32-bit limbs, and JavaScript keeps its host-BigInt implementation.
//
// Invariants:
// - len > 0
// - (exists 0 <= i < len. limbs[i] > 0) => limbs[len-1] > 0
// - (forall 0 <= i < len. limbs[i] == 0) => limbs[0] == 0 and len == 1
// - forall len <= i < limbs.length(). limbs[i] == 0

///|
#valtype
struct BigInt {
  limbs : FixedArray[UInt64]
  sign : Sign
  len : Int
}

///|
priv enum Sign {
  Positive
  Negative
} derive(Eq)

///|
/// Switch from schoolbook to Karatsuba at this many limbs.
const KARATSUBA_THRESHOLD = 64

///|
/// Number of bits represented by each wide limb.
const RADIX_BIT_LEN = 64

///|
let zero : BigInt = { limbs: FixedArray::make(1, 0UL), sign: Positive, len: 1, }

///|
let one : BigInt = { limbs: FixedArray::make(1, 1UL), sign: Positive, len: 1, }

// Construction

///|
fn make(len : Int) -> FixedArray[UInt64] {
  FixedArray::make(len, 0UL)
}

///|
/// Drop leading zero limbs; never returns less than 1.
fn normalize_len(limbs : FixedArray[UInt64], max_len : Int) -> Int {
  let mut i = max_len
  while i > 1 && limbs.unsafe_get(i - 1) == 0 {
    i -= 1
  }
  i
}

///|
/// Creates a non-negative `BigInt` from an unsigned 64-bit integer.
pub fn BigInt::from_uint64(n : UInt64) -> BigInt {
  { limbs: FixedArray::make(1, n), sign: Positive, len: 1, }
}

///|
/// Creates a non-negative `BigInt` from an unsigned 32-bit integer.
pub fn BigInt::from_uint(n : UInt) -> BigInt {
  BigInt::from_uint64(n.to_uint64())
}

///|
/// Creates a `BigInt` from a signed 64-bit integer.
pub fn BigInt::from_int64(n : Int64) -> BigInt {
  if n == 0 {
    return zero
  }
  if n < 0 {
    // Negating Int64::MIN overflows, so go through the unsigned domain.
    let mag = 0UL - n.reinterpret_as_uint64()
    { limbs: FixedArray::make(1, mag), sign: Negative, len: 1, }
  } else {
    {
      limbs: FixedArray::make(1, n.reinterpret_as_uint64()),
      sign: Positive,
      len: 1,
    }
  }
}

///|
/// Creates a `BigInt` from a signed 32-bit integer.
pub fn BigInt::from_int(n : Int) -> BigInt {
  BigInt::from_int64(n.to_int64())
}

///|
/// Returns whether this integer is zero.
pub fn BigInt::is_zero(self : BigInt) -> Bool {
  self.len == 1 && self.limbs.unsafe_get(0) == 0
}

///|
fn BigInt::with_sign(self : BigInt, sign : Sign) -> BigInt {
  if self.is_zero() {
    self
  } else {
    { ..self, sign, }
  }
}

///|
pub impl Neg for BigInt with fn neg(self : BigInt) -> BigInt {
  if self.is_zero() {
    return self
  }
  { ..self, sign: if self.sign == Positive { Negative } else { Positive }, }
}

// Magnitude comparison

///|
/// Compare |self| with |other|.
fn BigInt::cmp_mag(self : BigInt, other : BigInt) -> Int {
  if self.len != other.len {
    return if self.len < other.len { -1 } else { 1 }
  }
  for i = self.len - 1; i >= 0; i = i - 1 {
    let a = self.limbs.unsafe_get(i)
    let b = other.limbs.unsafe_get(i)
    if a != b {
      return if a < b { -1 } else { 1 }
    }
  }
  0
}

///|
pub impl Compare for BigInt with fn compare(self : BigInt, other : BigInt) -> Int {
  match (self.sign, other.sign) {
    (Positive, Negative) =>
      if self.is_zero() && other.is_zero() {
        0
      } else {
        1
      }
    (Negative, Positive) =>
      if self.is_zero() && other.is_zero() {
        0
      } else {
        -1
      }
    (Positive, Positive) => self.cmp_mag(other)
    (Negative, Negative) => -self.cmp_mag(other)
  }
}

///|
pub impl Eq for BigInt with fn equal(self : BigInt, other : BigInt) -> Bool {
  self.compare(other) == 0
}

// Magnitude add / sub
//
// These ignore signs entirely; the signed `Add`/`Sub` impls dispatch to them.

///|
/// |self| + |other|, always positive.
fn BigInt::add_mag(self : BigInt, other : BigInt) -> BigInt {
  // Ensure self is the longer operand.
  let (a, b) = if self.len >= other.len { (self, other) } else { (other, self) }
  let an = a.len
  let bn = b.len
  let limbs = make(an + 1)
  let c = add_vv(limbs, 0, a.limbs, 0, b.limbs, 0, bn)
  let c = add_vw(limbs, bn, a.limbs, bn, c, an - bn)
  limbs.unsafe_set(an, c)
  { limbs, sign: Positive, len: if c != 0 { an + 1 } else { an }, }
}

///|
/// |self| - |other|, requires |self| >= |other|. Always positive.
fn BigInt::sub_mag(self : BigInt, other : BigInt) -> BigInt {
  let an = self.len
  let bn = other.len
  let limbs = make(an)
  let c = sub_vv(limbs, 0, self.limbs, 0, other.limbs, 0, bn)
  ignore(sub_vw(limbs, bn, self.limbs, bn, c, an - bn))
  { limbs, sign: Positive, len: normalize_len(limbs, an), }
}

///|
pub impl Add for BigInt with fn add(self : BigInt, other : BigInt) -> BigInt {
  if self.sign == other.sign {
    self.add_mag(other).with_sign(self.sign)
  } else if self.cmp_mag(other) >= 0 {
    self.sub_mag(other).with_sign(self.sign)
  } else {
    other.sub_mag(self).with_sign(other.sign)
  }
}

///|
pub impl Sub for BigInt with fn sub(self : BigInt, other : BigInt) -> BigInt {
  if self.sign != other.sign {
    self.add_mag(other).with_sign(self.sign)
  } else if self.cmp_mag(other) >= 0 {
    self.sub_mag(other).with_sign(self.sign)
  } else {
    other
    .sub_mag(self)
    .with_sign(if self.sign == Positive { Negative } else { Positive })
  }
}

// Multiplication

///|
pub impl Mul for BigInt with fn mul(self : BigInt, other : BigInt) -> BigInt {
  if self.is_zero() || other.is_zero() {
    return zero
  }
  let sign = if self.sign == other.sign { Positive } else { Negative }
  // Dispatch on the shorter operand, with the longer operand first.
  let (a, b) = if self.len >= other.len { (self, other) } else { (other, self) }
  let ret = if b.len == 1 {
    a.mul_single_limb(b.limbs.unsafe_get(0))
  } else if b.len < KARATSUBA_THRESHOLD {
    a.grade_school_mul(b)
  } else {
    a.karatsuba_mul(b)
  }
  { ..ret, sign, }
}

///|
/// |self| * x for a single limb x. Requires x != 0 and self != 0.
fn BigInt::mul_single_limb(self : BigInt, x : UInt64) -> BigInt {
  let n = self.len
  let limbs = make(n + 1)
  let c = mul_add_vww(limbs, 0, self.limbs, 0, x, 0, n)
  limbs.unsafe_set(n, c)
  { limbs, sign: Positive, len: if c != 0 { n + 1 } else { n }, }
}

///|
/// Schoolbook O(n*m) multiply of the magnitudes.
fn BigInt::grade_school_mul(self : BigInt, other : BigInt) -> BigInt {
  let an = self.len
  let bn = other.len
  let limbs = make(an + bn)
  basic_mul(limbs, 0, self.limbs, 0, an, other.limbs, 0, bn)
  { limbs, sign: Positive, len: normalize_len(limbs, an + bn), }
}

///|
/// Karatsuba over one scratch buffer.
///
/// Requires `self.len >= other.len >= KARATSUBA_THRESHOLD`. Karatsuba itself
/// only handles the low `k` limbs of each operand (`k` from `karatsuba_len`, so
/// the recursion splits evenly); whatever sits above `k` is folded back in
/// afterwards as three ordinary products.
fn BigInt::karatsuba_mul(self : BigInt, other : BigInt) -> BigInt {
  let m = self.len
  let n = other.len
  let k = karatsuba_len(n, KARATSUBA_THRESHOLD)
  let scratch = make(6 * k)
  karatsuba(scratch, 0, self.limbs, 0, other.limbs, 0, k)
  let z = make(m + n)
  z.unsafe_blit(0, scratch, 0, 2 * k)
  if k < n || m != n {
    // With B = 2^(64k), x = xh*B + x0 and y = yh*B + y0. The scratch pass
    // produced x0*y0; add x0*yh*B, xh*y0*B and xh*yh*B^2.
    let x0 = slice_mag(self.limbs, 0, k)
    let xh = slice_mag(self.limbs, k, m - k)
    let y0 = slice_mag(other.limbs, 0, k)
    let yh = slice_mag(other.limbs, k, n - k)
    add_term(z, m + n, x0 * yh, k)
    add_term(z, m + n, xh * y0, k)
    add_term(z, m + n, xh * yh, 2 * k)
  }
  { limbs: z, sign: Positive, len: normalize_len(z, m + n), }
}

///|
/// `z[i..zn) += t`, skipping the no-op case so `add_at` never walks a zero.
fn add_term(z : FixedArray[UInt64], zn : Int, t : BigInt, i : Int) -> Unit {
  if !t.is_zero() {
    add_at(z, zn, t.limbs, t.len, i)
  }
}

///|
/// A normalized magnitude holding `x[off..off+n)`; `zero` when `n <= 0`.
fn slice_mag(x : FixedArray[UInt64], off : Int, n : Int) -> BigInt {
  if n <= 0 {
    return zero
  }
  let mut len = n
  while len > 1 && x.unsafe_get(off + len - 1) == 0 {
    len -= 1
  }
  let limbs = make(len)
  limbs.unsafe_blit(0, x, off, len)
  { limbs, sign: Positive, len, }
}

// Division

///|
pub impl Div for BigInt with fn div(self : BigInt, other : BigInt) -> BigInt {
  let (q, _) = self.div_mod(other)
  q
}

///|
pub impl Mod for BigInt with fn mod(self : BigInt, other : BigInt) -> BigInt {
  let (_, r) = self.div_mod(other)
  r
}

///|
/// Truncating division: the quotient rounds toward zero and the remainder takes
/// the sign of the dividend, matching core's `Div`/`Mod`.
fn BigInt::div_mod(self : BigInt, other : BigInt) -> (BigInt, BigInt) {
  if other.is_zero() {
    abort("division by zero")
  }
  let cmp = self.cmp_mag(other)
  if cmp < 0 {
    return (zero, self)
  }
  let q_sign = if self.sign == other.sign { Positive } else { Negative }
  if cmp == 0 {
    return (one.with_sign(q_sign), zero)
  }
  let a = { ..self, sign: Positive, }
  let b = { ..other, sign: Positive, }
  let (q, r) = a.div_mod_mag(b)
  (q.with_sign(q_sign), r.with_sign(self.sign))
}

///|
/// |self| divmod a single limb, using the Möller-Granlund 2/1 divider so the
/// inner loop is two wide multiplies rather than a hardware 128/64 divide.
fn BigInt::div_mod_single_limb(self : BigInt, d : UInt64) -> (BigInt, BigInt) {
  let n = self.len
  let q = make(n)
  if d == 1 {
    q.unsafe_blit(0, self.limbs, 0, n)
    return ({ limbs: q, sign: Positive, len: n, }, zero)
  }
  let s = nlz(d)
  let dn = d << s
  let r = div_w(q, self.limbs, n, dn, reciprocal_word(dn), s)
  (
    { limbs: q, sign: Positive, len: normalize_len(q, n), },
    { limbs: FixedArray::make(1, r), sign: Positive, len: 1, },
  )
}

///|
/// Knuth TAOCP 4.3.1 Algorithm D over 64-bit limbs.
///
/// Requires `|self| > |other|` and `other.len >= 2`.
fn BigInt::knuth_div(self : BigInt, other : BigInt) -> (BigInt, BigInt) {
  let n = other.len
  let m = self.len - n

  // D1. Normalize so the divisor's top limb has its high bit set.
  let s = nlz(other.limbs.unsafe_get(n - 1))
  let v = make(n)
  if s == 0 {
    v.unsafe_blit(0, other.limbs, 0, n)
  } else {
    ignore(shl_vu(v, other.limbs, s, n))
  }
  // u gets one extra limb to hold the shifted-out bits.
  let u = make(self.len + 1)
  if s == 0 {
    u.unsafe_blit(0, self.limbs, 0, self.len)
  } else {
    let carry = shl_vu(u, self.limbs, s, self.len)
    u.unsafe_set(self.len, carry)
  }
  let q = make(m + 1)
  let vn1 = v.unsafe_get(n - 1)
  let vn2 = v.unsafe_get(n - 2)
  let rec = reciprocal_word(vn1)
  let qhatv = make(n + 1)
  for j = m; j >= 0; j = j - 1 {
    // D3. Estimate q̂ from the top two limbs.
    let ujn = u.unsafe_get(j + n)
    let mut qhat = 0xffff_ffff_ffff_ffffUL
    if ujn != vn1 {
      let dm = div2by1(ujn, u.unsafe_get(j + n - 1), vn1, rec)
      qhat = dm.q
      let mut rhat = dm.r
      // Refine: while q̂ * v[n-2] > (r̂ << 64) + u[j+n-2], decrement q̂.
      let mut p = umul_wide(qhat, vn2)
      let ujn2 = u.unsafe_get(j + n - 2)
      while greater_than(p.hi, p.lo, rhat, ujn2) {
        qhat -= 1
        let prev = rhat
        rhat += vn1
        if rhat < prev {
          break
        }
        p = umul_wide(qhat, vn2)
      }
    }

    // D4. Multiply and subtract.
    let c = mul_add_vww(qhatv, 0, v, 0, qhat, 0, n)
    qhatv.unsafe_set(n, c)
    let borrow = sub_vv(u, j, u, j, qhatv, 0, n + 1)

    // D5/D6. Rare: q̂ was one too large, add the divisor back.
    if borrow != 0 {
      let carry = add_vv(u, j, u, j, v, 0, n)
      u.unsafe_set(j + n, u.unsafe_get(j + n) + carry)
      qhat -= 1
    }
    q.unsafe_set(j, qhat)
  }

  // D8. Unnormalize the remainder.
  let r = make(n)
  if s == 0 {
    r.unsafe_blit(0, u, 0, n)
  } else {
    ignore(shr_vu(r, u, s, n))
  }
  (
    { limbs: q, sign: Positive, len: normalize_len(q, m + 1), },
    { limbs: r, sign: Positive, len: normalize_len(r, n), },
  )
}

// Shifts

///|
pub impl Shl for BigInt with fn shl(self : BigInt, n : Int) -> BigInt {
  if n < 0 {
    abort("negative shift count")
  }
  if self.is_zero() || n == 0 {
    return self
  }
  let words = n / 64
  let bits = n % 64
  let len = self.len + words + 1
  let limbs = make(len)
  if bits == 0 {
    limbs.unsafe_blit(words, self.limbs, 0, self.len)
  } else {
    let shifted = make(self.len)
    let carry = shl_vu(shifted, self.limbs, bits, self.len)
    limbs.unsafe_blit(words, shifted, 0, self.len)
    limbs.unsafe_set(words + self.len, carry)
  }
  { limbs, sign: self.sign, len: normalize_len(limbs, len), }
}

///|
pub impl Shr for BigInt with fn shr(self : BigInt, n : Int) -> BigInt {
  if n < 0 {
    abort("negative shift count")
  }
  if self.is_zero() || n == 0 {
    return self
  }
  let words = n / 64
  let bits = n % 64
  if words >= self.len {
    // Arithmetic shift: negatives round toward -infinity, like core.
    return if self.sign == Positive { zero } else { -one }
  }
  let len = self.len - words
  let limbs = make(len)
  if bits == 0 {
    limbs.unsafe_blit(0, self.limbs, words, len)
  } else {
    let src = make(len)
    src.unsafe_blit(0, self.limbs, words, len)
    ignore(shr_vu(limbs, src, bits, len))
  }
  let res = { limbs, sign: self.sign, len: normalize_len(limbs, len), }
  if self.sign == Negative {
    // Check whether any bit was shifted out; if so round away from zero.
    let lost = for i in 0..<words {
      if self.limbs.unsafe_get(i) != 0 {
        break true
      }
    } nobreak {
      bits > 0 && (self.limbs.unsafe_get(words) & ((1UL << bits) - 1)) != 0
    }
    if lost {
      return res - one
    }
  }
  res
}

// Conversions

///|
/// Returns the number of bits in the minimal representation excluding its
/// sign bit.
pub fn BigInt::bit_length(self : BigInt) -> Int {
  if self.is_zero() {
    return 0
  }
  let mut bits = self.len * RADIX_BIT_LEN -
    nlz(self.limbs.unsafe_get(self.len - 1))
  if self.sign == Negative {
    // Core defines negative bit length from the minimal two's-complement
    // representation, so -2^k needs one fewer magnitude bit.
    let is_power_of_two = for i in 0..<self.len; one_bits = 0 {
      let one_bits = one_bits + self.limbs.unsafe_get(i).popcnt()
      if one_bits > 1 {
        break false
      }
      continue one_bits
    } nobreak {
      true
    }
    if is_power_of_two {
      bits -= 1
    }
  }
  bits
}

///|
/// Largest power of ten that fits in a limb: 10^19 < 2^64.
const DECIMAL_CHUNK : UInt64 = 10_000_000_000_000_000_000UL

///|
const DECIMAL_CHUNK_DIGITS = 19

///|
/// `DECIMAL_CHUNK` already has its top bit set, so it is normalized with a
/// shift of zero. Cache its expensive software reciprocal at module startup.
let decimal_chunk_reciprocal : UInt64 = reciprocal_word(DECIMAL_CHUNK)

///|
/// Decimal rendering uses recursively tabulated powers of ten for large values
/// and repeated division by 10^19 only at the leaves.
fn BigInt::to_string_dec(self : BigInt) -> String {
  format_decimal(self)
}

///|
/// `self ^ exp` by square-and-multiply.
pub fn BigInt::pow(self : BigInt, exp : BigInt, modulus? : BigInt) -> BigInt {
  if exp.sign == Negative {
    abort("negative exponent")
  }
  match modulus {
    None => {
      let bits = exp.bit_length()
      for i in 0..<bits; result = one, base = self {
        let result = if exp.test_bit(i) { result * base } else { result }
        let base = if i + 1 < bits { base * base } else { base }
        continue result, base
      } nobreak {
        result
      }
    }
    Some(m) => {
      if m.is_zero() || m.sign == Negative {
        abort("modulus must be positive")
      }
      if m.len == 1 && m.limbs.unsafe_get(0) == 1 {
        return zero
      }
      if exp.is_zero() {
        return one
      }
      // Reduce the base into [0, m), matching core's `(self % m + m) % m`.
      let r = self % m
      let base = if r.sign == Negative { r + m } else { r }
      if base.is_zero() {
        return zero
      }
      if (m.limbs.unsafe_get(0) & 1) == 1 {
        base.pow_mont(exp, m)
      } else {
        base.pow_mod_plain(exp, m)
      }
    }
  }
}

///|
/// Bit `i` of the magnitude.
fn BigInt::test_bit(self : BigInt, i : Int) -> Bool {
  let w = i / 64
  if w >= self.len {
    return false
  }
  ((self.limbs.unsafe_get(w) >> (i % 64)) & 1) == 1
}

///|
/// Square-and-multiply with an explicit reduction each step. Used when the
/// modulus is even, where Montgomery does not apply (it needs `m` invertible
/// mod 2^64).
fn BigInt::pow_mod_plain(self : BigInt, exp : BigInt, m : BigInt) -> BigInt {
  let bits = exp.bit_length()
  for i in 0..<bits; result = one, base = self {
    let result = if exp.test_bit(i) { result * base % m } else { result }
    let base = if i + 1 < bits { base * base % m } else { base }
    continue result, base
  } nobreak {
    result
  }
}

///|
/// Montgomery exponentiation with a 4-bit window.
///
/// Requires `0 < self < m`, `m` odd, `exp > 0`. The win over `pow_mod_plain` is
/// that every reduction becomes a Montgomery multiply — O(n^2) shift-and-add
/// instead of a full Knuth D division — and the window cuts the number of
/// multiplies by roughly a third.
fn BigInt::pow_mont(self : BigInt, exp : BigInt, m : BigInt) -> BigInt {
  let n = m.len
  let mlimbs = m.limbs
  let k0 = mont_k0(mlimbs.unsafe_get(0))
  let t = make(2 * n)

  // x, one, and RR = 2^(128n) mod m, each padded to exactly n limbs.
  let x = make(n)
  x.unsafe_blit(0, self.limbs, 0, self.len)
  let one_arr = make(n)
  one_arr.unsafe_set(0, 1)
  let rr_big = (one << (2 * 64 * n)) % m
  let rr = make(n)
  rr.unsafe_blit(0, rr_big.limbs, 0, rr_big.len)

  // powers[i] = Montgomery form of self^i, for the 4-bit window.
  let powers : Array[FixedArray[UInt64]] = []
  for _ in 0..<16 {
    powers.push(make(n))
  }
  montgomery(powers[0], one_arr, rr, mlimbs, k0, n, t)
  montgomery(powers[1], x, rr, mlimbs, k0, n, t)
  for i in 2..<16 {
    montgomery(powers[i], powers[i - 1], powers[1], mlimbs, k0, n, t)
  }
  let mut z = make(n)
  z.unsafe_blit(0, powers[0], 0, n)
  let mut zz = make(n)
  for i = exp.len - 1; i >= 0; i = i - 1 {
    let mut yi = exp.limbs.unsafe_get(i)
    let mut j = 0
    while j < 64 {
      // Four squarings per nibble, skipped only on the very first window.
      if i != exp.len - 1 || j != 0 {
        montgomery(zz, z, z, mlimbs, k0, n, t)
        montgomery(z, zz, zz, mlimbs, k0, n, t)
        montgomery(zz, z, z, mlimbs, k0, n, t)
        montgomery(z, zz, zz, mlimbs, k0, n, t)
      }
      montgomery(zz, z, powers[(yi >> 60).to_int()], mlimbs, k0, n, t)
      let swap = z
      z = zz
      zz = swap
      yi = yi << 4
      j += 4
    }
  }
  // Leave Montgomery form.
  montgomery(zz, z, one_arr, mlimbs, k0, n, t)
  let res = { limbs: zz, sign: Positive, len: normalize_len(zz, n), }
  // Montgomery's conditional subtraction leaves the result below 2m, not m.
  if res.cmp_mag(m) >= 0 {
    res.sub_mag(m)
  } else {
    res
  }
}

// Conversions and bitwise operations.

///|
fn minimum_int(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn maximum_int(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn digit_from_char(x : Int) -> Int {
  match x {
    '0'..='9' => x - '0'
    'A'..='Z' => x + (10 - 'A')
    'a'..='z' => x + (10 - 'a')
    _ => -1
  }
}

///|
fn char_from_digit(d : Int) -> Char {
  if d < 10 {
    (d + '0').unsafe_to_char()
  } else {
    (d - 10 + 'a').unsafe_to_char()
  }
}

///|
fn pow2_shift(radix : Int) -> Int? {
  if radix >= 2 && (radix & (radix - 1)) == 0 {
    Some(radix.ctz())
  } else {
    None
  }
}

///|
/// Converts this integer to a string in a radix between 2 and 36.
pub fn BigInt::to_string(self : BigInt, radix? : Int = 10) -> String {
  if radix < 2 || radix > 36 {
    abort("radix must be between 2 and 36")
  }
  if radix == 10 {
    self.to_string_dec()
  } else {
    self.to_string_radix(radix)
  }
}

///|
fn BigInt::to_string_radix(self : BigInt, radix : Int) -> String {
  if self.is_zero() {
    return "0"
  }
  match pow2_shift(radix) {
    Some(shift) => self.to_string_radix_pow2(shift)
    None => {
      let is_negative = self.sign == Negative
      let base = BigInt::from_int(radix)
      let mut value = if is_negative { -self } else { self }
      let digits = []
      while !value.is_zero() {
        let (q, r) = value.div_mod(base)
        digits.push(char_from_digit(r.to_int()))
        value = q
      }
      let builder = StringBuilder(
        size_hint=digits.length() + (if is_negative { 1 } else { 0 }),
      )
      if is_negative {
        builder.write_char('-')
      }
      for i in digits.length()>..0 {
        builder.write_char(digits[i])
      }
      builder.to_string()
    }
  }
}

///|
fn BigInt::to_string_radix_pow2(self : BigInt, shift : Int) -> String {
  let is_negative = self.sign == Negative
  let value = if is_negative { -self } else { self }
  let bit_len = value.bit_length()
  let digit_len = (bit_len + shift - 1) / shift
  let builder = StringBuilder(
    size_hint=digit_len + (if is_negative { 1 } else { 0 }),
  )
  if is_negative {
    builder.write_char('-')
  }
  let mask = (1UL << shift) - 1
  for pos in digit_len>..0 {
    let bit_index = pos * shift
    let limb_index = bit_index / RADIX_BIT_LEN
    let offset = bit_index % RADIX_BIT_LEN
    let mut chunk = value.limbs.unsafe_get(limb_index) >> offset
    if offset + shift > RADIX_BIT_LEN && limb_index + 1 < value.len {
      chunk = chunk |
        (value.limbs.unsafe_get(limb_index + 1) << (RADIX_BIT_LEN - offset))
    }
    builder.write_char(char_from_digit((chunk & mask).to_int()))
  }
  builder.to_string()
}

///|
fn BigInt::from_string_radix(input : StringView, radix : Int) -> BigInt raise {
  match pow2_shift(radix) {
    Some(shift) => BigInt::from_string_radix_pow2(input, radix, shift)
    None => {
      let len = input.length()
      if len == 0 {
        syntax_err()
      }
      let sign = if input.unsafe_get(0) == '-' { Negative } else { Positive }
      let start = if sign == Negative { 1 } else { 0 }
      if start == len {
        syntax_err()
      }
      let base = BigInt::from_int(radix)
      let acc = for i in start..<len; acc = zero {
        let digit = digit_from_char(input.unsafe_get(i).to_int())
        if digit < 0 || digit >= radix {
          syntax_err()
        }
        continue acc * base + BigInt::from_int(digit)
      } nobreak {
        acc
      }
      acc.with_sign(sign)
    }
  }
}

///|
fn BigInt::from_string_radix_pow2(
  input : StringView,
  radix : Int,
  shift : Int,
) -> BigInt raise {
  let len = input.length()
  if len == 0 {
    syntax_err()
  }
  let sign = if input.unsafe_get(0) == '-' { Negative } else { Positive }
  let start = if sign == Negative { 1 } else { 0 }
  if start == len {
    syntax_err()
  }
  let mut first = start
  while first < len {
    let digit = digit_from_char(input.unsafe_get(first).to_int())
    if digit < 0 || digit >= radix {
      syntax_err()
    }
    if digit != 0 {
      break
    }
    first += 1
  }
  if first == len {
    return zero
  }
  let total_bits = (len - first) * shift
  let limbs_len = (total_bits + RADIX_BIT_LEN - 1) / RADIX_BIT_LEN
  let limbs = FixedArray::make(limbs_len, 0UL)
  for i in len>..first; bit_pos = 0 {
    let digit = digit_from_char(input.unsafe_get(i).to_int())
    if digit < 0 || digit >= radix {
      syntax_err()
    }
    let limb_index = bit_pos / RADIX_BIT_LEN
    let offset = bit_pos % RADIX_BIT_LEN
    let value = digit.to_uint64()
    limbs.unsafe_set(
      limb_index,
      limbs.unsafe_get(limb_index) | (value << offset),
    )
    if offset + shift > RADIX_BIT_LEN {
      let hi = value >> (RADIX_BIT_LEN - offset)
      limbs.unsafe_set(limb_index + 1, limbs.unsafe_get(limb_index + 1) | hi)
    }
    continue bit_pos + shift
  }
  { limbs, sign, len: normalize_len(limbs, limbs_len), }
}

///|
fn BigInt::from_string_dec(input : StringView) -> BigInt raise {
  let len = input.length()
  if len == 0 {
    syntax_err()
  }
  let sign = if input.unsafe_get(0) == '-' { Negative } else { Positive }
  let mut i = if sign == Negative { 1 } else { 0 }
  if i == len {
    syntax_err()
  }
  let mut acc = zero
  while i < len {
    let take = minimum_int(DECIMAL_CHUNK_DIGITS, len - i)
    let (chunk, scale) = for offset in 0..<take; chunk = 0UL, scale = 1UL {
      let digit = digit_from_char(input.unsafe_get(i + offset).to_int())
      if digit < 0 || digit > 9 {
        syntax_err()
      }
      continue chunk * 10 + digit.to_uint64(), scale * 10
    } nobreak {
      (chunk, scale)
    }
    i += take
    acc = acc * BigInt::from_uint64(scale) + BigInt::from_uint64(chunk)
  }
  acc.with_sign(sign)
}

///|
/// Parses a string into a `BigInt` using a base between 2 and 36.
#internal(internal, "use `@string.parse_bigint` instead")
#doc(hidden)
pub fn parse_bigint(str : StringView, base? : Int = 10) -> BigInt raise {
  if base < 2 || base > 36 {
    base_err()
  }
  if base == 10 {
    BigInt::from_string_dec(str)
  } else {
    BigInt::from_string_radix(str, base)
  }
}

///|
/// Converts a string representation in the specified radix to a `BigInt`.
///
/// Panics if the input is malformed. Use `@string.parse_bigint` to handle
/// errors.
pub fn BigInt::from_string(input : String, radix? : Int = 10) -> BigInt {
  parse_bigint(input.view(), base=radix) catch {
    Failure(msg) => abort(msg)
    _ => abort("invalid syntax")
  }
}

///|
/// Creates a magnitude from unsigned big-endian bytes.
pub fn BigInt::from_octets(input : BytesView, signum? : Int = 1) -> BigInt {
  if signum == 0 || input.length() == 0 {
    return zero
  }
  if signum < 0 {
    return -BigInt::from_octets(input)
  }
  let byte_len = input.length()
  let full_limbs = byte_len / 8
  let head_len = byte_len % 8
  let limbs_len = if head_len == 0 { full_limbs } else { full_limbs + 1 }
  let limbs = FixedArray::make(limbs_len, 0UL)
  // Assemble the partial most-significant limb.
  for i in 0..<head_len {
    limbs.unsafe_set(
      limbs_len - 1,
      (limbs.unsafe_get(limbs_len - 1) << 8) | input.unsafe_get(i).to_uint64(),
    )
  }
  // Each remaining limb is one full-width big-endian word.
  for i in 0..<full_limbs {
    guard! input[byte_len - 8 - i * 8:] is [u64be(word), ..]
    limbs.unsafe_set(i, word)
  }
  { limbs, sign: Positive, len: normalize_len(limbs, limbs_len), }
}

///|
/// Converts a non-negative integer to unsigned big-endian bytes.
pub fn BigInt::to_octets(self : BigInt, length? : Int) -> Bytes {
  let minimum_length = match length {
    None => 1
    Some(value) => if value <= 0 { abort("negative length") } else { value }
  }
  if self.is_zero() {
    return Bytes::new(maximum_int(1, minimum_length))
  }
  if self.sign == Negative {
    abort("negative BigInt")
  }
  let value_length = (self.bit_length() + 7) / 8
  let result_length = maximum_int(minimum_length, value_length)
  let result = FixedArray::make(result_length, b'\x00')
  for i in 0..<value_length {
    let word = self.limbs.unsafe_get(i / 8)
    result.unsafe_set(
      result_length - 1 - i,
      ((word >> (i % 8 * 8)) & 0xffUL).to_int().to_byte(),
    )
  }
  unsafe_fixedarray_to_bytes(result)
}

///|
fn fill_twos_complement(value : BigInt, out : FixedArray[UInt64]) -> Unit {
  out.unsafe_blit(0, value.limbs, 0, value.len)
  if value.sign == Negative {
    for i in 0..<out.length() {
      out.unsafe_set(i, out.unsafe_get(i).lnot())
    }
    for i in 0..<out.length() {
      let word = out.unsafe_get(i) + 1
      out.unsafe_set(i, word)
      if word != 0 {
        break
      }
    }
  }
}

///|
fn BigInt::bitwise(
  self : BigInt,
  other : BigInt,
  op : (UInt64, UInt64) -> UInt64,
) -> BigInt {
  let limbs_len = maximum_int(self.len, other.len) + 1
  let x = FixedArray::make(limbs_len, 0UL)
  let y = FixedArray::make(limbs_len, 0UL)
  fill_twos_complement(self, x)
  fill_twos_complement(other, y)
  for i in 0..<limbs_len {
    x.unsafe_set(i, op(x.unsafe_get(i), y.unsafe_get(i)))
  }
  let negative = x.unsafe_get(limbs_len - 1) == 0xffff_ffff_ffff_ffffUL
  if negative {
    for i in 0..<limbs_len {
      let word = x.unsafe_get(i) - 1
      x.unsafe_set(i, word)
      if word != 0xffff_ffff_ffff_ffffUL {
        break
      }
    }
    for i in 0..<limbs_len {
      x.unsafe_set(i, x.unsafe_get(i).lnot())
    }
  }
  let len = normalize_len(x, limbs_len)
  {
    limbs: x,
    sign: if negative && !(len == 1 && x.unsafe_get(0) == 0) {
      Negative
    } else {
      Positive
    },
    len,
  }
}

///|
pub impl BitAnd for BigInt with fn land(self : BigInt, other : BigInt) -> BigInt {
  self.bitwise(other, (a, b) => a & b)
}

///|
pub impl BitOr for BigInt with fn lor(self : BigInt, other : BigInt) -> BigInt {
  self.bitwise(other, (a, b) => a | b)
}

///|
pub impl BitXOr for BigInt with fn lxor(self : BigInt, other : BigInt) -> BigInt {
  self.bitwise(other, (a, b) => a ^ b)
}

///|
/// Returns the low 32 bits reinterpreted as a signed integer.
pub fn BigInt::to_int(self : BigInt) -> Int {
  self.to_uint().reinterpret_as_int()
}

///|
/// Returns the low 32 bits as an unsigned integer.
pub fn BigInt::to_uint(self : BigInt) -> UInt {
  let low = self.limbs.unsafe_get(0).to_uint()
  if self.sign == Negative {
    0U - low
  } else {
    low
  }
}

///|
/// Returns the low 64 bits reinterpreted as a signed integer.
pub fn BigInt::to_int64(self : BigInt) -> Int64 {
  self.to_uint64().reinterpret_as_int64()
}

///|
/// Returns the low 64 bits as an unsigned integer.
pub fn BigInt::to_uint64(self : BigInt) -> UInt64 {
  let low = self.limbs.unsafe_get(0)
  if self.sign == Negative {
    0UL - low
  } else {
    low
  }
}

///|
/// Returns the number of trailing zero bits in the magnitude.
pub fn BigInt::ctz(self : BigInt) -> Int {
  if self.is_zero() {
    return 0
  }
  let mut i = 0
  while self.limbs.unsafe_get(i) == 0 {
    i += 1
  }
  RADIX_BIT_LEN * i + self.limbs.unsafe_get(i).ctz()
}

///|
fn unsafe_fixedarray_to_bytes(arr : FixedArray[Byte]) -> Bytes = "%identity"

///|
fn can_convert_to_int(x : BigInt) -> Bool {
  x.len == 1 &&
  (if x.sign == Negative {
    x.limbs.unsafe_get(0) <= 0x8000_0000UL
  } else {
    x.limbs.unsafe_get(0) < 0x8000_0000UL
  })
}

///|
fn can_convert_to_int64(x : BigInt) -> Bool {
  x.len == 1 &&
  (if x.sign == Negative {
    x.limbs.unsafe_get(0) <= 0x8000_0000_0000_0000UL
  } else {
    x.limbs.unsafe_get(0) < 0x8000_0000_0000_0000UL
  })
}

///|
fn is_neg(x : BigInt) -> Bool {
  x.sign == Negative
}

///|
/// Returns the magnitude as 32-bit words so hashing remains representation
/// independent and agrees with the JavaScript backend.
fn BigInt::limbs(self : Self) -> Array[UInt] {
  let result = []
  for i in 0..<self.len {
    let word = self.limbs.unsafe_get(i)
    result.push(word.to_uint())
    let high = (word >> 32).to_uint()
    if i + 1 < self.len || high != 0 {
      result.push(high)
    }
  }
  result
}
