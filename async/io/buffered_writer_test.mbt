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
async test "BufferedWriter" {
  let log = StringBuilder()
  @async.with_task_group() <| fn(root) {
    let (r, w) = @io.pipe()
    root.spawn_bg() <| () => {
      defer w.close()
      let w = @io.BufferedWriter::new(w, size=4)
      log <+ "2 bytes written\n"
      w.write(b"ab")
      @async.sleep(20)
      log <+ "2 bytes written\n"
      w.write(b"cd")
      @async.sleep(20)
      log <+ "2 bytes written\n"
      w.write(b"ef")
      w.flush()
    }
    root.spawn_bg() <| () => {
      defer r.close()
      while r.read() is Some(data) {
        log.write_string("received: \{@utf8.decode(data)}\n")
      }
    }
  }
  inspect(
    log.to_string(),
    content=(
      #|2 bytes written
      #|2 bytes written
      #|2 bytes written
      #|received: abcd
      #|received: ef
      #|
    ),
  )
}

///|
async test "BufferedWriter::write_reader" {
  let log = StringBuilder()
  @async.with_task_group() <| fn(root) {
    let (r1, w1) = @io.pipe()
    let (r2, w2) = @io.pipe()
    root.spawn_bg() <| () => {
      defer r2.close()
      defer w1.close()
      let w1 = @io.BufferedWriter::new(w1, size=6)
      w1.write_reader(r2)
      w1.flush()
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
      @async.sleep(100)
      log <+ "sending 4 bytes\n"
      w2.write(b"efgh")
      @async.sleep(100)
      log <+ "sending 4 bytes\n"
      w2.write(b"ijkl")
    }
  }
  inspect(
    log.to_string(),
    content=(
      #|sending 4 bytes
      #|sending 4 bytes
      #|received abcdef
      #|sending 4 bytes
      #|received ghijkl
      #|
    ),
  )
}
