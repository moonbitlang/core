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
async test "return_immediately basic" {
  @async.with_task_group(root => {
    root.spawn_bg() <| () => {
      @async.sleep(200)
      root.return_immediately()
    }
    root.spawn_bg() <| () => { @async.sleep(300) }
  })
}

///|
async test "return_immediately nested" {
  @async.with_task_group(root => {
    root.spawn_bg() <| () => { @async.sleep(300) }
    @async.with_task_group() <| fn(group) {
      group.spawn_bg() <| () => {
        @async.sleep(200)
        root.return_immediately()
      }
      group.spawn_bg() <| () => { @async.sleep(300) }
    }
  })
}

///|
async test "return_immediately error on cancel" {
  let log = StringBuilder()
  let err = @test.expect_error_async <| () => {
    @async.with_task_group(root => {
      root.spawn_bg() <| () => {
        @async.sleep(200)
        root.return_immediately()
      }
      root.spawn_bg() <| () => {
        match @async.handle_cancellation(() => @async.sleep(300)) {
          None => {
            log <+ "task cancelled, causing other error\n"
            raise Err
          }
          Some(_) => log <+ "task finished\n"
        }
      }
    })
  }
  log.write_string(@debug.to_string(err))
  inspect(
    log.to_string(),
    content=(
      #|task cancelled, causing other error
      #|Err
    ),
  )
}

///|
async test "return_immediately recursive cancel" {
  let log = []
  @async.with_task_group() <| group => {
    group.spawn_bg() <| () => {
      @async.sleep(100)
      log.push("100ms tick")
    }
    @async.with_task_group <| group => {
      defer @async.sleep(200)
      group.return_immediately()
    }
    log.push("inner group finished")
  }
  json_inspect(log, content=["inner group finished", "100ms tick"])
}

///|
async test "return_immediately called outside" {
  let log = []
  @async.with_task_group() <| outer => {
    outer.spawn_bg() <| () => {
      @async.sleep(100)
      log.push("100ms tick")
    }
    @async.with_task_group(inner => {
      outer.spawn_bg(() => inner.return_immediately())
    })
    log.push("inner group finished")
  }
  json_inspect(log, content=["inner group finished", "100ms tick"])
}
