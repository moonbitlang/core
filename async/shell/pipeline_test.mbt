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
test "a pipeline is a plain, inspectable description" {
  let plan = @shell.Pipeline([Cmd("cat", []), Cmd("sort", [])])
  debug_inspect(
    plan,
    content=(
      #|{
      #|  commands: [
      #|    {
      #|      program: "cat",
      #|      arguments: [],
      #|      cwd: None,
      #|      env: {},
      #|      inherit_env: true,
      #|      stdin: None,
      #|      stdout: Capture,
      #|      stderr: Capture,
      #|    },
      #|    {
      #|      program: "sort",
      #|      arguments: [],
      #|      cwd: None,
      #|      env: {},
      #|      inherit_env: true,
      #|      stdin: None,
      #|      stdout: Capture,
      #|      stderr: Capture,
      #|    },
      #|  ],
      #|}
    ),
  )
}

///|
async test "stages connect by real pipes" {
  let filter = filter_prog.wait()
  let output = @shell.Pipeline([
    Cmd(cat_prog.wait(), [], stdin=Text("alpha\nbeta\ngamma\n")),
    Cmd(filter, ["-keep", "beta"]),
    Cmd(filter, ["-upper"]),
  ]).output()
  inspect(output.exit_code(), content="0")
  inspect(output.stdout(), content="BETA\n")
  inspect(output.stderr(), content="")
}

///|
async test "the pipeline status uses pipefail" {
  let failing = () => {
    @shell.Pipeline([
      Cmd(sleep_prog.wait(), ["0", "-exit-code", "7"]),
      Cmd(cat_prog.wait(), []),
    ])
  }
  let output = failing().output()
  inspect(output.exit_code(), content="7")
  // `status` reports the same rule without capturing anything, and `run` is
  // its checked form.
  inspect(failing().status(), content="7")
  try failing().run() catch {
    err =>
      debug_inspect(
        err,
        content=(
          #|CommandFailed({ exit_code: 7, stdout: "", stdout_bytes: <Bytes: []>, stderr: "" })
        ),
      )
  } noraise {
    _ => fail("expected a non-zero exit to raise")
  }
}

///|
async test "stderr is preserved from every stage" {
  let filter = filter_prog.wait()
  let output = @shell.Pipeline([
    Cmd(
      cat_prog.wait(),
      ["-stderr"],
      stdin=Text("first\nignored: stdout is closed downstream\n"),
    ),
    Cmd(filter, ["-stderr", "second"]),
  ]).output()
  // Stage one sent everything to stderr, so stage two saw no lines at all.
  inspect(output.stdout(), content="")
  inspect(
    output.stderr(),
    content="first\nignored: stdout is closed downstream\nsecond",
  )
}

///|
async test "a large distinct payload crosses every stage unchanged" {
  let cat = cat_prog.wait()
  let payload = distinct_lines(50000)
  let piped = @shell.Pipeline([
    Cmd(cat, [], stdin=Text(payload)),
    Cmd(cat, []),
    Cmd(cat, []),
  ]).output(max_output_bytes=32 * 1024 * 1024)
  // Byte-for-byte, not merely the same length.
  assert_eq(piped.stdout(), payload)
}

///|
async test "a stage may stop reading before its producer finishes" {
  // The consumer takes one line and exits without draining its input. The
  // producer, mid-way through a payload much larger than a pipe buffer, gets
  // an ordinary broken pipe — the pipeline still completes and pipefail
  // reports the cut-off stage.
  let output = @shell.Pipeline([
    Cmd(cat_prog.wait(), [], stdin=Text(distinct_lines(100000))),
    Cmd(filter_prog.wait(), ["-head", "1"]),
  ]).output(timeout_ms=30000)
  inspect(output.stdout(), content="line-0\n")
  assert_true(output.exit_code() != 0)
}

///|
async test "a pipe stays open until its producer reaches EOF" {
  // The producer emits only after a delay. If the runtime closed or leaked
  // either pipe end, the consumer would see EOF early and lose the line, or
  // never see EOF and time out.
  let output = @shell.Pipeline([
    Cmd(sleep_prog.wait(), ["100", "-print-after-sleep", "late line"]),
    Cmd(cat_prog.wait(), []),
  ]).output(timeout_ms=10000)
  inspect(output.exit_code(), content="0")
  inspect(output.stdout().trim(char_set="\r\n"), content="late line")
}

///|
async test "a failing redirect closes every prepared pipe end" {
  // By the time the final stage's stderr file fails to open, the junction,
  // the stdout capture end, and the first stage's stdin all exist. The run
  // must fail with the open error and close them — CI runs with
  // MOONBIT_ASYNC_CHECK_FD_LEAK=1, which turns any leak here into a failure.
  let cat = cat_prog.wait()
  let directory = @fs.tmpdir(prefix="shell-leak")
  let missing = "\{directory}/absent-dir/out.txt"
  try
    @shell.Pipeline([
      Cmd(cat, [], stdin=Text("x\n")),
      Cmd(cat, [], stderr=ToFile(missing)),
    ]).output()
    |> ignore
  catch {
    _ => ()
  } noraise {
    _ => fail("expected the redirect to fail")
  }
  // The single-command shape fails before any spawn at all.
  try
    @shell.Cmd(cat, [], stdin=Text("x\n"), stdout=ToFile(missing)).output()
    |> ignore
  catch {
    _ => ()
  } noraise {
    _ => fail("expected the redirect to fail")
  }
  @fs.rmdir(directory, recursive=true)
}

///|
async test "each_line follows the last stage of a pipeline" {
  let seen = []
  let code = @shell.Pipeline([
    Cmd(cat_prog.wait(), [], stdin=Text("alpha\nbeta\ngamma\n")),
    Cmd(filter_prog.wait(), ["-keep", "mm"]),
  ]).each_line(line => seen.push(line))
  inspect(code, content="0")
  assert_eq(seen, ["gamma"])
}
