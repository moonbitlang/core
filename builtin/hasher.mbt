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

///|
let gPRIME1 = 0x9E3779B1

///|
let gPRIME2 = 0x85EBCA77

///|
let gPRIME3 = 0xC2B2AE3D

///|
let gPRIME4 = 0x27D4EB2F

///|
let gPRIME5 = 0x165667B1

///|
/// xxhash32 Hasher
struct Hasher {
  mut acc : Int
}

///|
pub fn Hasher::new(~seed : Int = 0) -> Hasher {
  { acc: seed + gPRIME5 }
}

///|
pub fn combine[T : Hash](self : Hasher, value : T) -> Unit {
  value.hash_combine(self)
}

///|
pub fn combine_unit(self : Hasher) -> Unit {
  self.combine_int(0)
}

///|
pub fn combine_bool(self : Hasher, value : Bool) -> Unit {
  self.combine_int(if value { 1 } else { 0 })
}

///|
pub fn combine_int(self : Hasher, value : Int) -> Unit {
  self.acc += 4
  self.consume4(value)
}

///|
pub fn combine_int64(self : Hasher, value : Int64) -> Unit {
  self.acc += 8
  self.consume4(value.to_int())
  self.consume4((value.reinterpret_as_uint64() >> 32).to_int())
}

///|
pub fn combine_uint(self : Hasher, value : UInt) -> Unit {
  self.combine_int(value.reinterpret_as_int())
}

///|
pub fn combine_uint64(self : Hasher, value : UInt64) -> Unit {
  self.combine_int64(value.reinterpret_as_int64())
}

///|
pub fn combine_double(self : Hasher, value : Double) -> Unit {
  self.combine_int64(value.reinterpret_as_int64())
}

///|
pub fn combine_byte(self : Hasher, value : Byte) -> Unit {
  self.consume1(value)
}

///|
pub fn combine_bytes(self : Hasher, value : Bytes) -> Unit {
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
pub fn combine_string(self : Hasher, value : String) -> Unit {
  for i = 0; i < value.length(); i = i + 1 {
    self.combine_int(value[i].to_int())
  }
}

///|
pub fn combine_char(self : Hasher, value : Char) -> Unit {
  self.combine_int(value.to_int())
}

///|
pub fn finalize(self : Hasher) -> Int {
  self.avalanche()
}

///|
fn avalanche(self : Hasher) -> Int {
  let mut acc = self.acc.reinterpret_as_uint()
  acc = acc ^ (acc >> 15)
  acc *= gPRIME2.reinterpret_as_uint()
  acc = acc ^ (acc >> 13)
  acc *= gPRIME3.reinterpret_as_uint()
  acc = acc ^ (acc >> 16)
  acc.reinterpret_as_int()
}

///|
fn consume4(self : Hasher, input : Int) -> Unit {
  self.acc = rotl(self.acc + input * gPRIME3, 17) * gPRIME4
}

///|
fn consume1(self : Hasher, input : Byte) -> Unit {
  self.acc = rotl(self.acc + input.to_int() * gPRIME5, 11) * gPRIME1
}

///|
fn rotl(x : Int, r : Int) -> Int {
  (x << r) | (x.reinterpret_as_uint() >> (32 - r)).reinterpret_as_int()
}

///|
fn endian32(input : Bytes, cur : Int) -> Int {
  input[cur + 0].to_int() |
  (
    (input[cur + 1].to_int() << 8) |
    (input[cur + 2].to_int() << 16) |
    (input[cur + 3].to_int() << 24)
  )
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
