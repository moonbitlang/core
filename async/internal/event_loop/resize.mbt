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
/// Terminal resizes seen by the event loop, reported by `Tty::read`
#cfg(not(platform="windows"))
priv struct Resize {
  /// a resize not yet reported by `Tty::read`
  mut pending : Bool
  /// the `Tty::read` waiting for input that a resize should wake
  mut waiter : @coroutine.Coroutine?
}

///|
#cfg(not(platform="windows"))
fn Resize::new() -> Resize {
  { pending: false, waiter: None, }
}

///|
/// Record a `SIGWINCH` and wake the `Tty::read` waiting for it
#cfg(not(platform="windows"))
fn Resize::notify(self : Resize) -> Unit {
  self.pending = true
  if self.waiter is Some(coro) {
    coro.wake()
  }
}

///|
/// Terminal resizes read from console input records, reported by `Tty::read`
#cfg(platform="windows")
priv struct Resize {
  /// a resize not yet reported by `Tty::read`
  mut pending : Bool
}

///|
#cfg(platform="windows")
fn Resize::new() -> Resize {
  { pending: false, }
}

///|
/// There is no `SIGWINCH` on Windows
#cfg(platform="windows")
fn Resize::notify(self : Resize) -> Unit {
  ignore(self)
}

///|
let resize_state : @ref.Ref[Resize?] = {
  let state : @ref.Ref[Resize?] = Ref(None)
  register_hook(init=() => state.val = Some(Resize::new()), exit=() => {
    state.val = None
  })
  state
}

///|
/// Record `signal` in `resize_state` if it is `SIGWINCH`.
/// Return whether it was.
fn notify_resize(signal : Int32) -> Bool {
  guard signal == SIGWINCH else { return false }
  if resize_state.val is Some(resize_state) {
    resize_state.notify()
  }
  true
}
