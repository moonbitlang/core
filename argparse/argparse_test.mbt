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
  let cmd = @argparse.Command(
    "demo",
    flags=[FlagArg("verbose", short='v', long="verbose")],
    options=[OptionArg("count", long="count", env="COUNT")],
    positionals=[PositionalArg("name")],
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
test "long defaults to name when omitted" {
  let cmd = @argparse.Command("demo", flags=[FlagArg("verbose")], options=[
    OptionArg("count"),
  ])
  let matches = cmd.parse(argv=["--verbose", "--count", "3"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(matches.flags is { "verbose": true, .. })
  assert_true(matches.values is { "count": ["3"], .. })
}

///|
test "long empty string disables long alias" {
  let cmd = @argparse.Command(
    "demo",
    flags=[FlagArg("verbose", short='v', long="")],
    options=[OptionArg("count", short='c', long="")],
  )

  let matches = cmd.parse(argv=["-v", "-c", "3"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(matches.flags is { "verbose": true, .. })
  assert_true(matches.values is { "count": ["3"], .. })

  try cmd.parse(argv=["--verbose"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unexpected argument '--verbose' found
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|  -v          
          #|  -c <count>  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["--count", "3"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unexpected argument '--count' found
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|  -v          
          #|  -c <count>  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "declaration order controls positional parsing" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionalArg("first"),
    PositionalArg("second"),
  ])

  let parsed = cmd.parse(argv=["a", "b"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "first": ["a"], "second": ["b"], .. })
}

///|
test "bounded non-last positional remains supported" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionalArg("first", num_args=ValueRange(lower=1, upper=2)),
    PositionalArg("second", required=true),
  ])

  let two = cmd.parse(argv=["a", "b"], env=empty_env()) catch { _ => panic() }
  assert_true(two.values is { "first": ["a"], "second": ["b"], .. })

  let three = cmd.parse(argv=["a", "b", "c"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(three.values is { "first": ["a", "b"], "second": ["c"], .. })
}

///|
test "negatable flag preserves false state" {
  let cmd = @argparse.Command("demo", flags=[
    FlagArg("cache", long="cache", negatable=true),
  ])

  let no_cache = cmd.parse(argv=["--no-cache"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(no_cache.flags is { "cache": false, .. })
  assert_true(no_cache.flag_counts.get("cache") is None)
}

///|
test "parse failure message contains error and contextual help" {
  let cmd = @argparse.Command("demo", options=[
    OptionArg("count", long="count", about="repeat count"),
  ])

  try cmd.parse(argv=["--bad"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unexpected argument '--bad' found
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help       Show help information.
          #|  --count <count>  repeat count
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "subcommand parse errors include subcommand help" {
  let cmd = @argparse.Command("demo", subcommands=[
    Command("echo", options=[OptionArg("times", long="times")]),
  ])

  try cmd.parse(argv=["echo", "--bad"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unexpected argument '--bad' found
          #|
          #|Usage: demo echo [options]
          #|
          #|Options:
          #|  -h, --help       Show help information.
          #|  --times <times>  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "build errors are surfaced as ArgError message with help" {
  let cmd = @argparse.Command("demo", flags=[
    FlagArg("fast", long="fast", requires=["missing"]),
  ])

  try cmd.parse(argv=[], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unknown requires target: fast -> missing
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|  --fast      
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "unknown argument keeps suggestion in final message" {
  let cmd = @argparse.Command("demo", flags=[FlagArg("verbose", long="verbose")])

  try cmd.parse(argv=["--verbse"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
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
  } noraise {
    _ => panic()
  }
}

///|
test "render_help remains available for pure formatting" {
  let cmd = @argparse.Command(
    "demo",
    about="Demo command",
    flags=[FlagArg("verbose", short='v', long="verbose")],
    options=[OptionArg("count", long="count")],
    positionals=[PositionalArg("name")],
    subcommands=[Command("echo")],
  )

  let help = cmd.render_help()
  assert_true(help.contains("Usage: demo [options] [name] [command]"))
  assert_true(help.contains("Commands:"))
  assert_true(help.contains("Options:"))
}

///|
test "display help and version" {
  let cmd = @argparse.Command("demo", about="demo app", version="1.2.3")

  inspect(
    cmd.render_help(),
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

  try cmd.parse(argv=["--oops"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unexpected argument '--oops' found
          #|
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
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "parse error show is readable" {
  let cmd = @argparse.Command(
    "demo",
    flags=[FlagArg("verbose", long="verbose")],
    positionals=[PositionalArg("name")],
  )

  try cmd.parse(argv=["--verbse"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
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
    _ => panic()
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["alice", "bob"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: too many positional arguments were provided
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
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "relationships and num args" {
  let requires_cmd = @argparse.Command("demo", options=[
    OptionArg("mode", long="mode", requires=["config"]),
    OptionArg("config", long="config"),
  ])

  try requires_cmd.parse(argv=["--mode", "fast"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: the following required argument was not provided: 'config'
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help         Show help information.
          #|  --mode <mode>      
          #|  --config <config>  
          #|
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  let appended = @argparse.Command("demo", options=[
    OptionArg("tag", long="tag", action=Append),
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
    flags=[FlagArg("fast", long="fast"), FlagArg("slow", long="slow")],
  )

  try cmd.parse(argv=[], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: the following required argument group was not provided: 'mode'
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|  --fast      
          #|  --slow      
          #|
          #|Groups:
          #|  mode (required, exclusive)  --fast, --slow
          #|
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["--fast", "--slow"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: group conflict mode
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|  --fast      
          #|  --slow      
          #|
          #|Groups:
          #|  mode (required, exclusive)  --fast, --slow
          #|
        ),
      )
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
    flags=[FlagArg("fast", long="fast"), FlagArg("json", long="json")],
  )

  try requires_cmd.parse(argv=["--fast"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: the following required argument group was not provided: 'output'
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|  --fast      
          #|  --json      
          #|
          #|Groups:
          #|  mode    --fast
          #|  output  --json
          #|
        ),
      )
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
    flags=[FlagArg("fast", long="fast"), FlagArg("json", long="json")],
  )

  try conflict_cmd.parse(argv=["--fast", "--json"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: group conflict mode conflicts with output
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|  --fast      
          #|  --json      
          #|
          #|Groups:
          #|  mode    --fast
          #|  output  --json
          #|
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "subcommand parsing" {
  let echo = @argparse.Command("echo", positionals=[PositionalArg("msg")])
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
    flags=[
      FlagArg("verbose", short='v', long="verbose", about="Enable verbose mode"),
    ],
    options=[
      OptionArg("count", long="count", about="Repeat count", default_values=[
        "1",
      ]),
    ],
    positionals=[PositionalArg("name", about="Target name")],
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
  let cmd = @argparse.Command("demo", options=[
    OptionArg("level", long="level", env="LEVEL", default_values=["1"]),
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
  let cmd = @argparse.Command("demo", options=[
    OptionArg("count", long="count", env="COUNT"),
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
    options=[
      OptionArg("count", short='c', long="count"),
      OptionArg("tag", long="tag", action=Append),
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
  let cmd = @argparse.Command("demo", flags=[
    FlagArg("cache", long="cache", negatable=true),
    FlagArg("failfast", long="failfast", action=SetFalse, negatable=true),
    FlagArg("verbose", long="verbose", conflicts_with=["quiet"]),
    FlagArg("quiet", long="quiet"),
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
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: conflicting arguments: verbose and quiet
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help       Show help information.
          #|  --[no-]cache     
          #|  --[no-]failfast  
          #|  --verbose        
          #|  --quiet          
          #|
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "flag does not accept inline value" {
  let cmd = @argparse.Command("demo", flags=[FlagArg("verbose", long="verbose")])
  try cmd.parse(argv=["--verbose=true"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unexpected argument '--verbose=true' found
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|  --verbose   
          #|
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "built-in long flags do not accept inline value" {
  let cmd = @argparse.Command("demo", version="1.2.3")

  try cmd.parse(argv=["--help=1"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unexpected argument '--help=1' found
          #|
          #|Usage: demo
          #|
          #|Options:
          #|  -h, --help     Show help information.
          #|  -V, --version  Show version information.
          #|
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["--version=1"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unexpected argument '--version=1' found
          #|
          #|Usage: demo
          #|
          #|Options:
          #|  -h, --help     Show help information.
          #|  -V, --version  Show version information.
          #|
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
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
    Message(msg) =>
      inspect(
        msg,
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
    _ => panic()
  } noraise {
    _ => panic()
  }
}
