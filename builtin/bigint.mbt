// Copyright 2024 International Digital Economy Academy
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

/// A big integer represented as an array of Int.
// 
// Design explained: 
// - Why use an FixedArray of Int with a len field instead of a Array[Int]? 
//   - It follows the principle of least dependency in MoonBit's core.
//   - In our case, we always do one-off array allocation for each BigInt.
// - Why keep a separate len field instead of using limbs.length()?
//   - Since we always do only once array allocation for each BigInt, we
//     often need to estimate the number of limbs needed before allocating.
//     Using len allows us to accommodate leading zeros.
//
// Invariants:
// - len > 0
// - forall i in 0..len-1, 0 <= limbs[i] < radix
// - limbs[len-1] > 0
// - forall i in len..limbs.length(), limbs[i] == 0
struct BigInt {
  limbs : FixedArray[UInt] // Note: do not use limbs.length(), use len instead because of leading zeros
  sign : Sign // true for positive, false for negative
  len : Int
}

priv enum Sign {
  Positive
  Negative
} derive(Show, Eq)

// Hyper Params

/// Invariants:
/// - ((radix - 1) ^ 2) must fit in an Int64
/// - radix can only be a power of 2
/// - radix_bit_len <= 32
let radix_bit_len = 32

/// The base of the number system.
let radix : UInt64 = 1UL.lsl(radix_bit_len) // TODO: This can be generalized once we have const generics

/// The mask to extract the lower `radix_bit_len` bits.
let radix_mask : UInt64 = radix - 1

/// The ratio of the number of decimal digits to the number of radix digits.
let decimal_ratio = 0.302 // log10(2)

/// When to switch to Karatsuba multiplication
let karatsuba_threshold = 50

// Useful bigints

let zero : BigInt = 0N

let one : BigInt = 1N

// Conversion Functions

/// Convert an Int to a BigInt.
pub fn BigInt::from_int(n : Int) -> BigInt {
  BigInt::from_int64(n.to_int64())
}

/// Convert an Int64 to a BigInt.
pub fn BigInt::from_int64(n : Int64) -> BigInt {
  if n == 0L {
    return { limbs: FixedArray::make(1, 0), sign: Positive, len: 1 }
  }
  let limbs = FixedArray::make(64 / radix_bit_len, 0U)
  let mut m = (if n < 0L { -n } else { n }).to_uint64()
  let mut i = 0
  while m > 0 {
    limbs[i] = (m % radix).to_uint()
    m /= radix
    i += 1
  }
  { limbs, sign: if n < 0L { Negative } else { Positive }, len: i }
}

// Arithmetic Operations

/// Negate a bigint
pub fn op_neg(self : BigInt) -> BigInt {
  if self.is_zero() {
    return zero
  }
  { ..self, sign: if self.sign == Positive { Negative } else { Positive } }
}

/// Add two bigint.
pub fn op_add(self : BigInt, other : BigInt) -> BigInt {
  if self.sign == Negative {
    if other.sign == Negative {
      return -(-other + -self)
    } else {
      return other - -self
    }
  } else if other.sign == Negative {
    return self - -other
  }
  let self_len = self.len
  let other_len = other.len
  let limbs = FixedArray::make(1 + max(self_len, other_len), 0U)
  let mut carry = 0UL
  let mut i = 0
  while i < self_len || i < other_len || carry != 0 {
    let a = if i < self_len { self.limbs[i].to_uint64() } else { 0 }
    let b = if i < other_len { other.limbs[i].to_uint64() } else { 0 }
    let sum = a + b + carry
    limbs[i] = (sum % radix).to_uint()
    carry = sum / radix
    i += 1
  }
  { limbs, sign: Positive, len: i }
}

/// Subtract two bigint
pub fn op_sub(self : BigInt, other : BigInt) -> BigInt {
  // first make sure self and other > 0
  if self.sign == Negative {
    if other.sign == Negative {
      return -other - -self
    } else {
      return -(other + -self)
    }
  } else if other.sign == Negative {
    return self + -other
  }
  // then make sure self >= other
  if self < other {
    return -(other - self)
  }
  let self_len = self.len
  let other_len = other.len
  let limbs = FixedArray::make(max(self_len, other_len), 0U)
  let mut borrow = 0L
  let mut i = 0
  while i < self_len || i < other_len || borrow != 0L {
    let a = if i < self_len { self.limbs[i].to_uint64().to_int64() } else { 0 }
    let b = if i < other_len {
      other.limbs[i].to_uint64().to_int64()
    } else {
      0
    }
    let diff = a - b - borrow // 0 <= a < radix, 0 <= b < radix, 0 <= borrow <= 1 => -radix <= diff < radix
    if diff < 0L {
      limbs[i] = (diff + radix.to_int64()).to_uint64().to_uint() // -radix <= diff < 0, so we don't need to mod by radix
      borrow = 1L
    } else {
      limbs[i] = diff.to_uint64().to_uint() // 0 <= diff < radix, so we don't need to mod by radix
      borrow = 0L
    }
    i += 1
  }
  // Ensure the result has at least one limb with a value of zero if the result is zero
  while i > 1 && limbs[i - 1] == 0 {
    i -= 1
  }
  { limbs, sign: Positive, len: i }
}

/// Multiply two bigint 
pub fn op_mul(self : BigInt, other : BigInt) -> BigInt {
  if self.is_zero() || other.is_zero() {
    return zero
  }
  let ret = if self.len < karatsuba_threshold || other.len < karatsuba_threshold {
    grade_school_mul(self, other)
  } else {
    karatsuba_mul(self, other)
  }
  { ..ret, sign: if self.sign == other.sign { Positive } else { Negative } }
}

// Simplest way to multiply two BigInts.
fn grade_school_mul(self : BigInt, other : BigInt) -> BigInt {
  let self_len = self.len
  let other_len = other.len
  let mut len = self_len + other_len
  let limbs = FixedArray::make(len, 0U)
  for i = 0; i < self_len; i = i + 1 {
    let mut carry = 0UL
    for j = 0; j < other_len || carry != 0; j = j + 1 {
      let product = limbs[i + j].to_uint64() +
        self.limbs[i].to_uint64() *
        if j < other_len { other.limbs[j].to_uint64() } else { 0 } +
        carry
      limbs[i + j] = (product % radix).to_uint()
      carry = product / radix
    }
  }
  if limbs[self_len + other_len - 1] == 0 {
    len -= 1
  }
  { limbs, sign: Positive, len }
}

// Karatsuba multiplication
fn karatsuba_mul(self : BigInt, other : BigInt) -> BigInt {
  let half = (max(self.len, other.len) + 1) / 2
  let (xl, xh) = self.split(half)
  let (yl, yh) = other.split(half)
  let p1 = xh * yh
  let p2 = xl * yl
  let p3 = (xh + xl) * (yh + yl)
  p1.shl(radix_bit_len * 2 * half) +
  (p3 - p1 - p2).shl(radix_bit_len * half) +
  p2
}

// Get the lower half of the number.
fn split(self : BigInt, half : Int) -> (BigInt, BigInt) {
  if self.len <= half {
    return ({ ..self, sign: Positive }, zero)
  }
  let lower = FixedArray::make(half, 0U)
  lower.unsafe_blit(0, self.limbs, 0, half)
  let upper = FixedArray::make(self.len - half, 0U)
  upper.unsafe_blit(0, self.limbs, half, self.len - half)
  (
    { limbs: lower, sign: Positive, len: half },
    { limbs: upper, sign: Positive, len: self.len - half },
  )
}

/// Divide two bigint
pub fn op_div(self : BigInt, other : BigInt) -> BigInt {
  // TODO: 
  // guard (other != zero, "division by zero")  
  if other == zero {
    abort("division by zero")
  }
  // Handle negative numbers
  if self.sign == Negative {
    if other.sign == Negative {
      grade_school_div(-self, -other).0
    } else {
      -grade_school_div(-self, other).0
    }
  } else if other.sign == Negative {
    -grade_school_div(self, -other).0
  } else {
    return grade_school_div(self, other).0
  }
}

/// Modulo two bigint
pub fn op_mod(self : BigInt, other : BigInt) -> BigInt {
  if other == zero {
    abort("division by zero")
  }
  // Handle negative numbers
  if self.sign == Negative {
    if other.sign == Negative {
      -grade_school_div(-self, -other).1
    } else {
      -grade_school_div(-self, other).1
    }
  } else if other.sign == Negative {
    grade_school_div(self, -other).1
  } else {
    grade_school_div(self, other).1
  }
}

// Simplest way to divide two BigInts.
// Assumption: other != zero.
fn grade_school_div(self : BigInt, other : BigInt) -> (BigInt, BigInt) {
  // Handle edge cases
  if self < other {
    return (zero, self)
  } else if self == other {
    return (one, zero)
  }
  if other.len == 1 {
    let number = other.limbs[0]
    let ret = self.deep_clone()
    if number == 1 {
      return (ret, zero)
    }
    let a = ret.limbs
    let x = number.to_uint64()
    let mut y = 0UL
    for i = self.len - 1; i >= 0; i = i - 1 {
      y = y.lsl(radix_bit_len)
      y += a[i].to_uint64()
      a[i] = (y / x).land(radix_mask).to_uint()
      y %= x
    }
    if ret.limbs[ret.len - 1] == 0 {
      return (
        { ..ret, len: ret.len - 1 },
        { limbs: FixedArray::make(1, y.to_uint()), sign: Positive, len: 1 },
      )
    }
    return (
      ret,
      { limbs: FixedArray::make(1, y.to_uint()), sign: Positive, len: 1 },
    )
  }

  // Cite: TAOCP Vol. 2, 4.3.1
  let dividend = self
  let divisor = other

  // D1. normalize
  // m = divident.limbs.length() - divisor.limbs.length()
  // left shift divident & divisor such that 
  // - divisor.limbs.last() >= radix / 2
  // - divident.limbs.length() = self.limbs.length() + 1
  let lshift = max(
    0,
    radix_bit_len -
    (64 - divisor.limbs[divisor.len - 1].to_uint64().to_int64().clz()),
  )
  let a_len = dividend.len
  let dividend = dividend.shl(lshift)
  let divisor = divisor.shl(lshift)
  let b_len = divisor.len
  let b = FixedArray::make(b_len, 0UL)
  for i = 0; i < b_len; i = i + 1 {
    b[i] = divisor.limbs[i].to_uint64()
  }
  let a = FixedArray::make(a_len + 1, 0UL)
  for i = 0; i < a_len; i = i + 1 {
    a[i] = dividend.limbs[i].to_uint64()
  } else {
    if dividend.limbs.length() > i {
      a[i] = dividend.limbs[i].to_uint64()
    }
  }
  // invariant : divisor.limbs.last() >= radix / 2
  // if b[b_len - 1] < radix / 2 {
  //   panic()
  // }
  let a_len = a_len + 1
  // a is the adjusted dividend and b is the adjusted divisor
  let v1 = b[b_len - 1]
  let v2 = b[b_len - 2]
  let q = FixedArray::make(a_len - b_len, 0U)
  // D2 - D7 loop through m to 0
  for i = q.length() - 1; i >= 0; i = i - 1 {
    let u0 = a[i + b_len]
    let u1 = a[i + b_len - 1]
    let u2 = a[i + b_len - 2]
    // D3 compute qh
    let mut qh = (u0 * radix + u1) / v1
    if qh * v2 > radix * (u0 * radix + u1 - qh * v1) + u2 {
      qh -= 1
    }
    // D4 divident = divident - qh * divisor
    let mut borrow = 0L
    let mut carry = 0UL
    for j = 0; j < b_len; j = j + 1 {
      carry += qh * b[j]
      borrow += a[i + j].to_int64()
      borrow -= carry.land(radix_mask).to_int64()
      a[i + j] = borrow.land(radix_mask.to_int64()).to_uint64()
      borrow = borrow.asr(radix_bit_len)
      carry = carry.lsr(radix_bit_len)
    }
    borrow = borrow + a[i + b_len].to_int64()
    borrow -= carry.to_int64()
    a[i + b_len] = borrow.land(radix_mask.to_int64()).to_uint64()
    borrow = borrow.asr(radix_bit_len)
    if borrow < 0L {
      carry = 0UL
      for j = 0; j < b_len; j = j + 1 {
        carry += a[i + j]
        carry += b[j]
        a[i + j] = carry.land(radix_mask)
        carry = carry.shr(radix_bit_len)
      }
      carry += a[i + b_len]
      a[i + b_len] = carry.land(radix_mask)
      carry = carry.shr(radix_bit_len)
      borrow += carry.to_int64()
      qh -= 1
    }
    q[i] = qh.to_uint()
  }
  let len = if q[q.length() - 1] == 0 { q.length() - 1 } else { q.length() }

  // strip leading zeros
  let mut i = a.length() - 1
  while i >= 0 && a[i] == 0 {
    i -= 1
  }
  if i < 0 {
    i = 1
  } else {
    i += 1
  }
  let modulo = FixedArray::make(i, 0U)
  for j = 0; j < i; j = j + 1 {
    modulo[j] = a[j].to_uint()
  }
  let modulo = { limbs: modulo, sign: Positive, len: i }
  ({ limbs: q, sign: Positive, len }, modulo.shr(lshift))
}

// Bitwise Operations

/// Left shift a bigint
/// /// @alert deprecate "Use shl instead"
pub fn lsl(self : BigInt, n : Int) -> BigInt {
  if n < 0 {
    abort("negative shift count")
  }
  if not(self.is_zero()) {
    let new_limbs = FixedArray::make(
      self.len + (n + radix_bit_len - 1) / radix_bit_len, // ceiling(n / radix_bit_len)
      0U,
    )
    let a = self.limbs
    let r = n % radix_bit_len
    let lz = n / radix_bit_len // number of leading zeros
    let mut len = self.len + lz
    if r != 0 {
      let mut carry = 0UL
      for i = 0; i < self.len; i = i + 1 {
        carry = carry.lor(a[i].to_uint64().lsl(r))
        new_limbs[i + lz] = (carry % radix).to_uint()
        carry = carry.lsr(radix_bit_len)
      }
      if carry != 0 {
        new_limbs[self.len + lz] = carry.to_uint()
        len += 1
      }
    } else {
      for i = 0; i < self.len; i = i + 1 {
        new_limbs[i + lz] = a[i]
      }
    }
    { limbs: new_limbs, sign: self.sign, len }
  } else {
    zero
  }
}

/// Left shift a bigint
/// The sign of the result is the same as the sign of the input.
/// Only the absolute value is shifted.
pub fn op_shl(self : BigInt, n : Int) -> BigInt {
  self.shl(n)
}

/// Left shift a bigint
/// The sign of the result is the same as the sign of the input.
/// Only the absolute value is shifted.
pub fn shl(self : BigInt, n : Int) -> BigInt {
  if n < 0 {
    abort("negative shift count")
  }
  if not(self.is_zero()) {
    let new_limbs = FixedArray::make(
      self.len + (n + radix_bit_len - 1) / radix_bit_len, // ceiling(n / radix_bit_len)
      0U,
    )
    let a = self.limbs
    let r = n % radix_bit_len
    let lz = n / radix_bit_len // number of leading zeros
    let mut len = self.len + lz
    if r != 0 {
      let mut carry = 0UL
      for i = 0; i < self.len; i = i + 1 {
        carry = carry.lor(a[i].to_uint64().lsl(r))
        new_limbs[i + lz] = (carry % radix).to_uint()
        carry = carry.lsr(radix_bit_len)
      }
      if carry != 0 {
        new_limbs[self.len + lz] = carry.to_uint()
        len += 1
      }
    } else {
      new_limbs.unsafe_blit(lz, self.limbs, 0, self.len)
    }
    { limbs: new_limbs, sign: self.sign, len }
  } else {
    zero
  }
}

/// Right shift a bigint
/// The sign of the result is the same as the sign of the input.
/// Only the absolute value is shifted.
pub fn op_shr(self : BigInt, n : Int) -> BigInt {
  self.shr(n)
}

/// Right shift a bigint
/// The sign of the result is the same as the sign of the input.
/// Only the absolute value is shifted.
pub fn shr(self : BigInt, n : Int) -> BigInt {
  if n < 0 {
    abort("negative shift count")
  }
  let r = n % radix_bit_len
  let lz = n / radix_bit_len
  if lz >= self.len {
    match self.sign {
      Positive => return zero
      Negative =>
        return { limbs: FixedArray::make(1, 1), sign: Negative, len: 1 }
    }
  }
  let mut new_len = self.len - lz
  if r == 0 {
    let new_limbs = FixedArray::make(new_len, 0U)
    new_limbs.unsafe_blit(0, self.limbs, lz, new_len)
    { limbs: new_limbs, sign: self.sign, len: new_len }
  } else {
    let new_limbs = FixedArray::make(new_len, 0U)
    let a = self.limbs
    let mut carry = 0UL
    for i = self.len - 1; i >= lz; i = i - 1 {
      let x = a[i].to_uint64()
      new_limbs[i - lz] = x.lsr(r).lor(carry).to_uint()
      carry = x.lsl(radix_bit_len - r) % radix
    }
    if new_len > 1 && new_limbs[new_len - 1] == 0 {
      new_len -= 1
    }
    if self.sign == Negative && (carry & 1UL.lsl(r)) != carry {
      { limbs: new_limbs, sign: self.sign, len: new_len } - 1
    } else {
      { limbs: new_limbs, sign: self.sign, len: new_len }
    }
  }
}

pub fn asr(self : BigInt, n : Int) -> BigInt {
  self >> n
}

// Comparison Operations

/// Check if a bigint is zero
pub fn is_zero(self : BigInt) -> Bool {
  self.len == 1 && self.limbs[0] == 0
}

/// Implements the compare trait for BigInt
pub fn compare(self : BigInt, other : BigInt) -> Int {
  if self.sign != other.sign {
    return if self.sign == Positive { 1 } else { -1 }
  }
  let self_len = self.len
  let other_len = other.len
  if self_len != other_len {
    return if self.sign == Positive {
      self_len - other_len
    } else {
      other_len - self_len
    }
  }
  for i = self_len - 1; i >= 0; i = i - 1 {
    if self.limbs[i] != other.limbs[i] {
      return if self.sign == Positive {
        self.limbs[i].compare(other.limbs[i])
      } else {
        other.limbs[i].compare(self.limbs[i])
      }
    }
  }
  0
}

/// Implements the Eq trait for BigInt
pub fn op_equal(self : BigInt, other : BigInt) -> Bool {
  if self.sign != other.sign || self.len != other.len {
    return false
  }
  for i = 0; i < self.len; i = i + 1 {
    if self.limbs[i] != other.limbs[i] {
      return false
    }
  }
  true
}

/// Returns the decimal string representation of the BigInt.
pub fn to_string(self : BigInt) -> String {
  // This function first converts the BigInt to a decimal representation, with a radix of 2^(`decimal_radix_bit_len`).
  // Then it converts the decimal representation to a string slot by slot.
  if self.is_zero() {
    return "0"
  }
  let decimal_radix_bit_len = 19 - 1 - (1 + radix_bit_len) / 3 // < len(9,223,372,036,854,775,807) - len(2^radix_bit_len). len means the number of digits in decimal.
  let decimal_mask = 10_000_000L // 10^(decimal_radix_bit_len). TODO: compute it when we have power function.
  // The following value should fit well into an Int without precision loss.
  // This is an approximation of the number of slots needed to represent the decimal value.
  let decimal_len = ((self.len * radix_bit_len).to_double() *
    decimal_ratio /
    decimal_radix_bit_len.to_double()).to_int() +
    1
  let s = if self.sign == Negative { "-" } else { "" }
  let v = Array::make(decimal_len, 0L)
  let mut v_idx = 0
  for i = self.len - 1; i >= 0; i = i - 1 {
    let mut x = self.limbs[i].to_uint64().to_int64()
    for j = 0; j < v_idx; j = j + 1 {
      let y = v[j].lsl(radix_bit_len).lor(x)
      x = y / decimal_mask
      v[j] = y % decimal_mask
    }
    while x > 0L {
      v[v_idx] = x % decimal_mask
      v_idx += 1
      x /= decimal_mask
    }
  }
  let mut ret = ""
  for i = 0; i < v_idx - 1; i = i + 1 {
    for j = 0; j < decimal_radix_bit_len; j = j + 1 {
      let x = v[i] % 10L
      v[i] /= 10L
      ret = x.to_string() + ret
    }
  }
  let mut x = v[v_idx - 1] // v_idx is at least 1, we check is_zero() at the beginning.
  while x > 0L {
    let y = x % 10L
    x /= 10L
    ret = y.to_string() + ret
  }
  s + ret
}

pub impl Show for BigInt with output(self, logger) {
  logger.write_string(self.to_string())
}

/// Converts decimal string to a BigInt.
pub fn BigInt::from_string(input : String) -> BigInt {
  let len = input.length()
  if len == 0 {
    abort("empty string")
  }
  let sign : Sign = if input[0] == '-' { Negative } else { Positive }
  let mut b_len = (
      (len.to_double() / decimal_ratio).to_int() + 1 + radix_bit_len
    ) /
    radix_bit_len +
    1
  let b = FixedArray::make(b_len, 0U)
  for i = match sign {
          Negative => 1
          Positive => 0
        }
      i < input.length()
      i = i + 1 {
    let x = input[i].to_int() - 48 // ASCII value of '0'
    if x < 0 || x > 9 {
      abort("invalid character")
    }
    let mut carry = x.reinterpret_as_uint().to_uint64()
    for j = 0; j < b_len; j = j + 1 {
      carry += b[j].to_uint64() * 10
      b[j] = (carry % radix).to_uint()
      carry /= radix
    }
  }
  while b[b_len - 1] == 0 && b_len > 1 {
    b_len -= 1
  }
  { limbs: b, sign, len: b_len }
}

/// Converts a hex string to a BigInt.
pub fn BigInt::from_hex(input : String) -> BigInt {
  // WARN: this implementation assumes that `radix` is a power of 2.
  let len = input.length()
  if len == 0 {
    abort("empty string")
  }
  let sign : Sign = if input[0] == '-' { Negative } else { Positive }
  let mut b_len = (len * 4 + 1 + radix_bit_len) / radix_bit_len + 1 // TODO: 4 is hardcoded.
  let b = FixedArray::make(b_len, 0U)
  for i = match sign {
          Negative => 1
          Positive => 0
        }
      i < input.length()
      i = i + 1 {
    let x = input[i].to_int().to_int64()
    let y = if x >= 48 && x <= 57 {
      // ASCII value of '0'
      x - 48
    } else if x >= 65 && x <= 70 {
      // ASCII value of 'A'
      x - 55
    } else if x >= 97 && x <= 102 {
      // ASCII value of 'a'
      x - 87
    } else {
      abort("invalid character")
    }
    let mut carry = y.to_uint64()
    for j = 0; j < b_len; j = j + 1 {
      carry += b[j].to_uint64() * 16
      b[j] = (carry % radix).to_uint()
      carry /= radix
    }
  }
  while b[b_len - 1] == 0 && b_len > 1 {
    b_len -= 1
  }
  { limbs: b, sign, len: b_len }
}

/// Converts a BigInt to a hex string.
pub fn to_hex(self : BigInt) -> String {
  // WARN: this implementation assumes that `radix_bit_len` is a multiple of 4.
  let mut result = ""
  for i = self.len - 1; i >= 0; i = i - 1 { // TODO: reverse iteration would be a bit faster.
    // split the limb into 4-bit chunks
    let mut x = self.limbs[i]
    let mut tmp = ""
    while x > 0 {
      let y = x % 16
      x /= 16
      tmp = if y < 10 {
          Char::from_int(y.reinterpret_as_int() + 48).to_string()
        } else {
          Char::from_int(y.reinterpret_as_int() + 55).to_string()
        } +
        tmp
    }
    if i != self.len - 1 && tmp.length() < radix_bit_len / 4 {
      let pad = radix_bit_len / 4 - tmp.length()
      // pad with zeros if not the last limb(the front of the BigInt)
      for j = 0; j < pad; j = j + 1 {
        tmp = "0" + tmp
      }
    }
    result = result + tmp
  }
  if result == "" {
    "0"
  } else if self.sign == Negative {
    "-" + result
  } else {
    result
  }
}

fn deep_clone(self : BigInt) -> BigInt {
  let new_limbs = FixedArray::make(self.len, 0U)
  new_limbs.unsafe_blit(0, self.limbs, 0, self.len)
  { limbs: new_limbs, sign: self.sign, len: self.len }
}

fn max[T : Compare](a : T, b : T) -> T {
  if a > b {
    a
  } else {
    b
  }
}
