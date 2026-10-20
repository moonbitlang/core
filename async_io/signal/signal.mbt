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
/// The set of currently supported signals.
/// - `SIGINT`: `SIGINT` on Unix, `CTRL_C_EVENT` on Windows
/// - `SIGTERM`: `SIGTERM` on Unix, unavailable on Windows
/// - `SIGHUP`: `SIGHUP` on Unix, `CTRL_CLOSE_EVENT` on Windows
/// - `SIGBREAK`: unavailable on Unix, `CTRL_BREAK_EVENT` on Windows
pub(all) enum Signal {
  SIGINT = 0
  SIGTERM = 1
  SIGHUP = 2
  SIGBREAK = 3
} derive(@debug.Debug)

///|
fn Signal::index(sig : Signal) -> Int32 = "%identity"

///|
/// Convert a signal to its underlying signal code in the OS.
/// The result of this function is platform-dependent.
pub fn Signal::to_int(signal : Signal) -> Int32 {
  @event_loop.all_signals[signal.index()]
}

///|
/// Set the list of signals that are used as global cancellation signal.
/// When a global cancellation signal is received, the whole program will be cancelled gracefully,
/// using the native cancellation mechanism of `moonbitlang/async`.
///
/// Signals unavailable on current platform will be silently ignored.
///
/// The default list is all supported signals.
pub fn set_global_cancellation_signals(signals : ReadOnlyArray[Signal]) -> Unit {
  @event_loop.set_global_cancellation_signals(signals.map(sig => sig.to_int()))
}
