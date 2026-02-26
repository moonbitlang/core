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
  {}
}

///|
test "declarative parse basics" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.FlagArg("verbose", short='v', long="verbose"),
    @argparse.OptionArg("count", long="count", env="COUNT"),
    @argparse.PositionalArg("name", index=0),
  ])
  let matches = cmd.parse(argv=["-v", "--count", "3", "alice"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(matches.flags is { "verbose": true, .. })
  assert_true(matches.values is { "count": ["3"], "name": ["alice"], .. })
}

///|
test "display help and version" {
  let cmd = @argparse.Command("demo", about="demo app", version="1.2.3")

  let mut help = ""
  try cmd.parse(argv=["-h"], env=empty_env()) catch {
    @argparse.DisplayHelp::Message(text) => help = text
    _ => panic()
  } noraise {
    _ => panic()
  }
  inspect(
    help,
    content=(
      #|Usage: demo
      #|
      #|demo app
      #|
      #|Options:
      #|  -h, --help     Show help information.
      #|  -V, --version  Show version information.
      #|
    ),
  )
  let mut version = ""
  try cmd.parse(argv=["--version"], env=empty_env()) catch {
    @argparse.DisplayVersion::Message(text) => version = text
    _ => panic()
  } noraise {
    _ => panic()
  }
  inspect(version, content="1.2.3")
}

///|
test "parse error show is readable" {
  inspect(
    @argparse.ArgParseError::UnknownArgument("--verbse", Some("--verbose")).to_string(),
    content=(
      #|error: unexpected argument '--verbse' found
      #|
      #|  tip: a similar argument exists: '--verbose'
    ),
  )
  inspect(
    @argparse.ArgParseError::TooManyPositionals.to_string(),
    content=(
      #|error: too many positional arguments were provided
    ),
  )
}

///|
test "relationships and num args" {
  let requires_cmd = @argparse.Command("demo", args=[
    @argparse.OptionArg("mode", long="mode", requires=["config"]),
    @argparse.OptionArg("config", long="config"),
  ])

  try requires_cmd.parse(argv=["--mode", "fast"], env=empty_env()) catch {
    @argparse.ArgParseError::MissingRequired(name) =>
      inspect(name, content="config")
    _ => panic()
  } noraise {
    _ => panic()
  }

  let appended = @argparse.Command("demo", args=[
    @argparse.OptionArg("tag", long="tag", action=Append),
  ]).parse(argv=["--tag", "a", "--tag", "b", "--tag", "c"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(appended.values is { "tag": ["a", "b", "c"], .. })
}

///|
test "arg groups required and multiple" {
  let cmd = @argparse.Command(
    "demo",
    groups=[
      ArgGroup("mode", required=true, multiple=false, args=["fast", "slow"]),
    ],
    args=[
      @argparse.FlagArg("fast", long="fast"),
      @argparse.FlagArg("slow", long="slow"),
    ],
  )

  try cmd.parse(argv=[], env=empty_env()) catch {
    @argparse.ArgParseError::MissingGroup(name) => inspect(name, content="mode")
    _ => panic()
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["--fast", "--slow"], env=empty_env()) catch {
    @argparse.ArgParseError::GroupConflict(name) =>
      inspect(name, content="mode")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "arg groups requires and conflicts" {
  let requires_cmd = @argparse.Command(
    "demo",
    groups=[
      ArgGroup("mode", args=["fast"], requires=["output"]),
      ArgGroup("output", args=["json"]),
    ],
    args=[
      @argparse.FlagArg("fast", long="fast"),
      @argparse.FlagArg("json", long="json"),
    ],
  )

  try requires_cmd.parse(argv=["--fast"], env=empty_env()) catch {
    @argparse.ArgParseError::MissingGroup(name) =>
      inspect(name, content="output")
    _ => panic()
  } noraise {
    _ => panic()
  }

  let conflict_cmd = @argparse.Command(
    "demo",
    groups=[
      ArgGroup("mode", args=["fast"], conflicts_with=["output"]),
      ArgGroup("output", args=["json"]),
    ],
    args=[
      @argparse.FlagArg("fast", long="fast"),
      @argparse.FlagArg("json", long="json"),
    ],
  )

  try conflict_cmd.parse(argv=["--fast", "--json"], env=empty_env()) catch {
    @argparse.ArgParseError::GroupConflict(msg) =>
      inspect(
        msg,
        content=(
          #|mode conflicts with output
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "subcommand parsing" {
  let echo = @argparse.Command("echo", args=[
    @argparse.PositionalArg("msg", index=0),
  ])
  let root = @argparse.Command("root", subcommands=[echo])

  let matches = root.parse(argv=["echo", "hi"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(
    matches.subcommand is Some(("echo", sub)) &&
    sub.values is { "msg": ["hi"], .. },
  )
}

///|
test "full help snapshot" {
  let cmd = @argparse.Command(
    "demo",
    about="Demo command",
    args=[
      @argparse.FlagArg(
        "verbose",
        short='v',
        long="verbose",
        about="Enable verbose mode",
      ),
      @argparse.OptionArg("count", long="count", about="Repeat count", default_values=[
        "1",
      ]),
      @argparse.PositionalArg("name", index=0, about="Target name"),
    ],
    subcommands=[Command("echo", about="Echo a message")],
  )
  inspect(
    cmd.render_help(),
    content=(
      #|Usage: demo [options] [name] [command]
      #|
      #|Demo command
      #|
      #|Commands:
      #|  echo  Echo a message
      #|  help  Print help for the subcommand(s).
      #|
      #|Arguments:
      #|  name  Target name
      #|
      #|Options:
      #|  -h, --help       Show help information.
      #|  -v, --verbose    Enable verbose mode
      #|  --count <count>  Repeat count (default: 1)
      #|
    ),
  )
}

///|
test "value source precedence argv env default" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.OptionArg("level", long="level", env="LEVEL", default_values=["1"]),
  ])

  let from_default = cmd.parse(argv=[], env=empty_env()) catch { _ => panic() }
  assert_true(from_default.values is { "level": ["1"], .. })
  assert_true(from_default.sources is { "level": Default, .. })

  let from_env = cmd.parse(argv=[], env={ "LEVEL": "2" }) catch { _ => panic() }
  assert_true(from_env.values is { "level": ["2"], .. })
  assert_true(from_env.sources is { "level": Env, .. })

  let from_argv = cmd.parse(argv=["--level", "3"], env={ "LEVEL": "2" }) catch {
    _ => panic()
  }
  assert_true(from_argv.values is { "level": ["3"], .. })
  assert_true(from_argv.sources is { "level": Argv, .. })
}

///|
test "omitted env does not read process environment by default" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.OptionArg("count", long="count", env="COUNT"),
  ])
  let matches = cmd.parse(argv=[]) catch { _ => panic() }
  assert_true(matches.values is { "count"? : None, .. })
  assert_true(matches.sources is { "count"? : None, .. })
}

///|
test "options and multiple values" {
  let serve = @argparse.Command("serve")
  let cmd = @argparse.Command(
    "demo",
    args=[
      @argparse.OptionArg("count", short='c', long="count"),
      @argparse.OptionArg("tag", long="tag", action=Append),
    ],
    subcommands=[serve],
  )

  let long_count = cmd.parse(argv=["--count", "2"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(long_count.values is { "count": ["2"], .. })

  let short_count = cmd.parse(argv=["-c", "3"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(short_count.values is { "count": ["3"], .. })

  let multi = cmd.parse(argv=["--tag", "a", "--tag", "b"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(multi.values is { "tag": ["a", "b"], .. })

  let subcommand = cmd.parse(argv=["serve"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(subcommand.subcommand is Some(("serve", _)))
}

///|
test "negatable and conflicts" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.FlagArg("cache", long="cache", negatable=true),
    @argparse.FlagArg(
      "failfast",
      long="failfast",
      action=SetFalse,
      negatable=true,
    ),
    @argparse.FlagArg("verbose", long="verbose", conflicts_with=["quiet"]),
    @argparse.FlagArg("quiet", long="quiet"),
  ])

  let no_cache = cmd.parse(argv=["--no-cache"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(no_cache.flags is { "cache": false, .. })
  assert_true(no_cache.sources is { "cache": Argv, .. })

  let no_failfast = cmd.parse(argv=["--no-failfast"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(no_failfast.flags is { "failfast": true, .. })

  try cmd.parse(argv=["--verbose", "--quiet"], env=empty_env()) catch {
    @argparse.ArgParseError::InvalidArgument(msg) =>
      inspect(
        msg,
        content=(
          #|conflicting arguments: verbose and quiet
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "flag does not accept inline value" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.FlagArg("verbose", long="verbose"),
  ])
  try cmd.parse(argv=["--verbose=true"], env=empty_env()) catch {
    @argparse.ArgParseError::InvalidArgument(arg) =>
      inspect(arg, content="--verbose=true")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "built-in long flags do not accept inline value" {
  let cmd = @argparse.Command("demo", version="1.2.3")

  try cmd.parse(argv=["--help=1"], env=empty_env()) catch {
    @argparse.ArgParseError::InvalidArgument(arg) =>
      inspect(arg, content="--help=1")
    _ => panic()
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["--version=1"], env=empty_env()) catch {
    @argparse.ArgParseError::InvalidArgument(arg) =>
      inspect(arg, content="--version=1")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "command policies" {
  let help_cmd = @argparse.Command("demo", arg_required_else_help=true)
  try help_cmd.parse(argv=[], env=empty_env()) catch {
    @argparse.DisplayHelp::Message(text) =>
      inspect(
        text,
        content=(
          #|Usage: demo
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  let sub_cmd = @argparse.Command("demo", subcommand_required=true, subcommands=[
    Command("echo"),
  ])
  assert_true(sub_cmd.render_help().has_prefix("Usage: demo <command>"))
  try sub_cmd.parse(argv=[], env=empty_env()) catch {
    @argparse.ArgParseError::MissingRequired(name) =>
      inspect(name, content="subcommand")
    _ => panic()
  } noraise {
    _ => panic()
  }
}
