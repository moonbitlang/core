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
fn division_bench_mix64(input : UInt64) -> UInt64 {
  let z = (input ^ (input >> 30)) * 0xbf58476d1ce4e5b9UL
  let z = (z ^ (z >> 27)) * 0x94d049bb133111ebUL
  z ^ (z >> 31)
}

///|
fn division_bench_dense(bytes : Int, seed : UInt64) -> @bigint.BigInt {
  @bigint.BigInt::from_octets(
    Bytes::makei(bytes, i => {
      let byte = (division_bench_mix64(seed + i.to_uint64()) & 0xffUL).to_int()
      (if i == 0 { byte | 0x80 } else { byte }).to_byte()
    }),
  )
}

///|
/// Builds a dense, balanced 2n-by-n division with roughly `digits` decimal
/// digits in both the quotient and divisor.
fn make_balanced_division(digits : Int) -> (@bigint.BigInt, @bigint.BigInt) {
  // 3.322 is a slight upper bound for log2(10).
  let bytes = (digits * 3322 / 1000 + 7) / 8
  let quotient = division_bench_dense(bytes, 0x123456789abcdef0UL)
  let divisor = division_bench_dense(bytes, 0xfedcba9876543210UL)
  (quotient * divisor + divisor - 1N, divisor)
}

///|
/// Builds an unbalanced division with exact native/wasm 64-bit limb counts.
fn make_unbalanced_division(
  quotient_limbs : Int,
  divisor_limbs : Int,
) -> (@bigint.BigInt, @bigint.BigInt) {
  let quotient = division_bench_dense(quotient_limbs * 8, 0x0f1e2d3c4b5a6978UL)
  let divisor = division_bench_dense(divisor_limbs * 8, 0x8796a5b4c3d2e1f0UL)
  (quotient * divisor + divisor - 1N, divisor)
}

///|
test "bench BigInt balanced division n=4000 digits" (it : @bench.T) {
  let (dividend, divisor) = make_balanced_division(4000)
  it.bench(fn() { it.keep(dividend / divisor) })
}

///|
test "bench BigInt balanced division n=40000 digits" (it : @bench.T) {
  let (dividend, divisor) = make_balanced_division(40000)
  it.bench(fn() { it.keep(dividend / divisor) })
}

///|
test "bench BigInt balanced division n=250000 digits" (it : @bench.T) {
  let (dividend, divisor) = make_balanced_division(250000)
  it.bench(fn() { it.keep(dividend / divisor) })
}

///|
test "bench BigInt unbalanced division q=65536 d=64 limbs" (it : @bench.T) {
  let (dividend, divisor) = make_unbalanced_division(65536, 64)
  it.bench(fn() { it.keep(dividend / divisor) })
}
