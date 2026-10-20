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
      "cannot read output of a process whose stdout/stderr is not `@process.read_from_process()`",
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
      "cannot write input of a process whose stdin is not `@process.write_to_process()`",
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
pub extend WriteToProcess with @io.BinaryWriter::{write, write_reader}

///|
/// Trait for objects that can be used to redirect stdin of child process
trait ProcessInput {
  // object with `is_shared() == false` will be closed automatically on process creation
  fn is_shared(Self) -> Bool
  async fn init_stdin(Self, context~ : String) -> (
    @event_loop.IoHandle?,
    WriteToProcess,
  )
}

///|
fn &ProcessInput::close(
  self : &ProcessInput,
  child_end : @event_loop.IoHandle?,
) -> Unit {
  if !self.is_shared() && child_end is Some(child_end) {
    child_end.close()
  }
}

///|
/// Trait for objects that can be used to redirect stdout/stderr of child process
trait ProcessOutput {
  // object with `is_shared() == false` will be closed automatically on process creation
  fn is_shared(Self) -> Bool
  async fn init_stdout(Self, context~ : String) -> (
    ReadFromProcess,
    @event_loop.IoHandle?,
  )
  // The special `duplicate_stdout` object need to access stdout
  async fn init_stderr(Self, stdout~ : @event_loop.IoHandle?, context~ : String) -> (
    ReadFromProcess,
    @event_loop.IoHandle?,
  ) = _
}

///|
impl ProcessOutput with fn init_stderr(self, stdout~, context~) {
  ignore(stdout)
  self.init_stdout(context~)
}

///|
fn &ProcessOutput::close(
  self : &ProcessOutput,
  child_end : @event_loop.IoHandle?,
) -> Unit {
  if !self.is_shared() && child_end is Some(child_end) {
    child_end.close()
  }
}

///|
/// A lazily created pipe for reading output/writing input of a single child process.
/// The pipe is lazily created when actually spawning the child process,
/// so that it won't leak even if program fail before spawning child process.
/// This way, the children end of the pipe can be completely hidden from the child process.
priv struct PipeWithParentLazy {}

///|
impl ProcessInput for PipeWithParentLazy with fn is_shared(_self) {
  false
}

///|
impl ProcessInput for PipeWithParentLazy with fn init_stdin(_self, context~) {
  let (r, w) = @fd_util.pipe(
    read_end_is_async=false,
    write_end_is_async=true,
    context~,
  )
  let r = @event_loop.IoHandle::from_fd(r, kind=Pipe, is_async=false)
  let w = @event_loop.IoHandle::from_fd(w, kind=Pipe)
  (Some(r), WriteToProcess(Some(w)))
}

///|
impl ProcessOutput for PipeWithParentLazy with fn is_shared(_self) {
  false
}

///|
impl ProcessOutput for PipeWithParentLazy with fn init_stdout(_self, context~) {
  let (r, w) = @fd_util.pipe(
    read_end_is_async=true,
    write_end_is_async=false,
    context~,
  )
  let r = @event_loop.IoHandle::from_fd(r, kind=Pipe)
  let w = @event_loop.IoHandle::from_fd(w, kind=Pipe, is_async=false)
  (ReadFromProcess(Some(r)), Some(w))
}

///|
/// Create a temporary channel used to collect output of a single child process.
/// The actual output of the child can be read from `Process.stdout` or `Process.stderr`
/// after spawning the child process.
pub fn read_from_process() -> &ProcessOutput {
  PipeWithParentLazy::{ }
}

///|
/// Create a temporary channel used to writing to input of a single child process.
/// The actual output of the child can be read from `Process.stdout` or `Process.stderr`
/// after spawning the child process.
pub fn write_to_process() -> &ProcessInput {
  PipeWithParentLazy::{ }
}

///|
/// A general object for redirecting stdin of child process.
/// Unlike `write_to_process()`, `SharedProcessInput` can be shared among multiple children.
/// Must be closed manually after being passed to the last child process or on failure.
struct SharedProcessInput(@event_loop.IoHandle)

///|
/// Close a shared process input channel, release associated resource
pub fn SharedProcessInput::close(self : SharedProcessInput) -> Unit {
  self.0.close()
}

///|
pub impl ProcessInput for SharedProcessInput with fn is_shared(_self) {
  true
}

///|
pub impl ProcessInput for SharedProcessInput with fn init_stdin(self, context~) {
  ignore(context)
  (Some(self.0), no_input)
}

///|
/// A general pipe for redirecting stdout/stderr of child process.
/// Unlike `read_from_process()`, `SharedProcessOutput` can be shared among multiple children.
/// Must be closed manually after being passed to the last child process or on failure.
struct SharedProcessOutput(@event_loop.IoHandle)

///|
/// Close a shared process output channel, release associated resource
pub fn SharedProcessOutput::close(self : SharedProcessOutput) -> Unit {
  self.0.close()
}

///|
pub impl ProcessOutput for SharedProcessOutput with fn is_shared(_self) {
  true
}

///|
pub impl ProcessOutput for SharedProcessOutput with fn init_stdout(
  self,
  context~,
) {
  ignore(context)
  (no_output, Some(self.0))
}

///|
/// Create a temporary pipe for reading from stdout/stderr of child process.
/// The return value is a pair `(r, w)`,
/// where `r` is a temporary pipe similar to `Process.stdout` for reading process output,
/// and `w` should be passed to `@process.run`, `@process.spawn` etc.
///
/// For simple redirection involving only one child,
/// `@process.read_from_process()` is cleaner and should be used instead.
/// Use `@process.read_from_process_shared()` only when multiple children process are involved,
/// or when `@process.spawn` cannot be used.
///
/// `w` can be shared among multiple children process,
/// and must be closed manually after being passed to the last child or on failure.
/// `r` must be closed manually when it become unused as well.
pub fn read_from_process_shared() -> (ReadFromProcess, SharedProcessOutput) raise {
  let context = "@process.read_from_process_shared()"
  let (r, w) = @fd_util.pipe(
    read_end_is_async=true,
    write_end_is_async=false,
    context~,
  )
  let r = @event_loop.IoHandle::from_fd(r, kind=Pipe)
  let w = @event_loop.IoHandle::from_fd(w, kind=Pipe, is_async=false)
  (ReadFromProcess(Some(r)), SharedProcessOutput(w))
}

///|
/// Create a temporary pipe for reading from stdout/stderr of child process.
/// The return value is a pair `(r, w)`,
/// where `w` is a temporary pipe similar to `Process.stdin` for writing process input,
/// and `r` should be passed to `@process.run`, `@process.spawn` etc.
///
/// For simple redirection involving only one child,
/// `@process.write_to_process()` is cleaner and should be used instead.
/// Use `@process.write_to_process_shared()` only when multiple children process are involved,
/// or when `@process.spawn` cannot be used.
///
/// `r` can be shared among multiple children process,
/// and must be closed manually after being passed to the last child or on failure.
/// `w` must be closed manually when it become unused as well.
pub fn write_to_process_shared() -> (SharedProcessInput, WriteToProcess) raise {
  let context = "@process.write_to_process_shared()"
  let (r, w) = @fd_util.pipe(
    read_end_is_async=false,
    write_end_is_async=true,
    context~,
  )
  let r = @event_loop.IoHandle::from_fd(r, kind=Pipe, is_async=false)
  let w = @event_loop.IoHandle::from_fd(w, kind=Pipe)
  (SharedProcessInput(r), WriteToProcess(Some(w)))
}

///|
/// Create a temporary pipe for direct communicationg between multiple children process.
/// Return value is a pair `(r, w)`,
/// where `r` should be connected to stdin of child process,
/// and `w` should be connected to stdout/stderr of child process.
/// Data written to `w` by some children can be read from `r` by other children.
///
/// Both `r` and `w` can be shared among multiple children process,
/// and must be closed manually after being passed to the last child or on failure.
pub fn pipe() -> (SharedProcessInput, SharedProcessOutput) raise {
  let context = "@process.pipe()"
  let (r, w) = @fd_util.pipe(
    read_end_is_async=false,
    write_end_is_async=false,
    context~,
  )
  let r = @event_loop.IoHandle::from_fd(r, kind=Pipe, is_async=false)
  let w = @event_loop.IoHandle::from_fd(w, kind=Pipe, is_async=false)
  (SharedProcessInput(r), SharedProcessOutput(w))
}

///|
fn @fs.CreateMode::to_int(self : @fs.CreateMode) -> Int32 = "%identity"

///|
priv struct RedirectWithFile {
  path : String
  mode : Int32
  append : Bool
  create_mode : @fs.CreateMode
  permission : Int32
}

///|
async fn RedirectWithFile::init(
  self : RedirectWithFile,
  context~ : String,
) -> @event_loop.IoHandle {
  let (file, _) = @event_loop.open(
    self.path,
    self.mode, // write only
    create=self.create_mode.to_int(),
    append=self.append,
    sync=0,
    mode=self.permission,
    context~,
  )
  file
}

///|
impl ProcessInput for RedirectWithFile with fn is_shared(_self) {
  false
}

///|
impl ProcessInput for RedirectWithFile with fn init_stdin(self, context~) {
  (Some(self.init(context~)), no_input)
}

///|
impl ProcessOutput for RedirectWithFile with fn is_shared(_self) {
  false
}

///|
impl ProcessOutput for RedirectWithFile with fn init_stdout(self, context~) {
  (no_output, Some(self.init(context~)))
}

///|
/// Redirect the output of a process to the file at `path`.
/// An output channel that should be passed to child process will be returned.
///
/// The meaning of `append`, `create_mode` and `permission` is the same as `@fs.open`,
/// see the document of `@fs.open` for more details.
pub fn redirect_to_file(
  path : String,
  append~ : Bool = false,
  create_mode~ : @fs.CreateMode = CreateOrTruncate,
  permission~ : Int32 = 0o644,
) -> &ProcessOutput {
  RedirectWithFile::{ path, mode: 1, append, create_mode, permission, }
}

///|
/// Redirect the content of a file at `path` to the stdin of a process.
pub fn redirect_from_file(path : String) -> &ProcessInput {
  RedirectWithFile::{
    path,
    mode: 0,
    append: false,
    create_mode: OpenExisting,
    permission: 0,
  }
}

///|
/// Similar to `redirect_to_file()`, except that
/// result of `redirect_to_file_shared()` can be shared among multiple child process,
/// and must be manually closed after being passed to the last child process or on failure.
pub async fn redirect_to_file_shared(
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
    context="@process.redirect_to_file_shared()",
  )
  SharedProcessOutput(file)
}

///|
/// Similar to `redirect_from_file()`, except that
/// result of `redirect_from_file_shared()` can be shared among multiple child process,
/// and must be manually closed after being passed to the last child process or on failure.
pub async fn redirect_from_file_shared(path : String) -> SharedProcessInput {
  let (file, _) = @event_loop.open(
    path,
    0, // read only
    create=@fs.OpenExisting.to_int(),
    append=false,
    sync=0,
    mode=0,
    context="@process.redirect_from_file_shared()",
  )
  SharedProcessInput(file)
}

///|
pub impl ProcessOutput for @stdio.Output with fn is_shared(_self) {
  true
}

///|
pub impl ProcessOutput for @stdio.Output with fn init_stdout(self, context~) {
  ignore(context)
  let fd = self.fd() catch { _ => @fd_util.invalid_fd }
  if @event_loop.stdout is Ok(stdout) && fd == stdout.fd() {
    return (no_output, Some(stdout))
  }
  if @event_loop.stderr is Ok(stderr) && fd == stderr.fd() {
    return (no_output, Some(stderr))
  }
  (no_output, None)
}

///|
pub impl ProcessInput for @stdio.Input with fn is_shared(_self) {
  true
}

///|
pub impl ProcessInput for @stdio.Input with fn init_stdin(_self, context~) {
  ignore(context)
  match @event_loop.stdin {
    Ok(stdin) => (Some(stdin), no_input)
    Err(_) => (None, no_input)
  }
}

///|
priv struct DuplicateStdout {}

///|
impl ProcessOutput for DuplicateStdout with fn is_shared(_self) {
  true
}

///|
impl ProcessOutput for DuplicateStdout with fn init_stdout(_self, context~) {
  ignore(context)
  abort("`@process.duplicate_stdout()` can only be used to redirect stderr")
}

///|
impl ProcessOutput for DuplicateStdout with fn init_stderr(
  _self,
  stdout~,
  context~,
) {
  ignore(context)
  (no_output, stdout)
}

///|
/// Return a special object that can be used to redirect `stderr` of a child process
/// and make it a duplicate of the `stdout` of the same child process.
/// When spawning a child process with `stderr=@process.duplicate_stdout()`,
/// `Process.stderr` cannot be used, and `Process.stdout` should be used instead, if available.
pub fn duplicate_stdout() -> &ProcessOutput {
  DuplicateStdout::{ }
}
