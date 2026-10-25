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
async test "basic create" {
  let path = "_build/basic_create_test"
  let w = @fs.create(path, sync=Full)
  defer @fs.remove(path)
  {
    defer w.close()
    w.write(b"abcd\n")
  }
  let result = {
    let r = @fs.open(path, mode=ReadOnly)
    defer r.close()
    r.text.read_all()
  }
  inspect(
    result,
    content=(
      #|abcd
      #|
    ),
  )
}

///|
async test "create or append" {
  let path = "_build/create_append_test"
  async fn add_data(data) {
    let w = @fs.open(
      path,
      mode=WriteOnly,
      create_mode=OpenOrCreate,
      sync=Full,
      append=true,
    )
    defer w.close()
    w.write(data)
  }

  add_data(b"abcd")
  defer @fs.remove(path)
  add_data(b"efgh")
  let result = {
    let r = @fs.open(path, mode=ReadOnly)
    defer r.close()
    r.text.read_all()
  }
  inspect(result, content="abcdefgh")
}

///|
async test "wrapper test" {
  let path = "_build/fs_wrapper_test"
  @fs.write_binary(path, b"abcd")
  defer @fs.remove(path)
  let result = @fs.read_binary(path)
  assert_eq(result, b"abcd")
}

///|
async test "create_mode test" {
  let path = "_build/create_exclusive_test"
  for create_mode in [@fs.OpenExisting, TruncateExisting] {
    @test.assert_raise_async <| () => {
      @fs.open(path, mode=WriteOnly, create_mode~)
    }
  }
  let file = @fs.create(path, allow_existing=false)
  defer @fs.remove(path)
  {
    defer file.close()
    file.write(b"abcd")
  }
  inspect(@fs.read_text(path), content="abcd")
  @test.assert_raise_async(() => @fs.create(path, allow_existing=false))
  @test.assert_raise_async <| () => {
    @fs.open(path, mode=WriteOnly, create_mode=CreateNew)
  }
  {
    let file = @fs.open(path, mode=WriteOnly, create_mode=OpenExisting)
    defer file.close()
    file.write(b"AB")
  }
  inspect(@fs.read_text(path), content="ABcd")
  {
    let file = @fs.open(path, mode=WriteOnly, create_mode=OpenOrCreate)
    defer file.close()
    file.write(b"XY")
  }
  inspect(@fs.read_text(path), content="XYcd")
  {
    let file = @fs.open(path, mode=WriteOnly, create_mode=CreateOrTruncate)
    defer file.close()
    file.write(b"12")
  }
  inspect(@fs.read_text(path), content="12")
  {
    let file = @fs.open(path, mode=WriteOnly, create_mode=TruncateExisting)
    defer file.close()
    file.write(b"34")
  }
  inspect(@fs.read_text(path), content="34")
}
