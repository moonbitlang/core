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
test "render help snapshot with groups and hidden entries" {
  let cmd = @argparse.Command(
    "render",
    groups=[
      ArgGroup("mode", required=true, multiple=false, args=[
        "fast", "slow", "path",
      ]),
    ],
    subcommands=[
      Command("run", about="run"),
      Command("hidden", about="hidden", hidden=true),
    ],
    flags=[
      FlagArg("fast", short='f', long="fast"),
      FlagArg("slow", long="slow", hidden=true),
      FlagArg("cache", long="cache", negatable=true, about="cache"),
    ],
    options=[
      OptionArg(
        "path",
        short='p',
        long="path",
        env="PATH_ENV",
        default_values=["a", "b"],
        required=true,
      ),
    ],
    positionals=[
      PositionalArg("target", required=true),
      PositionalArg("rest", num_args=ValueRange(lower=0)),
      PositionalArg("secret", hidden=true),
    ],
  )
  inspect(
    cmd.render_help(),
    content=(
      #|Usage: render [options] <target> [rest...] [command]
      #|
      #|Commands:
      #|  run   run
      #|  help  Print help for the subcommand(s).
      #|
      #|Arguments:
      #|  target   required
      #|  rest...  
      #|
      #|Options:
      #|  -h, --help         Show help information.
      #|  -f, --fast         
      #|  --[no-]cache       cache
      #|  -p, --path <path>  env: PATH_ENV, defaults: a, b, required
      #|
      #|Groups:
      #|  mode (required, exclusive)  -f, --fast, -p, --path <path>
      #|
    ),
  )
}

///|
test "render help conversion coverage snapshot" {
  let cmd = @argparse.Command(
    "shape",
    groups=[ArgGroup("grp", args=["f", "opt", "pos"])],
    flags=[
      FlagArg(
        "f",
        short='f',
        about="f",
        env="F_ENV",
        requires=["opt"],
        required=true,
        global=true,
        hidden=true,
      ),
    ],
    options=[
      OptionArg(
        "opt",
        short='o',
        about="opt",
        default_values=["x", "y"],
        env="OPT_ENV",
        allow_hyphen_values=true,
        required=true,
        global=true,
        hidden=true,
        conflicts_with=["pos"],
      ),
    ],
    positionals=[
      PositionalArg(
        "pos",
        about="pos",
        env="POS_ENV",
        default_values=["p1", "p2"],
        num_args=ValueRange(lower=0, upper=2),
        allow_hyphen_values=true,
        last=true,
        requires=["opt"],
        conflicts_with=["f"],
        required=true,
        global=true,
        hidden=true,
      ),
    ],
  )
  inspect(
    cmd.render_help(),
    content=(
      #|Usage: shape
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|
    ),
  )
}

///|
test "count flags and sources with pattern matching" {
  let cmd = @argparse.Command("demo", flags=[
    FlagArg("verbose", short='v', long="verbose", action=Count),
  ])
  let matches = cmd.parse(argv=["-v", "-v", "-v"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(matches.flags is { "verbose": true, .. })
  assert_true(matches.flag_counts is { "verbose": 3, .. })
  assert_true(matches.sources is { "verbose": Argv, .. })
}

///|
test "global option merges parent and child values" {
  let child = @argparse.Command("run")
  let cmd = @argparse.Command(
    "demo",
    options=[
      OptionArg(
        "profile",
        short='p',
        long="profile",
        action=Append,
        global=true,
      ),
    ],
    subcommands=[child],
  )

  let matches = cmd.parse(
    argv=["--profile", "parent", "run", "--profile", "child"],
    env=empty_env(),
  ) catch {
    _ => panic()
  }
  assert_true(matches.values is { "profile": ["parent", "child"], .. })
  assert_true(matches.sources is { "profile": Argv, .. })
  assert_true(
    matches.subcommand is Some(("run", sub)) &&
    sub.values is { "profile": ["parent", "child"], .. },
  )
}

///|
test "global requires is validated after parent-child merge" {
  let cmd = @argparse.Command(
    "demo",
    options=[
      OptionArg("mode", long="mode", requires=["config"], global=true),
      OptionArg("config", long="config", global=true),
    ],
    subcommands=[Command("run")],
  )

  let parsed = cmd.parse(
    argv=["--config", "a.toml", "run", "--mode", "fast"],
    env=empty_env(),
  ) catch {
    _ => panic()
  }
  assert_true(
    parsed.values is { "config": ["a.toml"], "mode": ["fast"], .. } &&
    parsed.subcommand is Some(("run", sub)) &&
    sub.values is { "config": ["a.toml"], "mode": ["fast"], .. },
  )
}

///|
test "global append keeps parent argv over child env/default" {
  let child = @argparse.Command("run")
  let cmd = @argparse.Command(
    "demo",
    options=[
      OptionArg(
        "profile",
        long="profile",
        action=Append,
        env="PROFILE",
        default_values=["def"],
        global=true,
      ),
    ],
    subcommands=[child],
  )

  let matches = cmd.parse(argv=["--profile", "parent", "run"], env={
    "PROFILE": "env",
  }) catch {
    _ => panic()
  }
  assert_true(matches.values is { "profile": ["parent"], .. })
  assert_true(matches.sources is { "profile": Argv, .. })
  assert_true(
    matches.subcommand is Some(("run", sub)) &&
    sub.values is { "profile": ["parent"], .. } &&
    sub.sources is { "profile": Argv, .. },
  )
}

///|
test "global scalar keeps parent argv over child env/default" {
  let child = @argparse.Command("run")
  let cmd = @argparse.Command(
    "demo",
    options=[
      OptionArg(
        "profile",
        long="profile",
        env="PROFILE",
        default_values=["def"],
        global=true,
      ),
    ],
    subcommands=[child],
  )

  let matches = cmd.parse(argv=["--profile", "parent", "run"], env={
    "PROFILE": "env",
  }) catch {
    _ => panic()
  }
  assert_true(matches.values is { "profile": ["parent"], .. })
  assert_true(matches.sources is { "profile": Argv, .. })
  assert_true(
    matches.subcommand is Some(("run", sub)) &&
    sub.values is { "profile": ["parent"], .. } &&
    sub.sources is { "profile": Argv, .. },
  )
}

///|
test "global count merges parent and child occurrences" {
  let child = @argparse.Command("run")
  let cmd = @argparse.Command(
    "demo",
    flags=[
      FlagArg("verbose", short='v', long="verbose", action=Count, global=true),
    ],
    subcommands=[child],
  )

  let matches = cmd.parse(argv=["-v", "run", "-v", "-v"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(matches.flag_counts is { "verbose": 3, .. })
  assert_true(
    matches.subcommand is Some(("run", sub)) &&
    sub.flag_counts is { "verbose": 3, .. },
  )
}

///|
test "global count keeps parent argv over child env fallback" {
  let child = @argparse.Command("run")
  let cmd = @argparse.Command(
    "demo",
    flags=[
      FlagArg(
        "verbose",
        short='v',
        long="verbose",
        action=Count,
        env="VERBOSE",
        global=true,
      ),
    ],
    subcommands=[child],
  )

  let matches = cmd.parse(argv=["-v", "run"], env={ "VERBOSE": "1" }) catch {
    _ => panic()
  }
  assert_true(matches.flag_counts is { "verbose": 1, .. })
  assert_true(matches.sources is { "verbose": Argv, .. })
  assert_true(
    matches.subcommand is Some(("run", sub)) &&
    sub.flag_counts is { "verbose": 1, .. } &&
    sub.sources is { "verbose": Argv, .. },
  )
}

///|
test "global flag keeps parent argv over child env fallback" {
  let child = @argparse.Command("run")
  let cmd = @argparse.Command(
    "demo",
    flags=[FlagArg("verbose", long="verbose", env="VERBOSE", global=true)],
    subcommands=[child],
  )

  let matches = cmd.parse(argv=["--verbose", "run"], env={ "VERBOSE": "0" }) catch {
    _ => panic()
  }
  assert_true(matches.flags is { "verbose": true, .. })
  assert_true(matches.sources is { "verbose": Argv, .. })
  assert_true(
    matches.subcommand is Some(("run", sub)) &&
    sub.flags is { "verbose": true, .. } &&
    sub.sources is { "verbose": Argv, .. },
  )
}

///|
test "subcommand cannot follow positional arguments" {
  let cmd = @argparse.Command("demo", positionals=[PositionalArg("input")], subcommands=[
    Command("run"),
  ])
  try cmd.parse(argv=["raw", "run"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: subcommand 'run' cannot be used with positional arguments
          #|
          #|Usage: demo [input] [command]
          #|
          #|Commands:
          #|  run   
          #|  help  Print help for the subcommand(s).
          #|
          #|Arguments:
          #|  input  
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

///|
test "global count source keeps env across subcommand merge" {
  let child = @argparse.Command("run")
  let cmd = @argparse.Command(
    "demo",
    flags=[
      FlagArg(
        "verbose",
        short='v',
        long="verbose",
        action=Count,
        env="VERBOSE",
        global=true,
      ),
    ],
    subcommands=[child],
  )

  let matches = cmd.parse(argv=["run"], env={ "VERBOSE": "1" }) catch {
    _ => panic()
  }
  assert_true(matches.flags is { "verbose": true, .. })
  assert_true(matches.flag_counts is { "verbose": 1, .. })
  assert_true(matches.sources is { "verbose": Env, .. })
  assert_true(
    matches.subcommand is Some(("run", sub)) &&
    sub.flag_counts is { "verbose": 1, .. } &&
    sub.sources is { "verbose": Env, .. },
  )
}

///|
test "help subcommand styles and errors" {
  let leaf = @argparse.Command("echo", about="echo")
  let cmd = @argparse.Command("demo", subcommands=[leaf])

  inspect(
    leaf.render_help(),
    content=(
      #|Usage: echo
      #|
      #|echo
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|
    ),
  )
  inspect(
    cmd.render_help(),
    content=(
      #|Usage: demo [command]
      #|
      #|Commands:
      #|  echo  echo
      #|  help  Print help for the subcommand(s).
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|
    ),
  )

  try cmd.parse(argv=["help", "--bad"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unexpected help argument: --bad
          #|
          #|Usage: demo [command]
          #|
          #|Commands:
          #|  echo  echo
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

  try cmd.parse(argv=["help", "missing"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unknown subcommand: missing
          #|
          #|Usage: demo [command]
          #|
          #|Commands:
          #|  echo  echo
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

///|
test "subcommand help includes inherited global options" {
  let leaf = @argparse.Command("echo", about="echo")
  let cmd = @argparse.Command(
    "demo",
    flags=[
      FlagArg(
        "verbose",
        short='v',
        long="verbose",
        about="Enable verbose mode",
        global=true,
      ),
    ],
    subcommands=[leaf],
  )

  try cmd.parse(argv=["echo", "--bad"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unexpected argument '--bad' found
          #|
          #|Usage: demo echo [options]
          #|
          #|echo
          #|
          #|Options:
          #|  -h, --help     Show help information.
          #|  -v, --verbose  Enable verbose mode
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "unknown argument suggestions are exposed" {
  let cmd = @argparse.Command("demo", flags=[
    FlagArg("verbose", short='v', long="verbose"),
  ])

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
          #|  -h, --help     Show help information.
          #|  -v, --verbose  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["-x"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
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
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["--zzzzzzzzzz"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
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
  } noraise {
    _ => panic()
  }
}

///|
test "long and short value parsing branches" {
  let cmd = @argparse.Command("demo", options=[
    OptionArg("count", short='c', long="count"),
  ])

  let long_inline = cmd.parse(argv=["--count=2"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(long_inline.values is { "count": ["2"], .. })

  let short_inline = cmd.parse(argv=["-c=3"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(short_inline.values is { "count": ["3"], .. })

  let short_attached = cmd.parse(argv=["-c4"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(short_attached.values is { "count": ["4"], .. })

  try cmd.parse(argv=["--count"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: a value is required for '--count' but none was supplied
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help           Show help information.
          #|  -c, --count <count>  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["-c"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: a value is required for '-c' but none was supplied
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help           Show help information.
          #|  -c, --count <count>  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "append option action is publicly selectable" {
  let cmd = @argparse.Command("demo", options=[
    OptionArg("tag", long="tag", action=Append),
  ])
  let appended = cmd.parse(argv=["--tag", "a", "--tag", "b"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(appended.values is { "tag": ["a", "b"], .. })
  assert_true(appended.sources is { "tag": Argv, .. })
}

///|
test "negation parsing and invalid negation forms" {
  let cmd = @argparse.Command(
    "demo",
    flags=[FlagArg("cache", long="cache", negatable=true)],
    options=[OptionArg("path", long="path")],
  )

  let off = cmd.parse(argv=["--no-cache"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(off.flags is { "cache": false, .. })
  assert_true(off.sources is { "cache": Argv, .. })

  try cmd.parse(argv=["--no-path"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unexpected argument '--no-path' found
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help     Show help information.
          #|  --[no-]cache   
          #|  --path <path>  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["--no-missing"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unexpected argument '--no-missing' found
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help     Show help information.
          #|  --[no-]cache   
          #|  --path <path>  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["--no-cache=1"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unexpected argument '--no-cache=1' found
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help     Show help information.
          #|  --[no-]cache   
          #|  --path <path>  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  let count_cmd = @argparse.Command("demo", flags=[
    FlagArg("verbose", long="verbose", action=Count, negatable=true),
  ])
  let reset = count_cmd.parse(
    argv=["--verbose", "--no-verbose"],
    env=empty_env(),
  ) catch {
    _ => panic()
  }
  assert_true(reset.flags is { "verbose": false, .. })
  assert_true(reset.flag_counts is { "verbose"? : None, .. })
  assert_true(reset.sources is { "verbose": Argv, .. })
}

///|
test "positionals force mode and dash handling" {
  let force_cmd = @argparse.Command("demo", positionals=[
    PositionalArg(
      "tail",
      num_args=ValueRange(lower=0),
      last=true,
      allow_hyphen_values=true,
    ),
  ])
  let forced = force_cmd.parse(argv=["a", "--x", "-y"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(forced.values is { "tail": ["a", "--x", "-y"], .. })

  let dashed = force_cmd.parse(argv=["--", "p", "q"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(dashed.values is { "tail": ["p", "q"], .. })

  let negative_cmd = @argparse.Command("demo", positionals=[PositionalArg("n")])
  let negative = negative_cmd.parse(argv=["-9"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(negative.values is { "n": ["-9"], .. })

  try negative_cmd.parse(argv=["x", "y"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: too many positional arguments were provided
          #|
          #|Usage: demo [n]
          #|
          #|Arguments:
          #|  n  
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

///|
test "variadic positional keeps accepting hyphen values after first token" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionalArg(
      "tail",
      num_args=ValueRange(lower=0),
      allow_hyphen_values=true,
    ),
  ])
  let parsed = cmd.parse(argv=["a", "-b", "--mystery"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "tail": ["a", "-b", "--mystery"], .. })
}

///|
test "bounded positional does not greedily consume later required values" {
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
test "indexed non-last positional allows explicit single num_args" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionalArg("first", num_args=@argparse.ValueRange::single()),
    PositionalArg("second", required=true),
  ])

  let parsed = cmd.parse(argv=["a", "b"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "first": ["a"], "second": ["b"], .. })
}

///|
test "empty positional value range is rejected at build time" {
  try
    @argparse.Command("demo", positionals=[
      PositionalArg("skip", num_args=ValueRange(lower=0, upper=0)),
      PositionalArg("name", required=true),
    ]).parse(argv=["alice"], env=empty_env())
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: empty value range (0..0) is unsupported
          #|
          #|Usage: demo [skip] <name>
          #|
          #|Arguments:
          #|  skip  
          #|  name  required
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

///|
test "env parsing for settrue setfalse count and invalid values" {
  let cmd = @argparse.Command("demo", flags=[
    FlagArg("on", long="on", action=SetTrue, env="ON"),
    FlagArg("off", long="off", action=SetFalse, env="OFF"),
    FlagArg("v", long="v", action=Count, env="V"),
  ])

  let parsed = cmd.parse(argv=[], env={ "ON": "true", "OFF": "true", "V": "3" }) catch {
    _ => panic()
  }
  assert_true(parsed.flags is { "on": true, "off": false, "v": true, .. })
  assert_true(parsed.flag_counts is { "v": 3, .. })
  assert_true(parsed.sources is { "on": Env, "off": Env, "v": Env, .. })

  try cmd.parse(argv=[], env={ "ON": "bad" }) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: invalid value 'bad' for boolean flag; expected one of: 1, 0, true, false, yes, no, on, off
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|  --on        env: ON
          #|  --off       env: OFF
          #|  --v         env: V
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=[], env={ "OFF": "bad" }) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: invalid value 'bad' for boolean flag; expected one of: 1, 0, true, false, yes, no, on, off
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|  --on        env: ON
          #|  --off       env: OFF
          #|  --v         env: V
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=[], env={ "V": "bad" }) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: invalid value 'bad' for count; expected a non-negative integer
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|  --on        env: ON
          #|  --off       env: OFF
          #|  --v         env: V
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=[], env={ "V": "-1" }) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: invalid value '-1' for count; expected a non-negative integer
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|  --on        env: ON
          #|  --off       env: OFF
          #|  --v         env: V
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "defaults and value range helpers through public API" {
  let defaults = @argparse.Command("demo", options=[
    OptionArg("mode", long="mode", action=Append, default_values=["a", "b"]),
    OptionArg("one", long="one", default_values=["x"]),
  ])
  let by_default = defaults.parse(argv=[], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(by_default.values is { "mode": ["a", "b"], "one": ["x"], .. })
  assert_true(by_default.sources is { "mode": Default, "one": Default, .. })

  let upper_only = @argparse.Command("demo", options=[
    OptionArg("tag", long="tag", action=Append),
  ])
  let upper_parsed = upper_only.parse(
    argv=["--tag", "a", "--tag", "b", "--tag", "c"],
    env=empty_env(),
  ) catch {
    _ => panic()
  }
  assert_true(upper_parsed.values is { "tag": ["a", "b", "c"], .. })

  let lower_only = @argparse.Command("demo", options=[
    OptionArg("tag", long="tag"),
  ])
  let lower_absent = lower_only.parse(argv=[], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(lower_absent.values is { "tag"? : None, .. })

  try lower_only.parse(argv=["--tag"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
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
  } noraise {
    _ => panic()
  }

  let single_range = @argparse.ValueRange::single()
  inspect(
    single_range,
    content=(
      #|{lower: 1, upper: Some(1)}
    ),
  )
}

///|
test "options consume exactly one value per occurrence" {
  let cmd = @argparse.Command("demo", options=[OptionArg("tag", long="tag")])
  let parsed = cmd.parse(argv=["--tag", "a"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "tag": ["a"], .. })
  assert_true(parsed.sources is { "tag": Argv, .. })

  try cmd.parse(argv=["--tag", "a", "b"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: too many positional arguments were provided
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help   Show help information.
          #|  --tag <tag>  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "set options reject duplicate occurrences" {
  let cmd = @argparse.Command("demo", options=[OptionArg("mode", long="mode")])
  try cmd.parse(argv=["--mode", "a", "--mode", "b"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: argument '--mode' cannot be used multiple times
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help     Show help information.
          #|  --mode <mode>  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "flag and option args require short or long names" {
  try
    @argparse.Command("demo", options=[OptionArg("input", long="")]).parse(
      argv=[],
      env=empty_env(),
    )
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: flag/option args require short/long/env
          #|
          #|Usage: demo
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", flags=[FlagArg("verbose", long="")]).parse(
      argv=[],
      env=empty_env(),
    )
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: flag/option args require short/long/env
          #|
          #|Usage: demo
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

///|
test "append options collect values across repeated occurrences" {
  let cmd = @argparse.Command("demo", options=[
    OptionArg("arg", long="arg", action=Append),
  ])
  let parsed = cmd.parse(argv=["--arg", "x", "--arg", "y"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "arg": ["x", "y"], .. })
  assert_true(parsed.sources is { "arg": Argv, .. })
}

///|
test "option parsing stops at the next option token" {
  let cmd = @argparse.Command(
    "demo",
    flags=[FlagArg("verbose", long="verbose")],
    options=[OptionArg("arg", short='a', long="arg")],
  )

  let stopped = cmd.parse(argv=["--arg", "x", "--verbose"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(stopped.values is { "arg": ["x"], .. })
  assert_true(stopped.flags is { "verbose": true, .. })

  try cmd.parse(argv=["--arg=x", "y", "--verbose"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: too many positional arguments were provided
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help       Show help information.
          #|  --verbose        
          #|  -a, --arg <arg>  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["-ax", "y", "--verbose"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: too many positional arguments were provided
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help       Show help information.
          #|  --verbose        
          #|  -a, --arg <arg>  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "options always require a value" {
  let cmd = @argparse.Command(
    "demo",
    flags=[FlagArg("verbose", long="verbose")],
    options=[OptionArg("opt", long="opt")],
  )
  try cmd.parse(argv=["--opt", "--verbose"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: a value is required for '--opt' but none was supplied
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help   Show help information.
          #|  --verbose    
          #|  --opt <opt>  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  let zero_value_required = @argparse.Command("demo", options=[
    OptionArg("opt", long="opt", required=true),
  ]).parse(argv=["--opt", "x"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(zero_value_required.values is { "opt": ["x"], .. })
}

///|
test "option values reject hyphen tokens unless allow_hyphen_values is enabled" {
  let strict = @argparse.Command("demo", options=[
    OptionArg("pattern", long="pattern"),
  ])
  let mut rejected = false
  try strict.parse(argv=["--pattern", "-file"], env=empty_env()) catch {
    Message(msg) => {
      inspect(
        msg,
        content=(
          #|error: a value is required for '--pattern' but none was supplied
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help           Show help information.
          #|  --pattern <pattern>  
          #|
        ),
      )
      rejected = true
    }
  } noraise {
    _ => rejected = true
  }
  assert_true(rejected)

  let permissive = @argparse.Command("demo", options=[
    OptionArg("pattern", long="pattern", allow_hyphen_values=true),
  ])
  let parsed = permissive.parse(argv=["--pattern", "-file"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "pattern": ["-file"], .. })
  assert_true(parsed.sources is { "pattern": Argv, .. })
}

///|

///|
test "default argv path is reachable" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionalArg(
      "rest",
      num_args=ValueRange(lower=0),
      allow_hyphen_values=true,
    ),
  ])
  let _ = cmd.parse(env=empty_env()) catch { _ => panic() }
}

///|
test "validation branches exposed through parse" {
  try
    @argparse.Command("demo", flags=[FlagArg("f", long="", action=Help)]).parse(
      argv=[],
      env=empty_env(),
    )
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: flag/option args require short/long/env
          #|
          #|Usage: demo
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", flags=[
      FlagArg("f", long="f", action=Help, negatable=true),
    ]).parse(argv=[], env=empty_env())
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: help/version actions do not support negatable
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|  --[no-]f    
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", flags=[
      FlagArg("f", long="f", action=Help, env="F"),
    ]).parse(argv=[], env=empty_env())
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: help/version actions do not support env/defaults
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|  --f         env: F
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", options=[OptionArg("x", long="x")]).parse(
      argv=["--x", "a", "b"],
      env=empty_env(),
    )
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: too many positional arguments were provided
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|  --x <x>     
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", options=[
      OptionArg("x", long="x", default_values=["a", "b"]),
    ]).parse(argv=[], env=empty_env())
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: default_values with multiple entries require action=Append
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|  --x <x>     defaults: a, b
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", positionals=[
      PositionalArg("x", num_args=ValueRange(lower=3, upper=2)),
    ]).parse(argv=[], env=empty_env())
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: max values must be >= min values
          #|
          #|Usage: demo <x...>
          #|
          #|Arguments:
          #|  x...  required
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", positionals=[
      PositionalArg("x", num_args=ValueRange(lower=-1, upper=2)),
    ]).parse(argv=[], env=empty_env())
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: min values must be >= 0
          #|
          #|Usage: demo [x...]
          #|
          #|Arguments:
          #|  x...  
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", positionals=[
      PositionalArg("x", num_args=ValueRange(lower=0, upper=-1)),
    ]).parse(argv=[], env=empty_env())
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: max values must be >= 0
          #|
          #|Usage: demo [x...]
          #|
          #|Arguments:
          #|  x...  
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  let positional_ok = @argparse.Command("demo", positionals=[
    PositionalArg("x", num_args=ValueRange(lower=0, upper=2)),
    PositionalArg("y"),
  ]).parse(argv=["a"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(positional_ok.values is { "x": ["a"], "y"? : None, .. })

  try
    @argparse.Command("demo", groups=[ArgGroup("g"), ArgGroup("g")]).parse(
      argv=[],
      env=empty_env(),
    )
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: duplicate group: g
          #|
          #|Usage: demo
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", groups=[ArgGroup("g", requires=["g"])]).parse(
      argv=[],
      env=empty_env(),
    )
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: group cannot require itself: g
          #|
          #|Usage: demo
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", groups=[ArgGroup("g", conflicts_with=["g"])]).parse(
      argv=[],
      env=empty_env(),
    )
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: group cannot conflict with itself: g
          #|
          #|Usage: demo
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", groups=[ArgGroup("g", args=["missing"])]).parse(
      argv=[],
      env=empty_env(),
    )
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unknown group arg: g -> missing
          #|
          #|Usage: demo
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", options=[
      OptionArg("x", long="x"),
      OptionArg("x", long="y"),
    ]).parse(argv=[], env=empty_env())
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: duplicate arg name: x
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|  --x <x>     
          #|  --y <x>     
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", options=[
      OptionArg("x", long="same"),
      OptionArg("y", long="same"),
    ]).parse(argv=[], env=empty_env())
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: duplicate long option: --same
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|  --same <x>  
          #|  --same <y>  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", flags=[
      FlagArg("hello", long="hello", negatable=true),
      FlagArg("x", long="no-hello"),
    ]).parse(argv=[], env=empty_env())
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: duplicate long option: --no-hello
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help    Show help information.
          #|  --[no-]hello  
          #|  --no-hello    
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", options=[
      OptionArg("x", short='s'),
      OptionArg("y", short='s'),
    ]).parse(argv=[], env=empty_env())
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: duplicate short option: -s
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help   Show help information.
          #|  -s, --x <x>  
          #|  -s, --y <y>  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", flags=[FlagArg("x", long="x", requires=["x"])]).parse(
      argv=[],
      env=empty_env(),
    )
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: arg cannot require itself: x
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|  --x         
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", flags=[
      FlagArg("x", long="x", conflicts_with=["x"]),
    ]).parse(argv=[], env=empty_env())
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: arg cannot conflict with itself: x
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|  --x         
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", subcommands=[Command("x"), Command("x")]).parse(
      argv=[],
      env=empty_env(),
    )
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: duplicate subcommand: x
          #|
          #|Usage: demo [command]
          #|
          #|Commands:
          #|  x     
          #|  x     
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

  try
    @argparse.Command("demo", subcommand_required=true).parse(
      argv=[],
      env=empty_env(),
    )
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: subcommand_required requires at least one subcommand
          #|
          #|Usage: demo
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", subcommands=[Command("help")]).parse(
      argv=[],
      env=empty_env(),
    )
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: subcommand name reserved for built-in help: help (disable with disable_help_subcommand)
          #|
          #|Usage: demo [command]
          #|
          #|Commands:
          #|  help  
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

  let custom_help = @argparse.Command("demo", flags=[
    FlagArg("custom_help", short='h', long="help", about="custom help"),
  ])
  let help_short = custom_help.parse(argv=["-h"], env=empty_env()) catch {
    _ => panic()
  }
  let help_long = custom_help.parse(argv=["--help"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(help_short.flags is { "custom_help": true, .. })
  assert_true(help_long.flags is { "custom_help": true, .. })
  inspect(
    custom_help.render_help(),
    content=(
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help  custom help
      #|
    ),
  )

  let custom_version = @argparse.Command("demo", version="1.0", flags=[
    FlagArg("custom_version", short='V', long="version", about="custom version"),
  ])
  let version_short = custom_version.parse(argv=["-V"], env=empty_env()) catch {
    _ => panic()
  }
  let version_long = custom_version.parse(argv=["--version"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(version_short.flags is { "custom_version": true, .. })
  assert_true(version_long.flags is { "custom_version": true, .. })
  inspect(
    custom_version.render_help(),
    content=(
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help     Show help information.
      #|  -V, --version  custom version
      #|
    ),
  )

  try
    @argparse.Command("demo", flags=[FlagArg("v", long="v", action=Version)]).parse(
      argv=[],
      env=empty_env(),
    )
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: version action requires command version text
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|  --v         
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "builtin and custom help/version dispatch edge paths" {
  let versioned = @argparse.Command("demo", version="1.2.3")
  inspect(
    versioned.render_help(),
    content=(
      #|Usage: demo
      #|
      #|Options:
      #|  -h, --help     Show help information.
      #|  -V, --version  Show version information.
      #|
    ),
  )

  try versioned.parse(argv=["--oops"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unexpected argument '--oops' found
          #|
          #|Usage: demo
          #|
          #|Options:
          #|  -h, --help     Show help information.
          #|  -V, --version  Show version information.
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  let long_help = @argparse.Command("demo", flags=[
    FlagArg("assist", long="assist", action=Help),
  ])
  inspect(
    long_help.render_help(),
    content=(
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|  --assist    
      #|
    ),
  )

  let short_help = @argparse.Command("demo", flags=[
    FlagArg("assist", short='?', action=Help),
  ])
  inspect(
    short_help.render_help(),
    content=(
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help    Show help information.
      #|  -?, --assist  
      #|
    ),
  )
}

///|
test "subcommand lookup falls back to positional value" {
  let cmd = @argparse.Command("demo", positionals=[PositionalArg("input")], subcommands=[
    Command("run"),
  ])
  let parsed = cmd.parse(argv=["raw"], env=empty_env()) catch { _ => panic() }
  assert_true(parsed.values is { "input": ["raw"], .. })
  assert_true(parsed.subcommand is None)
}

///|
test "group validation catches unknown requires target" {
  try
    @argparse.Command("demo", groups=[ArgGroup("g", requires=["missing"])]).parse(
      argv=[],
      env=empty_env(),
    )
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unknown group requires target: g -> missing
          #|
          #|Usage: demo
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

///|
test "group validation catches unknown conflicts_with target" {
  try
    @argparse.Command("demo", groups=[ArgGroup("g", conflicts_with=["missing"])]).parse(
      argv=[],
      env=empty_env(),
    )
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unknown group conflicts_with target: g -> missing
          #|
          #|Usage: demo
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

///|
test "group requires/conflicts can target argument names" {
  let requires_cmd = @argparse.Command(
    "demo",
    groups=[ArgGroup("mode", args=["fast"], requires=["config"])],
    flags=[FlagArg("fast", long="fast")],
    options=[OptionArg("config", long="config")],
  )

  let ok = requires_cmd.parse(
    argv=["--fast", "--config", "cfg.toml"],
    env=empty_env(),
  ) catch {
    _ => panic()
  }
  assert_true(ok.flags is { "fast": true, .. })
  assert_true(ok.values is { "config": ["cfg.toml"], .. })

  try requires_cmd.parse(argv=["--fast"], env=empty_env()) catch {
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
          #|  --fast             
          #|  --config <config>  
          #|
          #|Groups:
          #|  mode  --fast
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  let conflicts_cmd = @argparse.Command(
    "demo",
    groups=[ArgGroup("mode", args=["fast"], conflicts_with=["config"])],
    flags=[FlagArg("fast", long="fast")],
    options=[OptionArg("config", long="config")],
  )

  try
    conflicts_cmd.parse(
      argv=["--fast", "--config", "cfg.toml"],
      env=empty_env(),
    )
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: group conflict mode conflicts with config
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help         Show help information.
          #|  --fast             
          #|  --config <config>  
          #|
          #|Groups:
          #|  mode  --fast
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "group without members has no parse effect" {
  let cmd = @argparse.Command("demo", groups=[ArgGroup("known")], flags=[
    FlagArg("x", long="x"),
  ])
  let parsed = cmd.parse(argv=["--x"], env=empty_env()) catch { _ => panic() }
  assert_true(parsed.flags is { "x": true, .. })
  let help = cmd.render_help()
  assert_true(help.has_prefix("Usage: demo [options]"))
}

///|
test "arg validation catches unknown requires target" {
  try
    @argparse.Command("demo", options=[
      OptionArg("mode", long="mode", requires=["missing"]),
    ]).parse(argv=["--mode", "fast"], env=empty_env())
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unknown requires target: mode -> missing
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help     Show help information.
          #|  --mode <mode>  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "arg validation catches unknown conflicts_with target" {
  try
    @argparse.Command("demo", options=[
      OptionArg("mode", long="mode", conflicts_with=["missing"]),
    ]).parse(argv=["--mode", "fast"], env=empty_env())
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unknown conflicts_with target: mode -> missing
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help     Show help information.
          #|  --mode <mode>  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "empty groups without presence do not fail" {
  let grouped_ok = @argparse.Command(
    "demo",
    groups=[ArgGroup("left", args=["l"]), ArgGroup("right", args=["r"])],
    flags=[FlagArg("l", long="left"), FlagArg("r", long="right")],
  )
  let parsed = grouped_ok.parse(argv=["--left"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.flags is { "l": true, .. })
}

///|
test "help rendering edge paths stay stable" {
  let required_many = @argparse.Command("demo", positionals=[
    PositionalArg("files", required=true, num_args=ValueRange(lower=1)),
  ])
  let required_help = required_many.render_help()
  assert_true(required_help.has_prefix("Usage: demo <files...>"))

  let short_only_builtin = @argparse.Command("demo", options=[
    OptionArg("helpopt", long="help"),
  ])
  let short_only_text = short_only_builtin.render_help()
  assert_true(short_only_text.has_prefix("Usage: demo"))
  try short_only_builtin.parse(argv=["--help"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: a value is required for '--help' but none was supplied
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h                Show help information.
          #|  --help <helpopt>  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  let long_only_builtin = @argparse.Command("demo", flags=[
    FlagArg("custom_h", short='h'),
  ])
  let long_only_text = long_only_builtin.render_help()
  assert_true(long_only_text.has_prefix("Usage: demo"))
  let custom_h = long_only_builtin.parse(argv=["-h"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(custom_h.flags is { "custom_h": true, .. })

  let empty_options = @argparse.Command(
    "demo",
    disable_help_flag=true,
    disable_version_flag=true,
  )
  let empty_options_help = empty_options.render_help()
  assert_true(empty_options_help.has_prefix("Usage: demo"))

  let implicit_group = @argparse.Command("demo", positionals=[
    PositionalArg("item"),
  ])
  let implicit_group_help = implicit_group.render_help()
  assert_true(implicit_group_help.has_prefix("Usage: demo [item]"))

  let sub_visible = @argparse.Command("demo", disable_help_subcommand=true, subcommands=[
    Command("run"),
  ])
  let sub_help = sub_visible.render_help()
  assert_true(sub_help.has_prefix("Usage: demo [command]"))
}

///|
test "unified error message formatting remains stable" {
  let cmd = @argparse.Command("demo", options=[OptionArg("tag", long="tag")])

  try cmd.parse(argv=["--oops"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
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
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["--tag"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
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
  } noraise {
    _ => panic()
  }
}

///|
test "options require one value per occurrence" {
  let with_value = @argparse.Command("demo", options=[
    OptionArg("tag", long="tag"),
  ]).parse(argv=["--tag", "x"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(with_value.values is { "tag": ["x"], .. })

  try
    @argparse.Command("demo", options=[OptionArg("tag", long="tag")]).parse(
      argv=["--tag"],
      env=empty_env(),
    )
  catch {
    Message(msg) =>
      inspect(
        msg,
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
  } noraise {
    _ => panic()
  }
}

///|
test "short options require one value before next option token" {
  let cmd = @argparse.Command("demo", flags=[FlagArg("verbose", short='v')], options=[
    OptionArg("x", short='x'),
  ])
  let ok = cmd.parse(argv=["-x", "a", "-v"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(ok.values is { "x": ["a"], .. })
  assert_true(ok.flags is { "verbose": true, .. })

  try cmd.parse(argv=["-x", "-v"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: a value is required for '-x' but none was supplied
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help     Show help information.
          #|  -v, --verbose  
          #|  -x, --x <x>    
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "version action dispatches on custom long and short flags" {
  let cmd = @argparse.Command("demo", version="2.0.0", flags=[
    FlagArg("show_long", long="show-version", action=Version),
    FlagArg("show_short", short='S', action=Version),
  ])

  inspect(
    cmd.render_help(),
    content=(
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help        Show help information.
      #|  -V, --version     Show version information.
      #|  --show-version    
      #|  -S, --show_short  
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
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help        Show help information.
          #|  -V, --version     Show version information.
          #|  --show-version    
          #|  -S, --show_short  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "global version action keeps parent version text in subcommand context" {
  let cmd = @argparse.Command(
    "demo",
    version="1.0.0",
    flags=[
      FlagArg(
        "show_version",
        short='S',
        long="show-version",
        action=Version,
        global=true,
      ),
    ],
    subcommands=[Command("run")],
  )

  try cmd.parse(argv=["--oops"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unexpected argument '--oops' found
          #|
          #|Usage: demo [options] [command]
          #|
          #|Commands:
          #|  run   
          #|  help  Print help for the subcommand(s).
          #|
          #|Options:
          #|  -h, --help          Show help information.
          #|  -V, --version       Show version information.
          #|  -S, --show-version  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["run", "--oops"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unexpected argument '--oops' found
          #|
          #|Usage: demo run [options]
          #|
          #|Options:
          #|  -h, --help          Show help information.
          #|  -S, --show-version  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "required and env-fed ranged values validate after parsing" {
  let required_cmd = @argparse.Command("demo", options=[
    OptionArg("input", long="input", required=true),
  ])
  try required_cmd.parse(argv=[], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: the following required argument was not provided: 'input'
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help       Show help information.
          #|  --input <input>  required
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  let env_min_cmd = @argparse.Command("demo", options=[
    OptionArg("pair", long="pair", env="PAIR"),
  ])
  let env_value = env_min_cmd.parse(argv=[], env={ "PAIR": "one" }) catch {
    _ => panic()
  }
  assert_true(env_value.values is { "pair": ["one"], .. })
  assert_true(env_value.sources is { "pair": Env, .. })
}

///|
test "positionals honor explicit index sorting with last ranged positional" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionalArg("late", num_args=ValueRange(lower=2, upper=2)),
    PositionalArg("first"),
    PositionalArg("mid"),
  ])

  let parsed = cmd.parse(argv=["a", "b", "c", "d"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(
    parsed.values is { "late": ["a", "b"], "first": ["c"], "mid": ["d"], .. },
  )
}

///|
test "mixed indexed and unindexed positionals keep inferred order" {
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
test "single positional parses without explicit index metadata" {
  let parsed = @argparse.Command("demo", positionals=[PositionalArg("late")]).parse(
    argv=["x"],
    env=empty_env(),
  ) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "late": ["x"], .. })
}

///|
test "positional num_args lower bound rejects missing argv values" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionalArg("first", num_args=ValueRange(lower=2, upper=3)),
  ])

  try cmd.parse(argv=[], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: 'first' requires at least 2 values but only 0 were provided
          #|
          #|Usage: demo <first...>
          #|
          #|Arguments:
          #|  first...  required
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

///|
test "positional max clamp leaves trailing value for next positional" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionalArg("items", num_args=ValueRange(lower=0, upper=2)),
    PositionalArg("tail"),
  ])

  let parsed = cmd.parse(argv=["a", "b", "c"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "items": ["a", "b"], "tail": ["c"], .. })
}

///|
test "options with allow_hyphen_values accept option-like single values" {
  let cmd = @argparse.Command(
    "demo",
    flags=[
      FlagArg("verbose", long="verbose"),
      FlagArg("cache", long="cache", negatable=true),
      FlagArg("quiet", short='q'),
    ],
    options=[OptionArg("arg", long="arg", allow_hyphen_values=true)],
  )

  let known_long = cmd.parse(argv=["--arg", "--verbose"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(known_long.values is { "arg": ["--verbose"], .. })
  assert_true(known_long.flags is { "verbose"? : None, .. })

  let negated = cmd.parse(argv=["--arg", "--no-cache"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(negated.values is { "arg": ["--no-cache"], .. })
  assert_true(negated.flags is { "cache"? : None, .. })

  let unknown_long_value = cmd.parse(
    argv=["--arg", "--mystery"],
    env=empty_env(),
  ) catch {
    _ => panic()
  }
  assert_true(unknown_long_value.values is { "arg": ["--mystery"], .. })

  let known_short = cmd.parse(argv=["--arg", "-q"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(known_short.values is { "arg": ["-q"], .. })
  assert_true(known_short.flags is { "quiet"? : None, .. })

  let cmd_with_rest = @argparse.Command(
    "demo",
    options=[OptionArg("arg", long="arg", allow_hyphen_values=true)],
    positionals=[
      PositionalArg(
        "rest",
        num_args=ValueRange(lower=0),
        allow_hyphen_values=true,
      ),
    ],
  )
  let sentinel_stop = cmd_with_rest.parse(
    argv=["--arg", "x", "--", "tail"],
    env=empty_env(),
  ) catch {
    _ => panic()
  }
  assert_true(sentinel_stop.values is { "arg": ["x"], "rest": ["tail"], .. })
}

///|
test "single-value options avoid consuming additional option values" {
  let cmd = @argparse.Command(
    "demo",
    flags=[FlagArg("verbose", long="verbose")],
    options=[OptionArg("one", long="one")],
  )

  let parsed = cmd.parse(argv=["--one", "x", "--verbose"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "one": ["x"], .. })
  assert_true(parsed.flags is { "verbose": true, .. })
}

///|
test "missing option values are reported when next token is another option" {
  let cmd = @argparse.Command(
    "demo",
    flags=[FlagArg("verbose", long="verbose")],
    options=[OptionArg("arg", long="arg")],
  )

  let ok = cmd.parse(argv=["--arg", "x", "--verbose"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(ok.values is { "arg": ["x"], .. })
  assert_true(ok.flags is { "verbose": true, .. })

  try cmd.parse(argv=["--arg", "--verbose"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: a value is required for '--arg' but none was supplied
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help   Show help information.
          #|  --verbose    
          #|  --arg <arg>  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "short-only set options use short label in duplicate errors" {
  let cmd = @argparse.Command("demo", options=[OptionArg("mode", short='m')])
  try cmd.parse(argv=["-m", "a", "-m", "b"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: argument '--mode' cannot be used multiple times
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help         Show help information.
          #|  -m, --mode <mode>  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "unknown short suggestion can be absent" {
  let cmd = @argparse.Command("demo", disable_help_flag=true, options=[
    OptionArg("name", long="name"),
  ])

  try cmd.parse(argv=["-x"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
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
  } noraise {
    _ => panic()
  }
}

///|
test "setfalse flags apply false when present" {
  let cmd = @argparse.Command("demo", flags=[
    FlagArg("failfast", long="failfast", action=SetFalse),
  ])
  let parsed = cmd.parse(argv=["--failfast"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.flags is { "failfast": false, .. })
  assert_true(parsed.sources is { "failfast": Argv, .. })
}

///|
test "allow_hyphen positional treats unknown long token as value" {
  let cmd = @argparse.Command("demo", flags=[FlagArg("known", long="known")], positionals=[
    PositionalArg("input", allow_hyphen_values=true),
  ])
  let parsed = cmd.parse(argv=["--mystery"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "input": ["--mystery"], .. })
}

///|
test "global value from child default is merged back to parent" {
  let cmd = @argparse.Command(
    "demo",
    options=[
      OptionArg("mode", long="mode", default_values=["safe"], global=true),
      OptionArg("unused", long="unused", global=true),
    ],
    subcommands=[Command("run")],
  )

  let parsed = cmd.parse(argv=["run"], env=empty_env()) catch { _ => panic() }
  assert_true(parsed.values is { "mode": ["safe"], "unused"? : None, .. })
  assert_true(parsed.sources is { "mode": Default, .. })
  assert_true(
    parsed.subcommand is Some(("run", sub)) &&
    sub.values is { "mode": ["safe"], .. } &&
    sub.sources is { "mode": Default, .. },
  )
}

///|
test "child global arg with inherited global name updates parent global" {
  let cmd = @argparse.Command(
    "demo",
    options=[
      OptionArg("mode", long="mode", default_values=["safe"], global=true),
    ],
    subcommands=[
      Command("run", options=[OptionArg("mode", long="mode", global=true)]),
    ],
  )

  let parsed = cmd.parse(argv=["run", "--mode", "fast"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "mode": ["fast"], .. })
  assert_true(parsed.sources is { "mode": Argv, .. })
  assert_true(
    parsed.subcommand is Some(("run", sub)) &&
    sub.values is { "mode": ["fast"], .. } &&
    sub.sources is { "mode": Argv, .. },
  )
}

///|
test "child local arg shadowing inherited global is rejected at build time" {
  try
    @argparse.Command(
      "demo",
      options=[
        OptionArg(
          "mode",
          long="mode",
          env="MODE",
          default_values=["safe"],
          global=true,
        ),
      ],
      subcommands=[Command("run", options=[OptionArg("mode", long="mode")])],
    ).parse(argv=["run"], env=empty_env())
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: arg 'mode' shadows an inherited global; rename the arg or mark it global
          #|
          #|Usage: demo [options] [command]
          #|
          #|Commands:
          #|  run   
          #|  help  Print help for the subcommand(s).
          #|
          #|Options:
          #|  -h, --help     Show help information.
          #|  --mode <mode>  env: MODE, default: safe
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "global append env value from child is merged back to parent" {
  let cmd = @argparse.Command(
    "demo",
    options=[
      OptionArg("tag", long="tag", action=Append, env="TAG", global=true),
    ],
    subcommands=[Command("run")],
  )

  let parsed = cmd.parse(argv=["run"], env={ "TAG": "env-tag" }) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "tag": ["env-tag"], .. })
  assert_true(parsed.sources is { "tag": Env, .. })
  assert_true(
    parsed.subcommand is Some(("run", sub)) &&
    sub.values is { "tag": ["env-tag"], .. } &&
    sub.sources is { "tag": Env, .. },
  )
}

///|
test "global flag set in child argv is merged back to parent" {
  let cmd = @argparse.Command(
    "demo",
    flags=[FlagArg("verbose", long="verbose", global=true)],
    subcommands=[Command("run")],
  )

  let parsed = cmd.parse(argv=["run", "--verbose"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.flags is { "verbose": true, .. })
  assert_true(parsed.sources is { "verbose": Argv, .. })
  assert_true(
    parsed.subcommand is Some(("run", sub)) &&
    sub.flags is { "verbose": true, .. } &&
    sub.sources is { "verbose": Argv, .. },
  )
}

///|
test "global count negation after subcommand resets merged state" {
  let cmd = @argparse.Command(
    "demo",
    flags=[
      FlagArg(
        "verbose",
        long="verbose",
        action=Count,
        negatable=true,
        global=true,
      ),
    ],
    subcommands=[Command("run")],
  )

  let parsed = cmd.parse(
    argv=["--verbose", "run", "--no-verbose"],
    env=empty_env(),
  ) catch {
    _ => panic()
  }
  assert_true(parsed.flags is { "verbose": false, .. })
  assert_true(parsed.flag_counts.get("verbose") is None)
  assert_true(parsed.sources is { "verbose": Argv, .. })
  assert_true(
    parsed.subcommand is Some(("run", sub)) &&
    sub.flags is { "verbose": false, .. } &&
    sub.flag_counts.get("verbose") is None &&
    sub.sources is { "verbose": Argv, .. },
  )
}

///|
test "global set option rejects duplicate occurrences across subcommands" {
  let cmd = @argparse.Command(
    "demo",
    options=[OptionArg("mode", long="mode", global=true)],
    subcommands=[Command("run")],
  )
  try
    cmd.parse(argv=["--mode", "a", "run", "--mode", "b"], env=empty_env())
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: argument '--mode' cannot be used multiple times
          #|
          #|Usage: demo [options] [command]
          #|
          #|Commands:
          #|  run   
          #|  help  Print help for the subcommand(s).
          #|
          #|Options:
          #|  -h, --help     Show help information.
          #|  --mode <mode>  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "global override with incompatible inherited type is rejected" {
  try
    @argparse.Command(
      "demo",
      options=[OptionArg("mode", long="mode", required=true, global=true)],
      subcommands=[
        Command("run", flags=[FlagArg("mode", long="mode", global=true)]),
      ],
    ).parse(argv=["run", "--mode"], env=empty_env())
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: global arg 'mode' is incompatible with inherited global definition
          #|
          #|Usage: demo [options] [command]
          #|
          #|Commands:
          #|  run   
          #|  help  Print help for the subcommand(s).
          #|
          #|Options:
          #|  -h, --help     Show help information.
          #|  --mode <mode>  required
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "child local long alias collision with inherited global is rejected" {
  try
    @argparse.Command(
      "demo",
      flags=[FlagArg("verbose", long="verbose", global=true)],
      subcommands=[Command("run", options=[OptionArg("local", long="verbose")])],
    ).parse(argv=["run", "--verbose"], env=empty_env())
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: arg 'local' long option --verbose conflicts with inherited global 'verbose'
          #|
          #|Usage: demo [options] [command]
          #|
          #|Commands:
          #|  run   
          #|  help  Print help for the subcommand(s).
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
test "child local short alias collision with inherited global is rejected" {
  try
    @argparse.Command(
      "demo",
      flags=[FlagArg("verbose", short='v', global=true)],
      subcommands=[Command("run", options=[OptionArg("local", short='v')])],
    ).parse(argv=["run", "-v"], env=empty_env())
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: arg 'local' short option -v conflicts with inherited global 'verbose'
          #|
          #|Usage: demo [options] [command]
          #|
          #|Commands:
          #|  run   
          #|  help  Print help for the subcommand(s).
          #|
          #|Options:
          #|  -h, --help     Show help information.
          #|  -v, --verbose  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "nested subcommands inherit finalized globals from ancestors" {
  let leaf = @argparse.Command("leaf")
  let mid = @argparse.Command("mid", subcommands=[leaf])
  let cmd = @argparse.Command(
    "demo",
    flags=[FlagArg("verbose", long="verbose", global=true)],
    subcommands=[mid],
  )

  let parsed = cmd.parse(argv=["--verbose", "mid", "leaf"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.flags is { "verbose": true, .. })
  assert_true(
    parsed.subcommand is Some(("mid", mid_matches)) &&
    mid_matches.flags is { "verbose": true, .. } &&
    mid_matches.subcommand is Some(("leaf", leaf_matches)) &&
    leaf_matches.flags is { "verbose": true, .. } &&
    leaf_matches.sources is { "verbose": Argv, .. },
  )
}

///|
test "non-bmp short option token does not panic" {
  let cmd = @argparse.Command("demo", flags=[FlagArg("party", short='🎉')])
  let parsed = cmd.parse(argv=["-🎉"], env=empty_env()) catch { _ => panic() }
  assert_true(parsed.flags is { "party": true, .. })
}

///|
test "non-bmp hyphen token reports unknown argument without panic" {
  let cmd = @argparse.Command("demo", positionals=[PositionalArg("value")])
  try cmd.parse(argv=["-🎉"], env=empty_env()) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unexpected argument '-🎉' found
          #|
          #|Usage: demo [value]
          #|
          #|Arguments:
          #|  value  
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

///|
test "option env values remain string values instead of flags" {
  let cmd = @argparse.Command("demo", options=[
    OptionArg("mode", long="mode", env="MODE"),
  ])
  let parsed = cmd.parse(argv=[], env={ "MODE": "fast" }) catch { _ => panic() }
  assert_true(parsed.values is { "mode": ["fast"], .. })
  assert_true(parsed.flags.get("mode") is None)
  assert_true(parsed.sources is { "mode": Env, .. })
}

///|
test "nested global override deduplicates count merge by name" {
  let leaf = @argparse.Command("leaf")
  let mid = @argparse.Command(
    "mid",
    flags=[FlagArg("verbose", long="verbose", action=Count, global=true)],
    subcommands=[leaf],
  )
  let root = @argparse.Command(
    "root",
    flags=[FlagArg("verbose", long="verbose", action=Count, global=true)],
    subcommands=[mid],
  )

  let parsed = root.parse(argv=["mid", "leaf", "--verbose"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.flag_counts is { "verbose": 1, .. })
  assert_true(
    parsed.subcommand is Some(("mid", sub_mid)) &&
    sub_mid.flag_counts is { "verbose": 1, .. } &&
    sub_mid.subcommand is Some(("leaf", sub_leaf)) &&
    sub_leaf.flag_counts is { "verbose": 1, .. },
  )
}

///|
test "nested global override keeps single set value without false duplicate error" {
  let leaf = @argparse.Command("leaf")
  let mid = @argparse.Command(
    "mid",
    options=[OptionArg("mode", long="mode", global=true)],
    subcommands=[leaf],
  )
  let root = @argparse.Command(
    "root",
    options=[OptionArg("mode", long="mode", global=true)],
    subcommands=[mid],
  )

  let parsed = root.parse(
    argv=["mid", "leaf", "--mode", "fast"],
    env=empty_env(),
  ) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "mode": ["fast"], .. })
  assert_true(
    parsed.subcommand is Some(("mid", sub_mid)) &&
    sub_mid.values is { "mode": ["fast"], .. } &&
    sub_mid.subcommand is Some(("leaf", sub_leaf)) &&
    sub_leaf.values is { "mode": ["fast"], .. },
  )
}

///|
test "global override with different negatable setting is rejected" {
  try
    @argparse.Command(
      "demo",
      flags=[FlagArg("verbose", long="verbose", negatable=true, global=true)],
      subcommands=[
        Command("run", flags=[
          FlagArg("verbose", long="verbose", negatable=false, global=true),
        ]),
      ],
    ).parse(argv=["run"], env=empty_env())
  catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: global arg 'verbose' is incompatible with inherited global definition
          #|
          #|Usage: demo [options] [command]
          #|
          #|Commands:
          #|  run   
          #|  help  Print help for the subcommand(s).
          #|
          #|Options:
          #|  -h, --help      Show help information.
          #|  --[no-]verbose  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}
