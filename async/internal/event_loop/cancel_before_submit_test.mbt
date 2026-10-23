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
async test "cancel before submit" {
  let file = @fs.open("LICENSE", mode=ReadOnly)
  defer file.close()
  let buf = FixedArray::make(1, b'\x00')
  let result = @async.with_timeout_opt(1, () => {
    while file.read_into(buf, offset=0, max_len=1) is 1 {

    }
  })
  debug_inspect(result, content="None")
}
