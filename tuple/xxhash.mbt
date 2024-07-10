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

// https://github.com/Cyan4973/xxHash/blob/dev/doc/xxhash_spec.md#xxh32-algorithm-description

let gPRIME1 = 0x9E3779B1U

let gPRIME2 = 0x85EBCA77U

let gPRIME3 = 0xC2B2AE3DU

let gPRIME4 = 0x27D4EB2FU

let gPRIME5 = 0x165667B1U

pub fn hash[T0 : Hash, T1 : Hash](self : (T0, T1)) -> Int {
  let h1 = self.0.hash().to_uint()
  let h2 = self.1.hash().to_uint()
  let mut acc = empty_state(0U)
  acc += 8
  acc = consume(acc, h1)
  acc = consume(acc, h2)
  acc = avalanche(acc)
  acc.to_int()
}

pub fn hash[T0 : Hash, T1 : Hash, T2 : Hash](self : (T0, T1, T2)) -> Int {
  let h1 = self.0.hash().to_uint()
  let h2 = self.1.hash().to_uint()
  let h3 = self.2.hash().to_uint()
  let mut acc = empty_state(0U)
  acc += 12
  acc = consume(acc, h1)
  acc = consume(acc, h2)
  acc = consume(acc, h3)
  acc = avalanche(acc)
  acc.to_int()
}

pub fn hash[T0 : Hash, T1 : Hash, T2 : Hash, T3 : Hash](
  self : (T0, T1, T2, T3)
) -> Int {
  let h1 = self.0.hash().to_uint()
  let h2 = self.1.hash().to_uint()
  let h3 = self.2.hash().to_uint()
  let h4 = self.3.hash().to_uint()
  let (acc1, acc2, acc3, acc4) = initialize(0U)
  let acc1 = round(acc1, h1)
  let acc2 = round(acc2, h2)
  let acc3 = round(acc3, h3)
  let acc4 = round(acc4, h4)
  let mut acc = mix_state(acc1, acc2, acc3, acc4)
  acc += 16
  acc = avalanche(acc)
  acc.to_int()
}

pub fn hash[T0 : Hash, T1 : Hash, T2 : Hash, T3 : Hash, T4 : Hash](
  self : (T0, T1, T2, T3, T4)
) -> Int {
  let h1 = self.0.hash().to_uint()
  let h2 = self.1.hash().to_uint()
  let h3 = self.2.hash().to_uint()
  let h4 = self.3.hash().to_uint()
  let h5 = self.4.hash().to_uint()
  let (acc1, acc2, acc3, acc4) = initialize(0U)
  let acc1 = round(acc1, h1)
  let acc2 = round(acc2, h2)
  let acc3 = round(acc3, h3)
  let acc4 = round(acc4, h4)
  let mut acc = mix_state(acc1, acc2, acc3, acc4)
  acc += 20
  acc = consume(acc, h5)
  acc = avalanche(acc)
  acc.to_int()
}

pub fn hash[T0 : Hash, T1 : Hash, T2 : Hash, T3 : Hash, T4 : Hash, T5 : Hash](
  self : (T0, T1, T2, T3, T4, T5)
) -> Int {
  let h1 = self.0.hash().to_uint()
  let h2 = self.1.hash().to_uint()
  let h3 = self.2.hash().to_uint()
  let h4 = self.3.hash().to_uint()
  let h5 = self.4.hash().to_uint()
  let h6 = self.5.hash().to_uint()
  let (acc1, acc2, acc3, acc4) = initialize(0U)
  let acc1 = round(acc1, h1)
  let acc2 = round(acc2, h2)
  let acc3 = round(acc3, h3)
  let acc4 = round(acc4, h4)
  let mut acc = mix_state(acc1, acc2, acc3, acc4)
  acc += 24
  acc = consume(acc, h5)
  acc = consume(acc, h6)
  acc = avalanche(acc)
  acc.to_int()
}

pub fn hash[T0 : Hash, T1 : Hash, T2 : Hash, T3 : Hash, T4 : Hash, T5 : Hash, T6 : Hash](
  self : (T0, T1, T2, T3, T4, T5, T6)
) -> Int {
  let h1 = self.0.hash().to_uint()
  let h2 = self.1.hash().to_uint()
  let h3 = self.2.hash().to_uint()
  let h4 = self.3.hash().to_uint()
  let h5 = self.4.hash().to_uint()
  let h6 = self.5.hash().to_uint()
  let h7 = self.6.hash().to_uint()
  let (acc1, acc2, acc3, acc4) = initialize(0U)
  let acc1 = round(acc1, h1)
  let acc2 = round(acc2, h2)
  let acc3 = round(acc3, h3)
  let acc4 = round(acc4, h4)
  let mut acc = mix_state(acc1, acc2, acc3, acc4)
  acc += 28
  acc = consume(acc, h5)
  acc = consume(acc, h6)
  acc = consume(acc, h7)
  acc = avalanche(acc)
  acc.to_int()
}

pub fn hash[T0 : Hash, T1 : Hash, T2 : Hash, T3 : Hash, T4 : Hash, T5 : Hash, T6 : Hash, T7 : Hash](
  self : (T0, T1, T2, T3, T4, T5, T6, T7)
) -> Int {
  let h1 = self.0.hash().to_uint()
  let h2 = self.1.hash().to_uint()
  let h3 = self.2.hash().to_uint()
  let h4 = self.3.hash().to_uint()
  let h5 = self.4.hash().to_uint()
  let h6 = self.5.hash().to_uint()
  let h7 = self.6.hash().to_uint()
  let h8 = self.7.hash().to_uint()
  let (acc1, acc2, acc3, acc4) = initialize(0U)
  let acc1 = round(acc1, h1)
  let acc2 = round(acc2, h2)
  let acc3 = round(acc3, h3)
  let acc4 = round(acc4, h4)
  let acc1 = round(acc1, h5)
  let acc2 = round(acc2, h6)
  let acc3 = round(acc3, h7)
  let acc4 = round(acc4, h8)
  let mut acc = mix_state(acc1, acc2, acc3, acc4)
  acc += 32
  acc = avalanche(acc)
  acc.to_int()
}

fn initialize(seed : UInt) -> (UInt, UInt, UInt, UInt) {
  (seed + gPRIME1 + gPRIME2, seed + gPRIME2, seed + 0, seed - gPRIME1)
}

fn empty_state(seed : UInt) -> UInt {
  seed + gPRIME5
}

fn mix_state(acc1 : UInt, acc2 : UInt, acc3 : UInt, acc4 : UInt) -> UInt {
  rotl(acc1, 1) + rotl(acc2, 7) + rotl(acc3, 12) + rotl(acc4, 18)
}

fn avalanche(acc : UInt) -> UInt {
  let mut acc = acc.lxor(acc.lsr(15))
  acc *= gPRIME2
  acc = acc.lxor(acc.lsr(13))
  acc *= gPRIME3
  acc = acc.lxor(acc.lsr(16))
  acc
}

fn round(acc : UInt, input : UInt) -> UInt {
  rotl(acc + input * gPRIME2, 13) * gPRIME1
}

fn consume(acc : UInt, input : UInt) -> UInt {
  rotl(acc + input * gPRIME3, 17) * gPRIME4
}

fn rotl(x : UInt, r : Int) -> UInt {
  x.lsl(r).lor(x.lsr(32 - r))
}
