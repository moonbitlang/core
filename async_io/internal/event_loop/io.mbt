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
priv enum IoStatus {
  Idle
  // a pending read/write operation is already submitted to thread pool
  Submitted
  // waiting for read/write readiness or completion from the event bus
  Waiting(@coroutine.Coroutine)
}

///|
/// A managed file descriptor/`HANDLE`,
/// capable of performing async IO operations.
pub struct IoHandle {
  priv mut fd : @fd_util.Fd
  priv kind : @fd_util.FileKind
  /// - `is_async=true`: support native async operations through the event bus.
  ///   This usually means the fd is non blocking (Unix) or overlapped (Windows)
  /// - `is_async=false`: all operations are blocking and go through the thread pool
  priv is_async : Bool
  priv mut read : IoStatus
  /// The current offset for reading.
  /// A negative value indicates that the underlying object does not support random access.
  ///
  /// We manually maintain `read_offset`,
  /// because the semantic of native file pointer is undesirable:
  ///
  /// - On Unix-like systems, read/write share the same file pointer.
  /// - On Windows, random access read/write will change the file pointer for synchronous handle.
  mut read_offset : Int64
  priv mut write : IoStatus
  /// Similar to `read_offset`, but for the write end of the object.
  mut write_offset : Int64
  priv console_state : WindowsConsoleBuffer
}

///|
/// Get the associated file descriptor/Windows HANDLE of an `IoHandle`.
pub fn IoHandle::fd(handle : IoHandle) -> @fd_util.Fd {
  handle.fd
}

///|
/// Get the kind of an `IoHandle`.
pub fn IoHandle::kind(handle : IoHandle) -> @fd_util.FileKind {
  handle.kind
}

///|
/// Detach a file descriptor from the event loop,
/// but does not close the file descriptor itself.
/// The underlying file descriptor is returned.
pub fn IoHandle::detach_from_event_loop(handle : IoHandle) -> Unit {
  guard! curr_loop.val is Some(evloop)
  guard @fd_util.fd_is_valid(handle.fd) else { return }
  evloop.fds.remove(handle.fd)
  if handle.is_async {
    evloop.bus.remove(handle.fd) catch {
      _ => ()
    }
  }
}

///|
/// Close a file descriptor and detach it from the event loop.
/// This function is idempotent: it is safe to call `.close()` multiple times.
pub fn IoHandle::close(handle : IoHandle) -> Unit {
  handle.detach_from_event_loop()
  if @fd_util.fd_is_valid(handle.fd) {
    @fd_util.close(handle.fd, kind=handle.kind, context="") catch {
      _ => ()
    }
  }
  handle.fd = @fd_util.invalid_fd
}

///|
/// Create a IO handle from a raw file descriptor, and register the file descriptor to the event loop.
/// The ownership of the file descriptor would be transferred to this function,
/// so the caller must not close the file descriptor manually in any circumstances.
///
/// - `is_async` indicates whether the file descriptor support async operations.
///   On Unix systems, if `is_async=true`, the file descriptor will be set to non-blocking mode,
///   On Windows, the file descriptor must be created in overlapped mode.
///
/// - `read_only` indicates whether the handle has the concept of writing.
///   By default, `IoHandle::from_fd` will register both read/write events for the file descriptor,
///   If `read_only=true`, only read event will be registered.
pub fn IoHandle::from_fd(
  fd : @fd_util.Fd,
  kind~ : @fd_util.FileKind,
  is_async~ : Bool = true,
  read_only~ : Bool = false,
) -> IoHandle raise {
  let context = "@event_loop.IoHandle::from_fd()"
  errdefer @fd_util.close(fd, kind~, context~)
  guard! curr_loop.val is Some(evloop)
  guard! evloop.fds.get(fd) is None
  let is_async = is_async && evloop.bus.register(fd, read_only~)
  let handle = {
    fd,
    kind,
    is_async,
    read: Idle,
    read_offset: if kind is Regular {
      0
    } else {
      -1
    },
    write: Idle,
    write_offset: if kind is Regular {
      0
    } else {
      -1
    },
    console_state: WindowsConsoleBuffer(kind),
  }
  evloop.fds[fd] = handle
  handle
}

///|
/// Perform a read operation on the IO handle via the thread pool.
/// Used for handling objects that do not support native async reading.
async fn IoHandle::read_via_worker(
  handle : IoHandle,
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
  context~ : String,
) -> Int32 {
  guard! handle.read is Idle
  handle.read = Submitted
  defer {
    handle.read = Idle
  }
  let job = Job::read(handle.fd, buf, offset, len, position=handle.read_offset)
  defer job.free()
  perform_job_in_worker(
    job,
    context~,
    cancellable=platform is Windows || handle.kind.can_poll(),
  )
}

///|
#cfg(platform="windows")
const IS_NATIVE_WINDOWS : Bool = true

///|
#cfg(not(platform="windows"))
const IS_NATIVE_WINDOWS : Bool = false

///|
async fn IoHandle::read_console(
  handle : IoHandle,
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
  context~ : String,
) -> Int32 {
  guard! handle.read is Idle
  if handle.console_state.pending_len > 0 {
    return handle.console_state.write_pending(buf, offset~, len~)
  }

  // At this point, `handle.console_buffer` should not contain any pending decoded bytes,
  // but may contain unpaired high surrogate from the last read.
  let unpaired_offset = if handle.console_state.unpaired_surrogate > 0 {
    handle.console_state.buffer[0] = handle.console_state.unpaired_surrogate
    1
  } else {
    0
  }
  let max_read_len = @cmp.minimum(
    WINDOWS_CONSOLE_BUFFER_SIZE - unpaired_offset,
    @cmp.maximum(len / 3, 1),
  )
  let n = {
    handle.read = Submitted
    defer {
      handle.read = Idle
    }
    let job = Job::read_console(
      handle.fd,
      handle.console_state.buffer,
      unpaired_offset,
      max_read_len,
    )
    defer job.free()
    perform_job_in_worker(job, context~, cancellable=true)
  }

  let n = unpaired_offset + n
  handle.console_state.unpaired_surrogate = 0
  for rest = handle.console_state.buffer[:n], produced = 0 {
    let (char, rest) = match rest {
      [] => break produced
      [0xD800..<=0xDBFF as high, 0xDC00..<=0xDFFF as low, .. rest] => {
        let c = ((high.to_int() - 0xD800) << 10) +
          (low.to_int() - 0xDC00) +
          0x10000
        (if c > 0x10FFFF { 0xFFFD } else { c }, rest)
      }
      [0xD800..<=0xDBFF as high] =>
        if produced > 0 {
          handle.console_state.unpaired_surrogate = high
          break produced
        } else if unpaired_offset > 0 {
          // Corner case: the last code unit before EOF is an unpaired high surrogate.
          // Convert it to `U+FFFD` (replacement character)
          handle.console_state.pending_len = 3
          encode_utf8_char(0xFFFD, handle.console_state.pending, offset=1)
          return handle.console_state.write_pending(buf, offset~, len~)
        } else {
          // The input contain solely one unpaired surrogate,
          // since 0 inidicates EOF, we must read more data here.
          handle.console_state.unpaired_surrogate = high
          return handle.read_console(buf, offset~, len~, context~)
        }
      [0xD800..<=0xDFFF, .. rest] => (0xFFFD, rest)
      [c, .. rest] => (c.to_int(), rest)
    }
    let char_bytes = match char {
      _..<0x80 => 1
      _..<0x800 => 2
      _..<0x10000 => 3
      _ => 4
    }
    if produced + char_bytes <= len {
      encode_utf8_char(char, buf, offset=offset + produced)
      continue rest, produced + char_bytes
    } else {
      encode_utf8_char(
        char,
        handle.console_state.pending,
        offset=4 - char_bytes,
      )
      handle.console_state.pending_len = char_bytes
      guard! rest is []
      break produced +
        handle.console_state.write_pending(
          buf,
          offset=produced + offset,
          len=len - produced,
        )
    }
  }
}

///|
/// Perform a read operation on an `IoHandle`.
/// At most `len` bytes will be read into `buf[offset:]`.
/// The number of bytes actually written will be returned on success.
/// A return value of zero always indicate EOF on the underlying object.
/// In other cases, the return value is always positive, but may be smaller than `len`.
pub async fn IoHandle::read(
  handle : IoHandle,
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
  context~ : String,
) -> Int32 {
  @coroutine.check_cancellation()
  // TODO: port to Wasm
  let n = if IS_NATIVE_WINDOWS && handle.kind is Console {
    handle.read_console(buf, offset~, len~, context~)
  } else if handle.is_async {
    /// The implementation of `read_via_event_bus` is platform dependent,
    /// and is located in `io_unix.mbt`, `io_windows.mbt` etc.
    handle.read_via_event_bus(buf, offset~, len~, context~)
  } else {
    handle.read_via_worker(buf, offset~, len~, context~)
  }
  if handle.read_offset >= 0 {
    handle.read_offset += n.to_int64()
  }
  n
}

///|
/// Perform a write operation on the IO handle via the thread pool.
/// Used for handling objects that do not support native async writing.
async fn IoHandle::write_via_worker(
  handle : IoHandle,
  buf : Bytes,
  offset~ : Int32,
  len~ : Int32,
  context~ : String,
) -> Int32 {
  guard! handle.write is Idle
  handle.write = Submitted
  defer {
    handle.write = Idle
  }
  let job = Job::write(
    handle.fd,
    buf,
    offset,
    len,
    position=handle.write_offset,
  )
  defer job.free()
  perform_job_in_worker(
    job,
    context~,
    cancellable=platform is Windows || handle.kind.can_poll(),
  )
}

///|
#cfg(target="native")
#borrow(src, dst)
extern "C" fn utf8_decode_lossy_to_utf16(
  src~ : Bytes,
  src_offset~ : Int32,
  src_len~ : Int32,
  dst~ : FixedArray[UInt16],
  dst_offset~ : Int32,
) -> Int32 = "moonbit_utf8_decode_lossy_into_utf16"

///|
#cfg(target="wasm")
fn utf8_decode_lossy_to_utf16(
  src~ : Bytes,
  src_offset~ : Int32,
  src_len~ : Int32,
  dst~ : FixedArray[UInt16],
  dst_offset~ : Int32,
) -> Int32 {
  ignore(src)
  ignore(src_offset)
  ignore(src_len)
  ignore(dst)
  ignore(dst_offset)
  panic()
}

///|
async fn IoHandle::write_console(
  handle : IoHandle,
  buf : Bytes,
  offset~ : Int32,
  len~ : Int32,
  context~ : String,
) -> Int32 {
  guard! handle.write is Idle
  handle.write = Submitted
  defer {
    handle.write = Idle
  }
  let (cache_produced, cache_consumed) = if handle.console_state.pending_len > 0 {
    let total = match handle.console_state.pending[0] {
      0xC0..<0xE0 => 2
      0xE0..<0xF0 => 3
      0xF0..<=0xF4 => 4
      _ => panic()
    }
    let required = total - handle.console_state.pending_len
    let max_new_pending = @cmp.minimum(len, required)
    // Copy only continuation bytes, so that in case of invalid sequence,
    // subsequent correct characters can recover synchronization.
    let continuation_prefix = for i in 0..<max_new_pending {
      guard buf[offset + i] is (0x80..<0xC0) else { break i }
    } nobreak {
      max_new_pending
    }
    handle.console_state.pending.blit_from_bytesview(
      handle.console_state.pending_len,
      buf[offset:offset + continuation_prefix],
    )
    if continuation_prefix >= required {
      let decoded = @utf8.decode_lossy(
        handle.console_state.pending.unsafe_reinterpret_as_bytes()[:total],
      )
      for i, value in decoded.code_units() {
        handle.console_state.buffer[i] = value
      }
      (decoded.length(), required)
    } else if continuation_prefix < len {
      handle.console_state.buffer[0] = 0xFFFD
      (1, continuation_prefix)
    } else {
      // We still do no have enough data to produce a complete character
      handle.console_state.pending_len += len
      return len
    }
  } else {
    (0, 0)
  }

  let offset = offset + cache_consumed
  let len = @cmp.minimum(
    len - cache_consumed,
    (WINDOWS_CONSOLE_BUFFER_SIZE - cache_produced) / 2,
  )

  let remainder = match buf[offset:offset + len] {
    [.., 0xC0..<0xE0] => 1
    [.., 0xE0..<0xF0] => 1
    [.., 0xE0..<0xF0, 0x80..<0xC0] => 2
    [.., 0xF0..<=0xF4] => 1
    [.., 0xF0..<=0xF4, 0x80..<0xC0] => 2
    [.., 0xF0..<=0xF4, 0x80..<0XC0, 0x80..<0xC0] => 3
    _ => 0
  }

  let produced = if len > remainder {
    cache_produced +
    utf8_decode_lossy_to_utf16(
      src=buf,
      src_offset=offset,
      src_len=len - remainder,
      dst=handle.console_state.buffer,
      dst_offset=cache_produced,
    )
  } else {
    cache_produced
  }
  if produced > 0 {
    for written = 0; written < produced; {
      let job = Job::write_console(
        handle.fd,
        handle.console_state.buffer,
        written,
        produced - written,
      )
      defer job.free()
      // We need to ensure cancellation safety of `write_console`,
      // so if there is already data written (`written > 0`),
      // we should make subsequent write calls non-cancellable.
      let delta = perform_job_in_worker(job, context~, cancellable=written is 0)
      continue written + delta
    }
    handle.console_state.pending_len = 0
    cache_consumed + len - remainder
  } else {
    // the input is not enough to decode even a single complete unicode character
    handle.console_state.pending_len = remainder
    handle.console_state.pending.blit_from_bytesview(
      0,
      buf[offset + len - remainder:offset + len],
    )
    remainder
  }
}

///|
/// Perform a write operation on an `IoHandle`.
/// At most `len` bytes from `buf[offset:]` will be written.
/// The number of bytes actually written will be returned on success,
/// whics is always positive but may be smaller than `len`.
pub async fn IoHandle::write(
  handle : IoHandle,
  buf : Bytes,
  offset~ : Int32,
  len~ : Int32,
  context~ : String,
) -> Int32 {
  @coroutine.check_cancellation()
  // TODO: port to Wasm
  let n = if IS_NATIVE_WINDOWS && handle.kind is Console {
    handle.write_console(buf, offset~, len~, context~)
  } else if handle.is_async {
    /// The implementation of `write_via_event_bus` is platform dependent,
    /// and is located in `io_unix.mbt`, `io_windows.mbt` etc.
    handle.write_via_event_bus(buf, offset~, len~, context~)
  } else {
    handle.write_via_worker(buf, offset~, len~, context~)
  }
  if handle.write_offset >= 0 {
    handle.write_offset += n.to_int64()
  }
  n
}

///|
/// Perform a random access read on the IO handle.
/// Since only regular files support random access IO,
/// `read_at` is always dispatched to the thread pool.
pub async fn IoHandle::read_at(
  handle : IoHandle,
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
  position~ : Int64,
  context~ : String,
) -> Int32 {
  @coroutine.check_cancellation()
  guard! !handle.is_async
  let job = Job::read(handle.fd, buf, offset, len, position~)
  defer job.free()
  perform_job_in_worker(job, context~, cancellable=platform is Windows)
}

///|
/// Perform a random access write on the IO handle.
/// Since only regular files support random access IO,
/// `write_at` is always dispatched to the thread pool.
pub async fn IoHandle::write_at(
  handle : IoHandle,
  buf : Bytes,
  offset~ : Int32,
  len~ : Int32,
  position~ : Int64,
  context~ : String,
) -> Unit {
  @coroutine.check_cancellation()
  guard! !handle.is_async
  guard handle.write_offset >= 0 else {
    raise Failure::Failure(
      "`write_at` is not supported on non-regular file or file opened in append mode",
    )
  }
  let job = Job::write(handle.fd, buf, offset, len, position~)
  defer job.free()
  ignore(perform_job_in_worker(job, context~, cancellable=platform is Windows))
}
