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
let radix_shift = 16
let radix:Int64 = 2L.lsl(radix_shift) // TODO: This can be generalized once we have const generics
let init_capacity = 64

// Useful bigints

let zero:BigInt =  from_int64(0L)
/// Used for converting to decimal. 
/// Invariants: 
/// - Must be less than radix.
/// - Must be a power of 10.
let decimal_cutoff: BigInt = from_int64(10L) 

// Conversion Functions

pub fn from_int(n : Int) -> BigInt {
  let n = n.to_int64()
  from_int64(n)
}

pub fn from_int64(n : Int64) -> BigInt {
  let limbs = Array::make(init_capacity, 0)
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
    let b = if i < other_len { other.limbs[i].to_int64()} else { 0L }
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
fn grade_school_mul(self: BigInt, other : BigInt) -> BigInt {
  let sign :Sign= if self.sign == other.sign { Positive } else { Negative }
  let self_len = self.limbs.length()
  let other_len = other.limbs.length()
  let limbs = Array::make(self_len + other_len, 0)
  let mut i = 0
  while i < self_len {
    let mut j = 0
    let mut carry = 0L
    while j < other_len || carry != 0L {
      let product = limbs[i + j].to_int64() + self.limbs[i].to_int64() * if j < other_len { other.limbs[j].to_int64() } else { 0L } + carry
      limbs[i + j] = (product % radix).to_int()
      carry = product / radix
      j += 1
    }
    i += 1
  }
  { limbs, sign, len: self_len + other_len }
}


/// Divide two bigint
pub fn op_div(self: BigInt, other: BigInt) -> BigInt {
  if other == zero {
    return abort("division by zero")
  }
  let (quotient, _) = grade_school_div(self, other)
  quotient
}

/// Modulo two bigint
pub fn op_mod(self: BigInt, other: BigInt) -> BigInt {
  if other == zero {
    return abort("division by zero")
  }
  let (_, remainder) = grade_school_div(self, other)
  remainder
}

// Simplest way to divide two BigInts.
// Assumption: other != zero.
fn grade_school_div(self: BigInt, other: BigInt) -> (BigInt, BigInt) {
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

/// Implement the compare trait for BigInt
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

/// Implement the Eq trait for BigInt
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

// pub fn to_decimal_string(self : BigInt) -> String {
//   let decimal_ratio = 0.302 // log10(2)
//   let decimal_digits_per_slot = 5 // 100000
//   let decimal_len = (((self.len * radix_shift).to_double() * decimal_ratio) / decimal_digits_per_slot).ceil() 


//   let mut s = if self.sign == Negative { "-" } else { "" }
//   let ret = Array::make()

//   const vector<uint_type> a = this->digits;


//     v.reserve(a.size() * TOSTR_HINT); // roughly allocate memory
//     ull_type y;
//     for(size_type i = a.size() - 1; i != size_type(-1); --i)
//     {
//         uint_type x = a[i];
//         for(size_type j = 0; j < v.size(); ++j)
//         {
//             y = (ull_type(v[j]) << UINT_LEN) | x;
//             x = uint_type(y / TENS_MASK);
//             v[j] = uint_type(y % TENS_MASK);
//         }
//         while(x)
//         {
//             v.push_back(x % TENS_MASK);
//             x /= TENS_MASK;
//         }
//     }
//     std::string result;
//     result.reserve(v.size() * SUBSTR_LEN);
//     // If v.size > 1, add possible leading zeros to v[0..size-2]
//     if(v.size() > 1)
//     {
//         for(size_type i = 0; i < v.size() - 1; ++i)
//         {
//             for(size_type j = 0; j < SUBSTR_LEN; ++j)
//                 result.push_back(v[i]%10 + '0'), v[i] /= 10;
//         }
//     }
//     // But the last number in v don't need to
//     auto &back = v.back();
//     while(back)
//     {
//         result.push_back(back%10 + '0');
//         back /= 10;
//     }
//     if(result.size() == 0) result.push_back('0');

//     // the result itself is reversed, so if reverse is false,
//     // we reverse the result.
//     if(!reverse)
//     {
//         auto first = result.begin(), last = result.end();
//         while((first != last) && (first != --last))
//             std::iter_swap(first, last), ++first;
//     }
//     return std::move(result);
// }

fn max[T : Compare](a : T, b : T) -> T {
  if a > b {
    a
  } else {
    b
  }
}

test "to_string" {
  // let a = from_int64(1234567890123456789L)
  // inspect(a.to_string(), ~content="1234567890123456789")?
  // let b = from_int64(-1234567890123456789L)
  // inspect(b.to_string(), ~content="-1234567890123456789")?
      for i = 10-1 ; i >= 0; i = i- 1{
        println(i)
      }
}