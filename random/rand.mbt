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

/// Currently we only support [chacha8] as the source of randomness.
struct Rand {
  src : ChaCha8
}

/// Create a new random number generator with [seed].
pub fn Rand::new(
  ~seed : Bytes = string_to_bytes("ABCDEFGHIJKLMNOPQRSTUVWXYZ123456")
) -> Rand {
  let src = ChaCha8::new(seed)
  { src, }
}

fn Rand::next(self : Rand) -> UInt64 {
  for {
    let x = self.src.state.next()
    if x.1 {
      return x.0
    }
    self.src.state.refill()
  }
}

test "next" {
  let r = Rand::new()
  let n = r.next()
  let exp = 13219109469176600229UL
  assert_eq!(n, exp)
}

/// [int] Return a non-negative pseudo-random 31-bit integer as an Int.
pub fn Rand::int(self : Rand) -> Int {
  self.next().lsr(33).to_int()
}

/// [int64] returns a non-negative pseudo-random 63-bit integer as an Int64
pub fn Rand::int64(self : Rand) -> Int64 {
  // Create a mask that has all bits set to 1 except the highest bit
  let mask : UInt64 = 1UL << 63
  return (self.next() & mask).to_int64()
}

/// [uint] returns a non-negative pseudo-random 32-bit integer as a Uint
pub fn Rand::uint(self : Rand) -> UInt {
  self.next().to_uint()
}

/// [uint64] returns a non-negative pseudo-random 64-bit integer as a Uint64
pub fn Rand::uint64(self : Rand) -> UInt64 {
  self.next()
}

test "UInt64" {
  let r = Rand::new()
  let n = r.uint64()
  let exp = 13219109469176600229UL
  assert_eq!(n, exp)
}

/// [double64] returns a pseudo-random 64-bit Double in the range [0.0, 1.0)
pub fn Rand::double64(self : Rand) -> Double {
  Double::convert_uint64((self.next() << 11).lsr(11)) /
  Double::convert_uint64(1UL << 53)
}

test "double64" {
  let r = Rand::new()
  let n = r.double64()
  inspect!(n, content="0.615969772029264")
}

/// [umul128] returns the 128-bit product of x and y: (hi, lo) = x * y
/// with the product bits' upper half returned in hi and the lower
/// half returned in lo.
///
/// This function's execution time does not depend on the inputs.
fn umul128(a : UInt64, b : UInt64) -> (UInt64, UInt64) {
  let aLo = a.to_uint()
  let aHi = a.lsr(32).to_uint()
  let bLo = b.to_uint()
  let bHi = b.lsr(32).to_uint()
  let b00 = aLo.to_uint64() * bLo.to_uint64()
  let b01 = aLo.to_uint64() * bHi.to_uint64()
  let b10 = aHi.to_uint64() * bLo.to_uint64()
  let b11 = aHi.to_uint64() * bHi.to_uint64()
  let b00Lo = b00.to_uint()
  let b00Hi = b00.lsr(32).to_uint()
  let mid1 = b10 + b00Hi.to_uint64()
  let mid1Lo = mid1.to_uint()
  let mid1Hi = mid1.lsr(32).to_uint()
  let mid2 = b01 + mid1Lo.to_uint64()
  let mid2Lo = mid2.to_uint()
  let mid2Hi = mid2.lsr(32).to_uint()
  let pHi : UInt64 = b11 + mid1Hi.to_uint64() + mid2Hi.to_uint64()
  let pLo : UInt64 = mid2Lo.to_uint64().lsl(32).lor(b00Lo.to_uint64())
  (pHi, pLo)
}

test "umul128" {
  // let (hi, lo) = umul128(1UL << 32, 1UL << 32)
  // assert_eq!(hi, 1UL)
  // assert_eq!(lo, 0UL)
  let (hi, lo) = umul128(0x123456789ABCDEF0, 0xFEDCBA9876543210)
  assert_eq!(hi, 1305938385386173474UL)
  assert_eq!(lo, 2552847189736476416UL)
}

test "umul128: handles small numbers correctly" {
  let (hi, lo) = umul128(1UL, 1UL)
  assert_eq!(hi, 0UL)
  assert_eq!(lo, 1UL)
}

test "umul128: handles large numbers correctly" {
  let (hi, lo) = umul128(1UL, 0xFFFFFFFFFFFFFFFFUL)
  assert_eq!(hi, 0UL)
  assert_eq!(lo, 0xFFFFFFFFFFFFFFFFUL)
}

test "umul128: handles zero correctly" {
  let (hi, lo) = umul128(0UL, 0UL)
  assert_eq!(hi, 0UL)
  assert_eq!(lo, 0UL)
}

/// [uint64N] returns, as a Uint64, a pseudo-random number in the half-open interval [0,n)
/// @alert unsafe "Panics if n is 0"
pub fn Rand::uint64N(self : Rand, n : UInt64) -> UInt64 {
  if n == 0 {
    abort("Rand::uint64N: n must > 0")
  }
  // n is a power of 2, mask to get the unbiased result.
  if (n & (n - 1)) == 0 {
    return self.next() & (n - 1)
  }
  let mut t = (0UL, 0UL)
  t = umul128(self.next(), n)
  if t.1 < n {
    let thresh = n.lnot() % n
    while t.1 < thresh {
      t = umul128(self.next(), n)
    }
  }
  t.0
}

test "uint64N" {
  let r = Rand::new()
  let n = r.uint64N(10UL)
  inspect!(n, content="7")
  let n = r.uint64N(10UL)
  inspect!(n, content="0")
  let n = r.uint64N(10UL)
  inspect!(n, content="5")
}

/// [uintN] returns a non-negative pseudo-random 32-bit integer in the range [0, n)
/// @alert unsafe "Panics if n is 0"
pub fn Rand::uintN(self : Rand, n : UInt) -> UInt {
  if n == 0 {
    abort("Rand::uintN: n must > 0")
  }
  self.uint64N(n.to_uint64()).to_uint()
}

test "uintN" {
  let r = Rand::new()
  let n = r.uintN(10U)
  inspect!(n, content="7")
  let n = r.uintN(10U)
  inspect!(n, content="0")
  let n = r.uintN(10U)
  inspect!(n, content="5")
}

/// [int64N] returns a non-negative pseudo-random 63-bit integer in the range [0, n)
/// @alert unsafe "Panics if n is 0"
pub fn Rand::int64N(self : Rand, n : Int64) -> Int64 {
  if n <= 0 {
    abort("Rand::int64N: n must be positive")
  }
  self.uint64N(n.to_uint64()).to_int64()
}

/// [intN] returns a non-negative pseudo-random 31-bit integer in the range [0, n)
/// @alert unsafe "Panics if n is 0"
pub fn Rand::intN(self : Rand, n : Int) -> Int {
  if n <= 0 {
    abort("Rand::intN: n must be positive")
  }
  self.uintN(n.to_uint()).to_int()
}

pub fn Rand::shuffle(self : Rand, n : Int, swap : (Int, Int) -> Unit) -> Unit {
  if n < 0 {
    abort("Rand::shuffle: invalid argument n")
  }
  for i = n - 1; i > 0; i = i - 1 {
    let j = self.intN(i + 1)
    swap(i, j)
  }
}

test "shuffle" {
  let r = Rand::new()
  let a = [1, 2, 3, 4, 5]
  r.shuffle(
    a.length(),
    fn(i : Int, j : Int) {
      let t = a[i]
      a[i] = a[j]
      a[j] = t
    },
  )
  inspect!(a, content="[3, 5, 2, 1, 4]")
}
