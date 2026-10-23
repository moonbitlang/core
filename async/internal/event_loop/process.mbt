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
/// A handle to an running process, can be used for waiting etc.
#valtype
pub struct Process {
  pid : Int32
  priv handle : IoHandle?
}

///|
/// Close a proces handle, release associated resource
pub fn Process::close(self : Process) -> Unit {
  if self.handle is Some(io) {
    io.close()
  }
}

///|
#cfg(target="native")
extern "C" fn open_pid_handle(pid : Int32) -> @fd_util.Fd = "moonbit_rt_open_pid_handle"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn open_pid_handle(pid : Int32) -> @fd_util.Fd = "moonbitlang/async" "process/open_pid_handle"

///|
/// Create a new process handle from a PID
pub fn Process::from_pid(pid : Int32, context~ : String) -> Process raise {
  let handle = open_pid_handle(pid)
  let handle = if !@fd_util.fd_is_valid(handle) {
    @os_error.check_errno(context)
    None
  } else {
    IoHandle::from_fd(
      handle,
      kind=Unknown,
      is_async=platform is Linux,
      read_only=true,
    )
    |> Some
  }
  { pid, handle, }
}

///|
#cfg(target="native")
#borrow(out)
extern "C" fn get_process_result(
  handle : @fd_util.Fd,
  pid : Int32,
  out : @ref.Ref[Int32],
) -> Int32 = "moonbit_rt_get_process_result"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(out)
fn get_process_result(
  handle : @fd_util.Fd,
  pid : Int32,
  out : @ref.Ref[Int32],
) -> Int32 = "moonbitlang/async" "process/get_process_result"

///|
#cfg(all(target="native", not(platform="windows")))
type SpawnJobArgv = @c_buffer.Buffer

///|
#cfg(target="wasm")
type SpawnJobArgv = UInt64

///|
#cfg(target="native")
type SpawnJobEnv = @c_buffer.Buffer

///|
#cfg(target="wasm")
type SpawnJobEnv = UInt64

///|
/// Wait for the termination of a process
#cfg(platform="windows")
pub async fn Process::wait_pid(self : Process, context~ : String) -> Int32 {
  self.wait_pid_windows(context~)
}

///|
/// Wait for the termination of a process
#cfg(all(target="native", not(platform="windows")))
pub async fn Process::wait_pid(self : Process, context~ : String) -> Int32 {
  self.wait_pid_unix(context~)
}

///|
/// Wait for the termination of a process
#cfg(target="wasm")
pub async fn Process::wait_pid(self : Process, context~ : String) -> Int32 {
  match platform {
    Linux | MacOS => self.wait_pid_unix(context~)
    Windows => self.wait_pid_windows(context~)
  }
}
