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
  inspect(x, content="{val: 1}")
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

///|
test "map with error handling" {
  let x = @ref.new(10)
  let result = try? x.map(a => {
    if a > 5 {
      fail("value too large")
    }
    a * 2
  })
  assert_true(result is Err(_))
  let y = @ref.new(3)
  let result2 = try? y.map(a => {
    if a > 5 {
      fail("value too large")
    }
    a * 2
  })
  match result2 {
    Ok(r) => assert_eq(r.val, 6)
    Err(_) => assert_true(false)
  }
}

///|
test "update with error handling" {
  let x = @ref.new(5)
  let result = try? x.update(a => {
    if a == 5 {
      fail("cannot update value 5")
    }
    a + 1
  })
  assert_true(result is Err(_))
  assert_eq(x.val, 5) // value should remain unchanged on error
  let y = @ref.new(3)
  y.update(a => a + 1)
  assert_eq(y.val, 4)
}

///|
test "arbitrary ref samples" {
  let samples = (@quickcheck.samples(3) : Array[Ref[Int]])
  inspect(samples.length(), content="3")
}
