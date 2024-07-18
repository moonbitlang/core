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

// Not needed for 8 bytes data
// let gPRIME1 = 0x9E3779B1

let gPRIME2 = 0x85EBCA77

let gPRIME3 = 0xC2B2AE3D

let gPRIME4 = 0x27D4EB2F

let gPRIME5 = 0x165667B1

// https://github.com/Cyan4973/xxHash/blob/dev/doc/xxhash_spec.md#xxh32-algorithm-description
// For a more readable version, see bytes/xxhash.mbt
pub fn hash(self : Int64) -> Int {
  let mut input = self
  let seed = 0
  let mut acc = seed + gPRIME5 + 8
  let mut x = acc + input.to_int() * gPRIME3
  let r = 17
  acc = x.lsl(r).lor(x.lsr(32 - r)) * gPRIME4
  input = input.lsr(32)
  x = acc + input.to_int() * gPRIME3
  acc = x.lsl(r).lor(x.lsr(32 - r)) * gPRIME4
  input = input.lsr(32)
  acc = acc.lxor(acc.lsr(15))
  acc *= gPRIME2
  acc = acc.lxor(acc.lsr(13))
  acc *= gPRIME3
  acc = acc.lxor(acc.lsr(16))
  acc
}

pub fn hash_combine(self : Int64, hasher : Hasher) -> Unit {
  hasher.combine_int64(self)
}
