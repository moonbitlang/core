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
extern "C" fn init_main_loop() -> Int32 = "init_main_loop"

///|
extern "C" fn destroy_main_loop() -> Unit = "destroy_main_loop"

///|
extern "C" fn wakeup_main_loop() -> Unit = "wakeup_main_loop"

///|
extern "C" fn wait_main_loop(timeout~ : Int32) -> Int32 = "wait_main_loop"

///|
extern "C" fn trigger_event_ffi(
  pipe_w : @fd_util.Fd,
  data : Int32,
  deadline : UInt64,
) -> Unit = "trigger_event"

///|
/// Generic function for triggering an event in the custom event loop test.
/// The event will be triggered after `delay` milliseconds.
/// The delay will be performed asynchronously.
/// After the delay, `data` will be written to `pipe_w`, waking the MoonBit event loop.
/// If `pipe_w` is not a valid fd, a main loop specific event will be triggered.
pub fn trigger_event(
  pipe_w : @fd_util.Fd,
  data : Int32,
  delay~ : Int32,
) -> Unit {
  trigger_event_ffi(pipe_w, data, @env.now() + delay.to_uint64())
}

///|
/// Trigger a custom loop specific event after `delay` milliseconds.
/// The delay will be performed asynchronously.
pub fn trigger_main_loop_event(delay~ : Int32) -> Unit {
  trigger_event(@fd_util.invalid_fd, 1, delay~)
}

///|
/// A simple custom event loop for testing purpose
pub struct MainLoop {
  log : Array[String]
  priv main_loop_event : @cond_var.Cond
}

///|
/// Create a new custom event loop
pub fn MainLoop::MainLoop() -> MainLoop raise {
  if init_main_loop() < 0 {
    @os_error.check_errno("init main loop")
  }
  { log: [], main_loop_event: Cond(), }
}

///|
/// Log a message in the custom event loop
pub fn MainLoop::log(self : MainLoop, msg : String) -> Unit {
  self.log.push(msg)
}

///|
/// Wait for new events from the custom event loop
pub async fn MainLoop::wait(self : MainLoop) -> Unit {
  self.main_loop_event.wait()
}

///|
pub impl @external_loop_integration.ExternalEventLoop for MainLoop with fn get_wakeup_callback_for_foreign_thread(
  _self,
) {
  () => wakeup_main_loop()
}

///|
pub impl @external_loop_integration.ExternalEventLoop for MainLoop with fn poll(
  self,
  timeout?,
) {
  let ret = wait_main_loop(timeout=timeout.unwrap_or(-1))
  if ret < 0 {
    @os_error.check_errno("wait main loop")
  }
  match ret {
    0 | 1 => ()
    2 => {
      self.log("main loop: received custom event")
      self.main_loop_event.signal()
    }
    _ => panic()
  }
}

///|
pub impl @external_loop_integration.ExternalEventLoop for MainLoop with fn terminate(
  self,
) {
  self.log("terminate main loop")
  destroy_main_loop()
}
