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
async test "PipeRead blocked cancellation safety" {
  let (r, w) = @io.pipe()
  @async.with_task_group <| group => {
    let reader = group.spawn() <| () => {
      defer r.close()
      debug_inspect(
        r.read(),
        content=(
          #|Some(<Bytes: [0x61, 0x62, 0x63, 0x64]>)
        ),
      )
    }
    defer w.close()
    @async.pause()
    reader.cancel()
    w.write(b"abcd")
    // `reader` should succeed here
    reader.wait()
  }
}

///|
async test "PipeWrite blocked cancellation safety" {
  let (r, w) = @io.pipe()
  @async.with_task_group <| group => {
    let writer = group.spawn() <| () => {
      defer w.close()
      w.write(b"abcd")
    }
    defer r.close()
    @async.pause()
    writer.cancel()
    debug_inspect(
      r.read(),
      content=(
        #|Some(<Bytes: [0x61, 0x62, 0x63, 0x64]>)
      ),
    )
    // `reader` should succeed here
    writer.wait()
  }
}

///|
async test "PipeRead immediate cancellation safety" {
  let (r, w) = @io.pipe()
  @async.with_task_group <| group => {
    let reader = group.spawn() <| () => {
      defer r.close()
      debug_inspect(
        r.read(),
        content=(
          #|Some(<Bytes: [0x61, 0x62, 0x63, 0x64]>)
        ),
      )
    }
    defer w.close()
    w.write(b"abcd")
    reader.cancel()
    // `reader` should succeed here
    reader.wait()
  }
}

///|
async test "PipeWrite immediate cancellation safety" {
  let (r, w) = @io.pipe()
  @async.with_task_group <| group => {
    let writer = group.spawn() <| () => {
      defer w.close()
      w.write(b"abcd")
    }
    defer r.close()
    debug_inspect(
      r.read(),
      content=(
        #|Some(<Bytes: [0x61, 0x62, 0x63, 0x64]>)
      ),
    )
    writer.cancel()
    // `reader` should succeed here
    writer.wait()
  }
}
