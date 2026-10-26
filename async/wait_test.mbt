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
  @async.with_task_group <| group => {
    let task = group.spawn(no_wait=true) <| () => {
      let start = @async.now()
      @async.sleep(300)
      buf <+ "task finished\n"
      start
    }
    let start = task.wait()
    let end = @async.now()
    let t = (end - start + 50) / 300
    buf <+ "main task exit at tick #\{t}\n"
  }
  inspect(
    buf.to_string(),
    content=(
      #|task finished
      #|main task exit at tick #1
      #|
    ),
  )
}

///|
async test "wait cancelled" {
  let buf = StringBuilder()
  @async.with_task_group(root => {
    let task = root.spawn(() => {
      @async.sleep(1000)
      buf <+ "task finished\n"
    })
    root.spawn_bg() <| () => {
      match @async.handle_cancellation(() => task.wait()) {
        None => buf.write_string("`wait` cancelled\n")
        Some(_) => ()
      }
    }
    @async.sleep(20)
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
  @async.with_task_group() <| root => {
    let task = root.spawn(no_wait=true, () => {
      @async.sleep(450)
      42
    })
    root.spawn_bg() <| () => {
      @async.sleep(300)
      log.write_string("300ms: \{@debug.to_string(task.try_wait())}\n")
      @async.sleep(300)
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
