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
async test "tmpdir" {
  let t1 = @fs.tmpdir(prefix="tmp")
  defer @fs.rmdir(t1, recursive=true)
  let t2 = @fs.tmpdir(prefix="tmp")
  defer @fs.rmdir(t2, recursive=true)
  assert_not_eq(t1, t2)
  assert_true(@fs.exists(t1))
  assert_true(@fs.exists(t2))
  @fs.write_text(
    "\{t1}/file.txt",
    "abcd",
    create_mode=CreateNew,
    permission=0o600,
  )
  json_inspect(@fs.readdir(t1), content=["file.txt"])
}
