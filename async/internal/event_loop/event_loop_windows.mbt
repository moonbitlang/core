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
#cfg(any(target="wasm", platform="windows"))
priv struct WindowsEventLoopExtra {}

///|
#cfg(platform="windows")
type PlatformEventLoopExtra = WindowsEventLoopExtra

///|
#cfg(platform="windows")
extern "C" fn init_WSA_ffi() -> Int32 = "moonbit_rt_init_WSA"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn init_WSA_ffi() -> Int32 = "moonbitlang/async" "runtime/init_WSA"

///|
#cfg(any(target="wasm", platform="windows"))
fn WindowsEventLoopExtra::new() -> Self raise {
  if init_WSA_ffi() != 0 {
    @os_error.check_errno("initialize WSA")
  }
  WindowsEventLoopExtra::{ }
}

///|
#cfg(platform="windows")
extern "C" fn cleanup_WSA_ffi() -> Int32 = "moonbit_rt_cleanup_WSA"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn cleanup_WSA_ffi() -> Int32 = "moonbitlang/async" "runtime/cleanup_WSA"

///|
#cfg(any(target="wasm", platform="windows"))
fn WindowsEventLoopExtra::destroy(_self : WindowsEventLoopExtra) -> Unit {
  ignore(cleanup_WSA_ffi())
}

///|
#cfg(any(target="wasm", platform="windows"))
fn WindowsEventLoopExtra::cleanup(self : WindowsEventLoopExtra) -> Unit {
  ignore(self)
}

///|
#cfg(any(target="wasm", platform="windows"))
fn WindowsEventLoopExtra::handle_event(
  _self : Self,
  evloop : EventLoop,
  event : Event,
) -> Unit {
  let fd = event.fd()
  if fd == evloop.notify_recv {
    // custom completion packet from thread pool.
    // Here we use the `dwNumberOfBytesTransferred` field to store job ID
    let job_id = event.bytes_transferred()
    evloop.handle_completed_job(job_id)
  } else {
    // completed IO operation on a file descriptor
    guard evloop.fds.get(fd) is Some(io) else {  }
    let result = event.io_result()
    let event = result.event()
    if event is ReadEvent && io.read is Waiting(coro) {
      coro.wake()
    } else if event is WriteEvent && io.write is Waiting(coro) {
      coro.wake()
    }
  }
}
