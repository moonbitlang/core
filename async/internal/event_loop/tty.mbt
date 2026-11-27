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
/// The reading side of a terminal opened by `@tty`.
#cfg(platform="windows")
struct Tty {
  /// a console input handle
  input : IoHandle
  console_buffer : WindowsConsoleBuffer
}

///|
/// The reading side of a terminal opened by `@tty`.
#cfg(not(platform="windows"))
struct Tty {
  /// non-blocking and registered to the event bus
  input : IoHandle
}

///|
/// Wrap the terminal input opened by `@tty`.
#cfg(platform="windows")
pub fn Tty::new(input~ : IoHandle) -> Tty {
  { input, console_buffer: WindowsConsoleBuffer(Console), }
}

///|
/// Wrap the terminal input opened by `@tty`.
#cfg(not(platform="windows"))
pub fn Tty::new(input~ : IoHandle) -> Tty {
  { input, }
}

///|
/// Close the terminal input. Idempotent.
pub fn Tty::close(self : Tty) -> Unit {
  self.input.close()
}

///|
/// The input descriptor of the terminal.
pub fn Tty::input_fd(self : Tty) -> @fd_util.Fd {
  self.input.fd()
}

///|
/// Wait for input or a resize, then read input.
/// Return `-1` for a resize, which may be reported after later input.
/// With `block_resize`, like a blocked signal, a resize does not end the wait
/// and stays pending until a read without `block_resize`.
/// `raw` is whether line input is off: then input is read as console input
/// records, the only source of resizes.
#cfg(platform="windows")
pub async fn Tty::read(
  self : Tty,
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
  raw~ : Bool,
  block_resize~ : Bool,
  context~ : String,
) -> Int32 {
  @coroutine.check_cancellation()
  let resize = resize_state.val.unwrap()
  let console = self.console_buffer
  if console.pending_len > 0 {
    return console.write_pending(buf, offset~, len~)
  }
  for ;; {
    if resize.pending && !block_resize {
      resize.pending = false
      return -1
    }
    let n = if raw {
      self.read_console_input(buf, offset~, len~, context~)
    } else {
      self.input.read(buf, offset~, len~, context~)
    }
    if n < 0 {
      resize.pending = true
    } else {
      return n
    }
  }
}

///|
/// Wait for input or a resize, then read input.
/// Return `-1` for a resize, which may be reported after later input.
/// With `block_resize`, like a blocked signal, a resize does not end the wait
/// and stays pending until a read without `block_resize`.
/// `raw` is whether line input is off; the kernel already applies it to reads.
#cfg(not(platform="windows"))
pub async fn Tty::read(
  self : Tty,
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
  raw~ : Bool,
  block_resize~ : Bool,
  context~ : String,
) -> Int32 {
  ignore(raw)
  @coroutine.check_cancellation()
  let resize = resize_state.val.unwrap()
  for ;; {
    if !block_resize && resize.pending {
      resize.pending = false
      return -1
    }
    let n = read_unix_ffi(self.input.fd, buf, offset~, len~)
    if n >= 0 {
      // Like `read_via_event_bus_unix`, give other tasks a chance to run.
      @coroutine.pause_nocancel()
      return n
    }
    if !@errno_util.is_nonblocking_io_error() {
      @os_error.check_errno(context)
    }
    // `SIGWINCH` wakes the wait for input; the loop then checks
    // `resize.pending` itself instead of guessing from a failed read.
    if !block_resize {
      resize.waiter = Some(@coroutine.current_coroutine())
    }
    defer {
      resize.waiter = None
    }
    self.input.wait_read()
  }
}

///|
/// `sizeof(INPUT_RECORD)` (20 bytes) in `UInt16` code units of the job buffer
#cfg(platform="windows")
const INPUT_RECORD_UNITS : Int32 = 10

///|
#cfg(platform="windows")
async fn Tty::read_console_input(
  self : Tty,
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
  context~ : String,
) -> Int32 {
  let console = self.console_buffer
  // A record produces at most one code unit, which takes up to 3 UTF-8 bytes
  let max_records = @cmp.maximum(len / 3, 1)
  let max_len = @cmp.minimum(
    console.buffer.length(),
    max_records * INPUT_RECORD_UNITS,
  )
  for ;; {
    let error = @ref.Ref(0)
    let job = ReadConsoleInputJob::new(
      self.input.fd,
      console.buffer,
      max_len,
      error,
    )
    defer job.0.free()
    if error.val != 0 {
      raise @os_error.OsError::from_errno(error.val, context~)
    }
    let n = perform_job_in_worker(job.0, context~, cancellable=true)
    if n < 0 {
      return n
    }
    let produced = console.decode_utf16(n, buf, offset~, len~)
    if job.resized() {
      if produced == 0 {
        return -1
      }
      let resize = resize_state.val.unwrap()
      resize.pending = true
    }
    if produced > 0 {
      return produced
    }
  }
}

///|
#cfg(platform="windows")
priv struct ReadConsoleInputJob(Job)

///|
/// Read console input records into `buf[:len]` and compact them in place
/// into UTF-16 code units. The job owns the event that cancels the wait;
/// `error` is set when that event cannot be created.
#cfg(platform="windows")
#owned(buf)
#borrow(input, error)
extern "C" fn ReadConsoleInputJob::new(
  input : @fd_util.Fd,
  buf : FixedArray[UInt16],
  len : Int32,
  error : @ref.Ref[Int32],
) -> ReadConsoleInputJob = "moonbit_rt_make_read_console_input_job"

///|
/// Whether a resize was read along with the returned input
#cfg(platform="windows")
#borrow(job)
extern "C" fn ReadConsoleInputJob::resized(job : ReadConsoleInputJob) -> Bool = "moonbit_rt_read_console_input_job_get_resized"

///|
/// Consume a resize already observed by the event loop, without reading input.
/// Checked by `Tty::wait_resize()` before looking at buffered input.
pub fn Tty::take_pending_resize(self : Tty) -> Bool {
  ignore(self)
  if resize_state.val is Some(resize) && resize.pending {
    resize.pending = false
    true
  } else {
    false
  }
}
