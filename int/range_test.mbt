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

// POC: one generic `range` over a `Step` trait, to see whether a single
// entry point could replace per-type `Int::until` / `Int64::until` / etc.

///|
trait Step {
  step_add(Self, Self) -> Self
  step_lt(Self, Self) -> Bool
}

///|
impl Step for Int with step_add(a, b) {
  a + b
}

///|
impl Step for Int with step_lt(a, b) {
  a < b
}

///|
impl Step for Int64 with step_add(a, b) {
  a + b
}

///|
impl Step for Int64 with step_lt(a, b) {
  a < b
}

///|
fn[T : Step] range(start : T, end : T, step : T) -> Iter[T] {
  let mut i = start
  Iter::new(() => {
    guard T::step_lt(i, end) else { None }
    let v = i
    i = T::step_add(i, step)
    Some(v)
  })
}

///|
test "range poc - Int" {
  inspect(range(0, 10, 3), content="[0, 3, 6, 9]")
  inspect(range(0, 5, 1), content="[0, 1, 2, 3, 4]")
  inspect(range(10, 0, 1), content="[]")
}

///|
test "range poc - Int64" {
  inspect(range(0L, 10L, 3L), content="[0, 3, 6, 9]")
  inspect(range(0L, 5L, 1L), content="[0, 1, 2, 3, 4]")
}
