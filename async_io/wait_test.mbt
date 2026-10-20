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
async test "wait basic" {
  let buf = StringBuilder()
  @async_io.with_task_group(root => {
    root.spawn_bg() <| () => {
      @async_io.sleep(200)
      buf <+ "200ms tick\n"
      @async_io.sleep(200)
      buf <+ "400ms tick\n"
    }
    let task = root.spawn(no_wait=true, () => {
      @async_io.sleep(300)
      buf <+ "task finished\n"
    })
    task.wait()
    buf <+ "main task exit\n"
  })
  inspect(
    buf.to_string(),
    content=(
      #|200ms tick
      #|task finished
      #|main task exit
      #|400ms tick
      #|
    ),
  )
}

///|
async test "wait cancelled" {
  let buf = StringBuilder()
  @async_io.with_task_group(root => {
    let task = root.spawn(() => {
      @async_io.sleep(1000)
      buf <+ "task finished\n"
    })
    root.spawn_bg() <| () => {
      match @async_io.handle_cancellation(() => task.wait()) {
        None => buf.write_string("`wait` cancelled\n")
        Some(_) => ()
      }
    }
    @async_io.sleep(20)
    raise Err
  }) catch {
    err => buf.write_string(@debug.to_string(err))
  }
  inspect(
    buf.to_string(),
    content=(
      #|`wait` cancelled
      #|Err
    ),
  )
}

///|
async test "try_wait" {
  let log = StringBuilder()
  @async_io.with_task_group() <| root => {
    let task = root.spawn(no_wait=true, () => {
      @async_io.sleep(450)
      42
    })
    root.spawn_bg() <| () => {
      @async_io.sleep(300)
      log.write_string("300ms: \{@debug.to_string(task.try_wait())}\n")
      @async_io.sleep(300)
      log.write_string("600ms: \{@debug.to_string(task.try_wait())}\n")
    }
    log.write_string("task finished with \{task.wait()}\n")
  }
  inspect(
    log.to_string(),
    content=(
      #|300ms: None
      #|task finished with 42
      #|600ms: Some(42)
      #|
    ),
  )
}
