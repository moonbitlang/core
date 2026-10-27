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
/// This type is not implemented on wasm-gc backend
type Timer

///|
/// This function is not implemented on wasm-gc backend
pub fn Timer::new(duration : Int32, callback : () -> Unit) -> Timer {
  ignore(duration)
  ignore(callback)
  abort("`Timer::new()` is unimplemented on WASM backend")
}

///|
/// This function is not implemented on wasm-gc backend
pub fn Timer::cancel(timer : Timer) -> Unit {
  ignore(timer)
  abort("`Timer::cancel()` is unimplemented on WASM backend")
}

///|
/// This function is not implemented on wasm-gc backend
#warnings("-unused_async")
pub async fn sleep(duration : Int32) -> Unit {
  ignore(duration)
  abort("`sleep()` is unimplemented on WASM backend")
}
