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
/// A JavaScript promise that resolves to a value of type `X`
#external
pub type Promise[X]

///|
#external
priv type JsValue

///|
fn[X] JsValue::make(v : X) -> JsValue = "%identity"

///|
fn[X] JsValue::cast(v : JsValue) -> X = "%identity"

///|
extern "js" fn JsValue::abort_error() -> JsValue =
  #| () => {
  #|   const err = new Error()
  #|   err.name = 'AbortError'
  #|   return err
  #| }

///|
extern "js" fn JsValue::to_string(v : JsValue) -> String =
  #| (v) => v.toString()

///|
/// A JavaScript exception wrapped in MoonBit error
suberror JsError {
  JsError(JsValue)
}

///|
pub impl Show for JsError with fn output(self, logger) {
  let JsError(value) = self
  logger <+ "\{value.to_string()}"
}

///|
pub extend JsError with Show::{to_string}

///|
/// A JavaScript `AbortController` used to cancel promises
#external
pub type AbortController

///|
/// A JavaScript `AbortSignal` used to cancel promises
#external
pub type AbortSignal

///|
/// Create a new abort controller
pub extern "js" fn AbortController::new() -> AbortController =
  #| () => new AbortController()

///|
/// Get the abort signal of an abort controller.
/// The abort signal will be triggered when `.abort()` is called on the controller.
pub extern "js" fn AbortController::signal(self : Self) -> AbortSignal =
  #| (controller) => controller.signal

///|
/// Abort the abort controller and activate its abort signal.
/// All promises tied to the signal will be cancelled.
pub extern "js" fn AbortController::abort(self : Self) =
  #| (controller) => controller.abort()

///|
extern "js" fn AbortSignal::on_abort(
  signal : AbortSignal,
  f : () -> Unit,
) -> Unit =
  #| (signal, f) => signal.addEventListener('abort', f, { once: true })

///|
extern "js" fn AbortSignal::remove_abort_listener(
  signal : AbortSignal,
  f : () -> Unit,
) -> Unit =
  #| (signal, f) => signal.removeEventListener('abort', f)

///|
extern "js" fn AbortSignal::aborted(signal : AbortSignal) -> Bool =
  #| (signal) => signal.aborted

///|
extern "js" fn JsValue::then(
  promise : JsValue,
  resolve : (JsValue) -> Unit,
  reject : (JsValue) -> Unit,
) =
  #| (p, resolve, reject) => p.then(resolve, reject)

///|
extern "js" fn JsValue::new_promise(
  f : ((JsValue) -> Unit, (JsValue) -> Unit) -> Unit,
) -> JsValue =
  #| (f) => new Promise(f)

///|
priv struct PromiseWaiter[X] {
  mut coro : @coroutine.Coroutine?
  mut ret : X?
  mut err : Error?
}

///|
/// Wait for a JavaScript promise to resolve and return the fulfilled value,
/// or raise an error if the promise is rejected.
///
/// If `abort_controller` is provided,
/// it should be an abort controller that controls the promise,
/// and `.abort()` will be called on the controller automatically when `wait` is cancelled,
/// cancelling the promise automatically.
///
/// If `abort_controller` is absent, `wait` is non-cancellable.
pub async fn[X] Promise::wait(
  promise : Promise[X],
  abort_controller? : AbortController,
) -> X {
  let waiter : PromiseWaiter[X] = {
    coro: Some(@coroutine.current_coroutine()),
    ret: None,
    err: None,
  }
  fn resolve(value : JsValue) {
    waiter.ret = Some(value.cast())
    if waiter.coro is Some(coro) {
      coro.wake()
      @event_loop.reschedule()
    }
  }

  fn reject(err) {
    waiter.err = Some(JsError(err))
    if waiter.coro is Some(coro) {
      coro.wake()
      @event_loop.reschedule()
    }
  }

  JsValue::make(promise).then(resolve, reject)
  defer {
    waiter.coro = None
  }
  if abort_controller is Some(controller) {
    errdefer controller.abort()
    @coroutine.suspend()
  } else {
    @coroutine.protect_from_cancel(() => @coroutine.suspend())
  }
  if waiter.err is Some(err) {
    raise err
  } else {
    waiter.ret.unwrap()
  }
}

///|
/// Convenient helper for calling async JavaScript code from MoonBit.
/// `run_promise(f)` create a fresh abort signal, passed it to `f`,
/// and wait for the promise that `f` returns.
/// If `f` resolve to a value, `run_promise` return that value.
/// If `f` is rejected with an error, `run_promise` raise that error.
/// If `run_promise` is cancelled, the abort signal passed to `f` is activated,
/// and the promise returned by `f` should be cancelled automatically.
///
/// `run_promise` should only be used for cancellable JavaScript code
/// (i.e. the promised returned by `f` should properly handle the passed-in abort signal).
/// For non-cancellable JavaScript code, use `Promise::wait()` directly.
pub async fn[X] run_promise(f : (AbortSignal) -> Promise[X]) -> X {
  let controller = AbortController::new()
  let promise = f(controller.signal())
  promise.wait(abort_controller=controller)
}

///|
/// Convert a MoonBit async function into a JavaScript promise.
/// `Promise::from_async(f)` returns a promise that:
///
/// - resolve to the result of `f` when `f` return
/// - reject with the error that `f` raise if `f` fail
///
/// If `abort_signal` is present,
/// `f` will be automatically cancelled when the signal is activated,
/// and the returned promise will reject with JavaScript `AbortError`.
///
/// The async function `f` will be run in a global context,
/// so there is no structured concurrency support for `Promise::from_async`,
/// and this function should only be used for exporting MoonBit code to JavaScript.
///
/// It is undefined whether `f` will actually start running immediately,
/// or start at the next JavaScript event loop.
pub fn[X] Promise::from_async(
  f : async () -> X,
  abort_signal? : AbortSignal,
) -> Promise[X] {
  let promise = JsValue::new_promise((resolve, reject) => {
    let _ = @coroutine.spawn(() => {
      let coro = @coroutine.current_coroutine()
      fn abort_handler() {
        coro.cancel()
      }
      if abort_signal is Some(signal) {
        signal.on_abort(abort_handler)
      }
      defer (if abort_signal is Some(signal) {
        signal.remove_abort_listener(abort_handler)
      })
      if abort_signal is Some(signal) {
        // An abort event fired before listener registration is not replayed.
        // Register first, then inspect the sticky state to cover both orderings.
        if signal.aborted() {
          coro.cancel()
        }
      }
      try @coroutine.handle_cancellation(f) catch {
        err => reject(JsValue::make(err.to_string()))
      } noraise {
        None => reject(JsValue::abort_error())
        Some(ret) => resolve(JsValue::make(ret))
      }
    })
  })
  @event_loop.reschedule()
  promise.cast()
}
