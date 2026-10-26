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
async test "lazy init basic" {
  let log = []
  let x = @async.Lazy(() => {
    log.push("lazy init started")
    @async.sleep(200)
    log.push("lazy init completed")
  })
  x.wait()
  log.push("wait#1 got lazy init result")
  @async.with_timeout(0, () => x.wait())
  json_inspect(log, content=[
    "lazy init started", "lazy init completed", "wait#1 got lazy init result",
  ])
}

///|
async test "lazy init failure" {
  let mut failed = false
  let x : @async.Lazy[Unit] = Lazy(() => {
    @async.sleep(200)
    failed = true
    raise Failure::Failure("msg")
  })
  let result = @test.expect_error_async(() => x.wait())
  assert_true(failed)
  debug_inspect(
    result,
    content=(
      #|Failure("msg")
    ),
  )
  let result = @test.expect_error_async(() => {
    @async.with_timeout(0, () => x.wait())
  })
  debug_inspect(
    result,
    content=(
      #|Failure("msg")
    ),
  )
}

///|
async test "lazy init cancelled" {
  let log = []
  let x = @async.Lazy(() => {
    log.push("lazy init started")
    match @async.handle_cancellation(() => @async.sleep(400)) {
      None => {
        log.push("lazy init cancelled")
        @coroutine.check_cancellation()
      }
      Some(_) => log.push("lazy init completed")
    }
  })
  debug_inspect(@async.with_timeout_opt(200, () => x.wait()), content="None")
  @async.sleep(100)
  // the previous attempt is already cancelled,
  // this `wait` will trigger a new attempt
  log.push("attempting second wait on lazy init")
  x.wait()
  json_inspect(log, content=[
    "lazy init started", "lazy init cancelled", "attempting second wait on lazy init",
    "lazy init started", "lazy init completed",
  ])
}

///|
async test "lazy init multiple waiters 1" {
  let log = []
  let cond = @async.Cond()
  let x = @async.Lazy(() => {
    log.push("lazy init started")
    cond.wait()
    assert_false(@async.is_being_cancelled())
    @async.sleep(200)
    log.push("lazy init completed")
  })
  @async.with_task_group(group => {
    group.spawn_bg() <| () => {
      x.wait()
      log.push("second wait got lazy init value")
    }
    debug_inspect(@async.with_timeout_opt(200, () => x.wait()), content="None")
    log.push("first wait timeout")
    cond.signal()
  })
  json_inspect(log, content=[
    "lazy init started", "first wait timeout", "lazy init completed", "second wait got lazy init value",
  ])
}

///|
async test "lazy init multiple waiters 2" {
  let log = []
  let cond = @async.Cond()

  let x = @async.Lazy(() => {
    log.push("lazy init started")
    match @async.handle_cancellation(() => cond.wait()) {
      None => {
        @async.protect_from_cancel(() => @async.sleep(50))
        log.push("lazy init cancelled")
      }
      Some(_) => log.push("lazy init completed")
    }
  })
  @async.with_task_group() <| group => {
    group.spawn_bg() <| () => {
      debug_inspect(
        @async.with_timeout_opt(200, () => x.wait()),
        content="None",
      )
      log.push("first wait cancelled")
    }
    group.spawn_bg() <| () => {
      debug_inspect(
        @async.with_timeout_opt(400, () => x.wait()),
        content="None",
      )
      log.push("second wait cancelled")
    }
  }
  @async.sleep(200)
  json_inspect(log, content=[
    "lazy init started", "first wait cancelled", "second wait cancelled", "lazy init cancelled",
  ])
}
