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
test "a command is a plain, inspectable description" {
  let cmd = @shell.Cmd("git", ["status", "--short"], cwd="workspace", env={
    "NO_COLOR": "1",
  })
  debug_inspect(
    cmd,
    content=(
      #|{
      #|  program: "git",
      #|  arguments: ["status", "--short"],
      #|  cwd: Some("workspace"),
      #|  env: { "NO_COLOR": "1" },
      #|  inherit_env: true,
      #|  stdin: None,
      #|  stdout: Capture,
      #|  stderr: Capture,
      #|}
    ),
  )
}

///|
test "defaults keep a command closed and inherited" {
  let cmd = @shell.Cmd("true", [])
  debug_inspect(
    cmd,
    content=(
      #|{
      #|  program: "true",
      #|  arguments: [],
      #|  cwd: None,
      #|  env: {},
      #|  inherit_env: true,
      #|  stdin: None,
      #|  stdout: Capture,
      #|  stderr: Capture,
      #|}
    ),
  )
}

///|
test "a command does not alias the caller's collections" {
  let arguments = ["status"]
  let env = { "NO_COLOR": "1" }
  let cmd = @shell.Cmd("git", arguments, env~)
  // Mutating what was passed in does not reach the command...
  arguments.push("--short")
  env["NO_COLOR"] = "0"
  debug_inspect(
    cmd,
    content=(
      #|{
      #|  program: "git",
      #|  arguments: ["status"],
      #|  cwd: None,
      #|  env: { "NO_COLOR": "1" },
      #|  inherit_env: true,
      #|  stdin: None,
      #|  stdout: Capture,
      #|  stderr: Capture,
      #|}
    ),
  )
}

///|
async test "invalid plans fail before spawning" {
  try @shell.Cmd("", []).output() catch {
    err =>
      debug_inspect(
        err,
        content=(
          #|EmptyProgram
        ),
      )
  } noraise {
    _ => fail("expected an empty program to raise")
  }
  try @shell.Pipeline([]).output() catch {
    err =>
      debug_inspect(
        err,
        content=(
          #|EmptyPipeline
        ),
      )
  } noraise {
    _ => fail("expected an empty pipeline to raise")
  }
  try
    @shell.Pipeline([
      Cmd("first", []),
      Cmd("second", [], stdin=Text("not allowed")),
    ]).output()
  catch {
    err =>
      debug_inspect(
        err,
        content=(
          #|StdinOnNonFirstStage(1)
        ),
      )
  } noraise {
    _ => fail("expected stdin on a later stage to raise")
  }
  try
    @shell.Pipeline([Cmd("first", [], stdout=ToFile("nope")), Cmd("second", [])]).output()
  catch {
    err =>
      debug_inspect(
        err,
        content=(
          #|RedirectOnNonFinalStage(0)
        ),
      )
  } noraise {
    _ => fail("expected a redirected intermediate stage to raise")
  }
  try @shell.Cmd("cat", [], stdout=Inherit).each_line(_line => ()) catch {
    err =>
      debug_inspect(
        err,
        content=(
          #|StdoutNotCaptured
        ),
      )
  } noraise {
    _ => fail("expected uncaptured line output to raise")
  }
  try @shell.Cmd("cat", ["allowed\u{0000}truncated"]).output() catch {
    err =>
      debug_inspect(
        err,
        content=(
          #|NulByte("argument[0]")
        ),
      )
  } noraise {
    _ => fail("expected a NUL argument to raise")
  }
  try @shell.Cmd("cat", [], stdout=ToFile("bad\u{0000}path")).output() catch {
    err =>
      debug_inspect(
        err,
        content=(
          #|NulByte("standard output path")
        ),
      )
  } noraise {
    _ => fail("expected a NUL redirect path to raise")
  }
  try @shell.Cmd("cat", [], env={ "BAD=NAME": "value" }).output() catch {
    err =>
      debug_inspect(
        err,
        content=(
          #|InvalidEnvironmentName("BAD=NAME")
        ),
      )
  } noraise {
    _ => fail("expected an environment name containing '=' to raise")
  }
  try @shell.Cmd("cat", [], env={ "": "value" }).output() catch {
    err =>
      debug_inspect(
        err,
        content=(
          #|InvalidEnvironmentName("")
        ),
      )
  } noraise {
    _ => fail("expected an empty environment name to raise")
  }
  try @shell.Cmd("cat", []).output(max_output_bytes=0) catch {
    err =>
      debug_inspect(
        err,
        content=(
          #|InvalidOutputLimit(0)
        ),
      )
  } noraise {
    _ => fail("expected a non-positive output limit to raise")
  }
}
