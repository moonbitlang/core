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
#cfg(not(platform="windows"))
async test "kind of symlink to regular" {
  let link_path = "_build/stat_symlink_to_regular_test"
  @fs.symlink(link_path, target="../LICENSE")
  defer @fs.remove(link_path)
  debug_inspect(@fs.kind(link_path), content="Regular")
  debug_inspect(@fs.kind(link_path, follow_symlink=false), content="SymLink")
}

///|
async test "kind of symlink to directory" {
  guard! @env.current_dir() is Some(cwd)
  let link_path = "_build/stat_symlink_to_dir_test"
  @fs.symlink(link_path, target="\{cwd}/_build")
  defer @fs.remove(link_path)
  debug_inspect(@fs.kind(link_path), content="Directory")
  debug_inspect(@fs.kind(link_path, follow_symlink=false), content="SymLink")
}
