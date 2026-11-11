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
let default_rand : Rand = Rand()

///|
/// Returns a non-negative pseudo-random `Int32` using a shared generator.
/// With a positive `limit`, the result is uniformly distributed in `0..<limit`.
/// If `limit` is omitted, the result is in `0..<2^31`.
/// Aborts if an explicitly supplied `limit` is zero or negative.
///
/// The generator uses platform entropy when available and a fixed default
/// seed otherwise. Calls advance the same generator.
/// Use `Rand::chacha8(seed~)` for an independent,
/// reproducible sequence.
/// The shared generator is not thread-safe; calls from multiple threads
/// require external synchronization.
///
/// # Example
/// ```mbt check
/// test {
///   let die = @random.int32(limit=6) + 1
///   inspect(die >= 1 && die <= 6, content="true")
/// }
/// ```
pub fn int32(limit? : Int32) -> Int32 {
  match limit {
    None => default_rand.int()
    Some(limit) => {
      guard limit > 0 else { abort("int32: limit must be positive") }
      default_rand.int(limit~)
    }
  }
}

///|
/// Returns a non-negative pseudo-random `Int64` using the shared generator
/// described in [int32]. With a positive `limit`, the result is uniformly
/// distributed in `0..<limit`. If omitted, the result is in `0..<2^63`.
/// Aborts if an explicitly supplied `limit` is zero or negative.
///
/// # Example
/// ```mbt check
/// test {
///   let value = @random.int64(limit=10L)
///   inspect(value >= 0L && value < 10L, content="true")
/// }
/// ```
pub fn int64(limit? : Int64) -> Int64 {
  match limit {
    None => default_rand.int64()
    Some(limit) => {
      guard limit > 0L else { abort("int64: limit must be positive") }
      default_rand.int64(limit~)
    }
  }
}

///|
/// Returns a pseudo-random `UInt32` using the shared generator
/// described in [int32]. With a positive `limit`, the result is uniformly
/// distributed in `0..<limit`. If omitted, the result is in `0..<2^32`.
/// Aborts if an explicitly supplied `limit` is zero.
///
/// # Example
/// ```mbt check
/// test {
///   let value = @random.uint32(limit=10U)
///   inspect(value < 10U, content="true")
/// }
/// ```
pub fn uint32(limit? : UInt32) -> UInt32 {
  match limit {
    None => default_rand.uint()
    Some(limit) => {
      guard limit > 0U else { abort("uint32: limit must be positive") }
      default_rand.uint(limit~)
    }
  }
}

///|
/// Returns a pseudo-random `UInt64` using the shared generator
/// described in [int32]. With a positive `limit`, the result is uniformly
/// distributed in `0..<limit`. If omitted, the result is in `0..<2^64`.
/// Aborts if an explicitly supplied `limit` is zero.
///
/// # Example
/// ```mbt check
/// test {
///   let value = @random.uint64(limit=10UL)
///   inspect(value < 10UL, content="true")
/// }
/// ```
pub fn uint64(limit? : UInt64) -> UInt64 {
  match limit {
    None => default_rand.uint64()
    Some(limit) => {
      guard limit > 0UL else { abort("uint64: limit must be positive") }
      default_rand.uint64(limit~)
    }
  }
}

///|
/// Returns a pseudo-random `Double` in `[min, max)` using the shared generator
/// described in [int32]. The bounds default to `0.0` and `1.0`.
/// Uses the same sampling and bound validation as [Rand::double]: bounds
/// must be finite, `min < max`, and non-zero bounds must have magnitude at
/// least `4 * @double.min_positive`. Aborts if scaling a bound underflows.
///
/// # Example
/// ```mbt check
/// test {
///   let value = @random.double(min=-2.0, max=3.0)
///   inspect(value >= -2.0 && value < 3.0, content="true")
/// }
/// ```
pub fn double(min~ : Double = 0.0, max~ : Double = 1.0) -> Double {
  default_rand.double(min~, max~)
}

///|
/// Returns a pseudo-random `Float` in `[min, max)` using the shared generator
/// described in [int32]. The bounds default to `0.0F` and `1.0F`.
/// Uses the same sampling and bound validation as [Rand::float]: bounds
/// must be finite, `min < max`, and non-zero bounds must have magnitude at
/// least `4 * @float.min_positive`.
///
/// # Example
/// ```mbt check
/// test {
///   let value = @random.float(min=-2.0F, max=3.0F)
///   inspect(value >= -2.0F && value < 3.0F, content="true")
/// }
/// ```
pub fn float(
  min~ : @float.Float = 0.0F,
  max~ : @float.Float = 1.0F,
) -> @float.Float {
  default_rand.float(min~, max~)
}

///|
/// Returns a pseudo-random boolean with equal probability of `true` and
/// `false`, using the shared generator described in [int32].
///
/// # Example
/// ```mbt check
/// test {
///   let coin = if @random.boolean() { "heads" } else { "tails" }
///   inspect(coin == "heads" || coin == "tails", content="true")
/// }
/// ```
pub fn boolean() -> Bool {
  default_rand.boolean()
}

///|
/// Returns a non-negative pseudo-random `BigInt` with at most `bits` bits,
/// using the shared generator described in [int32]. Leading zero bits are
/// allowed. The `bits` parameter is an `Int32` bit count, so `bigint(128)`
/// returns a value in `0..<2^128`. Zero bits returns zero; negative bits abort.
///
/// # Example
/// ```mbt check
/// test {
///   let value = @random.bigint(128)
///   inspect(value >= 0N && value.bit_length() <= 128, content="true")
/// }
/// ```
pub fn bigint(bits : Int32) -> @bigint.BigInt {
  guard bits >= 0 else { abort("bigint: bits must be non-negative") }
  default_rand.bigint(bits)
}

///|
/// Shuffles `limit` elements using Fisher-Yates and the shared generator
/// described in [int32]. The callback swaps the elements at its two indices,
/// both in `0..<limit`. Zero or one elements require no swaps.
/// Aborts if `limit` is negative.
///
/// # Example
/// ```mbt check
/// test {
///   let values = [1, 2, 3, 4, 5]
///   @random.shuffle(values.length(), (i, j) => {
///     let tmp = values[i]
///     values[i] = values[j]
///     values[j] = tmp
///   })
///   values.sort()
///   debug_inspect(values, content="[1, 2, 3, 4, 5]")
/// }
/// ```
pub fn shuffle(limit : Int32, swap : (Int32, Int32) -> Unit) -> Unit {
  default_rand.shuffle(limit, swap)
}
