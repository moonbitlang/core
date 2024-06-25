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

test "map" {
  let x = ref(1)
  let y = map(x, fn(a) { a + 1 })
  @assertion.assert_eq(y.val, 2)?
}

test "protect" {
  let x = ref(1)
  @assertion.assert_eq(x.val, 1)?
  protect(x, 2, fn() { @assertion.assert_eq(x.val, 2) })?
  @assertion.assert_eq(x.val, 1)?
}

test "update with increment function" {
  let a = ref(1)
  update(a, fn(x) { x + 1 })
  @assertion.assert_eq(a.val, 2)?
}

test "update with decrement function" {
  let a = ref(1)
  update(a, fn(x) { x - 1 })
  @assertion.assert_eq(a.val, 0)?
}

test "update with multiplication function" {
  let a = ref(2)
  update(a, fn(x) { x * 2 })
  @assertion.assert_eq(a.val, 4)?
}

test "update with division function" {
  let a = ref(4)
  update(a, fn(x) { x / 2 })
  @assertion.assert_eq(a.val, 2)?
}

test "update with identity function" {
  let a = ref(1)
  update(a, fn(x) { x })
  @assertion.assert_eq(a.val, 1)?
}
