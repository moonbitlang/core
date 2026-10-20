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
async test "write large data" {
  @async_io.with_task_group() <| root => {
    let (r, w) = @io.pipe()
    root.spawn_bg() <| () => {
      defer w.close()
      let data = Bytes::make(1024 * 16, 0)
      w.write(data)
    }
    root.spawn_bg() <| () => {
      defer r.close()
      inspect(r.read_all().length(), content="16384")
    }
  }
}

///|
async test "write reader" {
  let log = StringBuilder()
  @async_io.with_task_group() <| root => {
    let (r1, w1) = @io.pipe()
    let (r2, w2) = @io.pipe()
    root.spawn_bg() <| () => {
      defer r2.close()
      defer w1.close()
      w1.write_reader(r2)
    }
    root.spawn_bg() <| () => {
      defer r1.close()
      while r1.read() is Some(data) {
        let data = @utf8.decode(data)
        log.write_string("received \{data}\n")
      }
    }
    root.spawn_bg() <| () => {
      defer w2.close()
      log <+ "sending 4 bytes\n"
      w2.write(b"abcd")
      @async_io.sleep(300)
      log <+ "sending 4 bytes\n"
      w2.write(b"efgh")
      @async_io.sleep(300)
      log <+ "sending 4 bytes\n"
      w2.write(b"ijkl")
    }
  }
  inspect(
    log.to_string(),
    content=(
      #|sending 4 bytes
      #|received abcd
      #|sending 4 bytes
      #|received efgh
      #|sending 4 bytes
      #|received ijkl
      #|
    ),
  )
}

///|
struct DummyWriter {
  logger : &Logger
  base_timeout : Int32
  ctrl : @io.BinaryWriterController
}

///|
impl @io.BinaryWriter for DummyWriter

///|
impl @io.BinaryWriterImpl for DummyWriter with fn get_controller(self) {
  self.ctrl
}

///|
impl @io.BinaryWriterImpl for DummyWriter with fn raw_write_impl(
  self,
  buf,
  offset~,
  len~,
) {
  guard! offset + len <= buf.length()
  @async_io.sleep(self.base_timeout)
  let logger = self.logger
  logger <+ "writing byte \{buf[offset]}\n"
  1
}

///|
extend DummyWriter with @io.BinaryWriter::{write}

///|
async test "write cancel" {
  let log = StringBuilder()
  let writer = {
    logger: log,
    base_timeout: 300,
    ctrl: BinaryWriterController(),
  }
  @async_io.with_timeout_opt(450, () => writer.write(b"abcd")) |> ignore
  // The `write` here is partial and corrupted,
  // but we have no choice because making `write` atomic may cause hang
  inspect(
    log.to_string(),
    content=(
      #|writing byte b'\x61'
      #|
    ),
  )
}

///|
async test "write_string" {
  @async_io.with_task_group() <| root => {
    let (r, w) = @io.pipe()
    defer r.close()
    root.spawn_bg() <| () => {
      defer w.close()
      @io.Utf8Writer(w).write("abcd中文☺")
    }
    inspect(@io.Utf8Reader(r).read_all(), content="abcd中文☺")
  }
}
