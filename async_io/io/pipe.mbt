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
priv enum PipeReader {
  NoReader
  ReadEndClosed
  HasReader(
    coro~ : @coroutine.Coroutine,
    buf~ : FixedArray[Byte],
    offset~ : Int32,
    max_len~ : Int32,
    mut result~ : Int32
  )
}

///|
priv enum PipeWriter {
  NoWriter
  WriteEndClosed
  HasWriter(
    coro~ : @coroutine.Coroutine,
    buf~ : Bytes,
    offset~ : Int32,
    len~ : Int32,
    mut result~ : Int32
  )
}

///|
priv struct Pipe {
  mut reader : PipeReader
  mut writer : PipeWriter
}

///|
/// The read end of a pipe.
/// Data written to the write end can be read from here.
#valtype
struct PipeRead {
  pipe : Pipe
  ctrl : BinaryReaderController
}

///|
/// The write end of a pipe.
/// Data written here can be read from the read end.
#valtype
struct PipeWrite {
  pipe : Pipe
  ctrl : BinaryWriterController
}

///|
/// Create a new in-memory pipe.
/// Data written to the write end can be obtained from the read end.
/// Useful for testing and converting writer-based function to reader.
pub fn pipe() -> (PipeRead, PipeWrite) {
  let pipe : Pipe = { reader: NoReader, writer: NoWriter, }
  (
    { pipe, ctrl: BinaryReaderController(), },
    { pipe, ctrl: BinaryWriterController(), },
  )
}

///|
/// Close the read end of a pipe.
/// After closing the read end, writing to the write end result in error.
pub fn PipeRead::close(self : PipeRead) -> Unit {
  if self.pipe.writer is (HasWriter(_) as writer) {
    writer.result = 0
    writer.coro.wake()
  }
  self.pipe.reader = ReadEndClosed
}

///|
/// Close the write end of a pipe.
/// After closing the write end, reading from the read end result in EOF.
pub fn PipeWrite::close(self : PipeWrite) -> Unit {
  if self.pipe.reader is (HasReader(_) as reader) {
    reader.result = 0
    reader.coro.wake()
  }
  self.pipe.writer = WriteEndClosed
}

///|
/// Read data from a pipe. The data come from the write end of the pipe.
/// Data transfer only happen when reader and writer are present at the same time.
pub impl BinaryReader for PipeRead

///|
impl BinaryReaderImpl for PipeRead with fn raw_read_impl(
  self,
  dst,
  offset~,
  max_len~,
) {
  guard! self.pipe.reader is NoReader
  @coroutine.check_cancellation()
  match self.pipe.writer {
    NoWriter => {
      let coro = @coroutine.current_coroutine()
      let reader = HasReader(coro~, buf=dst, offset~, max_len~, result=0)
      self.pipe.reader = reader
      defer (if self.pipe.reader is HasReader(_) {
        self.pipe.reader = NoReader
      })
      match @coroutine.suspend_check_cancel() {
        Continue => {
          guard! reader is HasReader(result~, ..)
          result
        }
        Cancelled if reader is HasReader(result~, ..) && result > 0 =>
          // if data is already transferred to the reader
          // within the same scheduler round of cancellaiton,
          // swallow the cancellation to avoid data loss
          return result
        Cancelled => @coroutine.raise_cancellation_signal()
      }
    }
    WriteEndClosed => 0
    HasWriter(_) as writer => {
      let len = @cmp.minimum(max_len, writer.len)
      dst.blit_from_bytes(offset, writer.buf, writer.offset, len)
      writer.result = len
      writer.coro.wake()
      // The pause here is not cancellable,
      // because otherwise the writer cannot have correct knowledge on what is written,
      // making writing not cancellation safe.
      @coroutine.pause_nocancel()
      len
    }
  }
}

///|
impl BinaryReaderImpl for PipeRead with fn get_controller(self) {
  self.ctrl
}

///|
pub extend PipeRead with BinaryReader::{
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
/// This error will be raised when
/// writing to a pipe whose read end is already closed.
pub suberror PipeClosed derive(@debug.Debug, @json.ToJson)

///|
/// Write data to a pipe. The data can be read from the read end of the pipe.
/// Data transfer only happen when reader and writer are present at the same time.
pub impl BinaryWriter for PipeWrite

///|
impl BinaryWriterImpl for PipeWrite with fn raw_write_impl(
  self,
  buf,
  offset~,
  len~,
) {
  guard! self.pipe.writer is NoWriter
  @coroutine.check_cancellation()
  match self.pipe.reader {
    NoReader => {
      let coro = @coroutine.current_coroutine()
      let writer = HasWriter(coro~, buf~, offset~, len~, result=0)
      self.pipe.writer = writer
      defer (if self.pipe.writer is HasWriter(_) {
        self.pipe.writer = NoWriter
      })
      match @coroutine.suspend_check_cancel() {
        Continue => {
          guard! writer is HasWriter(result~, ..)
          guard result > 0 else { raise PipeClosed }
          result
        }
        Cancelled if self.pipe.writer is HasWriter(result~, ..) && result > 0 =>
          // if data is already transferred to the reader
          // within the same scheduler round of cancellaiton,
          // swallow the cancellation so that the writer side
          // can have correct knowledge of what is written
          result
        Cancelled => @coroutine.raise_cancellation_signal()
      }
    }
    ReadEndClosed => raise PipeClosed
    HasReader(_) as reader => {
      let len = @cmp.minimum(len, reader.max_len)
      reader.buf.blit_from_bytes(reader.offset, buf, offset, len)
      reader.result = len
      reader.coro.wake()
      // We must make sure the writer return after the reader is woken,
      // otherwise another immediate write after this one will
      // accidentally write to the same read request.
      //
      // We cannot set `self.reader` to `NoReader` a priori here as well,
      // because in that case, an immediate write + read combo after this write
      // may complete faster than the previous read.
      // The `pause` here is also vital for preventing stackoverflow in a busy loop.
      //
      // The pause here is not cancellable,
      // because otherwise the writer cannot have correct knowledge on what is written,
      // making writing not cancellation safe.
      @coroutine.pause_nocancel()
      len
    }
  }
}

///|
impl BinaryWriterImpl for PipeWrite with fn get_controller(self) {
  self.ctrl
}

///|
pub extend PipeWrite with BinaryWriter::{write, write_reader}
