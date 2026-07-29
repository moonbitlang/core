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
test "buffer growth capacity doubles while representable" {
  inspect(buffer_growth_capacity(8, 8, 9), content="16")
  inspect(buffer_growth_capacity(8, 8, 33), content="64")
}

///|
test "buffer growth capacity falls back to the exact requirement" {
  inspect(
    buffer_growth_capacity(0x40000000, 0x40000000, 0x40000001),
    content="1073741825",
  )
  inspect(
    buffer_growth_capacity(0x20000000, 0x20000000, 0x40000001),
    content="1073741825",
  )
}

///|
test "panic buffer growth rejects a wrapped required size" {
  ignore(buffer_growth_capacity(16, 16, -1))
}
