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
priv struct Waiter {
  coro : @coroutine.Coroutine
  /// For intrusive cancellable queue
  mut index : Int32
  mut next : Int32
  mut prev : Int32
}

///|
impl @cancellable_queue.Element for Waiter with fn get_index(self) {
  self.index
}

///|
impl @cancellable_queue.Element for Waiter with fn set_index(self, value) {
  self.index = value
}

///|
impl @cancellable_queue.Element for Waiter with fn get_next(self) {
  self.next
}

///|
impl @cancellable_queue.Element for Waiter with fn set_next(self, value) {
  self.next = value
}

///|
impl @cancellable_queue.Element for Waiter with fn get_prev(self) {
  self.prev
}

///|
impl @cancellable_queue.Element for Waiter with fn set_prev(self, value) {
  self.prev = value
}

///|
extend Waiter with @cancellable_queue.Element::{is_queued}

///|
/// A condition variable that can be used for synchronization between tasks.
#valtype
struct Cond {
  waiters : @cancellable_queue.Queue[Waiter]
}

///|
/// Create a new condition variable.
#alias(new, deprecated)
pub fn Cond::Cond() -> Cond {
  { waiters: Queue(), }
}

///|
/// Wait for the condition to get signaled.
/// `wait` itself never fail, and will wait indefinitely.
/// However, since `wait` is a blocking point,
/// the task running `wait` may be cancelled,
/// in this case, an cancellation will be raised from `wait`.
pub async fn Cond::wait(cond : Cond) -> Unit noraise {
  let coro = @coroutine.current_coroutine()
  let waiter = { coro, index: -1, next: -1, prev: -1, }
  cond.waiters.push(waiter)
  match @coroutine.suspend_check_cancel() {
    Continue => ()
    Cancelled if !waiter.is_queued() =>
      // In the rare case where:
      //
      // - `signal` wake up a waiter, the piece of resource is assigned to that waiter
      // - the waiter is immediately cancelled after woken up by `signal`,
      //   but before the waiter's coroutine actually resumes execution
      //
      // we must swallow the cancellation signal,
      // as otherwise the signal will be gone forever.
      // So we set `woken = true` after waking up a waiter,
      // and use this flag to protect against dangerous cancellation.
      ()
    Cancelled => {
      cond.waiters.remove(waiter)
      @coroutine.raise_cancellation_signal()
    }
  }
}

///|
/// Issue a single signal through the condition variable,
/// waking up the first task waiting for the condition variable.
/// If no task is waiting for the condition variable, nothing will happen.
pub fn Cond::signal(cond : Cond) -> Unit {
  if cond.waiters.pop() is Some(waiter) {
    waiter.coro.wake()
  }
}

///|
/// Send a broadcast signal to the condition variable,
/// waking up all tasks waiting for the condition variable.
/// If no task is waiting for the condition variable, nothing will happen.
pub fn Cond::broadcast(cond : Cond) -> Unit {
  while cond.waiters.pop() is Some(waiter) {
    waiter.coro.wake()
  }
}
