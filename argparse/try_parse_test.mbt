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
test "try_parse returns matches for ordinary arguments" {
  let cmd = @argparse.Command("demo", flags=[FlagArg("verbose", long="verbose")])
  guard cmd.try_parse(argv=["--verbose"], env=empty_env()) is Parsed(matches) else {
    fail("expected Parsed")
  }
  assert_eq(matches.flags.get("verbose"), Some(true))
}

///|
test "try_parse returns the help text instead of exiting" {
  let cmd = @argparse.Command("demo", about="demo app")
  let expected = cmd.render_help()
  for flag in ["--help", "-h"] {
    guard cmd.try_parse(argv=[flag], env=empty_env()) is Help(text) else {
      fail("expected Help for " + flag)
    }
    assert_eq(text + "\n", expected)
  }
}

///|
test "try_parse returns subcommand help for both help spellings" {
  let cmd = @argparse.Command("demo", subcommands=[
    Command("echo", about="echo text"),
  ])
  guard cmd.try_parse(argv=["help", "echo"], env=empty_env())
    is Help(by_subcommand) else {
    fail("expected Help from help echo")
  }
  guard cmd.try_parse(argv=["echo", "--help"], env=empty_env()) is Help(by_flag) else {
    fail("expected Help from echo --help")
  }
  assert_eq(by_subcommand, by_flag)
  assert_true(by_flag.contains("echo text"))
}

///|
test "try_parse returns help when arguments are required" {
  let cmd = @argparse.Command("demo", arg_required_else_help=true, positionals=[
    PositionArg("file"),
  ])
  assert_true(cmd.try_parse(argv=[], env=empty_env()) is Help(_))
}

///|
test "try_parse returns the version text instead of exiting" {
  let cmd = @argparse.Command("demo", version="1.2.3")
  guard cmd.try_parse(argv=["--version"], env=empty_env()) is Version(text) else {
    fail("expected Version")
  }
  assert_true(text.contains("1.2.3"))
  assert_false(text.has_suffix("\n"))
}

///|
test "try_parse returns help and version for custom flag actions" {
  let cmd = @argparse.Command(
    "demo",
    version="1.2.3",
    disable_help_flag=true,
    disable_version_flag=true,
    flags=[
      FlagArg("show-help", long="show-help", action=Help),
      FlagArg("show-version", long="show-version", action=Version),
    ],
  )
  assert_true(cmd.try_parse(argv=["--show-help"], env=empty_env()) is Help(_))
  assert_true(
    cmd.try_parse(argv=["--show-version"], env=empty_env()) is Version(_),
  )
}

///|
test "try_parse still raises parse errors" {
  let cmd = @argparse.Command("demo")
  let message = @test.expect_error(() => {
    cmd.try_parse(argv=["--bad"], env=empty_env())
  })
  assert_true(message.to_string().contains("unexpected argument '--bad'"))
}
