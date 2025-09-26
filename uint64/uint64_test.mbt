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

///|
test "to_be_bytes" {
  inspect(
    @uint64.max_value.to_be_bytes(),
    content=(
      #|b"\xff\xff\xff\xff\xff\xff\xff\xff"
    ),
  )
  inspect(
    @uint64.min_value.to_be_bytes(),
    content=(
      #|b"\x00\x00\x00\x00\x00\x00\x00\x00"
    ),
  )
  inspect(
    0x123456789ABCDEF0UL.to_be_bytes(),
    content=(
      #|b"\x124Vx\x9a\xbc\xde\xf0"
    ),
  )
}

///|
test "to_le_bytes" {
  inspect(
    @uint64.max_value.to_le_bytes(),
    content=(
      #|b"\xff\xff\xff\xff\xff\xff\xff\xff"
    ),
  )
  inspect(
    @uint64.min_value.to_le_bytes(),
    content=(
      #|b"\x00\x00\x00\x00\x00\x00\x00\x00"
    ),
  )
  inspect(
    0x123456789ABCDEF0UL.to_le_bytes(),
    content=(
      #|b"\xf0\xde\xbc\x9axV4\x12"
    ),
  )
}
