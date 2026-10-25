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
test "non-cancellable pause preserves round robin scheduling" {
  let log : Array[Int32] = []
  let a = spawn(() => {
    for _ in 0..<3 {
      log.push(1)
      pause_nocancel()
    }
  })
  let b = spawn(() => {
    for _ in 0..<3 {
      log.push(2)
      pause_nocancel()
    }
  })
  while has_immediately_ready_task() {
    reschedule()
  }
  guard! a.unwrap() is Continue
  guard! b.unwrap() is Continue
  @test.assert_eq(log, [1, 2, 1, 2, 1, 2])
}

///|
test "non-cancellable pause completes then preserves cancellation" {
  let log : Array[String] = []
  let _ = spawn(() => {
    let self = current_coroutine()
    log.push("started")
    self.cancel()
    pause_nocancel()
    log.push("completed")
    assert_false(self.shielded)
    assert_true(self.cancelled)
  })
  while has_immediately_ready_task() {
    reschedule()
  }
  @json.json_inspect(log, content=["started", "completed"])
}

///|
test "non-cancellable pause restores an enclosing cancellation shield" {
  let log : Array[String] = []
  let _ = spawn(() => {
    let self = current_coroutine()
    protect_from_cancel(() => {
      self.cancel()
      pause_nocancel()
      log.push("completed")
      assert_true(self.shielded)
      assert_true(self.cancelled)
    })
    assert_false(self.shielded)
    assert_true(self.cancelled)
  })
  while has_immediately_ready_task() {
    reschedule()
  }
  @test.assert_eq(log, ["completed"])
}

///|
test "non-cancellable pause cancelled during suspension" {
  let log : Array[String] = []
  let a = spawn(() => {
    log.push("started")
    pause_nocancel()
    log.push("completed")
    check_cancellation()
    log.push("unreachable")
  })
  reschedule()
  @test.assert_eq(log, ["started"])
  a.cancel()
  while has_immediately_ready_task() {
    reschedule()
  }
  guard! a.unwrap() is Cancelled
  @test.assert_eq(log, ["started", "completed"])
}
