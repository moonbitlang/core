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
/// Converts a string representation in the specified radix to a `BigInt`.
///
/// Panics if the input is malformed.
///
/// Deprecated: use `@string.parse_bigint`, which raises on malformed input.
#deprecated("Use `@string.parse_bigint` instead")
pub fn BigInt::from_string(input : String, radix~ : Int32 = 10) -> BigInt {
  parse_bigint(input, base=radix) catch {
    Failure(msg) => abort(msg)
    _ => abort("invalid syntax")
  }
}
