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
extern "C" fn register_termination_handler() = "register_termination_handler"

///|
extern "C" fn set_swallow_cancel_signal() = "set_swallow_cancel_signal"

///|
extern "C" fn exit(code : Int32) = "exit"

///|
async fn main {
  let mut time = 10_000
  let mut exit_code = 0
  let mut msg_after_sleep = None
  let mut msg_finally = None
  let mut use_default_handler = false
  let mut wait_on_init = false
  for args = @env.args()[1:] {
    match args {
      [] => break
      ["-exit-code", .. rest] => {
        guard rest is [code, .. rest] else { fail("invalid arguments") }
        exit_code = @string.parse_int(code)
        continue rest
      }
      ["-swallow-cancel-signal", .. rest] => {
        set_swallow_cancel_signal()
        continue rest
      }
      ["-print-after-sleep", .. rest] => {
        guard rest is [msg, .. rest] else { fail("invalid arguments") }
        msg_after_sleep = Some(msg)
        continue rest
      }
      ["-print-finally", .. rest] => {
        guard rest is [msg, .. rest] else { fail("invalid arguments") }
        msg_finally = Some(msg)
        continue rest
      }
      ["-use-default-handler", .. rest] => {
        use_default_handler = true
        continue rest
      }
      ["-wait-on-init", .. rest] => {
        wait_on_init = true
        continue rest
      }
      [['-', ..] as flag, ..] => fail("unrecognized argument \{flag}")
      [t, .. rest] => {
        time = @string.parse_int(t)
        continue rest
      }
    }
  }
  defer (if msg_finally is Some(msg) { println(msg) })
  if wait_on_init {
    ignore(@stdio.stdin.read())
  }
  if !use_default_handler {
    @signal.set_global_cancellation_signals([])
    register_termination_handler()
  }
  @async_io.sleep(time)
  if msg_after_sleep is Some(msg) {
    println(msg)
  }
  exit(exit_code)
}
