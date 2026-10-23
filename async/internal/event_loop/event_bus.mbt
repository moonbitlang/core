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
/// The main event bus for receiving various notifications
/// This is what the main event loop iterates over.
/// Implementation:
///
/// - Linux: epoll
/// - MacOS: kqueue
/// - Windows: IOCP
priv struct EventBus(@fd_util.Fd)

///|
const ReadEvent = 1

///|
const WriteEvent = 2

///|
#cfg(not(platform="windows"))
const ProcessEvent = 4

///|
extern "C" fn EventBus::new() -> EventBus = "moonbit_rt_event_bus_create"

///|
extern "C" fn EventBus::destroy(self : EventBus) = "moonbit_rt_event_bus_destroy"

///|
extern "C" fn EventBus::register_ffi(
  self : EventBus,
  fd : @fd_util.Fd,
  read_only : Bool,
) -> Int32 = "moonbit_rt_event_bus_register"

///|
/// Try to register the file descriptor with the event bus,
/// return `true` if the file descriptor is succesfully registered,
/// `false` if the fd is not supported.
fn EventBus::register(
  self : EventBus,
  fd : @fd_util.Fd,
  read_only~ : Bool,
) -> Bool raise {
  let ret = self.register_ffi(fd, read_only)
  if ret < 0 {
    @os_error.check_errno("runtime internal: @event_loop.EventBus::register()")
  }
  ret > 0
}

///|
#cfg(not(platform="windows"))
extern "C" fn EventBus::register_pid_ffi(self : EventBus, pid : Int32) -> Int32 = "moonbit_rt_event_bus_register_pid"

///|
/// Return `true` if the PID is successfully registered.
/// Return `false` if the process has already terminated.
#cfg(not(platform="windows"))
fn EventBus::register_pid(self : EventBus, pid : Int32) -> Bool raise {
  let ret = self.register_pid_ffi(pid)
  if ret == -1 {
    @os_error.check_errno("poll_register_pid")
  }
  ret > 0
}

///|
extern "C" fn EventBus::remove_ffi(self : EventBus, fd : @fd_util.Fd) -> Int32 = "moonbit_rt_event_bus_remove"

///|
fn EventBus::remove(self : EventBus, fd : @fd_util.Fd) -> Unit raise {
  if self.remove_ffi(fd) < 0 {
    @os_error.check_errno("runtime internal: @event_loop.EventBus::remove()")
  }
}

///|
#external
priv type Event

///|
extern "C" fn EventBus::get_event(self : EventBus, index : Int32) -> Event = "moonbit_rt_event_list_get"

///|
extern "C" fn Event::fd(self : Event) -> @fd_util.Fd = "moonbit_rt_event_get_fd"

///|
#cfg(not(platform="windows"))
fn Event::pid(self : Event) -> Int32 {
  self.fd()
}

///|
#cfg(not(platform="windows"))
extern "C" fn Event::events(self : Event) -> Int32 = "moonbit_rt_event_get_events"

///|
#cfg(platform="windows")
extern "C" fn Event::io_result(self : Event) -> IoResult = "moonbit_rt_event_get_io_result"

///|
#cfg(platform="windows")
extern "C" fn Event::bytes_transferred(self : Event) -> Int32 = "moonbit_rt_event_get_bytes_transferred"

///|
extern "C" fn EventBus::wait(self : EventBus, timeout~ : Int32) -> Int32 = "moonbit_rt_event_bus_wait"

///|
priv struct EventBusWaiter(@c_buffer.Buffer)

///|
extern "C" fn EventBus::spawn_waiter(
  bus : EventBus,
  wakeup_callback~ : FuncRef[() -> Unit],
) -> EventBusWaiter = "moonbit_rt_spawn_event_bus_waiter"

///|
extern "C" fn EventBusWaiter::terminate(self : Self) -> Unit = "moonbit_rt_terminate_event_bus_waiter"

///|
extern "C" fn EventBusWaiter::get_events(self : Self) -> Int32 = "moonbit_rt_event_bus_waiter_get_events"

///|
extern "C" fn EventBusWaiter::wake(self : Self) -> Unit = "moonbit_rt_wake_event_bus_waiter"
