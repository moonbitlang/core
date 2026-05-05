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
test "parse_double huge exponent" {
  // Exponents whose digit count exceeds what fits in `Int` must clamp before
  // they overflow the slow-path accumulator. Positive side overflows to a
  // range error; negative side underflows to zero.
  inspect(
    try? @string.parse_double("1e999999999999999999999999999999999999"),
    content=(
      #|Err(Failure("value out of range"))
    ),
  )
  inspect(
    try? @string.parse_double("-1e999999999999999999999999999999999999"),
    content=(
      #|Err(Failure("value out of range"))
    ),
  )
  inspect(
    try? @string.parse_double("1e-999999999999999999999999999999999999"),
    content=(
      #|Ok(0)
    ),
  )
  inspect(
    try? @string.parse_double("-1e-999999999999999999999999999999999999"),
    content=(
      #|Ok(0)
    ),
  )
}
