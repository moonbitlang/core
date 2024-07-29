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
pub impl Hash for Int64 with hash(self) -> Int {
  let mut input = self
  let seed = 0
  let mut acc = seed + gPRIME5 + 8
  let mut x = acc + input.to_int() * gPRIME3
  let r = 17
  acc = x.shl(r).lor(x.shr(32 - r)) * gPRIME4
  input = input.shr(32)
  x = acc + input.to_int() * gPRIME3
  acc = x.shl(r).lor(x.shr(32 - r)) * gPRIME4
  input = input.shr(32)
  acc = acc.lxor(acc.shr(15))
  acc *= gPRIME2
  acc = acc.lxor(acc.shr(13))
  acc *= gPRIME3
  acc = acc.lxor(acc.shr(16))
  acc
}

pub impl Hash for Int64 with hash_combine(self, hasher) {
  hasher.combine_int64(self)
}

fn slow_hash(self : Int64) -> Int {
  let b = Bytes::new(8)
  b[7] = self.shr(56).to_byte()
  b[6] = self.shr(48).land(0xFFL).to_byte()
  b[5] = self.shr(40).land(0xFFL).to_byte()
  b[4] = self.shr(32).land(0xFFL).to_byte()
  b[3] = self.shr(24).land(0xFFL).to_byte()
  b[2] = self.shr(16).land(0xFFL).to_byte()
  b[1] = self.shr(8).land(0xFFL).to_byte()
  b[0] = self.land(0xFFL).to_byte()
  Hash::hash(b)
}

test "int64 hash" {
  let i0 = 9_223_372_036_854_775_807L // INT64_MAX
  let i1 = -9_223_372_036_854_775_808L // INT64_MIN
  let i2 = gPRIME2.to_int64()
  let i3 = gPRIME3.to_int64()
  let i4 = gPRIME4.to_int64()
  let i5 = gPRIME5.to_int64()
  let i6 = 0L
  inspect!(Hash::hash(i0).to_string(), content=i0.slow_hash().to_string())
  inspect!(Hash::hash(i1).to_string(), content=i1.slow_hash().to_string())
  inspect!(Hash::hash(i2).to_string(), content=i2.slow_hash().to_string())
  inspect!(Hash::hash(i3).to_string(), content=i3.slow_hash().to_string())
  inspect!(Hash::hash(i4).to_string(), content=i4.slow_hash().to_string())
  inspect!(Hash::hash(i5).to_string(), content=i5.slow_hash().to_string())
  inspect!(Hash::hash(i6).to_string(), content=i6.slow_hash().to_string())
}
