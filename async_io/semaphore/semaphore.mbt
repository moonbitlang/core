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
  // `None` indicates that the waiter is cancelled
  coro : @coroutine.Coroutine
  mut index : Int32
  mut prev : Int32
  mut next : Int32
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
/// A semaphore data structure useful for synchronization between tasks
pub struct Semaphore {
  size : Int32
  priv mut value : Int32
  priv waiters : @cancellable_queue.Queue[Waiter]
}

///|
/// Create a semaphore of size `size`,
/// the initial value of the semaphore
/// will be set to `initial_value` (`size` by default)
#alias(new, deprecated)
pub fn Semaphore::Semaphore(
  size : Int32,
  initial_value~ : Int32 = size,
) -> Semaphore {
  if size <= 0 {
    abort("size of semaphore must be positive")
  }
  guard! initial_value >= 0 && initial_value <= size
  { value: initial_value, size, waiters: Queue(), }
}

///|
/// Release a unit of resource back to the semaphore. This function never blocks.
/// If there are waiters currently blocked on the semaphore,
/// the first waiter will be woken to acquire the resource.
///
/// `release` must be called after a successful `acquire`,
/// in strictly one-to-one manner.
/// If the value of the semaphore exceed its size,
/// `release` will abort immediately.
pub fn Semaphore::release(self : Semaphore) -> Unit {
  if self.value >= self.size {
    abort("semaphore: too many release")
  }
  if self.waiters.pop() is Some(waiter) {
    waiter.coro.wake()
  } else {
    self.value += 1
  }
}

///|
/// Acquire one unit of resource from the semaphore.
/// If no resource is available,
/// `acquire` will block and wait until any resource is available.
/// If there are multiple tasks both waiting for the same resource,
/// new resource will be delivered in a first-come-first-serve manner.
///
/// `acquire` itself never fail, and will wait indefinitely.
/// However, since `acquire` is a blocking point,
/// the task running `acquire` may be cancelled,
/// in this case, an cancellation will be raised from `acquire`.
pub async fn Semaphore::acquire(self : Semaphore) -> Unit noraise {
  if self.value > 0 {
    self.value -= 1
  } else {
    let waiter = {
      coro: @coroutine.current_coroutine(),
      index: -1,
      next: -1,
      prev: -1,
    }
    self.waiters.push(waiter)
    match @coroutine.suspend_check_cancel() {
      Continue => ()
      Cancelled if !waiter.is_queued() =>
        // In the rare case where:
        //
        // - `release` wake up a waiter, the piece of resource is assigned to that waiter
        // - the waiter is immediately cancelled after woken up by `release`,
        //   but before the waiter's coroutine actually resumes execution
        //
        // we must swallow the cancellation signal,
        // as otherwise the piece of resource will be gone forever.
        ()
      Cancelled => {
        self.waiters.remove(waiter)
        @coroutine.raise_cancellation_signal()
      }
    }
  }
}

///|
/// Try to acquire one unit of resource from the semaphore.
/// If resource is successfully acquired, `true` is returned,
/// Otherwise, `false` is returned immediately without blocking.
pub fn Semaphore::try_acquire(self : Semaphore) -> Bool {
  if self.value > 0 {
    self.value -= 1
    true
  } else {
    false
  }
}
