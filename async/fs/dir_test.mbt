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
  let dir = @fs.opendir("async/fs/test_directory/dir1")
  defer dir.close()
  let list = dir
    .read_all()
    .filter_map(x => if x is "target" { None } else { Some(x) })
  list.sort()
  json_inspect(list, content=["file", "inner1"])
}

///|
async test "as_dir" {
  let dir_file = @fs.open("async/fs/test_directory/dir1", mode=ReadOnly)
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
    let dir = @fs.opendir("async/fs/test_directory/dir1")
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

///|
async test "Directory::close is idempotent" {
  for _ in 0..<16 {
    let dir = @fs.opendir("async/fs/test_directory/dir1")
    dir.close()
    // closing twice used to free the entry buffer twice
    dir.close()
  }
}

///|
async test "Directory::next after close raises" {
  let dir = @fs.opendir("async/fs/test_directory/dir1")
  // leave buffered entries behind, which used to be read from freed memory
  guard dir.next() is Some(_) else { fail("expected an entry") }
  dir.close()
  @test.assert_raise_async(() => dir.next())
  @test.assert_raise_async(() => dir.read_all())
}

///|
async test "Directory::close while next is in progress" {
  for _ in 0..<16 {
    let dir = @fs.opendir("async/fs/test_directory/dir1")
    let mut result = ""
    @async.with_task_group() <| group => {
      group.spawn_bg() <| () => {
        result = try dir.next() catch {
          _ => "raised"
        } noraise {
          _ => "returned"
        }
      }
      // let `next` submit its readdir job, then close under it:
      // the entry buffer it is reading into must outlive the job
      @async.pause()
      dir.close()
    }
    inspect(result, content="raised")
  }
}
