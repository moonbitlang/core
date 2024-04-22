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

let radix = 65536L // TODO: This can be generalized once we have const generics

let init_capacity = 64

pub fn from_int(n : Int) -> BigInt {
  let n = n.to_int64()
  from_int64(n)
}

pub fn from_int64(n : Int64) -> BigInt {
  let limbs = Array::make(init_capacity, 0L)
  let mut m = n.abs()
  let mut i = 0
  while m > 0L {
    limbs[i] = m % radix
    m /= radix
    i += 1
  }
  { limbs, sign: if n < 0L { Negative } else { Positive }, len: i }
}

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

/// Add two bigint
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
  let limbs = Array::make(1 + max(self_len, other_len), 0L)
  let mut carry = 0L
  let mut i = 0
  while i < self_len || i < other_len || carry != 0L {
    let a = if i < self_len { self.limbs[i] } else { 0L }
    let b = if i < other_len { other.limbs[i] } else { 0L }
    let sum = a + b + carry
    limbs[i] = sum % radix
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
  let limbs = Array::make(max(self_len, other_len), 0L)
  let mut borrow = 0L
  let mut i = 0
  while i < self_len || i < other_len || borrow != 0L {
    let a = if i < self_len { self.limbs[i] } else { 0L }
    let b = if i < other_len { other.limbs[i] } else { 0L }
    let diff = a - b - borrow
    if diff < 0L {
      limbs[i] = diff + radix
      borrow = 1L
    } else {
      limbs[i] = diff
      borrow = 0L
    }
    i += 1
  }
  { limbs, sign: Positive, len: i }
}

/// Multiply two bigint by Karatsuba algorithm
pub fn op_mul(self : BigInt, other : BigInt) -> BigInt {
  let sign :Sign= if self.sign == other.sign { Positive } else { Negative }
  let self_len = self.limbs.length()
  let other_len = other.limbs.length()
  let limbs = Array::make(self_len + other_len, 0L)
  let mut i = 0
  while i < self_len {
    let mut j = 0
    let mut carry = 0L
    while j < other_len || carry != 0L {
      let product = limbs[i + j] + self.limbs[i] * if j < other_len { other.limbs[j] } else { 0L } + carry
      limbs[i + j] = product % radix
      carry = product / radix
      j += 1
    }
    i += 1
  }
  { limbs, sign, len: self_len + other_len }
}

/// Divide two bigint


/// Implement the compare trait for BigInt
pub fn Compare::compare(self : BigInt, other : BigInt) -> Int {
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

/// Implement the Eq trait for BigInt
pub fn Eq::op_equal(self : BigInt, other : BigInt) -> Bool {
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

pub fn to_string(self : BigInt) -> String {
  let mut s = if self.sign == Negative { "-" } else { "" }
  let mut i = self.len - 1
  while i >= 0 {
    s = s + self.limbs[i].to_string()
    i -= 1
  }
  s
}

fn max[T : Compare](a : T, b : T) -> T {
  if a > b {
    a
  } else {
    b
  }
}
