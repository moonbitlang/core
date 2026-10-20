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
/// Spawn a child process.
/// On Windows, target program and its command line arguments are supplied
/// via a command line string, instead of an array of string.
#cfg(any(platform="windows", target="wasm"))
pub async fn spawn_windows(
  command_line : @os_string.OsString,
  env~ : SpawnJobEnv,
  stdin~ : @fd_util.Fd,
  stdout~ : @fd_util.Fd,
  stderr~ : @fd_util.Fd,
  cwd~ : @os_string.OsString?,
  no_console_window~ : Bool,
  is_orphan~ : Bool,
  context~ : String,
) -> Process {
  let job = Job::spawn_windows(
    command_line,
    env~,
    stdin~,
    stdout~,
    stderr~,
    cwd~,
    no_console_window~,
    is_orphan~,
  )
  defer job.0.free()
  let pid = perform_job_in_worker(job.0, context~)
  let handle = IoHandle::from_fd(
    job.result_handle(),
    kind=Unknown,
    is_async=false,
  )
  { pid, handle: Some(handle), }
}

///|
#cfg(any(platform="windows", target="wasm"))
async fn Process::wait_pid_windows(self : Process, context~ : String) -> Int32 {
  guard! self.handle is Some(io)
  let job = Job::wait_for_process(io.fd, pid=self.pid)
  defer job.free()
  let _ = perform_job_in_worker(job, context~, cancellable=true)
  let out = @ref.Ref(0)
  let ret = get_process_result(io.fd, self.pid, out)
  if ret < 0 {
    @os_error.check_errno(context)
  }
  out.val
}
