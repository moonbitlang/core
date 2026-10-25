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
/// This function is used for integration of `moonbitlang/async`
/// into the MoonBit toolchain, do not call directly.
#coverage.skip
#cfg(target="native")
#doc(hidden)
pub fn run_async_main(main : async () -> Unit) -> Unit {
  @event_loop.with_event_loop(() => main()) catch {
    @event_loop.KilledBySignal(signal) =>
      @event_loop.terminate_process_by_signal(signal)
    err => {
      eprintln(err.to_string())
      exit(1)
    }
  }
}

///|
/// Set a custom event loop implementation
/// instead of using `moonbitlang/async`'s default one.
/// If a user-provided event loop is present,
/// `moonbitlang/async` will spawn its own loop in a dedicated thread
/// to integrate with the user-provided loop.
///
/// For what a custom event loop should provide,
/// see `@external_loop_integration.ExternalEventLoop`.
///
/// `set_external_event_loop` MUST be invoked before `moonbitlang/async`
/// actually starts the event loop, for example inside `fn init`.
/// It is possible to invoke `set_external_event_loop` inside `async fn main` as well.
/// But in this case, it must be invoked before running any actual async code.
/// For example, a CLI program may invoke `set_external_event_loop` in `async fn main`
/// after processing command line arguments and (synchronous) event loop initialization.
///
/// When using an external event loop, all MoonBit code are still run in the main thread.
/// `moonbitlang/async` will only spawn its waiting part in a dedicated thread.
/// As a consequence, even if an external event loop is used,
/// `moonbitlang/async` may still modify state of the main thread, such as changing signal mask.
#cfg(target="native")
pub using @event_loop {set_external_event_loop}

///|
#cfg(target="native")
extern "C" fn exit(code : Int32) = "exit"

///|
#coverage.skip
#cfg(target="js")
#doc(hidden)
pub fn run_async_main(main : async () -> Unit) -> Unit {
  let _ = @coroutine.spawn <| () => {
    main() catch {
      err => {
        eprintln(err.to_string())
        panic()
      }
    }
  }
  @event_loop.reschedule()
}
