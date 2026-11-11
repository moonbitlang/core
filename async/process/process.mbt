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
/// If a process's `stdout` or `stderr` is redirected with `Collect`, the content
/// of that stream can be obtained via
/// `.stdout_binary()` or `.stdout_text()`/`.stderr_binary()` or `.stderr_text()`.
pub struct ProcessResult {
  exit_code : Int32
  priv stdout : Bytes?
  priv stderr : Bytes?
}

///|
/// Obtain the collected content of a child process's stdout.
/// The child process's `stdout` must be redirected with `Collect`.
pub fn ProcessResult::stdout_binary(self : ProcessResult) -> Bytes {
  guard self.stdout is Some(stdout) else {
    abort(
      "cannot read output of a process whose stdout is not redirected with `Collect`",
    )
  }
  stdout
}

///|
/// Obtain the collected content of a child process's stdout, as UTF-8 encoded text.
/// The child process's `stdout` must be redirected with `Collect`.
pub fn ProcessResult::stdout_text(self : ProcessResult) -> String raise {
  @utf8.decode(self.stdout_binary())
}

///|
/// Obtain the collected content of a child process's stderr.
/// The child process's `stderr` must be redirected with `Collect`.
pub fn ProcessResult::stderr_binary(self : ProcessResult) -> Bytes {
  guard self.stderr is Some(stderr) else {
    abort(
      "cannot read output of a process whose stderr is not redirected with `Collect`",
    )
  }
  stderr
}

///|
/// Obtain the collected content of a child process's stderr, as UTF-8 encoded text.
/// The child process's `stderr` must be redirected with `Collect`.
pub fn ProcessResult::stderr_text(self : ProcessResult) -> String raise {
  @utf8.decode(self.stderr_binary())
}

///|
/// Error raised when `accepted_exit_code` rejects a command's exit code.
/// It contains the rejected code and a copy of the command's program and
/// arguments.
#derive(@debug.Debug)
pub suberror CommandFailed {
  CommandFailed(Int32, program~ : String, args~ : ReadOnlyArray[String])
}

///|
pub impl Show for CommandFailed with fn output(self, logger) {
  let CommandFailed(code, program~, args~) = self
  logger..write_string("command `").write_string(program)
  for arg in args {
    logger..write_char(' ').write_string(arg)
  }
  logger..write_string("` failed with exit code ").write_object(code)
}

///|
pub extend CommandFailed with Show::{to_string}

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
/// As a consequence, `FeedFromParent` cannot be used to interact with
/// `@process.run()`.
/// When the current process needs to interact with the child's `stdin`,
/// use `@process.spawn` with `FeedFromParent`, or create a caller-owned input
/// channel with `@process.write_to_process()` and pass it as `stdin=Shared(input)`.
///
/// When `stdout` or `stderr` is redirected with `Collect`, `@process.run()`
/// collects the corresponding output automatically.
/// The result can be obtained by calling
/// `.stdout_binary()`/`.stderr_binary()`/`.stdout_text()`/`.stderr_text()`
/// on the returned `struct ProcessResult`.
///
/// `accepted_exit_code` is called with the exit code after the process terminates normally.
/// By default all exit codes are accepted and returned.
/// If the predicate reports `false` on the child process' exit code,
/// `run` raises `CommandFailed` with the rejected code, program, and arguments.
/// The error code is not checked when `run` is cancelled.
///
/// All remaining arguments of `@process.run` have the same meaning as `@process.spawn`,
/// see `@process.spawn` for more details.
pub async fn run(
  cmd : StringView,
  args : ArrayView[String],
  extra_env~ : Map[String, String] = Map([]),
  inherit_env~ : Bool = true,
  stdin~ : ProcessInput = Inherit,
  stdout~ : ProcessOutput = Inherit,
  stderr~ : ProcessOutput = Inherit,
  cwd? : StringView,
  no_console_window~ : Bool = false,
  cancel_handler~ : CancellationHandler = graceful_cancel(timeout=5000),
  accepted_exit_code~ : (Int32) -> Bool = _ => true,
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
  @async.with_task_group <| group => {
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
    match @async.handle_cancellation(() => process.wait_pid(context~)) {
      None => {
        @async.protect_from_cancel() <| () => {
          @async.with_task_group() <| group => {
            group.spawn_bg(no_wait=true, () => cancel_handler(pid))
            ignore <| process.wait_pid(context~)
          }
        }
        @coroutine.raise_cancellation_signal()
      }
      Some(ret) => {
        guard accepted_exit_code(ret) else {
          raise CommandFailed(
            ret,
            program=cmd.to_owned(),
            args=ReadOnlyArray::from_array(args),
          )
        }
        exit_code = ret
      }
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
  /// with `stdin=FeedFromParent`.
  /// In this case, it can be used to write to stdin of the child process.
  stdin : WriteToProcess
  /// Redirected `stdout` channel of the process.
  /// This field is only meaningful if the process is spawned
  /// with `stdout=Collect`.
  /// In this case, it can be used to read from the stdout of the child process.
  stdout : ReadFromProcess
  /// Redirected `stderr` channel of the process.
  /// This field is only meaningful if the process is spawned
  /// with `stderr=Collect`.
  /// In this case, it can be used to read from the stderr of the child process.
  stderr : ReadFromProcess
  priv result : @async.Task[Result[Int32, CommandFailed]]
}

///|
/// Wait for a process to terminate and return its exit code.
/// If the process is killed by a signal, the result would be `-signal_number`.
///
/// If the final exit code is rejected by the `accepted_exit_code` passed to
/// `spawn`, this method raises `CommandFailed`, including when the exit code is
/// produced while cancelling the process. A rejection caused by cancellation
/// does not fail the process's task group.
pub async fn Process::wait(self : Process) -> Int32 {
  self.result.wait().unwrap_or_error()
}

///|
/// If the process already terminated, return its exit code.
/// If the process is killed by a signal, the result would be `-signal_number`.
/// If the process is still running, return `None`.
///
/// If the final exit code is rejected by the `accepted_exit_code` passed to
/// `spawn`, this method raises `CommandFailed`, including when the exit code is
/// produced while cancelling the process. A rejection caused by cancellation
/// does not fail the process's task group.
pub fn Process::try_wait(self : Process) -> Int32? raise {
  match self.result.try_wait() {
    Some(result) => Some(result.unwrap_or_error())
    None => None
  }
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
/// If `no_wait` is `false` (`false` by default),
/// the task group will wait for termination of the child process before returning normally.
/// When the task group is about to exit, for example due to fatal error, external cancellation,
/// the child process will be terminated automatically.
///
/// A `Process` object will be returned,
/// users can retrieve the PID of the spawned process via `.pid`
/// or wait for the process to terminate via `.wait()`/`.try_wait()`.
///
/// The new process's standard streams are configured by `stdin`, `stdout`, and
/// `stderr`. They default to `Inherit`, which inherits the corresponding stream
/// from the current execution context.
///
/// Use `FeedFromParent` to write through `Process.stdin`, and `Collect` to read
/// through `Process.stdout` or `Process.stderr`. `FromFile`, `ToFile`, and
/// `AppendFile` provide automatically managed file redirection.
/// `DuplicateStdout` redirects standard error to the standard-output
/// destination. `Stdin`, `Stdout`, and `Stderr` select a parent-process standard
/// stream explicitly.
///
/// Use `Shared(input)` or `Shared(output)` with caller-owned endpoints returned
/// by `write_to_process()`, `read_from_process()`, `pipe_between_process()`,
/// `redirect_from_file()`, or `redirect_to_file()` when an endpoint must be
/// shared by multiple children or used independently of a `Process` handle.
/// Caller-owned endpoints must be closed after they have been passed to their
/// last child, or if spawning is abandoned.
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
/// `accepted_exit_code` would be called with the process's final exit code.
/// By default all exit codes are accepted.
/// If `accepted_exit_code` reports `false` on the exit code,
/// the child process will fail the task group and its waiters with `CommandFailed`.
/// If the child process is cancelled, an unsucessful exit code no longer fail the task group,
/// but `.wait()` and `.try_wait()` will still receive `CommandFailed`.
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
  group : @async.TaskGroup,
  cmd : StringView,
  args : ArrayView[String],
  extra_env~ : Map[String, String] = Map([]),
  inherit_env~ : Bool = true,
  stdin~ : ProcessInput = Inherit,
  stdout~ : ProcessOutput = Inherit,
  stderr~ : ProcessOutput = Inherit,
  cwd? : StringView,
  no_console_window~ : Bool = false,
  cancel_handler~ : CancellationHandler = graceful_cancel(timeout=5000),
  accepted_exit_code~ : (Int32) -> Bool = _ => true,
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
    match @async.handle_cancellation(() => process.wait_pid(context~)) {
      None => {
        let mut result = 0
        @async.protect_from_cancel() <| () => {
          @async.with_task_group() <| group => {
            group.spawn_bg(no_wait=true, () => cancel_handler(pid))
            result = process.wait_pid(context~)
          }
        }
        if accepted_exit_code(result) {
          Ok(result)
        } else {
          // On cancellation, don't fail the whole task group for incorrect exit code.
          // We still want `.wait()` to report the error, though,
          // similar to how `@async.Task::wait` fail with `TaskAlreadyCancelled`
          Err(
            CommandFailed(
              result,
              program=cmd.to_owned(),
              args=ReadOnlyArray::from_array(args),
            ),
          )
        }
      }
      Some(ret) => {
        guard accepted_exit_code(ret) else {
          raise CommandFailed(
            ret,
            program=cmd.to_owned(),
            args=ReadOnlyArray::from_array(args),
          )
        }
        Ok(ret)
      }
    }
  })
  { pid, stdin, stdout, stderr, result, }
}
