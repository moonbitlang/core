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
async test "read_all" {
  let dir = @fs.opendir("async_io/fs/test_directory/dir1")
  defer dir.close()
  let list = dir
    .read_all()
    .filter_map(x => if x is "target" { None } else { Some(x) })
  list.sort()
  json_inspect(list, content=["file", "inner1"])
}

///|
async test "as_dir" {
  let dir_file = @fs.open("async_io/fs/test_directory/dir1", mode=ReadOnly)
  guard! dir_file.kind() is Directory
  let dir = dir_file.as_dir()
  defer dir.close()
  let list = dir.read_all()..sort()
  json_inspect(list, content=["file", "inner1"])
}

///|
test "readdir clear errno" {
  @event_loop.with_event_loop() <| () => {
    // do something to set a non-zero errno
    try @fs.open("/this/file/does/not/exist", mode=ReadOnly) catch {
      _ => ()
    } noraise {
      _ => ()
    }
    let dir = @fs.opendir("async_io/fs/test_directory/dir1")
    defer dir.close()
    let list = dir.read_all()
    inspect(
      list.length(),
      content=(
        #|2
      ),
    )
  }
}
