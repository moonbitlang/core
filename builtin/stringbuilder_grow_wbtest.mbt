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
test "StringBuilder growth_capacity doubles until the requirement is covered" {
  inspect(stringbuilder_growth_capacity(1, 0, 100), content="128")
  inspect(stringbuilder_growth_capacity(3, 0, 24), content="24")
  inspect(stringbuilder_growth_capacity(16, 0, 16), content="16")
  inspect(stringbuilder_growth_capacity(16, 0, 17), content="32")
}

///|
test "StringBuilder growth_capacity survives Int overflow" {
  // 2^30 doubles to INT_MIN; the old loop then went 0 -> 0 -> ... forever.
  let big = 1 << 30
  inspect(
    stringbuilder_growth_capacity(big, 0, big + 1) == big + 1,
    content="true",
  )
  // A non-power-of-two start can overflow to a negative value on the way up.
  inspect(
    stringbuilder_growth_capacity(11, 0, 1_500_000_000),
    content="1500000000",
  )
}
