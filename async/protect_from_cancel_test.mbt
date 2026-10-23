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
async test "protect_from_cancel" {
  let log = StringBuilder()
  @async.with_task_group(root => {
    root.spawn_bg() <| () => {
      @async.protect_from_cancel <| () => {
        match @async.handle_cancellation(() => @async.sleep(400)) {
          None => log.write_string("critial job cancelled\n")
          Some(_) => log <+ "critical job finished\n"
        }
      }
      match @async.handle_cancellation(() => @async.sleep(200)) {
        None => log <+ "job cancelled after critical part\n"
        Some(_) => log <+ "non-critial part of job finished\n"
      }
    }
    root.spawn_bg() <| () => {
      match @async.handle_cancellation(() => @async.sleep(400)) {
        None => log.write_string("non-critial job cancelled\n")
        Some(_) => log <+ "non-critical job finished\n"
      }
    }
    @async.sleep(200)
    raise Err
  }) catch {
    err => log.write_string(@debug.to_string(err))
  }
  inspect(
    log.to_string(),
    content=(
      #|non-critial job cancelled
      #|critical job finished
      #|job cancelled after critical part
      #|Err
    ),
  )
}

///|
async test "protect_from_cancel wait" {
  let log = StringBuilder()
  @async.with_task_group(root => {
    root.spawn_bg() <| () => {
      @async.sleep(200)
      log <+ "200ms tick\n"
      @async.sleep(200)
      log <+ "400ms tick\n"
    }
    @async.with_task_group(group => {
      group.spawn_bg() <| () => {
        @async.sleep(300)
        log.write_string("trying to cancel the group containing critial job\n")
        raise Err
      }
      @async.protect_from_cancel() <| () => {
        @async.sleep(500)
        log <+ "critial job finished\n"
      }
    }) catch {
      _ => ()
    }
    log <+ "task group containing critical job finished\n"
  })
  inspect(
    log.to_string(),
    content=(
      #|200ms tick
      #|trying to cancel the group containing critial job
      #|400ms tick
      #|critial job finished
      #|task group containing critical job finished
      #|
    ),
  )
}

///|
async test "protect_from_cancel with_timeout" {
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    root.spawn_bg() <| () => {
      @async.sleep(200)
      log <+ "200ms tick\n"
      @async.sleep(200)
      log <+ "400ms tick\n"
    }
    @async.with_timeout_opt(300, () => {
      @async.protect_from_cancel() <| () => {
        @async.sleep(500)
        log <+ "critial job finished\n"
      }
    })
    |> ignore
    log <+ "`with_timeout` containing critical job finished\n"
  }
  inspect(
    log.to_string(),
    content=(
      #|200ms tick
      #|400ms tick
      #|critial job finished
      #|`with_timeout` containing critical job finished
      #|
    ),
  )
}

///|
async test "protect_from_cancel fail" {
  let log = StringBuilder()
  let result : Error = @test.expect_error_async <| () => {
    (
      @async.with_task_group(root => {
        root.spawn_bg() <| () => {
          @async.sleep(200)
          log <+ "200ms tick\n"
          @async.sleep(200)
          log <+ "400ms tick\n"
        }
        @async.with_timeout(300, () => {
          @async.protect_from_cancel() <| () => {
            @async.sleep(500)
            log <+ "critial job fail\n"
            raise Err
          }
        })
      }) : Unit)
  }
  log.write_string(@debug.to_string(result))
  inspect(
    log.to_string(),
    content=(
      #|200ms tick
      #|400ms tick
      #|critial job fail
      #|Err
    ),
  )
}

///|
async test "protect_from_cancel nested1" {
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    root.spawn_bg() <| () => {
      @async.sleep(200)
      log <+ "200ms tick\n"
      @async.sleep(200)
      log <+ "400ms tick\n"
    }
    @async.with_timeout_opt(300, () => {
      @async.protect_from_cancel() <| () => {
        @async.protect_from_cancel() <| () => {
          @async.sleep(500)
          log <+ "critial job finished\n"
        }
      }
    })
    |> ignore
    log <+ "`with_timeout` containing critical job finished\n"
  }
  inspect(
    log.to_string(),
    content=(
      #|200ms tick
      #|400ms tick
      #|critial job finished
      #|`with_timeout` containing critical job finished
      #|
    ),
  )
}

///|
async test "protect_from_cancel nested2" {
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    root.spawn_bg() <| () => {
      @async.sleep(200)
      log <+ "200ms tick\n"
      @async.sleep(200)
      log <+ "400ms tick\n"
      @async.sleep(200)
      log <+ "600ms tick\n"
    }
    @async.with_timeout_opt(100, () => {
      @async.protect_from_cancel() <| () => {
        @async.protect_from_cancel() <| () => {
          @async.sleep(300)
          log <+ "inner critial job finished\n"
        }
        @async.sleep(200)
        log <+ "outer critial job finished\n"
      }
    })
    |> ignore
    log <+ "`with_timeout` containing critical job finished\n"
  }
  inspect(
    log.to_string(),
    content=(
      #|200ms tick
      #|inner critial job finished
      #|400ms tick
      #|outer critial job finished
      #|`with_timeout` containing critical job finished
      #|600ms tick
      #|
    ),
  )
}

///|
async test "protect_from_cancel in cancellation handler" {
  let log = StringBuilder()
  @async.with_task_group(root => {
    root.spawn_bg(no_wait=true) <| () => {
      match @async.handle_cancellation(() => @async.sleep(400)) {
        None => {
          log.write_string("cancelled\n")
          @async.protect_from_cancel() <| () => {
            @async.sleep(200)
            log <+ "critial cancellation handler terminated\n"
          }
        }
        Some(_) => ()
      }
    }
    @async.sleep(200)
    log <+ "start cancellation\n"
  })
  inspect(
    log.to_string(),
    content=(
      #|start cancellation
      #|cancelled
      #|critial cancellation handler terminated
      #|
    ),
  )
}

///|
async test "cancel while scheduled" {
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    root.spawn_bg() <| () => {
      for _ in 0..<2 {
        @async.sleep(200)
        log <+ "tick\n"
      }
    }
    let task1 = root.spawn(() => {
      // after calling `pause`, current coroutine would be in `run_later`,
      // and it will receive cancellation in this situation
      match @async.handle_cancellation(() => @async.pause()) {
        None => {
          log.write_string("`pause` cancelled\n")
          @async.protect_from_cancel() <| () => {
            // Now, due to `protect_from_cancel`,
            // we are allowed to suspend inside cancellation handler.
            // However, since current coroutine is still in `run_later`,
            // the scheduler will wakeup current coroutine immediately,
            // before the timer expires.
            @async.sleep(300)
            log <+ "async cleanup finished\n"
          }
        }
        Some(_) => ()
      }
    })
    root.spawn_bg(() => task1.cancel())
  }
  inspect(
    log.to_string(),
    content=(
      #|`pause` cancelled
      #|tick
      #|async cleanup finished
      #|tick
      #|
    ),
  )
}

///|
async test "error in async cancel" {
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    root.spawn_bg() <| () => {
      for _ in 0..<2 {
        @async.sleep(300)
        log <+ "tick\n"
      }
    }
    @async.with_task_group(group => {
      group.spawn_bg(no_wait=true, allow_failure=true) <| () => {
        errdefer {
          log <+ "performing async cleanup\n"
          @async.protect_from_cancel() <| () => {
            @async.sleep(300)
            log <+ "raising error from async cleanup\n"
            raise Err
          }
        }
        @async.sleep(1000)
      }
      @async.sleep(150)
      log <+ "main task of inner group done\n"
    })
    log <+ "group terminates\n"
  }
  inspect(
    log.to_string(),
    content=(
      #|main task of inner group done
      #|performing async cleanup
      #|tick
      #|raising error from async cleanup
      #|group terminates
      #|tick
      #|
    ),
  )
}
