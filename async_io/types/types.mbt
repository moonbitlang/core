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
/// The wasm host uses opaque `UInt64` handles for host-owned file resources.
#cfg(target="wasm")
pub type Fd = UInt64

///|
/// The type for a system file descriptor.
/// An integer on Unix-like systems, or an opaque pointer (`HANDLE`) on Windows
#cfg(platform="windows")
#external
pub type Fd

///|
#cfg(platform="windows")
pub impl Eq for Fd with fn equal(x, y) = "%refeq"

///|
#cfg(platform="windows")
extern "C" fn Fd::to_uint64(fd : Fd) -> UInt64 = "moonbit_rt_fd_as_uint64"

///|
#cfg(platform="windows")
pub impl Hash for Fd with fn hash_combine(self, hasher) {
  hasher.combine_uint64(self.to_uint64())
}

///|
/// The type for a system file descriptor.
/// An integer on Unix-like systems, or an opaque pointer (`HANDLE`) on Windows
#cfg(not(any(platform="windows", target="wasm")))
pub type Fd = Int32

///|
/// Current operating system running the program.
/// For Wasm backend, the actual operating system can only be known at runtime.
pub(all) enum Platform {
  Linux = 0
  MacOS = 1
  Windows = 2
}
