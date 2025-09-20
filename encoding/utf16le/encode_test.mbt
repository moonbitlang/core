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
test "encode" {
  let s = "abc你好👀"
  let encoded = @utf16le.encode(s)
  inspect(
    encoded,
    content=(
      #|b"\x61\x00\x62\x00\x63\x00\x60\x4f\x7d\x59\x3d\xd8\x40\xdc"
    ),
  )
  let encoded_with_bom = @utf16le.encode(s, bom=true)
  inspect(
    encoded_with_bom,
    content=(
      #|b"\xff\xfe\x61\x00\x62\x00\x63\x00\x60\x4f\x7d\x59\x3d\xd8\x40\xdc"
    ),
  )
}
