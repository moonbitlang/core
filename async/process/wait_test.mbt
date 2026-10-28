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
async test "basic wait" {
  let log = StringBuilder()
  let test_prog = sleep_prog.wait()
  @async.with_task_group() <| root => {
    root.spawn_bg() <| () => {
      for i in 0..<2 {
        @async.sleep(750)
        log <+ "\{(i + 1) * 750}ms tick\n"
      }
    }
    @async.sleep(10)
    let result = @process.run(test_prog, ["750"])
    log <+ "process completed with \{result.exit_code}\n"
  }
  inspect(
    log.to_string(),
    content=(
      #|750ms tick
      #|process completed with 0
      #|1500ms tick
      #|
    ),
  )
}

///|
async test "wait exitcode" {
  let result = @process.run(shell, ["-c", "exit 42"])
  inspect(result.exit_code, content="42")
}

///|
async test "wait_pid" {
  let log = StringBuilder()
  let test_prog = sleep_prog.wait()
  @async.with_task_group() <| group => {
    group.spawn_bg() <| () => {
      for _ in 0..<2 {
        @async.sleep(800)
        log <+ "tick\n"
      }
    }
    let proc = @process.spawn_orphan(test_prog, ["1000", "-exit-code", "42"])
    defer proc.close()
    let exit_code = proc.wait()
    log <+ "process terminated with \{exit_code}\n"
  }
  inspect(
    log.to_string(),
    content=(
      #|tick
      #|process terminated with 42
      #|tick
      #|
    ),
  )
}

///|
async test "spawn without standard handles on Windows" {
  guard @event_loop.platform is Windows else {  }
  let spawn = spawn_prog.wait()
  let sleep = sleep_prog.wait()
  let result = @process.run(spawn, ["-no-stdio", "-orphan", sleep, "0"])
  inspect(result.exit_code, content="0")
}

///|
async test "wait exitcode STILL_ACTIVE" {
  guard @event_loop.platform is Windows else {  }
  // `259` is the special value for `STILL_ACTIVE`,
  // wihch is returned by `GetExitCodeProcess` when the process is still running on Windows.
  // However, 259 can also be a valid exit code,
  // so we should not use it to determine whether the process has exited or not.
  let result = @process.run(shell, ["-c", "exit 259"])
  inspect(result.exit_code, content="259")
}

///|
async test "signal exit code" {
  guard !(@event_loop.platform is Windows) else {  }
  let sleep = sleep_prog.wait()
  @async.with_task_group <| group => {
    let proc = @process.spawn(group, sleep, ["1000", "-use-default-handler"])
    group.spawn_bg(no_wait=true) <| () => {
      @async.sleep(100)
      @process.graceful_cancel(timeout=1000, signal=SIGINT)(proc.pid)
    }
    let exit_code = proc.wait()
    assert_eq(exit_code, -@signal.SIGINT.to_int())
  }
}
