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
fn make_v128(lo : UInt64, hi : UInt64) -> V128 = "%v128.make"

///|
test "V128 equality without importing v128" {
  let value = make_v128(1UL, 0xfedcba9876543210UL)
  let equal = V128::equal
  inspect(equal(value, value), content="true")
  inspect(value.equal(value), content="true")
  inspect(value == value, content="true")
  inspect(value != value, content="false")
  let different_lo = make_v128(2UL, 0xfedcba9876543210UL)
  let different_hi = make_v128(1UL, 0xfedcba9876543211UL)
  inspect(value.equal(different_lo), content="false")
  inspect(value.equal(different_hi), content="false")
  inspect(value != different_lo, content="true")
  inspect(value != different_hi, content="true")
}

///|
test "V128 display without importing v128" {
  let value = make_v128(1UL, 0xfedcba9876543210UL)
  let to_string = V128::to_string
  inspect(
    to_string(value),
    content="V128(0x0000000000000001, 0xfedcba9876543210)",
  )
  inspect(
    value.to_string(),
    content="V128(0x0000000000000001, 0xfedcba9876543210)",
  )
  inspect(value, content="V128(0x0000000000000001, 0xfedcba9876543210)")
  inspect(
    make_v128(0UL, 0UL),
    content="V128(0x0000000000000000, 0x0000000000000000)",
  )
  debug_inspect(
    value,
    content="<V128: (0x0000000000000001, 0xfedcba9876543210)>",
  )
}
