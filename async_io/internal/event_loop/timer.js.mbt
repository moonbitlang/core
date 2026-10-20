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
/// A one-shot timer that may run in parallel with other async code
#external
type Timer

///|
extern "js" fn set_timeout(duration : Int32, f : () -> Unit) -> Timer =
  #| (duration, f) => setTimeout(f, duration)

///|
/// Create a new one-shot timer that expires `duration` milliseconds later.
/// `callback` will be invoked if the timer expires normally.
pub fn Timer::new(duration : Int32, f : () -> Unit) -> Timer {
  set_timeout(duration) <| () => {
    f()
    reschedule()
  }
}

///|
/// Cancel a timer
pub extern "js" fn Timer::cancel(self : Timer) =
  #| (timer) => clearTimeout(timer)

///|
/// Sleep for `duration` milliseconds.
/// This function can run in parallel with other `async` code
/// without blocking the whole program.
pub async fn sleep(duration : Int32) -> Unit noraise {
  let coro = @coroutine.current_coroutine()
  let timer = Timer::new(duration, () => coro.wake())
  defer timer.cancel()
  @coroutine.suspend()
}
