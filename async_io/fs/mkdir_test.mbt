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
async test "mkdir" {
  let path = "_build/mkdir_test"
  @fs.mkdir(path)
  defer @fs.rmdir(path, recursive=true)
  @fs.write_text("\{path}/file", "")
  let result = @fs.readdir(path, sort=true)
  debug_inspect(result, content="[\"file\"]")
}

///|
async test "rmdir recursive" {
  guard! @env.current_dir() is Some(cwd)
  let path = "_build/rmdir_test"
  @fs.mkdir(path, permission=0o755)
  @fs.write_text("\{path}/file", "")
  @fs.mkdir("\{path}/inner")
  @fs.write_text("\{path}/inner/file", "")
  @fs.symlink("\{path}/symlink", target="\{cwd}/_build")
  defer (if @fs.exists(path) { @fs.rmdir(path, recursive=true) })
  @test_util.assert_raise_async(() => @fs.rmdir(path))
  @fs.rmdir(path, recursive=true)
}

///|
async test "mkdir recursive" {
  let base_path = "_build/recursive_mkdir"
  let path = "\{base_path}/test//directory"
  @fs.mkdir(path, recursive=true)
  defer @fs.rmdir(base_path, recursive=true)
  json_inspect(@fs.readdir(base_path), content=["test"])
  json_inspect(@fs.readdir("\{base_path}/test"), content=["directory"])
  json_inspect(@fs.readdir("\{base_path}/test/directory"), content=[])
}

///|
async test "mkdir recursive windows" {
  // Wasm learns the host platform at runtime instead of through MoonBit target
  // cfg, so keep this test present and select it using moonrun's host platform.
  if !(@event_loop.platform is Windows) {
    return
  }
  let base_path = "_build\\recursive_mkdir_windows"
  let path = "\{base_path}\\test\\\\directory"
  @fs.mkdir(path, recursive=true)
  defer @fs.rmdir(base_path, recursive=true)
  json_inspect(@fs.readdir(base_path), content=["test"])
  json_inspect(@fs.readdir("\{base_path}\\test"), content=["directory"])
  json_inspect(@fs.readdir("\{base_path}\\test/directory"), content=[])
}

///|
async test "mkdir allow_exist" {
  @async_io.with_task_group() <| group => {
    let base_path = "_build/mkdir_allow_exist"
    let path = "\{base_path}/directory"
    @fs.mkdir(path, recursive=true)
    group.add_defer(() => @fs.rmdir(base_path, recursive=true))
    @fs.mkdir(path, allow_exist=true)
    @fs.mkdir("\{path}/", allow_exist=true)
    @fs.mkdir(path, recursive=true, allow_exist=true)
    // without `allow_exist`, an existing directory is an error
    @test_util.assert_raise_async(() => @fs.mkdir(path))
    @test_util.assert_raise_async(() => @fs.mkdir(path, recursive=true))
    // an existing non-directory is an error even with `allow_exist`
    let file = "\{base_path}/file"
    @fs.write_text(file, "", create_mode=CreateOrTruncate)
    @test_util.assert_raise_async(() => @fs.mkdir(file, allow_exist=true))
    @test_util.assert_raise_async(() => {
      @fs.mkdir(file, recursive=true, allow_exist=true)
    })
    json_inspect(@fs.readdir(base_path, sort=true), content=[
      "file", "directory",
    ])
  }
}

///|
async test "mkdir recursive concurrent with shared parents" {
  @async_io.with_task_group() <| group => {
    let base_path = "_build/recursive_mkdir_concurrent"
    group.add_defer(() => @fs.rmdir(base_path, recursive=true))
    @async_io.with_task_group() <| workers => {
      for i in 0..<8 {
        workers.spawn_bg(() => {
          @fs.mkdir("\{base_path}/shared/parent/\{i}", recursive=true)
        })
      }
    }
    json_inspect(@fs.readdir("\{base_path}/shared/parent", sort=true), content=[
      "0", "1", "2", "3", "4", "5", "6", "7",
    ])
  }
}
