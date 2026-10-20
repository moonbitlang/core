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
async test "spawn_loop basic" {
  let log = StringBuilder()
  @async_io.with_task_group(root => {
    let mut i = 0
    root.spawn_loop() <| () => {
      log.write_string("tick \{i}\n")
      i = i + 1
      if i >= 3 {
        raise @async_io.BreakFromSpawnLoop
      }
    }
  })
  inspect(
    log.to_string(),
    content=(
      #|tick 0
      #|tick 1
      #|tick 2
      #|
    ),
  )
}

///|
async test "spawn_loop basic-error" {
  let log = StringBuilder()
  let err = @test_util.expect_error_async <| () => {
    @async_io.with_task_group(root => {
      let mut i = 0
      root.spawn_loop() <| () => {
        log.write_string("tick \{i}\n")
        i = i + 1
        if i >= 3 {
          raise Err
        }
      }
    })
  }
  log.write_string(@debug.to_string(err))
  inspect(
    log.to_string(),
    content=(
      #|tick 0
      #|tick 1
      #|tick 2
      #|Err
    ),
  )
}

///|
async test "spawn_loop retry-exponential" {
  let log = []
  @async_io.with_task_group() <| group => {
    let mut i = 0
    let start = @async_io.now()
    fn tick() {
      (@async_io.now() - start + 50).to_int() / 200
    }
    group.spawn_loop(
      retry=ExponentialDelay(initial=200, factor=2, maximum=600),
      () => {
        log.push("loop \{i} at tick #\{tick()}")
        i = i + 1
        match i {
          1 | 2 | 3 => raise Err
          4 => ()
          5 | 6 => raise Err
          _ => raise @async_io.BreakFromSpawnLoop
        }
      },
    )
  }
  json_inspect(log, content=[
    "loop 0 at tick #0", "loop 1 at tick #1", "loop 2 at tick #3", "loop 3 at tick #6",
    "loop 4 at tick #6", "loop 5 at tick #7", "loop 6 at tick #9",
  ])
}
