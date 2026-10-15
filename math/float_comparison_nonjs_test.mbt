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
test "atanh does not classify NaN as outside the numerical domain" {
  for bits in [0x7ff8000000000123UL, 0xfff8000000000456UL] {
    let nan = bits.reinterpret_as_double()
    // ln_1p canonicalizes the payload; atanh restores the input sign.
    assert_eq(
      @math.atanh(nan).reinterpret_as_uint64() & 0x8000000000000000UL,
      bits & 0x8000000000000000UL,
    )
  }
}
