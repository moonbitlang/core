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
pub fn round(input : Double) -> Double {
  input.round()
}

test "round" {
  assert_eq!(round(4503599627370497.5), 4503599627370498.0)
  assert_eq!(round(2251799813685248.5), 2251799813685249.0)
}

///|
pub fn ceil(input : Double) -> Double {
  input.ceil()
}

test "ceil" {
  assert_eq!(ceil(2251799813685248.5), 2251799813685249.0)
  assert_eq!(ceil(1.1), 2.0)
  assert_eq!(ceil(1.0), 1.0)
  assert_eq!(ceil(0.9), 1.0)
  assert_eq!(ceil(0.0), 0.0)
}

///|
pub fn floor(input : Double) -> Double {
  input.floor()
}

test "floor" {
  assert_eq!(floor(2251799813685248.5), 2251799813685248.0)
  assert_eq!(floor(1.1), 1.0)
  assert_eq!(floor(1.0), 1.0)
  assert_eq!(floor(0.9), 0.0)
  assert_eq!(floor(0.0), 0.0)
}

///|
pub fn trunc(input : Double) -> Double {
  input.trunc()
}

test "trunc" {
  assert_eq!(trunc(4503599627370497.0), 4503599627370497.0)
  assert_eq!(trunc(2251799813685248.5), 2251799813685248.0)
  assert_eq!(trunc(4.5), 4.0)
  assert_eq!(trunc(1.5), 1.0)
  assert_eq!(trunc(1.0), 1.0)
  assert_eq!(trunc(0.2), 0.0)
  assert_eq!(trunc(0.0), 0.0)
}
