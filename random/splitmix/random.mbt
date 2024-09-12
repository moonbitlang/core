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

struct RandomState {
  mut seed : UInt64
  mut gamma : UInt64
} derive(Show)

let golden_gamma : UInt64 = 0x9e3779b97f4a7c15

let double_ulp : Double = 1.0 / (1L << 53).to_double()

pub fn RandomState::new(~seed : UInt64 = 37) -> RandomState {
  { seed: mix64(seed), gamma: mix_gamma(seed + golden_gamma) }
}

pub fn clone(self : RandomState) -> RandomState {
  { ..self }
}

pub fn next(self : RandomState) -> Unit {
  self.next_uint64() |> ignore
}

pub fn next_uint64(self : RandomState) -> UInt64 {
  let { seed, gamma } = self
  self.seed = seed + gamma
  mix64(self.seed)
}

pub fn next_uint(self : RandomState) -> UInt {
  self.next_uint64().to_uint()
}

pub fn next_int64(self : RandomState) -> Int64 {
  self.next_uint64().to_int64()
}

pub fn next_two_uint(self : RandomState) -> (UInt, UInt) {
  let g = self.next_uint64()
  (g.lsr(32).to_uint(), g.to_uint())
}

pub fn next_int(self : RandomState) -> Int {
  self.next_uint().reinterpret_as_int()
}

pub fn next_double(self : RandomState) -> Double {
  let u = self.next_uint64()
  u.lsr(11).to_int64().to_double() * double_ulp
}

pub fn split(self : RandomState) -> RandomState {
  let seed1 = self.seed + self.gamma
  self.seed = seed1 + self.gamma
  { seed: mix64(seed1), gamma: mix_gamma(self.seed) }
}

fn shift_xor(n : Int, w : UInt64) -> UInt64 {
  w.lxor(w.lsr(n))
}

fn shift_xor_mul(n : Int, k : UInt64, w : UInt64) -> UInt64 {
  shift_xor(n, w) * k
}

fn mix64(z0 : UInt64) -> UInt64 {
  let z1 = shift_xor_mul(30, 0xff51afd7ed558ccd, z0)
  let z2 = shift_xor_mul(33, 0xc4ceb9fe1a85ec53, z1)
  shift_xor(33, z2)
}

fn mix64variant13(z0 : UInt64) -> UInt64 {
  let z1 = shift_xor_mul(30, 0xbf58476d1ce4e5b9, z0)
  let z2 = shift_xor_mul(27, 0x94d049bb133111eb, z1)
  shift_xor(31, z2)
}

fn pop_count(c : UInt64) -> Int {
  c.to_int64().popcnt()
}

test {
  inspect!(pop_count(0x7000_0001_1F00_100FUL), content="14")
}

fn mix_gamma(z0 : UInt64) -> UInt64 {
  let z1 = mix64variant13(z0.lor(1))
  let n = pop_count(z1.lxor(z1.lsr(1)))
  if n >= 24 {
    z1
  } else {
    z1.lxor(0xaaaaaaaaaaaaaaaa)
  }
}
