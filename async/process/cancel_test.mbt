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
async test "cancel `@process.run()`" {
  let test_prog = sleep_prog.wait()
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    let (r, w) = @process.read_from_process_shared()
    let task = root.spawn(() => {
      defer log.write_string("process terminates\n")
      defer w.close()
      @process.run(test_prog, ["10000"], stdout=w)
    })
    root.spawn_bg() <| () => {
      defer r.close()
      while r.text.read() is Some(data) {
        let data = data.replace_all(old="\r\n", new="\n")
        log.write_string("from process: \{data}")
      }
    }
    @async.sleep(500)
    task.cancel()
    log <+ "cancelling task running process\n"
  }
  inspect(
    log.to_string(),
    content=(
      #|cancelling task running process
      #|from process: received termination signal
      #|process terminates
      #|
    ),
  )
}

///|
async test "cancel process timeout" {
  let test_prog = sleep_prog.wait()
  @async.with_task_group() <| group => {
    let child = @process.spawn(
      group,
      test_prog,
      ["-swallow-cancel-signal", "10000"],
      stdout=@process.read_from_process(),
      cancel_handler=@process.graceful_cancel(timeout=500),
    )
    let t_receive_graceful_termination = group.spawn(() => {
      defer child.stdout.close()
      guard! child.stdout.text.read() is Some(data)
      let data = data.trim_end(chars="\r\n")
      let t = @async.now()
      inspect(data, content="received termination signal")
      t
    })
    @async.sleep(500)
    let t_cancel = @async.now()
    child.cancel()
    match @event_loop.platform {
      Linux | MacOS => inspect(child.wait(), content="-9")
      Windows => inspect(child.wait(), content="1")
    }
    let t_process_terminates = @async.now()
    let t1 = t_receive_graceful_termination.wait() - t_cancel
    let t2 = t_process_terminates - t_cancel
    inspect(t1 / 250, content="0")
    inspect(t2 / 250, content="2")
  }
}

///|
async test "cancel process hard" {
  let test_prog = sleep_prog.wait()
  @async.with_task_group() <| group => {
    let child = @process.spawn(
      group,
      test_prog,
      ["10000"],
      stdout=@process.read_from_process(),
      cancel_handler=@process.hard_cancel(),
    )
    group.spawn_bg() <| () => {
      defer child.stdout.close()
      inspect(child.stdout.text.read_all(), content="")
    }
    @async.sleep(500)
    let t0 = @async.now()
    child.cancel()
    match @event_loop.platform {
      Linux | MacOS => inspect(child.wait(), content="-9")
      Windows => inspect(child.wait(), content="1")
    }
    let t1 = @async.now()
    inspect((t1 - t0) / 250, content="0")
  }
}

///|
async test "orphan process" {
  let log = StringBuilder()
  @async.with_task_group() <| group => {
    let proc = @process.spawn_orphan(
      shell,
      ["-c", "\{write_stdout} first; sleep 1; \{write_stdout} second"],
      stdout=@process.read_from_process(),
    )
    let wait_task = group.spawn() <| () => {
      defer log.write_string("process terminates\n")
      let _ = proc.wait()
    }
    defer proc.close()
    defer proc.stdout.close()
    inspect(@utf8.decode(proc.stdout.read_exactly(5)), content="first")
    wait_task.cancel()
    log <+ "cancelling task running process\n"
    inspect(proc.stdout.text.read_all(), content="second")
  }
  inspect(
    log.to_string(),
    content=(
      #|cancelling task running process
      #|process terminates
      #|
    ),
  )
}

///|
#cfg(platform="windows")
async test "kill children on hard cancel" {
  let spawn = spawn_prog.wait()
  let sleep = sleep_prog.wait()
  @async.with_task_group <| group => {
    let child = @process.spawn(
      group,
      spawn,
      [sleep, "450", "-print-after-sleep", "after sleep"],
      stdout=@process.read_from_process(),
      cancel_handler=@process.hard_cancel(),
    )
    defer child.stdout.close()
    @async.sleep(300)
    child.cancel()
    inspect(child.stdout.text.read_all().trim(), content="")
  }
}

///|
async test "do not kill orphan children on hard cancel" {
  let spawn = spawn_prog.wait()
  let sleep = sleep_prog.wait()
  @async.with_task_group <| group => {
    let child = @process.spawn(
      group,
      spawn,
      ["-orphan", sleep, "450", "-print-after-sleep", "after sleep"],
      stdout=@process.read_from_process(),
      cancel_handler=@process.hard_cancel(),
    )
    defer child.stdout.close()
    @async.sleep(300)
    child.cancel()
    inspect(child.stdout.text.read_all().trim(), content="after sleep")
  }
}
