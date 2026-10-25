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
async fn writer(log : StringBuilder, w : @io.PipeWrite) -> Unit {
  defer w.close()
  @async.sleep(20)
  log <+ "writing 4 bytes of data\n"
  w.write(b"abcd")
  @async.sleep(20)
  log <+ "writing 4 bytes of data\n"
  w.write(b"efgh")
  @async.sleep(20)
  log <+ "writing 4 bytes of data\n"
  w.write(b"ijkl")
}

///|
async test "read_all basic" {
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    let (r, w) = @io.pipe()
    defer r.close()
    root.spawn_bg(() => writer(log, w))
    inspect(@utf8.decode(r.read_all()), content="abcdefghijkl")
  }
}

///|
async test "read_all large data" {
  @async.with_task_group() <| root => {
    let (r, w) = @io.pipe()
    defer r.close()
    root.spawn_bg() <| () => {
      defer w.close()
      w.write(Bytes::make(4097, 0))
    }
    inspect(r.read_all().length(), content="4097")
  }
}
