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

/// Converts a boolean value to its integer representation, where `true` becomes
/// 1 and `false` becomes 0.
///
/// Parameters:
/// - `bool`: A boolean value to be converted to integer.
///
/// Returns an integer value: 1 for `true` and 0 for `false`.
///
/// Examples:
///
/// ```moonbit
/// test "to_int/basic" {
///   inspect!(to_int(true), content="1")
///   inspect!(to_int(false), content="0")
/// }
/// 
/// test "to_int/expression" {
///   let x = 5
///   let y = 3
///   inspect!(to_int(x > y), content="1")
///   inspect!(to_int(x < y), content="0")
/// }
/// ```
pub fn to_int(self : Bool) -> Int {
  if self {
    1
  } else {
    0
  }
}

/// Converts a boolean value to a 64-bit integer. Returns 1 for `true` and 0 for
/// `false`.
///
/// Parameters:
/// - `value`: A boolean value to be converted.
///
/// Returns a 64-bit integer representation of the boolean value.
///
/// Examples:
///
/// ```moonbit
/// test "to_int64" {
///   inspect!(to_int64(true), content="1")
///   inspect!(to_int64(false), content="0")
/// }
/// 
/// test "bool_to_int64_operations" {
///   let x = true
///   let y = false
///   inspect!(to_int64(x) + to_int64(y), content="1")
/// }
/// ```
pub fn to_int64(self : Bool) -> Int64 {
  if self {
    1
  } else {
    0
  }
}

/// Converts a boolean value to an unsigned integer. Returns 1 for `true` and 0
/// for `false`.
///
/// Parameters:
/// - `value`: A boolean value to be converted to unsigned integer.
///
/// Returns an unsigned integer (UInt) that represents the boolean value.
///
/// Examples:
///
/// ```moonbit
/// test "to_uint" {
///   inspect!(Bool::to_uint(true), content="1")
///   inspect!(Bool::to_uint(false), content="0")
/// }
/// 
/// test "bool_comparison" {
///   let b = true
///   let n = Bool::to_uint(b)
///   inspect!(n == 1, content="true")
/// }
/// ```
pub fn to_uint(self : Bool) -> UInt {
  if self {
    1
  } else {
    0
  }
}

/// Converts a boolean value to an unsigned 64-bit integer. Returns 1 for `true`
/// and 0 for `false`.
///
/// Parameters:
/// - `value` : The boolean value to be converted.
///
/// Returns an unsigned 64-bit integer representation of the boolean value.
///
/// Examples:
///
/// ```moonbit
/// test "to_uint64" {
///   inspect!(to_uint64(true), content="1")
///   inspect!(to_uint64(false), content="0")
/// }
/// ```
pub fn to_uint64(self : Bool) -> UInt64 {
  if self {
    1
  } else {
    0
  }
}

///|
pub impl Hash for Bool with hash(self) { self.to_int() }

///|
pub impl Hash for Bool with hash_combine(self, hasher) {
  hasher.combine_bool(self)
}
