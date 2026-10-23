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
let sleep_prog : @async.Lazy[String] = Lazy(() => {
  @test_util.build_test_program("sleep")
})

///|
async test "cancel with default signal" {
  let test_prog = sleep_prog.wait()
  let log = []
  @async.with_task_group() <| group => {
    let child = @process.spawn(
      group,
      test_prog,
      stdout=@process.read_from_process(),
      [
        "10000", "-use-default-handler", "-print-after-sleep", "normal exit", "-print-finally",
        "before exit",
      ],
    )
    group.spawn_bg() <| () => {
      defer log.push("process terminates")
      let _ = child.wait()
    }
    group.spawn_bg() <| () => {
      defer child.stdout.close()
      while child.stdout.text.read() is Some(data) {
        let data = data.replace_all(old="\r\n", new="\n").trim()
        log.push("from process: \{data}")
      }
    }
    @async.sleep(500)
    child.cancel()
    log.push("cancelling task running process")
  }
  json_inspect(log, content=[
    "cancelling task running process", "from process: before exit", "process terminates",
  ])
}

///|
// On Windows, `CTRL_C_EVENT` cannot be sent to a single process
#cfg(not(platform="windows"))
async test "cancel with ctrl+c" {
  let test_prog = sleep_prog.wait()
  let log = []
  @async.with_task_group() <| group => {
    let child = @process.spawn(
      group,
      test_prog,
      stdout=@process.read_from_process(),
      cancel_handler=@process.graceful_cancel(timeout=5000, signal=SIGINT),
      [
        "10000", "-use-default-handler", "-print-after-sleep", "normal exit", "-print-finally",
        "before exit",
      ],
    )
    group.spawn_bg() <| () => {
      defer log.push("process terminates")
      let _ = child.wait()
    }
    group.spawn_bg() <| () => {
      defer child.stdout.close()
      while child.stdout.text.read() is Some(data) {
        let data = data.replace_all(old="\r\n", new="\n").trim()
        log.push("from process: \{data}")
      }
    }
    @async.sleep(500)
    child.cancel()
    log.push("cancelling task running process")
  }
  json_inspect(log, content=[
    "cancelling task running process", "from process: before exit", "process terminates",
  ])
}

///|
// On Windows, `CTRL_CLOSE_EVENT` cannot be sent programmatically
#cfg(not(platform="windows"))
async test "cancel with SIGHUP" {
  let test_prog = sleep_prog.wait()
  let log = []
  @async.with_task_group() <| group => {
    let child = @process.spawn(
      group,
      test_prog,
      stdout=@process.read_from_process(),
      cancel_handler=@process.graceful_cancel(timeout=5000, signal=SIGHUP),
      [
        "10000", "-use-default-handler", "-print-after-sleep", "normal exit", "-print-finally",
        "before exit",
      ],
    )
    group.spawn_bg() <| () => {
      defer log.push("process terminates")
      let _ = child.wait()
    }
    group.spawn_bg() <| () => {
      defer child.stdout.close()
      while child.stdout.text.read() is Some(data) {
        let data = data.replace_all(old="\r\n", new="\n").trim()
        log.push("from process: \{data}")
      }
    }
    @async.sleep(500)
    child.cancel()
    log.push("cancelling task running process")
  }
  json_inspect(log, content=[
    "cancelling task running process", "from process: before exit", "process terminates",
  ])
}

///|
async test "change cancellation signal set in the middle #1" {
  let test_prog = sleep_prog.wait()
  let log = []
  @async.with_task_group() <| group => {
    let proc = @process.spawn(
      group,
      test_prog,
      stdin=@process.write_to_process(),
      stdout=@process.read_from_process(),
      [
        "2000", "-wait-on-init", "-print-finally", "before exit", "-swallow-cancel-signal",
      ],
    )
    group.spawn_bg() <| () => {
      defer proc.stdout.close()
      while proc.stdout.text.read() is Some(data) {
        let data = data.replace_all(old="\r\n", new="\n").trim()
        log.push("from process: \{data}")
      }
    }
    defer proc.stdin.close()
    @async.sleep(250)
    proc.cancel()
    log.push("cancelling task running process")
    @async.sleep(250)
  }
  json_inspect(log, content=[
    "cancelling task running process", "from process: before exit",
  ])
}

///|
async test "change cancellation signal set in the middle #2" {
  let test_prog = sleep_prog.wait()
  let log = []
  @async.with_task_group() <| group => {
    let proc = @process.spawn(
      group,
      test_prog,
      stdin=@process.write_to_process(),
      stdout=@process.read_from_process(),
      [
        "500", "-wait-on-init", "-print-finally", "before exit", "-swallow-cancel-signal",
      ],
    )
    group.spawn_bg() <| () => {
      defer proc.stdout.close()
      while proc.stdout.text.read() is Some(data) {
        let data = data.replace_all(old="\r\n", new="\n").trim()
        log.push("from process: \{data}")
      }
    }
    defer proc.stdin.close()
    proc.stdin.text.write("whatever")
    @async.sleep(250)
    proc.cancel()
    log.push("cancelling task running process")
  }
  json_inspect(log, content=[
    "cancelling task running process", "from process: received termination signal",
  ])
}
