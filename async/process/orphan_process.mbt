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
/// A handle to a spawned orphan process. Must be explicitly closed.
pub struct OrphanProcess {
  pid : Int32
  /// Redirected `stdin` channel of the process.
  /// This field is only meaningful if the process is spawned
  /// with `stdin` redirected to `@process.write_to_process()`.
  /// In this case, it can be used to write to stdin of the child process.
  stdin : WriteToProcess
  /// Redirected `stdout` channel of the process.
  /// This field is only meaningful if the process is spawned
  /// with `stdout` redirected to `@process.read_from_process()`.
  /// In this case, it can be used to read from the stdout of the child process.
  stdout : ReadFromProcess
  /// Redirected `stderr` channel of the process.
  /// This field is only meaningful if the process is spawned
  /// with `stderr` redirected to `@process.read_from_process()`.
  /// In this case, it can be used to read from the stderr of the child process.
  stderr : ReadFromProcess
  priv handle : @event_loop.Process
}

///|
/// Close handle to an orphan process, release associated resource.
/// Note that closing the handle will not terminate the child process.
pub fn OrphanProcess::close(self : OrphanProcess) -> Unit {
  self.handle.close()
}

///|
/// Execute a system process with command `cmd`,
/// and provide `args` as extra arguments to `cmd.
/// Both `cmd` and elements of `args` are encoded using UTF8.
/// A handle similar to `Process` is returned, see `@process.spawn` for more details.
///
/// The spawned process would be *orphan*, meaning that it will
/// keep running until completion or explicitly terminated,
/// even if the task that calls `spawn_orphan` is cancelled.
/// Users are recommended to use `@process.run` whenever possible,
/// because `@process.spawn`/`@process.run` has better structured concurrency integration.
/// `spawn_orphan` should only be used when the process is intended to be orphan
/// (i.e. keep running after parent process terminates).
///
/// The meaning of the arguments is the same as `@process.spawn`,
/// see `@process.spawn` for more details.
pub async fn spawn_orphan(
  cmd : StringView,
  args : ArrayView[String],
  extra_env~ : Map[String, String] = Map([]),
  inherit_env~ : Bool = true,
  stdin~ : &ProcessInput = @stdio.stdin,
  stdout~ : &ProcessOutput = @stdio.stdout,
  stderr~ : &ProcessOutput = @stdio.stderr,
  cwd? : StringView,
  no_console_window~ : Bool = false,
) -> OrphanProcess {
  let (proc, stdin, stdout, stderr) = raw_spawn(
    cmd,
    args,
    extra_env~,
    inherit_env~,
    stdin~,
    stdout~,
    stderr~,
    cwd~,
    no_console_window~,
    is_orphan=true,
    context="@process.spawn_orphan()",
  )
  { pid: proc.pid, stdin, stdout, stderr, handle: proc, }
}

///|
/// Wait for the completion of an orphan process and return its exit code.
/// If the process is killed by signal, the result would be `-signal_number`.
pub async fn OrphanProcess::wait(self : OrphanProcess) -> Int32 {
  self.handle.wait_pid(context="@process.OrphanProcess::wait()")
}

///|
/// Wait for the process with specfic ID to terminate,
/// and return the exit code of the process.
/// If the process is killed by a signal, the result would be `-signal_number`.
pub async fn wait_pid(pid : Int32) -> Int32 {
  let context = "@process.wait_pid()"
  let process = @event_loop.Process::from_pid(pid, context~)
  defer process.close()
  process.wait_pid(context~)
}
