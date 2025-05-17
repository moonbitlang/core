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
/// Calculcates x * 2 **n where x is a single-precision floating number and n is an integer.
///
/// Parameters:
///
/// - `self` - The floating number to be scaled.
/// - `exp` - The exponent to scale by.
///
/// Returns the scaled floating number.
///
/// Example:
///
/// ```moonbit
/// test "scalbnf" {
///   inspect!((1.5 : Float).scalbn(2), content="6")
///   inspect!((2.0 : Float).scalbn(-1), content="1")
///   inspect!((3.0 : Float).scalbn(0), content="3")
///   inspect!((1.0 : Float).scalbn(128), content="Infinity")
///   inspect!((1.0 : Float).scalbn(-150), content="0")
///   inspect!((1.0 : Float).scalbn(254), content="Infinity")
///   inspect!(@float.not_a_number.scalbn(1), content="NaN")
///   inspect!((-2.0 : Float).scalbn(1), content="-4")
///   inspect!((-2.0 : Float).scalbn(128), content="-Infinity")
/// }
/// ```
pub fn scalbn(self : Float, exp : Int) -> Float {
  let mut y = self
  let mut n = exp
  if n > 127 {
    y *= (0x1.0p127 : Float)
    n -= 127
    if n > 127 {
      y *= (0x1.0p127 : Float)
      n -= 127
      if n > 127 {
        n = 127
      }
    }
  } else if n < -126 {
    y *= (0x1.0p-126 : Float) * 0x1.0p24
    n += 126 - 24
    if n < -126 {
      y *= (0x1.0p-126 : Float) * 0x1.0p24
      n += 126 - 24
      if n < -126 {
        n = -126
      }
    }
  }
  let u = (0x7f + n) << 23
  return y * u.reinterpret_as_float()
}
