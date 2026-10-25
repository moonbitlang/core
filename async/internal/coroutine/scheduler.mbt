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
struct Scheduler {
  mut coro_id : Int32
  mut curr_coro : Coroutine?
  run_later : @deque.Deque[Coroutine]
  all_coros : @set.Set[Coroutine]
}

///|
/// The global coroutine scheduler
pub let scheduler : Scheduler = {
  coro_id: 0,
  curr_coro: None,
  run_later: Deque([]),
  all_coros: Set([]),
}

///|
/// Return current coroutine
pub fn current_coroutine() -> Coroutine {
  scheduler.curr_coro.unwrap()
}

///|
/// Check if there is any coroutine that can resume execution immediately
pub fn has_immediately_ready_task() -> Bool {
  !scheduler.run_later.is_empty()
}

///|
/// Perform a new round of scheduling by running all ready coroutines.
/// While running these coroutines, new coroutines may get waken or spawned,
/// these new coroutines will *not* get executed in this run of `reschedule`.
/// This give the event loop a chance to check of completed IO operations
/// and prevent starvation, even when there is always immediately ready coroutine.
pub fn reschedule() -> Unit {
  let n = scheduler.run_later.length()
  for _ in 0..<n {
    guard scheduler.run_later.pop_front() is Some(coro) else { break }
    coro.ready = false
    guard coro.state is Suspend(cont) else {  }
    coro.state = Running
    let last_coro = scheduler.curr_coro
    scheduler.curr_coro = Some(coro)
    if coro.cancelled && !coro.shielded {
      cont(Cancelled)
    } else {
      cont(Continue)
    }
    scheduler.curr_coro = last_coro
  }
}

///|
/// Return the list of all active coroutines
pub fn all_coroutines() -> @set.Set[Coroutine] {
  scheduler.all_coros
}
