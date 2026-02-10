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

  fn new(
    lower? : Int,
    upper? : Int,
    lower_inclusive? : Bool,
    upper_inclusive? : Bool,
  ) -> ValueRange
} derive(Eq, Show)

///|
pub fn ValueRange::empty() -> ValueRange {
  ValueRange(lower=0, upper=0)
}

///|
pub fn ValueRange::single() -> ValueRange {
  ValueRange(lower=1, upper=1)
}

///|
pub fn ValueRange::new(
  lower? : Int,
  upper? : Int,
  lower_inclusive? : Bool = true,
  upper_inclusive? : Bool = true,
) -> ValueRange {
  let lower = match lower {
    None => 0
    Some(lower) => if lower_inclusive { lower } else { lower + 1 }
  }
  let upper = match upper {
    None => None
    Some(upper) => Some(if upper_inclusive { upper } else { upper - 1 })
  }
  ValueRange::{ lower, upper }
}
