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
test "ToStringView for Char - comprehensive demo" {
  // Test 1: Simple join without separator
  let chars1 : Array[Char] = ['h', 'e', 'l', 'l', 'o']
  let result1 = chars1.join("")
  inspect(result1, content="hello")

  // Test 2: Join with separator
  let chars2 : Array[Char] = ['a', 'b', 'c', 'd']
  let result2 = chars2.join(", ")
  inspect(result2, content="a, b, c, d")

  // Test 3: Empty array
  let chars3 : Array[Char] = []
  let result3 = chars3.join("-")
  inspect(result3, content="")

  // Test 4: Single character
  let chars4 : Array[Char] = ['x']
  let result4 = chars4.join(" | ")
  inspect(result4, content="x")

  // Test 5: Unicode characters
  let chars5 : Array[Char] = ['🌟', '✨', '🎉']
  let result5 = chars5.join(" ")
  inspect(result5, content="🌟 ✨ 🎉")
}
