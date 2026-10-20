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
async test "read EOF" {
  let buf = FixedArray::make(16, b'0')
  let path = "_build/read_eof_test"
  let w = @fs.create(path, permission=0o644, sync=Full)
  defer @fs.remove(path)
  {
    defer w.close()
    w.write(b"abcd")
  }
  let n = {
    let r = @fs.open(path, mode=ReadOnly)
    defer r.close()
    r.read_into(buf)
  }
  assert_eq(n, 4)
  inspect(@utf8.decode(buf.unsafe_reinterpret_as_bytes()[0:n]), content="abcd")
}
