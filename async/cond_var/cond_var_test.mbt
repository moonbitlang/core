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
async test "cond var cancellation" {
  @async.with_task_group() <| root => {
    let cond = @cond_var.Cond()
    root.spawn_bg() <| () => {
      @async.sleep(500)
      cond.signal()
    }
    debug_inspect(
      @test.expect_error_async <| () => {
        @async.with_timeout(250, () => cond.wait())
      },
      content="TimeoutError",
    )
  }
}

///|
async test "cond var cancellation no_swallow" {
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    let cond = @cond_var.Cond()
    let wait_task = root.spawn(() => {
      cond.wait()
      log <+ "waiter 1 succeed\n"
    })
    root.spawn_bg(no_wait=true) <| () => {
      cond.wait()
      log <+ "waiter 2 succeed\n"
    }
    @async.sleep(100)
    cond.signal()
    wait_task.cancel()
    @async.sleep(100)
  }
  inspect(
    log.to_string(),
    content=(
      #|waiter 1 succeed
      #|
    ),
  )
}

///|
async test "cond var fairness" {
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    let cond = @cond_var.Cond()
    root.spawn_bg() <| () => {
      for _ in 0..<3 {
        cond.wait()
        log <+ "task 1 received signal\n"
      }
    }
    root.spawn_bg() <| () => {
      @async.sleep(100)
      for _ in 0..<3 {
        cond.wait()
        log <+ "task 2 received signal\n"
      }
    }
    @async.sleep(200)
    for _ in 0..<6 {
      cond.signal()
      @async.sleep(50)
    }
  }
  inspect(
    log.to_string(),
    content=(
      #|task 1 received signal
      #|task 2 received signal
      #|task 1 received signal
      #|task 2 received signal
      #|task 1 received signal
      #|task 2 received signal
      #|
    ),
  )
}

///|
async test "cond var broadcast" {
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    let cond = @cond_var.Cond()
    for i in 0..<3 {
      root.spawn_bg() <| () => {
        cond.wait()
        log.write_string("task \{i} received signal\n")
      }
    }
    @async.sleep(100)
    cond.broadcast()
  }
  inspect(
    log.to_string(),
    content=(
      #|task 0 received signal
      #|task 1 received signal
      #|task 2 received signal
      #|
    ),
  )
}

///|
async test "cond var broadcast cancellation" {
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    let cond = @cond_var.Cond()
    for i in 0..<3 {
      root.spawn_bg(allow_failure=true) <| () => {
        @async.with_timeout(200 * (i + 1), () => cond.wait())
        log.write_string("task \{i} received signal\n")
      }
    }
    @async.sleep(500)
    cond.broadcast()
  }
  inspect(
    log.to_string(),
    content=(
      #|task 2 received signal
      #|
    ),
  )
}
