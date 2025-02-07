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

///|
let gPRIME1 : UInt = 0x9E3779B1

///|
let gPRIME2 : UInt = 0x85EBCA77

///|
let gPRIME3 : UInt = 0xC2B2AE3D

///|
let gPRIME4 : UInt = 0x27D4EB2F

///|
let gPRIME5 : UInt = 0x165667B1

///|
/// xxhash32 Hasher
struct Hasher {
  mut acc : Int
}

///|
pub fn Hasher::new(seed~ : Int = 0) -> Hasher {
  let result = seed.reinterpret_as_uint() + gPRIME5
  { acc: result.reinterpret_as_int() }
}

///|
pub fn Hasher::combine[T : Hash](self : Hasher, value : T) -> Unit {
  value.hash_combine(self)
}

///|
pub fn Hasher::combine_unit(self : Hasher) -> Unit {
  self.combine_int(0)
}

///|
pub fn Hasher::combine_bool(self : Hasher, value : Bool) -> Unit {
  self.combine_int(if value { 1 } else { 0 })
}

///|
pub fn Hasher::combine_int(self : Hasher, value : Int) -> Unit {
  self.acc += 4
  self.consume4(value)
}

///|
pub fn Hasher::combine_int64(self : Hasher, value : Int64) -> Unit {
  self.acc += 8
  self.consume4(value.to_int())
  self.consume4((value.reinterpret_as_uint64() >> 32).to_int())
}

///|
pub fn Hasher::combine_uint(self : Hasher, value : UInt) -> Unit {
  self.combine_int(value.reinterpret_as_int())
}

///|
pub fn Hasher::combine_uint64(self : Hasher, value : UInt64) -> Unit {
  self.combine_int64(value.reinterpret_as_int64())
}

///|
pub fn Hasher::combine_double(self : Hasher, value : Double) -> Unit {
  self.combine_int64(value.reinterpret_as_int64())
}

///|
pub fn Hasher::combine_float(self : Hasher, value : Float) -> Unit {
  self.combine_int(value.reinterpret_as_int())
}

///|
pub fn Hasher::combine_byte(self : Hasher, value : Byte) -> Unit {
  self.consume1(value)
}

///|
pub fn Hasher::combine_bytes(self : Hasher, value : Bytes) -> Unit {
  let mut remain = value.length()
  let mut cur = 0
  while remain >= 4 {
    self.consume4(endian32(value, cur))
    cur += 4
    remain -= 4
  }
  while remain >= 1 {
    self.consume1(value[cur])
    cur += 1
    remain -= 1
  }
}

///|
pub fn Hasher::combine_string(self : Hasher, value : String) -> Unit {
  for i = 0; i < value.length(); i = i + 1 {
    self.combine_int(value[i].to_int())
  }
}

///|
pub fn Hasher::combine_char(self : Hasher, value : Char) -> Unit {
  self.combine_int(value.to_int())
}

///|
pub fn Hasher::finalize(self : Hasher) -> Int {
  self.avalanche()
}

///|
fn Hasher::avalanche(self : Hasher) -> Int {
  let mut acc = self.acc.reinterpret_as_uint()
  acc = acc ^ (acc >> 15)
  acc *= gPRIME2
  acc = acc ^ (acc >> 13)
  acc *= gPRIME3
  acc = acc ^ (acc >> 16)
  acc.reinterpret_as_int()
}

///|
fn Hasher::consume4(self : Hasher, input : Int) -> Unit {
  let tmp = self.acc.reinterpret_as_uint() +
    input.reinterpret_as_uint() * gPRIME3
  let tmp = rotl(tmp.reinterpret_as_int(), 17).reinterpret_as_uint()
  let tmp = tmp * gPRIME4
  self.acc = tmp.reinterpret_as_int()
}

///|
fn Hasher::consume1(self : Hasher, input : Byte) -> Unit {
  let tmp = self.acc.reinterpret_as_uint() + input.to_uint() * gPRIME5
  let tmp = rotl(tmp.reinterpret_as_int(), 11).reinterpret_as_uint() * gPRIME1
  self.acc = tmp.reinterpret_as_int()
}

///|
fn rotl(x : Int, r : Int) -> Int {
  ((x.reinterpret_as_uint() << r) | (x.reinterpret_as_uint() >> (32 - r))).reinterpret_as_int()
}

///|
fn endian32(input : Bytes, cur : Int) -> Int {
  let tmp = input[cur + 0].to_uint() |
    (
      (input[cur + 1].to_uint() << 8) |
      (input[cur + 2].to_uint() << 16) |
      (input[cur + 3].to_uint() << 24)
    )
  tmp.reinterpret_as_int()
}

// pub impl Hash for String with hash(self) {
//   let hasher = Hasher::new()
//   hasher.combine(self)
//   hasher.finalize()
// }

///|
pub impl Hash for String with hash_combine(self, hasher) {
  hasher.combine_string(self)
}

///|
// https://github.com/skeeto/hash-prospector
pub impl Hash for Int with hash(self) {
  let self = self.reinterpret_as_uint()
  let mut x = self ^ (self >> 17)
  x = x * 0xed5ad4bb
  x = x ^ (x >> 11)
  x = x * 0xac4c1b51
  x = x ^ (x >> 15)
  x = x * 0x31848bab
  x = x ^ (x >> 14)
  x.reinterpret_as_int()
}

///|
pub impl Hash for Int with hash_combine(self, hasher) {
  hasher.combine_int(self)
}

///|
pub impl Hash for UInt with hash_combine(self, hasher) {
  hasher.combine_uint(self)
}

///|
pub impl Hash for UInt64 with hash_combine(self, hasher) {
  hasher.combine_uint64(self)
}

///|
pub impl[X : Hash] Hash for X? with hash_combine(self, hasher) {
  match self {
    None => hasher.combine_int(0)
    Some(x) => hasher..combine_int(1).combine(x)
  }
}

///|
pub impl[T : Hash, E : Hash] Hash for Result[T, E] with hash_combine(
  self,
  hasher
) {
  match self {
    Ok(x) => hasher..combine_int(0).combine(x)
    Err(x) => hasher..combine_int(1).combine(x)
  }
}
