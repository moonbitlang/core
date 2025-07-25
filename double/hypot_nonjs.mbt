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

// origin: boost_1_81_0/boost/math/special_functions/hypot.hpp
//
// This implementation is inspired by the hypot function from the Boost C++ Libraries.
// Original Boost implementation (C) Copyright John Maddock 2005-2006.
// Boost Software License, Version 1.0. (See accompanying file
// LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
// The algorithm has been adapted and implemented independently in this code.

///|
#deprecated("use `@math.hypot` instead")
#coverage.skip
pub fn Double::hypot(self : Double, y : Double) -> Double {
  if self.is_nan() || y.is_nan() {
    return not_a_number
  }
  if self.is_inf() || y.is_inf() {
    return infinity
  }
  let x = self.abs()
  let y = y.abs()
  let double_epsilon : Double = 0x0.0000000000001P-1022
  let (x, y) = if y > x { (y, x) } else { (x, y) }
  if x * double_epsilon >= y {
    return x
  }
  let r = y / x
  x * (1.0 + r * r).sqrt()
}
