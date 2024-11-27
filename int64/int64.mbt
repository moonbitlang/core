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

///|
pub let max_value = 9223372036854775807L

///|
pub let min_value = -9223372036854775808L

///|
pub fn Int64::from_int(i : Int) -> Int64 {
  i.to_int64()
}

///|
pub fn abs(self : Int64) -> Int64 {
  if self < 0L {
    -self
  } else {
    self
  }
}

///|
pub fn min(self : Int64, x : Int64) -> Int64 {
  if self > x {
    x
  } else {
    self
  }
}

///|
pub fn max(self : Int64, x : Int64) -> Int64 {
  if self > x {
    self
  } else {
    x
  }
}
