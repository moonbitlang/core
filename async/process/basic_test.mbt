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
async test "basic_ls" {
  @async.with_task_group() <| group => {
    let child = @process.spawn(
      group,
      shell,
      ["-c", "\{ls} async/fs/test_directory/dir1"],
      stdout=@process.read_from_process(),
      extra_env={ "LC_ALL": "C" },
    )
    defer child.stdout.close()
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

///|
async test "basic_cat" {
  let cat = cat.wait()
  @async.with_task_group() <| group => {
    let child = @process.spawn(
      group,
      cat,
      [],
      stdin=@process.write_to_process(),
      stdout=@process.read_from_process(),
    )
    group.spawn_bg() <| () => {
      defer child.stdin.close()
      child.stdin.write(b"abcd")
      @async.sleep(50)
      child.stdin.write(b"efgh")
    }
    group.spawn_bg() <| () => {
      defer child.stdout.close()
      inspect(child.stdout.text.read_all(), content="abcdefgh")
    }
  }
}

///|
#cfg(platform="windows")
async test "execute .com file" {
  let result = @process.run("chcp.com", [], stdout=@process.read_from_process())
  let output = result.stdout_binary()
  guard output.strip_suffix(b"\r\n") is Some(output) &&
    output.rev_find(b" ") is Some(index) &&
    index + 1 < output.length() else {
    fail("invalid output format from chcp")
  }
  let _code = @string.parse_int(@utf8.decode(output[index + 1:]))
}

///|
// Currently the Wasm runtime perform extra NUL check on Unix,
// so passing argument with NUL will result in an error,
// hence this test is currently disabled for Wasm1.
// Both behavior (truncation v.s. report error) are acceptable
// for NUL in process arguments, though.
#cfg(target="native")
async test "prevent NUL command injection" {
  let prog = sleep_prog.wait()
  let bad_arg = "abc\u{0000}def"
  let result = @process.run(
    prog,
    ["100", "-print-after-sleep", bad_arg],
    stdout=@process.read_from_process(),
  )
  inspect(result.stdout_text().trim_end(chars="\r\n"), content="abc")
}

///|
#cfg(target="wasm")
let _wasm_unused_string_import : Unit = ignore(() => @string.parse_int(""))
