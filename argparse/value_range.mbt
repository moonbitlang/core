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
/// Number-of-values constraint for an argument.
pub struct ValueRange {
  priv lower : Int
  priv upper : Int?

  /// Create a value-count range.
  fn new(lower? : Int, upper? : Int) -> ValueRange
} derive(Eq, Show)

///|
/// Exact single-value range (`1..1`).
pub fn ValueRange::single() -> ValueRange {
  ValueRange(lower=1, upper=1)
}

///|
/// Create a value-count range.
///
/// Examples:
/// - `ValueRange(lower=0)` means `0..`.
/// - `ValueRange(lower=1, upper=3)` means `1..=3`.
pub fn ValueRange::new(lower? : Int = 0, upper? : Int) -> ValueRange {
  { lower, upper }
}
