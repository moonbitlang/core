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
/// Get current time since Unix EPOCH in milliseconds.
/// The event loop uses the same timer as `now()` for timers.
pub fn now() -> Int64 {
  @env.now().reinterpret_as_int64()
}

///|
/// Perform a new round of scheduling by running all ready coroutines immediately.
/// While running these coroutines, new coroutines may get waken or spawned,
/// these new coroutines will *not* get executed immediately.
/// Instead, they will be executed on the next JavaScript event loop (delayed via `setTimeout(0)`).
/// This give other code in the same JS event loop get a chance to execute and prevent starvation.
pub fn reschedule() -> Unit {
  guard !@coroutine.all_coroutines().is_empty() else {  }
  @coroutine.reschedule()
  // Instead of looping blockingly until there is no ready task,
  // we only perform one round of scheduling here
  // (i.e., only those tasks already ready when `reschedule` is called are run).
  // Remaining tasks are delayed untin the next js event loop,
  // so that those blocking jobs got a chance to execute instead of starving.
  if @coroutine.has_immediately_ready_task() {
    ignore(set_timeout(0, reschedule))
  }
}
