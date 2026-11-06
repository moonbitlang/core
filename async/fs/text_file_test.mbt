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
async test "text file" {
  let path = "_build/basic_text_file_test"
  @fs.write_text(path, "abcd")
  defer @fs.remove(path)
  inspect(@fs.read_text(path), content="abcd")
}

///|
async test "write_text default creation mode" {
  let dir = @fs.tmpdir(prefix="write_text_defaults")
  defer @fs.rmdir(dir, recursive=true)
  let path = "\{dir}/file"
  for content in ["", "月🌙"] {
    @fs.write_text(path, "ABCDE")
    @fs.write_text(path, content, append=true)
    assert_eq(@fs.read_text(path), "ABCDE" + content)
    @fs.write_text(path, content)
    assert_eq(@fs.read_text(path), content)
  }
}

///|
async test "write_text creates missing files with empty or nonempty content" {
  let dir = @fs.tmpdir(prefix="write_text_missing")
  defer @fs.rmdir(dir, recursive=true)
  let path = "\{dir}/file"
  for append in [false, true] {
    for content in ["", "月🌙"] {
      @fs.write_text(path, content, append~)
      assert_eq(@fs.read_text(path), content)
      @fs.remove(path)
    }
  }
}

///|
async test "write_text honors explicit creation modes" {
  let dir = @fs.tmpdir(prefix="write_text_explicit")
  defer @fs.rmdir(dir, recursive=true)
  let path = "\{dir}/file"
  for content in ["", "月🌙"] {
    for create_mode in [@fs.OpenExisting, OpenOrCreate, CreateOrTruncate] {
      @fs.write_text(path, "ABCDE")
      @fs.write_text(path, content, append=true, create_mode~)
      assert_eq(
        @fs.read_text(path),
        if create_mode is CreateOrTruncate {
          content
        } else {
          "ABCDE" + content
        },
      )
    }
    @fs.write_text(path, "ABCDE")
    @test.assert_raise_async(() => {
      @fs.write_text(path, content, append=true, create_mode=CreateNew)
    })
    assert_eq(@fs.read_text(path), "ABCDE")
    @fs.remove(path)
    @test.assert_raise_async(() => {
      @fs.write_text(path, content, append=true, create_mode=OpenExisting)
    })
    assert_false(@fs.exists(path))
    @fs.write_text(path, content, append=true, create_mode=CreateNew)
    assert_eq(@fs.read_text(path), content)
  }
  @fs.write_text(path, "ABCDE")
  @fs.write_text(path, "xy", create_mode=OpenOrCreate)
  inspect(@fs.read_text(path), content="xyCDE")
  @fs.write_text(path, "z", create_mode=TruncateExisting)
  inspect(@fs.read_text(path), content="z")
}
