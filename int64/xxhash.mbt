// Copyright 2025 International Digital Economy Academy
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

///|
let gPRIME2 = 0x85EBCA77U

///|
let gPRIME3 = 0xC2B2AE3DU

///|
let gPRIME4 = 0x27D4EB2FU

///|
let gPRIME5 = 0x165667B1U

///|
pub impl Hash for Int64 with hash_combine(self, hasher) {
  hasher.combine_int64(self)
}

///|
test "int64 hash" {
  let i0 = 9_223_372_036_854_775_807L // INT64_MAX
  let i1 = -9_223_372_036_854_775_808L // INT64_MIN
  let i2 = gPRIME2.to_int64()
  let i3 = gPRIME3.to_int64()
  let i4 = gPRIME4.to_int64()
  let i5 = gPRIME5.to_int64()
  let i6 = 0L
  inspect(i0.hash().to_string(), content="1886677411")
  inspect(i1.hash().to_string(), content="483163611")
  inspect(i2.hash().to_string(), content="-283106542")
  inspect(i3.hash().to_string(), content="1841207399")
  inspect(i4.hash().to_string(), content="-1983297055")
  inspect(i5.hash().to_string(), content="118566791")
  inspect(i6.hash().to_string(), content="-558656237")
}
