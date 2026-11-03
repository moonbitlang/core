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
async test "basic sleep" {
  let buf = StringBuilder()
  @async.with_task_group() <| root => {
    root.spawn_bg() <| () => {
      @async.sleep(100)
      buf <+ "task 1, tick 1\n"
      @async.sleep(200)
      buf <+ "task 1, tick 2\n"
      @async.sleep(200)
      buf <+ "task 1, tick 3\n"
    }
    root.spawn_bg() <| () => {
      @async.sleep(200)
      buf <+ "task 2, tick 1\n"
      @async.sleep(200)
      buf <+ "task 2, tick 2\n"
      @async.sleep(200)
      buf <+ "task 2, tick 3\n"
    }
  }
  inspect(
    buf.to_string(),
    content=(
      #|task 1, tick 1
      #|task 2, tick 1
      #|task 1, tick 2
      #|task 2, tick 2
      #|task 1, tick 3
      #|task 2, tick 3
      #|
    ),
  )
}

///|
async test "Timer basic" {
  let log = []
  @async.with_task_group() <| group => {
    group.spawn_bg() <| () => {
      @async.sleep(150)
      log.push("sleep: tick #1")
      @async.sleep(300)
      log.push("sleep: tick #2")
      @async.sleep(300)
      log.push("sleep: tick #3")
    }
    @async.sleep(300)
    log.push("creating timer")
    let timer = @async.Timer(300)
    @async.with_task_group() <| group => {
      for _ in 0..<3 {
        group.spawn_bg() <| () => {
          timer.wait()
          log.push("timer completed")
        }
      }
    }
    let result = @async.with_timeout_opt(0, () => timer.wait())
    log.push("wait again: \{@debug.to_string(result)}")
  }
  json_inspect(log, content=[
    "sleep: tick #1", "creating timer", "sleep: tick #2", "timer completed", "timer completed",
    "timer completed", "wait again: Some(())", "sleep: tick #3",
  ])
}

///|
async test "Timer no waiter" {
  let timer = @async.Timer(200)
  @async.sleep(400)
  debug_inspect(
    @async.with_timeout_opt(0, () => timer.wait()),
    content=(
      #|Some(())
    ),
  )
}

///|
async test "Timer no one waiting" {
  let _ = @async.Timer(1000000)
  @async.pause()
}

///|
async test "Timer waiter cancelled 1" {
  let timer = @async.Timer(600)
  assert_true(@async.with_timeout_opt(200, () => timer.wait()) is None)
  @async.sleep(200)
  assert_false(@async.with_timeout_opt(300, () => timer.wait()) is None)
}

///|
async test "Timer waiter cancelled 2" {
  let timer = @async.Timer(300)
  assert_true(@async.with_timeout_opt(200, () => timer.wait()) is None)
  @async.sleep(200)
  assert_false(@async.with_timeout_opt(0, () => timer.wait()) is None)
}

///|
async test "Timer::cancel" {
  let log = []
  let timer = @async.Timer(450)
  @async.with_task_group() <| group => {
    group.spawn_bg() <| () => {
      @async.sleep(150)
      timer.cancel()
    }
    group.spawn_bg() <| () => {
      let result = @test.expect_error_async(() => timer.wait())
      log.push("Timer::wait(): \{@debug.to_string(result)}")
    }
    @async.sleep(600)
    let err = @test.expect_error_async(() => timer.wait())
    log.push("wait after cancellation: \{@debug.to_string(err)}")
    timer.cancel()
    let err = @test.expect_error_async(() => timer.wait())
    log.push("wait after repeated cancellation: \{@debug.to_string(err)}")
  }
  json_inspect(log, content=[
    "Timer::wait(): TimerCancelled", "wait after cancellation: TimerCancelled", "wait after repeated cancellation: TimerCancelled",
  ])
}

///|
async test "Timer::refresh has waiter" {
  let log = []
  let mut refreshed_at = @async.now()
  let timer = @async.Timer(300)
  @async.with_task_group() <| group => {
    group.spawn_bg() <| () => {
      timer.wait()
      // Keep the previous 50ms early tolerance, with no upper bound on lateness.
      assert_true(@async.now() - refreshed_at >= 250)
      log.push("Timer::wait() completed")
    }
    group.spawn_bg() <| () => {
      @async.sleep(150)
      log.push("refresh timer #1")
      refreshed_at = @async.now()
      timer.refresh()
      // Sequence the refreshes instead of racing two independently scheduled tasks.
      @async.sleep(150)
      log.push("refresh timer #2")
      refreshed_at = @async.now()
      timer.refresh()
    }
  }
  json_inspect(log, content=[
    "refresh timer #1", "refresh timer #2", "Timer::wait() completed",
  ])
}

///|
async test "Timer::refresh no waiter" {
  let timer = @async.Timer(300)
  @async.sleep(150)
  let refreshed_at = @async.now()
  timer.refresh()
  timer.wait()
  // A no-op refresh would leave at most 150ms on the original deadline.
  // There is no upper bound: a busy runner may resume the task late.
  assert_true(@async.now() - refreshed_at >= 250)
}

///|
async test "Timer::refresh already terminated" {
  let timer = @async.Timer(300)
  timer.wait()
  let refreshed_at = @async.now()
  timer.refresh()
  timer.wait()
  assert_true(@async.now() - refreshed_at >= 250)
}

///|
async test "Timer::refresh already cancelled" {
  let timer = @async.Timer(300)
  timer.cancel()
  timer.refresh()
  debug_inspect(
    @async.with_timeout_opt(0, () => {
      @test.expect_error_async(() => timer.wait())
    }),
    content=(
      #|Some(TimerCancelled)
    ),
  )
}
