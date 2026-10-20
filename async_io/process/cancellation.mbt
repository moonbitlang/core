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
#cfg(not(target="wasm"))
extern "C" fn terminate_process(pid : Int32, signal : Int32) = "moonbit_rt_terminate_process"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn terminate_process(pid : Int32, signal : Int32) = "moonbitlang/async" "process/terminate"

///|
#cfg(not(target="wasm"))
extern "C" fn kill_process(pid : Int32) = "moonbit_rt_kill_process"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn kill_process(pid : Int32) = "moonbitlang/async" "process/kill"

///|
/// A handler function used to stop spawned process on cancellation.
/// The function receive the PID of the process as input.
pub(all) struct CancellationHandler(async (Int32) -> Unit)

///|
let default_signal : @signal.Signal = if @event_loop.platform is Windows {
  SIGBREAK
} else {
  SIGTERM
}

///|
/// A process cancellation handler that first try to gracefully stop the process,
/// and if the process is still running after `timeout` milliseconds,
/// forcefully stop the process.
///
/// Graceful process termination is implemented by sendig `signal` to the process.
/// The default signal is `SIGTERM` on POSIX-like systems
/// and `SIGBREAK` (aka `CTRL_BREAK_EVENT`) on Windows.
///
/// Note that on Windows, `SIGBREAK` is the only signal allowed to be be sent.
pub fn graceful_cancel(
  timeout~ : Int32,
  signal~ : @signal.Signal = default_signal,
) -> CancellationHandler {
  pid => {
    if signal.to_int() is code && code >= 0 {
      terminate_process(pid, signal.to_int())
    }
    @async_io.sleep(timeout)
    kill_process(pid)
  }
}

///|
/// A process cancellation handler that forcefully stop the process.
/// Implemented via `SIGKILL` on POSIX-like systems and `TerminateProcess` on Windows.
pub fn hard_cancel() -> CancellationHandler {
  pid => kill_process(pid)
}
