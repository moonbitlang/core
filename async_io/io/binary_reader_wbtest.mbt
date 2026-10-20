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
async test "read_all_binary preserves multiple prefixes" {
  let reader = MemoryReader() <| writer => { writer.write(b"body") }
  defer reader.close()
  let prefixes : FixedArray[BytesView] = [b"a", b"bc"]
  inspect(
    @utf8.decode(read_all_binary(reader, prefix_list=prefixes, chunk_size=2)),
    content="abcbody",
  )
}

///|
test "BinaryReaderController reserves aligned prefix storage" {
  let controller = BinaryReaderController()
  inspect(controller.buf_start, content="8")
  inspect(controller.buf.length(), content="8")
  controller.enlarge_to(1024)
  inspect(controller.buf_start, content="8")
  assert_true(controller.buf.length() >= 1032)
  controller.clear()
  inspect(controller.buf_start, content="8")
  inspect(controller.buf.length(), content="8")
}

///|
priv struct EnsureBufferedTestReader {
  ctrl : BinaryReaderController
  fail : Bool
}

///|
impl BinaryReaderImpl for EnsureBufferedTestReader with fn get_controller(self) {
  self.ctrl
}

///|
impl BinaryReaderImpl for EnsureBufferedTestReader with fn raw_read_impl(
  self,
  _buf,
  offset~,
  max_len~,
) {
  ignore(offset)
  ignore(max_len)
  if self.fail {
    raise ReaderClosed
  }
  0
}

///|
async test "ensure_buffered distinguishes EOF from an inner ReaderClosed" {
  let eof_reader = { ctrl: BinaryReaderController(), fail: false, }
  assert_false(BinaryReaderImpl::ensure_buffered(eof_reader, 1))
  let failing_reader = { ctrl: BinaryReaderController(), fail: true, }
  try BinaryReaderImpl::ensure_buffered(failing_reader, 1) |> ignore catch {
    ReaderClosed => ()
    err => raise err
  } noraise {
    _ => fail("expected inner ReaderClosed")
  }
}
