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
async test "remove recursive" {
  guard! @env.current_dir() is Some(cwd)
  let path = "_build/remove_test"
  @fs.mkdir(path, permission=0o755)
  @fs.write_text("\{path}/file", "")
  @fs.mkdir("\{path}/inner")
  @fs.write_text("\{path}/inner/file", "")
  @fs.symlink("\{path}/symlink", target="\{cwd}/_build")
  @test.assert_raise_async(() => @fs.remove(path))
  @fs.remove(path, recursive=true)
}

///|
async test "remove allow_missing" {
  let path = "_build/remove_allow_missing_test"
  @test.assert_raise_async(() => @fs.remove(path))
  @fs.remove(path, allow_missing=true)
}
