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
/// Represents a hasher that implements the xxHash32 algorithm. The hasher
/// maintains a mutable accumulator that is updated with each value added to the
/// hash computation.
///
/// This struct provides methods for combining different types of values into a
/// single hash value, making it suitable for implementing hash functions for
/// custom types.
///
/// Example:
///
/// ```moonbit
/// test "Hasher/basic" {
///   let hasher = Hasher::new()
///   hasher.combine_int(42)
///   hasher.combine_string("hello")
///   inspect!(hasher.finalize(), content="860601284")
/// }
/// ```
struct Hasher {
  mut acc : Int
}

///|
/// Creates a new hasher with an optional seed value.
///
/// Parameters:
///
/// * `seed` : An integer value used to initialize the hasher's internal state.
/// Defaults to 0.
///
/// Returns a new `Hasher` instance initialized with the given seed value.
///
/// Example:
///
/// ```moonbit
/// test "Hasher::new" {
///   let h1 = Hasher::new() // Create a hasher with default seed
///   let h2 = Hasher::new(seed=42) // Create a hasher with custom seed
///   let x = 123
///   h1.combine(x)
///   h2.combine(x)
///   inspect!(h1.finalize() != h2.finalize(), content="true") // Different seeds produce different hashes
/// }
/// ```
pub fn Hasher::new(seed~ : Int = 0) -> Hasher {
  { acc: seed + gPRIME5 }
}

///|
/// Combines a hashable value with the current state of the hasher. This is
/// typically used to incrementally build a hash value from multiple components.
///
/// Parameters:
///
/// * `self` : The hasher instance to update.
/// * `value` : The value to be combined with the current hash state. Must
/// implement the `Hash` trait.
///
/// Example:
///
/// ```moonbit
/// test "Hasher::combine" {
///   let hasher = Hasher::new()
///   hasher.combine(42)
///   hasher.combine("hello")
///   inspect!(hasher.finalize(), content="860601284")
/// }
/// ```
pub fn Hasher::combine[T : Hash](self : Hasher, value : T) -> Unit {
  value.hash_combine(self)
}

///|
/// Combines the unit value (i.e., `()`) into the hasher's internal state by
/// hashing it as an integer value of 0.
///
/// Parameters:
///
/// * `hasher` : The hasher object to combine the unit value into.
///
/// Example:
///
/// ```moonbit
/// test "Hasher::combine_unit" {
///   let hasher = Hasher::new()
///   hasher.combine_unit()
///   inspect!(hasher.finalize(), content="148298089")
/// }
/// ```
pub fn Hasher::combine_unit(self : Hasher) -> Unit {
  self.combine_int(0)
}

///|
/// Combines a boolean value into the current hash state. The boolean value is
/// converted to an integer (1 for true, 0 for false) before being combined with
/// the hash.
///
/// Parameters:
///
/// * `self` : The hasher instance to update.
/// * `value` : The boolean value to be combined into the hash state.
///
/// Example:
///
/// ```moonbit
/// test "Hasher::combine_bool" {
///   let hasher = Hasher::new()
///   hasher.combine_bool(true)
///   inspect!(hasher.finalize(), content="-205818221")
/// }
/// ```
pub fn Hasher::combine_bool(self : Hasher, value : Bool) -> Unit {
  self.combine_int(if value { 1 } else { 0 })
}

///|
/// Combines a 32-bit integer value into the hasher's internal state. The value
/// is processed
/// as a 4-byte sequence, and the internal accumulator is updated accordingly.
///
/// Parameters:
///
/// * `self` : The hasher instance to update.
/// * `value` : A 32-bit integer value to be incorporated into the hash.
///
/// Example:
///
/// ```moonbit
/// test "Hasher::combine_int" {
///   let hasher = Hasher::new()
///   hasher.combine_int(42)
///   inspect!(hasher.finalize(), content="1161967057")
/// }
/// ```
pub fn Hasher::combine_int(self : Hasher, value : Int) -> Unit {
  self.acc += 4
  self.consume4(value)
}

///|
/// Combines a 64-bit integer value into the hash state by splitting it into two
/// 32-bit parts and processing them separately. This method is used internally
/// by the hash implementation to incorporate 64-bit integers into the hash
/// computation.
///
/// Parameters:
///
/// * `hasher` : The hasher object whose internal state will be updated.
/// * `value` : The 64-bit integer value to be incorporated into the hash state.
///
/// Example:
///
/// ```moonbit
/// test "Hasher::combine_int64" {
///   let hasher = Hasher::new()
///   hasher.combine_int64(42L)
///   inspect!(hasher.finalize(), content="-1962516083")
/// }
/// ```
pub fn Hasher::combine_int64(self : Hasher, value : Int64) -> Unit {
  self.acc += 8
  self.consume4(value.to_int())
  self.consume4((value.reinterpret_as_uint64() >> 32).to_int())
}

///|
/// Combines an unsigned 32-bit integer into the hasher's internal state by
/// reinterpreting it as a signed integer and incorporating it into the hash
/// computation.
///
/// Parameters:
///
/// * `hasher` : The hasher object to update.
/// * `value` : The unsigned 32-bit integer value to be combined into the hash.
///
/// Example:
///
/// ```moonbit
/// test "Hasher::combine_uint" {
///   let hasher = Hasher::new()
///   hasher.combine_uint(42U)
///   inspect!(hasher.finalize(), content="1161967057")
/// }
/// ```
pub fn Hasher::combine_uint(self : Hasher, value : UInt) -> Unit {
  self.combine_int(value.reinterpret_as_int())
}

///|
/// Combines a 64-bit unsigned integer into the hasher's internal state. Useful
/// for hashing `UInt64` values as part of a larger composite structure.
///
/// Parameters:
///
/// * `self` : The hasher instance to update.
/// * `value` : The 64-bit unsigned integer value to be incorporated into the
/// hash.
///
/// Example:
///
/// ```moonbit
/// test "Hasher::combine_uint64" {
///   let hasher = Hasher::new()
///   hasher.combine_uint64(42UL)
///   inspect!(hasher.finalize(), content="-1962516083")
/// }
/// ```
pub fn Hasher::combine_uint64(self : Hasher, value : UInt64) -> Unit {
  self.combine_int64(value.reinterpret_as_int64())
}

///|
/// Combines a double-precision floating-point number into the hasher's internal
/// state by reinterpreting its bits as a 64-bit integer. Maintains consistent
/// hashing behavior regardless of the floating-point value's representation.
///
/// Parameters:
///
/// * `hasher` : The hasher to combine the value into.
/// * `value` : The double-precision floating-point number to be combined into
/// the hash.
///
/// Example:
///
/// ```moonbit
/// test "Hasher::combine_double" {
///   let hasher = Hasher::new()
///   hasher.combine_double(3.14)
///   inspect!(hasher.finalize(), content="-428265677")
/// }
/// ```
pub fn Hasher::combine_double(self : Hasher, value : Double) -> Unit {
  self.combine_int64(value.reinterpret_as_int64())
}

///|
/// Combines a 32-bit floating-point value into the hasher by reinterpreting its
/// bit pattern as a 32-bit integer. The operation maintains the same hash result
/// regardless of the floating-point value's representation.
///
/// Parameters:
///
/// * `hasher` : The hasher object that maintains the internal state of the
/// hashing operation.
/// * `value` : The 32-bit floating-point value to be combined into the hash.
///
/// Example:
///
/// ```moonbit
/// test "Hasher::combine_float" {
///   let hasher = Hasher::new()
///   hasher.combine_float(3.14)
///   inspect!(hasher.finalize(), content="635116317") // Hash of the bits of 3.14
/// }
/// ```
pub fn Hasher::combine_float(self : Hasher, value : Float) -> Unit {
  self.combine_int(value.reinterpret_as_int())
}

///|
/// Combines a byte value into the hash state.
///
/// Parameters:
///
/// * `hasher` : The hasher object to update with the byte value.
/// * `byte` : The byte value to be combined into the hash.
///
/// Example:
///
/// ```moonbit
/// test "Hasher::combine_byte" {
///   let hasher = Hasher::new()
///   hasher.combine_byte(b'\xFF')
///   inspect!(hasher.finalize(), content="1955036104")
/// }
/// ```
pub fn Hasher::combine_byte(self : Hasher, value : Byte) -> Unit {
  self.consume1(value)
}

///|
/// Combines a byte sequence into the hasher's internal state using xxHash32
/// algorithm. Processes the input bytes in chunks of 4 bytes for efficiency,
/// with remaining bytes processed individually.
///
/// Parameters:
///
/// * `hasher` : The hasher object to update with the byte sequence.
/// * `bytes` : The byte sequence to be combined into the hash.
///
/// Example:
///
/// ```moonbit
/// test "Hasher::combine_bytes" {
///   let hasher = Hasher::new()
///   hasher.combine_bytes(b"\xFF\x00\xFF\x00")
///   inspect!(hasher.finalize(), content="-686861102")
/// }
/// ```
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
/// Combines a string value into the current hash state by processing each
/// character in the string sequentially.
///
/// Parameters:
///
/// * `self` : The hasher object whose state will be updated.
/// * `value` : The string value to be combined into the hash state.
///
/// Example:
///
/// ```moonbit
/// test "Hasher::combine_string" {
///   let hasher = Hasher::new()
///   hasher.combine_string("hello")
///   inspect!(hasher.finalize(), content="-655549713")
/// }
/// ```
pub fn Hasher::combine_string(self : Hasher, value : String) -> Unit {
  for i = 0; i < value.length(); i = i + 1 {
    self.combine_int(value[i].to_int())
  }
}

///|
/// Combines a character value into the hasher's internal state. The character is
/// first converted to its Unicode code point (as an integer) before being
/// combined.
///
/// Parameters:
///
/// * `self` : The hasher instance to update.
/// * `value` : The character value to be combined into the hash state.
///
/// Example:
///
/// ```moonbit
/// test "Hasher::combine_char" {
///   let hasher = Hasher::new()
///   hasher.combine_char('A')
///   inspect!(hasher.finalize(), content="-1625495534")
/// }
/// ```
pub fn Hasher::combine_char(self : Hasher, value : Char) -> Unit {
  self.combine_int(value.to_int())
}

///|
/// Finalizes the hashing process and returns the computed hash value. Applies an
/// avalanche function to improve the distribution of the hash value.
///
/// Parameters:
///
/// * `hasher` : The hasher object containing the accumulated hash state.
///
/// Returns a 32-bit integer representing the final hash value.
///
/// Example:
///
/// ```moonbit
/// test "Hasher::finalize" {
///   let hasher = Hasher::new()
///   hasher.combine_byte(b'\xFF')
///   inspect!(hasher.finalize(), content="1955036104")
/// }
/// ```
pub fn Hasher::finalize(self : Hasher) -> Int {
  self.avalanche()
}

///|
fn Hasher::avalanche(self : Hasher) -> Int {
  let mut acc = self.acc.reinterpret_as_uint()
  acc = acc ^ (acc >> 15)
  acc *= gPRIME2.reinterpret_as_uint()
  acc = acc ^ (acc >> 13)
  acc *= gPRIME3.reinterpret_as_uint()
  acc = acc ^ (acc >> 16)
  acc.reinterpret_as_int()
}

///|
fn Hasher::consume4(self : Hasher, input : Int) -> Unit {
  self.acc = rotl(self.acc + input * gPRIME3, 17) * gPRIME4
}

///|
fn Hasher::consume1(self : Hasher, input : Byte) -> Unit {
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
/// Implements the `Hash` trait for `String` type, providing a method to combine
/// a string's hash value with a hasher's state.
///
/// Parameters:
///
/// * `self` : The string value to be hashed.
/// * `hasher` : The hasher object that will be updated with the string's hash
/// value.
///
/// Example:
///
/// ```moonbit
/// test "String::hash" {
///   let s1 = "hello"
///   let s2 = "hello"
///   let s3 = "world"
///   inspect!(Hash::hash(s1) == Hash::hash(s2), content="true")
///   inspect!(Hash::hash(s1) == Hash::hash(s3), content="false")
/// }
/// ```
pub impl Hash for String with hash_combine(self, hasher) {
  hasher.combine_string(self)
}

///|
/// Implements the `Hash` trait for integer values using a combination of shifts
/// and multiplications to produce a well-distributed hash value. Based on the
/// hash algorithm from hash-prospector
/// (https://github.com/skeeto/hash-prospector).
///
/// Parameters:
///
/// * `integer` : The integer value to be hashed. The value will be reinterpreted
/// as an unsigned integer before hashing to ensure consistent behavior across
/// positive and negative values.
///
/// Returns a 32-bit hash value derived from the input integer.
///
/// Example:
///
/// ```moonbit
/// test "Int::hash" {
///   let x = 42
///   inspect!(Hash::hash(x), content="-1704501356")
///   let y = -42
///   inspect!(Hash::hash(y), content="1617647962")
/// }
/// ```
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
/// Implements hash combination for integers by combining the integer value with
/// a hasher. This implementation ensures that integers can be used as keys in
/// hash-based collections like hash maps and hash sets.
///
/// Parameters:
///
/// * `self` : The integer value to be hashed.
/// * `hasher` : A `Hasher` object that accumulates the hash value.
///
/// Example:
///
/// ```moonbit
/// test "Int::hash_combine" {
///   let hasher = Hasher::new()
///   hasher.combine_int(42)
///   inspect!(hasher.finalize(), content="1161967057")
/// }
/// ```
pub impl Hash for Int with hash_combine(self, hasher) {
  hasher.combine_int(self)
}

///|
/// Combines the hash value of an unsigned integer with a hasher object. This is
/// useful when you need to hash a data structure that contains unsigned
/// integers.
///
/// Parameters:
///
/// * `value` : The unsigned integer to be combined with the hasher.
/// * `hasher` : The hasher object that will incorporate the hash value of the
/// unsigned integer.
///
/// Example:
///
/// ```moonbit
/// test "UInt::hash_combine" {
///   let hasher = Hasher::new()
///   hasher.combine_uint(42U)
///   inspect!(hasher.finalize(), content="1161967057")
/// }
/// ```
pub impl Hash for UInt with hash_combine(self, hasher) {
  hasher.combine_uint(self)
}

///|
/// Implements the `Hash` trait for `UInt64` by combining the hash value of an
/// unsigned 64-bit integer into a hasher.
///
/// Parameters:
///
/// * `self` : The unsigned 64-bit integer value to be hashed.
/// * `hasher` : The hasher object used to compute the combined hash value.
///
/// Example:
///
/// ```moonbit
/// test "UInt64::hash_combine" {
///   let hasher = Hasher::new()
///   hasher.combine_uint64(42UL)
///   inspect!(hasher.finalize(), content="-1962516083")
/// }
/// ```
pub impl Hash for UInt64 with hash_combine(self, hasher) {
  hasher.combine_uint64(self)
}

///|
/// Implements the `Hash` trait for `Option` types, allowing them to be used as
/// keys in hash-based collections.
///
/// Parameters:
///
/// * `self` : The `Option` value to be hashed.
/// * `hasher` : The hasher object that accumulates the hash state.
///
/// Example:
///
/// ```moonbit
/// test "Option::hash_combine" {
///   let hasher = Hasher::new()
///   let some_value : Int? = Some(42)
///   let none_value : Int? = None
///   hasher.combine(some_value)
///   inspect!(hasher.finalize(), content="2103260413")
///   let hasher2 = Hasher::new()
///   hasher2.combine(none_value)
///   inspect!(hasher2.finalize(), content="148298089")
/// }
/// ```
pub impl[X : Hash] Hash for X? with hash_combine(self, hasher) {
  match self {
    None => hasher.combine_int(0)
    Some(x) => hasher..combine_int(1).combine(x)
  }
}

///|
/// Implements the `Hash` trait for `Result` type, allowing `Result` values to be
/// used in hash-based collections.
///
/// Parameters:
///
/// * `self` : The `Result` value to be hashed.
/// * `hasher` : The hasher object to which the hash value will be combined.
///
/// Example:
///
/// ```moonbit
/// test "Result::hash_combine" {
///   let hasher = Hasher::new()
///   let ok_result : Result[Int, String] = Ok(42)
///   let err_result : Result[Int, String] = Err("error")
///   hasher.combine(ok_result)
///   inspect!(hasher.finalize(), content="-1948635851")
///   let hasher = Hasher::new()
///   hasher.combine(err_result)
///   inspect!(hasher.finalize(), content="1953766574")
/// }
/// ```
pub impl[T : Hash, E : Hash] Hash for Result[T, E] with hash_combine(
  self,
  hasher
) {
  match self {
    Ok(x) => hasher..combine_int(0).combine(x)
    Err(x) => hasher..combine_int(1).combine(x)
  }
}
