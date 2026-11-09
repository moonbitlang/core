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
test "contains_code_unit at every offset of every view" {
  // Reaches both halves of the sixteen-unit block, the single eight-unit
  // step, and the scalar tail from every alignment; `at < 0` places no match.
  let n = 48
  for at in -1..<n {
    let str = String::from_array(
      Array::makei(n, i => if i == at { 'z' } else { 'a' }),
    )
    for start in 0..<=n {
      for end in start..<=n {
        let expected = at >= start && at < end
        let view = str[start:end]
        assert_eq(view.contains_code_unit(0x7A), expected)
        assert_eq(view.contains("z"), expected)
        if start == 0 && end == n {
          assert_eq(str.contains_code_unit(0x7A), expected)
        }
      }
    }
  }
}
