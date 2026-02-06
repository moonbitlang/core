// Copyright 2026 International Digital Economy Academy
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
const GPRIME1 : UInt = 0x9E3779B1

///|
const GPRIMES2 : UInt = 0x85EBCA77

///|
const GPRIME3 : UInt = 0xC2B2AE3D

///|
const GPRIME4 : UInt = 0x27D4EB2F

///|
const GPRIME5 : UInt = 0x165667B1

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
/// ```mbt check
/// test {
///   let hasher = Hasher::new(seed=0)
///   hasher.combine_int(42)
///   hasher.combine_string("hello")
///   inspect(hasher.finalize(), content=(
///   #|-1929254126
/// ))
/// }
/// ```
struct Hasher {
  seed : UInt
  mut total_len : Int
  mut v1 : UInt
  mut v2 : UInt
  mut v3 : UInt
  mut v4 : UInt
  mut memsize : Int
  mut mem : FixedArray[Byte]
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
/// ```mbt check
/// test {
///   let h1 = Hasher::new(seed=0) // Create a hasher with default seed
///   let h2 = Hasher::new(seed=42) // Create a hasher with custom seed
///   let x = 123
///   h1.combine(x)
///   h2.combine(x)
///   inspect(h1.finalize() != h2.finalize(), content="true") // Different seeds produce different hashes
/// }
/// ```
pub fn Hasher::new(seed? : Int = seed) -> Hasher {
  let seed = seed.reinterpret_as_uint()
  {
    seed,
    total_len: 0,
    v1: seed + GPRIME1 + GPRIMES2,
    v2: seed + GPRIMES2,
    v3: seed,
    v4: seed - GPRIME1,
    memsize: 0,
    mem: FixedArray::make(16, 0),
  }
}

///|
#cfg(not(target="js"))
let seed : Int = 0

///|
#cfg(target="js")
let seed : Int = random_seed()

///|
#cfg(target="js")
extern "js" fn random_seed() -> Int =
  #|() => {
  #|  if (globalThis.crypto?.getRandomValues) {
  #|    const array = new Uint32Array(1);
  #|    globalThis.crypto.getRandomValues(array);
  #|    return array[0] | 0; // Convert to signed 32
  #|  } else {
  #|    return Math.floor(Math.random() * 0x100000000) | 0; // Fallback to Math.random
  #|  }
  #|}

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
/// ```mbt check
/// test {
///   let hasher = Hasher::new(seed=0)
///   hasher.combine(42)
///   hasher.combine("hello")
///   inspect(hasher.finalize(), content=(
///   #|-1929254126
/// ))
/// }
/// ```
pub fn[T : Hash] Hasher::combine(self : Hasher, value : T) -> Unit {
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
/// ```mbt check
/// test {
///   let hasher = Hasher::new(seed=0)
///   hasher.combine_unit()
///   inspect(hasher.finalize(), content="148298089")
/// }
/// ```
pub fn Hasher::combine_unit(self : Hasher) -> Unit {
  self.combine_uint(0)
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
/// ```mbt check
/// test {
///   let hasher = Hasher::new(seed=0)
///   hasher.combine_bool(true)
///   inspect(hasher.finalize(), content="-205818221")
/// }
/// ```
pub fn Hasher::combine_bool(self : Hasher, value : Bool) -> Unit {
  self.combine_uint(if value { 1 } else { 0 })
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
/// ```mbt check
/// test {
///   let hasher = Hasher::new(seed=0)
///   hasher.combine_int(42)
///   inspect(hasher.finalize(), content="1161967057")
/// }
/// ```
pub fn Hasher::combine_int(self : Hasher, value : Int) -> Unit {
  self.combine_uint(value.reinterpret_as_uint())
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
/// ```mbt check
/// test {
///   let hasher = Hasher::new(seed=0)
///   hasher.combine_int64(42L)
///   inspect(hasher.finalize(), content="-1962516083")
/// }
/// ```
pub fn Hasher::combine_int64(self : Hasher, value : Int64) -> Unit {
  self.combine_uint64(value.reinterpret_as_uint64())
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
/// ```mbt check
/// test {
///   let hasher = Hasher::new(seed=0)
///   hasher.combine_uint(42U)
///   inspect(hasher.finalize(), content="1161967057")
/// }
/// ```
pub fn Hasher::combine_uint(self : Hasher, value : UInt) -> Unit {
  self.push_byte((value & 0xFFU).to_byte())
  self.push_byte(((value >> 8) & 0xFFU).to_byte())
  self.push_byte(((value >> 16) & 0xFFU).to_byte())
  self.push_byte(((value >> 24) & 0xFFU).to_byte())
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
/// ```mbt check
/// test {
///   let hasher = Hasher::new(seed=0)
///   hasher.combine_uint64(42UL)
///   inspect(hasher.finalize(), content="-1962516083")
/// }
/// ```
pub fn Hasher::combine_uint64(self : Hasher, value : UInt64) -> Unit {
  self.push_byte((value & 0xFFUL).to_uint().to_byte())
  self.push_byte(((value >> 8) & 0xFFUL).to_uint().to_byte())
  self.push_byte(((value >> 16) & 0xFFUL).to_uint().to_byte())
  self.push_byte(((value >> 24) & 0xFFUL).to_uint().to_byte())
  self.push_byte(((value >> 32) & 0xFFUL).to_uint().to_byte())
  self.push_byte(((value >> 40) & 0xFFUL).to_uint().to_byte())
  self.push_byte(((value >> 48) & 0xFFUL).to_uint().to_byte())
  self.push_byte(((value >> 56) & 0xFFUL).to_uint().to_byte())
}

///|
fn Hasher::combine_uint16(self : Hasher, value : UInt16) -> Unit {
  self.push_byte((value & 0xFF).to_byte())
  self.push_byte(((value >> 8) & 0xFF).to_byte())
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
/// ```mbt check
/// test {
///   let hasher = Hasher::new(seed=0)
///   hasher.combine_double(3.14)
///   inspect(hasher.finalize(), content="-428265677")
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
/// ```mbt check
/// test {
///   let hasher = Hasher::new(seed=0)
///   hasher.combine(3.14F)
///   inspect(hasher.finalize(), content="635116317") // Hash of the bits of 3.14
/// }
/// ```
#deprecated
pub fn Hasher::combine_float(self : Hasher, value : Float) -> Unit {
  self.combine_uint(value.reinterpret_as_uint())
}

///|
fn Float::reinterpret_as_uint(self : Float) -> UInt = "%f32.to_i32_reinterpret"

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
/// ```mbt check
/// test {
///   let hasher = Hasher::new(seed=0)
///   hasher.combine_byte(b'\xFF')
///   inspect(hasher.finalize(), content=(
///   #|-1766008628
/// ))
/// }
/// ```
pub fn Hasher::combine_byte(self : Hasher, value : Byte) -> Unit {
  self.push_byte(value)
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
/// ```mbt check
/// test {
///   let hasher = Hasher::new(seed=0)
///   hasher.combine_bytes(b"\xFF\x00\xFF\x00")
///   inspect(hasher.finalize(), content=(
///   #|-771288068
/// ))
/// }
/// ```
pub fn Hasher::combine_bytes(self : Hasher, value : Bytes) -> Unit {
  self.update_bytes(value, 0, value.length())
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
/// ```mbt check
/// test {
///   let hasher = Hasher::new(seed=0)
///   hasher.combine_string("hello")
///   inspect(hasher.finalize(), content=(
///   #|-1916221897
/// ))
/// }
/// ```
pub fn Hasher::combine_string(self : Hasher, value : String) -> Unit {
  for i in 0..<value.length() {
    self.combine_uint16(value.unsafe_get(i))
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
/// ```mbt check
/// test {
///   let hasher = Hasher::new(seed=0)
///   hasher.combine_char('A')
///   inspect(hasher.finalize(), content="-1625495534")
/// }
/// ```
pub fn Hasher::combine_char(self : Hasher, value : Char) -> Unit {
  self.combine_uint(value.to_uint())
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
/// ```mbt check
/// test {
///   let hasher = Hasher::new(seed=0)
///   hasher.combine_byte(b'\xFF')
///   inspect(hasher.finalize(), content=(
///   #|-1766008628
/// ))
/// }
/// ```
pub fn Hasher::finalize(self : Hasher) -> Int {
  let mut acc = if self.total_len >= 16 {
    let mut acc = rotl(self.v1, 1) +
      rotl(self.v2, 7) +
      rotl(self.v3, 12) +
      rotl(self.v4, 18)
    acc = xxh32_merge_round(acc, self.v1)
    acc = xxh32_merge_round(acc, self.v2)
    acc = xxh32_merge_round(acc, self.v3)
    xxh32_merge_round(acc, self.v4)
  } else {
    self.seed + GPRIME5
  }
  acc += self.total_len.reinterpret_as_uint()
  let mut i = 0
  while i + 4 <= self.memsize {
    acc += read_u32_from_mem(self.mem, i) * GPRIME3
    acc = rotl(acc, 17) * GPRIME4
    i += 4
  }
  while i < self.memsize {
    acc += self.mem[i].to_uint() * GPRIME5
    acc = rotl(acc, 11) * GPRIME1
    i += 1
  }
  xxh32_avalanche(acc).reinterpret_as_int()
}

///|
fn xxh32_avalanche(acc : UInt) -> UInt {
  let mut acc = acc
  acc = acc ^ (acc >> 15)
  acc *= GPRIMES2
  acc = acc ^ (acc >> 13)
  acc *= GPRIME3
  acc = acc ^ (acc >> 16)
  acc
}

///|
fn xxh32_round(acc : UInt, input : UInt) -> UInt {
  rotl(acc + input * GPRIMES2, 13) * GPRIME1
}

///|
fn xxh32_merge_round(acc : UInt, value : UInt) -> UInt {
  let mut acc = acc ^ xxh32_round(0, value)
  acc = acc * GPRIME1 + GPRIME4
  acc
}

///|
fn Hasher::process_mem_block(self : Hasher) -> Unit {
  self.v1 = xxh32_round(self.v1, read_u32_from_mem(self.mem, 0))
  self.v2 = xxh32_round(self.v2, read_u32_from_mem(self.mem, 4))
  self.v3 = xxh32_round(self.v3, read_u32_from_mem(self.mem, 8))
  self.v4 = xxh32_round(self.v4, read_u32_from_mem(self.mem, 12))
}

///|
fn Hasher::push_byte(self : Hasher, value : Byte) -> Unit {
  self.total_len += 1
  self.mem[self.memsize] = value
  self.memsize += 1
  if self.memsize == 16 {
    self.process_mem_block()
    self.memsize = 0
  }
}

///|
fn Hasher::update_bytes(
  self : Hasher,
  bytes : Bytes,
  start : Int,
  len : Int,
) -> Unit {
  guard len > 0 else { return }
  self.total_len += len
  let mut idx = 0
  if self.memsize + len < 16 {
    for i in 0..<len {
      self.mem[self.memsize + i] = bytes.unsafe_get(start + i)
    }
    self.memsize += len
    return
  }
  if self.memsize > 0 {
    let fill = 16 - self.memsize
    for i in 0..<fill {
      self.mem[self.memsize + i] = bytes.unsafe_get(start + i)
    }
    self.process_mem_block()
    self.memsize = 0
    idx = fill
  }
  while idx + 16 <= len {
    self.v1 = xxh32_round(self.v1, read_u32_from_bytes(bytes, start + idx + 0))
    self.v2 = xxh32_round(self.v2, read_u32_from_bytes(bytes, start + idx + 4))
    self.v3 = xxh32_round(self.v3, read_u32_from_bytes(bytes, start + idx + 8))
    self.v4 = xxh32_round(self.v4, read_u32_from_bytes(bytes, start + idx + 12))
    idx += 16
  }
  if idx < len {
    let remain = len - idx
    for i in 0..<remain {
      self.mem[i] = bytes.unsafe_get(start + idx + i)
    }
    self.memsize = remain
  }
}

///|
fn rotl(x : UInt, r : Int) -> UInt {
  (x << r) | (x >> (32 - r))
}

///|
fn read_u32_from_bytes(input : Bytes, cur : Int) -> UInt {
  input[cur + 0].to_uint() |
  (
    (input[cur + 1].to_uint() << 8) |
    (input[cur + 2].to_uint() << 16) |
    (input[cur + 3].to_uint() << 24)
  )
}

///|
fn read_u32_from_mem(input : FixedArray[Byte], cur : Int) -> UInt {
  input[cur + 0].to_uint() |
  (
    (input[cur + 1].to_uint() << 8) |
    (input[cur + 2].to_uint() << 16) |
    (input[cur + 3].to_uint() << 24)
  )
}

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
/// ```mbt check
/// test {
///   let s1 = "hello"
///   let s2 = "hello"
///   let s3 = "world"
///   inspect(Hash::hash(s1) == Hash::hash(s2), content="true")
///   inspect(Hash::hash(s1) == Hash::hash(s3), content="false")
/// }
/// ```
pub impl Hash for String with hash_combine(self, hasher) {
  hasher.combine_string(self)
}

///|
pub impl Hash for StringView with hash_combine(
  self : StringView,
  hasher : Hasher,
) -> Unit {
  let str = self.str()
  for i in self.start()..<self.end() {
    hasher.combine_uint16(str.unsafe_get(i))
  }
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
/// ```mbt check
/// test {
///   let hasher = Hasher::new(seed=0)
///   hasher.combine_int(42)
///   inspect(hasher.finalize(), content="1161967057")
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
/// ```mbt check
/// test {
///   let hasher = Hasher::new(seed=0)
///   hasher.combine_uint(42U)
///   inspect(hasher.finalize(), content="1161967057")
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
/// ```mbt check
/// test {
///   let hasher = Hasher::new(seed=0)
///   hasher.combine_uint64(42UL)
///   inspect(hasher.finalize(), content="-1962516083")
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
/// ```mbt check
/// test {
///   let hasher = Hasher::new(seed=0)
///   let some_value : Int? = Some(42)
///   let none_value : Int? = None
///   hasher.combine(some_value)
///   inspect(hasher.finalize(), content=(
///   #|1892291193
/// ))
///   let hasher2 = Hasher::new(seed=0)
///   hasher2.combine(none_value)
///   inspect(hasher2.finalize(), content="148298089")
/// }
/// ```
pub impl[X : Hash] Hash for X? with hash_combine(self, hasher) {
  match self {
    None => hasher.combine_int(0)
    Some(x) => {
      hasher.combine_int(1)
      hasher.combine(x)
    }
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
/// ```mbt check
/// test {
///   let hasher = Hasher::new(seed=0)
///   let ok_result : Result[Int, String] = Ok(42)
///   let err_result : Result[Int, String] = Err("error")
///   hasher.combine(ok_result)
///   inspect(hasher.finalize(), content=(
///   #|-2139784891
/// ))
///   let hasher = Hasher::new(seed=0)
///   hasher.combine(err_result)
///   inspect(hasher.finalize(), content=(
///   #|-544046459
/// ))
/// }
/// ```
pub impl[T : Hash, E : Hash] Hash for Result[T, E] with hash_combine(
  self,
  hasher,
) {
  match self {
    Ok(x) => {
      hasher.combine_int(0)
      hasher.combine(x)
    }
    Err(x) => {
      hasher.combine_int(1)
      hasher.combine(x)
    }
  }
}

///|
pub impl Hash for BytesView with hash_combine(self : BytesView, hasher : Hasher) {
  hasher.update_bytes(self.bytes(), self.start(), self.len())
}
