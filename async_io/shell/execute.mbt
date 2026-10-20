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
/// Default aggregate limit for captured stdout and stderr: 8 MiB.
let default_max_output_bytes : Int32 = 8 * 1024 * 1024

///|
/// What the caller wants done with the streams a stage marks `Capture`.
priv enum Sink {
  /// Collect into `Output`, bounded by the given aggregate byte limit.
  Buffer(Int32)
  /// Deliver final stdout one line at a time, holding at most one line of the
  /// given size.
  Lines(async (String) -> Unit, Int32)
  /// Capture nothing; a `Capture` stream falls back to the parent's
  /// descriptor, as `status` and `run` have no channel to return it on.
  Inherited
}

///|
/// Execute this command and capture stdout and stderr.
///
/// Constructing a `Cmd` does not execute it. Captured stdout and stderr share
/// `max_output_bytes`; streams sent elsewhere by `stdout` or `stderr` do not
/// count against it and arrive empty in `Output`. When `timeout_ms` expires,
/// each direct child is killed immediately; descendants require enforcement by
/// the host's native process sandbox.
///
/// # Example
/// ```mbt check
/// async test {
///   let output = @shell.Cmd("moonx", ["bobzhang/printf@0.1.0", "hello"]).output()
///   assert_eq(output.stdout(), "hello")
/// }
/// ```
pub async fn Cmd::output(
  self : Cmd,
  timeout_ms? : Int32,
  max_output_bytes~ : Int32 = default_max_output_bytes,
) -> Output {
  validate_output_limit(max_output_bytes)
  Pipeline::{ commands: [self], }.execute(Buffer(max_output_bytes), timeout_ms)
}

///|
/// Execute this command without capturing stdout or stderr.
///
/// Streams left as `Capture` are inherited by the current process, because
/// `status` has no channel to return them on; explicit `ToFile`,
/// `AppendToFile`, and `Inherit` settings still apply. This method returns
/// only the exit status and has no capture limit.
///
/// # Example
/// ```mbt check
/// async test {
///   assert_eq(@shell.Cmd("moonx", ["bobzhang/false@0.1.0"]).status(), 1)
/// }
/// ```
pub async fn Cmd::status(self : Cmd, timeout_ms? : Int32) -> Int32 {
  Pipeline::{ commands: [self], }.execute(Inherited, timeout_ms).exit_code
}

///|
/// Execute this command and raise on a non-zero exit status.
///
/// This is the checked form of `status` and the common verb of a script:
/// streams are inherited exactly as there, and a failure becomes an error
/// instead of a status the caller might forget to look at. Use `status` when
/// a non-zero exit is an answer rather than a failure.
///
/// # Example
/// ```mbt check
/// async test {
///   @shell.Cmd("moonx", ["bobzhang/true@0.1.0"]).run()
///   try @shell.Cmd("moonx", ["bobzhang/false@0.1.0"]).run() catch {
///     _ => ()
///   } noraise {
///     _ => fail("expected a non-zero exit to raise")
///   }
/// }
/// ```
pub async fn Cmd::run(self : Cmd, timeout_ms? : Int32) -> Unit {
  Pipeline::{ commands: [self], }.execute(Inherited, timeout_ms).check()
}

///|
/// Execute this command, delivering standard output one line at a time.
///
/// `on_line` receives each line without its terminator — `\n` or `\r\n` — as
/// soon as the child flushes it, so a long-running command can report progress
/// instead of arriving as one block at the end. A trailing fragment with no
/// newline is delivered as a final line. Standard error follows the same rule
/// as in `status`.
///
/// Completed lines are not retained, so total output is unbounded. One line is
/// held while it is assembled, and `max_line_bytes` caps its content exactly:
/// any single line longer than that raises, whether or not a newline ever
/// arrives, so a child that emits no newline cannot exhaust memory. A CRLF
/// terminator's CR is punctuation rather than content and does not consume the
/// allowance.
///
/// Raises when `stdout` sends the stream elsewhere, since there would be
/// nothing to read.
///
/// # Example
/// ```mbt check
/// async test {
///   let seen = []
///   let code = @shell.Cmd("moonx", ["bobzhang/printf@0.1.0", "a\nb\n"]).each_line(line => {
///       seen.push(line)
///     },
///   )
///   assert_eq(code, 0)
///   assert_eq(seen, ["a", "b"])
/// }
/// ```
pub async fn Cmd::each_line(
  self : Cmd,
  on_line : async (String) -> Unit,
  timeout_ms? : Int32,
  max_line_bytes~ : Int32 = default_max_output_bytes,
) -> Int32 {
  validate_output_limit(max_line_bytes)
  Pipeline::{ commands: [self], }.execute(
    Lines(on_line, max_line_bytes),
    timeout_ms,
  ).exit_code
}

///|
/// Execute this pipeline and capture final stdout plus every stage's stderr.
///
/// Stages run concurrently in one structured task group. `timeout_ms`, when
/// present, applies to the whole pipeline.
///
/// # Example
/// ```mbt check
/// async test {
///   let output = @shell.Pipeline([
///     Cmd("moonx", ["bobzhang/printf@0.1.0", "alpha\nbeta\n"]),
///     Cmd("moonx", ["bobzhang/tail@0.1.0", "-n", "1"]),
///   ]).output()
///   assert_eq(output.stdout(), "beta\n")
/// }
/// ```
pub async fn Pipeline::output(
  self : Pipeline,
  timeout_ms? : Int32,
  max_output_bytes~ : Int32 = default_max_output_bytes,
) -> Output {
  validate_output_limit(max_output_bytes)
  self.execute(Buffer(max_output_bytes), timeout_ms)
}

///|
/// Execute this pipeline without capturing stdout or stderr.
///
/// The last stage's streams left as `Capture` are inherited by the current
/// process, exactly as in `Cmd::status`; the earlier stages' stdout is the
/// connecting pipe regardless. The returned status uses the same pipefail
/// rule as `output`, and there is no capture limit.
pub async fn Pipeline::status(self : Pipeline, timeout_ms? : Int32) -> Int32 {
  self.execute(Inherited, timeout_ms).exit_code
}

///|
/// Execute this pipeline and raise when any stage fails.
///
/// The checked form of `Pipeline::status`: streams are inherited the same
/// way, and the pipefail status becomes an error when it is non-zero.
pub async fn Pipeline::run(self : Pipeline, timeout_ms? : Int32) -> Unit {
  self.execute(Inherited, timeout_ms).check()
}

///|
/// Execute this pipeline, delivering the last stage's output one line at a
/// time.
///
/// The returned status uses the same pipefail rule as `output`. See
/// `Cmd::each_line` for how lines are delivered and bounded.
///
/// # Example
/// ```mbt check
/// async test {
///   let seen = []
///   @shell.Pipeline([
///     Cmd("moonx", ["bobzhang/printf@0.1.0", "alpha\nbeta\n"]),
///     Cmd("moonx", ["bobzhang/tail@0.1.0", "-n", "1"]),
///   ]).each_line(line => seen.push(line))
///   |> ignore
///   assert_eq(seen, ["beta"])
/// }
/// ```
pub async fn Pipeline::each_line(
  self : Pipeline,
  on_line : async (String) -> Unit,
  timeout_ms? : Int32,
  max_line_bytes~ : Int32 = default_max_output_bytes,
) -> Int32 {
  validate_output_limit(max_line_bytes)
  self.execute(Lines(on_line, max_line_bytes), timeout_ms).exit_code
}

///|
/// Validate the whole plan, then run it under an optional deadline.
async fn Pipeline::execute(
  self : Pipeline,
  sink : Sink,
  timeout_ms : Int32?,
) -> Output {
  let count = self.commands.length()
  if count == 0 {
    raise ShellError::EmptyPipeline
  }
  for index, cmd in self.commands {
    validate_cmd(cmd)
    if index > 0 && cmd.stdin is Some(_) {
      raise StdinOnNonFirstStage(index)
    }
    if index + 1 < count && !(cmd.stdout is Capture) {
      raise RedirectOnNonFinalStage(index)
    }
  }
  if sink is Lines(_, _) && !(self.commands[count - 1].stdout is Capture) {
    raise StdoutNotCaptured
  }
  match timeout_ms {
    None => run_pipeline(self, sink)
    Some(milliseconds) =>
      @async_io.with_timeout(milliseconds, () => run_pipeline(self, sink))
  }
}

///|
fn validate_cmd(cmd : Cmd) -> Unit raise ShellError {
  if cmd.program.is_empty() {
    raise EmptyProgram
  }
  if cmd.program.contains("\u{0000}") {
    raise NulByte("program")
  }
  for index, argument in cmd.arguments {
    if argument.contains("\u{0000}") {
      raise NulByte("argument[\{index}]")
    }
  }
  if cmd.cwd is Some(directory) && directory.contains("\u{0000}") {
    raise NulByte("working directory")
  }
  if cmd.stdin is Some(FromFile(path)) && path.contains("\u{0000}") {
    raise NulByte("standard input path")
  }
  validate_redirect(cmd.stdout, "standard output path")
  validate_redirect(cmd.stderr, "standard error path")
  for name, value in cmd.env {
    if name.contains("\u{0000}") {
      raise NulByte("environment name")
    }
    if name.is_empty() || name.contains("=") {
      raise InvalidEnvironmentName(name)
    }
    if value.contains("\u{0000}") {
      raise NulByte("environment value for \{name}")
    }
  }
}

///|
fn validate_redirect(
  redirect : Redirect,
  location : String,
) -> Unit raise ShellError {
  if redirect is (ToFile(path) | AppendToFile(path)) &&
    path.contains("\u{0000}") {
    raise NulByte(location)
  }
}

///|
fn validate_output_limit(limit : Int32) -> Unit raise ShellError {
  if limit <= 0 {
    raise InvalidOutputLimit(limit)
  }
}

///|
/// Turn a `Redirect` into the descriptor a child should receive.
///
/// `None` means the child inherits the parent's descriptor. `capture` is the
/// descriptor this run reads from, and is absent when the caller keeps nothing.
///
/// File redirections are lazy single-child descriptors: the file is opened by
/// `spawn`, which also owns cleanup if process creation fails.
fn resolve_redirect(
  redirect : Redirect,
  capture : &@process.ProcessOutput?,
) -> &@process.ProcessOutput? {
  match redirect {
    Capture => capture
    Inherit => None
    ToFile(path) =>
      Some(@process.redirect_to_file(path, create_mode=CreateOrTruncate))
    AppendToFile(path) =>
      Some(
        @process.redirect_to_file(path, append=true, create_mode=OpenOrCreate),
      )
    Discard =>
      Some(@process.redirect_to_file(null_device, create_mode=OpenExisting))
  }
}

///|
/// The platform's always-existing sink for unwanted output.
let null_device : String = if @env_util.platform is Windows {
  "NUL"
} else {
  "/dev/null"
}

///|
async fn spawn_stage(
  group : @async_io.TaskGroup,
  cmd : Cmd,
  stdin : &@process.ProcessInput,
  stdout : &@process.ProcessOutput?,
  stderr : &@process.ProcessOutput?,
) -> @process.Process {
  @process.spawn(
    group,
    cmd.program,
    cmd.arguments,
    extra_env=cmd.env,
    inherit_env=cmd.inherit_env,
    stdin~,
    stdout?,
    stderr?,
    cwd?=cmd.cwd.map(directory => directory),
    // Cancellation — a timeout, a capture limit, a failing sibling — kills the
    // child immediately: a sandboxed runtime never waits on an untrusted
    // process.
    cancel_handler=@process.hard_cancel(),
  )
}

///|
async fn write_standard_input(
  writer : @process.WriteToProcess,
  input : Stdin?,
) -> Unit {
  defer writer.close()
  match input {
    Some(Text(text)) => writer.text.write(text)
    Some(Binary(bytes)) => writer.write(bytes)
    // `FromFile` and `Inherit` never reach here: those descriptors are handed
    // to the child directly.
    Some(FromFile(_) | Inherit) | None => ()
  }
}

///|
fn pipefail_exit_code(exit_codes : ArrayView[Int32]) -> Int32 {
  let mut result = 0
  for code in exit_codes {
    if code != 0 {
      result = code
    }
  }
  result
}

///|
async fn read_bounded(
  reader : @process.ReadFromProcess,
  captured : @ref.Ref[Int32],
  limit : Int32,
  stream : String,
) -> Bytes {
  let buffer = @buffer.Buffer(size_hint=4096)
  for ;; {
    match reader.read() {
      None => break
      Some(chunk) => {
        let next_total = captured.val + chunk.length()
        if next_total > limit {
          raise OutputLimitExceeded(stream~, limit~)
        }
        captured.val = next_total
        buffer.write_bytes(chunk)
      }
    }
  }
  buffer.to_bytes()
}

///|
/// Deliver every line the child writes, including a final unterminated one.
///
/// This splits binary `read` chunks itself rather than using `read_until`, so
/// the line-length limit can be enforced incrementally without first buffering
/// an unbounded line. Decoding here is lossy and per line, matching how
/// `Output` treats captured text.
///
/// Only one line is held at a time, and `limit` caps that line's content
/// exactly, so a child that never emits a newline cannot grow it without
/// bound. A CRLF terminator's CR is punctuation, not content, and so does not
/// consume the line's allowance.
async fn read_lines(
  reader : @process.ReadFromProcess,
  on_line : async (String) -> Unit,
  limit : Int32,
) -> Unit {
  let pending = @buffer.Buffer(size_hint=4096)
  while reader.read() is Some(chunk) {
    let mut start = 0
    for index in 0..<chunk.length() {
      if chunk[index] == b'\n' {
        extend_line(pending, chunk[start:index], limit)
        on_line(take_line(pending, terminated=true, limit))
        start = index + 1
      }
    }
    extend_line(pending, chunk[start:], limit)
  }
  if pending.length() > 0 {
    on_line(take_line(pending, terminated=false, limit))
  }
}

///|
/// Append to the line being assembled, refusing to buffer more than one line.
///
/// `limit` counts line content, and the CR of a CRLF terminator is not content.
/// Whether a trailing CR is a terminator is only known once the LF arrives, so
/// one byte of headroom is allowed here and `take_line` makes the final ruling.
fn extend_line(
  pending : @buffer.Buffer,
  view : BytesView,
  limit : Int32,
) -> Unit raise ShellError {
  let projected = pending.length() + view.length()
  // Written this way rather than `projected > limit + 1` so that a caller
  // passing a limit near `Int`'s maximum cannot overflow the comparison.
  if projected > limit && projected - limit > 1 {
    raise OutputLimitExceeded(stream="stdout line", limit~)
  }
  pending.write_bytesview(view)
}

///|
/// Take the assembled line and reset the buffer.
///
/// The CR of a CRLF terminator is dropped, but only for a line that a newline
/// actually terminated: a lone trailing CR in the final unterminated fragment
/// is data, not punctuation. What remains is the line content, so this is where
/// `limit` is decided.
fn take_line(
  pending : @buffer.Buffer,
  terminated~ : Bool,
  limit : Int32,
) -> String raise ShellError {
  let raw = pending.to_bytes()
  pending.reset()
  let length = raw.length()
  let bytes = if terminated && length > 0 && raw[length - 1] == b'\r' {
    raw[:length - 1].to_owned()
  } else {
    raw
  }
  if bytes.length() > limit {
    raise OutputLimitExceeded(stream="stdout line", limit~)
  }
  @utf8.decode_lossy(bytes)
}

///|
async fn run_pipeline(pipeline : Pipeline, sink : Sink) -> Output {
  let commands = pipeline.commands
  let count = commands.length()
  //
  // Each adjacent pair of stages shares one process-owned operating-system
  // pipe. Both ends are blocking in the children, so payload bytes stay in the
  // host pipe rather than crossing this process through a relay task.
  //
  // Everything the parent itself reads or writes uses the process-owned pipes.
  // `@pipe.pipe()` makes both ends non-blocking, and that flag survives into
  // the child, so a child that outran us would get `EAGAIN` on its own write
  // instead of blocking. The process redirections keep the child's end
  // blocking, which is the whole point of using them here.
  //
  // The parent owns both ends returned by `@process.pipe()`. Each end is closed
  // immediately after the only child that needs it has spawned. The error
  // cleanup below covers junctions whose child has not spawned yet.
  let collect_stderr = sink is Buffer(_)
  let mut result = None
  @async_io.with_task_group() <| group => {
    let captured = @ref.Ref(0)
    let limit = match sink {
      Buffer(limit) => limit
      _ => 0
    }
    let mut stdout_task : @async_io.Task[Bytes]? = None
    let stderr_tasks : Array[@async_io.Task[Bytes]?] = []
    //
    // Inter-stage pipes are shared descriptors: unlike the lazy single-child
    // redirections, `spawn` never closes the parent's copies. Build all
    // junctions under error cleanup, then close each end as soon as its one
    // consumer has spawned.
    let junction_inputs : Array[@process.SharedProcessInput] = []
    let junction_outputs : Array[@process.SharedProcessOutput] = []
    errdefer {
      for input in junction_inputs {
        input.close()
      }
      for output in junction_outputs {
        output.close()
      }
    }
    for _ in 1..<count {
      let (input, output) = @process.pipe()
      junction_inputs.push(input)
      junction_outputs.push(output)
    }
    //
    // Standard input for the first stage: a file the child reads itself, the
    // parent's own descriptor, or a lazy single-child pipe this task fills
    // through the `Process` returned by `spawn`.
    let first_stdin = commands[0].stdin
    let writes_first_input = match first_stdin {
      Some(FromFile(_) | Inherit) => false
      Some(Text(_) | Binary(_)) | None => true
    }
    let first_input : &@process.ProcessInput = match first_stdin {
      Some(FromFile(path)) => @process.redirect_from_file(path)
      Some(Inherit) => @stdio.stdin
      Some(Text(_) | Binary(_)) | None => @process.write_to_process()
    }
    let processes : Array[@process.Process] = []
    for index, cmd in commands {
      let stdin : &@process.ProcessInput = if index == 0 {
        first_input
      } else {
        junction_inputs[index - 1]
      }
      //
      // A downstream stage that stops reading early closes the pipe in the
      // ordinary operating-system way, and the producer observes the resulting
      // broken pipe.
      let captures_stdout = index + 1 == count &&
        !(sink is Inherited) &&
        cmd.stdout is Capture
      let stdout : &@process.ProcessOutput? = if index + 1 < count {
        Some(junction_outputs[index])
      } else {
        let final_capture : &@process.ProcessOutput? = if captures_stdout {
          Some(@process.read_from_process())
        } else {
          None
        }
        resolve_redirect(cmd.stdout, final_capture)
      }
      //
      let captures_stderr = collect_stderr && cmd.stderr is Capture
      let stderr_capture : &@process.ProcessOutput? = if captures_stderr {
        Some(@process.read_from_process())
      } else {
        None
      }
      let stderr = resolve_redirect(cmd.stderr, stderr_capture)
      let child = spawn_stage(group, cmd, stdin, stdout, stderr)
      // Shared junction ends remain owned by this process after `spawn`.
      if index > 0 {
        junction_inputs[index - 1].close()
      }
      if index + 1 < count {
        junction_outputs[index].close()
      }
      // The lazy single-child pipes become accessible only after `spawn`.
      // Start their tasks immediately so a full pipe cannot stall a child.
      if index == 0 && writes_first_input {
        group.spawn_bg(allow_failure=true, () => {
          write_standard_input(child.stdin, first_stdin)
        })
      }
      if captures_stdout {
        match sink {
          Buffer(_) =>
            stdout_task = Some(
              group.spawn(() => {
                defer child.stdout.close()
                read_bounded(child.stdout, captured, limit, "stdout")
              }),
            )
          Lines(on_line, line_limit) =>
            group.spawn_bg(() => {
              defer child.stdout.close()
              read_lines(child.stdout, on_line, line_limit)
            })
          Inherited => ()
        }
      }
      if captures_stderr {
        stderr_tasks.push(
          Some(
            group.spawn(() => {
              defer child.stderr.close()
              read_bounded(child.stderr, captured, limit, "stderr")
            }),
          ),
        )
      } else {
        stderr_tasks.push(None)
      }
      processes.push(child)
    }
    let exit_codes = [ for child in processes => child.wait() ]
    let stdout_bytes = match stdout_task {
      Some(task) => task.wait()
      None => b""
    }
    let stderr = StringBuilder()
    for task in stderr_tasks {
      let stage_bytes = match task {
        Some(task) => task.wait()
        None => b""
      }
      stderr.write_string(@utf8.decode_lossy(stage_bytes))
    }
    result = Some({
      exit_code: pipefail_exit_code(exit_codes),
      stdout: @utf8.decode_lossy(stdout_bytes),
      stdout_bytes,
      stderr: stderr.to_string(),
    })
  }
  result.unwrap()
}
