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
async test "manual cancel" {
  let buf = StringBuilder()
  @async.with_task_group(root => {
    let task = root.spawn(() => {
      match @async.handle_cancellation(() => @async.sleep(300)) {
        None => buf.write_string("cancelled\n")
        Some(_) => buf <+ "task finished\n"
      }
    })
    @async.sleep(100)
    task.cancel()
    @async.sleep(200)
    buf <+ "main task exit\n"
  })
  inspect(
    buf.to_string(),
    content=(
      #|cancelled
      #|main task exit
      #|
    ),
  )
}

///|
suberror Err derive(Debug)

///|
async test "error propagation" {
  let buf = StringBuilder()
  let err = @test.expect_error_async <| () => {
    @async.with_task_group(root => {
      root.spawn_bg() <| () => {
        @async.sleep(300)
        raise Err
      }
      root.spawn_bg() <| () => {
        let result = @async.handle_cancellation() <| () => {
          @async.sleep(200)
          buf <+ "task 2, tick 1\n"
          @async.sleep(200)
          buf <+ "task 2, tick 2\n"
        }
        match result {
          None => buf.write_string("task 2 cancelled\n")
          Some(_) => ()
        }
      }
    })
  }
  buf.write_string(@debug.to_string(err))
  inspect(
    buf.to_string(),
    content=(
      #|task 2, tick 1
      #|task 2 cancelled
      #|Err
    ),
  )
}

///|
async test "multiple scope" {
  let buf = StringBuilder()
  @async.with_task_group() <| root => {
    root.spawn_bg() <| () => {
      try
        @async.with_task_group() <| fn(ctx) {
          ctx.spawn_bg() <| () => {
            @async.sleep(200)
            raise Err
          }
          ctx.spawn_bg() <| () => {
            match @async.handle_cancellation(() => @async.sleep(400)) {
              None => buf.write_string("ctx 1 task 2 cancelled\n")
              Some(_) => buf <+ "ctx 1 task 2 finished\n"
            }
          }
        }
      catch {
        err => {
          buf <+ "ctx 1 received error "
          buf.write_string(@debug.to_string(err))
          buf.write_char('\n')
        }
      } noraise {
        _ => buf <+ "ctx 1 finished normally\n"
      }
    }
    root.spawn_bg() <| () => {
      try
        @async.with_task_group() <| fn(ctx) {
          ctx.spawn_bg() <| () => {
            @async.sleep(500)
            raise Err
          }
          ctx.spawn_bg() <| () => {
            match @async.handle_cancellation(() => @async.sleep(300)) {
              None => buf.write_string("ctx 2 task 2 cancelled\n")
              Some(_) => buf <+ "ctx 2 task 2 finished\n"
            }
          }
        }
      catch {
        err => {
          buf <+ "ctx 2 received error "
          buf.write_string(@debug.to_string(err))
          buf.write_char('\n')
        }
      } noraise {
        _ => buf <+ "ctx 2 finished normally\n"
      }
    }
  }
  inspect(
    buf.to_string(),
    content=(
      #|ctx 1 task 2 cancelled
      #|ctx 1 received error Err
      #|ctx 2 task 2 finished
      #|ctx 2 received error Err
      #|
    ),
  )
}

///|
async test "recursive cancel" {
  let buf = StringBuilder()
  @async.with_task_group(root => {
    root.spawn_bg() <| () => {
      for _ in 0..<2 {
        @async.sleep(400)
        buf <+ "tick\n"
      }
    }
    let task = root.spawn(() => {
      if @async.handle_cancellation(() => @async.sleep(1000)) is None {
        buf.write_string("first sleep cancelled\n")
      }
      if @async.handle_cancellation(() => @async.sleep(1000)) is None {
        buf.write_string("second sleep cancelled\n")
      }
      buf <+ "task finished\n"
    })
    @async.sleep(600)
    task.cancel()
    buf <+ "main task exit\n"
  })
  inspect(
    buf.to_string(),
    content=(
      #|tick
      #|main task exit
      #|first sleep cancelled
      #|second sleep cancelled
      #|task finished
      #|tick
      #|
    ),
  )
}

///|
async test "spawn directly error" {
  let buf = StringBuilder()
  let err = @test.expect_error_async <| () => {
    @async.with_task_group(root => {
      root.spawn_bg() <| () => {
        @async.with_task_group() <| group => {
          @async.sleep(1)
          group.spawn_bg(() => raise Err)
          buf <+ "after spawn\n"
          @async.sleep(400)
          buf <+ "main task exit\n"
        }
      }
      @async.sleep(200)
    })
  }
  buf.write_string(@debug.to_string(err))
  inspect(
    buf.to_string(),
    content=(
      #|after spawn
      #|Err
    ),
  )
}

///|
async test "error in cancellation" {
  let log = StringBuilder()
  let err = @test.expect_error_async <| () => {
    @async.with_task_group(root => {
      root.spawn_bg(no_wait=true) <| () => {
        match @async.handle_cancellation(() => @async.sleep(1000)) {
          None => {
            log <+ "causing other error in cancellation handler\n"
            raise Err
          }
          Some(_) => ()
        }
      }
      @async.sleep(200)
    })
  }
  log.write_string(@debug.to_string(err))
  inspect(
    log.to_string(),
    content=(
      #|causing other error in cancellation handler
      #|Err
    ),
  )
}

///|
async test "immediately cancelled" {
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    let task = root.spawn(() => {
      defer log.write_string("task terminated\n")
      log <+ "task started\n"
      @async.sleep(100)
      log <+ "task finished\n"
    })
    log <+ "task spawned\n"
    task.cancel()
  }
  inspect(
    log.to_string(),
    content=(
      #|task spawned
      #|task started
      #|task terminated
      #|
    ),
  )
}

///|
async test "immediate failure" {
  let result = @test.expect_error_async <| () => {
    @async.with_task_group(group => {
      group.spawn_bg(() => raise Failure::Failure("failure"))
      group.spawn_bg(() => group.spawn_bg(() => @async.sleep(100)))
    })
  }
  debug_inspect(
    result,
    content=(
      #|Failure("failure")
    ),
  )
}

//|

///|
async test "task group cancel & complete at the same time" {
  let log = []
  @async.with_task_group() <| outer => {
    @async.with_task_group() <| inner => {
      outer.spawn_bg(no_wait=true) <| () => {
        for i = 1; ; i = i + 1 {
          @async.pause()
          log.push("round #\{i}")
        }
      }
      // At round #1, the following things will happen in order:
      // - `inner.return_immediately()` is called,
      //   and all tasks in `inner` are cancelled,
      //   including the main task of `inner`.
      // - `task1` starts and completes, waking the main task of `inner`
      // So here we will have `.cancer()` and `.wake()` called on the same coroutine,
      // but the coroutine should be woken only once in this case.
      inner.spawn_bg(() => inner.return_immediately())
      let task1 = inner.spawn(() => ())
      match @async.handle_cancellation(() => task1.wait()) {
        None => {
          log.push("inner group main task cancelled")
          @async.protect_from_cancel() <| () => {
            @async.pause()
            log.push("inner group main task cleanup completed")
          }
        }
        Some(_) => ()
      }
    }
  }
  json_inspect(log, content=[
    "round #1", "inner group main task cancelled", "round #2", "inner group main task cleanup completed",
    "round #3",
  ])
}
