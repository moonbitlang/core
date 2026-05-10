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
test "Lazy defers evaluation" {
  let mut runs = 0
  let cell = @lazy.Lazy(() => {
    runs += 1
    "hello"
  })
  assert_eq(runs, 0)
  assert_eq(cell.force(), "hello")
  assert_eq(runs, 1)
}

///|
test "force memoizes the result" {
  let mut runs = 0
  let cell = @lazy.Lazy(() => {
    runs += 1
    runs * 10
  })
  assert_eq(cell.force(), 10)
  assert_eq(cell.force(), 10)
  assert_eq(cell.force(), 10)
  assert_eq(runs, 1)
}

///|
test "ready returns the value without running anything" {
  let cell = @lazy.ready(99)
  assert_eq(cell.force(), 99)
  assert_eq(cell.force(), 99)
}

///|
test "force returns each captured value" {
  let cells = [@lazy.Lazy(() => 1), @lazy.Lazy(() => 2), @lazy.Lazy(() => 3)]
  let mut sum = 0
  for c in cells {
    sum += c.force()
  }
  assert_eq(sum, 6)
}

///|
test "Result-as-data bridge for fallible thunks" {
  let mut runs = 0
  let cell : @lazy.Lazy[Result[Int, Error]] = @lazy.Lazy(() => {
    runs += 1
    try? ({
      if runs > 1 {
        fail("should not re-run")
      }
      runs
    })
  })
  assert_true(cell.force() is Ok(1))
  assert_true(cell.force() is Ok(1))
  assert_eq(runs, 1)
}
