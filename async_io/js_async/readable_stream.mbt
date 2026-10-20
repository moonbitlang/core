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
#external
priv type StreamReader

///|
priv struct ReadableStreamChunk {
  value : Bytes
  done : Bool
}

///|
extern "js" fn StreamReader::read_ffi(
  reader : Self,
) -> Promise[ReadableStreamChunk] =
  #| (reader) => reader.read()

///|
async fn StreamReader::read(reader : StreamReader) -> Bytes? {
  match reader.read_ffi().wait() {
    { done: true, .. } => None
    { done: false, value, } => Some(value)
  }
}

///|
extern "js" fn StreamReader::release_lock(reader : Self) -> Unit =
  #| (stream) => stream.releaseLock()

///|
#external
priv type ReadableStreamController

///|
extern "js" fn ReadableStreamController::close(controller : Self) =
  #| (controller) => controller.close()

///|
extern "js" fn ReadableStreamController::enqueue(
  controller : Self,
  chunk : Bytes,
) =
  #| (controller, chunk) => controller.enqueue(chunk)

///|
/// The `ReadableStream` type in Web API, see
///   https://developer.mozilla.org/en-US/docs/Web/API/ReadableStream
/// for more details.
///
/// Use this type on JavaScript FFI boundary to interact with
/// API that make use of `ReadableStream`, such as `fetch`.
#external
type JsReadableStream

///|
extern "js" fn JsReadableStream::new(
  pull : (ReadableStreamController) -> Promise[Unit],
  cancel : (JsValue) -> Unit,
) -> JsReadableStream =
  #| (f, cancel) => new ReadableStream({ start: f, pull: f, cancel: cancel })

///|
extern "js" fn JsReadableStream::cancel(stream : Self) -> Unit =
  #| (stream) => {
  #|   stream.cancel().catch(() => {})
  #| }

///|
extern "js" fn JsReadableStream::get_reader(stream : Self) -> StreamReader =
  #| (stream) => stream.getReader()

///|
/// A wrapper around `JsReadableStream`
/// that allows reading the content via the `@io.BinaryReader` interface.
///
/// This type SHOULD NOT be used on FFI directly:
/// its ABI is NOT the same as `JsReadableStream`,
/// and most JavaScript types won't understand it.
struct ReadableStream {
  read_end : @io.PipeRead
  worker : @coroutine.Coroutine
  worker_error : @ref.Ref[Error?]
  stream : JsReadableStream
  reader : StreamReader
}

///|
/// Create a `ReadableStream` wrapper from a `JsReadableStream` object,
/// in order to read the content of the stream from the MoonBit side.
/// The ownership of the JS stream will be transferred to the `ReadableStream`:
/// other code cannot read the stream anymore.
pub fn ReadableStream::from_js(stream : JsReadableStream) -> ReadableStream {
  let (r, w) = @io.pipe()
  let reader = stream.get_reader()
  // Here, we use a coroutine to copy the data,
  // because the `.read()` method of `StreamReader` is NOT cancellable.
  // It can only be cancelled by cancelling the whole stream.
  // So we use a `@io.pipe` in the middle to provide proper cancellation support.
  let worker_error : @ref.Ref[Error?] = Ref(None)
  let worker = @coroutine.spawn(() => {
    defer w.close()
    try {
      while reader.read() is Some(chunk) {
        w.write(chunk)
      }
    } catch {
      err => worker_error.val = Some(err)
    }
  })
  { read_end: r, worker, worker_error, stream, reader, }
}

///|
/// Close a `ReadableStream`. The underlying JS stream will be cancelled.
pub fn ReadableStream::close(self : ReadableStream) -> Unit {
  self.worker.cancel()
  self.read_end.close()
  self.reader.release_lock()
  self.stream.cancel()
}

///|
pub impl @io.BinaryReader for ReadableStream

///|
impl @io.BinaryReaderImpl for ReadableStream with fn get_controller(self) {
  @io.BinaryReaderImpl::get_controller(self.read_end as &@io.BinaryReader)
}

///|
impl @io.BinaryReaderImpl for ReadableStream with fn raw_read_impl(
  self,
  buf,
  offset~,
  max_len~,
) {
  let n = @io.BinaryReaderImpl::raw_read_impl(
    self.read_end as &@io.BinaryReader,
    buf,
    offset~,
    max_len~,
  )
  if n == 0 && self.worker_error.val is Some(err) {
    raise err
  }
  n
}

///|
pub extend ReadableStream with @io.BinaryReader::{
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
/// Create an anonymous pipe and wrap the read end into a `JsReadableStream`.
/// This allows writing data from MoonBit code to JavaScript.
/// Usually users should pass the read end of the pipe (`JsReadableStream`)
/// to JavaScript code, and write to the write end of the pipe (`@io.PipeWrite`)
/// from MoonBit code.
///
/// Closing the write end of the pipe will signal EOF on the read end.
/// If the read end of the stream is cancelled from the JavaScript side,
/// further write operations on the write end will fail with error.
pub fn JsReadableStream::new_pipe() -> (JsReadableStream, @io.PipeWrite) {
  let abort_controller = AbortController::new()
  let abort_signal = abort_controller.signal()
  let (pipe_r, pipe_w) = @io.pipe()
  fn pull(controller : ReadableStreamController) {
    Promise::from_async(abort_signal~) <| () => {
      guard pipe_r.read() is Some(chunk) else { controller.close() }
      controller.enqueue(chunk)
    }
  }
  fn cancel(_reason) {
    pipe_r.close()
    abort_controller.abort()
    @coroutine.reschedule()
  }
  let stream = JsReadableStream::new(pull, cancel)
  (stream, pipe_w)
}
