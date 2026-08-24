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
struct RandomState {
  mut seed : UInt64
  gamma : UInt64
} derive(@debug.Debug)

///|
let golden_gamma : UInt64 = 0x9e3779b97f4a7c15

///|
let double_ulp : Double = 1.0 / (1L << 53).to_double()

///|
let float_ulp : Float = 1.0F / Float::from_int64(1L << 24)

///|
/// Create a new RandomState from an optional seed.
pub fn new(seed? : UInt64 = 37) -> RandomState {
  { seed: mix64(seed), gamma: mix_gamma(seed + golden_gamma) }
}

///|
/// Clone a RandomState.
pub fn RandomState::clone(self : RandomState) -> RandomState {
  { ..self }
}

///|
/// Skip the next random number.
pub fn RandomState::next(self : RandomState) -> Unit {
  self.next_uint64() |> ignore
}

///|
fn RandomState::next_uint64_raw(self : RandomState) -> UInt64 {
  let { seed, gamma } = self
  self.seed = seed + gamma
  mix64(self.seed)
}

///|
/// Returns a random `UInt64`.
///
/// With no `limit`, values span the complete `UInt64` range. With `limit`,
/// this method uses bitmask rejection to return an unbiased value in the
/// half-open interval `[0, limit)`. Rejected words consume additional values
/// from this random state.
///
/// # Panics
///
/// Panics if `limit` is explicitly set to zero.
pub fn RandomState::next_uint64(self : RandomState, limit? : UInt64) -> UInt64 {
  match limit {
    None => self.next_uint64_raw()
    Some(0UL) => abort("RandomState::next_uint64: limit must be positive")
    Some(limit) => {
      let mask = if limit == 1UL {
        0UL
      } else {
        0xffff_ffff_ffff_ffffUL >> (limit - 1UL).clz()
      }
      for candidate = self.next_uint64_raw() & mask; candidate >= limit; {
        continue self.next_uint64_raw() & mask
      } nobreak {
        candidate
      }
    }
  }
}

///|
/// Returns a random `UInt`.
///
/// With no `limit`, values span the complete `UInt` range. With `limit`, this
/// method returns an unbiased value in the half-open interval `[0, limit)`.
///
/// # Panics
///
/// Panics if `limit` is explicitly set to zero.
pub fn RandomState::next_uint(self : RandomState, limit? : UInt) -> UInt {
  match limit {
    None => self.next_uint64_raw().to_uint()
    Some(0U) => abort("RandomState::next_uint: limit must be positive")
    Some(limit) => self.next_uint64(limit=limit.to_uint64()).to_uint()
  }
}

///|
/// Get the next random number as a 64-bit signed integer.
pub fn RandomState::next_int64(self : RandomState) -> Int64 {
  self.next_uint64().reinterpret_as_int64()
}

///|
/// Get the next two random number as 32-bit signed integers.
pub fn RandomState::next_two_uint(self : RandomState) -> (UInt, UInt) {
  let g = self.next_uint64()
  ((g >> 32).to_uint(), g.to_uint())
}

///|
/// Get the next random number as a 32-bit signed integer.
pub fn RandomState::next_int(self : RandomState) -> Int {
  self.next_uint().reinterpret_as_int()
}

///|
/// Get the next random number as a positive 32-bit signed integer.
pub fn RandomState::next_positive_int(self : RandomState) -> Int {
  let r = self.next_int()
  match r {
    -2147483648 => 2147483647
    0 => 1
    r if r < 0 => -r
    r => r
  }
}

///|
/// Get the next random number as a float in [0, 1]
pub fn RandomState::next_float(self : RandomState) -> Float {
  let u = self.next_uint64()
  Float::from_uint64(u >> 40) * float_ulp
}

///|
/// Get the next random number as a double in [0, 1]
pub fn RandomState::next_double(self : RandomState) -> Double {
  let u = self.next_uint64()
  (u >> 11).to_double() * double_ulp
}

///|
/// Generates an independent random number generator.
pub fn RandomState::split(self : RandomState) -> RandomState {
  let seed1 = self.seed + self.gamma
  self.seed = seed1 + self.gamma
  { seed: mix64(seed1), gamma: mix_gamma(self.seed) }
}

///|
fn shift_xor(n : Int, w : UInt64) -> UInt64 {
  w ^ (w >> n)
}

///|
fn shift_xor_mul(n : Int, k : UInt64, w : UInt64) -> UInt64 {
  shift_xor(n, w) * k
}

///|
fn mix64(z0 : UInt64) -> UInt64 {
  let z1 = shift_xor_mul(30, 0xff51afd7ed558ccd, z0)
  let z2 = shift_xor_mul(33, 0xc4ceb9fe1a85ec53, z1)
  shift_xor(33, z2)
}

///|
fn mix64variant13(z0 : UInt64) -> UInt64 {
  let z1 = shift_xor_mul(30, 0xbf58476d1ce4e5b9, z0)
  let z2 = shift_xor_mul(27, 0x94d049bb133111eb, z1)
  shift_xor(31, z2)
}

///|
fn mix_gamma(z0 : UInt64) -> UInt64 {
  let z1 = mix64variant13(z0 | 1)
  let n = (z1 | (z1 >> 1)).popcnt()
  if n >= 24 {
    z1
  } else {
    z1 ^ 0xaaaaaaaaaaaaaaaa
  }
}

///|
pub impl Default for RandomState with fn default() {
  new()
}

///|
test "non-zero default" {
  let rs = (Default::default() : RandomState)
  @test.assert_not_eq(rs.seed, 0)
  @test.assert_not_eq(rs.gamma, 0)
}
