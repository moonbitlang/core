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
/// A child process running on a fresh controlling terminal: a Unix PTY or a
/// Windows pseudo console. The child's standard handles are not the
/// terminal; it opens the terminal itself (`/dev/tty`, `CONIN$`/`CONOUT$`).
///
/// What is written to a `Pty` is typed into the terminal, and what is read
/// from it is what the terminal displays. On Windows the latter is a rendering
/// of the screen, so it carries VT sequences instead of the child's exact bytes.
priv struct Pty {
  input : @raw_fd.RawFdStream
  output : @raw_fd.RawFdStream
  handle : Handle
  mut closed : Bool
}

///|
/// Run `path` on a fresh pseudo terminal of 24 x 80.
async fn spawn(path : StringView) -> Pty {
  let env = @env.get_env_vars()
    .to_array()
    .map(entry => @utf8.encode("\{entry.0}=\{entry.1}"))
  let handle = Handle::spawn(
    @utf8.encode(path),
    FixedArray::from_array(env),
    24,
    80,
  )
  let error = handle.error()
  if error != 0 {
    handle.close()
    raise @os_error.OsError::from_errno(error, context="spawn()")
  }
  let input = {
    errdefer handle.close()
    @raw_fd.RawFdStream(handle.take_input())
  }
  let output = {
    errdefer {
      input.close()
      handle.close()
    }
    @raw_fd.RawFdStream(handle.take_output())
  }
  { input, output, handle, closed: false, }
}

///|
/// Wait for the child to exit and return its exit code.
async fn Pty::wait(self : Pty) -> Int32 {
  @process.wait_pid(self.handle.pid())
}

///|
/// Resize the terminal.
fn Pty::resize(self : Pty, rows~ : Int32, cols~ : Int32) -> Unit raise {
  let error = self.handle.resize(rows, cols)
  if error != 0 {
    raise @os_error.OsError::from_errno(error, context="Pty::resize()")
  }
}

///|
/// Close the terminal, which kills the child if it is still running.
fn Pty::close(self : Pty) -> Unit {
  guard !self.closed else { return }
  self.closed = true
  // Our end of the output goes first: before Windows 11 24H2, closing the
  // pseudo console waits for its output to be drained. On Unix, the terminal
  // hangs up, sending SIGHUP, only if the master closes while a slave is
  // still open, so both master descriptors go before the slave anchor.
  self.output.close()
  self.input.close()
  self.handle.close()
}

///|
/// Read the terminal output available, or `None` once the terminal closes.
async fn Pty::read_some(self : Pty) -> Bytes? {
  self.output.read()
}

///|
/// Type `bytes` into the terminal.
async fn Pty::write(self : Pty, bytes : BytesView) -> Unit {
  self.input.write(bytes)
}

///|
#external
priv type Handle

///|
#borrow(path, env)
extern "C" fn Handle::spawn(
  path : Bytes,
  env : FixedArray[Bytes],
  rows : Int32,
  cols : Int32,
) -> Handle = "moonbitlang_async_pty_spawn"

///|
extern "C" fn Handle::error(self : Handle) -> Int32 = "moonbitlang_async_pty_error"

///|
extern "C" fn Handle::pid(self : Handle) -> Int32 = "moonbitlang_async_pty_pid"

///|
extern "C" fn Handle::take_input(self : Handle) -> @types.Fd = "moonbitlang_async_pty_take_input"

///|
extern "C" fn Handle::take_output(self : Handle) -> @types.Fd = "moonbitlang_async_pty_take_output"

///|
extern "C" fn Handle::resize(
  self : Handle,
  rows : Int32,
  cols : Int32,
) -> Int32 = "moonbitlang_async_pty_resize"

///|
extern "C" fn Handle::close(self : Handle) -> Unit = "moonbitlang_async_pty_close"
