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
/// The result of a completed process.
/// Exit code of the process can be obtained via `.exit_code`.
///
/// If the stdout/stderr channel of a process is redirected to `@process.read_from_process()`,
/// the content of the corresponding channel can be obtained via
/// `.stdout_binary()` or `.stdout_text()`/`.stderr_binary()` or `.stderr_text()`.
pub struct ProcessResult {
  exit_code : Int32
  priv stdout : Bytes?
  priv stderr : Bytes?
}

///|
/// Obtain the collected content of a child process's stdout.
/// The child process's `stdout` must be redirected to `@process.read_from_process()`.
pub fn ProcessResult::stdout_binary(self : ProcessResult) -> Bytes {
  guard self.stdout is Some(stdout) else {
    abort(
      "cannot read output of a process whose stdout is not `@process.read_from_process()`",
    )
  }
  stdout
}

///|
/// Obtain the collected content of a child process's stdout, as UTF-8 encoded text.
/// The child process's `stdout` must be redirected to `@process.read_from_process()`.
pub fn ProcessResult::stdout_text(self : ProcessResult) -> String raise {
  @utf8.decode(self.stdout_binary())
}

///|
/// Obtain the collected content of a child process's stderr.
/// The child process's `stderr` must be redirected to `@process.read_from_process()`.
pub fn ProcessResult::stderr_binary(self : ProcessResult) -> Bytes {
  guard self.stderr is Some(stderr) else {
    abort(
      "cannot read output of a process whose stderr is not `@process.read_from_process()`",
    )
  }
  stderr
}

///|
/// Obtain the collected content of a child process's stderr, as UTF-8 encoded text.
/// The child process's `stderr` must be redirected to `@process.read_from_process()`.
pub fn ProcessResult::stderr_text(self : ProcessResult) -> String raise {
  @utf8.decode(self.stderr_binary())
}

///|
/// Execute a system process with command `cmd`,
/// and provide `args` as extra arguments to `cmd`.
///
/// Instead of spawning the child process in a task group,
/// run will simply block and wait for completion of the child process in current task.
/// If `@process.run()` is cancelled after the child process started,
/// the child process will be cancelled automatically as well, and `@process.run()` will return
/// only after the child completes its cleanup and actually terminates.
///
/// `@process.run()` does not expose a `Process` object for the child,
/// so the caller cannot retrieve the PID or `.stdin` channel of the child process.
/// As a consequence, `@process.write_to_process()` cannot be used with `@process.run()`.
/// When the current process needs to interact with the child's `stdin`,
/// use `@process.spawn` instead or `@process.write_to_process_shared()` instead.
///
/// When `stdout`/`stderr` of `@process.run()` is redirected to `@process.read_from_process()`,
/// `@process.run` will collect the output of the corresponding channel automatically.
/// The result can be obtained by calling
/// `.stdout_binary()`/`.stderr_binary()`/`.stdout_text()`/`.stderr_text()`
/// on the returned `struct ProcessResult`.
///
/// All remaining arguments of `@process.run` have the same meaning as `@process.spawn`,
/// see `@process.spawn` for more details.
pub async fn run(
  cmd : StringView,
  args : ArrayView[String],
  extra_env~ : Map[String, String] = Map([]),
  inherit_env~ : Bool = true,
  stdin~ : &ProcessInput = @stdio.stdin,
  stdout~ : &ProcessOutput = @stdio.stdout,
  stderr~ : &ProcessOutput = @stdio.stderr,
  cwd? : StringView,
  no_console_window~ : Bool = false,
  cancel_handler~ : CancellationHandler = graceful_cancel(timeout=5000),
) -> ProcessResult {
  let context = "@process.run()"
  let (process, stdin, stdout, stderr) = raw_spawn(
    cmd,
    args,
    extra_env~,
    inherit_env~,
    stdin~,
    stdout~,
    stderr~,
    cwd~,
    no_console_window~,
    is_orphan=false,
    context~,
  )
  defer process.close()
  // The caller of `run` has no way to obtain this channel,
  // so close it immediately to avoid leak & hang up.
  stdin.close()
  let pid = process.pid
  let mut exit_code = 0
  let mut stdout_result = None
  let mut stderr_result = None
  @async_io.with_task_group <| group => {
    group.spawn_bg() <| () => {
      defer stdout.close()
      if stdout.io is Some(_) {
        stdout_result = Some(stdout.read_all())
      }
    }
    group.spawn_bg() <| () => {
      defer stderr.close()
      if stderr.io is Some(_) {
        stderr_result = Some(stderr.read_all())
      }
    }
    match @async_io.handle_cancellation(() => process.wait_pid(context~)) {
      None => {
        @async_io.protect_from_cancel() <| () => {
          @async_io.with_task_group() <| group => {
            group.spawn_bg(no_wait=true, () => cancel_handler(pid))
            ignore <| process.wait_pid(context~)
          }
        }
        @coroutine.raise_cancellation_signal()
      }
      Some(ret) => exit_code = ret
    }
  }
  { exit_code, stdout: stdout_result, stderr: stderr_result, }
}

///|
/// A handle to a spawned process
pub struct Process {
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
  priv result : @async_io.Task[Int32]
}

///|
/// Wait for a process to terminate, return the exit code of the process
/// If the process is killed by a signal, the result would be `-signal_number`.
pub async fn Process::wait(self : Process) -> Int32 {
  self.result.wait()
}

///|
/// If the process already terminated, return its exit code.
/// If the process is killed by a signal, the result would be `-signal_number`.
/// If the process is still running, return `None`.
pub fn Process::try_wait(self : Process) -> Int32? raise {
  self.result.try_wait()
}

///|
/// Cancel a child process.
/// The method of cancellation is determined by the `cancel_handler` parameter of `@process.spawn`.
/// Notice that after `.cancel()` is called,
/// if may take a while before the child process actually terminates.
/// Use `.wait()` to wait for actual termination of the child process.
pub fn Process::cancel(self : Process) -> Unit {
  self.result.cancel()
}

///|
/// Spawn a child process inside a task group.
/// The child process runs the program on path `cmd`,
/// and `args` will be provided to the program as command line arguments.
/// On Linux/MacOS, both `cmd` and `args` are encoded using UTF-8.
/// On Windows, both `cmd` and `args` are passed via native unicode string,
/// and `args` will be converted to Windows-style command line string via C argv splitting rule.
///
/// If `no_wait` is `false` (`fales` by default),
/// the task group will wait for termination of the child process before returning normally.
/// When the task group is about to exit, for example due to fatal error, external cancellation,
/// the child process will be terminated automatically.
///
/// A `Process` object will be returned,
/// users can retrieve the PID of the spawned process via `.pid`
/// or wait for the process to terminate via `.wait()`/`.try_wait()`.
///
/// The standard IO of the new process will be redirected to the value of `stdin`, stdout` and `stderr`.
/// By default the child process will inherit corresponding stdio channels from current process.
/// Standard IO channel can be redirected to one of the following:
///
/// - `@process.read_from_process()`, `@process.write_to_process()`,
///   `@process.read_from_process_shared()` and `@process.write_to_process_shared()`
///   can be used to interact with the child from current process
/// - `@process.pipe()` can be used to connect input/output channels of multiple children process
/// - `@process.redirect_to_file()`, `@process.rerdirect_from_file()`,
///   `@process.redirect_to_file_shared()` and `@process.rerdirect_from_file_shared()`
///   can be used to redirect input/output to a file path
/// - `@stdio.stdin`, `@stdio.stdout` and `@stdio.stderr` can also be used for redirection directly
/// - `@process.duplicate_stdout()` can be used to redirect stderr,
///   in this case the child process's stderr channel will be the same as its stdout channel
///
/// See the document of the above functions for more detail on each kind of redirection,
/// in particular resource management contract on various objects involved.
///
/// If `inherit_env` is `true` (`true` by default),
/// the new process will inherit environment variables of current process.
///
/// `extra_env`, if present, will set extra environment variables for the new process
/// (in addition to and overriding those inherited ones, if `inherit_env` is `true`).
/// Keys and values of `extra_env` are encoded using UTF8.
///
/// If `cwd` is present, the spawned command will be executed
/// in the directory specified by `cwd`.
///
/// When `no_console_window` is `true` (`false` by default),
/// creation of a new console window will be disabled on Windows.
/// By default a new console window may be created
/// when the calling process is a GUI application
/// and the child process is a conlose application.
/// `no_console_window` has no effect on non-Windows platforms.
///
/// The child process can be cancelled manually via `.cancel()` on the returned `Process` object.
/// The child may also get cancelled automatically by the task group.
/// When the child process is cancelled, `cancel_handler` will be used to automatically stop the process.
/// The default value of `cancel_handler` is `graceful_cancel(timeout=5000)`
/// (First try to gracefully terminate the process,
/// and if the process is still running after five seconds, terminate it forcefully).
/// Note that the task group will not exit until the child process actually terminates
/// (i.e. after the child process completes its cleanup process).
/// So the child process will never leak outside its task group.
///
/// If `cancel_handler` is still running after the process terminates,
/// it will be cancelled.
pub async fn spawn(
  group : @async_io.TaskGroup,
  cmd : StringView,
  args : ArrayView[String],
  extra_env~ : Map[String, String] = Map([]),
  inherit_env~ : Bool = true,
  stdin~ : &ProcessInput = @stdio.stdin,
  stdout~ : &ProcessOutput = @stdio.stdout,
  stderr~ : &ProcessOutput = @stdio.stderr,
  cwd? : StringView,
  no_console_window~ : Bool = false,
  cancel_handler~ : CancellationHandler = graceful_cancel(timeout=5000),
  no_wait? : Bool,
) -> Process {
  let context = "@process.spawn()"
  let (process, stdin, stdout, stderr) = raw_spawn(
    cmd,
    args,
    extra_env~,
    inherit_env~,
    stdin~,
    stdout~,
    stderr~,
    cwd~,
    no_console_window~,
    is_orphan=false,
    context~,
  )
  let pid = process.pid
  let result = group.spawn(no_wait?, () => {
    defer process.close()
    match @async_io.handle_cancellation(() => process.wait_pid(context~)) {
      None => {
        let mut result = 0
        @async_io.protect_from_cancel() <| () => {
          @async_io.with_task_group() <| group => {
            group.spawn_bg(no_wait=true, () => cancel_handler(pid))
            result = process.wait_pid(context~)
          }
        }
        result
      }
      Some(ret) => ret
    }
  })
  { pid, stdin, stdout, stderr, result, }
}
