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
pub fn op_mod(self : Double, other : Double) -> Double {
  let x = self
  let y = other
  let mut uint64_x = x.reinterpret_as_uint64()
  let mut uint64_y = y.reinterpret_as_uint64()
  let mut ex = ((uint64_x >> 52) & 0x7FF).to_int()
  let mut ey = ((uint64_y >> 52) & 0x7FF).to_int()
  let sign_x = uint64_x >> 63
  let mut i : UInt64 = 0
  if (uint64_y << 1) == 0 || y.is_nan() || ex == 0x7ff {
    return x * y / (x * y)
  }
  if (uint64_x << 1) <= (uint64_y << 1) {
    if (uint64_x << 1) == (uint64_y << 1) {
      return 0.0 * x
    }
    return x
  }

  // normalize x and y
  if ex == 0 {
    i = uint64_x << 12
    while (i >> 63) == 0 {
      ex -= 1
      i = i << 1
    }
    uint64_x = uint64_x << (-ex + 1)
  } else {
    uint64_x = uint64_x & (18446744073709551615UL >> 12)
    uint64_x = uint64_x | (1UL << 52)
  }
  if ey == 0 {
    i = uint64_y << 12
    while (i >> 63) == 0 {
      ey -= 1
      i = i << 1
    }
    uint64_y = uint64_y << (-ey + 1)
  } else {
    uint64_y = uint64_y & (18446744073709551615UL >> 12)
    uint64_y = uint64_y | (1UL << 52)
  }

  // x mod y
  while ex > ey {
    i = uint64_x - uint64_y
    if (i >> 63) == 0 {
      if i == 0 {
        return 0.0 * x
      }
      uint64_x = i
    }
    uint64_x = uint64_x << 1
    ex -= 1
  }
  i = uint64_x - uint64_y
  if (i >> 63) == 0 {
    if i == 0 {
      return 0.0 * x
    }
    uint64_x = i
  }
  while (uint64_x >> 52) == 0 {
    uint64_x = uint64_x << 1
    ex -= 1
  }

  // scale result
  if ex > 0 {
    uint64_x = uint64_x - (1UL << 52)
    uint64_x = uint64_x | (ex.to_uint64() << 52)
  } else {
    uint64_x = uint64_x >> (-ex + 1)
  }
  uint64_x = uint64_x | (sign_x << 63)
  uint64_x.reinterpret_as_double()
}
