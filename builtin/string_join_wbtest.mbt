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
#cfg(not(target="js"))
test "join length accepts the largest representable sum" {
  inspect(join_length_add(0x7FFFFFFE, 1), content="2147483647")
}

///|
#cfg(not(target="js"))
test "panic join length overflow" {
  ignore(join_length_add(0x7FFFFFFF, 1))
}

///|
#cfg(not(target="js"))
test "join copies raw UTF-16 units across part boundaries" {
  let high = unsafe_fixedarray_uint16_to_string([0xD83D])
  let low = unsafe_fixedarray_uint16_to_string([0xDE00])
  let parts : FixedArray[String] = [high, low]
  inspect(parts.join(""), content="😀")
  let separated = parts.join("|")
  inspect(separated.length(), content="3")
  inspect(separated.unsafe_get(0).to_int(), content="55357")
  inspect(separated.unsafe_get(1).to_int(), content="124")
  inspect(separated.unsafe_get(2).to_int(), content="56832")
}
