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

///|
test "BigInt::to_double rounds to nearest, ties to even" {
  let p53 = 1N << 53
  // Spacing between doubles is 2 at 2^53, 4 at 2^54 and 8 at 2^55.
  assert_eq((p53 + 1).to_double(), 9007199254740992.0) // tie, round down to even
  assert_eq((p53 + 3).to_double(), 9007199254740996.0) // tie, round up to even
  let p54 = 1N << 54
  assert_eq((p54 + 2).to_double(), 18014398509481984.0) // tie, round down to even
  assert_eq((p54 + 3).to_double(), 18014398509481988.0) // above the tie
  let p55 = 1N << 55
  assert_eq((p55 + 4).to_double(), 36028797018963968.0) // tie, round down to even
  assert_eq((p55 + 5).to_double(), 36028797018963976.0) // sticky bit breaks the tie
  // Rounding up carries into the next power of two.
  assert_eq(((1N << 54) - 1).to_double(), 18014398509481984.0)
  assert_eq((-(p53 + 3)).to_double(), -9007199254740996.0)
}

///|
test "BigInt::to_double at the edges of the Double range" {
  inspect(0N.to_double(), content="0")
  inspect((-0N).to_double(), content="0")
  inspect(((1N << 64) - 1).to_double(), content="18446744073709552000")
  let max_finite = (1N << 1024) - (1N << 971)
  assert_eq(
    max_finite.to_double(),
    0x7FEFFFFFFFFFFFFFUL.reinterpret_as_double(),
  )
  // Just below the midpoint between the largest finite double and 2^1024.
  assert_eq(
    ((1N << 1024) - (1N << 970) - 1).to_double(),
    0x7FEFFFFFFFFFFFFFUL.reinterpret_as_double(),
  )
  // The midpoint itself ties to even, which is 2^1024: infinity.
  inspect(((1N << 1024) - (1N << 970)).to_double(), content="Infinity")
  inspect((1N << 1024).to_double(), content="Infinity")
  inspect((-(1N << 5000)).to_double(), content="-Infinity")
}

///|
test "BigInt::to_double agrees with decimal parsing" {
  // `@string.parse_double` is correctly rounded, so it is an oracle for any
  // value in the finite range.
  let mut state = 0x9E3779B97F4A7C15UL
  fn next() -> UInt64 {
    state = state * 6364136223846793005UL + 1442695040888963407UL
    state
  }

  fn check(v : @bigint.BigInt) -> Unit raise {
    let expected = @string.parse_double(v.to_string())
    assert_eq(v.to_double(), expected, msg=v.to_string())
  }

  for _ in 0..<2000 {
    // Random values of random bit length up to 1023 bits.
    let limbs = (next() >> 58).to_int() + 1 // 1..=64 limbs of 16 bits
    let mut v = 0N
    for _ in 0..<limbs {
      v = (v << 16) | @bigint.BigInt::from_uint64(next() >> 48)
    }
    let v = v >> (next() >> 61).to_int()
    check(v)
    check(-v)
    // Values right at, just below and just above a rounding midpoint.
    let significand = @bigint.BigInt::from_uint64(next() >> 11) // < 2^53
    let k = (next() >> 54).to_int() % 960 + 1 // 1..=960
    let midpoint = (significand << k) + (1N << (k - 1))
    check(midpoint)
    check(midpoint - 1)
    check(midpoint + 1)
  }
}
