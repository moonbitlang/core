// Copyright 2024 International Digital Economy Academy
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

test "add to empty set" {
  let set = MutableSet::new()
  set.add(1)
  @assertion.assert_eq(set.contains(1), true)!
}

test "add to non-empty set" {
  let set = MutableSet::new()
  set.add(1)
  set.add(2)
  @assertion.assert_eq(set.contains(1), true)!
  @assertion.assert_eq(set.contains(2), true)!
}

test "add duplicate value" {
  let set = MutableSet::new()
  set.add(1)
  set.add(1)
  @assertion.assert_eq(set.contains(1), true)!
  @assertion.assert_eq(set.size(), 2L)!
}

test "add multiple values" {
  let set = MutableSet::new()
  set.add(1)
  set.add(2)
  set.add(3)
  @assertion.assert_eq(set.contains(1), true)!
  @assertion.assert_eq(set.contains(2), true)!
  @assertion.assert_eq(set.contains(3), true)!
  @assertion.assert_eq(set.size(), 3L)!
}

test "add and check color of root" {
  let set = MutableSet::new()
  set.add(1)
  @assertion.assert_eq(get_color(set.root), Black)!
}
