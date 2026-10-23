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
async test "spawn_in_group wait" {
  let log = []
  let sleep = sleep_prog.wait()
  let t0 = @async.now()
  @async.with_task_group() <| group => {
    let _ = @process.spawn(group, sleep, ["500"])
    @async.sleep(250)
    let t = (@async.now() - t0).to_int() / 250
    log.push("main task completed at tick #\{t}")
  }
  let t = (@async.now() - t0).to_int() / 250
  log.push("`with_task_group` completed at tick #\{t}")
  json_inspect(log, content=[
    "main task completed at tick #1", "`with_task_group` completed at tick #2",
  ])
}

///|
async test "spawn_in_group cancel" {
  let sleep = sleep_prog.wait()
  @async.with_task_group() <| outer => {
    let (r, w) = @process.read_from_process_shared()
    outer.spawn_bg() <| () => {
      defer r.close()
      inspect(r.text.read_all().trim(), content="received termination signal")
    }
    @async.with_task_group() <| inner => {
      let _ = {
        defer w.close()
        @process.spawn(inner, sleep, ["10000"], stdout=w, no_wait=true)
      }
      @async.sleep(300)
    }
  }
}

///|
async test "Process::wait" {
  let sleep = sleep_prog.wait()
  let mut t0 = 0L
  @async.with_task_group() <| group => {
    let child = @process.spawn(group, sleep, ["500", "-exit-code", "42"])
    t0 = @async.now()
    let result = child.wait()
    let t = (@async.now() - t0).to_int() / 250
    inspect(t, content="2")
    inspect(result, content="42")
    // `.wait()` should be idempotent
    inspect(child.wait(), content="42")
  }
}

///|
async test "Process::try_wait" {
  let sleep = sleep_prog.wait()
  @async.with_task_group() <| group => {
    let child = @process.spawn(group, sleep, ["200", "-exit-code", "42"])
    debug_inspect(child.try_wait(), content="None")
    @async.sleep(400)
    debug_inspect(child.try_wait(), content="Some(42)")
  }
}

///|
async test "Process::cancel" {
  let sleep = sleep_prog.wait()
  let mut t0 = 0L
  @async.with_task_group() <| group => {
    let child = @process.spawn(
      group,
      sleep,
      ["10000"],
      stdout=@process.read_from_process(),
    )
    group.spawn_bg() <| () => {
      defer child.stdout.close()
      inspect(
        child.stdout.text.read_all().trim(),
        content="received termination signal",
      )
    }
    t0 = @async.now()
    @async.sleep(500)
    child.cancel()
  }
  let t = (@async.now() - t0).to_int() / 500
  inspect(t, content="1")
}
