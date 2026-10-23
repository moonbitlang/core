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
#doc(hidden)
#internal(internal, "This API is for compatibility with `moonbitlang/async`, do not use")
#warnings("-unused_constructor")
struct Scheduler(@coroutine.Scheduler)

///|
#doc(hidden)
#internal(internal, "This API is for compatibility with `moonbitlang/async`, do not use")
pub fn get_current_scheduler() -> Scheduler {
  @coroutine.scheduler
}

///|
#doc(hidden)
#internal(internal, "This API is for compatibility with `moonbitlang/async`, do not use")
#warnings("-unused_constructor")
#cfg(any(target="native", target="wasm"))
struct CurrentEventLoop(@ref.Ref[@event_loop.EventLoop?])

///|
#doc(hidden)
#internal(internal, "This API is for compatibility with `moonbitlang/async`, do not use")
#cfg(any(target="native", target="wasm"))
pub fn get_current_event_loop() -> CurrentEventLoop {
  @event_loop.get_current_event_loop()
}

///|
#doc(hidden)
#internal(internal, "This API is for compatibility with `moonbitlang/async`, do not use")
#cfg(any(target="native", target="wasm"))
pub using @event_loop {with_event_loop, register_hook, set_deadlock_handler}

///|
#doc(hidden)
#internal(internal, "This API is for compatibility with `moonbitlang/async`, do not use")
#warnings("-unused_constructor")
#cfg(any(target="native", target="wasm"))
struct StdioChannel(Result[@event_loop.IoHandle, Error])

///|
#doc(hidden)
#internal(internal, "This API is for compatibility with `moonbitlang/async`, do not use")
#cfg(any(target="native", target="wasm"))
pub let stdin : StdioChannel = @event_loop.stdin

///|
#doc(hidden)
#internal(internal, "This API is for compatibility with `moonbitlang/async`, do not use")
#cfg(any(target="native", target="wasm"))
pub let stdout : StdioChannel = @event_loop.stdout

///|
#doc(hidden)
#internal(internal, "This API is for compatibility with `moonbitlang/async`, do not use")
#cfg(any(target="native", target="wasm"))
pub let stderr : StdioChannel = @event_loop.stderr
