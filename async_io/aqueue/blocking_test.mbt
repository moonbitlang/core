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
async test "blocking unbuffered" {
  let log = []
  @async_io.with_task_group() <| group => {
    let q = @async_io.Queue(kind=Blocking(1))
    group.spawn_bg() <| () => {
      for i in 0..<3 {
        q.put(i)
        log.push("put(\{i})")
      }
    }
    group.spawn_bg() <| () => {
      for _ in 0..<3 {
        let x = q.get()
        log.push("get() => \{x}")
        @async_io.sleep(100)
      }
    }
  }
  json_inspect(log, content=[
    "put(0)", "get() => 0", "put(1)", "get() => 1", "put(2)", "get() => 2",
  ])
}

///|
async test "blocking buffered" {
  let log = []
  @async_io.with_task_group() <| group => {
    let q = @async_io.Queue(kind=Blocking(2))
    group.spawn_bg() <| () => {
      for i in 0..<4 {
        q.put(i)
        log.push("put(\{i})")
      }
    }
    group.spawn_bg() <| () => {
      for _ in 0..<4 {
        let x = q.get()
        log.push("get() => \{x}")
        @async_io.sleep(100)
      }
    }
  }
  json_inspect(log, content=[
    "put(0)", "put(1)", "get() => 0", "put(2)", "get() => 1", "put(3)", "get() => 2",
    "get() => 3",
  ])
}

///|
async test "blocking fairness" {
  let log = []
  @async_io.with_task_group() <| group => {
    let q = @async_io.Queue(kind=Blocking(1))
    q.put(0)
    group.spawn_bg() <| () => {
      for i in 0..<3 {
        q.put(i)
        log.push("task 1 put(\{i})")
      }
    }
    group.spawn_bg() <| () => {
      for i in 0..<3 {
        q.put(i)
        log.push("task 2 put(\{i})")
      }
    }
    group.spawn_bg(no_wait=true) <| () => {
      for ;; {
        @async_io.sleep(100)
        ignore(q.get())
      }
    }
  }
  json_inspect(log, content=[
    "task 1 put(0)", "task 2 put(0)", "task 1 put(1)", "task 2 put(1)", "task 1 put(2)",
    "task 2 put(2)",
  ])
}

///|
async test "blocking cancellation" {
  let log = []
  @async_io.with_task_group() <| group => {
    let q = @async_io.Queue(kind=Blocking(1))
    q.put(0)
    group.spawn_bg(no_wait=true) <| () => {
      @async_io.sleep(250)
      ignore(q.get())
    }
    @async_io.with_timeout(500, () => {
      for ;; {
        match @async_io.handle_cancellation(() => q.put(0)) {
          None => {
            log.push("put() cancelled")
            break
          }
          Some(_) => log.push("put() completed")
        }
      }
    }) catch {
      @async_io.TimeoutError => ()
      err => raise err
    }
  }
  json_inspect(log, content=["put() completed", "put() cancelled"])
}

///|
async test "blocking fairness2" {
  let log = []
  @async_io.with_task_group() <| root => {
    let queue = @async_io.Queue(kind=Blocking(1))
    queue.put(0)
    root.spawn_bg() <| () => {
      for i in 0..<2 {
        queue.put(i)
        log.push("task 1: put() completed")
        @async_io.sleep(200)
        let x = queue.get()
        log.push("task 1: get() => \{x}")
      }
    }
    root.spawn_bg() <| () => {
      @async_io.sleep(100)
      for i in 0..<2 {
        queue.put(i)
        log.push("task 2: put() completed")
        @async_io.sleep(200)
        let x = queue.get()
        log.push("task 2: get() => \{x}")
      }
    }
    @async_io.sleep(200)
    inspect(queue.get(), content="0")
  }
  json_inspect(log, content=[
    "task 1: put() completed", "task 1: get() => 0", "task 2: put() completed", "task 2: get() => 0",
    "task 1: put() completed", "task 1: get() => 1", "task 2: put() completed", "task 2: get() => 1",
  ])
}

///|
async test "blocking immediate cancellation" {
  let log = []
  @async_io.with_task_group() <| group => {
    let q = @async_io.Queue(kind=Blocking(1))
    q.put(0)
    let put_task = group.spawn(() => {
      match @async_io.handle_cancellation(() => q.put(1)) {
        None => log.push("put() cancelled")
        Some(_) => log.push("put() completed")
      }
    })
    @async_io.sleep(100)
    let _ = q.get()
    put_task.cancel()
    @async_io.sleep(100)
    debug_inspect(q.try_get(), content="Some(1)")
  }
  json_inspect(log, content=["put() completed"])
}

///|
async test "blocking zero buffered" {
  let log = []
  @async_io.with_task_group() <| group => {
    let q = @async_io.Queue(kind=Blocking(0))
    group.spawn_bg() <| () => {
      for i in 0..<4 {
        q.put(i)
        log.push("put(\{i})")
      }
    }
    group.spawn_bg() <| () => {
      for _ in 0..<4 {
        let x = q.get()
        log.push("get() => \{x}")
        @async_io.sleep(100)
      }
    }
  }
  json_inspect(log, content=[
    "get() => 0", "put(0)", "get() => 1", "put(1)", "get() => 2", "put(2)", "get() => 3",
    "put(3)",
  ])
}

///|
async test "zero buffered try_put" {
  let q = @async_io.Queue(kind=Blocking(0))
  debug_inspect(q.try_put(0), content="false")
  debug_inspect(q.try_get(), content="None")
}

///|
test "blocking try_put" {
  let q = @async_io.Queue(kind=Blocking(3))
  debug_inspect(q.try_put(0), content="true")
  debug_inspect(q.try_put(1), content="true")
  debug_inspect(q.try_put(2), content="true")
  debug_inspect(q.try_put(3), content="false")
  // the last `put` should have no effect
  for i in 0..<3 {
    @debug.assert_eq(q.try_get(), Some(i))
  }
  debug_inspect(q.try_get(), content="None")
  // `put` again
  debug_inspect(q.try_put(0), content="true")
  debug_inspect(q.try_put(1), content="true")
  debug_inspect(q.try_put(2), content="true")
  debug_inspect(q.try_put(3), content="false")
  debug_inspect(q.try_get(), content="Some(0)")
  debug_inspect(q.try_put(3), content="true")
  debug_inspect(q.try_put(4), content="false")
}

///|
async test "blocked zero buffered try_get" {
  let log = []
  @async_io.with_task_group() <| group => {
    let q = @async_io.Queue(kind=Blocking(0))
    @debug.assert_eq(None, q.try_get())
    for i in 0..<3 {
      group.spawn_bg() <| () => {
        q.put(i)
        log.push("put(\{i})")
      }
    }
    group.spawn_bg() <| () => {
      while q.try_get() is Some(x) {
        log.push("try_get() => \{x}")
      }
    }
    @debug.assert_eq(None, q.try_get())
  }
  json_inspect(log, content=[
    "try_get() => 0", "try_get() => 1", "try_get() => 2", "put(0)", "put(1)", "put(2)",
  ])
}

///|
async test "blocked zero buffered try_put" {
  let log = []
  @async_io.with_task_group() <| group => {
    let q = @async_io.Queue(kind=Blocking(0))
    assert_eq(false, q.try_put(-1))
    for _ in 0..<3 {
      group.spawn_bg() <| () => {
        let x = q.get()
        log.push("get() => \{x}")
      }
    }
    group.spawn_bg() <| () => {
      for i in 0..<3 {
        if q.try_put(i) {
          log.push("try_put(\{i})")
        } else {
          log.push("try_put(\{i}) => false")
        }
      }
    }
    assert_eq(false, q.try_put(-1))
  }
  json_inspect(log, content=[
    "try_put(0)", "try_put(1)", "try_put(2)", "get() => 0", "get() => 1", "get() => 2",
  ])
}

///|
async test "blocked zero buffered discard oldest try_get" {
  let log = []
  @async_io.with_task_group() <| group => {
    let q = @async_io.Queue(kind=DiscardOldest(0))
    @debug.assert_eq(None, q.try_get())
    for i in 0..<3 {
      group.spawn_bg() <| () => {
        q.put(i) // will be discarded since the buffer size is 0 and no waiting readers
        log.push("put(\{i})")
      }
    }
    group.spawn_bg() <| () => {
      while q.try_get() is Some(x) {
        log.push("try_get() => \{x}")
      }
    }
    @debug.assert_eq(None, q.try_get())
  }
  json_inspect(log, content=["put(0)", "put(1)", "put(2)"])
}

///|
async test "blocked zero buffered discard oldest try_put" {
  let log = []
  @async_io.with_task_group() <| group => {
    let q = @async_io.Queue(kind=DiscardOldest(0))
    @debug.assert_eq(false, q.try_put(-1))
    for _ in 0..<3 {
      group.spawn_bg() <| () => {
        let x = q.get()
        log.push("get() => \{x}")
      }
    }
    group.spawn_bg() <| () => {
      for i in 0..<3 {
        if q.try_put(i) {
          log.push("try_put(\{i})")
        } else {
          log.push("try_put(\{i}) => false")
        }
      }
    }
    @debug.assert_eq(false, q.try_put(-1))
  }
  json_inspect(log, content=[
    "try_put(0)", "try_put(1)", "try_put(2)", "get() => 0", "get() => 1", "get() => 2",
  ])
}

///|
async test "blocked zero buffered discard latest try_put" {
  let log = []
  @async_io.with_task_group() <| group => {
    let q = @async_io.Queue(kind=DiscardLatest(0))
    @debug.assert_eq(false, q.try_put(-1))
    for _ in 0..<3 {
      group.spawn_bg() <| () => {
        let x = q.get()
        log.push("get() => \{x}")
      }
    }
    group.spawn_bg() <| () => {
      for i in 0..<3 {
        if q.try_put(i) {
          log.push("try_put(\{i})")
        } else {
          log.push("try_put(\{i}) => false")
        }
      }
    }
    @debug.assert_eq(false, q.try_put(-1))
  }
  json_inspect(log, content=[
    "try_put(0)", "try_put(1)", "try_put(2)", "get() => 0", "get() => 1", "get() => 2",
  ])
}
