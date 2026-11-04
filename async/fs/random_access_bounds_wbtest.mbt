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
async test "panic IoHandle::write_at rejects an out-of-bounds source" {
  let path = "_build/write_at_bounds_test"
  write_text(path, "", sync=Full)
  defer remove(path)
  let file = open(path, mode=ReadWrite)
  defer file.close()
  file.io.write_at(
    b"ab",
    offset=1,
    len=2,
    position=0,
    context="write_at bounds test",
  )
}
