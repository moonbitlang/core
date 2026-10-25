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
priv enum TransportState {
  Normal
  Closed
  Error(Error)
}

///|
priv struct Transport {
  mut state : TransportState
  reader : &@io.BinaryReader
  read_lock : @semaphore.Semaphore
  write_buf : @io_buffer.Buffer
  writer : &@io.BinaryWriter
  write_lock : @semaphore.Semaphore
}

///|
const BUFFER_SIZE = 4096

///|
fn Transport::new(
  reader : &@io.BinaryReader,
  writer : &@io.BinaryWriter,
) -> Transport {
  {
    state: Normal,
    reader,
    read_lock: Semaphore(1),
    write_buf: @io_buffer.new(BUFFER_SIZE),
    writer,
    write_lock: Semaphore(1),
  }
}

///|
#warnings("-fragile_catch_all")
async fn Transport::read_more(self : Transport) -> Unit {
  self.read_lock.acquire()
  defer self.read_lock.release()
  match self.state {
    Normal => ()
    Closed => raise ConnectionClosed
    Error(err) => raise err
  }
  let controller = @io.BinaryReaderImpl::get_controller(self.reader)
  let prev_len = controller.buffered().length()
  try @io.BinaryReaderImpl::ensure_buffered(self.reader, prev_len + 1) catch {
    err => {
      self.state = Error(err)
      raise err
    }
  } noraise {
    true => ()
    false => self.state = Closed
  }
}

///|
async fn Transport::flush_write(self : Transport) -> Unit {
  self.write_lock.acquire()
  defer self.write_lock.release()
  guard self.write_buf.len > 0 else {  }
  match self.state {
    Normal => ()
    Closed => raise ConnectionClosed
    Error(err) => raise err
  }
  let start = self.write_buf.start
  let end = self.write_buf.start + self.write_buf.len
  let data = self.write_buf.buf.unsafe_reinterpret_as_bytes()[start:end]
  self.writer.write(data)
  self.write_buf.start = 0
  self.write_buf.len = 0
}
