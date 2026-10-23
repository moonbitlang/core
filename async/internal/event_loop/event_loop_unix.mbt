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
#cfg(not(platform="windows"))
priv struct UnixEventLoopExtra {
  // On MacOS, PID waiting is implemented directly via kqueue, 
  // so we need to separately maintain waiters for each PID.
  pids : Map[Int32, @coroutine.Coroutine]
  // On Linux/MacOS, notifications for completion of thread pool job
  // are transferred via a pipe, this buffer is used to read from the pipe.
  completed_jobs_buffer : FixedArray[Int32]
}

///|
#cfg(all(target="native", not(platform="windows")))
type PlatformEventLoopExtra = UnixEventLoopExtra

///|
#cfg(not(platform="windows"))
fn UnixEventLoopExtra::new() -> UnixEventLoopExtra {
  { pids: Map([]), completed_jobs_buffer: FixedArray::make(1024, 0), }
}

///|
#cfg(not(platform="windows"))
fn UnixEventLoopExtra::destroy(self : UnixEventLoopExtra) -> Unit {
  ignore(self)
}

///|
#cfg(not(platform="windows"))
fn UnixEventLoopExtra::cleanup(self : UnixEventLoopExtra) -> Unit {
  for _, coro in self.pids {
    coro.cancel()
  }
  self.pids.clear()
}

///|
#cfg(not(platform="windows"))
fn UnixEventLoopExtra::handle_event(
  self : Self,
  evloop : EventLoop,
  event : Event,
) -> Unit raise {
  let events = event.events()
  if (events & ProcessEvent) != 0 {
    let pid = event.pid()
    if self.pids.get(pid) is Some(coro) {
      coro.wake()
    }
    return
  }
  let fd = event.fd()
  if fd == evloop.notify_recv {
    while true {
      let bytes_transferred = fetch_completion_ffi(
        evloop.notify_recv,
        self.completed_jobs_buffer,
      )
      if bytes_transferred < 0 {
        @os_error.check_errno("runtime internal: failed to get completed job")
      }
      let n = bytes_transferred / 4
      for i in 0..<n {
        evloop.handle_completed_job(self.completed_jobs_buffer[i])
      }
      if n < self.completed_jobs_buffer.length() {
        break
      }
    }
  } else if evloop.fds.get(fd) is Some(handle) {
    if (events & ReadEvent) != 0 && handle.read is Waiting(coro) {
      coro.wake()
    }
    if (events & WriteEvent) != 0 && handle.write is Waiting(coro) {
      coro.wake()
    }
  }
}

///|
#cfg(not(platform="windows"))
async fn UnixEventLoopExtra::wait_pid(
  self : Self,
  evloop : EventLoop,
  pid : Int32,
) -> Unit {
  guard! self.pids.get(pid) is None
  self.pids[pid] = @coroutine.current_coroutine()
  defer self.pids.remove(pid)
  evloop.suspend()
}
