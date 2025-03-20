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
test "utf16 indexed subview" {
  let str = "aa😭b😂cc"
  let v1 = str.view(start_offset=1, end_offset=8)
  inspect!(v1, content="a😭b😂c")
  inspect!(v1.char_length(), content="5")
  let v2 = v1.view()
  inspect!(v2, content="a😭b😂c")
  inspect!(v2.char_length(), content="5")
  let v3 = v1.view(start_offset=1, end_offset=4)
  inspect!(v3, content="😭b")
  inspect!(v3.char_length(), content="2")
  let v4 = v1.view(start_offset=1)
  inspect!(v4, content="😭b😂c")
  inspect!(v4.char_length(), content="4")
  let v5 = v1.view(end_offset=4)
  inspect!(v5, content="a😭b")
  inspect!(v5.char_length(), content="3")
  let v6 = v1.view(start_offset=1, end_offset=1)
  inspect!(v6, content="")
  inspect!(v6.char_length(), content="0")
  let v7 = v1.view(end_offset=0)
  inspect!(v7, content="")
  inspect!(v7.char_length(), content="0")
  let v8 = v1.view(start_offset=7)
  inspect!(v8, content="")
  inspect!(v8.char_length(), content="0")
  let v9 = v1.view(start_offset=7, end_offset=7)
  inspect!(v9, content="")
  inspect!(v9.char_length(), content="0")
}
