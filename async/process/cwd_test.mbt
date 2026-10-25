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
async test "set cwd" {
  @async.with_task_group() <| group => {
    // FIXME(upstram): missing codelens here
    guard! @env.current_dir() is Some(prev_cwd)
    let child = @process.spawn(
      group,
      shell,
      ["-c", ls],
      stdout=@process.read_from_process(),
      cwd="async/fs/test_directory/dir1",
      extra_env={ "LC_ALL": "C" },
    )
    defer child.stdout.close()
    guard! @env.current_dir() is Some(new_cwd)
    guard! prev_cwd == new_cwd
    let files = child.stdout.text
      .read_all()
      .trim(char_set="\n\r ")
      .replace_all(old="\r\n", new="\n")
      .split("\n")
      .to_array()
    files.sort()
    json_inspect(files, content=["file", "inner1"])
  }
}
