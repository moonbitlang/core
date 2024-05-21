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

fn slow_hash(self : Int64) -> Int {
  let b = Bytes::make(8)
  b[7] = self.lsr(56).to_byte()
  b[6] = self.lsr(48).land(0xFFL).to_byte()
  b[5] = self.lsr(40).land(0xFFL).to_byte()
  b[4] = self.lsr(32).land(0xFFL).to_byte()
  b[3] = self.lsr(24).land(0xFFL).to_byte()
  b[2] = self.lsr(16).land(0xFFL).to_byte()
  b[1] = self.lsr(8).land(0xFFL).to_byte()
  b[0] = self.land(0xFFL).to_byte()
  b.hash()
}

// Not needed for 8 bytes data
// let gPRIME1 = -1640531535

let gPRIME2 = -2048144777

let gPRIME3 = -1028477379

let gPRIME4 = 668265263

let gPRIME5 = 374761393

// https://github.com/Cyan4973/xxHash/blob/dev/doc/xxhash_spec.md#xxh32-algorithm-description
// For a more readable version, see bytes/xxhash.mbt
pub fn hash(self : Int64) -> Int {
  let mut input = self
  let seed = 0
  let mut len = 8
  let mut acc = seed + gPRIME5 + len
  while len > 0 {
    len -= 4
    let x = acc + input.to_int() * gPRIME3
    let r = 17
    acc = x.lsl(r).lor(x.lsr(32 - r)) * gPRIME4
    input = input.lsr(32)
  }
  acc = acc.lxor(acc.lsr(15))
  acc *= gPRIME2
  acc = acc.lxor(acc.lsr(13))
  acc *= gPRIME3
  acc = acc.lxor(acc.lsr(16))
  acc
}

test "int64 hash" {
  let i0 = 9_223_372_036_854_775_807L // INT64_MAX
  let i1 = -9_223_372_036_854_775_808L // INT64_MIN
  let i2 = gPRIME2.to_int64()
  let i3 = gPRIME3.to_int64()
  let i4 = gPRIME4.to_int64()
  let i5 = gPRIME5.to_int64()
  let i6 = 0L
  inspect(i0.hash().to_string(), content=i0.slow_hash().to_string())?
  inspect(i1.hash().to_string(), content=i1.slow_hash().to_string())?
  inspect(i2.hash().to_string(), content=i2.slow_hash().to_string())?
  inspect(i3.hash().to_string(), content=i3.slow_hash().to_string())?
  inspect(i4.hash().to_string(), content=i4.slow_hash().to_string())?
  inspect(i5.hash().to_string(), content=i5.slow_hash().to_string())?
  inspect(i6.hash().to_string(), content=i6.slow_hash().to_string())?
}
