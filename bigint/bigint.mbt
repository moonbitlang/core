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
pub impl ToJson for BigInt with to_json(self : BigInt) -> Json {
  Json::string(self.to_string())
}

///|
pub impl @json.FromJson for BigInt with from_json(json, path) {
  guard json is String(s) else {
    raise @json.JsonDecodeError((path, "BigInt::from_json: expected number"))
  }
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
/// Test equality between a `BigInt` and an `Int`.
pub fn BigInt::equal_int(self : BigInt, other : Int) -> Bool {
  can_convert_to_int(self) && self.to_int() == other
}

///|
/// Test equality between a `BigInt` and an `Int64`.
pub fn BigInt::equal_int64(self : BigInt, other : Int64) -> Bool {
  can_convert_to_int64(self) && self.to_int64() == other
}

///|
/// Compare a `BigInt` with an `Int`.
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
