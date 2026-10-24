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
async test "read_into rejects destination ranges outside the buffer" {
  @async.with_task_group() <| root => {
    let (reader, writer) = @io.pipe()
    defer reader.close()
    root.spawn_bg() <| () => {
      defer writer.close()
      writer.write(b"abc")
    }
    // buffer the payload so the writer can finish and close its end
    reader.peek_at_least(3) |> ignore
    let dst : FixedArray[Byte] = FixedArray::make(16, b'0')
    try reader.read_into(dst, offset=16, max_len=1) catch {
      _ => ()
    } noraise {
      _ => fail("read_into past the end succeeded")
    }
    try reader.read_into(dst, offset=-1, max_len=1) catch {
      _ => ()
    } noraise {
      _ => fail("read_into with a negative offset succeeded")
    }
    try reader.read_into(dst, offset=0, max_len=17) catch {
      _ => ()
    } noraise {
      _ => fail("read_into beyond capacity succeeded")
    }
  }
}

///|
async test "read_into accepts ranges inside the destination" {
  @async.with_task_group() <| root => {
    let (reader, writer) = @io.pipe()
    defer reader.close()
    root.spawn_bg() <| () => {
      defer writer.close()
      writer.write(b"abcdef")
    }
    reader.peek_at_least(6) |> ignore
    let dst : FixedArray[Byte] = FixedArray::make(16, b'0')
    let n = reader.read_into(dst, offset=8, max_len=4)
    assert_eq(n, 4)
    assert_eq(dst[8], b'a')
    assert_eq(dst[9], b'b')
    assert_eq(dst[10], b'c')
    assert_eq(dst[11], b'd')
    assert_eq(dst[12], b'0')
  }
}
