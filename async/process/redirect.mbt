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
/// A pipe for reading the output of child process.
/// Must be closed when it is no longer used.
pub struct ReadFromProcess {
  text : @io.Utf8Reader
  priv io : @event_loop.IoHandle?
  priv ctrl : @io.BinaryReaderController
}

///|
fn ReadFromProcess::ReadFromProcess(
  io : @event_loop.IoHandle?,
) -> ReadFromProcess {
  let output : ReadFromProcess = {
    text: @io.Utf8Reader::new_uninitialized(),
    io,
    ctrl: BinaryReaderController(),
  }
  if io is Some(_) {
    output.text.set_inner(output)
  }
  output
}

///|
let no_output : ReadFromProcess = ReadFromProcess(None)

///|
/// Close a process output reading pipe, release associated resource
pub fn ReadFromProcess::close(self : ReadFromProcess) -> Unit {
  self.text.close()
  if self.io is Some(io) {
    io.close()
  }
}

///|
pub impl @io.BinaryReader for ReadFromProcess

///|
impl @io.BinaryReaderImpl for ReadFromProcess with fn name(_self) {
  "@process.ReadFromProcess"
}

///|
impl @io.BinaryReaderImpl for ReadFromProcess with fn get_controller(self) {
  self.ctrl
}

///|
impl @io.BinaryReaderImpl for ReadFromProcess with fn raw_read_impl(
  self,
  buf,
  offset~,
  max_len~,
) {
  guard self.io is Some(io) else {
    abort(
      "cannot read output of a process whose stdout/stderr is not redirected with `Collect`",
    )
  }
  io.read(
    buf,
    offset~,
    len=max_len,
    context="impl @io.BinaryReader for ReadFromProcess",
  )
}

///|
pub extend ReadFromProcess with @io.BinaryReader::{
  read_into,
  read,
  read_at_least,
  peek,
  peek_at_least,
  read_exactly,
  drop_exactly,
  peek_exactly,
  read_all,
  drop_all,
  read_until,
  peek_until,
}

///|
/// A pipe for writing to the input of child process.
/// Must be closed when it is no longer used.
pub struct WriteToProcess {
  text : @io.Utf8Writer
  priv io : @event_loop.IoHandle?
  priv ctrl : @io.BinaryWriterController
}

///|
fn WriteToProcess::WriteToProcess(io : @event_loop.IoHandle?) -> WriteToProcess {
  let output : WriteToProcess = {
    text: @io.Utf8Writer::new_uninitialized(),
    io,
    ctrl: BinaryWriterController(),
  }
  if io is Some(_) {
    output.text.set_inner(output)
  }
  output
}

///|
let no_input : WriteToProcess = WriteToProcess(None)

///|
/// Close a process input writing pipe, release associated resource
pub fn WriteToProcess::close(self : WriteToProcess) -> Unit {
  self.text.close()
  if self.io is Some(io) {
    io.close()
  }
}

///|
pub impl @io.BinaryWriter for WriteToProcess

///|
impl @io.BinaryWriterImpl for WriteToProcess with fn name(_self) {
  "@process.WriteToProcess"
}

///|
impl @io.BinaryWriterImpl for WriteToProcess with fn get_controller(self) {
  self.ctrl
}

///|
impl @io.BinaryWriterImpl for WriteToProcess with fn raw_write_impl(
  self,
  buf,
  offset~,
  len~,
) {
  guard self.io is Some(io) else {
    abort(
      "cannot write input of a process whose stdin is not redirected with `FeedFromParent`",
    )
  }
  io.write(
    buf,
    offset~,
    len~,
    context="impl @io.BinaryWriter for WriteToProcess",
  )
}

///|
impl @io.BinaryWriterImpl for WriteToProcess with fn flush_partial_data(self) {
  ignore(self)
}

///|
pub extend WriteToProcess with @io.BinaryWriter::{write, write_reader}

///|
/// Describes how a child process's standard input should be redirected.
#non_exhaustive
pub(all) enum ProcessInput {
  /// Inherit standard input from the current execution context.
  Inherit
  /// Use the parent process's standard input.
  Stdin
  /// Create a private pipe through which the parent can feed the child's
  /// standard input. With `spawn()` or `spawn_orphan()`, write through the
  /// returned process handle's `.stdin` field and close it to send end-of-file.
  FeedFromParent
  /// Redirect the child's standard input to an empty stream
  Empty
  /// Read the child's standard input from the file at `path`.
  FromFile(StringView)
  /// Read the child's standard input from a caller-owned shared channel.
  ///
  /// Create the channel with `pipe()`, `write_to_process()`, or
  /// `redirect_from_file()`. Close it after it has been passed to the last
  /// child, or if spawning is abandoned.
  Shared(SharedProcessInput)
}

///|
let null_device : String = match @event_loop.platform {
  Linux | MacOS => "/dev/null"
  Windows => "NUL"
  @event_loop.Platform::.. => panic()
}

///|
async fn ProcessInput::init_stdin(
  input : ProcessInput,
  context~ : String,
) -> (@event_loop.IoHandle?, WriteToProcess) {
  match input {
    Inherit | Stdin => (@event_loop.stdin.to_option(), no_input)
    FeedFromParent => {
      let (r, w) = @fd_util.pipe(
        read_end_is_async=false,
        write_end_is_async=true,
        context~,
      )
      let r = @event_loop.IoHandle::from_fd(r, kind=Pipe, is_async=false)
      let w = @event_loop.IoHandle::from_fd(w, kind=Pipe)
      (Some(r), WriteToProcess(Some(w)))
    }
    Empty => {
      let (file, _) = @event_loop.open(
        null_device,
        0, // read only
        create=@fs.OpenExisting.to_int(),
        append=false,
        sync=0,
        mode=0,
        context~,
      )
      (Some(file), no_input)
    }
    FromFile(filename) => {
      let (file, _) = @event_loop.open(
        filename,
        0, // read only
        create=@fs.OpenExisting.to_int(),
        append=false,
        sync=0,
        mode=0,
        context~,
      )
      (Some(file), no_input)
    }
    Shared(obj) => (Some(obj.io), no_input)
  }
}

///|
fn ProcessInput::close(
  self : ProcessInput,
  child_end : @event_loop.IoHandle?,
) -> Unit {
  match self {
    Inherit | Stdin | Shared(_) => ()
    FeedFromParent | Empty | FromFile(_) =>
      if child_end is Some(child_end) {
        child_end.close()
      }
  }
}

///|
/// Describes how a child process's standard output or standard error should be
/// redirected.
#non_exhaustive
pub(all) enum ProcessOutput {
  /// Inherit the corresponding output stream from the current execution
  /// context.
  Inherit
  /// Use the parent process's standard output.
  Stdout
  /// Use the parent process's standard error.
  Stderr
  /// Collect the child's output through a private pipe.
  ///
  /// With `spawn()` or `spawn_orphan()`, read through the returned process
  /// handle's `.stdout` or `.stderr` field. With `run()`, use the corresponding
  /// accessor on `ProcessResult`, such as `stdout_binary()` or `stderr_text()`.
  Collect
  /// Discard all output content written by the child
  Discard
  /// Write the child's output to the file at `path`.
  /// If the file does not exist it will be created, otherwise it will be truncated.
  ToFile(StringView)
  /// Append the child's output to the file at `path`.
  /// If the file does not exist it will be created,
  /// otherwise the child's output will be appended to the end of the file.
  AppendFile(StringView)
  /// Use the child's standard-output destination for its standard error as
  /// well. This variant is only valid for `stderr`.
  DuplicateStdout
  /// Write the child's output to a caller-owned shared channel.
  ///
  /// Create the channel with `pipe()`, `read_from_process()`, or
  /// `redirect_to_file()`. Close it after it has been passed to the last child,
  /// or if spawning is abandoned.
  Shared(SharedProcessOutput)
}

///|
async fn ProcessOutput::init_stdout(
  output : ProcessOutput,
  context~ : String,
) -> (ReadFromProcess, @event_loop.IoHandle?) {
  match output {
    Inherit | Stdout => (no_output, @event_loop.stdout.to_option())
    Stderr => (no_output, @event_loop.stderr.to_option())
    Collect => {
      let (r, w) = @fd_util.pipe(
        read_end_is_async=true,
        write_end_is_async=false,
        context~,
      )
      let r = @event_loop.IoHandle::from_fd(r, kind=Pipe)
      let w = @event_loop.IoHandle::from_fd(w, kind=Pipe, is_async=false)
      (ReadFromProcess(Some(r)), Some(w))
    }
    Discard => {
      let (file, _) = @event_loop.open(
        null_device,
        1, // write only
        create=@fs.OpenExisting.to_int(),
        append=false,
        sync=0,
        mode=0,
        context~,
      )
      (no_output, Some(file))
    }
    ToFile(filename) => {
      let (file, _) = @event_loop.open(
        filename,
        1, // write only
        create=@fs.CreateOrTruncate.to_int(),
        append=false,
        sync=0,
        mode=0o644,
        context~,
      )
      (no_output, Some(file))
    }
    AppendFile(filename) => {
      let (file, _) = @event_loop.open(
        filename,
        1, // write only
        create=@fs.OpenOrCreate.to_int(),
        append=true,
        sync=0,
        mode=0o644,
        context~,
      )
      (no_output, Some(file))
    }
    DuplicateStdout => panic()
    Shared(output) => (no_output, Some(output.io))
  }
}

///|
async fn ProcessOutput::init_stderr(
  output : ProcessOutput,
  stdout~ : @event_loop.IoHandle?,
  context~ : String,
) -> (ReadFromProcess, @event_loop.IoHandle?) {
  match output {
    Inherit => ProcessOutput::init_stdout(Stderr, context~)
    DuplicateStdout => (no_output, stdout)
    Stdout
    | Stderr
    | Collect
    | Discard
    | ToFile(_)
    | AppendFile(_)
    | Shared(_) => output.init_stdout(context~)
  }
}

///|
fn ProcessOutput::close(
  self : ProcessOutput,
  child_end : @event_loop.IoHandle?,
) -> Unit {
  match self {
    Inherit | Stdout | Stderr | Shared(_) | DuplicateStdout => ()
    Collect | Discard | ToFile(_) | AppendFile(_) =>
      if child_end is Some(child_end) {
        child_end.close()
      }
  }
}

///|
/// A caller-owned input endpoint that can be shared by multiple child processes.
/// Pass it as `stdin=Shared(input)`, then close it after it has been passed to
/// the last child, or if spawning is abandoned.
struct SharedProcessInput {
  // The reference counting is mainly for use in `Cmd`'s complex composite commands
  mut rc : Int32
  io : @event_loop.IoHandle
}

///|
fn SharedProcessInput::incref(self : SharedProcessInput) -> Unit {
  self.rc += 1
}

///|
/// Closes a shared process input channel and releases its resources.
pub fn SharedProcessInput::close(self : SharedProcessInput) -> Unit {
  self.rc -= 1
  if self.rc is 0 {
    self.io.close()
  }
}

///|
/// A caller-owned output endpoint that can be shared by multiple child
/// processes. Pass it as `stdout=Shared(output)` or `stderr=Shared(output)`,
/// then close it after it has been passed to the last child, or if spawning is
/// abandoned.
struct SharedProcessOutput {
  // The reference counting is mainly for use in `Cmd`'s complex composite commands
  mut rc : Int32
  io : @event_loop.IoHandle
}

///|
fn SharedProcessOutput::incref(self : SharedProcessOutput) -> Unit {
  self.rc += 1
}

///|
/// Closes a shared process output channel and releases its resources.
pub fn SharedProcessOutput::close(self : SharedProcessOutput) -> Unit {
  self.rc -= 1
  if self.rc is 0 {
    self.io.close()
  }
}

///|
/// Creates a pipe for collecting output from one or more child processes.
///
/// Returns `(reader, output)`. Read the merged output through `reader`, and pass
/// `Shared(output)` as a child's `stdout` or `stderr` redirection.
///
/// For one child created with `spawn()` or `spawn_orphan()`, prefer `Collect`.
///
/// Both returned values are caller-owned. Close `output` after passing it to the
/// last child, and close `reader` after reading is complete.
pub fn read_from_process() -> (ReadFromProcess, SharedProcessOutput) raise {
  let context = "@process.read_from_process()"
  let (r, w) = @fd_util.pipe(
    read_end_is_async=true,
    write_end_is_async=false,
    context~,
  )
  let r = @event_loop.IoHandle::from_fd(r, kind=Pipe)
  let w = @event_loop.IoHandle::from_fd(w, kind=Pipe, is_async=false)
  (ReadFromProcess(Some(r)), { rc: 1, io: w, })
}

///|
/// Creates a pipe for feeding input to one or more child processes.
///
/// Returns `(input, writer)`. Pass `Shared(input)` as a child's `stdin`
/// redirection, and feed data through `writer`.
///
/// For one child created with `spawn()` or `spawn_orphan()`, prefer
/// `FeedFromParent`.
///
/// Both returned values are caller-owned. Close `input` after passing it to the
/// last child, and close `writer` after writing is complete so readers observe
/// end-of-file.
pub fn write_to_process() -> (SharedProcessInput, WriteToProcess) raise {
  let context = "@process.write_to_process()"
  let (r, w) = @fd_util.pipe(
    read_end_is_async=false,
    write_end_is_async=true,
    context~,
  )
  let r = @event_loop.IoHandle::from_fd(r, kind=Pipe, is_async=false)
  let w = @event_loop.IoHandle::from_fd(w, kind=Pipe)
  ({ rc: 1, io: r, }, WriteToProcess(Some(w)))
}

///|
/// Creates a pipe for direct communication between child processes.
///
/// Returns `(input, output)`. Pass `Shared(output)` to producer processes and
/// `Shared(input)` to consumer processes. Data written by producers can be read
/// by consumers.
///
/// Both endpoints are caller-owned and can be shared by multiple children.
/// Close each endpoint after passing it to its last child, or if spawning is
/// abandoned.
pub fn pipe() -> (SharedProcessInput, SharedProcessOutput) raise {
  let context = "@process.pipe()"
  let (r, w) = @fd_util.pipe(
    read_end_is_async=false,
    write_end_is_async=false,
    context~,
  )
  let r = @event_loop.IoHandle::from_fd(r, kind=Pipe, is_async=false)
  let w = @event_loop.IoHandle::from_fd(w, kind=Pipe, is_async=false)
  ({ rc: 1, io: r, }, { rc: 1, io: w, })
}

///|
fn @fs.CreateMode::to_int(self : @fs.CreateMode) -> Int32 = "%identity"

///|
/// Opens a file and returns a caller-owned output endpoint that can be shared by
/// multiple child processes.
///
/// Pass the result as `stdout=Shared(output)` or `stderr=Shared(output)`. Unlike
/// `ToFile(path)` and `AppendFile(path)`, this function opens the file
/// immediately and supports custom creation modes and permissions. Close the
/// endpoint after passing it to the last child, or if spawning is abandoned.
pub async fn redirect_to_file(
  path : String,
  append~ : Bool = false,
  create_mode~ : @fs.CreateMode = CreateOrTruncate,
  permission~ : Int32 = 0o644,
) -> SharedProcessOutput {
  let (file, _) = @event_loop.open(
    path,
    1, // write only
    create=create_mode.to_int(),
    append~,
    sync=0,
    mode=permission,
    context="@process.redirect_to_file()",
  )
  { rc: 1, io: file, }
}

///|
/// Opens a file and returns a caller-owned input endpoint that can be shared by
/// multiple child processes.
///
/// Pass the result as `stdin=Shared(input)`. Unlike `FromFile(path)`, this
/// function opens the file immediately. Children share one open file
/// description and therefore one file offset. Close the endpoint after passing
/// it to the last child, or if spawning is abandoned.
pub async fn redirect_from_file(path : String) -> SharedProcessInput {
  let (file, _) = @event_loop.open(
    path,
    0, // read only
    create=@fs.OpenExisting.to_int(),
    append=false,
    sync=0,
    mode=0,
    context="@process.redirect_from_file()",
  )
  { rc: 1, io: file, }
}
