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
test "cancelling a finished coroutine leaves no ready task" {
  let coro = spawn(() => ())
  while has_immediately_ready_task() {
    reschedule()
  }
  guard! coro.unwrap() is Continue
  coro.cancel()
  assert_false(has_immediately_ready_task())
}

///|
test "a running coroutine cancelling itself leaves no ready task" {
  let _ = spawn(() => current_coroutine().cancel())
  reschedule()
  assert_false(has_immediately_ready_task())
}

///|
test "cancelling a suspended coroutine wakes it" {
  let coro = spawn(() => suspend())
  reschedule()
  assert_false(has_immediately_ready_task())
  coro.cancel()
  assert_true(has_immediately_ready_task())
  reschedule()
  guard! coro.unwrap() is Cancelled
}
