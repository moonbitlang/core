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
async test "merge multiple" {
  @async_io.with_task_group() <| root => {
    let (r, w) = @process.read_from_process_shared()
    root.spawn_bg(no_wait=true) <| () => {
      defer r.close()
      inspect(r.text.read_all(), content="abcdefgh")
    }
    @async_io.with_task_group() <| group => {
      defer w.close()
      @process.spawn(group, shell, ["-c", "\{write_stdout} abcd"], stdout=w, extra_env={
        "LANG": "en_US.UTF-8",
      })
      |> ignore
      @process.spawn(
        group,
        shell,
        ["-c", "sleep 1; \{write_stdout} efgh"],
        stdout=w,
        extra_env={ "LANG": "en_US.UTF-8" },
      )
      |> ignore
    }
  }
}

///|
async test "redirect to file" {
  let cat = cat.wait()
  @async_io.with_task_group() <| root => {
    let input_file = "_build/process_redirect_test_in.txt"
    let output_file = "_build/process_redirect_test_out.txt"
    root.add_defer(() => @fs.remove(input_file))
    root.add_defer(() => @fs.remove(output_file))
    @fs.write_text(input_file, "abcd")
    let _ = @process.run(
      cat,
      [],
      stdin=@process.redirect_from_file(input_file),
      stdout=@process.redirect_to_file(output_file),
    )
    inspect(@fs.read_text(output_file), content="abcd")
  }
}

///|
async test "merge multiple to file" {
  let output_file = "_build/process_redirect_merge_multiple_test_out.txt"
  defer @fs.remove(output_file)
  let w = @process.redirect_to_file_shared(output_file)
  @async_io.with_task_group <| group => {
    defer w.close()
    let _ = @process.spawn(
      group,
      shell,
      ["-c", "\{write_stdout} abcd"],
      stdout=w,
      extra_env={ "LANG": "en_US.UTF-8" },
    )
    let _ = @process.spawn(
      group,
      shell,
      ["-c", "sleep 1; \{write_stdout} efgh"],
      stdout=w,
      extra_env={ "LANG": "en_US.UTF-8" },
    )
  }
  inspect(
    @fs.read_text(output_file),
    content=(
      #|abcdefgh
    ),
  )
}

///|
async test "merge stdout and stderr" {
  @async_io.with_task_group() <| group => {
    let child = @process.spawn(
      group,
      shell,
      ["-c", "\{write_stdout} abcd; \{write_stderr} efgh"],
      stdout=@process.read_from_process(),
      stderr=@process.duplicate_stdout(),
    )
    defer child.stdout.close()
    inspect(child.stdout.text.read_all(), content="abcdefgh")
  }
}

///|
async test "merge stdout and stderr to file" {
  let output_file = "_build/process_redirect_merge_test_out.txt"
  defer @fs.remove(output_file)
  let _ = @process.run(
    shell,
    ["-c", "\{write_stdout} abcd; \{write_stderr} efgh"],
    stdout=@process.redirect_to_file(output_file),
    stderr=@process.duplicate_stdout(),
  )
  inspect(
    @fs.read_text(output_file),
    content=(
      #|abcdefgh
    ),
  )
}

///|
async test "pipe" {
  @async_io.with_task_group() <| group => {
    let cat = cat.wait()
    let (r, w) = @process.pipe()
    defer r.close()
    defer w.close()
    let child1 = @process.spawn(
      group,
      cat,
      [],
      stdin=@process.write_to_process(),
      stdout=w,
    )
    defer child1.stdin.close()
    let child2 = @process.spawn(
      group,
      cat,
      [],
      stdin=r,
      stdout=@process.read_from_process(),
    )
    defer child2.stdout.close()
    child1.stdin.write(b"abcd")
    debug_inspect(
      child2.stdout.text.read(),
      content=(
        #|Some("abcd")
      ),
    )
    child1.stdin.write(b"xyzw")
    debug_inspect(
      child2.stdout.text.read(),
      content=(
        #|Some("xyzw")
      ),
    )
  }
}
