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
priv enum PlatformEventLoopExtra {
  Unix(UnixEventLoopExtra)
  Windows(WindowsEventLoopExtra)
}

///|
fn PlatformEventLoopExtra::new() -> Self raise {
  match platform {
    Linux | MacOS => Unix(UnixEventLoopExtra::new())
    Windows => Windows(WindowsEventLoopExtra::new())
  }
}

///|
fn PlatformEventLoopExtra::destroy(self : PlatformEventLoopExtra) -> Unit {
  match self {
    Unix(extra) => extra.destroy()
    Windows(extra) => extra.destroy()
  }
}

///|
fn PlatformEventLoopExtra::cleanup(self : PlatformEventLoopExtra) -> Unit {
  match self {
    Unix(extra) => extra.cleanup()
    Windows(extra) => extra.cleanup()
  }
}

///|
fn PlatformEventLoopExtra::handle_event(
  self : Self,
  evloop : EventLoop,
  event : Event,
) -> Unit raise {
  match self {
    Unix(extra) => extra.handle_event(evloop, event)
    Windows(extra) => extra.handle_event(evloop, event)
  }
}

///|
async fn PlatformEventLoopExtra::wait_pid(
  self : Self,
  evloop : EventLoop,
  pid : Int32,
) -> Unit {
  match self {
    Unix(extra) => extra.wait_pid(evloop, pid)
    Windows(_) => panic()
  }
}
