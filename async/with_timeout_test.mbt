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
async test "with_timeout normal exit" {
  let log = []
  @async.with_task_group(root => {
    root.spawn_bg() <| () => {
      @async.sleep(300)
      log.push("300ms tick")
    }
    @async.with_timeout(400) <| () => {
      @async.sleep(200)
      log.push("task finished after 200ms")
    }
    log.push("main task finished")
  })
  json_inspect(log, content=[
    "task finished after 200ms", "main task finished", "300ms tick",
  ])
}

///|
#warnings("-fragile_catch_all")
async test "with_timeout failure" {
  let log = StringBuilder()
  @async.with_task_group(root => {
    root.spawn_bg() <| () => {
      @async.sleep(200)
      log <+ "200ms tick\n"
    }
    @async.with_timeout(300, () => {
      @async.sleep(100)
      raise Err
    }) catch {
      err => {
        log <+ "main task fail with \{@debug.to_string(err)}\n"
        raise err
      }
    }
  }) catch {
    err => log.write_string(@debug.to_string(err))
  }
  inspect(
    log.to_string(),
    content=(
      #|main task fail with Err
      #|Err
    ),
  )
}

///|
async test "with_timeout timeout" {
  let log = StringBuilder()
  @async.with_task_group(root => {
    root.spawn_bg() <| () => {
      @async.sleep(300)
      log <+ "300ms tick\n"
    }
    @async.with_timeout(200, () => {
      match @async.handle_cancellation(() => @async.sleep(400)) {
        None => {
          log <+ "task cancelled\n"
          @coroutine.raise_cancellation_signal()
        }
        Some(_) => log <+ "task finished\n"
      }
    }) catch {
      err => log <+ "`with_timeout` fail with \{err}\n"
    }
    log <+ "main task finished\n"
  })
  inspect(
    log.to_string(),
    content=(
      #|task cancelled
      #|`with_timeout` fail with TimeoutError
      #|main task finished
      #|300ms tick
      #|
    ),
  )
}

///|
async test "with_timeout nested1" {
  let log = StringBuilder()
  @async.with_task_group(root => {
    root.spawn_bg() <| () => {
      @async.sleep(200)
      log <+ "200ms tick\n"
      @async.sleep(200)
      log <+ "400ms tick\n"
    }
    @async.with_timeout(300, () => {
      let result = @async.handle_cancellation() <| () => {
        @async.with_timeout(500) <| () => {
          match @async.handle_cancellation(() => @async.sleep(2000)) {
            None => {
              log <+ "task cancelled\n"
              @coroutine.raise_cancellation_signal()
            }
            Some(_) => log <+ "task finished after 2s\n"
          }
        }
      }
      match result {
        None => {
          log <+ "inner `with_timeout` cancelled\n"
          @coroutine.raise_cancellation_signal()
        }
        Some(_) => ()
      }
    }) catch {
      err => log <+ "outer `with_timeout` fail with \{err}\n"
    }
    log <+ "main task finished\n"
  })
  inspect(
    log.to_string(),
    content=(
      #|200ms tick
      #|task cancelled
      #|inner `with_timeout` cancelled
      #|outer `with_timeout` fail with TimeoutError
      #|main task finished
      #|400ms tick
      #|
    ),
  )
}

///|
async test "with_timeout nested2" {
  let log = StringBuilder()
  @async.with_task_group(root => {
    root.spawn_bg() <| () => {
      @async.sleep(300)
      log <+ "300ms tick\n"
      @async.sleep(300)
      log <+ "600ms tick\n"
    }
    @async.with_timeout(750, () => {
      @async.with_timeout(450, () => {
        match @async.handle_cancellation(() => @async.sleep(2000)) {
          None => {
            log <+ "task cancelled\n"
            @coroutine.raise_cancellation_signal()
          }
          Some(_) => log <+ "task finished after 2s\n"
        }
      }) catch {
        err => log <+ "inner `with_timeout` fail with \{err}\n"
      }
    }) catch {
      err => log <+ "outer `with_timeout` fail with \{err}\n"
    }
    log <+ "main task finished\n"
  })
  inspect(
    log.to_string(),
    content=(
      #|300ms tick
      #|task cancelled
      #|inner `with_timeout` fail with TimeoutError
      #|main task finished
      #|600ms tick
      #|
    ),
  )
}

///|
async test "with_timeout error_on_cancel" {
  let log = StringBuilder()
  let err = @test.expect_error_async <| () => {
    @async.with_task_group(root => {
      root.spawn_bg() <| () => {
        @async.sleep(200)
        log <+ "200ms tick\n"
      }
      @async.with_timeout(100) <| () => {
        match @async.handle_cancellation(() => @async.sleep(2000)) {
          None => {
            log <+ "causing other error on cancellation\n"
            raise Err
          }
          Some(_) => log <+ "task finished after 2s\n"
        }
      }
      log <+ "main task finished\n"
    })
  }
  log.write_string(@debug.to_string(err))
  inspect(
    log.to_string(),
    content=(
      #|causing other error on cancellation
      #|Err
    ),
  )
}

///|
async test "with_timeout error-on-timeout" {
  let log = StringBuilder()
  let err = @test.expect_error_async <| () => {
    @async.with_task_group(root => {
      root.spawn_bg() <| () => {
        @async.sleep(200)
        log <+ "200ms tick\n"
      }
      defer log <+ "main task terminates\n"
      @async.with_timeout(100, error=Err) <| () => {
        match @async.handle_cancellation(() => @async.sleep(2000)) {
          None => {
            log <+ "task cancelled\n"
            @coroutine.raise_cancellation_signal()
          }
          Some(_) => log <+ "task finished after 2s\n"
        }
      }
    })
  }
  log.write_string(@debug.to_string(err))
  inspect(
    log.to_string(),
    content=(
      #|task cancelled
      #|main task terminates
      #|Err
    ),
  )
}

///|
async test "with_timeout_opt normal exit" {
  let log = []
  @async.with_task_group(root => {
    root.spawn_bg() <| () => {
      @async.sleep(200)
      log.push("200ms tick")
    }
    let result = @async.with_timeout_opt(1000, () => {
      @async.sleep(100)
      log.push("task finished after 100ms")
      42
    })
    log.push(@debug.to_string(result))
  })
  json_inspect(log, content=[
    "task finished after 100ms", "Some(42)", "200ms tick",
  ])
}

///|
#warnings("-fragile_catch_all")
async test "with_timeout_opt failure" {
  let log = StringBuilder()
  @async.with_task_group(root => {
    root.spawn_bg() <| () => {
      @async.sleep(200)
      log <+ "200ms tick\n"
    }
    @async.with_timeout(1000, () => {
      @async.sleep(100)
      raise Err
    }) catch {
      err => {
        log <+ "main task fail with \{@debug.to_string(err)}\n"
        raise err
      }
    }
  }) catch {
    err => log.write_string(@debug.to_string(err))
  }
  inspect(
    log.to_string(),
    content=(
      #|main task fail with Err
      #|Err
    ),
  )
}

///|
async test "with_timeout_opt timeout" {
  let log = []
  @async.with_task_group() <| root => {
    root.spawn_bg() <| () => {
      @async.sleep(200)
      log.push("200ms tick")
    }
    let result = @async.with_timeout_opt(100, () => {
      match @async.handle_cancellation(() => @async.sleep(2000)) {
        None => {
          log.push("task cancelled")
          @coroutine.raise_cancellation_signal()
        }
        Some(_) => log.push("task finished after 2s")
      }
      42
    })
    log.push(@debug.to_string(result))
  }
  json_inspect(log, content=["task cancelled", "None", "200ms tick"])
}
