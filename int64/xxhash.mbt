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

let gPRIME2 = 0x85EBCA77U

let gPRIME3 = 0xC2B2AE3DU

let gPRIME4 = 0x27D4EB2FU

let gPRIME5 = 0x165667B1U

// https://github.com/Cyan4973/xxHash/blob/dev/doc/xxhash_spec.md#xxh32-algorithm-description
// For a more readable version, see bytes/xxhash.mbt
pub impl Hash for Int64 with hash(self) -> Int {
  let mut input = self.reinterpret_as_uint64()
  let seed = 0U
  let mut acc = seed + gPRIME5 + 8
  let mut x = acc + input.to_uint() * gPRIME3
  let r = 17
  acc = ((x << r) | (x >> (32 - r))) * gPRIME4
  input = input >> 32
  x = acc + input.to_uint() * gPRIME3
  acc = ((x << r) | (x >> (32 - r))) * gPRIME4
  input = input >> 32
  acc = acc ^ (acc >> 15)
  acc *= gPRIME2
  acc = acc ^ (acc >> 13)
  acc *= gPRIME3
  acc = acc ^ (acc >> 16)
  acc.reinterpret_as_int()
}

pub impl Hash for Int64 with hash_combine(self, hasher) {
  hasher.combine_int64(self)
}

fn slow_hash(self : Int64) -> Int {
  let b = Bytes::new(8)
  let self = self.reinterpret_as_uint64()
  b[7] = (self >> 56).to_byte()
  b[6] = ((self >> 48) & 0xFF).to_byte()
  b[5] = ((self >> 40) & 0xFF).to_byte()
  b[4] = ((self >> 32) & 0xFF).to_byte()
  b[3] = ((self >> 24) & 0xFF).to_byte()
  b[2] = ((self >> 16) & 0xFF).to_byte()
  b[1] = ((self >> 8) & 0xFF).to_byte()
  b[0] = (self & 0xFF).to_byte()
  Hash::hash(b)
}

test "int64 hash" {
  let i0 = 9_223_372_036_854_775_807L // INT64_MAX
  let i1 = -9_223_372_036_854_775_808L // INT64_MIN
  let i2 = gPRIME2.to_uint64().to_int64()
  let i3 = gPRIME3.to_uint64().to_int64()
  let i4 = gPRIME4.to_uint64().to_int64()
  let i5 = gPRIME5.to_uint64().to_int64()
  let i6 = 0L
  inspect!(Hash::hash(i0).to_string(), content=i0.slow_hash().to_string())
  inspect!(Hash::hash(i1).to_string(), content=i1.slow_hash().to_string())
  inspect!(Hash::hash(i2).to_string(), content=i2.slow_hash().to_string())
  inspect!(Hash::hash(i3).to_string(), content=i3.slow_hash().to_string())
  inspect!(Hash::hash(i4).to_string(), content=i4.slow_hash().to_string())
  inspect!(Hash::hash(i5).to_string(), content=i5.slow_hash().to_string())
  inspect!(Hash::hash(i6).to_string(), content=i6.slow_hash().to_string())
}
