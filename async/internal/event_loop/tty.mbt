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
  /// non-blocking and registered to the event bus on Unix,
  /// a console input handle on Windows
  input : IoHandle
  console_buffer : WindowsConsoleBuffer
}

///|
/// Wrap the terminal input opened by `@tty`.
pub fn Tty::new(input~ : IoHandle) -> Tty {
  { input, console_buffer: WindowsConsoleBuffer(Console), }
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
/// On Windows, resizes are only read from console input records in `raw` mode;
/// `raw` is ignored on Unix.
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
  if platform is Windows {
    self.read_windows(buf, offset~, len~, raw~, block_resize~, context~)
  } else {
    self.read_unix(buf, offset~, len~, block_resize~, context~)
  }
}

///|
async fn Tty::read_unix(
  self : Tty,
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
  block_resize~ : Bool,
  context~ : String,
) -> Int32 {
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
async fn Tty::read_windows(
  self : Tty,
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
  raw~ : Bool,
  block_resize~ : Bool,
  context~ : String,
) -> Int32 {
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
    guard n < 0 else { return n }
    resize.pending = true
  }
}

///|
/// Write `char` to `buf`, or to `pending` if it does not fit.
/// Return the new number of bytes written to `buf`.
fn tty_emit_char(
  console : WindowsConsoleBuffer,
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
  if console.pending_len == 0 && produced + char_bytes <= len {
    encode_utf8_char(char, buf, offset=offset + produced)
    produced + char_bytes
  } else {
    console.pending.blit_to(
      console.pending,
      src_offset=4 - console.pending_len,
      dst_offset=4 - console.pending_len - char_bytes,
      len=console.pending_len,
    )
    encode_utf8_char(char, console.pending, offset=4 - char_bytes)
    console.pending_len += char_bytes
    produced
  }
}

///|
/// Convert `buffer[:n]` to UTF-8 in `buf`. Return the number of bytes written.
fn tty_decode_input(
  console : WindowsConsoleBuffer,
  n : Int32,
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
) -> Int32 {
  let mut produced = 0
  for unit in console.buffer[:n] {
    let high = console.unpaired_surrogate
    match unit {
      0xD800..<=0xDBFF => {
        if high != 0 {
          produced = tty_emit_char(
            console,
            0xFFFD,
            buf,
            offset~,
            len~,
            produced~,
          )
        }
        console.unpaired_surrogate = unit
      }
      0xDC00..<=0xDFFF => {
        let char = if high != 0 {
          ((high.to_int() - 0xD800) << 10) + (unit.to_int() - 0xDC00) + 0x10000
        } else {
          0xFFFD
        }
        console.unpaired_surrogate = 0
        produced = tty_emit_char(console, char, buf, offset~, len~, produced~)
      }
      _ => {
        if high != 0 {
          console.unpaired_surrogate = 0
          produced = tty_emit_char(
            console,
            0xFFFD,
            buf,
            offset~,
            len~,
            produced~,
          )
        }
        produced = tty_emit_char(
          console,
          unit.to_int(),
          buf,
          offset~,
          len~,
          produced~,
        )
      }
    }
  }
  produced +
  console.write_pending(buf, offset=offset + produced, len=len - produced)
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
  let max_len = @cmp.minimum(console.buffer.length(), @cmp.maximum(len / 3, 1))
  for ;; {
    let job = TtyReadConsoleInputJob::new(
      self.input.fd,
      console.buffer,
      0,
      max_len,
    )
    defer job.0.free()
    let n = perform_job_in_worker(job.0, context~, cancellable=true)
    if n < 0 {
      return n
    }
    let produced = tty_decode_input(console, n, buf, offset~, len~)
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
priv struct TtyReadConsoleInputJob(Job)
