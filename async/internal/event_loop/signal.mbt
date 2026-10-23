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
#cfg(target="native")
extern "C" fn get_signal_by_index(index : Int32) -> Int32 = "moonbit_rt_get_signal_by_index"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn get_signal_by_index(index : Int32) -> Int32 = "moonbitlang/async" "signal/get_signal_by_index"

///|
/// The list of all supported global cancellation signals
pub let all_signals : ReadOnlyArray[Int32] = ReadOnlyArray::makei(
  4, get_signal_by_index,
)

///|
/// Error raised when current event loop is cancelled by a registered cancellation signal
pub suberror KilledBySignal {
  KilledBySignal(Int32)
}

///|
#cfg(target="native")
#borrow(all_signals, signals)
extern "C" fn set_global_cancellation_signals_ffi(
  all_signals : ReadOnlyArray[Int32],
  all_signals_len : Int32,
  signals : ReadOnlyArray[Int32],
  signals_len : Int32,
) -> Unit = "moonbit_rt_set_global_cancellation_signals"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(all_signals, signals)
fn set_global_cancellation_signals_ffi(
  all_signals : ReadOnlyArray[Int32],
  all_signals_len : Int32,
  signals : ReadOnlyArray[Int32],
  signals_len : Int32,
) -> Unit = "moonbitlang/async" "signal/set_global_cancellation_signals"

///|
let global_signal_handler_initialized : @ref.Ref[Bool] = Ref(false)

///|
/// Set the list of global cancellation signals.
/// Can be invoked after the event loop started or invoked multiple times.
pub fn set_global_cancellation_signals(signals : ReadOnlyArray[Int32]) -> Unit {
  global_signal_handler_initialized.val = true
  set_global_cancellation_signals_ffi(
    all_signals,
    all_signals.length(),
    signals,
    signals.length(),
  )
}

///|
#cfg(all(target="native", not(platform="windows")))
extern "C" fn start_signal_handler_ffi() -> Unit = "moonbit_rt_start_signal_handler"

///|
#cfg(all(target="native", not(platform="windows")))
extern "C" fn terminate_signal_handler_ffi() -> Unit = "moonbit_rt_terminate_signal_handler"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn start_signal_handler_ffi() -> Unit = "moonbitlang/async" "signal/start_signal_handler"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn terminate_signal_handler_ffi() -> Unit = "moonbitlang/async" "signal/terminate_signal_handler"

///|
#cfg(not(platform="windows"))
fn setup_signal_handler_unix() -> Unit {
  if !global_signal_handler_initialized.val {
    set_global_cancellation_signals(all_signals)
  }
  start_signal_handler_ffi()
}

///|
#cfg(not(platform="windows"))
fn EventLoop::terminate_signal_handler_unix(evloop : EventLoop) -> Unit raise {
  global_signal_handler_initialized.val = false
  terminate_signal_handler_ffi()
  if evloop.killed_by_signal is Some(signal) {
    raise KilledBySignal(signal)
  }
}

///|
#cfg(platform="windows")
extern "C" fn set_console_control_handler(add : Int32) -> Int32 = "moonbit_rt_set_console_control_handler"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn set_console_control_handler(add : Int32) -> Int32 = "moonbitlang/async" "signal/set_console_control_handler"

///|
#cfg(any(target="wasm", platform="windows"))
fn setup_signal_handler_windows() -> Unit raise {
  if !global_signal_handler_initialized.val {
    set_global_cancellation_signals(all_signals)
  }
  if set_console_control_handler(1) is 0 {
    @os_error.check_errno("setup_signal_handler()")
  }
}

///|
#cfg(any(target="wasm", platform="windows"))
fn EventLoop::terminate_signal_handler_windows(
  evloop : EventLoop,
) -> Unit raise {
  if set_console_control_handler(0) is 0 {
    @os_error.check_errno("terminate_signal_handler()")
  }
  if evloop.killed_by_signal is Some(signal) {
    raise KilledBySignal(signal)
  }
}

///|
#cfg(all(target="native", not(platform="windows")))
fn setup_signal_handler() -> Unit {
  setup_signal_handler_unix()
}

///|
#cfg(all(target="native", not(platform="windows")))
fn EventLoop::terminate_signal_handler(evloop : EventLoop) -> Unit raise {
  evloop.terminate_signal_handler_unix()
}

///|
#cfg(platform="windows")
fn setup_signal_handler() -> Unit raise {
  setup_signal_handler_windows()
}

///|
#cfg(platform="windows")
fn EventLoop::terminate_signal_handler(evloop : EventLoop) -> Unit raise {
  global_signal_handler_initialized.val = false
  evloop.terminate_signal_handler_windows()
}

///|
#cfg(target="wasm")
fn setup_signal_handler() -> Unit raise {
  match platform {
    Linux | MacOS => setup_signal_handler_unix()
    Windows => setup_signal_handler_windows()
  }
}

///|
#cfg(target="wasm")
fn EventLoop::terminate_signal_handler(evloop : EventLoop) -> Unit raise {
  global_signal_handler_initialized.val = false
  match platform {
    Linux | MacOS => evloop.terminate_signal_handler_unix()
    Windows => evloop.terminate_signal_handler_windows()
  }
}

///|
/// Terminate current process using the specified signal.
/// Can be used to mimic "killed by signal" exit status.
#cfg(target="native")
pub extern "C" fn terminate_process_by_signal(sig : Int32) -> Unit = "moonbit_rt_terminate_process_by_signal"
