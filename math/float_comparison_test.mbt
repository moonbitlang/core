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
test "hypotf keeps IEEE NaN arithmetic instead of returning an unordered operand" {
  for bits in [0x7f800123U, 0x7fc00123U, 0xff800456U] {
    let nan = Float::reinterpret_from_uint(bits)
    for result in [@math.hypotf(nan, 1.0F), @math.hypotf(1.0F, nan)] {
      assert_true(result.is_nan())
      // Arithmetic quiets a signaling NaN; an early return of x need not.
      assert_true((result.reinterpret_as_uint() & 0x00400000U) != 0U)
    }
  }
}
