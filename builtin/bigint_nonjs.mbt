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
// - forall 0 <= i < len. 0 <= limbs[i] < radix
// - (exists 0 <= i < len. limbs[i] > 0) => limbs[len-1] > 0
// - (forall 0 <= i < len. limbs[i] == 0) => limbs[0] == 0 and len == 1
// - forall len <= i < limbs.length(). limbs[i] == 0
struct BigInt {
  limbs : FixedArray[UInt] // Note: do not use limbs.length(), use len instead because of leading zeros
  sign : Sign // true for positive, false for negative
  len : Int
}

///|
priv enum Sign {
  Positive
  Negative
} derive(Show, Eq)

// Hyper Params

///|
/// Invariants:
/// - ((radix - 1) ^ 2) must fit in an Int64
/// - radix can only be a power of 2
/// - radix_bit_len is multiple of 4
/// - radix_bit_len <= 32
let radix_bit_len = 32

///|
/// The base of the number system.
let radix : UInt64 = 1UL << radix_bit_len // TODO: This can be generalized once we have const generics

///|
/// The mask to extract the lower `radix_bit_len` bits.
let radix_mask : UInt64 = radix - 1

///|
/// The ratio of the number of decimal digits to the number of radix digits.
let decimal_ratio = 0.302 // log10(2)

///|
/// When to switch to Karatsuba multiplication
let karatsuba_threshold = 50

// Useful bigints

///|
let zero : BigInt = 0N

///|
let one : BigInt = 1N

// Conversion Functions

///|
/// Convert an Int to a BigInt.
pub fn BigInt::from_int(n : Int) -> BigInt {
  BigInt::from_int64(n.to_int64())
}

///|
/// Convert an UInt to a BigInt.
pub fn BigInt::from_uint(n : UInt) -> BigInt {
  BigInt::from_uint64(n.to_uint64())
}

///|
/// Convert an Int64 to a BigInt.
pub fn BigInt::from_int64(n : Int64) -> BigInt {
  if n < 0L {
    -BigInt::from_uint64((-n).reinterpret_as_uint64())
  } else {
    BigInt::from_uint64(n.reinterpret_as_uint64())
  }
}

///| 
/// Convert an UInt64 to a BigInt.
pub fn BigInt::from_uint64(n : UInt64) -> BigInt {
  if n == 0UL {
    return { limbs: FixedArray::make(1, 0), sign: Positive, len: 1 }
  }
  let limbs = FixedArray::make(64 / radix_bit_len, 0U)
  let mut m = n
  let mut i = 0
  while m > 0 {
    limbs[i] = (m % radix).to_uint()
    m /= radix
    i += 1
  }
  { limbs, sign: Positive, len: i }
}

// Arithmetic Operations

///|
/// Negate a bigint
pub fn BigInt::op_neg(self : BigInt) -> BigInt {
  if self.is_zero() {
    return zero
  }
  { ..self, sign: if self.sign == Positive { Negative } else { Positive } }
}

///|
/// Add two bigint.
pub fn BigInt::op_add(self : BigInt, other : BigInt) -> BigInt {
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

///|
/// Subtract two bigint
pub fn BigInt::op_sub(self : BigInt, other : BigInt) -> BigInt {
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
    let a = if i < self_len {
      self.limbs[i].to_uint64().reinterpret_as_int64()
    } else {
      0
    }
    let b = if i < other_len {
      other.limbs[i].to_uint64().reinterpret_as_int64()
    } else {
      0
    }
    let diff = a - b - borrow // 0 <= a < radix, 0 <= b < radix, 0 <= borrow <= 1 => -radix <= diff < radix
    if diff < 0L {
      limbs[i] = (diff + radix.reinterpret_as_int64())
        .reinterpret_as_uint64()
        .to_uint() // -radix <= diff < 0, so we don't need to mod by radix
      borrow = 1L
    } else {
      limbs[i] = diff.reinterpret_as_uint64().to_uint() // 0 <= diff < radix, so we don't need to mod by radix
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

///|
/// Multiply two bigint 
pub fn BigInt::op_mul(self : BigInt, other : BigInt) -> BigInt {
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

///|
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
        (if j < other_len { other.limbs[j].to_uint64() } else { 0 }) +
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

///|
// Karatsuba multiplication
fn karatsuba_mul(self : BigInt, other : BigInt) -> BigInt {
  let half = (max(self.len, other.len) + 1) / 2
  let (xl, xh) = self.split(half)
  let (yl, yh) = other.split(half)
  let p1 = xh * yh
  let p2 = xl * yl
  let p3 = (xh + xl) * (yh + yl)
  (p1 << (radix_bit_len * 2 * half)) +
  ((p3 - p1 - p2) << (radix_bit_len * half)) +
  p2
}

///|
// Get the lower half of the number.
fn BigInt::split(self : BigInt, half : Int) -> (BigInt, BigInt) {
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

///|
/// Divide two bigint
pub fn BigInt::op_div(self : BigInt, other : BigInt) -> BigInt {
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

///|
/// Modulo two bigint
pub fn BigInt::op_mod(self : BigInt, other : BigInt) -> BigInt {
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

///|
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
      y = y << radix_bit_len
      y += a[i].to_uint64()
      a[i] = ((y / x) & radix_mask).to_uint()
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
  // m = dividend.len - divisor.len
  // left shift dividend & divisor such that 
  // - b[b.length() - 1] >= radix / 2
  // - a.length() == self.len + 1 
  // where a and b represent the limbs of the adjusted dividend and divisor
  let lshift = max(
    0,
    radix_bit_len -
    (
      64 -
      divisor.limbs[divisor.len - 1].to_uint64().reinterpret_as_int64().clz()
    ),
  )
  let a_len = dividend.len
  let dividend = dividend << lshift
  let divisor = divisor << lshift
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
      borrow += a[i + j].reinterpret_as_int64()
      borrow -= (carry & radix_mask).reinterpret_as_int64()
      a[i + j] = (borrow & radix_mask.reinterpret_as_int64()).reinterpret_as_uint64()
      borrow = borrow >> radix_bit_len
      carry = carry >> radix_bit_len
    }
    borrow = borrow + a[i + b_len].reinterpret_as_int64()
    borrow -= carry.reinterpret_as_int64()
    a[i + b_len] = (borrow & radix_mask.reinterpret_as_int64()).reinterpret_as_uint64()
    borrow = borrow >> radix_bit_len
    if borrow < 0L {
      carry = 0UL
      for j = 0; j < b_len; j = j + 1 {
        carry += a[i + j]
        carry += b[j]
        a[i + j] = carry & radix_mask
        carry = carry >> radix_bit_len
      }
      carry += a[i + b_len]
      a[i + b_len] = carry & radix_mask
      carry = carry >> radix_bit_len
      borrow += carry.reinterpret_as_int64()
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
  ({ limbs: q, sign: Positive, len }, modulo >> lshift)
}

// Bitwise Operations

///|
/// Left shift a bigint
/// The sign of the result is the same as the sign of the input.
/// Only the absolute value is shifted.
/// 
pub fn BigInt::op_shl(self : BigInt, n : Int) -> BigInt {
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
        carry = carry | (a[i].to_uint64() << r)
        new_limbs[i + lz] = (carry % radix).to_uint()
        carry = carry >> radix_bit_len
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

///|
/// Right shift a bigint
/// The sign of the result is the same as the sign of the input.
/// Only the absolute value is shifted.
pub fn BigInt::op_shr(self : BigInt, n : Int) -> BigInt {
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
      new_limbs[i - lz] = ((x >> r) | carry).to_uint()
      carry = (x << (radix_bit_len - r)) % radix
    }
    if new_len > 1 && new_limbs[new_len - 1] == 0 {
      new_len -= 1
    }
    if self.sign == Negative && (carry & (1UL << r)) != carry {
      { limbs: new_limbs, sign: self.sign, len: new_len } - 1
    } else {
      { limbs: new_limbs, sign: self.sign, len: new_len }
    }
  }
}

// Comparison Operations

///|
/// Check if a bigint is zero
pub fn BigInt::is_zero(self : BigInt) -> Bool {
  self.len == 1 && self.limbs[0] == 0
}

///|
/// Implements the compare trait for BigInt
pub fn BigInt::compare(self : BigInt, other : BigInt) -> Int {
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

///|
/// Implements the Eq trait for BigInt
pub fn BigInt::op_equal(self : BigInt, other : BigInt) -> Bool {
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

///|
/// Returns the decimal string representation of the BigInt.
pub fn BigInt::to_string(self : BigInt) -> String {
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
    decimal_radix_bit_len.to_double()).to_unchecked_int() +
    1
  let s = if self.sign == Negative { "-" } else { "" }
  let v = Array::make(decimal_len, 0L)
  let mut v_idx = 0
  for i = self.len - 1; i >= 0; i = i - 1 {
    let mut x = self.limbs[i].to_uint64().reinterpret_as_int64()
    for j = 0; j < v_idx; j = j + 1 {
      let y = (v[j] << radix_bit_len) | x
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

///|
pub impl Show for BigInt with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
/// Converts decimal string to a BigInt.
pub fn BigInt::from_string(input : String) -> BigInt {
  let len = input.length()
  if len == 0 {
    abort("empty string")
  }
  let sign : Sign = if input[0] == '-' { Negative } else { Positive }
  let mut b_len = (
      (len.to_double() / decimal_ratio).to_unchecked_int() + 1 + radix_bit_len
    ) /
    radix_bit_len +
    1
  let b = FixedArray::make(b_len, 0U)
  for i = (match sign {
          Negative => 1
          Positive => 0
        })
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

///|
/// Converts a hex string to a BigInt.
/// 
/// The input string must be a valid hex string with no extra `0x` prefix.
pub fn BigInt::from_hex(input : String) -> BigInt {
  // WARN: this implementation assumes that `radix_bit_len` is a multiple of 4.
  fn char_from_hex(c : Char) -> UInt {
    let x = c.to_int()
    if x >= 48 && x <= 57 {
      // ASCII value of '0'
      (x - 48).reinterpret_as_uint()
    } else if x >= 65 && x <= 70 {
      // ASCII value of 'A'
      (x - 55).reinterpret_as_uint()
    } else if x >= 97 && x <= 102 {
      // ASCII value of 'a'
      (x - 87).reinterpret_as_uint()
    } else {
      abort("invalid character")
    }
  }

  let len = input.length()
  if len == 0 {
    abort("empty string")
  }
  let (sign, number_len) = if input[0] == '-' {
    (Negative, len - 1)
  } else {
    (Positive, len)
  }
  let nb_char = radix_bit_len / 4 // number of char per limb
  let quotient = number_len / nb_char
  let mod = number_len % nb_char
  let b_len = if mod == 0 { quotient } else { quotient + 1 }
  let b = FixedArray::make(b_len, 0U)
  if mod != 0 {
    let start = len - quotient * nb_char - mod
    for i = 0; i < mod; i = i + 1 {
      b[b_len - 1] = (b[b_len - 1] << 4) | char_from_hex(input[start + i])
    }
  }
  for i = 0; i < quotient; i = i + 1 {
    let start = len - (i + 1) * nb_char
    for j = 0; j < nb_char; j = j + 1 {
      b[i] = (b[i] << 4) | char_from_hex(input[start + j])
    }
  }
  { limbs: b, sign, len: b_len }
}

///|
/// Converts a BigInt to a hex string.
pub fn BigInt::to_hex(self : BigInt, uppercase~ : Bool = true) -> String {
  // WARN: this implementation assumes that `radix_bit_len` is a multiple of 4.
  let mut result = ""
  for i = self.len - 1; i >= 0; i = i - 1 { // TODO: reverse iteration would be a bit faster.
    // split the limb into 4-bit chunks
    let mut x = self.limbs[i]
    let mut tmp = ""
    while x > 0 {
      let y = x % 16
      x /= 16
      tmp = (if y < 10 {
          Char::from_int(y.reinterpret_as_int() + 48).to_string()
        } else if uppercase {
          Char::from_int(y.reinterpret_as_int() + 55).to_string()
        } else {
          Char::from_int(y.reinterpret_as_int() + 87).to_string()
        }) +
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

///|
fn BigInt::deep_clone(self : BigInt) -> BigInt {
  let new_limbs = FixedArray::make(self.len, 0U)
  new_limbs.unsafe_blit(0, self.limbs, 0, self.len)
  { limbs: new_limbs, sign: self.sign, len: self.len }
}

///|
fn max[T : Compare](a : T, b : T) -> T {
  if a > b {
    a
  } else {
    b
  }
}

///|
/// Computes the result of raising a `BigInt` to the power of another `BigInt`,
/// with an optional modulus.
///
/// When a modulus is provided, computes the modular exponentiation using the
/// square-and-multiply algorithm. This is particularly useful in cryptographic
/// applications where direct exponentiation would result in numbers too large to
/// handle efficiently.
///
/// Parameters:
///
/// * `self` : The base number to be raised to a power.
/// * `exp` : The exponent (must be non-negative).
/// * `modulus` : Optional modulus for modular exponentiation (must be positive
/// if provided).
///
/// Returns the result of the exponentiation, or the result modulo `modulus` if a
/// modulus is provided.
///
/// Throws:
///
/// * Aborts if the exponent is negative.
/// * Aborts if the provided modulus is zero or negative.
///
/// Example:
///
/// ```moonbit
/// test "BigInt::pow" {
///   let base = BigInt::from_string("3")
///   let exp = BigInt::from_string("4")
///   inspect!(base.pow(exp), content="81")
///   inspect!(base.pow(exp, modulus=BigInt::from_string("10")), content="1")
/// }
/// 
/// test "panic BigInt::pow/negative_exponent" {
///   let base = BigInt::from_string("3")
///   let exp = BigInt::from_string("-1")
///   ignore(base.pow(exp))
/// }
/// ```
pub fn BigInt::pow(self : BigInt, exp : BigInt, modulus? : BigInt) -> BigInt {
  if exp.sign == Negative {
    abort("negative exponent")
  }
  match modulus {
    None => {
      let mut result = 1N
      let mut base = self
      let mut exp = exp
      while exp > 0 {
        if exp % 2 == 1 {
          result = result * base
        }
        base = base * base
        exp = exp / 2
      }
      result
    }
    Some(modulus) => {
      guard not(modulus.is_zero() || modulus.sign == Negative)
      let mut result = 1N
      let mut base = self
      let mut exp = exp
      while exp > 0 {
        if exp % 2 == 1 {
          result = result * base % modulus
        }
        base = base * base % modulus
        exp = exp / 2
      }
      result
    }
  }
}

///|
/// Convert an octet string to a BigInt.
/// 
/// The input is treated as a big-endian octet array.
/// 
/// Example: `from_octets(b"\xab\xcd\xef") == from_hex("abcdef")`
/// 
/// The input must not be empty, unless signum is zero
pub fn BigInt::from_octets(input : Bytes, signum~ : Int = 1) -> BigInt {
  let len = input.length() // number of bytes
  if signum == 0 {
    return zero
  } else if signum < 0 {
    return -BigInt::from_octets(input)
  }
  if len == 0 {
    abort("empty octet string")
  }
  let div = len * 8 / radix_bit_len
  let mod = len * 8 % radix_bit_len // number of bits in the first limb
  let limbs_len = if mod == 0 { div } else { div + 1 }
  let limbs = FixedArray::make(limbs_len, 0U)
  // head at most significant limb
  for i = 0; i < mod / 8; i = i + 1 {
    limbs[limbs_len - 1] = (limbs[limbs_len - 1] << 8) |
      input[i].to_int().reinterpret_as_uint()
  }
  let byte_per_limb = radix_bit_len / 8
  // tail
  for i = 0; i < div; i = i + 1 {
    for j = 0; j < byte_per_limb; j = j + 1 {
      let bytes_idx = len - byte_per_limb - i * byte_per_limb + j
      limbs[i] = (limbs[i] << 8) |
        input[bytes_idx].to_int().reinterpret_as_uint()
    }
  }
  if limbs[limbs_len - 1] == 0 {
    { limbs, sign: Positive, len: max(1, limbs_len - 1) }
  } else {
    { limbs, sign: Positive, len: limbs_len }
  }
}

///|
/// Convert a BigInt to an octet string.
/// 
/// The output is a big-endian octet array.
/// 
/// The output may be padded with leading zeros to meet the length requirement 
/// if and only if the actual length is less than the expected.
/// 
/// The value should be non-negative and the padding should be positive.
/// 
/// Example: 
/// - `to_octets(from_hex("abcdef"), length=3) == b"\xab\xcd\xef"`
/// - `to_octets(from_hex("1abcdef"), length=3) == b"\x01\xab\xcd\xef"`
pub fn BigInt::to_octets(self : BigInt, length? : Int) -> Bytes {
  let length = match length {
    None => 1
    Some(l) => if l <= 0 { abort("negative length") } else { l }
  }
  if self.is_zero() {
    return Bytes::new(max(1, length))
  }
  if self.sign == Negative {
    abort("negative BigInt")
  }
  let head_bits = 32 - self.limbs[self.len - 1].reinterpret_as_int().clz()
  let tail_len = self.len - 1
  let len = (head_bits + 7) / 8 + tail_len * (radix_bit_len / 8)
  let len = max(length, len)
  let result = FixedArray::make(len, Byte::default())
  for i = 0; i < len && i / 4 < self.len; i = i + 1 {
    result[len - 1 - i] = ((self.limbs[i / 4] >> (i % 4 * 8)) & 0xffU)
      .reinterpret_as_int()
      .to_byte()
  }
  result.unsafe_to_bytes()
}

///|
pub fn BigInt::land(self : BigInt, other : BigInt) -> BigInt {
  let max_length = if self.limbs.length() < other.limbs.length() {
    other.limbs.length() + 1
  } else {
    self.limbs.length() + 1
  }
  // Extend the limbs to store the sign bits
  let x_limbs = FixedArray::make(max_length, 0U)..unsafe_blit(
    0,
    self.limbs,
    0,
    self.limbs.length(),
  )
  let y_limbs = FixedArray::make(max_length, 0U)..unsafe_blit(
    0,
    other.limbs,
    0,
    other.limbs.length(),
  )

  // Calculate the complement code per 2
  if self.sign == Negative {
    for i = 0; i < x_limbs.length(); i = i + 1 {
      x_limbs[i] = x_limbs[i] ^ 0xFFFFFFFFU
    }
    for i = 0; i < x_limbs.length(); i = i + 1 {
      x_limbs[i] += 1
      if x_limbs[i] != 0x0U {
        break
      }
    }
  }
  if other.sign == Negative {
    for i = 0; i < y_limbs.length(); i = i + 1 {
      y_limbs[i] = y_limbs[i] ^ 0xFFFFFFFFU
    }
    for i = 0; i < y_limbs.length(); i = i + 1 {
      y_limbs[i] += 1
      if y_limbs[i] != 0x0U {
        break
      }
    }
  }

  // Bit Ops 
  for i = 0; i < x_limbs.length(); i = i + 1 {
    x_limbs[i] = x_limbs[i] & y_limbs[i]
  }

  // Check wether the result is either positive or negative
  let new_sign = if x_limbs[x_limbs.length() - 1] == 0xFFFFFFFFU {
    Negative
  } else {
    Positive
  }

  // Restore as true code
  if new_sign == Negative {
    for i = 0; i < x_limbs.length(); i = i + 1 {
      x_limbs[i] -= 1
      if x_limbs[i] != 0xFFFFFFFFU {
        break
      }
    }
    for i = 0; i < x_limbs.length(); i = i + 1 {
      x_limbs[i] = x_limbs[i] ^ 0xFFFFFFFFU
    }
  }

  // return the result
  {
    limbs: FixedArray::make(max_length - 1, 0U)..unsafe_blit(
      0,
      x_limbs,
      0,
      max_length - 1,
    ),
    sign: new_sign,
    len: if self.len > other.len {
      self.len
    } else {
      other.len
    },
  }
}

///|
pub fn BigInt::lor(self : BigInt, other : BigInt) -> BigInt {
  let max_length = if self.limbs.length() < other.limbs.length() {
    other.limbs.length() + 1
  } else {
    self.limbs.length() + 1
  }
  // Extend the limbs to store the sign bits
  let x_limbs = FixedArray::make(max_length, 0U)..unsafe_blit(
    0,
    self.limbs,
    0,
    self.limbs.length(),
  )
  let y_limbs = FixedArray::make(max_length, 0U)..unsafe_blit(
    0,
    other.limbs,
    0,
    other.limbs.length(),
  )

  // Calculate the complement code per 2
  if self.sign == Negative {
    for i = 0; i < x_limbs.length(); i = i + 1 {
      x_limbs[i] = x_limbs[i] ^ 0xFFFFFFFFU
    }
    for i = 0; i < x_limbs.length(); i = i + 1 {
      x_limbs[i] += 1
      if x_limbs[i] != 0x0U {
        break
      }
    }
  }
  if other.sign == Negative {
    for i = 0; i < y_limbs.length(); i = i + 1 {
      y_limbs[i] = y_limbs[i] ^ 0xFFFFFFFFU
    }
    for i = 0; i < y_limbs.length(); i = i + 1 {
      y_limbs[i] += 1
      if y_limbs[i] != 0x0U {
        break
      }
    }
  }

  // Bit Ops 
  for i = 0; i < x_limbs.length(); i = i + 1 {
    x_limbs[i] = x_limbs[i] | y_limbs[i]
  }

  // Check wether the result is either positive or negative
  let new_sign = if x_limbs[x_limbs.length() - 1] == 0xFFFFFFFFU {
    Negative
  } else {
    Positive
  }

  // Restore as true code
  if new_sign == Negative {
    for i = 0; i < x_limbs.length(); i = i + 1 {
      x_limbs[i] -= 1
      if x_limbs[i] != 0xFFFFFFFFU {
        break
      }
    }
    for i = 0; i < x_limbs.length(); i = i + 1 {
      x_limbs[i] = x_limbs[i] ^ 0xFFFFFFFFU
    }
  }

  // return the result
  {
    limbs: FixedArray::make(max_length - 1, 0U)..unsafe_blit(
      0,
      x_limbs,
      0,
      max_length - 1,
    ),
    sign: new_sign,
    len: if self.len > other.len {
      self.len
    } else {
      other.len
    },
  }
}

///|
pub fn BigInt::lxor(self : BigInt, other : BigInt) -> BigInt {
  let max_length = if self.limbs.length() < other.limbs.length() {
    other.limbs.length() + 1
  } else {
    self.limbs.length() + 1
  }
  // Extend the limbs to store the sign bits
  let x_limbs = FixedArray::make(max_length, 0U)..unsafe_blit(
    0,
    self.limbs,
    0,
    self.limbs.length(),
  )
  let y_limbs = FixedArray::make(max_length, 0U)..unsafe_blit(
    0,
    other.limbs,
    0,
    other.limbs.length(),
  )

  // Calculate the complement code per 2
  if self.sign == Negative {
    for i = 0; i < x_limbs.length(); i = i + 1 {
      x_limbs[i] = x_limbs[i] ^ 0xFFFFFFFFU
    }
    for i = 0; i < x_limbs.length(); i = i + 1 {
      x_limbs[i] += 1
      if x_limbs[i] != 0x0U {
        break
      }
    }
  }
  if other.sign == Negative {
    for i = 0; i < y_limbs.length(); i = i + 1 {
      y_limbs[i] = y_limbs[i] ^ 0xFFFFFFFFU
    }
    for i = 0; i < y_limbs.length(); i = i + 1 {
      y_limbs[i] += 1
      if y_limbs[i] != 0x0U {
        break
      }
    }
  }

  // Bit Ops 
  for i = 0; i < x_limbs.length(); i = i + 1 {
    x_limbs[i] = x_limbs[i] ^ y_limbs[i]
  }

  // Check wether the result is either positive or negative
  let new_sign = if x_limbs[x_limbs.length() - 1] == 0xFFFFFFFFU {
    Negative
  } else {
    Positive
  }

  // Restore as true code
  if new_sign == Negative {
    for i = 0; i < x_limbs.length(); i = i + 1 {
      x_limbs[i] -= 1
      if x_limbs[i] != 0xFFFFFFFFU {
        break
      }
    }
    for i = 0; i < x_limbs.length(); i = i + 1 {
      x_limbs[i] = x_limbs[i] ^ 0xFFFFFFFFU
    }
  }

  // return the result
  {
    limbs: FixedArray::make(max_length - 1, 0U)..unsafe_blit(
      0,
      x_limbs,
      0,
      max_length - 1,
    ),
    sign: new_sign,
    len: if self.len > other.len {
      self.len
    } else {
      other.len
    },
  }
}

///|
/// Converts a `BigInt` to a 32-bit signed integer (`Int`).
///
/// Parameters:
///
/// * `self` : The `BigInt` value to be converted.
///
/// Returns a 32-bit signed integer representing the lower 32 bits of the input
/// `BigInt`.
///
/// Example:
///
/// ```moonbit
/// test "BigInt::to_int" {
///   let big = 2147483648N // 2^31
///   inspect!(big.to_int(), content="-2147483648") // Overflow to Int.min_value
/// }
/// ```
pub fn BigInt::to_int(self : BigInt) -> Int {
  self.to_uint().reinterpret_as_int()
}

///|
/// Converts a `BigInt` to an unsigned 32-bit integer (`UInt`).
///
/// Parameters:
///
/// * `self` : The `BigInt` value to be converted.
///
/// Returns a `UInt` value representing the lower 32 bits of the input `BigInt`.
///
/// Example:
///
/// ```moonbit
/// test "BigInt::to_uint" {
///   let n = 42N
///   inspect!(n.to_uint(), content="42")
///   let neg = -1N
///   inspect!(neg.to_uint(), content="4294967295") // 2^32 - 1
/// }
/// ```
pub fn BigInt::to_uint(self : BigInt) -> UInt {
  let value = if self.sign == Negative { (1N << 32) + self } else { self }
  value.limbs[0]
}

///|
/// Converts a `BigInt` to a signed 64-bit integer (`Int64`).
///
/// Parameters:
///
/// * `value` : The `BigInt` value to be converted.
///
/// Returns a 64-bit signed integer (`Int64`) representing the lower 64 bits of
/// the input `BigInt`.
///
/// Example:
///
/// ```moonbit
/// test "BigInt::to_int64" {
///   let big = 9223372036854775807N // max value of Int64
///   inspect!(big.to_int64(), content="9223372036854775807")
///   let bigger = big + 1
///   inspect!(bigger.to_int64(), content="-9223372036854775808") // Overflow to Int64.min_value
/// }
/// ```
pub fn BigInt::to_int64(self : BigInt) -> Int64 {
  self.to_uint64().reinterpret_as_int64()
}

///|
/// Converts a `BigInt` to an unsigned 64-bit integer (`UInt64`).
///
/// Parameters:
///
/// * `self` : The `BigInt` value to be converted.
///
/// Returns a `UInt64` value representing the lower 64 bits of the input
/// `BigInt`.
///
/// Example:
///
/// ```moonbit
/// test "BigInt::to_uint64" {
///   let n = 12345678901234567890N
///   inspect!(n.to_uint64(), content="12345678901234567890")
///   let neg = -1N
///   inspect!(neg.to_uint64(), content="18446744073709551615") // 2^64 - 1
/// }
/// ```
pub fn BigInt::to_uint64(self : BigInt) -> UInt64 {
  let value = if self.sign == Negative { (1N << 64) + self } else { self }
  let len = 64 / radix_bit_len
  let len = if value.len < len { value.len } else { len }
  let mut result = 0UL
  for i = len - 1; i >= 0; i = i - 1 {
    result = result << radix_bit_len
    result = result | (value.limbs[i].to_uint64() & radix_mask)
  }
  result
}
