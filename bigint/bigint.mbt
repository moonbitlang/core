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

let radix : Int64 = 1L.lsl(radix_bit_len) // TODO: This can be generalized once we have const generics

// Useful bigints

let zero : BigInt = from_int64(0L)

// Conversion Functions

/// Convert an Int to a BigInt.
pub fn from_int(n : Int) -> BigInt {
  let n = n.to_int64()
  from_int64(n)
}

/// Convert an Int64 to a BigInt.
pub fn from_int64(n : Int64) -> BigInt {
  let limbs = Array::make(64 / radix_bit_len, 0)
  let mut m = n.abs()
  let mut i = 0
  while m > 0L {
    limbs[i] = (m % radix).to_int()
    m /= radix
    i += 1
  }
  { limbs, sign: if n < 0L { Negative } else { Positive }, len: i }
}

/// Construct a zero
pub fn make_zero() -> BigInt {
  { limbs: Array::make(1, 0), sign: Positive, len: 1 }
}

// Arithmetic Operations

/// Negate a bigint
pub fn op_neg(self : BigInt) -> BigInt {
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
      return -(-other + -self)
    } else {
      return other - -self
    }
  } else if other.sign == Negative {
    return self - -other
  }
  let self_len = self.limbs.length()
  let other_len = other.limbs.length()
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
  if self.sign == Negative {
    if other.sign == Negative {
      return -other - -self
    } else {
      return -(other + -self)
    }
  } else if other.sign == Negative {
    return self + -other
  }
  if self < other {
    return -(other - self)
  }
  let self_len = self.limbs.length()
  let other_len = other.limbs.length()
  let limbs = Array::make(max(self_len, other_len), 0)
  let mut borrow = 0L
  let mut i = 0
  while i < self_len || i < other_len || borrow != 0L {
    let a = if i < self_len { self.limbs[i].to_int64() } else { 0L }
    let b = if i < other_len { other.limbs[i].to_int64() } else { 0L }
    let diff = a - b - borrow
    if diff < 0L {
      limbs[i] = ((diff + radix) % radix).to_int()
      borrow = 1L
    } else {
      limbs[i] = diff.to_int()
      borrow = 0L
    }
    i += 1
  }
  { limbs, sign: Positive, len: i }
}

/// Multiply two bigint 
pub fn op_mul(self : BigInt, other : BigInt) -> BigInt {
  grade_school_mul(self, other)
}

// Simplest way to multiply two BigInts.
fn grade_school_mul(self : BigInt, other : BigInt) -> BigInt {
  let sign : Sign = if self.sign == other.sign { Positive } else { Negative }
  let self_len = self.limbs.length()
  let other_len = other.limbs.length()
  let limbs = Array::make(self_len + other_len, 0)
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
  { limbs, sign, len: self_len + other_len }
}

/// Divide two bigint
pub fn op_div(self : BigInt, other : BigInt) -> BigInt {
  if other == zero {
    return abort("division by zero")
  }
  let (quotient, _) = grade_school_div(self, other)
  quotient
}

/// Modulo two bigint
pub fn op_mod(self : BigInt, other : BigInt) -> BigInt {
  if other == zero {
    return abort("division by zero")
  }
  let (_, remainder) = grade_school_div(self, other)
  remainder
}

// Simplest way to divide two BigInts.
// Assumption: other != zero.
fn grade_school_div(self : BigInt, other : BigInt) -> (BigInt, BigInt) {
  if self.sign == Negative {
    if other.sign == Negative {
      return grade_school_div(-self, -other)
    } else {
      let (quotient, remainder) = grade_school_div(-self, other)
      return (-quotient, -remainder)
    }
  } else if other.sign == Negative {
    let (quotient, remainder) = grade_school_div(self, -other)
    return (-quotient, remainder)
  }

  // Cite: TAOCP Vol. 2, 4.3.1
  if self < other {
    return (zero, self)
  } else if self == other {
    return (from_int(1), zero)
  }

  // implement the algorithm in Knuth[The Art of Computer Programming]
  let dividend = self.deep_clone()
  let divisor = other.deep_clone()
  // 1. normalize
  let base = radix
  let mut lshift = 0
  let mut back = divisor.limbs[divisor.limbs.length() - 1].to_int64()
  while back < base / 2L {
    back = back.lsl(1)
    lshift += 1
  }
  let dividend = dividend.lsl(lshift)
  let divisor = divisor.lsl(lshift)
  let b = divisor.limbs
  let sz_b = b.length() // size of divisor
  dividend.limbs = dividend.limbs + Array::make(sz_b, 0)
  // let a = dividend.limbs

  // // 2. loop
  // const uint_type &v1 = b[sz_b-1], &v2 = b[sz_b-2];
  // q.resize(a.size() - b.size());
  // for(size_type i = q.size() - 1; i != (size_type)-1; --i)
  // {
  //     // get the estimated value of q
  //     ull_type qh;
  //     uint_type &u0 = a[i+sz_b], &u1 = a[i+sz_b-1], &u2 = a[i+sz_b-2];
  //     qh = (u0 * base + u1) / v1;
  //     if(qh * v2 > base * (u0 * base + u1 - qh * v1) + u2) --qh;

  //     // multi and subtract
  //     llint_type borrow = 0;
  //     ull_type carry = 0;
  //     for(size_type j = 0; j < sz_b; ++j)
  //     {
  //         carry += qh * b[j];
  //         borrow += a[i+j];
  //         borrow -= uint_type(carry);
  //         a[i+j] = uint_type(borrow);
  //         borrow >>= UINT_LEN;
  //         carry >>= UINT_LEN;
  //     }
  //     borrow += a[i+sz_b];
  //     borrow -= carry;
  //     a[i+sz_b] = uint_type(borrow);
  //     borrow >>= UINT_LEN;
  //     while(borrow < 0)
  //     {
  //         // add divisor back to dividend
  //         assert(borrow==-1);
  //         carry = 0;
  //         for(size_type j = 0; j < sz_b; ++j)
  //         {
  //             carry += a[i+j];
  //             carry += b[j];
  //             a[i+j] = uint_type(carry);
  //             carry >>= UINT_LEN;
  //         }
  //         carry += a[i+sz_b];
  //         a[i+sz_b] = uint_type(carry);
  //         carry >>= UINT_LEN;
  //         borrow += carry;
  //         --qh; // don't forget
  //     }
  //     assert(borrow == 0);
  //     q[i] = uint_type(qh);

  // }
  // // 3. get quotient and real remainder
  // unsigned_bigint quotient(std::move(q));
  // dividend.strip();
  // dividend >>= lshift;
  // return std::make_pair(std::move(quotient), std::move(dividend));

  (zero, zero)
}

test "grade_school_div" {
  // let a = from_int64(1234567890123456789L)
  // let b = from_int64(123456789L)
  // let (quotient, remainder) = grade_school_div(a, b)
  // assert(quotient == from_int64(10000000000L))
  // assert(remainder == from_int64(987654321L))
}

// Bitwise Operations

/// Left shift a bigint
pub fn lsl(self : BigInt, n : Int) -> BigInt {
  if n < 0 {
    return abort("negative shift count")
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
      for i = 0; i < a.length(); i = i + 1 {
        carry = carry.lor(a[i].to_int64().lsl(r))
        new_limbs[i + lz] = carry.to_int()
        carry = carry.lsr(radix_bit_len)
      }
      if carry > 0L {
        new_limbs[a.length() + lz] = carry.to_int()
        len += 1
      }
    } else {
      for i = 0; i < a.length(); i = i + 1 {
        new_limbs[i + lz] = a[i]
      }
    }
    { limbs: new_limbs, sign: self.sign, len }
  } else {
    make_zero()
  }
}

test "lsl" {
  let a = from_int64(1234567890123456789L)
  let b = a.lsl(1)
  inspect(b.to_decimal_string(), content="2469135780246913578")?
  let c = a.lsl(64)
  inspect(
    c.to_decimal_string(),
    content="22773757910726981402256170801141121024",
  )?
}

/// Right shift a bigint
pub fn lsr(self : BigInt, n : Int) -> BigInt {
  if n < 0 {
    return abort("negative shift count")
  }    
  
  let r = n % radix_bit_len
  let lz = n / radix_bit_len 
  if lz >= self.len {
    return make_zero()
  }

  if (r == 0) {
    let new_limbs = Array::make(self.len - lz, 0)
    for i = lz; i < self.len; i = i + 1 {
      new_limbs[i - lz] = self.limbs[i]
    }
    { limbs: new_limbs, sign: self.sign, len: self.len - lz }
  } else {
    let new_limbs = Array::make(self.len - lz, 0)
    let a = self.limbs
    let mut carry = 0L
    for i = self.len - 1; i >= lz; i = i - 1 {
      let x = a[i].to_int64()
      new_limbs[i - lz] = (x.lsr(r).lor(carry)).to_int()
      carry = x.lsl(radix_bit_len - r) % radix
    }
    { limbs: new_limbs, sign: self.sign, len: self.len - lz }
  }
}

test "lsr" {
  let a = from_int64(1234567890123456789L)
  let b = a.lsr(1)
  inspect(b.to_decimal_string(), content="617283945061728394")?
  let c = a.lsr(64)
  inspect(c.to_decimal_string(), content="0")?
}

// Comparison Operations

/// Check if a bigint is zero
pub fn is_zero(self : BigInt) -> Bool {
  self.len == 0 || self.len == 1 && self.limbs[0] == 0
}

/// Implements the compare trait for BigInt
pub fn compare(self : BigInt, other : BigInt) -> Int {
  if self.sign != other.sign {
    return if self.sign == Positive { 1 } else { -1 }
  }
  let self_len = self.limbs.length()
  let other_len = other.limbs.length()
  if self_len != other_len {
    return if self.sign == Positive {
      self_len - other_len
    } else {
      other_len - self_len
    }
  }
  let mut i = self_len - 1
  while i >= 0 {
    if self.limbs[i] != other.limbs[i] {
      return if self.sign == Positive {
        self.limbs[i].compare(other.limbs[i])
      } else {
        other.limbs[i].compare(self.limbs[i])
      }
    }
    i -= 1
  }
  0
}

/// Implements the Eq trait for BigInt
pub fn op_equal(self : BigInt, other : BigInt) -> Bool {
  if self.sign != other.sign || self.limbs.length() != other.limbs.length() {
    return false
  }
  let mut i = 0
  while i < self.limbs.length() {
    if self.limbs[i] != other.limbs[i] {
      return false
    }
    i += 1
  }
  true
}

/// Returns the decimal string representation of the BigInt.
pub fn to_decimal_string(self : BigInt) -> String {
  // This function first converts the BigInt to a decimal representation, with a radix of 2^(`decimal_radix_bit_len`).
  // Then it converts the decimal representation to a string slot by slot.
  if self.is_zero() {
    return "0"
  }
  let decimal_ratio = 0.302 // log10(2)
  let decimal_radix_bit_len = 19 - (1 + radix_bit_len) / 3 - 1 // < len(9,223,372,036,854,775,807) - len(2^radix_bit_len). len means the number of digits in decimal.
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

pub fn deep_clone(self : BigInt) -> BigInt {
  let new_limbs = self.limbs.map(fn(x) { x })
  { limbs: new_limbs, sign: self.sign, len: self.len }
}

fn max[T : Compare](a : T, b : T) -> T {
  if a > b {
    a
  } else {
    b
  }
}

// Tests

test "to_decimal_string" {
  let a = from_int64(1234567890123456789L)
  inspect(a.to_decimal_string(), content="1234567890123456789")?
  let b = from_int64(-1234567890L)
  inspect(b.to_decimal_string(), content="-1234567890")?
}
