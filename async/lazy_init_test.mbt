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
  let start = @async.now()
  fn current_tick() -> Int32 {
    (@async.now() - start + 20).to_int() / 200
  }

  let x = @async.Lazy(() => {
    log.push("lazy init started at tick \{current_tick()}")
    @async.sleep(200)
    log.push("lazy init completed at tick \{current_tick()}")
  })
  @async.sleep(200)
  x.wait()
  log.push("got lazy init result at tick \{current_tick()}")
  x.wait()
  log.push("got lazy init result again at tick \{current_tick()}")
  json_inspect(log, content=[
    "lazy init started at tick 1", "lazy init completed at tick 2", "got lazy init result at tick 2",
    "got lazy init result again at tick 2",
  ])
}

///|
async test "lazy init failure" {
  let x : @async.Lazy[Unit] = Lazy(() => {
    @async.sleep(200)
    raise Failure::Failure("msg")
  })
  let start = @async.now()
  fn current_tick() -> Int32 {
    (@async.now() - start + 20).to_int() / 200
  }

  let result = @test.expect_error_async(() => x.wait())
  inspect(current_tick(), content="1")
  debug_inspect(
    result,
    content=(
      #|Failure("msg")
    ),
  )
  let result = @test.expect_error_async(() => x.wait())
  inspect(current_tick(), content="1")
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
  let start = @async.now()
  fn current_tick() -> Int32 {
    (@async.now() - start + 20).to_int() / 200
  }

  let x = @async.Lazy(() => {
    log.push("lazy init started at tick \{current_tick()}")
    match @async.handle_cancellation(() => @async.sleep(400)) {
      None => {
        log.push("lazy init cancelled at tick \{current_tick()}")
        @coroutine.check_cancellation()
      }
      Some(_) => log.push("lazy init completed at tick \{current_tick()}")
    }
  })
  debug_inspect(@async.with_timeout_opt(200, () => x.wait()), content="None")
  @async.sleep(100)
  // the previous attempt is already cancelled,
  // this `wait` will trigger a new attempt
  x.wait()
  json_inspect(log, content=[
    "lazy init started at tick 0", "lazy init cancelled at tick 1", "lazy init started at tick 1",
    "lazy init completed at tick 3",
  ])
}

///|
async test "lazy init multiple waiters 1" {
  let log = []
  let start = @async.now()
  fn current_tick() -> Int32 {
    (@async.now() - start + 20).to_int() / 200
  }

  let x = @async.Lazy(() => {
    log.push("lazy init started at tick \{current_tick()}")
    match @async.handle_cancellation(() => @async.sleep(400)) {
      None => log.push("lazy init cancelled at tick \{current_tick()}")
      Some(_) => log.push("lazy init completed at tick \{current_tick()}")
    }
  })
  @async.with_task_group(group => {
    group.spawn_bg() <| () => {
      x.wait()
      log.push("got lazy init value at tick \{current_tick()}")
    }
    debug_inspect(@async.with_timeout_opt(200, () => x.wait()), content="None")
  })
  json_inspect(log, content=[
    "lazy init started at tick 0", "lazy init completed at tick 2", "got lazy init value at tick 2",
  ])
}

///|
async test "lazy init multiple waiters 2" {
  let log = []
  let start = @async.now()
  fn current_tick() -> Int32 {
    (@async.now() - start + 20).to_int() / 200
  }

  let x = @async.Lazy(() => {
    log.push("lazy init started at tick \{current_tick()}")
    match @async.handle_cancellation(() => @async.sleep(600)) {
      None => log.push("lazy init cancelled at tick \{current_tick()}")
      Some(_) => log.push("lazy init completed at tick \{current_tick()}")
    }
  })
  @async.with_task_group() <| group => {
    group.spawn_bg() <| () => {
      debug_inspect(
        @async.with_timeout_opt(200, () => x.wait()),
        content="None",
      )
    }
    group.spawn_bg() <| () => {
      debug_inspect(
        @async.with_timeout_opt(400, () => x.wait()),
        content="None",
      )
    }
  }
  json_inspect(log, content=[
    "lazy init started at tick 0", "lazy init cancelled at tick 2",
  ])
}
