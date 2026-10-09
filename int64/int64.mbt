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
/// Max value constant for this type.
pub const MAX_VALUE = 9223372036854775807L

///|
/// Max value constant for this type.
#deprecated("Use `MAX_VALUE` instead")
pub let max_value = 9223372036854775807L

///|
/// Min value constant for this type.
pub const MIN_VALUE = -9223372036854775808L

///|
/// Min value constant for this type.
#deprecated("Use `MIN_VALUE` instead")
pub let min_value = -9223372036854775808L

///|
/// same as `Int64::from_int`
#deprecated("Use Int64::from_int instead")
#doc(hidden)
pub fn from_int(i : Int) -> Int64 {
  i.to_int64()
}

///|
/// Return absolute value.
#deprecated("Use Int64::abs instead")
#doc(hidden)
pub fn abs(x : Int64) -> Int64 {
  Int64::abs(x)
}
