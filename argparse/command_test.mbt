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
fn empty_env() -> Map[String, String] {
  Map([])
}

///|
test "declarative parse basics" {
  let cmd = @argparse.Command(
    "demo",
    flags=[FlagArg("verbose", short='v', long="verbose")],
    options=[OptionArg("count", long="count", env="COUNT")],
    positionals=[PositionArg("name")],
  )
  let matches = cmd.parse(argv=["-v", "--count", "3", "alice"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(matches.flags is { "verbose": true, .. })
  assert_true(matches.values is { "count": ["3"], "name": ["alice"], .. })
  assert_true(
    matches.sources is { "verbose": Argv, "count": Argv, "name": Argv, .. },
  )
}

///|
test "command policies" {
  let help_cmd = @argparse.Command("demo", arg_required_else_help=true)
  inspect(
    help_cmd.render_help(),
    content=(
      #|Usage: demo
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|
    ),
  )

  let sub_cmd = @argparse.Command("demo", subcommand_required=true, subcommands=[
    Command("echo"),
  ])
  inspect(
    sub_cmd.render_help(),
    content=(
      #|Usage: demo <command>
      #|
      #|Commands:
      #|  echo  
      #|  help  Print help for the subcommand(s).
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|
    ),
  )
  try sub_cmd.parse(argv=[], env=empty_env()) catch {
    err =>
      inspect(
        err,
        content=(
          #|error: the following required argument was not provided: 'subcommand'
          #|
          #|Usage: demo <command>
          #|
          #|Commands:
          #|  echo  
          #|  help  Print help for the subcommand(s).
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}
