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
#deprecated("use `@math.hypotf` instead")
#coverage.skip
pub fn Float::hypot(self : Float, y : Float) -> Float {
  let epsilon : Float = 1.1920928955078125e-7
  let x = self.abs()
  let y = y.abs()
  if self.is_inf() || y.is_inf() {
    return infinity
  }
  let (x, y) = if y > x { (y, x) } else { (x, y) }
  if x * epsilon >= y {
    return x
  }
  let rat = y / x
  x * (rat * rat + 1.0).sqrt()
}
