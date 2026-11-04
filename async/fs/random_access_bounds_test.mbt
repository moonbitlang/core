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
async test "panic File::read_at rejects an out-of-bounds destination" {
  let path = "_build/read_at_bounds_test"
  @fs.write_text(path, "abcdef", sync=Full)
  defer @fs.remove(path)
  let file = @fs.open(path, mode=ReadOnly)
  defer file.close()
  let buf = FixedArray::make(2, b'\x00')
  ignore(file.read_at(buf, position=0, offset=1, len=2))
}

///|
async test "panic BinaryReader::read_into rejects an out-of-bounds destination" {
  let path = "_build/read_into_bounds_test"
  @fs.write_text(path, "abcdef", sync=Full)
  defer @fs.remove(path)
  let file = @fs.open(path, mode=ReadOnly)
  defer file.close()
  let buf = FixedArray::make(2, b'\x00')
  ignore(file.read_into(buf, offset=1, max_len=2))
}
