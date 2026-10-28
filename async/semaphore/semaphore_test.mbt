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
async test "semaphore mutex" {
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    let semaphore = @semaphore.Semaphore(1)
    for i in 0..<3 {
      root.spawn_bg() <| () => {
        semaphore.acquire()
        log <+ "task \{i} obtained resource\n"
        @async.sleep(300)
        semaphore.release()
      }
    }
    @async.sleep(150)
    for _ in 0..<3 {
      log <+ "tick\n"
      @async.sleep(300)
    }
  }
  inspect(
    log.to_string(),
    content=(
      #|task 0 obtained resource
      #|tick
      #|task 1 obtained resource
      #|tick
      #|task 2 obtained resource
      #|tick
      #|
    ),
  )
}

///|
async test "semaphore multiple value" {
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    let semaphore = @semaphore.Semaphore(2)
    for i in 0..<6 {
      root.spawn_bg() <| () => {
        semaphore.acquire()
        log <+ "task \{i} obtained resource\n"
        @async.sleep(300)
        semaphore.release()
      }
    }
    @async.sleep(150)
    for _ in 0..<3 {
      log <+ "tick\n"
      @async.sleep(300)
    }
  }
  inspect(
    log.to_string(),
    content=(
      #|task 0 obtained resource
      #|task 1 obtained resource
      #|tick
      #|task 2 obtained resource
      #|task 3 obtained resource
      #|tick
      #|task 4 obtained resource
      #|task 5 obtained resource
      #|tick
      #|
    ),
  )
}

///|
async test "semaphore cancellation" {
  @async.with_task_group() <| root => {
    let semaphore = @semaphore.Semaphore(1)
    root.spawn_bg() <| () => {
      semaphore.acquire()
      @async.sleep(500)
      semaphore.release()
    }
    debug_inspect(
      @test.expect_error_async <| () => {
        @async.with_timeout(250, () => semaphore.acquire())
      },
      content="TimeoutError",
    )
    @async.sleep(500)
    inspect(semaphore.try_acquire(), content="true")
  }
}

///|
async test "semaphore cancellation no_swallow" {
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    let semaphore = @semaphore.Semaphore(1)
    semaphore.acquire()
    let acquire_taskire_task = root.spawn(() => {
      semaphore.acquire()
      log <+ "acquire() succeed\n"
    })
    @async.sleep(100)
    semaphore.release()
    acquire_taskire_task.cancel()
    @async.sleep(100)
    inspect(semaphore.try_acquire(), content="false")
  }
  inspect(
    log.to_string(),
    content=(
      #|acquire() succeed
      #|
    ),
  )
}

///|
async test "semaphore fairness" {
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    let semaphore = @semaphore.Semaphore(1)
    root.spawn_bg() <| () => {
      for _ in 0..<3 {
        semaphore.acquire()
        log <+ "task 1 acquired resource\n"
        @async.sleep(200)
        semaphore.release()
      }
    }
    root.spawn_bg() <| () => {
      @async.sleep(100)
      for _ in 0..<3 {
        semaphore.acquire()
        log <+ "task 2 acquired resource\n"
        @async.sleep(200)
        semaphore.release()
      }
    }
  }
  inspect(
    log.to_string(),
    content=(
      #|task 1 acquired resource
      #|task 2 acquired resource
      #|task 1 acquired resource
      #|task 2 acquired resource
      #|task 1 acquired resource
      #|task 2 acquired resource
      #|
    ),
  )
}

///|
test "try_acquire" {
  let semaphore = @semaphore.Semaphore(2, initial_value=0)
  inspect(semaphore.try_acquire(), content="false")
  semaphore.release()
  inspect(semaphore.try_acquire(), content="true")
  inspect(semaphore.try_acquire(), content="false")
  semaphore.release()
  semaphore.release()
  inspect(semaphore.try_acquire(), content="true")
  inspect(semaphore.try_acquire(), content="true")
  inspect(semaphore.try_acquire(), content="false")
}
