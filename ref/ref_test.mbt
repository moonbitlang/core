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
test "map" {
  let x = @ref.new(1)
  let y = x.map(a => a + 1)
  assert_eq(y.val, 2)
}

///|
test "protect" {
  let x = @ref.new(1)
  assert_eq(x.val, 1)
  let mut r = 0
  x.protect(2, () => r = x.val)
  assert_eq(r, 2)
  assert_eq(x.val, 1)
}

///|
test "protect with error" {
  let x = @ref.new(1)
  assert_eq(x.val, 1)
  let mut r = 0
  let result = try? x.protect(2, () => {
      r = x.val
      fail("")
      r = -x.val
    })
  assert_true(result is Err(_))
  assert_eq(r, 2)
  assert_eq(x.val, 1)
}

///|
test "update with increment function" {
  let a = @ref.new(1)
  a.update(x => x + 1)
  assert_eq(a.val, 2)
}

///|
test "update with decrement function" {
  let a = @ref.new(1)
  a.update(x => x - 1)
  assert_eq(a.val, 0)
}

///|
test "update with multiplication function" {
  let a = @ref.new(2)
  a.update(x => x * 2)
  assert_eq(a.val, 4)
}

///|
test "update with division function" {
  let a = @ref.new(4)
  a.update(x => x / 2)
  assert_eq(a.val, 2)
}

///|
test "update with identity function" {
  let a = @ref.new(1)
  a.update(x => x)
  assert_eq(a.val, 1)
}

///|
test "Ref::new with string" {
  let r = Ref::new("hello")
  inspect(r, content="{val: \"hello\"}")
}
