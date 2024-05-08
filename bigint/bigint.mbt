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

// Hyper Params

/// Invariants:
/// - ((radix - 1) ^ 2) must fit in an Int64
/// - radix can only be a power of 2
/// - radix_bit_len < 32 (TODO: change this to <= 32 once we have unsigned integers)
let radix_bit_len = 16

/// The base of the number system.
let radix : Int64 = 1L.lsl(radix_bit_len) // TODO: This can be generalized once we have const generics

/// The mask to extract the lower `radix_bit_len` bits.
let radix_mask : Int64 = radix - 1L

/// The ratio of the number of decimal digits to the number of radix digits.
let decimal_ratio = 0.302 // log10(2)

/// When to switch to Karatsuba multiplication
let karatsuba_threshold = 50

// Useful bigints

let zero : BigInt = from_int64(0L)

let one : BigInt = from_int64(1L)

// Conversion Functions

/// Convert an Int to a BigInt.
pub fn from_int(n : Int) -> BigInt {
  if n < 0 {
    { limbs: Array::make(1, -n), sign: Negative, len: 1 }
  } else {
    { limbs: Array::make(1, n), sign: Positive, len: 1 }
  }
}

/// Convert an Int64 to a BigInt.
pub fn from_int64(n : Int64) -> BigInt {
  if n == 0L {
    return { limbs: Array::make(1, 0), sign: Positive, len: 1 }
  }
  let limbs = Array::make(64 / radix_bit_len, 0)
  let mut m = if n < 0L { -n } else { n }
  let mut i = 0
  while m > 0L {
    limbs[i] = (m % radix).to_int()
    m /= radix
    i += 1
  }
  { limbs, sign: if n < 0L { Negative } else { Positive }, len: i }
}

/// Construct a zero
/// 
/// TODO: modify function name after literal syntax is supported
pub fn make_zero() -> BigInt {
  { limbs: Array::make(1, 0), sign: Positive, len: 1 }
}

// Arithmetic Operations

/// Negate a bigint
pub fn op_neg(self : BigInt) -> BigInt {
  // copy limbs
  let limbs = Array::make(self.len, 0)
  for i = 0; i < self.len; i = i + 1 {
    limbs[i] = self.limbs[i]
  }
  {
    limbs,
    sign: if self.sign == Positive {
      Negative
    } else {
      Positive
    },
    len: self.len,
  }
}

/// Negate a bigint without copying limbs, for internal use.
fn neg(self : BigInt) -> BigInt {
  {
    limbs: self.limbs,
    sign: if self.sign == Positive {
      Negative
    } else {
      Positive
    },
    len: self.len,
  }
}

/// Add two bigint.
pub fn op_add(self : BigInt, other : BigInt) -> BigInt {
  if self.sign == Negative {
    if other.sign == Negative {
      return neg(neg(other) + neg(self))
    } else {
      return other - neg(self)
    }
  } else if other.sign == Negative {
    return self - neg(other)
  }
  let self_len = self.len
  let other_len = other.len
  let limbs = Array::make(1 + max(self_len, other_len), 0)
  let mut carry = 0L
  let mut i = 0
  while i < self_len || i < other_len || carry != 0L {
    let a = if i < self_len { self.limbs[i].to_int64() } else { 0L }
    let b = if i < other_len { other.limbs[i].to_int64() } else { 0L }
    let sum = a + b + carry
    limbs[i] = (sum % radix).to_int()
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
      return neg(other) - neg(self)
    } else {
      return neg(other + neg(self))
    }
  } else if other.sign == Negative {
    return self + neg(other)
  }
  // then make sure self >= other
  if self < other {
    return neg(other - self)
  }
  let self_len = self.len
  let other_len = other.len
  let limbs = Array::make(max(self_len, other_len), 0)
  let mut borrow = 0L
  let mut i = 0
  while i < self_len || i < other_len || borrow != 0L {
    let a = if i < self_len { self.limbs[i].to_int64() } else { 0L }
    let b = if i < other_len { other.limbs[i].to_int64() } else { 0L }
    let diff = a - b - borrow // 0 <= a < radix, 0 <= b < radix, 0 <= borrow <= 1 => -radix <= diff < radix
    if diff < 0L {
      limbs[i] = (diff + radix).to_int() // -radix <= diff < 0, so we don't need to mod by radix
      borrow = 1L
    } else {
      limbs[i] = diff.to_int() // 0 <= diff < radix, so we don't need to mod by radix
      borrow = 0L
    }
    i += 1
  }
  if limbs[i - 1] == 0 {
    i -= 1
  }
  { limbs, sign: Positive, len: i }
}

/// Multiply two bigint 
pub fn op_mul(self : BigInt, other : BigInt) -> BigInt {
  if self.is_zero() || other.is_zero() {
    return make_zero()
  }
  let ret = if self.len < karatsuba_threshold || other.len < karatsuba_threshold {
    grade_school_mul(self, other)
  } else {
    karatsuba_mul(self, other)
  }
  ret.sign = if self.sign == other.sign { Positive } else { Negative }
  ret
}

// Simplest way to multiply two BigInts.
fn grade_school_mul(self : BigInt, other : BigInt) -> BigInt {
  let self_len = self.len
  let other_len = other.len
  let mut len = self_len + other_len
  let limbs = Array::make(len, 0)
  let mut i = 0
  while i < self_len {
    let mut j = 0
    let mut carry = 0L
    while j < other_len || carry != 0L {
      let product = limbs[i + j].to_int64() + self.limbs[i].to_int64() * if j < other_len {
          other.limbs[j].to_int64()
        } else {
          0L
        } + carry
      limbs[i + j] = (product % radix).to_int()
      carry = product / radix
      j += 1
    }
    i += 1
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
  p1.lsl(radix_bit_len * 2 * half) + (p3 - p1 - p2).lsl(radix_bit_len * half) + p2
}

// Get the lower half of the number.
fn split(self : BigInt, half : Int) -> (BigInt, BigInt) {
  if self.len <= half {
    let ret = self.deep_clone()
    ret.sign = Positive
    return (ret, make_zero())
  }
  let lower = Array::make(half, 0)
  for i = 0; i < half; i = i + 1 {
    lower[i] = self.limbs[i]
  }
  let upper = Array::make(self.len - half, 0)
  for i = half; i < self.len; i = i + 1 {
    upper[i - half] = self.limbs[i]
  }
  (
    { limbs: lower, sign: Positive, len: half },
    { limbs: upper, sign: Positive, len: self.len - half },
  )
}

/// Divide two bigint
pub fn op_div(self : BigInt, other : BigInt) -> BigInt {
  if other == zero {
    abort("division by zero")
  }
  let (quotient, _) = grade_school_div(self, other)
  quotient
}

/// Modulo two bigint
pub fn op_mod(self : BigInt, other : BigInt) -> BigInt {
  if other == zero {
    abort("division by zero")
  }
  let (_, remainder) = grade_school_div(self, other)
  remainder
}

// Simplest way to divide two BigInts.
// Assumption: other != zero.
fn grade_school_div(self : BigInt, other : BigInt) -> (BigInt, BigInt) {
  fn fix(a : (BigInt, BigInt), divisor : BigInt) -> (BigInt, BigInt) {
    let (res, remain) = a
    if remain == zero {
      res.sign = Negative
      return (res, make_zero())
    }
    let remain = match divisor.sign {
      Positive => divisor - remain
      Negative => neg(divisor) - remain
    }
    remain.sign = divisor.sign
    let res = res + one
    res.sign = Negative
    (res, remain)
  }

  // Handle negative numbers

  if self.sign == Negative {
    if other.sign == Negative {
      return grade_school_div(neg(self), neg(other))
    } else {
      return fix(grade_school_div(neg(self), other), other)
    }
  } else if other.sign == Negative {
    return fix(grade_school_div(self, neg(other)), other)
  }

  // Handle edge cases
  if self < other {
    return (make_zero(), self)
  } else if self == other {
    return (from_int(1), make_zero())
  }
  if other.len == 1 {
    let number = other.limbs[0]
    if number == 0 {
      abort("divided by zero")
    }
    let ret = self.deep_clone()
    if number == 1 {
      return (ret, make_zero())
    }
    let a = ret.limbs
    let x = number.to_int64()
    let mut y = 0L
    for i = self.len - 1; i >= 0; i = i - 1 {
      y = y.lsl(radix_bit_len)
      y += a[i].to_int64()
      a[i] = (y / x).land(radix_mask).to_int()
      y %= x
    }
    if ret.limbs[ret.len - 1] == 0 {
      ret.len -= 1
    }
    return (ret, from_int64(y.land(radix_mask)))
  }

  // Cite: TAOCP Vol. 2, 4.3.1
  let dividend = self
  let divisor = other

  // normalize 
  let mut lshift = 0
  let mut back = divisor.limbs[divisor.len - 1].to_int64()
  while back < radix / 2L {
    back = back.lsl(1)
    lshift += 1
  }
  let dividend = dividend.lsl(lshift)
  let divisor = divisor.lsl(lshift)
  let a_len = dividend.len
  let b_len = divisor.len
  let b = Array::make(b_len, 0L)
  for i = 0; i < b_len; i = i + 1 {
    b[i] = divisor.limbs[i].to_int64()
  }
  let a = Array::make(a_len, 0L)
  for i = 0; i < a_len; i = i + 1 {
    a[i] = dividend.limbs[i].to_int64()
  }
  let v1 = b[b_len - 1]
  let v2 = b[b_len - 2]
  let q = Array::make(a_len - b_len, 0)
  for i = q.length() - 1; i >= 0; i = i - 1 {
    let u0 = a[i + b_len]
    let u1 = a[i + b_len - 1]
    let u2 = a[i + b_len - 2]
    let mut qh = (u0 * radix + u1) / v1
    if qh * v2 > radix * (u0 * radix + u1 - qh * v1) + u2 {
      qh -= 1L
    }
    let mut borrow = 0L
    let mut carry = 0L
    for j = 0; j < b_len; j = j + 1 {
      carry += qh * b[j]
      borrow += a[i + j]
      borrow -= carry.land(radix_mask)
      a[i + j] = borrow.land(radix_mask)
      borrow = borrow.asr(radix_bit_len)
      carry = carry.asr(radix_bit_len)
    }
    borrow = borrow + a[i + b_len]
    borrow -= carry
    a[i + b_len] = borrow.land(radix_mask)
    borrow = borrow.asr(radix_bit_len)
    while borrow < 0L {
      carry = 0L
      for j = 0; j < b_len; j = j + 1 {
        carry += a[i + j]
        carry += b[j]
        a[i + j] = carry.land(radix_mask)
        carry = carry.asr(radix_bit_len)
      }
      carry += a[i + b_len]
      a[i + b_len] = carry.land(radix_mask)
      carry = carry.asr(radix_bit_len)
      borrow += carry
      qh -= 1L
    }
    q[i] = qh.to_int()
  }
  let len = if q[q.length() - 1] == 0 { q.length() - 1 } else { q.length() }

  // strip leading zeros
  let mut i = a.length() - 1
  while i >= 0 && a[i] == 0L {
    i -= 1
  }
  if i < 0 {
    i = 1
  } else {
    i += 1
  }
  let modulo = Array::make(i, 0)
  for j = 0; j < i; j = j + 1 {
    modulo[j] = a[j].to_int()
  }
  let modulo = { limbs: modulo, sign: Positive, len: i }
  ({ limbs: q, sign: Positive, len }, modulo.lsr(lshift))
}

// Bitwise Operations

/// Left shift a bigint
pub fn lsl(self : BigInt, n : Int) -> BigInt {
  if n < 0 {
    abort("negative shift count")
  }
  if not(self.is_zero()) {
    let new_limbs = Array::make(
      self.len + (n + radix_bit_len - 1) / radix_bit_len, // ceiling(n / radix_bit_len)
      0,
    )
    let a = self.limbs
    let r = n % radix_bit_len
    let lz = n / radix_bit_len // number of leading zeros
    let mut len = self.len + lz
    if r != 0 {
      let mut carry = 0L
      for i = 0; i < self.len; i = i + 1 {
        carry = carry.lor(a[i].to_int64().lsl(r))
        new_limbs[i + lz] = (carry % radix).to_int()
        carry = carry.lsr(radix_bit_len)
      }
      if carry > 0L {
        new_limbs[self.len + lz] = carry.to_int()
        len += 1
      }
    } else {
      for i = 0; i < self.len; i = i + 1 {
        new_limbs[i + lz] = a[i]
      }
    }
    { limbs: new_limbs, sign: self.sign, len }
  } else {
    make_zero()
  }
}

/// Right shift a bigint
pub fn lsr(self : BigInt, n : Int) -> BigInt {
  if n < 0 {
    abort("negative shift count")
  }
  let r = n % radix_bit_len
  let lz = n / radix_bit_len
  if lz >= self.len {
    return make_zero()
  }
  let mut new_len = self.len - lz
  if r == 0 {
    let new_limbs = Array::make(new_len, 0)
    for i = lz; i < self.len; i = i + 1 {
      new_limbs[i - lz] = self.limbs[i]
    }
    { limbs: new_limbs, sign: self.sign, len: new_len }
  } else {
    let new_limbs = Array::make(new_len, 0)
    let a = self.limbs
    let mut carry = 0L
    for i = self.len - 1; i >= lz; i = i - 1 {
      let x = a[i].to_int64()
      new_limbs[i - lz] = x.lsr(r).lor(carry).to_int()
      carry = x.lsl(radix_bit_len - r) % radix
    }
    if new_len > 1 && new_limbs[new_len - 1] == 0 {
      new_len -= 1
    }
    { limbs: new_limbs, sign: self.sign, len: new_len }
  }
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
  let decimal_mask = 10000000000000L // 10^(decimal_radix_bit_len). TODO: compute it when we have power function.
  // The following value should fit well into an Int without precision loss.
  // This is an approximation of the number of slots needed to represent the decimal value.
  let decimal_len = ((self.len * radix_bit_len).to_double() * decimal_ratio / decimal_radix_bit_len.to_double()).to_int() +
    1
  let s = if self.sign == Negative { "-" } else { "" }
  let v = Array::make(decimal_len, 0L)
  let mut v_idx = 0
  for i = self.len - 1; i >= 0; i = i - 1 {
    let mut x = self.limbs[i].to_int64()
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

/// Converts decimal string to a BigInt.
pub fn from_string(input : String) -> BigInt {
  let len = input.length()
  if len == 0 {
    abort("empty string")
  }
  let sign : Sign = if input[0] == '-' { Negative } else { Positive }
  let mut b_len = ((len.to_double() / decimal_ratio).to_int() + 1 + radix_bit_len) /
    radix_bit_len + 1
  let b = Array::make(b_len, 0)
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
    let mut carry = x.to_int64()
    for j = 0; j < b_len; j = j + 1 {
      carry += (b[j] * 10).to_int64()
      b[j] = (carry % radix).to_int()
      carry /= radix
    }
  }
  while b[b_len - 1] == 0 && b_len > 1 {
    b_len -= 1
  }
  { limbs: b, sign, len: b_len }
}

/// Converts a hex string to a BigInt.
pub fn from_hex(input : String) -> BigInt {
  let len = input.length()
  if len == 0 {
    abort("empty string")
  }
  let sign : Sign = if input[0] == '-' { Negative } else { Positive }
  let mut b_len = (len * 4 + 1 + radix_bit_len) / radix_bit_len + 1
  let b = Array::make(b_len, 0)
  for i = match sign {
          Negative => 1
          Positive => 0
        }
      i < input.length()
      i = i + 1 {
    let x = input[i].to_int()
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
    let mut carry = y
    for j = 0; j < b_len; j = j + 1 {
      carry += b[j] * 16
      b[j] = carry % radix.to_int()
      carry /= radix.to_int()
    }
  }
  while b[b_len - 1] == 0 && b_len > 1 {
    b_len -= 1
  }
  { limbs: b, sign, len: b_len }
}

/// Converts a BigInt to a hex string.
pub fn to_hex(self : BigInt) -> String {
  let mut result = ""
  for i = self.len - 1; i >= 0; i = i - 1 {
    // split the limb into 4-bit chunks
    let mut x = self.limbs[i]
    let mut tmp = ""
    while x > 0 {
      let y = x % 16
      x /= 16
      tmp = if y < 10 {
          Char::from_int(y + 48).to_string()
        } else {
          Char::from_int(y + 55).to_string()
        } + tmp
    }
    if i != self.len - 1 && tmp.length() < 4 {
      let pad = 4 - tmp.length()
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
  let new_limbs = Array::make(self.len, 0)
  for i = 0; i < self.len; i = i + 1 {
    new_limbs[i] = self.limbs[i]
  }
  { limbs: new_limbs, sign: self.sign, len: self.len }
}

fn max[T : Compare](a : T, b : T) -> T {
  if a > b {
    a
  } else {
    b
  }
}
