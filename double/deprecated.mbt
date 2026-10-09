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
/// Function `pow`.
#deprecated("Use `@math.pow` instead")
#warnings("-deprecated")
pub fn pow(m : Double, n : Double) -> Double {
  m.pow(n)
}

///|
/// Return whether the value close.
#deprecated("Use `Double::is_close` instead")
pub fn is_close(
  d : Double,
  other : Double,
  relative_tolerance? : Double = 1.0e-09,
  absolute_tolerance? : Double = 0.0,
) -> Bool {
  d.is_close(other, relative_tolerance~, absolute_tolerance~)
}

///|
/// Create from `int`.
#deprecated("Use `Double::from_int` instead")
pub fn from_int(i : Int) -> Double {
  Double::from_int(i)
}

///|
/// Return absolute value.
#deprecated("Use `x.abs()` instead")
pub fn abs(x : Double) -> Double {
  x.abs()
}
