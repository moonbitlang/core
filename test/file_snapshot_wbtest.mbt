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
fn snapshot_fixture(root : String) -> Test {
  {
    name: "fixture",
    buffer: StringBuilder(),
    snapshots: Some({
      root,
      baselines: root,
      prefix: "case",
      closed: false,
      files: [],
      names: {},
      results: [],
    }),
  }
}

///|
async test "file snapshots collect differences and close the context" {
  let root = @fs.tmpdir(prefix="snapshot-context")
  defer @fs.remove(root, recursive=true)
  let t = snapshot_fixture(root)
  @fs.write_text(root + "/before", "old")
  let text = t.create_file()
  @fs.write_text(text.path(), "new")
  text.snapshot(filename="before")
  let binary = t.create_file()
  @fs.write_binary(binary.path(), b"\x00\xff")
  binary.snapshot(filename="missing")
  assert_eq(t.snapshots.unwrap().results.length(), 2)
  assert_eq(
    t.snapshots.unwrap().results.map(r => {
      if r is { "offset": String(s), .. } {
        s
      } else {
        "invalid"
      }
    }),
    ["0", "-2"],
  )
  inspect(@fs.read_text(root + "/before"), content="old")
  let message = t.finish("")
  assert_true(message.contains("@FILE_SNAPSHOTS "))
  assert_true(message.contains("\"body_error\":\"\""))
  assert_true(
    expect_error(() => t.create_file()).to_string().contains("closed"),
  )
}

///|
async test "unused files and stable paths do not require disposal" {
  let root = @fs.tmpdir(prefix="snapshot-lifecycle")
  defer @fs.remove(root, recursive=true)
  let t = snapshot_fixture(root)
  let file = t.create_file()
  let path = file.path()
  assert_true(
    expect_error(() => file.snapshot(filename="../escape"))
    .to_string()
    .contains("relative"),
  )
  inspect(t.finish(""), content="")
  assert_eq(file.path(), path)
  assert_true(
    expect_error(() => file.snapshot(filename="late"))
    .to_string()
    .contains("closed"),
  )
}

///|
async test "caught I/O errors cannot hide incomplete comparisons" {
  let root = @fs.tmpdir(prefix="snapshot-incomplete")
  defer @fs.remove(root, recursive=true)
  let t = snapshot_fixture(root)
  let file = t.create_file()
  @fs.remove(file.path())
  ignore(expect_error(() => file.snapshot(filename="missing")))
  assert_true(t.finish("").contains("comparison(s) did not complete"))
}

///|
async test "body errors survive snapshots and duplicate claims fail" {
  let root = @fs.tmpdir(prefix="snapshot-errors")
  defer @fs.remove(root, recursive=true)
  let t = snapshot_fixture(root)
  let file = t.create_file()
  @fs.write_text(file.path(), "new")
  file.snapshot(filename="a")
  assert_true(
    expect_error(() => file.snapshot(filename="again"))
    .to_string()
    .contains("already started"),
  )
  let duplicate = t.create_file()
  assert_true(
    expect_error(() => duplicate.snapshot(filename="a"))
    .to_string()
    .contains("duplicate"),
  )
  assert_true(t.finish("body failed").contains("body failed"))
  assert_false(@fs.exists(root + "/a"))
}

///|
async test "comparison crosses chunks and detects prefixes and binary differences" {
  let root = @fs.tmpdir(prefix="snapshot-chunks")
  defer @fs.remove(root, recursive=true)
  let a = root + "/a"
  let b = root + "/b"
  let data = FixedArray::make(131073, b'x')
  @fs.write_binary(a, Bytes::from_array(data))
  @fs.write_binary(b, Bytes::from_array(data))
  inspect(@snapshot_io.compare(a, b), content="-1")
  data[65536] = 0
  @fs.write_binary(b, Bytes::from_array(data))
  inspect(@snapshot_io.compare(a, b), content="65536")
  @fs.write_binary(b, b"xx")
  inspect(@snapshot_io.compare(a, b), content="2")
  @fs.write_binary(a, b"")
  inspect(@snapshot_io.compare(a, b), content="0")
  @fs.write_binary(b, b"")
  inspect(@snapshot_io.compare(a, b), content="-1")
}
