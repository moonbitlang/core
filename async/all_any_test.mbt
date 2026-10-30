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
async test "all basic" {
  let cond1 = @async.Cond()
  let cond2 = @async.Cond()
  @async.with_task_group <| group => {
    let mut both_signaled = false
    group.spawn_bg() <| () => {
      @async.sleep(200)
      cond1.signal()
      @async.sleep(200)
      cond2.signal()
      both_signaled = true
    }
    let results = @async.all([
      () => {
        cond1.wait()
        1
      },
      () => {
        cond2.wait()
        2
      },
      () => 3,
    ])
    assert_true(both_signaled)
    json_inspect(results, content=[1, 2, 3])
  }
}

///|
async test "all preserves order" {
  let log = []
  let conds = [ for _ in 0..<3 => @async.Cond() ]
  @async.with_task_group <| group => {
    group.spawn_bg() <| () => {
      for i in [2, 1, 0] {
        @async.sleep(200)
        conds[i].signal()
      }
    }
    let results = @async.all(
      [
        for i, cond in conds => {
          () => {
            cond.wait()
            log.push("task \{i}")
            i
          }
        }
      ],
    )
    json_inspect(log, content=["task 2", "task 1", "task 0"])
    json_inspect(results, content=[0, 1, 2])
  }
}

///|
async test "all with max_concurrent" {
  let log = []
  let conds = [ for _ in 0..<3 => @async.Cond() ]
  @async.with_task_group <| group => {
    group.spawn_bg() <| () => {
      for i in [1, 2, 0] {
        @async.sleep(200)
        conds[i].signal()
      }
    }
    let result = @async.all(
      [
        for i, cond in conds => {
          () => {
            log.push("task #\{i + 1} started")
            defer log.push("task #\{i + 1} completed")
            cond.wait()
            i
          }
        }
      ],
      max_concurrent=2,
    )
    json_inspect(result, content=[0, 1, 2])
    json_inspect(log, content=[
      "task #1 started", "task #2 started", "task #2 completed", "task #3 started",
      "task #3 completed", "task #1 completed",
    ])
  }
}

///|
async test "all empty" {
  let results : Array[Int32] = @async.all([])
  json_inspect(results, content=[])
}

///|
async test "all single task" {
  let result = @async.all([() => 42])
  json_inspect(result, content=[42])
}

///|
async test "all failure propagates" {
  let log = []
  let conds = [ for _ in 0..<3 => @async.Cond() ]
  @async.with_task_group <| group => {
    group.spawn_bg() <| () => {
      for i in 0..<3 {
        @async.sleep(200)
        conds[i].signal()
      }
    }
    let result = @test.expect_error_async <| () => {
      @async.all([
        () => {
          conds[0].wait()
          log.push("task #1 completed")
        },
        () => {
          conds[1].wait()
          log.push("task #2 failing")
          raise Failure::Failure("Err")
        },
        () => {
          match @async.handle_cancellation(() => conds[2].wait()) {
            None => log.push("task #3 cancelled")
            Some(_) => log.push("task #3 completed")
          }
        },
      ])
    }
    inspect(
      result,
      content=(
        #|Failure(Err)
      ),
    )
    json_inspect(log, content=[
      "task #1 completed", "task #2 failing", "task #3 cancelled",
    ])
  }
}

///|
async test "all cancelled" {
  let log = []
  async fn task(idx : Int32, sleep_time : Int32) -> Int32 {
    match @async.handle_cancellation(() => @async.sleep(sleep_time)) {
      None => log.push("task #\{idx} cancelled")
      Some(_) => log.push("task #\{idx} completed")
    }
    idx
  }

  let result = @async.with_timeout_opt(300, () => {
    @async.all([() => task(1, 450), () => task(2, 150)])
  })
  debug_inspect(result, content="None")
  json_inspect(log, content=["task #2 completed", "task #1 cancelled"])
}

///|
async test "any basic" {
  let conds = [ for _ in 0..<3 => @async.Cond() ]
  @async.with_task_group <| group => {
    group.spawn_bg(no_wait=true) <| () => {
      for i in [1, 0, 2] {
        @async.sleep(200)
        conds[i].signal()
      }
    }
    let result = @async.any(
      [
        for i, cond in conds => {
          () => {
            cond.wait()
            i + 1
          }
        }
      ],
    )
    inspect(result, content="2")
  }
}

///|
async test "any returns first success" {
  let log = []
  let conds = [ for _ in 0..<3 => @async.Cond() ]
  async fn task(idx : Int32) -> Int32 {
    match @async.handle_cancellation(() => conds[idx].wait()) {
      None => {
        log.push("task #\{idx + 1} cancelled")
        @coroutine.check_cancellation()
      }
      Some(_) => log.push("task #\{idx + 1} completed")
    }
    idx + 1
  }

  @async.with_task_group <| group => {
    group.spawn_bg(no_wait=true) <| () => {
      for i in [1, 0, 2] {
        @async.sleep(200)
        conds[i].signal()
      }
    }
    let result = @async.any([ for i in 0..<3 => () => task(i) ])
    json_inspect(result, content=2)
    json_inspect(log, content=[
      "task #2 completed", "task #1 cancelled", "task #3 cancelled",
    ])
  }
}

///|
async test "any failure without allow_failure" {
  let log = []
  let result = @test.expect_error_async <| () => {
    @async.any([
      () => {
        match @async.handle_cancellation(() => @async.sleep(1000)) {
          None => log.push("task #1 cancelled")
          Some(_) => log.push("task #1 completed")
        }
      },
      () => {
        @async.sleep(200)
        raise Failure::Failure("Err")
      },
    ])
  }
  inspect(
    result,
    content=(
      #|Failure(Err)
    ),
  )
  json_inspect(log, content=["task #1 cancelled"])
}

///|
async test "any with allow_failure" {
  let log = []
  let conds = [ for _ in 0..<3 => @async.Cond() ]
  let results : ReadOnlyArray[Result[_, Error]] = [
    Err(Err),
    Err(Failure("fail")),
    Ok(2),
  ]
  @async.with_task_group <| group => {
    group.spawn_bg(no_wait=true) <| () => {
      for i in [1, 0, 2] {
        @async.sleep(200)
        conds[i].signal()
      }
    }
    let result = @async.any(
      [
        for i, cond in conds => {
          () => {
            cond.wait()
            match results[i] {
              Ok(ret) => {
                log.push("task #\{i + 1} completed")
                ret
              }
              Err(err) => {
                log.push("task #\{i + 1} failing")
                raise err
              }
            }
          }
        }
      ],
      allow_failure=true,
    )
    json_inspect(log, content=[
      "task #2 failing", "task #1 failing", "task #3 completed",
    ])
    json_inspect(result, content=2)
  }
}

///|
async test "any with allow_failure all fail" {
  let log = []
  let cond = @async.Cond()
  let result : Error = @test.expect_error_async <| async fn() -> Unit {
    @async.any(
      [
        () => {
          cond.wait()
          log.push("task #1 failing")
          raise Err
        },
        () => {
          @async.sleep(150)
          log.push("task #2 failing")
          cond.signal()
          raise Failure::Failure("fail")
        },
      ],
      allow_failure=true,
    )
  }
  json_inspect(log, content=["task #2 failing", "task #1 failing"])
  debug_inspect(result, content="Err")
}

///|
async test "any single task" {
  let result = @async.any([() => 42])
  json_inspect(result, content=42)
}

///|
async test "any empty fails" {
  debug_inspect(
    @test.expect_error_async(() => (@async.any([]) : Unit)),
    content=(
      #|Failure("async/all_any_test.mbt:333:37-333:51@moonbitlang/core FAILED: no tasks provided to any()")
    ),
  )
}

///|
async test "any cancelled" {
  let log = []
  let cond = @async.Cond()
  async fn task(idx : Int32) -> Int32 {
    match @async.handle_cancellation(() => cond.wait()) {
      None => log.push("task #\{idx} cancelled")
      Some(_) => log.push("task #\{idx} completed")
    }
    idx
  }

  let result = @async.with_timeout_opt(200, () => {
    @async.any([() => task(1), () => task(2)])
  })
  debug_inspect(result, content="None")
  json_inspect(log, content=["task #1 cancelled", "task #2 cancelled"])
}
