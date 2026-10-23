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
async test "realpath absolute" {
  let rp = @fs.realpath("async/fs/realpath_test.mbt")
  guard! @env.current_dir() is Some(cwd)
  assert_true(rp.has_prefix(cwd))
  inspect(
    rp[cwd.length():].replace_all(old="\\", new="/"),
    content="/async/fs/realpath_test.mbt",
  )
}

///|
// These symlink scenarios are not supported on Windows. Wasm learns the host
// platform at runtime instead of through MoonBit target cfg.
async test "realpath link to absolute" {
  if @event_loop.platform is Windows {
    return
  }
  guard! @env.current_dir() is Some(cwd)
  let path = match cwd {
    [.., '/'] => cwd + "async/fs/realpath_test.mbt"
    _ => cwd + "/async/fs/realpath_test.mbt"
  }
  let link_path = "_build/realpath_test_link_to_absolute.test"
  @fs.symlink(link_path, target=path)
  defer @fs.remove(link_path)
  let rp = @fs.realpath(link_path)
  assert_true(rp.has_prefix(cwd))
  inspect(rp[cwd.length():], content="/async/fs/realpath_test.mbt")
}

///|
async test "realpath link to relative" {
  if @event_loop.platform is Windows {
    return
  }
  guard! @env.current_dir() is Some(cwd)
  let rel_path = "../async/fs/realpath_test.mbt"
  let link_path = "_build/realpath_test_link_to_relative.test"
  @fs.symlink(link_path, target=rel_path)
  defer @fs.remove(link_path)
  let rp = @fs.realpath(link_path)
  assert_true(rp.has_prefix(cwd))
  inspect(rp[cwd.length():], content="/async/fs/realpath_test.mbt")
}

///|
async test "realpath link to dir absolute" {
  guard! @env.current_dir() is Some(cwd)
  let path = match cwd {
    [.., '/'] => cwd + "async/fs"
    _ => cwd + "/async/fs"
  }
  let link_path = "_build/realpath_test_link_to_dir_absolute.test"
  @fs.symlink(link_path, target=path)
  defer @fs.remove(link_path)
  let rp = @fs.realpath(link_path + "/realpath_test.mbt")
  assert_true(rp.has_prefix(cwd))
  inspect(
    rp[cwd.length():].replace_all(old="\\", new="/"),
    content="/async/fs/realpath_test.mbt",
  )
}

///|
async test "realpath link to dir relative" {
  if @event_loop.platform is Windows {
    return
  }
  guard! @env.current_dir() is Some(cwd)
  let rel_path = "../async/fs"
  let link_path = "_build/realpath_test_link_to_dir_relative.test"
  @fs.symlink(link_path, target=rel_path)
  defer @fs.remove(link_path)
  let rp = @fs.realpath(link_path + "/realpath_test.mbt")
  assert_true(rp.has_prefix(cwd))
  inspect(rp[cwd.length():], content="/async/fs/realpath_test.mbt")
}
