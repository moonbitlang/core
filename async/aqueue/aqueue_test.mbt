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
async test "aqueue basic" {
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    let queue = @aqueue.Queue(kind=Unbounded)
    root.spawn_bg() <| () => {
      for _ in 0..<6 {
        log.write_string("get => \{queue.get()}\n")
      }
    }
    root.spawn_bg() <| () => {
      for x in 0..<6 {
        @async.sleep(70)
        queue.put(x)
        log.write_string("put(\{x})\n")
      }
    }
  }
  inspect(
    log.to_string(),
    content=(
      #|put(0)
      #|get => 0
      #|put(1)
      #|get => 1
      #|put(2)
      #|get => 2
      #|put(3)
      #|get => 3
      #|put(4)
      #|get => 4
      #|put(5)
      #|get => 5
      #|
    ),
  )
}

///|
async test "aqueue multi-reader" {
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    let queue = @aqueue.Queue(kind=Unbounded)
    root.spawn_bg() <| () => {
      @async.sleep(70)
      let x = queue.get()
      log.write_string("task 1: get => \{x}\n")
    }
    root.spawn_bg() <| () => {
      let x = queue.get()
      log.write_string("task 2: get => \{x}\n")
    }
    @async.sleep(170)
    queue.put(1)
    queue.put(2)
  }
  inspect(
    log.to_string(),
    content=(
      #|task 2: get => 1
      #|task 1: get => 2
      #|
    ),
  )
}

///|
async test "aqueue cancellation" {
  let log = StringBuilder()
  let queue : @aqueue.Queue[Int32] = Queue(kind=Unbounded)
  @async.with_timeout(350, () => {
    match @async.handle_cancellation(() => queue.get()) {
      None => log.write_string("`queue.get()` cancelled\n")
      Some(x) => log.write_string("get => \{x}\n")
    }
  }) catch {
    @async.TimeoutError => ()
    err => raise err
  }
  inspect(
    log.to_string(),
    content=(
      #|`queue.get()` cancelled
      #|
    ),
  )
}

///|
async test "aqueue cancellation no_swallow" {
  // `get` should not swallow the value
  let log = StringBuilder()
  @async.with_task_group() <| group => {
    let q = @aqueue.Queue(kind=Unbounded)
    let get_task = group.spawn(() => log.write_string("get() => \{q.get()}\n"))
    @async.sleep(100)
    q.put(42)
    get_task.cancel()
    @async.sleep(100)
    debug_inspect(q.try_get(), content="None")
  }
  inspect(
    log.to_string(),
    content=(
      #|get() => 42
      #|
    ),
  )
}

///|
async test "aqueue fairness" {
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    let queue = @aqueue.Queue(kind=Unbounded)
    root.spawn_bg() <| () => {
      for _ in 0..<2 {
        let x = queue.get()
        log.write_string("task 1: get => \{x}\n")
      }
    }
    root.spawn_bg() <| () => {
      for _ in 0..<2 {
        let x = queue.get()
        log.write_string("task 2: get => \{x}\n")
      }
    }
    @async.sleep(70)
    queue.put(1)
    queue.put(2)
    @async.sleep(70)
    queue.put(3)
    queue.put(4)
  }
  inspect(
    log.to_string(),
    content=(
      #|task 1: get => 1
      #|task 2: get => 2
      #|task 1: get => 3
      #|task 2: get => 4
      #|
    ),
  )
}

///|
async test "aqueue fairness2" {
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    let queue = @aqueue.Queue(kind=Unbounded)
    queue.put(1)
    root.spawn_bg() <| () => {
      for _ in 0..<2 {
        let x = queue.get()
        log.write_string("task 1: get => \{x}\n")
        @async.sleep(200)
        queue.put(x + 1)
      }
    }
    root.spawn_bg() <| () => {
      @async.sleep(100)
      for _ in 0..<2 {
        let x = queue.get()
        log.write_string("task 2: get => \{x}\n")
        @async.sleep(200)
        queue.put(x + 1)
      }
    }
  }
  inspect(
    log.to_string(),
    content=(
      #|task 1: get => 1
      #|task 2: get => 2
      #|task 1: get => 3
      #|task 2: get => 4
      #|
    ),
  )
}

///|
test "try_get" {
  let q = @aqueue.Queue(kind=Unbounded)
  debug_inspect(q.try_get(), content="None")
  assert_true(q.try_put(42))
  debug_inspect(q.try_get(), content="Some(42)")
  debug_inspect(q.try_get(), content="None")
  assert_true(q.try_put(1))
  assert_true(q.try_put(2))
  debug_inspect(q.try_get(), content="Some(1)")
  debug_inspect(q.try_get(), content="Some(2)")
  debug_inspect(q.try_get(), content="None")
}
