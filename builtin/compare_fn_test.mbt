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
test "compare free function" {
  // agrees with the trait method
  assert_eq(compare(1, 2), Compare::compare(1, 2))
  assert_eq(compare("abd", "abc"), Compare::compare("abd", "abc"))
  // three-way result
  assert_eq(compare(1, 2), -1)
  assert_eq(compare(2, 1), 1)
  assert_eq(compare("abc", "abc"), 0)
}

///|
test "compare as function value" {
  let arr = [3, 1, 2]
  arr.sort_by(compare)
  assert_eq(arr, [1, 2, 3])
}
