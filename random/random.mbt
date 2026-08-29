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
/// `Rand` is a pseudo-random number generator (PRNG) that provides various
/// methods to generate random numbers of different types.
struct Rand(&Source)

///|
/// The [Source] trait defines a method to generate random numbers.
pub(open) trait Source {
  fn next(Self) -> UInt64
}

///|
impl Source for @random_source.ChaCha8 with fn next(
  self : @random_source.ChaCha8,
) -> UInt64 {
  self.next_uint64()
}

///|
/// Create a new random number generator with [seed].
/// @alert unsafe "Panic if seed is not 32 bytes long"
pub fn Rand::chacha8(
  seed? : Bytes = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ123456",
) -> Rand {
  if seed.length() != 32 {
    abort("seed must be 32 bytes long")
  }
  Rand(@random_source.ChaCha8(seed) as &Source)
}

///|
let fixed_test_seed : Bytes = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ123456"

///|
/// Create a new random number generator with a given [Gen] source.
pub fn Rand::new(generator? : &Source) -> Rand {
  match generator {
    None =>
      match @env.rand(32) {
        Some(seed) => Rand::chacha8(seed~)
        None => Rand::chacha8()
      }
    Some(gen) => Rand(gen)
  }
}

///|
fn Rand::next(self : Rand) -> UInt64 {
  let Rand(s) = self
  s.next()
}

///|
test "next" {
  let r = Rand::chacha8(seed=fixed_test_seed)
  let n = r.next()
  let exp = 13219109469176600229UL
  @test.assert_eq(n, exp)
}

///|
/// [int] Return a non-negative pseudo-random 31-bit integer as an Int in the range [0, 2^31) or [0, limit) if limit is provided.
///
/// # Arguments
///
/// * `limit` - The upper bound (exclusive) of the random number to be generated (Optional).
///             When limit is 0, the range is [0, 2^31).
pub fn Rand::int(self : Rand, limit? : Int = 0) -> Int {
  if limit < 0 {
    abort("Rand::int: invalid argument limit")
  }
  if limit == 0 {
    // Range [0, 2^31)
    (self.next() >> 33).to_int()
  } else {
    self.uint(limit=limit.reinterpret_as_uint()).reinterpret_as_int()
  }
}

///|
/// [int64] returns a non-negative pseudo-random 63-bit integer as an Int64 in the range [0, 2^63)
///
/// # Arguments
///
/// * `limit` - The upper bound (exclusive) of the random number to be generated (Optional).
///            When limit is 0, the range is [0, 2^63).
pub fn Rand::int64(self : Rand, limit? : Int64 = 0) -> Int64 {
  if limit < 0 {
    abort("Rand::int64: invalid argument limit")
  }
  if limit == 0 {
    // range [0, 2^63)
    // Create a mask that keeps the lower 63 bits
    let mask : UInt64 = (1UL << 63) - 1UL
    return (self.next() & mask).reinterpret_as_int64()
  } else {
    self.uint64(limit=limit.reinterpret_as_uint64()).reinterpret_as_int64()
  }
}

///|
/// [uint] returns a non-negative pseudo-random 32-bit integer as a Uint in the range [0, 2^32) or [0, limit) if limit is provided.
///
/// # Arguments
///
/// * `limit` - The upper bound (exclusive) of the random number to be generated (Optional).
///            When limit is 0, the range is [0, 2^32).
pub fn Rand::uint(self : Rand, limit? : UInt = 0) -> UInt {
  if limit == 0 {
    // Range: [0, 2^32)
    return self.next().to_uint()
  }
  self.uint64(limit=limit.to_uint64()).to_uint()
}

///|
test "uint" {
  let r = Rand::chacha8(seed=fixed_test_seed)
  let n = r.uint(limit=10U)
  inspect(n, content="7")
  let n = r.uint(limit=10U)
  inspect(n, content="0")
  let n = r.uint(limit=10U)
  inspect(n, content="5")
}

///|
/// [uint64] returns a non-negative pseudo-random 64-bit integer as a Uint64 in the range [0, 2^64) or [0, limit) if limit is provided.
///
/// # Arguments
///
/// * `limit` - The upper bound (exclusive) of the random number to be generated (Optional).
///           When limit is 0, the range is [0, 2^64).
pub fn Rand::uint64(self : Rand, limit? : UInt64 = 0) -> UInt64 {
  if limit == 0 {
    // Range: [0, 2^64)
    return self.next()
  } else if (limit & (limit - 1)) == 0 {
    // limit is a power of 2, mask to get the unbiased result.
    return self.next() & (limit - 1)
  }
  let r = umul128(self.next(), limit)
  if r.lo >= limit {
    return r.hi
  }
  // In wrapping UInt64 arithmetic, ~limit + 1 is -limit modulo 2^64.
  let thresh = (limit.lnot() + 1) % limit
  for r = r; r.lo < thresh; {
    continue umul128(self.next(), limit)
  } nobreak {
    r.hi
  }
}

///|
test "UInt64" {
  let r = Rand::chacha8(seed=fixed_test_seed)
  let n = r.uint64()
  let exp = 13219109469176600229UL
  @test.assert_eq(n, exp)
  let r = Rand::chacha8(seed=fixed_test_seed)
  let n = r.uint64(limit=10UL)
  inspect(n, content="7")
  let n = r.uint64(limit=10UL)
  inspect(n, content="0")
  let n = r.uint64(limit=10UL)
  inspect(n, content="5")
}

///|
/// Returns a pseudo-random `Double` in the half-open interval `[min, max)`.
/// The bounds default to `0.0` and `1.0`; that interval uses the original
/// direct 53-bit construction. Other intervals use Goualard's corrected
/// gamma-section algorithm.
///
/// # Example
/// ```mbt check
/// test {
///   let rand = @random.Rand::chacha8()
///   let value = rand.double(min=-2.0, max=3.0)
///   inspect(value >= -2.0 && value < 3.0, content="true")
/// }
/// ```
///
/// # Panics
///
/// Panics if either bound is not finite, if `min >= max`, or if a non-zero
/// bound has magnitude below `4 * @double.min_positive`. It also panics if
/// dividing either bound by the selected gamma step would underflow.
pub fn Rand::double(
  self : Rand,
  min? : Double = 0.0,
  max? : Double = 1.0,
) -> Double {
  if min == 0.0 && max == 1.0 {
    Double::convert_uint64(self.next() << 11 >> 11) /
    Double::convert_uint64(1UL << 53)
  } else {
    self.double_in_range(min~, max~)
  }
}

///|
test "double" {
  let r = Rand::chacha8(seed=fixed_test_seed)
  let n = r.double()
  inspect(n, content="0.615969772029264")
}

///|
/// Returns a pseudo-random `Float` in the half-open interval `[min, max)`.
/// The bounds default to `0.0F` and `1.0F`; that interval uses the original
/// direct 24-bit construction. Other intervals use Goualard's corrected
/// gamma-section algorithm.
///
/// # Example
/// ```mbt check
/// test {
///   let rand = @random.Rand::chacha8()
///   let value = rand.float(min=-2.0F, max=3.0F)
///   inspect(value >= -2.0F && value < 3.0F, content="true")
/// }
/// ```
///
/// # Panics
///
/// Panics if either bound is not finite, if `min >= max`, or if a non-zero
/// bound has magnitude below `4 * @float.min_positive`.
pub fn Rand::float(
  self : Rand,
  min? : Float = 0.0F,
  max? : Float = 1.0F,
) -> Float {
  if min == 0.0F && max == 1.0F {
    Float::from_uint(self.uint() << 8 >> 8) / Float::from_uint(1U << 24)
  } else {
    self.float_in_range(min~, max~)
  }
}

///|
/// Returns the spacing from `anchor` to the adjacent value toward zero.
fn double_gamma(anchor : Double) -> Double {
  if anchor == 0.0 {
    1UL.reinterpret_as_double()
  } else {
    let toward_zero = (anchor.reinterpret_as_uint64() - 1).reinterpret_as_double()
    (anchor - toward_zero).abs()
  }
}

///|
/// Computes `ceil(scaled_max - scaled_min)` with Dekker's exact-sum residual.
/// When the rounded distance is an integer, the residual distinguishes it
/// from an exact value immediately above or below that integer.
fn ceil_sections(
  scaled_min : Double,
  scaled_max : Double,
  anchor_is_max~ : Bool,
) -> UInt64 {
  let distance = scaled_max - scaled_min
  let error = if anchor_is_max {
    -scaled_min - (distance - scaled_max)
  } else {
    scaled_max - (distance + scaled_min)
  }
  let ceiling = distance.ceil()
  let sections = ceiling.to_uint64()
  if distance != ceiling {
    sections
  } else if error > 0.0 {
    sections + error.ceil().to_uint64()
  } else {
    sections - (-error).floor().to_uint64()
  }
}

///|
/// Goualard v5 proves that the binary64 gamma-section count is less than
/// 2^55. Callers pass either k < sections or k - 1 < sections, so
/// `value < 2^55`. Splitting `value = 4 * high + low` therefore gives
/// `high < 2^53` and `low < 4`, making both UInt64-to-Double conversions exact.
fn split_uint64_for_double(value : UInt64) -> (Double, Double) {
  (Double::convert_uint64(value >> 2), Double::convert_uint64(value & 0x3))
}

///|
/// Returns the spacing from `anchor` to the adjacent value toward zero.
fn float_gamma(anchor : Float) -> Float {
  if anchor == 0.0F {
    Float::reinterpret_from_uint(1U)
  } else {
    let toward_zero = Float::reinterpret_from_uint(
      anchor.reinterpret_as_uint() - 1,
    )
    (anchor - toward_zero).abs()
  }
}

///|
/// Splitting by four leaves `high` below 2^24 for every binary32 interval, so
/// conversion to `Float` is exact.
fn split_uint64_for_float(value : UInt64) -> (Float, Float) {
  (Float::from_uint64(value >> 2), Float::from_uint64(value & 0x3))
}

///|
/// Implements the non-unit `Double` interval path.
fn Rand::double_in_range(self : Rand, min~ : Double, max~ : Double) -> Double {
  guard !(min.is_nan() || min.is_inf() || max.is_nan() || max.is_inf()) else {
    abort("Rand::double: bounds must be finite")
  }
  let underflow_threshold = 4.0 * @double.min_positive
  guard (min == 0.0 || min.abs() >= underflow_threshold) &&
    (max == 0.0 || max.abs() >= underflow_threshold) else {
    abort("Rand::double: bounds must be outside the underflow region")
  }
  guard min < max else { abort("Rand::double: min must be less than max") }
  let anchor_is_max = min.abs() <= max.abs()
  let gamma = double_gamma(if anchor_is_max { max } else { min })
  let scaled_min = min / gamma
  let scaled_max = max / gamma
  guard (min == 0.0 || scaled_min.abs() >= @double.min_positive) &&
    (max == 0.0 || scaled_max.abs() >= @double.min_positive) else {
    abort("Rand::double: scaling a bound would underflow")
  }
  let sections = ceil_sections(scaled_min, scaled_max, anchor_is_max~)
  let k = self.uint64(limit=sections) + 1
  if anchor_is_max {
    if k == sections {
      min
    } else {
      let (k_high, k_low) = split_uint64_for_double(k)
      4.0 * (max * 0.25 - k_high * gamma) - k_low * gamma
    }
  } else {
    let (k_high, k_low) = split_uint64_for_double(k - 1)
    4.0 * (min * 0.25 + k_high * gamma) + k_low * gamma
  }
}

///|
/// Implements the non-unit `Float` interval path.
fn Rand::float_in_range(self : Rand, min~ : Float, max~ : Float) -> Float {
  guard !(min.is_nan() || min.is_inf() || max.is_nan() || max.is_inf()) else {
    abort("Rand::float: bounds must be finite")
  }
  let underflow_threshold = 4.0F * @float.min_positive
  guard (min == 0.0F || min.abs() >= underflow_threshold) &&
    (max == 0.0F || max.abs() >= underflow_threshold) else {
    abort("Rand::float: bounds must be outside the underflow region")
  }
  guard min < max else { abort("Rand::float: min must be less than max") }
  let anchor_is_max = min.abs() <= max.abs()
  let gamma = float_gamma(if anchor_is_max { max } else { min })
  // Every Float and its power-of-two gamma convert exactly to Double. The
  // widened quotients and subtraction therefore compute the section count
  // without binary32 underflow or rounding.
  let sections = ceil_sections(
    min.to_double() / gamma.to_double(),
    max.to_double() / gamma.to_double(),
    anchor_is_max~,
  )
  let k = self.uint64(limit=sections) + 1
  if anchor_is_max {
    if k == sections {
      min
    } else {
      let (k_high, k_low) = split_uint64_for_float(k)
      4.0F * (max * 0.25F - k_high * gamma) - k_low * gamma
    }
  } else {
    let (k_high, k_low) = split_uint64_for_float(k - 1)
    4.0F * (min * 0.25F + k_high * gamma) + k_low * gamma
  }
}

///|
test "ceil_sections corrects a negative Dekker residual" {
  let min = 0xffefffffffffffffUL.reinterpret_as_double()
  let max = 0x7fe0000000000000UL.reinterpret_as_double()
  let gamma = double_gamma(min)
  let sections = ceil_sections(min / gamma, max / gamma, anchor_is_max=false)
  @test.assert_eq(sections, 0x2fffffffffffffUL)
}

///|
/// [boolean] returns a random boolean value (true or false).
pub fn Rand::boolean(self : Rand) -> Bool {
  (self.next() & 1) == 1
}

///|
/// Generates a random positive `BigInt` with a specified number of bits.
///
/// Parameters:
///
/// * `rand` : A random number generator that implements the `Rand` trait.
/// * `bits` : The desired number of bits in the generated number.
///
/// Example:
///
/// ```mbt check
/// test {
///   let rand = @random.Rand::new()
///   let n = rand.bigint(8) // Generate random 8-bit number
///   inspect(n.bit_length() <= 8, content="true")
/// }
/// ```
pub fn Rand::bigint(self : Rand, bits : Int) -> @bigint.BigInt {
  let mod = bits % 8
  let len = if mod == 0 { bits / 8 } else { bits / 8 + 1 }
  let bytes = Bytes::makei(len, i => {
    if i == 0 && mod != 0 {
      let mask = (1U << mod) - 1U
      (self.uint(limit=256) & mask).to_byte()
    } else {
      self.uint(limit=256).to_byte()
    }
  })
  @bigint.BigInt::from_octets(bytes)
}

///|
test "bigint" {
  let r = Rand::chacha8(seed=fixed_test_seed)
  inspect(r.bigint(1), content="1")
  inspect(r.bigint(3), content="4")
  inspect(r.bigint(7), content="124")
  inspect(r.bigint(8), content="214")
  inspect(r.bigint(32), content="2910404175")
  inspect(r.bigint(40), content="714745001576")
  inspect(r.bigint(64), content="13430064486797060338")
  inspect(r.bigint(128), content="251068071753473224445949321151725639522")
}

///|
#valtype
priv struct UInt128 {
  hi : UInt64
  lo : UInt64
}

///|
/// [umul128] returns the 128-bit product of x and y: (hi, lo) = x * y
/// with the product bits' upper half returned in hi and the lower
/// half returned in lo.
///
/// This function's execution time does not depend on the inputs.
fn umul128(a : UInt64, b : UInt64) -> UInt128 {
  let aLo = a & 0xffffffff
  let aHi = a >> 32
  let bLo = b & 0xffffffff
  let bHi = b >> 32
  let x = aLo * bLo
  let y = aHi * bLo + (x >> 32)
  let z = aLo * bHi + (y & 0xffffffff)
  let w = aHi * bHi + (y >> 32) + (z >> 32)
  { hi: w, lo: a * b, }
}

///|
test "umul128" {
  let r = umul128(0x123456789ABCDEF0, 0xFEDCBA9876543210)
  @test.assert_eq(r.hi, 1305938385386173474UL)
  @test.assert_eq(r.lo, 2552847189736476416UL)
}

///|
test "umul128: handles small numbers correctly" {
  let r = umul128(1UL, 1UL)
  @test.assert_eq(r.hi, 0UL)
  @test.assert_eq(r.lo, 1UL)
}

///|
test "umul128: handles large numbers correctly" {
  let r = umul128(1UL, 0xFFFFFFFFFFFFFFFFUL)
  @test.assert_eq(r.hi, 0UL)
  @test.assert_eq(r.lo, 0xFFFFFFFFFFFFFFFFUL)
}

///|
test "umul128: handles zero correctly" {
  let r = umul128(0UL, 0UL)
  @test.assert_eq(r.hi, 0UL)
  @test.assert_eq(r.lo, 0UL)
}

///|
/// [shuffle] shuffles the first n elements of an array using the Fisher-Yates shuffle algorithm.
/// The limit should not be negative.
///
/// # Example
/// ```mbt check
/// test {
///   let r = @random.Rand::new()
///   let a : FixedArray[Int] = [1, 2, 3, 4, 5]
///   r.shuffle(a.length(), (i : Int, j : Int) => {
///     let t = a[i]
///     a[i] = a[j]
///     a[j] = t
///   })
/// }
/// ```
pub fn Rand::shuffle(
  self : Rand,
  limit : Int,
  swap : (Int, Int) -> Unit,
) -> Unit {
  if limit < 0 {
    abort("Rand::shuffle: invalid argument limit")
  }
  for i in limit>..1 {
    let j = self.int(limit=i + 1)
    swap(i, j)
  }
}

///|
test "shuffle" {
  let r = Rand::chacha8(seed=fixed_test_seed)
  let a = [1, 2, 3, 4, 5]
  r.shuffle(a.length(), (i : Int, j : Int) => {
    let t = a[i]
    a[i] = a[j]
    a[j] = t
  })
  @debug.debug_inspect(a, content="[3, 5, 2, 1, 4]")
}
