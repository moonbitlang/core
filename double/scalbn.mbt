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
fn scalbn(self : Double, exp : Int) -> Double {
  let mut n = exp
  let mut y : Double = self
  if n > 1023 {
    y *= 0x1.0p1023
    n -= 1023
    if n > 1023 {
      y *= 0x1.0p1023
      n -= 1023
      if n > 1023 {
        n = 1023
      }
    }
  } else if n < -1022 {
    // make sure final n < -53 to avoid double
    // rounding in the subnormal range
    y *= 0x1.0p-1022 * 0x1.0p53
    n += 1022 - 53
    if n < -1022 {
      y *= 0x1.0p-1022 * 0x1.0p53
      n += 1022 - 53
      if n < -1022 {
        n = -1022
      }
    }
  }
  let ui = (0x3ff + n).to_uint64() << 52
  return y * ui.reinterpret_as_double()
}

test "scalbn" {
  inspect!(scalbn(1.5, 2), content="6")
  inspect!(scalbn(2.0, -1), content="1")
  inspect!(scalbn(3.0, 0), content="3")
  inspect!(scalbn(1.0, 1024), content="Infinity")
  inspect!(scalbn(1.0, -1023), content="1.1125369292536007e-308")
  inspect!(scalbn(1.0, 2047), content="Infinity")
  inspect!(scalbn(1.0, -1992), content="0")
  inspect!(scalbn(1.0, 3070), content="Infinity")
  inspect!(scalbn(1.0, -2961), content="0")
  inspect!(scalbn(infinity, 10), content="Infinity")
  inspect!(scalbn(not_a_number, 10), content="NaN")
  inspect!(scalbn(0.0, 10), content="0")
}
