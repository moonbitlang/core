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
test "unknown argument keeps suggestion in final message" {
  let cmd = @argparse.Command("demo", flags=[FlagArg("verbose", long="verbose")])

  inspect(
    @test.expect_error(() => cmd.parse(argv=["--verbse"], env=empty_env())),
    content=(
      #|error: unexpected argument '--verbse' found
      #|
      #|  tip: a similar argument exists: '--verbose'
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|  --verbose   
      #|
    ),
  )
}

///|
test "parse error show is readable" {
  let cmd = @argparse.Command(
    "demo",
    flags=[FlagArg("verbose", long="verbose")],
    positionals=[PositionArg("name")],
  )

  inspect(
    @test.expect_error(() => cmd.parse(argv=["--verbse"], env=empty_env())),
    content=(
      #|error: unexpected argument '--verbse' found
      #|
      #|  tip: a similar argument exists: '--verbose'
      #|
      #|Usage: demo [options] [name]
      #|
      #|Arguments:
      #|  name  
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|  --verbose   
      #|
    ),
  )

  inspect(
    @test.expect_error(() => cmd.parse(argv=["alice", "bob"], env=empty_env())),
    content=(
      #|error: unexpected value 'bob' for '<name>' found; no more were expected
      #|
      #|Usage: demo [options] [name]
      #|
      #|Arguments:
      #|  name  
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|  --verbose   
      #|
    ),
  )
}

///|
test "unknown argument suggestions are exposed" {
  let cmd = @argparse.Command("demo", flags=[
    FlagArg("verbose", short='v', long="verbose"),
  ])

  inspect(
    @test.expect_error(() => cmd.parse(argv=["--verbse"], env=empty_env())),
    content=(
      #|error: unexpected argument '--verbse' found
      #|
      #|  tip: a similar argument exists: '--verbose'
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help     Show help information.
      #|  -v, --verbose  
      #|
    ),
  )

  inspect(
    @test.expect_error(() => cmd.parse(argv=["-x"], env=empty_env())),
    content=(
      #|error: unexpected argument '-x' found
      #|
      #|  tip: a similar argument exists: '-v'
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help     Show help information.
      #|  -v, --verbose  
      #|
    ),
  )

  inspect(
    @test.expect_error(() => cmd.parse(argv=["--zzzzzzzzzz"], env=empty_env())),
    content=(
      #|error: unexpected argument '--zzzzzzzzzz' found
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help     Show help information.
      #|  -v, --verbose  
      #|
    ),
  )
}

///|
test "unified error message formatting remains stable" {
  let cmd = @argparse.Command("demo", options=[OptionArg("tag", long="tag")])

  inspect(
    @test.expect_error(() => cmd.parse(argv=["--oops"], env=empty_env())),
    content=(
      #|error: unexpected argument '--oops' found
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help   Show help information.
      #|  --tag <tag>  
      #|
    ),
  )

  inspect(
    @test.expect_error(() => cmd.parse(argv=["--tag"], env=empty_env())),
    content=(
      #|error: a value is required for '--tag' but none was supplied
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help   Show help information.
      #|  --tag <tag>  
      #|
    ),
  )
}

///|
test "unknown short suggestion can be absent" {
  let cmd = @argparse.Command("demo", disable_help_flag=true, options=[
    OptionArg("name", long="name"),
  ])

  inspect(
    @test.expect_error(() => cmd.parse(argv=["-x"], env=empty_env())),
    content=(
      #|error: unexpected argument '-x' found
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  --name <name>  
      #|
    ),
  )
}

///|
test "Debug for argparse enums" {
  @debug.debug_inspect(@argparse.FlagAction::SetTrue, content="SetTrue")
  @debug.debug_inspect(@argparse.FlagAction::Count, content="Count")
  @debug.debug_inspect(@argparse.OptionAction::Set, content="Set")
  @debug.debug_inspect(@argparse.OptionAction::Append, content="Append")
}
