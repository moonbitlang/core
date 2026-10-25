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
async test "an argument reaches the child literally, without a shell" {
  // The needle is full of shell syntax. It arrives as one argv element — on
  // Windows through `@process`'s escaping — or the child cannot select the
  // marker line.
  let needle = "$(echo not-executed) | *"
  let output = @shell.Cmd(
    filter_prog.wait(),
    ["-keep", needle],
    stdin=Text("plain\n\{needle} marker\n"),
  ).output()
  inspect(output.exit_code(), content="0")
  inspect(output.stdout(), content="$(echo not-executed) | * marker\n")
  inspect(output.stderr(), content="")
}

///|
async test "binary bytes cross stdin and capture unharmed" {
  let output = @shell.Cmd(cat_prog.wait(), [], stdin=Binary(b"\x00\xff")).output()
  inspect(output.exit_code(), content="0")
  assert_eq(output.stdout_bytes(), b"\x00\xff")
  // The text field decodes lossily instead of failing the run.
  inspect(output.stdout(), content="\u{0000}�")
}

///|
async test "status returns the exit code without capturing" {
  let sleep = sleep_prog.wait()
  inspect(@shell.Cmd(sleep, ["0"]).status(), content="0")
  inspect(@shell.Cmd(sleep, ["0", "-exit-code", "3"]).status(), content="3")
  // A non-zero exit is a result, not an error — until `check` makes it one.
  let output = @shell.Cmd(sleep, ["0", "-exit-code", "1"]).output()
  inspect(output.exit_code(), content="1")
  try output.check() catch {
    err =>
      debug_inspect(
        err,
        content=(
          #|CommandFailed({ exit_code: 1, stdout: "", stdout_bytes: <Bytes: []>, stderr: "" })
        ),
      )
  } noraise {
    _ => fail("expected a non-zero exit to raise")
  }
  // `run` is the checked form of `status`: quiet on success, an error on a
  // non-zero exit.
  @shell.Cmd(sleep, ["0"]).run()
  try @shell.Cmd(sleep, ["0", "-exit-code", "9"]).run() catch {
    err =>
      debug_inspect(
        err,
        content=(
          #|CommandFailed({ exit_code: 9, stdout: "", stdout_bytes: <Bytes: []>, stderr: "" })
        ),
      )
  } noraise {
    _ => fail("expected a non-zero exit to raise")
  }
}

///|
async test "stdin can be inherited and output discarded" {
  // `Inherit` hands over the parent's own standard input. The child here
  // ignores it, which keeps the test independent of what that input is.
  inspect(
    @shell.Cmd(sleep_prog.wait(), ["0"], stdin=Inherit).status(),
    content="0",
  )
  // `Discard` gives the child a real, writable sink: the whole payload is
  // accepted — a closed or broken descriptor would fail the child — and none
  // of it reaches the capture.
  let output = @shell.Cmd(
    cat_prog.wait(),
    [],
    stdin=Text(distinct_lines(5000)),
    stdout=Discard,
  ).output()
  inspect(output.exit_code(), content="0")
  inspect(output.stdout(), content="")
}

///|
async test "env entries add to, or replace, the inherited environment" {
  let dump_env = dump_env_prog.wait()
  let added = @shell.Cmd(dump_env, [], env={ "SHELL_TEST_MAGIC": "works" }).output()
  assert_true(added.stdout().contains("SHELL_TEST_MAGIC=works"))
  let clean = @shell.Cmd(
    dump_env,
    [],
    env={ "SHELL_TEST_ONLY_1": "one", "SHELL_TEST_ONLY_2": "two" },
    inherit_env=false,
  ).output()
  inspect(
    clean.stdout().replace_all(old="\r\n", new="\n"),
    content=(
      #|SHELL_TEST_ONLY_1=one
      #|SHELL_TEST_ONLY_2=two
      #|
    ),
  )
}

///|
async test "cwd changes where the child runs" {
  let output = @shell.Cmd(
    filter_prog.wait(),
    ["-print-cwd"],
    cwd="async/fs/test_directory/dir1",
  ).output()
  inspect(output.exit_code(), content="0")
  inspect(
    output
    .stdout()
    .trim(char_set="\r\n ")
    .replace_all(old="\\", new="/")
    .has_suffix("async/fs/test_directory/dir1"),
    content="true",
  )
}

///|
async test "stdout can be sent to a file, appended, and read back as stdin" {
  let cat = cat_prog.wait()
  let directory = @fs.tmpdir(prefix="shell-redirect")
  let path = "\{directory}/log.txt"
  @shell.Cmd(cat, [], stdin=Text("one\n"), stdout=ToFile(path)).status()
  |> ignore
  @shell.Cmd(cat, [], stdin=Text("two\n"), stdout=AppendToFile(path)).status()
  |> ignore
  inspect(@fs.read_text(path), content="one\ntwo\n")
  // `ToFile` truncates, so the appended line is gone again.
  @shell.Cmd(cat, [], stdin=Text("three\n"), stdout=ToFile(path)).status()
  |> ignore
  inspect(@fs.read_text(path), content="three\n")
  // `FromFile` is the structured `< path`.
  let back = @shell.Cmd(cat, [], stdin=FromFile(path)).output()
  inspect(back.stdout(), content="three\n")
  @fs.rmdir(directory, recursive=true)
}

///|
async test "a redirected stream is absent from the captured output" {
  let directory = @fs.tmpdir(prefix="shell-redirect-stderr")
  let path = "\{directory}/errors.txt"
  let output = @shell.Cmd(
    cat_prog.wait(),
    ["-stderr"],
    stdin=Text("err\n"),
    stderr=ToFile(path),
  ).output()
  inspect(output.stdout(), content="")
  inspect(output.stderr(), content="")
  inspect(@fs.read_text(path), content="err\n")
  @fs.rmdir(directory, recursive=true)
}

///|
async test "a timeout cancels the run" {
  let sleep = sleep_prog.wait()
  try @shell.Cmd(sleep, ["10000"]).output(timeout_ms=50) catch {
    @async.TimeoutError => ()
    err => fail("unexpected error: \{err}")
  } noraise {
    _ => fail("expected TimeoutError")
  }
  try
    @shell.Pipeline([Cmd(sleep, ["10000"]), Cmd(cat_prog.wait(), [])]).output(
      timeout_ms=50,
    )
  catch {
    @async.TimeoutError => ()
    err => fail("unexpected error: \{err}")
  } noraise {
    _ => fail("expected TimeoutError")
  }
}

///|
async test "capture is bounded across stdout and stderr" {
  let cat = cat_prog.wait()
  let payload = "x".repeat(64)
  try
    @shell.Cmd(cat, [], stdin=Text(payload)).output(max_output_bytes=16)
  catch {
    err => {
      let diagnostic = "\{Repr(err)}"
      assert_true(diagnostic.contains("OutputLimitExceeded"))
      assert_true(diagnostic.contains("limit=16"))
    }
  } noraise {
    _ => fail("expected the output limit to raise")
  }
  // Standard error counts against the same aggregate limit.
  try
    @shell.Cmd(cat, ["-stderr"], stdin=Text(payload)).output(
      max_output_bytes=16,
    )
  catch {
    err => {
      let diagnostic = "\{Repr(err)}"
      assert_true(diagnostic.contains("OutputLimitExceeded"))
      assert_true(diagnostic.contains("limit=16"))
    }
  } noraise {
    _ => fail("expected the output limit to raise")
  }
  // The limit is genuinely aggregate: 12 bytes of stdout and 12 bytes of
  // stderr each fit under 16 alone, and still trip it together.
  try
    @shell.Cmd(
      filter_prog.wait(),
      ["-stderr", "e".repeat(12)],
      stdin=Text("\{"o".repeat(11)}\n"),
    ).output(max_output_bytes=16)
  catch {
    err => {
      let diagnostic = "\{Repr(err)}"
      assert_true(diagnostic.contains("OutputLimitExceeded"))
      assert_true(diagnostic.contains("limit=16"))
    }
  } noraise {
    _ => fail("expected the aggregate output limit to raise")
  }
}

///|
async test "a child that never reads its stdin does not fail the run" {
  // The writer hits a closed pipe as soon as the child exits; that belongs to
  // the run's plumbing, not to its result.
  let output = @shell.Cmd(
    sleep_prog.wait(),
    ["0"],
    stdin=Text("x".repeat(1024 * 1024)),
  ).output(timeout_ms=10000)
  inspect(output.exit_code(), content="0")
}

///|
async test "output larger than a pipe buffer survives intact" {
  // Spans many operating-system pipe buffers; a child that outran a
  // non-blocking reader would abort mid-way and leave a silent prefix.
  let payload = distinct_lines(20000)
  let output = @shell.Cmd(cat_prog.wait(), [], stdin=Text(payload)).output(
    max_output_bytes=32 * 1024 * 1024,
  )
  inspect(output.exit_code(), content="0")
  assert_eq(output.stdout(), payload)
}
