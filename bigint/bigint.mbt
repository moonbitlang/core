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
  if self < other {
    return (zero, self)
  } else if self == other {
    return (from_int(1), zero)
  }
  (zero, self)
}

test "grade_school_div" {
  // let a = from_int64(1234567890123456789L)
  // let b = from_int64(123456789L)
  // let (quotient, remainder) = grade_school_div(a, b)
  // assert(quotient == from_int64(10000000000L))
  // assert(remainder == from_int64(987654321L))
}

// Comparison Operations

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
  let decimal_ratio = 0.302 // log10(2)
  let decimal_radix_bit_len = 18 // < len(9,223,372,036,854,775,807)
  let decimal_mask = 10000_0000_0000_0000_00L // 10^(decimal_digits_per_slot)
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
  for i = 0; i < v_idx; i = i + 1 {
    ret = v[i].to_string() + ret
  }
  if ret == "" {
    ret = "0"
  }
  s + ret
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
