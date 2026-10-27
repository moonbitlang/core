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
struct Tty {
  input : IoHandle
  /// `SIGWINCH` signalfd/kqueue on Unix, an event for cancellation on Windows
  mut wakeup : @fd_util.Fd
  console_buffer : TtyConsoleBuffer
  /// a resize not yet returned by `read`
  mut resize_pending : Bool
}

///|
/// Like `WindowsConsoleBuffer`, but `pending` can hold several characters
priv struct TtyConsoleBuffer {
  buffer : FixedArray[UInt16]
  mut unpaired_surrogate : UInt16
  pending : FixedArray[Byte]
  mut pending_offset : Int32
  mut pending_len : Int32
}

///|
fn TtyConsoleBuffer::TtyConsoleBuffer() -> TtyConsoleBuffer {
  let (buffer_size, pending_size) = if platform is Windows {
    (WINDOWS_CONSOLE_BUFFER_SIZE, 8)
  } else {
    (0, 0)
  }
  {
    buffer: FixedArray::make(buffer_size, 0),
    unpaired_surrogate: 0,
    pending: FixedArray::make(pending_size, 0),
    pending_offset: 0,
    pending_len: 0,
  }
}

///|
fn TtyConsoleBuffer::write_pending(
  self : TtyConsoleBuffer,
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
) -> Int32 {
  let n = @cmp.minimum(self.pending_len, len)
  self.pending.blit_to(
    buf,
    src_offset=self.pending_offset,
    dst_offset=offset,
    len=n,
  )
  self.pending_len -= n
  self.pending_offset = if self.pending_len > 0 {
    self.pending_offset + n
  } else {
    0
  }
  n
}

///|
/// Write `char` to `buf`, or to `pending` if it does not fit.
/// Return the new number of bytes written to `buf`.
fn TtyConsoleBuffer::emit(
  self : TtyConsoleBuffer,
  char : Int32,
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
  produced~ : Int32,
) -> Int32 {
  let char_bytes = match char {
    _..<0x80 => 1
    _..<0x800 => 2
    _..<0x10000 => 3
    _ => 4
  }
  if self.pending_len == 0 && produced + char_bytes <= len {
    encode_utf8_char(char, buf, offset=offset + produced)
    produced + char_bytes
  } else {
    encode_utf8_char(char, self.pending, offset=self.pending_len)
    self.pending_len += char_bytes
    produced
  }
}

///|
/// Convert `buffer[:n]` to UTF-8 in `buf`. Return the number of bytes written.
fn TtyConsoleBuffer::decode(
  self : TtyConsoleBuffer,
  n : Int32,
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
) -> Int32 {
  let mut produced = 0
  for unit in self.buffer[:n] {
    let high = self.unpaired_surrogate
    match unit {
      0xD800..<=0xDBFF => {
        if high != 0 {
          produced = self.emit(0xFFFD, buf, offset~, len~, produced~)
        }
        self.unpaired_surrogate = unit
      }
      0xDC00..<=0xDFFF => {
        let char = if high != 0 {
          ((high.to_int() - 0xD800) << 10) + (unit.to_int() - 0xDC00) + 0x10000
        } else {
          0xFFFD
        }
        self.unpaired_surrogate = 0
        produced = self.emit(char, buf, offset~, len~, produced~)
      }
      _ => {
        if high != 0 {
          self.unpaired_surrogate = 0
          produced = self.emit(0xFFFD, buf, offset~, len~, produced~)
        }
        produced = self.emit(unit.to_int(), buf, offset~, len~, produced~)
      }
    }
  }
  produced +
  self.write_pending(buf, offset=offset + produced, len=len - produced)
}

///|
/// Wrap the terminal input descriptor and the wakeup descriptor opened by `@tty`.
/// The input is read through the thread pool, so it is not registered to the event loop.
pub fn Tty::new(input_fd~ : @fd_util.Fd, wakeup_fd~ : @fd_util.Fd) -> Tty {
  {
    input: {
      fd: input_fd,
      kind: if platform is Windows {
        Console
      } else {
        CharDevice
      },
      is_async: false,
      read: Idle,
      read_offset: -1,
      write: Idle,
      write_offset: -1,
      console_state: WindowsConsoleBuffer(Console),
    },
    wakeup: wakeup_fd,
    console_buffer: TtyConsoleBuffer(),
    resize_pending: false,
  }
}

///|
/// Close the input and wakeup descriptors. Idempotent.
pub fn Tty::close(self : Tty) -> Unit {
  self.input.close()
  if @fd_util.fd_is_valid(self.wakeup) {
    @fd_util.close(self.wakeup, kind=CharDevice, context="") catch {
      _ => ()
    }
    self.wakeup = @fd_util.invalid_fd
  }
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
  let console = self.console_buffer
  if console.pending_len > 0 {
    return console.write_pending(buf, offset~, len~)
  }
  for ;; {
    if self.resize_pending && !block_resize {
      self.resize_pending = false
      return -1
    }
    let n = if platform is Windows {
      if raw {
        self.read_console_input(buf, offset~, len~, context~)
      } else {
        self.input.read(buf, offset~, len~, context~)
      }
    } else {
      let job = Job::tty_read(self.input.fd, self.wakeup, buf, offset, len)
      defer job.free()
      perform_job_in_worker(job, context~, cancellable=true)
    }
    guard n < 0 else { return n }
    self.resize_pending = true
  }
}

///|
async fn Tty::read_console_input(
  self : Tty,
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
  context~ : String,
) -> Int32 {
  let console = self.console_buffer
  let max_len = @cmp.minimum(console.buffer.length(), @cmp.maximum(len / 3, 3))
  for ;; {
    let job = TtyReadConsoleInputJob::new(
      self.input.fd,
      self.wakeup,
      console.buffer,
      0,
      max_len,
    )
    defer job.0.free()
    let n = perform_job_in_worker(job.0, context~, cancellable=true)
    if n < 0 {
      return n
    }
    let produced = console.decode(n, buf, offset~, len~)
    if job.resized() {
      if produced == 0 {
        return -1
      }
      self.resize_pending = true
    }
    if produced > 0 {
      return produced
    }
  }
}

///|
/// A console input job, which can report a resize read along with input
priv struct TtyReadConsoleInputJob(Job)
