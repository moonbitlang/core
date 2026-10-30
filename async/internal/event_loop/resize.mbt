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
#cfg(target="wasm")
priv struct Resize {
  /// a resize not yet reported by `Tty::read`
  mut pending : Bool
  /// the `Tty::read` waiting for input that a resize should wake
  mut waiter : @coroutine.Coroutine?
}

///|
#cfg(target="wasm")
fn Resize::new() -> Resize {
  { pending: false, waiter: None, }
}

///|
/// Record a `SIGWINCH` and wake the `Tty::read` waiting for it
#cfg(target="wasm")
fn Resize::notify(self : Resize) -> Unit {
  self.pending = true
  if self.waiter is Some(coro) {
    coro.wake()
  }
}

///|
/// `@tty` is not supported on native yet, so a `SIGWINCH` is only dropped
#cfg(target="native")
priv enum Resize {
  Unsupported
}

///|
#cfg(target="native")
fn Resize::new() -> Resize {
  Unsupported
}

///|
#cfg(target="native")
fn Resize::notify(self : Resize) -> Unit {
  match self {
    Unsupported => ()
  }
}
