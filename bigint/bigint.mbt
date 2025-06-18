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
/// Converts a `BigInt` value to its JSON representation as a string.
///
/// This implementation serializes the `BigInt` by first converting it to its
/// decimal string representation, then wrapping it in a JSON string value. This
/// approach preserves the exact numerical value while ensuring compatibility
/// with JSON parsers that may not natively support arbitrary-precision integers.
///
/// Parameters:
///
/// * `self` : The `BigInt` value to be converted to JSON.
///
/// Returns a `Json` value containing the string representation of the `BigInt`.
///
/// Example:
///
/// ```moonbit
///   let big = 12345678901234567890N
///   let json = big.to_json()
///   inspect(json, content=
///   #|String("12345678901234567890")
/// )
/// ```
///
pub impl ToJson for BigInt with to_json(self : BigInt) -> Json {
  Json::string(self.to_string())
}

///|
pub impl @json.FromJson for BigInt with from_json(json, path) {
  guard json is String(s) else {
    raise @json.JsonDecodeError(
      (path, "BigInt::from_json: expected number in string representation"),
    )
  }
  // TODO: Capture parse failure
  BigInt::from_string(s)
}

///|
pub impl @quickcheck.Arbitrary for BigInt with arbitrary(size, rs) {
  if size == 0 {
    0
  } else {
    rs.next_int64() |> BigInt::from_int64
  }
}

///|
/// Tests equality between a `BigInt` and an `Int` value.
///
/// This function performs a safe comparison by first checking if the `BigInt`
/// can be converted to an `Int` without overflow, then comparing the converted
/// value with the `Int` parameter. If the `BigInt` is too large or too small to
/// fit in an `Int`, the function returns `false`.
///
/// Parameters:
///
/// * `self` : The `BigInt` value to compare.
/// * `other` : The `Int` value to compare against.
///
/// Returns `true` if the `BigInt` and `Int` represent the same numerical value,
/// `false` otherwise.
///
/// Example:
///
/// ```moonbit
///   let big = 42N
///   inspect(big.equal_int(42), content="true")
///   inspect(big.equal_int(41), content="false")
///   let large = 9223372036854775808N // Beyond Int64 range
///   inspect(large.equal_int(42), content="false")
/// ```
///
pub fn BigInt::equal_int(self : BigInt, other : Int) -> Bool {
  can_convert_to_int(self) && self.to_int() == other
}

///|
/// Tests whether a `BigInt` value is equal to an `Int64` value.
///
/// This function performs an efficient equality check by first verifying if the
/// `BigInt` can be represented as an `Int64` without overflow. If it can be
/// converted, it then compares the converted value with the given `Int64`.
///
/// Parameters:
///
/// * `self` : The `BigInt` value to compare.
/// * `other` : The `Int64` value to compare against.
///
/// Returns `true` if the `BigInt` and `Int64` represent the same numerical
/// value, `false` otherwise.
///
/// Example:
///
/// ```moonbit
///   let big = BigInt::from_int64(9223372036854775807L) // Int64 max value
///   inspect(big.equal_int64(9223372036854775807L), content="true")
///   inspect(big.equal_int64(42L), content="false")
///   
///   let overflow = BigInt::from_string("9223372036854775808") // Beyond Int64 range
///   inspect(overflow.equal_int64(9223372036854775807L), content="false")
/// ```
///
pub fn BigInt::equal_int64(self : BigInt, other : Int64) -> Bool {
  can_convert_to_int64(self) && self.to_int64() == other
}

///|
/// Compares a `BigInt` with an `Int` and returns their relative order.
///
/// Parameters:
///
/// * `self` : The `BigInt` value to compare.
/// * `other` : The `Int` value to compare against.
///
/// Returns an integer indicating the relative order:
///
/// * A negative value if `self` is less than `other`
/// * Zero if `self` equals `other`
/// * A positive value if `self` is greater than `other`
///
/// Example:
///
/// ```moonbit
///   let big = 42N
///   inspect(big.compare_int(24), content="1") // 42 > 24
///   inspect(big.compare_int(42), content="0") // 42 = 42
///   inspect(big.compare_int(100), content="-1") // 42 < 100
/// ```
///
pub fn BigInt::compare_int(self : BigInt, other : Int) -> Int {
  guard can_convert_to_int(self) else {
    return if is_neg(self) { -1 } else { 1 }
  }
  let self = self.to_int()
  Int::compare(self, other)
}

///|
/// Compare a `BigInt` with an `Int64`.
pub fn BigInt::compare_int64(self : BigInt, other : Int64) -> Int {
  guard can_convert_to_int64(self) else {
    return if is_neg(self) { -1 } else { 1 }
  }
  let self = self.to_int64()
  Int64::compare(self, other)
}

///|
test "can_convert_to_int" {
  assert_true(can_convert_to_int(0N))
  assert_true(can_convert_to_int(1N))
  assert_true(can_convert_to_int(-1N))
  assert_true(can_convert_to_int(2147483647N)) // Int.max_value
  assert_true(can_convert_to_int(-2147483648N)) // Int.min_value
  assert_false(can_convert_to_int(2147483648N)) // Int.max_value + 1
  assert_false(can_convert_to_int(-2147483649N)) // Int.min_value - 1
  assert_false(can_convert_to_int(4294967295N)) // 2^32 - 1
  assert_false(can_convert_to_int(-4294967295N)) // -(2^32 - 1)
  assert_false(can_convert_to_int(4294967296N)) // 2^32
  assert_false(can_convert_to_int(-4294967296N)) // -2^32
}

///|
test "can_convert_to_int64" {
  assert_true(can_convert_to_int64(0N))
  assert_true(can_convert_to_int64(1N))
  assert_true(can_convert_to_int64(-1N))
  assert_true(can_convert_to_int64(2147483647N)) // Int.max_value
  assert_true(can_convert_to_int64(-2147483648N)) // Int.min_value
  assert_true(can_convert_to_int64(2147483648N)) // Int.max_value + 1
  assert_true(can_convert_to_int64(-2147483649N)) // Int.min_value - 1
  assert_true(can_convert_to_int64(4294967295N)) // 2^32 - 1
  assert_true(can_convert_to_int64(-4294967295N)) // -(2^32 - 1)
  assert_true(can_convert_to_int64(4294967296N)) // 2^32
  assert_true(can_convert_to_int64(-4294967296N)) // -2^32
  assert_true(can_convert_to_int64(9223372036854775807N)) // Int64.max_value
  assert_true(can_convert_to_int64(-9223372036854775808N)) // Int64.min_value
  assert_false(can_convert_to_int64(9223372036854775808N)) // Int64.max_value + 1
  assert_false(can_convert_to_int64(-9223372036854775809N)) // Int64.min_value - 1
  assert_false(can_convert_to_int64(18446744073709551615N)) // 2^64 - 1
  assert_false(can_convert_to_int64(-18446744073709551615N)) // -(2^64 - 1)
  assert_false(can_convert_to_int64(18446744073709551616N)) // 2^64
  assert_false(can_convert_to_int64(-18446744073709551616N)) // -2^64
}
