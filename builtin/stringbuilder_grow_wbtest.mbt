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
test "StringBuilder grow_capacity doubles until the requirement is covered" {
  inspect(stringbuilder_grow_capacity(1, 100), content="128")
  inspect(stringbuilder_grow_capacity(3, 24), content="24")
  inspect(stringbuilder_grow_capacity(16, 16), content="16")
  inspect(stringbuilder_grow_capacity(16, 17), content="32")
}

///|
test "StringBuilder grow_capacity survives Int overflow" {
  // 2^30 doubles to INT_MIN; the old loop then went 0 -> 0 -> ... forever.
  let big = 1 << 30
  inspect(stringbuilder_grow_capacity(big, big + 1) == big + 1, content="true")
  // A non-power-of-two start can overflow to a negative value on the way up.
  inspect(stringbuilder_grow_capacity(11, 1_500_000_000), content="1500000000")
}
