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
// The explicit function type checks that parsing requires no raising effect.
test "parse_as_result is non-raising and preserves inputs across calls" {
  let cmd = @argparse.Command("demo", options=[
    OptionArg("name", env="NAME", default_values=["default"]),
  ])
  let parse : (ArrayView[String], Map[String, String]) -> Result[
    @argparse.ParseOutcome,
    Error,
  ] = (argv, env) => cmd.parse_as_result(argv~, env~)
  let argv = ["--name", "cli"]
  let env = { "NAME": "environment" }
  for _ in 0..<2 {
    guard parse(argv, env) is Ok(Parsed(matches)) else {
      fail("expected matches")
    }
    assert_eq(matches.values.get("name"), Some(["cli"]))
    // Mutating a result must not affect the inputs or a later parse.
    matches.values["name"].push("changed")
  }
  debug_inspect(argv, content="[\"--name\", \"cli\"]")
  debug_inspect(env, content="{ \"NAME\": \"environment\" }")
  guard parse([], env) is Ok(Parsed(from_env)) else {
    fail("expected environment value")
  }
  debug_inspect(from_env.values, content="{ \"name\": [\"environment\"] }")
  guard cmd.parse_as_result(argv=[]) is Ok(Parsed(from_default)) else {
    fail("expected default value")
  }
  debug_inspect(from_default.values, content="{ \"name\": [\"default\"] }")
  from_default.values["name"].push("changed")
  guard cmd.parse_as_result(argv=[]) is Ok(Parsed(again)) else {
    fail("expected unchanged default")
  }
  debug_inspect(again.values, content="{ \"name\": [\"default\"] }")
}

///|
test "parse_as_result returns help for all built-in routes" {
  let cmd = @argparse.Command("demo", about="demo app", subcommands=[
    Command("echo", about="echo text"),
  ])
  for flag in ["--help", "-h"] {
    guard cmd.parse_as_result(argv=[flag]) is Ok(Help(text)) else {
      fail("expected help")
    }
    assert_eq(text + "\n", cmd.render_help())
  }
  guard cmd.parse_as_result(argv=["help", "echo"]) is Ok(Help(by_subcommand)) else {
    fail("expected subcommand help")
  }
  guard cmd.parse_as_result(argv=["echo", "--help"]) is Ok(Help(by_flag)) else {
    fail("expected subcommand help")
  }
  inspect(by_subcommand == by_flag, content="true")
  inspect(by_flag.contains("echo text"), content="true")
  let required = @argparse.Command("demo", arg_required_else_help=true)
  inspect(required.parse_as_result(argv=[]) is Ok(Help(_)), content="true")
}

///|
test "parse_as_result returns version and custom display actions" {
  let cmd = @argparse.Command("demo", version="1.2.3")
  for flag in ["--version", "-V"] {
    guard cmd.parse_as_result(argv=[flag]) is Ok(Version(text)) else {
      fail("expected version")
    }
    assert_eq(text, "1.2.3")
  }
  let custom = @argparse.Command(
    "demo",
    version="1.2.3",
    disable_help_flag=true,
    disable_version_flag=true,
    flags=[
      FlagArg("show-help", action=Help),
      FlagArg("show-version", action=Version),
    ],
  )
  inspect(
    custom.parse_as_result(argv=["--show-help"]) is Ok(Help(_)),
    content="true",
  )
  guard custom.parse_as_result(argv=["--show-version"]) is Ok(Version(text)) else {
    fail("expected custom version")
  }
  inspect(text, content="1.2.3")
  let with_newlines = @argparse.Command("demo", version="1.2.3\n\n")
  guard with_newlines.parse_as_result(argv=["--version"]) is Ok(Version(text)) else {
    fail("expected version with a trailing newline")
  }
  inspect(text, content="1.2.3\n")
}

///|
test "parse_as_result returns errors with the same diagnostics as parse" {
  let cmd = @argparse.Command("demo")
  guard cmd.parse_as_result(argv=["--bad"]) is Err(err) else {
    fail("expected parse error")
  }
  let raised = @test.expect_error(() => cmd.parse(argv=["--bad"]))
  inspect(err.to_string() == raised.to_string(), content="true")
  inspect(
    err.to_string().contains("unexpected argument '--bad'"),
    content="true",
  )
  inspect(err.to_string().contains("Usage: demo"), content="true")
  let invalid = @argparse.Command("demo", options=[OptionArg("input", long="")])
  guard invalid.parse_as_result(argv=[]) is Err(err) else {
    fail("expected command-definition error")
  }
  inspect(
    err,
    content="error: command definition validation failed: flag/option args require short/long/env",
  )
}
