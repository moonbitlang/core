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
async test "relative open" {
  let old_path = "_build/relative_open_test"
  let new_path = "_build/relative_open_test_renamed"
  @fs.mkdir(old_path)
  defer @fs.rmdir(old_path, allow_missing=true, recursive=true)
  defer @fs.rmdir(new_path, allow_missing=true, recursive=true)
  @fs.write_text("\{old_path}/file", "abcd")
  let dir = @fs.opendir(old_path)
  defer dir.close()
  json_inspect(dir.read_all(), content=["file"])
  @fs.rename(old_path, new_path)
  match @test.expect_error_async(() => @fs.read_text("\{old_path}/file")) {
    @os_error.OsError(NotFound, ..) => ()
    err =>
      raise Failure("incorrect error when accessing out-dated old path: \{err}")
  }
  inspect(@fs.read_text("\{new_path}/file"), content="abcd")
  let file = dir.open("file", mode=ReadOnly)
  defer file.close()
  inspect(file.text.read_all(), content="abcd")
}

///|
async test "relative remove" {
  let old_path = "_build/relative_remove_test"
  let new_path = "_build/relative_remove_test_renamed"
  @fs.mkdir(old_path)
  defer @fs.rmdir(old_path, allow_missing=true, recursive=true)
  defer @fs.rmdir(new_path, allow_missing=true, recursive=true)
  @fs.write_text("\{old_path}/file", "abcd")
  let dir = @fs.opendir(old_path)
  defer dir.close()
  json_inspect(dir.read_all(), content=["file"])
  @fs.rename(old_path, new_path)
  match @test.expect_error_async(() => @fs.read_text("\{old_path}/file")) {
    @os_error.OsError(NotFound, ..) => ()
    err =>
      raise Failure("incorrect error when accessing out-dated old path: \{err}")
  }
  inspect(@fs.read_text("\{new_path}/file"), content="abcd")
  dir.remove("file")
  assert_false(@fs.exists("\{new_path}/file"))
}
