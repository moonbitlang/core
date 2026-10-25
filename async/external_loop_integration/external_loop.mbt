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
/// `moonbitlang/async` need an event loop to perform asynchronous IO.
/// However, some programs, such as GUI programs, have their own event loop,
/// and that event loop sometimes must be run in the main thread.
/// In this case, `moonbitlang/async` supports running its event loop
/// in a dedicated thread internally and integrate with the user-provided loop.
///
/// `ExternalEventLoop` is an abstraction for such user-provided event loop.
/// An implementation of `ExternalEventLoop` represent an event loop instance.
/// The required methods for the user-provided event loop are:
///
/// - `evloop.poll(timeout?)`: the main wait function of the user-provided loop.
///   `poll` should block the program until any interested event occur or timeout expired.
///   After waking up, `poll` should process main loop specific events and return,
///   `moonbitlang/async` will handle its own events and invoke `poll` again for the next loop.
///
///   When handling main loop specific events, `poll` SHOULD NOT perform heavy work directly.
///   Instead, it is recommended to send the event back to `async` code via `@async.CondVar`
///   or `@async.Queue`. This way, main loop events can integrate with `moonbitlang/async`
///   code better.
///
///   `poll` must support three timeout modes:
///
///   + if `timeout` is `Some(0)`, `poll` MUST NOT enter waiting state.
///     Instead, `poll` should simply check for immediately available events
///     and return immediately
///
///   + otherwise, if `timeout` is `Some(t)` (in this case it is guaranteed that `t > 0`),
///     `poll` should wait for no more than `t` milliseconds.
///     If some event occur before `t`, `poll` should return immediately.
///     Slight delay is allowed on timeout, but the delay will affect timer precision
///     of `moonbitlang/async`
///
///   + if `timeout` is `None`, `poll` should wait indefinitely for events
///
/// - `evloop.get_wakeup_callback_for_foreign_thread()` should return a callback function
///   for waking up the user-provided loop. `moonbitlang/async` will use this callback
///   to wake up the main loop when `moonbitlang/async` specific events occur.
///
///   When the callback returned by `evloop.get_wakeup_callback_for_foreign_thread()`
///   is invoked, it MUST wake up the blocked `poll` wait, if `poll` is currently running.
///   If `poll` is not running when the callback is invoked,
///   the callback should make the next `poll` should return immediately.
///   MISSED WAKEUP MAY RESULT IN PROGRAM DEAD LOCK.
///
///   If the wakeup callback event is implemented via some form of special event,
///   that event itself can be ignored in `poll`. `moonbitlang/async` will
///   check for its own events unconditionally after `poll` returns.
///
///   IMPORTANT CORRECTNESS NOTE: the returned wakeup callback will be invoked
///   in a dedicated thread, so the callback MUST NOT do anything other than
///   invoking a C FFI function directly, and that invoked C FFI function MUST NOT
///   perform any MoonBit reference counting operation.
///
/// - `terminate` will be invoked when the main loop exit.
///   Cleanup code for the user-provided event loop should be placed here.
///   Notice that `moonbitlang/async` need to perform some additional cleanup
///   after `async fn main` returns. So event loop cleanup should not be performed
///   inside `async fn main`.
pub(open) trait ExternalEventLoop {
  fn poll(Self, timeout? : Int32) -> Unit raise
  fn get_wakeup_callback_for_foreign_thread(Self) -> FuncRef[() -> Unit]
  fn terminate(Self) -> Unit raise
}
