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
/// A command that can be started multiple times.
/// The command may be a single process or a composite command made up of multiple processes.
enum Cmd {
  Single(
    String,
    ReadOnlyArray[String],
    extra_env~ : Map[String, String],
    inherit_env~ : Bool,
    stdin~ : ProcessInput,
    stdout~ : ProcessOutput,
    stderr~ : ProcessOutput,
    cwd~ : StringView?,
    no_console_window~ : Bool,
    accepted_exit_code~ : (Int32) -> Bool
  )
  WithContext(
    Cmd,
    stdin~ : ProcessInput,
    stdout~ : ProcessOutput,
    stderr~ : ProcessOutput,
    cwd~ : StringView?
  )
  Pipe(Cmd, Cmd)
  Sequence(Array[Cmd])
}

///|
/// Create a new single-process command with given program and arguments.
///
/// `stdin`/`stdout`/`stderr` can be used to redirect stdio channels of the child process.
/// `stdin` MUST NOT be `FeedFromParent`, and `stdout`/`stderr` MUST NOT be `Collect`:
/// to supply input or collect output, set the corresponding channel to `Inherit`,
/// and supply `stdin=Empty`, `stdout=Collect` or `stderr=Collect` in `.run()` or `.spawn()`.
///
/// `args` and `extra_env` are copied, so later changes to the caller's
/// collections do not affect the command.
///
/// `accepted_exit_code` determines which normal exit codes are accepted. It
/// defaults to accepting every code, preserving the ordinary `@process`
/// behavior of returning nonzero statuses. If it returns `false`, running the
/// command raises `CommandFailed` with the exit code, program, and arguments.
/// Exit codes produced while cancelling the command are also checked, but a
/// rejection caused by cancellation does not fail the task group. If that
/// command's result remains observable, `.wait()` and `.try_wait()` report the
/// rejection as `CommandFailed`.
///
/// `cwd` can be used to set the working directory of this process.
/// If `cwd` is absent, the child process inherits the working directory from its context.
/// If `cwd` is a relative path, it is always interpreted
/// relative to the parent process (i.e. current process)'s working directory.
///
/// This command reports the process's exit status. When it is started with
/// `Cmd::spawn`, the returned `Process::pid` is this process's PID.
pub fn Cmd::Cmd(
  program : StringView,
  args : ArrayView[String],
  extra_env~ : Map[String, String] = Map([]),
  inherit_env~ : Bool = true,
  stdin~ : ProcessInput = Inherit,
  stdout~ : ProcessOutput = Inherit,
  stderr~ : ProcessOutput = Inherit,
  cwd? : StringView,
  no_console_window~ : Bool = false,
  accepted_exit_code~ : (Int32) -> Bool = _ => true,
) -> Cmd {
  if stdin is FeedFromParent {
    abort(
      "`stdin` must not be set to `FeedFromParent` when creating `@process.Cmd`",
    )
  }
  if stdout is Collect {
    abort("`stdout` must not be set to `Collect` when creating `@process.Cmd`")
  }
  if stderr is Collect {
    abort("`stderr` must not be set to `Collect` when creating `@process.Cmd`")
  }
  Single(
    program.to_owned(),
    ReadOnlyArray::from_array(args),
    extra_env=extra_env.copy(),
    inherit_env~,
    stdin~,
    stdout~,
    stderr~,
    cwd~,
    no_console_window~,
    accepted_exit_code~,
  )
}

///|
/// Create a command with local standard-I/O and working-directory settings.
///
/// Omitted settings, and channels explicitly set to `Inherit`, inherit from
/// the surrounding context. Settings on commands nested inside `cmd` take
/// precedence over this context. File redirections are opened once when this
/// context starts and are shared by all commands that inherit them.
///
/// `stdin` MUST NOT be `FeedFromParent`, and `stdout`/`stderr` MUST NOT be
/// `Collect`, because those settings create handles that can only be returned
/// from the outermost context established by `Cmd::run` or `Cmd::spawn`.
/// `Discard` is valid for either output channel.
///
/// This context does not change the wrapped command's exit-status or PID
/// selection rules.
pub fn Cmd::with_context(
  cmd : Cmd,
  stdin~ : ProcessInput = Inherit,
  stdout~ : ProcessOutput = Inherit,
  stderr~ : ProcessOutput = Inherit,
  cwd? : StringView,
) -> Cmd {
  if stdin is FeedFromParent {
    abort(
      "`stdin` must not be set to `FeedFromParent` in `@process.Cmd::with_context`",
    )
  }
  if stdout is Collect {
    abort(
      "`stdout` must not be set to `Collect` in `@process.Cmd::with_context`",
    )
  }
  if stderr is Collect {
    abort(
      "`stderr` must not be set to `Collect` in `@process.Cmd::with_context`",
    )
  }
  WithContext(cmd, stdin~, stdout~, stderr~, cwd~)
}

///|
/// Create a composite command that runs two commands in parallel,
/// and pipe the standard output of the first command to the standard input of the second.
///
/// When both commands succeed, the composite command reports `cmd2`'s status.
/// If either command rejects an exit code, the pipeline waits for both commands
/// and propagates the rightmost `CommandFailed`, following shell `pipefail`
/// behavior. These rules apply recursively to nested composites. `Cmd::spawn`
/// returns a `Process` whose `pid` is selected by `cmd2` according to its
/// recursive PID-selection rule; its `wait()` and `try_wait()` methods report
/// the whole pipeline's status. `Cmd::spawn` returns only after the pipeline's
/// current frontier has started. A sequence on that frontier starts as a
/// dedicated task and may not yet have spawned its first process. If starting
/// the frontier fails, members that have already started are cancelled and
/// awaited before the startup error is propagated.
pub impl BitOr for Cmd with fn lor(cmd1, cmd2) {
  Pipe(cmd1, cmd2)
}

///|
/// The named form of `cmd1 | cmd2`. When both commands succeed, the composite
/// command reports `cmd2`'s status. Otherwise it propagates the rightmost
/// rejected exit code according to the recursive `pipefail` rule. `Cmd::spawn`
/// returns a `Process` whose `pid` is selected by `cmd2` according to its
/// recursive PID-selection rule. It waits for the pipeline's current frontier
/// to start; if that fails, previously started frontier members are cancelled
/// and awaited before the startup error is propagated.
pub extend Cmd with BitOr::{lor as pipe}

///|
/// Create a composite command that runs multiple sub-commands in sequence.
/// If a command raises an error, including `CommandFailed` for a rejected exit/ code,
/// the error propagates and later commands are not started.
/// The final status of the whole sequence is the status of the last completed command.
///
/// `Cmd::spawn` starts a multi-command sequence in a dedicated task
/// and may return before its first command starts.
/// The returned `Process::pid` is `0`, because a sequence has no meaningful process PID.
///
/// `cmds` must not be empty.
pub fn Cmd::sequence(cmds : ArrayView[Cmd]) -> Cmd {
  if cmds.is_empty() {
    abort("cannot create an empty `@process.Cmd` sequence")
  }
  if cmds is [cmd] {
    return cmd
  }
  Sequence(cmds.to_owned())
}

///|
async fn ProcessInput::to_shared(
  input : ProcessInput,
) -> (ProcessInput, WriteToProcess) {
  match input {
    Inherit | Empty | Stdin => (input, no_input)
    Shared(obj) => {
      obj.incref()
      (input, no_input)
    }
    FeedFromParent => {
      let (r, w) = write_to_process()
      (Shared(r), w)
    }
    FromFile(path) => (Shared(redirect_from_file(path.to_owned())), no_input)
  }
}

///|
fn ProcessInput::incref(input : ProcessInput) -> Unit {
  if input is Shared(input) {
    input.incref()
  }
}

///|
fn ProcessInput::close_if_shared(input : ProcessInput) -> Unit {
  if input is Shared(input) {
    input.close()
  }
}

///|
async fn ProcessOutput::to_shared(
  output : ProcessOutput,
) -> (ReadFromProcess, ProcessOutput) {
  match output {
    Inherit | Discard | Stdout | Stderr | DuplicateStdout => (no_output, output)
    Shared(obj) => {
      obj.incref()
      (no_output, output)
    }
    Collect => {
      let (r, w) = read_from_process()
      (r, Shared(w))
    }
    ToFile(path) => {
      let w = redirect_to_file(path.to_owned())
      (no_output, Shared(w))
    }
    AppendFile(path) => {
      let w = redirect_to_file(
        path.to_owned(),
        create_mode=OpenOrCreate,
        append=true,
      )
      (no_output, Shared(w))
    }
  }
}

///|
fn ProcessOutput::incref(output : ProcessOutput) -> Unit {
  if output is Shared(output) {
    output.incref()
  }
}

///|
fn ProcessOutput::close_if_shared(output : ProcessOutput) -> Unit {
  if output is Shared(output) {
    output.close()
  }
}

///|
priv enum RunningSubCommand {
  SingleProc(
    @event_loop.Process,
    program~ : String,
    args~ : ReadOnlyArray[String],
    accepted_exit_code~ : (Int32) -> Bool
  )
  Nested(
    @coroutine.Coroutine,
    exit_status~ : @ref.Ref[Result[Int32, CommandFailed]]
  )
}

///|
#warnings("-result_error_return")
async fn RunningSubCommand::wait_propagate_cancel(
  cmd : RunningSubCommand,
  cancel_now~ : Bool,
  cancel_handler~ : CancellationHandler,
  context~ : String,
) -> Result[Int32, CommandFailed] {
  match cmd {
    SingleProc(proc, program~, args~, accepted_exit_code~) => {
      defer proc.close()
      let wait_status = if cancel_now {
        None
      } else {
        @async.handle_cancellation(() => proc.wait_pid(context~))
      }
      let result = match wait_status {
        None => {
          let mut result = 0
          @async.protect_from_cancel() <| () => {
            @async.with_task_group() <| group => {
              group.spawn_bg(no_wait=true, () => cancel_handler(proc.pid))
              result = proc.wait_pid(context~)
            }
          }
          result
        }
        Some(result) => result
      }
      if accepted_exit_code(result) {
        Ok(result)
      } else {
        Err(CommandFailed(result, program~, args~))
      }
    }
    Nested(coro, exit_status~) => {
      let wait_status = if cancel_now {
        None
      } else {
        @async.handle_cancellation(() => coro.wait())
      }
      match wait_status {
        None => {
          coro.cancel()
          @async.protect_from_cancel(() => ignore(coro.wait()))
        }
        Some(_) => ()
      }
      exit_status.val
    }
  }
}

///|
priv struct RunningCommand(Array[RunningSubCommand])

///|
#warnings("-result_error_return")
async fn RunningCommand::wait_propagate_cancel(
  instance : RunningCommand,
  cancel_now~ : Bool,
  cancel_handler~ : CancellationHandler,
  context~ : String,
) -> Result[Int32, CommandFailed] {
  let mut current_result_index = -1
  let mut current_result = Ok(0)
  let _ = @async.handle_cancellation <| () => {
    @async.with_task_group <| group => {
      for i, cmd in instance.0 {
        group.spawn_bg() <| () => {
          let result = cmd.wait_propagate_cancel(
            cancel_now~,
            cancel_handler~,
            context~,
          )
          match (current_result, result) {
            (Err(_), Ok(_)) => ()
            (Ok(_), Ok(_)) | (Err(_), Err(_)) if i < current_result_index => ()
            _ => {
              current_result_index = i
              current_result = result
            }
          }
        }
      }
    }
  }
  current_result
}

///|
async fn Cmd::spawn_single(
  cmd : Cmd,
  stdin~ : ProcessInput,
  stdout~ : ProcessOutput,
  stderr~ : ProcessOutput,
  cwd~ : StringView?,
  context~ : String,
) -> @event_loop.Process {
  guard! cmd
    is Single(
      program,
      args,
      extra_env~,
      inherit_env~,
      stdin=self_stdin,
      stdout=self_stdout,
      stderr=self_stderr,
      cwd=self_cwd,
      no_console_window~,
      accepted_exit_code=_
    )
  let cwd = if self_cwd is None { cwd } else { self_cwd }
  let (proc, _, _, _) = {
    defer stdin.close_if_shared()
    defer stdout.close_if_shared()
    defer stderr.close_if_shared()
    let stdin = if self_stdin is Inherit { stdin } else { self_stdin }
    let stdout = if self_stdout is Inherit { stdout } else { self_stdout }
    let stderr = if self_stderr is Inherit { stderr } else { self_stderr }
    raw_spawn(
      program,
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
  }
  proc
}

///|
async fn Cmd::update_context(
  cmd : Cmd,
  stdin~ : ProcessInput,
  stdout~ : ProcessOutput,
  stderr~ : ProcessOutput,
  cwd~ : StringView?,
) -> (ProcessInput, ProcessOutput, ProcessOutput, StringView?) {
  guard! cmd
    is WithContext(
      _,
      stdin=local_stdin,
      stdout=local_stdout,
      stderr=local_stderr,
      cwd=local_cwd
    )
  let mut stdin = stdin
  let mut stdout = stdout
  let mut stderr = stderr
  errdefer stdin.close_if_shared()
  errdefer stdout.close_if_shared()
  errdefer stderr.close_if_shared()
  if !(local_stdin is Inherit) {
    let new_stdin = local_stdin.to_shared().0
    stdin.close_if_shared()
    stdin = new_stdin
  }
  if !(local_stdout is Inherit) {
    let new_stdout = local_stdout.to_shared().1
    stdout.close_if_shared()
    stdout = new_stdout
  }
  if !(local_stderr is Inherit) {
    let new_stderr = local_stderr.to_shared().1
    stderr.close_if_shared()
    stderr = new_stderr
  }
  let cwd = if local_cwd is None { cwd } else { local_cwd }
  (stdin, stdout, stderr, cwd)
}

///|
#warnings("-result_error_return")
async fn Cmd::run_aux(
  cmd : Cmd,
  result : @ref.Ref[Result[Int32, CommandFailed]],
  stdin~ : ProcessInput,
  stdout~ : ProcessOutput,
  stderr~ : ProcessOutput,
  cwd~ : StringView?,
  cancel_handler~ : CancellationHandler,
  context~ : String,
) -> Unit {
  match cmd {
    Single(_) | Pipe(_) => {
      let instance = RunningCommand([])
      errdefer {
        // Cancel all other commands if some command in a pipe failed.
        //
        // `wait_propagate_cancel` will handle cancellation correctly itself.
        // it is still cancellable, though, intentionally
        result.val = instance.wait_propagate_cancel(
          cancel_now=true,
          cancel_handler~,
          context~,
        )
      }
      cmd.spawn_aux(
        instance,
        stdin~,
        stdout~,
        stderr~,
        cwd~,
        context~,
        cancel_handler~,
      )
      result.val = instance.wait_propagate_cancel(
        cancel_now=false,
        cancel_handler~,
        context~,
      )
    }
    WithContext(inner, ..) => {
      let (stdin, stdout, stderr, cwd) = cmd.update_context(
        stdin~,
        stdout~,
        stderr~,
        cwd~,
      )
      inner.run_aux(
        result,
        stdin~,
        stdout~,
        stderr~,
        cwd~,
        cancel_handler~,
        context~,
      )
    }
    Sequence([] | [_]) => panic()
    Sequence([.. cmds, last]) => {
      {
        errdefer {
          stdin.close_if_shared()
          stdout.close_if_shared()
          stderr.close_if_shared()
        }
        for cmd in cmds {
          stdin.incref()
          stdout.incref()
          stderr.incref()
          cmd.run_aux(
            result,
            stdin~,
            stdout~,
            stderr~,
            cwd~,
            cancel_handler~,
            context~,
          )
          if result.val is Err(_) {
            break
          }
        }
      }
      if result.val is Ok(_) {
        last.run_aux(
          result,
          stdin~,
          stdout~,
          stderr~,
          cwd~,
          cancel_handler~,
          context~,
        )
      } else {
        stdin.close_if_shared()
        stdout.close_if_shared()
        stderr.close_if_shared()
      }
    }
  }
}

///|
async fn Cmd::spawn_aux(
  cmd : Cmd,
  instance : RunningCommand,
  stdin~ : ProcessInput,
  stdout~ : ProcessOutput,
  stderr~ : ProcessOutput,
  cwd~ : StringView?,
  cancel_handler~ : CancellationHandler,
  context~ : String,
) -> Unit {
  match cmd {
    Single(program, args, accepted_exit_code~, ..) => {
      let proc = cmd.spawn_single(stdin~, stdout~, stderr~, cwd~, context~)
      instance.0.push(SingleProc(proc, program~, args~, accepted_exit_code~))
    }
    WithContext(inner, ..) => {
      let (stdin, stdout, stderr, cwd) = cmd.update_context(
        stdin~,
        stdout~,
        stderr~,
        cwd~,
      )
      inner.spawn_aux(
        instance,
        stdin~,
        stdout~,
        stderr~,
        cwd~,
        context~,
        cancel_handler~,
      )
    }
    Pipe(cmd1, cmd2) => {
      let mut stdin_consumed = false
      let mut stdout_consumed = false
      let mut stderr_consumed = false
      errdefer (if !stdin_consumed { stdin.close_if_shared() })
      errdefer (if !stdout_consumed { stdout.close_if_shared() })
      errdefer (if !stderr_consumed { stderr.close_if_shared() })
      let (r, w) = pipe()
      {
        errdefer r.close()
        stderr.incref()
        stdin_consumed = true
        cmd1.spawn_aux(
          instance,
          stdin~,
          stdout=Shared(w),
          stderr~,
          cwd~,
          cancel_handler~,
          context~,
        )
      }
      stdout_consumed = true
      stderr_consumed = true
      cmd2.spawn_aux(
        instance,
        stdin=Shared(r),
        stdout~,
        stderr~,
        cwd~,
        cancel_handler~,
        context~,
      )
    }
    Sequence(_) => {
      let exit_status = @ref.Ref(Ok(0))
      let coro = @coroutine.spawn() <| () => {
        cmd.run_aux(
          exit_status,
          stdin~,
          stdout~,
          stderr~,
          cwd~,
          cancel_handler~,
          context~,
        )
      }
      instance.0.push(Nested(coro, exit_status~))
    }
  }
}

///|
/// Run a command and wait for its completion, similar to `@process.run`.
///
/// `ProcessResult::exit_code` is the command's successful status: the process
/// status for a single command, the right-hand command's status for a
/// pipeline, or the final command's status for a sequence. A pipeline instead
/// raises the rightmost rejected exit according to shell `pipefail`. These
/// rules apply recursively to nested composites. `Cmd::run` does not expose a
/// process PID; use `Cmd::spawn` when one is needed.
///
/// An error from any nested command propagates from `run`. A pipeline waits for
/// all of its commands and selects the rightmost rejected exit; in a sequence,
/// an error prevents later commands from starting. If building a pipeline's
/// frontier fails, frontier members that have already started are cancelled
/// and awaited before the startup error is propagated.
///
/// `stdin`, `stdout` and `stderr` can be used to redirect a specific channel of the command.
/// Redirection here takes effect only when the command itself does not redirect the corresponding channel
/// (i.e. the corresponding channel is set to `Inherit`).
///
/// `cwd` can be used to override working directory of the command.
/// Notice that if some sub-command may have their own working directory setting,
/// in this case the sub-command's more specific setting will NOT get overridden.
///
/// If the task running `Cmd::run` is cancelled, all running child processes
/// are stopped via `cancel_handler`.
/// The default value of `cancel_handler` is `graceful_cancel(timeout=5000)`
/// (First try to gracefully terminate the process,
/// and if the process is still running after five seconds, terminate it forcefully).
/// Note that the task group will not exit until the child process actually terminates
/// (i.e. after the child process completes its cleanup process).
/// So the child process will never leak outside its task group.
///
/// If `cancel_handler` is still running after the process terminates,
/// it will be cancelled.
pub async fn Cmd::run(
  cmd : Cmd,
  stdin~ : ProcessInput = Inherit,
  stdout~ : ProcessOutput = Inherit,
  stderr~ : ProcessOutput = Inherit,
  cwd? : StringView,
  cancel_handler~ : CancellationHandler = graceful_cancel(timeout=5000),
) -> ProcessResult {
  let result = @ref.Ref(Ok(0))
  let mut stdout_result = None
  let mut stderr_result = None
  @async.with_task_group <| group => {
    let (stdin, stdout, stderr) = {
      let (stdout_parent, stdout_child) = stdout.to_shared()
      errdefer stdout_child.close_if_shared()
      group.spawn_bg() <| () => {
        defer stdout_parent.close()
        if stdout_parent.io is Some(_) {
          stdout_result = Some(stdout_parent.read_all())
        }
      }

      let (stderr_parent, stderr_child) = stderr.to_shared()
      errdefer stderr_child.close_if_shared()
      group.spawn_bg() <| () => {
        defer stderr_parent.close()
        if stderr_parent.io is Some(_) {
          stderr_result = Some(stderr_parent.read_all())
        }
      }

      let (stdin_child, stdin_parent) = stdin.to_shared()
      // Like `@process.run`, there is no caller-visible writer, so close it
      // before starting the command. For `FeedFromParent`, this sends EOF.
      stdin_parent.close()
      (stdin_child, stdout_child, stderr_child)
    }

    cmd.run_aux(
      result,
      stdin~,
      stdout~,
      stderr~,
      cwd~,
      cancel_handler~,
      context="@process.Cmd::run()",
    )
  }
  if result.val is Err(err) && !@coroutine.is_being_cancelled() {
    raise err
  }
  let exit_code = result.val.unwrap_or_error()
  { exit_code, stdout: stdout_result, stderr: stderr_result, }
}

///|
/// Spawn a command inside the task group `group`.
///
/// The returned `Process` represents the whole command.
/// Its `pid` is the process's PID for a single command,
/// the right-hand command's selected PID for a pipeline,
/// or `0` for a multi-command sequence.
///
/// For a pipeline, `spawn` returns after all its components has started.
/// Failure in spawning sub-commands in a pipe is considered fatal,
/// `spawn` will fail in this case, and already spawned sub commands will be cancelled.
/// For a sequence, `spawn` will return immediately without
/// waiting for the first child process in the sequence.
///
/// `stdin`, `stdout` and `stderr` can be used to redirect a specific channel of the command.
/// Redirection here takes effect only when the command itself does not redirect the corresponding channel
/// (i.e. the corresponding channel is set to `Inherit`).
///
/// `cwd` can be used to override working directory of the command.
/// Notice that if some sub-command may have their own working directory setting,
/// in this case the sub-command's more specific setting will NOT get overridden.
///
/// If `no_wait` is `false` (`false` by default),
/// the task group will wait for termination of the child process before returning normally.
/// When the task group is about to exit, for example due to fatal error or external cancellation,
/// the child process will be terminated automatically via `cancel_handler`.
///
/// The child process can be cancelled manually via `.cancel()` on the returned `Process` object.
/// The child may also get cancelled automatically by the task group.
/// When the child process is cancelled, `cancel_handler` will be used to
/// automatically stop all children process in the command.
/// The default value of `cancel_handler` is `graceful_cancel(timeout=5000)`
/// (First try to gracefully terminate the process,
/// and if the process is still running after five seconds, terminate it forcefully).
/// Note that the task group will not exit until the child process actually terminates
/// (i.e. after the child process completes its cleanup process).
/// So the child process will never leak outside its task group.
///
/// If `cancel_handler` is still running after the process terminates,
/// it will be cancelled.
pub async fn Cmd::spawn(
  cmd : Cmd,
  group : @async.TaskGroup,
  no_wait~ : Bool = false,
  stdin~ : ProcessInput = Inherit,
  stdout~ : ProcessOutput = Inherit,
  stderr~ : ProcessOutput = Inherit,
  cwd? : StringView,
  cancel_handler~ : CancellationHandler = graceful_cancel(timeout=5000),
) -> Process {
  let context = "@process.Cmd::spawn()"
  let (stdin_child, stdin_parent) = stdin.to_shared()
  defer stdin_child.close_if_shared()
  errdefer stdin_parent.close()

  let (stdout_parent, stdout_child) = stdout.to_shared()
  defer stdout_child.close_if_shared()
  errdefer stdout_parent.close()

  let (stderr_parent, stderr_child) = stderr.to_shared()
  defer stderr_child.close_if_shared()
  errdefer stderr_parent.close()

  stdin_child.incref()
  stdout_child.incref()
  stderr_child.incref()
  let instance = RunningCommand([])
  errdefer ignore(
    instance.wait_propagate_cancel(cancel_now=true, cancel_handler~, context~),
  )
  cmd.spawn_aux(
    instance,
    stdin=stdin_child,
    stdout=stdout_child,
    stderr=stderr_child,
    cwd~,
    cancel_handler~,
    context~,
  )
  let result = group.spawn(no_wait~) <| () => {
    let result = instance.wait_propagate_cancel(
      cancel_now=false,
      cancel_handler~,
      context~,
    )
    if result is Err(err) && !@coroutine.is_being_cancelled() {
      raise err
    }
    result
  }
  let pid = match instance.0 {
    [] => 0
    [.., SingleProc(proc, ..)] => proc.pid
    [.., Nested(_)] => 0
  }
  {
    pid,
    result,
    stdin: stdin_parent,
    stdout: stdout_parent,
    stderr: stderr_parent,
  }
}
