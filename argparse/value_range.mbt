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
struct ValueRange {
  lower : Int?
  upper : Int?
  lower_inclusive : Bool
  upper_inclusive : Bool
} derive(Eq, Show)

///|
pub fn ValueRange::empty() -> ValueRange {
  ValueRange::{
    lower: Some(0),
    upper: Some(0),
    lower_inclusive: true,
    upper_inclusive: true,
  }
}

///|
pub fn ValueRange::single() -> ValueRange {
  ValueRange::{
    lower: Some(1),
    upper: Some(1),
    lower_inclusive: true,
    upper_inclusive: true,
  }
}

///|
pub fn ValueRange::new(
  lower? : Int? = None,
  upper? : Int? = None,
  lower_inclusive? : Bool = true,
  upper_inclusive? : Bool = true,
) -> ValueRange {
  ValueRange::{ lower, upper, lower_inclusive, upper_inclusive }
}
