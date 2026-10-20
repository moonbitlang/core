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
async test "run with captured stdout" {
  let result = @process.run(
    shell,
    ["-c", "\{write_stdout} abcd"],
    stdout=@process.read_from_process(),
  )
  inspect(result.exit_code, content="0")
  inspect(result.stdout_text(), content="abcd")
}

///|
async test "run with captured stderr" {
  let result = @process.run(
    shell,
    ["-c", "\{write_stderr} abcd"],
    stderr=@process.read_from_process(),
  )
  inspect(result.exit_code, content="0")
  inspect(result.stderr_text(), content="abcd")
}

///|
async test "run with captured stdout and stderr" {
  let result = @process.run(
    shell,
    [
      "-c",
      "\{write_stdout} ab; \{write_stderr} ab; \{write_stdout} cd; \{write_stderr} cd",
    ],
    stdout=@process.read_from_process(),
    stderr=@process.read_from_process(),
  )
  inspect(result.exit_code, content="0")
  inspect(result.stdout_text(), content="abcd")
  inspect(result.stderr_text(), content="abcd")
}

///|
async test "run with merged stdout and stderr" {
  let result = @process.run(
    shell,
    [
      "-c",
      "\{write_stdout} ab; \{write_stderr} ab; \{write_stdout} cd; \{write_stderr} cd",
    ],
    stdout=@process.read_from_process(),
    stderr=@process.duplicate_stdout(),
  )
  inspect(result.exit_code, content="0")
  inspect(result.stdout_text(), content="ababcdcd")
}

///|
async test "run drains captured output concurrently" {
  let test_prog = cat.wait()
  @async_io.with_task_group() <| group => {
    let (cat_read, we_write) = @process.write_to_process_shared()
    group.spawn_bg() <| () => {
      defer we_write.close()
      let chunk = Bytes::make(1024, 0)
      for _ in 0..<1024 {
        we_write.write(chunk)
      }
    }
    defer cat_read.close()
    let result = @process.run(
      test_prog,
      ["-stderr"],
      stdin=cat_read,
      stdout=@process.read_from_process(),
      stderr=@process.read_from_process(),
    )
    inspect(result.exit_code, content="0")
    inspect(result.stdout_binary().length(), content="0")
    inspect(result.stderr_binary().length(), content="1048576")
  }
}
