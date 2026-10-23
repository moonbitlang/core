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
async test "mutex basic" {
  let log = []
  @async.with_task_group() <| group => {
    let mutex = @async.Mutex()
    for i in 0..<3 {
      group.spawn_bg() <| () => {
        mutex.acquire()
        log.push("task \{i} acquired mutex")
        @async.sleep(300)
        mutex.release()
      }
    }
    @async.sleep(150)
    for _ in 0..<3 {
      log.push("tick")
      @async.sleep(300)
    }
  }
  json_inspect(log, content=[
    "task 0 acquired mutex", "tick", "task 1 acquired mutex", "tick", "task 2 acquired mutex",
    "tick",
  ])
}

///|
async test "mutex cancellation" {
  @async.with_task_group() <| group => {
    let mutex = @async.Mutex()
    group.spawn_bg() <| () => {
      mutex.acquire()
      @async.sleep(500)
      mutex.release()
    }
    debug_inspect(
      @test.expect_error_async <| () => {
        @async.with_timeout(250, () => mutex.acquire())
      },
      content="TimeoutError",
    )
    @async.sleep(500)
    inspect(mutex.try_acquire(), content="true")
  }
}

///|
async test "mutex cancellation no_swallow" {
  let log = []
  @async.with_task_group() <| group => {
    let mutex = @async.Mutex()
    mutex.acquire()
    let acquire_taskire_task = group.spawn(() => {
      mutex.acquire()
      log.push("acquire() succeed")
    })
    @async.sleep(100)
    mutex.release()
    acquire_taskire_task.cancel()
    @async.sleep(100)
    inspect(mutex.try_acquire(), content="false")
  }
  json_inspect(log, content=["acquire() succeed"])
}

///|
async test "mutex fairness" {
  let log = []
  @async.with_task_group() <| group => {
    let mutex = @async.Mutex()
    group.spawn_bg() <| () => {
      for _ in 0..<3 {
        mutex.acquire()
        log.push("task 1 acquired mutex")
        @async.sleep(200)
        mutex.release()
      }
    }
    group.spawn_bg() <| () => {
      @async.sleep(100)
      for _ in 0..<3 {
        mutex.acquire()
        log.push("task 2 acquired mutex")
        @async.sleep(200)
        mutex.release()
      }
    }
  }
  json_inspect(log, content=[
    "task 1 acquired mutex", "task 2 acquired mutex", "task 1 acquired mutex", "task 2 acquired mutex",
    "task 1 acquired mutex", "task 2 acquired mutex",
  ])
}
