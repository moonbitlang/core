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
struct DecodeName {
  name : String
}

///|
impl @argparse.FromMatches for DecodeName with from_matches(
  matches : @argparse.Matches,
) {
  match matches.values.get("name") {
    Some(values) if values.length() > 0 => DecodeName::{ name: values[0] }
    _ => raise @argparse.ArgParseError::MissingRequired("name")
  }
}

///|
test "render help snapshot with groups and hidden entries" {
  let cmd = @argparse.Command(
    "render",
    groups=[
      @argparse.ArgGroup("mode", required=true, multiple=false, args=[
        "fast", "path",
      ]),
    ],
    subcommands=[
      @argparse.Command("run", about="run"),
      @argparse.Command("hidden", about="hidden", hidden=true),
    ],
    args=[
      @argparse.FlagArg("fast", short='f', long="fast", group="mode"),
      @argparse.FlagArg("slow", long="slow", group="mode", hidden=true),
      @argparse.FlagArg("cache", long="cache", negatable=true, about="cache"),
      @argparse.OptionArg(
        "path",
        short='p',
        long="path",
        env="PATH_ENV",
        default_values=["a", "b"],
        required=true,
        group="mode",
      ),
      @argparse.PositionalArg("target", index=0, required=true),
      @argparse.PositionalArg(
        "rest",
        index=1,
        num_args=@argparse.ValueRange(lower=0),
      ),
      @argparse.PositionalArg("secret", index=2, hidden=true),
    ],
  )
  inspect(
    cmd.render_help(),
    content=(
      #|Usage: render [options] <command> <target> [rest...]
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
    groups=[@argparse.ArgGroup("grp", args=["f", "opt", "pos"])],
    args=[
      @argparse.FlagArg(
        "f",
        short='f',
        about="f",
        env="F_ENV",
        requires=["opt"],
        required=true,
        global=true,
        hidden=true,
        group="grp",
      ),
      @argparse.OptionArg(
        "opt",
        short='o',
        about="opt",
        default_values=["x", "y"],
        env="OPT_ENV",
        allow_hyphen_values=true,
        last=true,
        required=true,
        global=true,
        hidden=true,
        conflicts_with=["pos"],
        group="grp",
      ),
      @argparse.PositionalArg(
        "pos",
        about="pos",
        env="POS_ENV",
        default_values=["p1", "p2"],
        num_args=@argparse.ValueRange(lower=0, upper=2),
        allow_hyphen_values=true,
        last=true,
        requires=["opt"],
        conflicts_with=["f"],
        group="grp",
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
  let cmd = @argparse.Command("demo", args=[
    @argparse.FlagArg(
      "verbose",
      short='v',
      long="verbose",
      action=@argparse.FlagAction::Count,
    ),
  ])
  let matches = cmd.parse(argv=["-v", "-v", "-v"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(matches.flags is { "verbose": true, .. })
  assert_true(matches.flag_counts is { "verbose": 3, .. })
  assert_true(matches.sources is { "verbose": @argparse.ValueSource::Argv, .. })
}

///|
test "global option merges parent and child values" {
  let child = @argparse.Command("run")
  let cmd = @argparse.Command(
    "demo",
    args=[
      @argparse.OptionArg(
        "profile",
        short='p',
        long="profile",
        action=@argparse.OptionAction::Append,
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
  assert_true(matches.sources is { "profile": @argparse.ValueSource::Argv, .. })
  assert_true(
    matches.subcommand is Some(("run", sub)) &&
    sub.values is { "profile": ["parent", "child"], .. },
  )
}

///|
test "global append keeps parent argv over child env/default" {
  let child = @argparse.Command("run")
  let cmd = @argparse.Command(
    "demo",
    args=[
      @argparse.OptionArg(
        "profile",
        long="profile",
        action=@argparse.OptionAction::Append,
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
  assert_true(matches.sources is { "profile": @argparse.ValueSource::Argv, .. })
  assert_true(
    matches.subcommand is Some(("run", sub)) &&
    sub.values is { "profile": ["parent"], .. } &&
    sub.sources is { "profile": @argparse.ValueSource::Argv, .. },
  )
}

///|
test "global scalar keeps parent argv over child env/default" {
  let child = @argparse.Command("run")
  let cmd = @argparse.Command(
    "demo",
    args=[
      @argparse.OptionArg(
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
  assert_true(matches.sources is { "profile": @argparse.ValueSource::Argv, .. })
  assert_true(
    matches.subcommand is Some(("run", sub)) &&
    sub.values is { "profile": ["parent"], .. } &&
    sub.sources is { "profile": @argparse.ValueSource::Argv, .. },
  )
}

///|
test "global count merges parent and child occurrences" {
  let child = @argparse.Command("run")
  let cmd = @argparse.Command(
    "demo",
    args=[
      @argparse.FlagArg(
        "verbose",
        short='v',
        long="verbose",
        action=@argparse.FlagAction::Count,
        global=true,
      ),
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
    args=[
      @argparse.FlagArg(
        "verbose",
        short='v',
        long="verbose",
        action=@argparse.FlagAction::Count,
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
  assert_true(matches.sources is { "verbose": @argparse.ValueSource::Argv, .. })
  assert_true(
    matches.subcommand is Some(("run", sub)) &&
    sub.flag_counts is { "verbose": 1, .. } &&
    sub.sources is { "verbose": @argparse.ValueSource::Argv, .. },
  )
}

///|
test "global flag keeps parent argv over child env fallback" {
  let child = @argparse.Command("run")
  let cmd = @argparse.Command(
    "demo",
    args=[
      @argparse.FlagArg("verbose", long="verbose", env="VERBOSE", global=true),
    ],
    subcommands=[child],
  )

  let matches = cmd.parse(argv=["--verbose", "run"], env={ "VERBOSE": "0" }) catch {
    _ => panic()
  }
  assert_true(matches.flags is { "verbose": true, .. })
  assert_true(matches.sources is { "verbose": @argparse.ValueSource::Argv, .. })
  assert_true(
    matches.subcommand is Some(("run", sub)) &&
    sub.flags is { "verbose": true, .. } &&
    sub.sources is { "verbose": @argparse.ValueSource::Argv, .. },
  )
}

///|
test "global count source keeps env across subcommand merge" {
  let child = @argparse.Command("run")
  let cmd = @argparse.Command(
    "demo",
    args=[
      @argparse.FlagArg(
        "verbose",
        short='v',
        long="verbose",
        action=@argparse.FlagAction::Count,
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
  assert_true(matches.sources is { "verbose": @argparse.ValueSource::Env, .. })
  assert_true(
    matches.subcommand is Some(("run", sub)) &&
    sub.flag_counts is { "verbose": 1, .. } &&
    sub.sources is { "verbose": @argparse.ValueSource::Env, .. },
  )
}

///|
test "help subcommand styles and errors" {
  let leaf = @argparse.Command("echo", about="echo")
  let cmd = @argparse.Command("demo", subcommands=[leaf])

  try cmd.parse(argv=["help", "echo", "-h"], env=empty_env()) catch {
    @argparse.DisplayHelp::Message(text) =>
      inspect(
        text,
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
    _ => panic()
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["help", "echo", "--help"], env=empty_env()) catch {
    @argparse.DisplayHelp::Message(text) =>
      inspect(
        text,
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
    _ => panic()
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["help"], env=empty_env()) catch {
    @argparse.DisplayHelp::Message(text) =>
      inspect(
        text,
        content=(
          #|Usage: demo <command>
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
    _ => panic()
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["help", "--bad"], env=empty_env()) catch {
    @argparse.ArgParseError::InvalidArgument(msg) =>
      inspect(
        msg,
        content=(
          #|unexpected help argument: --bad
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["help", "missing"], env=empty_env()) catch {
    @argparse.ArgParseError::InvalidArgument(msg) =>
      inspect(
        msg,
        content=(
          #|unknown subcommand: missing
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "subcommand help includes inherited global options" {
  let leaf = @argparse.Command("echo", about="echo")
  let cmd = @argparse.Command(
    "demo",
    args=[
      @argparse.FlagArg(
        "verbose",
        short='v',
        long="verbose",
        about="Enable verbose mode",
        global=true,
      ),
    ],
    subcommands=[leaf],
  )

  try cmd.parse(argv=["echo", "-h"], env=empty_env()) catch {
    @argparse.DisplayHelp::Message(text) => {
      assert_true(text.contains("Usage: echo [options]"))
      assert_true(text.contains("-v, --verbose"))
    }
    _ => panic()
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["help", "echo"], env=empty_env()) catch {
    @argparse.DisplayHelp::Message(text) => {
      assert_true(text.contains("Usage: echo [options]"))
      assert_true(text.contains("-v, --verbose"))
    }
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "unknown argument suggestions are exposed" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.FlagArg("verbose", short='v', long="verbose"),
  ])

  try cmd.parse(argv=["--verbse"], env=empty_env()) catch {
    @argparse.ArgParseError::UnknownArgument(arg, hint) => {
      assert_true(arg == "--verbse")
      assert_true(hint is Some("--verbose"))
    }
    _ => panic()
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["-x"], env=empty_env()) catch {
    @argparse.ArgParseError::UnknownArgument(arg, hint) => {
      assert_true(arg == "-x")
      assert_true(hint is Some("-v"))
    }
    _ => panic()
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["--zzzzzzzzzz"], env=empty_env()) catch {
    @argparse.ArgParseError::UnknownArgument(arg, hint) => {
      assert_true(arg == "--zzzzzzzzzz")
      assert_true(hint is None)
    }
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "long and short value parsing branches" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.OptionArg("count", short='c', long="count"),
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
    @argparse.ArgParseError::MissingValue(name) =>
      assert_true(name == "--count")
    _ => panic()
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["-c"], env=empty_env()) catch {
    @argparse.ArgParseError::MissingValue(name) => assert_true(name == "-c")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "append option action is publicly selectable" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.OptionArg(
      "tag",
      long="tag",
      action=@argparse.OptionAction::Append,
    ),
  ])
  let appended = cmd.parse(argv=["--tag", "a", "--tag", "b"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(appended.values is { "tag": ["a", "b"], .. })
  assert_true(appended.sources is { "tag": @argparse.ValueSource::Argv, .. })
}

///|
test "negation parsing and invalid negation forms" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.FlagArg("cache", long="cache", negatable=true),
    @argparse.OptionArg("path", long="path"),
  ])

  let off = cmd.parse(argv=["--no-cache"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(off.flags is { "cache": false, .. })
  assert_true(off.sources is { "cache": @argparse.ValueSource::Argv, .. })

  try cmd.parse(argv=["--no-path"], env=empty_env()) catch {
    @argparse.ArgParseError::UnknownArgument(arg, _) =>
      assert_true(arg == "--no-path")
    _ => panic()
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["--no-missing"], env=empty_env()) catch {
    @argparse.ArgParseError::UnknownArgument(arg, _) =>
      assert_true(arg == "--no-missing")
    _ => panic()
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["--no-cache=1"], env=empty_env()) catch {
    @argparse.ArgParseError::InvalidArgument(arg) =>
      assert_true(arg == "--no-cache=1")
    _ => panic()
  } noraise {
    _ => panic()
  }

  let count_cmd = @argparse.Command("demo", args=[
    @argparse.FlagArg(
      "verbose",
      long="verbose",
      action=@argparse.FlagAction::Count,
      negatable=true,
    ),
  ])
  let reset = count_cmd.parse(
    argv=["--verbose", "--no-verbose"],
    env=empty_env(),
  ) catch {
    _ => panic()
  }
  assert_true(reset.flags is { "verbose": false, .. })
  assert_true(reset.flag_counts is { "verbose"? : None, .. })
  assert_true(reset.sources is { "verbose": @argparse.ValueSource::Argv, .. })
}

///|
test "positionals force mode and dash handling" {
  let force_cmd = @argparse.Command("demo", args=[
    @argparse.PositionalArg(
      "tail",
      index=0,
      num_args=@argparse.ValueRange(lower=0),
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

  let negative_cmd = @argparse.Command("demo", args=[
    @argparse.PositionalArg("n", index=0),
  ])
  let negative = negative_cmd.parse(argv=["-9"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(negative.values is { "n": ["-9"], .. })

  try negative_cmd.parse(argv=["x", "y"], env=empty_env()) catch {
    @argparse.ArgParseError::TooManyPositionals => ()
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "variadic positional keeps accepting hyphen values after first token" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.PositionalArg(
      "tail",
      index=0,
      num_args=@argparse.ValueRange(lower=0),
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
  let cmd = @argparse.Command("demo", args=[
    @argparse.PositionalArg(
      "first",
      index=0,
      num_args=@argparse.ValueRange(lower=1, upper=2),
    ),
    @argparse.PositionalArg("second", index=1, required=true),
  ])

  let two = cmd.parse(argv=["a", "b"], env=empty_env()) catch { _ => panic() }
  assert_true(two.values is { "first": ["a"], "second": ["b"], .. })

  let three = cmd.parse(argv=["a", "b", "c"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(three.values is { "first": ["a", "b"], "second": ["c"], .. })
}

///|
test "env parsing for settrue setfalse count and invalid values" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.FlagArg(
      "on",
      long="on",
      action=@argparse.FlagAction::SetTrue,
      env="ON",
    ),
    @argparse.FlagArg(
      "off",
      long="off",
      action=@argparse.FlagAction::SetFalse,
      env="OFF",
    ),
    @argparse.FlagArg(
      "v",
      long="v",
      action=@argparse.FlagAction::Count,
      env="V",
    ),
  ])

  let parsed = cmd.parse(argv=[], env={ "ON": "true", "OFF": "true", "V": "3" }) catch {
    _ => panic()
  }
  assert_true(parsed.flags is { "on": true, "off": false, "v": true, .. })
  assert_true(parsed.flag_counts is { "v": 3, .. })
  assert_true(
    parsed.sources
    is {
      "on": @argparse.ValueSource::Env,
      "off": @argparse.ValueSource::Env,
      "v": @argparse.ValueSource::Env,
      ..
    },
  )

  try cmd.parse(argv=[], env={ "ON": "bad" }) catch {
    @argparse.ArgParseError::InvalidValue(msg) =>
      inspect(
        msg,
        content=(
          #|invalid value 'bad' for boolean flag; expected one of: 1, 0, true, false, yes, no, on, off
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=[], env={ "OFF": "bad" }) catch {
    @argparse.ArgParseError::InvalidValue(msg) =>
      inspect(
        msg,
        content=(
          #|invalid value 'bad' for boolean flag; expected one of: 1, 0, true, false, yes, no, on, off
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=[], env={ "V": "bad" }) catch {
    @argparse.ArgParseError::InvalidValue(msg) =>
      inspect(
        msg,
        content=(
          #|invalid value 'bad' for count; expected a non-negative integer
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=[], env={ "V": "-1" }) catch {
    @argparse.ArgParseError::InvalidValue(msg) =>
      inspect(
        msg,
        content=(
          #|invalid value '-1' for count; expected a non-negative integer
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "defaults and value range helpers through public API" {
  let defaults = @argparse.Command("demo", args=[
    @argparse.OptionArg(
      "mode",
      long="mode",
      default_values=["a", "b"],
      num_args=@argparse.ValueRange(lower=1),
    ),
    @argparse.OptionArg("one", long="one", default_values=["x"]),
  ])
  let by_default = defaults.parse(argv=[], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(by_default.values is { "mode": ["a", "b"], "one": ["x"], .. })
  assert_true(
    by_default.sources
    is {
      "mode": @argparse.ValueSource::Default,
      "one": @argparse.ValueSource::Default,
      ..
    },
  )

  let upper_only = @argparse.Command("demo", args=[
    @argparse.OptionArg(
      "tag",
      long="tag",
      action=@argparse.OptionAction::Append,
      num_args=@argparse.ValueRange(lower=1, upper=2),
    ),
  ])
  let upper_parsed = upper_only.parse(
    argv=["--tag", "a", "--tag", "b", "--tag", "c"],
    env=empty_env(),
  ) catch {
    _ => panic()
  }
  assert_true(upper_parsed.values is { "tag": ["a", "b", "c"], .. })

  let lower_only = @argparse.Command("demo", args=[
    @argparse.OptionArg(
      "tag",
      long="tag",
      num_args=@argparse.ValueRange(lower=1),
    ),
  ])
  let lower_absent = lower_only.parse(argv=[], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(lower_absent.values is { "tag"? : None, .. })

  try lower_only.parse(argv=["--tag"], env=empty_env()) catch {
    @argparse.ArgParseError::MissingValue(name) => assert_true(name == "--tag")
    _ => panic()
  } noraise {
    _ => panic()
  }

  let empty_range = @argparse.ValueRange::empty()
  let single_range = @argparse.ValueRange::single()
  inspect(
    (empty_range, single_range),
    content=(
      #|({lower: 0, upper: Some(0)}, {lower: 1, upper: Some(1)})
    ),
  )
}

///|
test "num_args options consume argv values in one occurrence" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.OptionArg(
      "tag",
      long="tag",
      num_args=@argparse.ValueRange(lower=2, upper=2),
    ),
  ])
  let parsed = cmd.parse(argv=["--tag", "a", "b"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "tag": ["a", "b"], .. })
  assert_true(parsed.sources is { "tag": @argparse.ValueSource::Argv, .. })
}

///|
test "set options reject duplicate occurrences" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.OptionArg("mode", long="mode"),
  ])
  try cmd.parse(argv=["--mode", "a", "--mode", "b"], env=empty_env()) catch {
    @argparse.ArgParseError::InvalidArgument(msg) =>
      inspect(msg, content="argument '--mode' cannot be used multiple times")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "flag and option args require short or long names" {
  try
    @argparse.Command("demo", args=[@argparse.OptionArg("input")]).parse(
      argv=[],
      env=empty_env(),
    )
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(msg, content="flag/option args require short/long")
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", args=[@argparse.FlagArg("verbose")]).parse(
      argv=[],
      env=empty_env(),
    )
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(msg, content="flag/option args require short/long")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "num_args range option consumes optional extra argv value" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.OptionArg(
      "arg",
      long="arg",
      num_args=@argparse.ValueRange(lower=1, upper=2),
    ),
  ])
  let parsed = cmd.parse(argv=["--arg", "x", "y"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "arg": ["x", "y"], .. })
  assert_true(parsed.sources is { "arg": @argparse.ValueSource::Argv, .. })
}

///|
test "num_args range option stops at the next option token" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.OptionArg(
      "arg",
      short='a',
      long="arg",
      num_args=@argparse.ValueRange(lower=1, upper=2),
    ),
    @argparse.FlagArg("verbose", long="verbose"),
  ])

  let stopped = cmd.parse(argv=["--arg", "x", "--verbose"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(stopped.values is { "arg": ["x"], .. })
  assert_true(stopped.flags is { "verbose": true, .. })

  let inline = cmd.parse(argv=["--arg=x", "y", "--verbose"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(inline.values is { "arg": ["x", "y"], .. })
  assert_true(inline.flags is { "verbose": true, .. })

  let short_inline = cmd.parse(argv=["-ax", "y", "--verbose"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(short_inline.values is { "arg": ["x", "y"], .. })
  assert_true(short_inline.flags is { "verbose": true, .. })
}

///|
test "option num_args cannot be flag-like" {
  try
    @argparse.Command("demo", args=[
      @argparse.OptionArg(
        "opt",
        long="opt",
        num_args=@argparse.ValueRange(lower=0, upper=1),
      ),
      @argparse.FlagArg("verbose", long="verbose"),
    ]).parse(argv=["--opt", "--verbose"], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(msg, content="option args require at least one value")
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", args=[
      @argparse.OptionArg(
        "opt",
        long="opt",
        required=true,
        num_args=@argparse.ValueRange(lower=0, upper=0),
      ),
    ]).parse(argv=["--opt"], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(msg, content="option args require at least one value")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "option values reject hyphen tokens unless allow_hyphen_values is enabled" {
  let strict = @argparse.Command("demo", args=[
    @argparse.OptionArg("pattern", long="pattern"),
  ])
  let mut rejected = false
  try strict.parse(argv=["--pattern", "-file"], env=empty_env()) catch {
    @argparse.ArgParseError::MissingValue(name) => {
      assert_true(name == "--pattern")
      rejected = true
    }
    @argparse.ArgParseError::UnknownArgument(arg, _) => {
      assert_true(arg == "-f")
      rejected = true
    }
    _ => panic()
  } noraise {
    _ => ()
  }
  assert_true(rejected)

  let permissive = @argparse.Command("demo", args=[
    @argparse.OptionArg("pattern", long="pattern", allow_hyphen_values=true),
  ])
  let parsed = permissive.parse(argv=["--pattern", "-file"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "pattern": ["-file"], .. })
  assert_true(parsed.sources is { "pattern": @argparse.ValueSource::Argv, .. })
}

///|
test "from_matches uses public decoding hook" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.OptionArg("name", long="name"),
  ])
  let matches = cmd.parse(argv=["--name", "alice"], env=empty_env()) catch {
    _ => panic()
  }
  let decoded : DecodeName = @argparse.from_matches(matches) catch {
    _ => panic()
  }
  assert_true(decoded.name == "alice")
}

///|
test "default argv path is reachable" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.PositionalArg(
      "rest",
      num_args=@argparse.ValueRange(lower=0),
      allow_hyphen_values=true,
    ),
  ])
  let _ = cmd.parse(env=empty_env()) catch { _ => panic() }
}

///|
test "validation branches exposed through parse" {
  try
    @argparse.Command("demo", args=[
      @argparse.OptionArg("x", long="x", last=true),
    ]).parse(argv=[], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|positional-only settings require no short/long
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", args=[
      @argparse.FlagArg("f", action=@argparse.FlagAction::Help),
    ]).parse(argv=[], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|flag/option args require short/long
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", args=[
      @argparse.FlagArg(
        "f",
        long="f",
        action=@argparse.FlagAction::Help,
        negatable=true,
      ),
    ]).parse(argv=[], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|help/version actions do not support negatable
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", args=[
      @argparse.FlagArg(
        "f",
        long="f",
        action=@argparse.FlagAction::Help,
        env="F",
      ),
    ]).parse(argv=[], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|help/version actions do not support env/defaults
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", args=[
      @argparse.OptionArg(
        "x",
        long="x",
        num_args=@argparse.ValueRange(lower=2, upper=2),
      ),
    ]).parse(argv=["--x", "a", "--x", "b"], env=empty_env())
  catch {
    @argparse.ArgParseError::TooFewValues(name, got, min) => {
      assert_true(name == "x")
      assert_true(got == 1)
      assert_true(min == 2)
    }
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", args=[
      @argparse.OptionArg("x", long="x", default_values=["a", "b"]),
    ]).parse(argv=[], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|default_values require action=Append or num_args allowing >1
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", args=[
      @argparse.OptionArg(
        "x",
        long="x",
        num_args=@argparse.ValueRange(lower=3, upper=2),
      ),
    ]).parse(argv=[], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|max values must be >= min values
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", groups=[
      @argparse.ArgGroup("g"),
      @argparse.ArgGroup("g"),
    ]).parse(argv=[], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|duplicate group: g
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", groups=[@argparse.ArgGroup("g", requires=["g"])]).parse(
      argv=[],
      env=empty_env(),
    )
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|group cannot require itself: g
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", groups=[
      @argparse.ArgGroup("g", conflicts_with=["g"]),
    ]).parse(argv=[], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|group cannot conflict with itself: g
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", groups=[@argparse.ArgGroup("g", args=["missing"])]).parse(
      argv=[],
      env=empty_env(),
    )
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|unknown group arg: g -> missing
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", args=[
      @argparse.OptionArg("x", long="x"),
      @argparse.OptionArg("x", long="y"),
    ]).parse(argv=[], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|duplicate arg name: x
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", args=[
      @argparse.OptionArg("x", long="same"),
      @argparse.OptionArg("y", long="same"),
    ]).parse(argv=[], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|duplicate long option: --same
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", args=[
      @argparse.FlagArg("hello", long="hello", negatable=true),
      @argparse.FlagArg("x", long="no-hello"),
    ]).parse(argv=[], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|duplicate long option: --no-hello
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", args=[
      @argparse.OptionArg("x", short='s'),
      @argparse.OptionArg("y", short='s'),
    ]).parse(argv=[], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|duplicate short option: -s
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", args=[
      @argparse.FlagArg("x", long="x", requires=["x"]),
    ]).parse(argv=[], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|arg cannot require itself: x
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", args=[
      @argparse.FlagArg("x", long="x", conflicts_with=["x"]),
    ]).parse(argv=[], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|arg cannot conflict with itself: x
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", subcommands=[
      @argparse.Command("x"),
      @argparse.Command("x"),
    ]).parse(argv=[], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|duplicate subcommand: x
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", subcommand_required=true).parse(
      argv=[],
      env=empty_env(),
    )
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|subcommand_required requires at least one subcommand
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", subcommands=[@argparse.Command("help")]).parse(
      argv=[],
      env=empty_env(),
    )
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|subcommand name reserved for built-in help: help (disable with disable_help_subcommand)
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  let custom_help = @argparse.Command("demo", args=[
    @argparse.FlagArg(
      "custom_help",
      short='h',
      long="help",
      about="custom help",
    ),
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

  let custom_version = @argparse.Command("demo", version="1.0", args=[
    @argparse.FlagArg(
      "custom_version",
      short='V',
      long="version",
      about="custom version",
    ),
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
    @argparse.Command("demo", args=[
      @argparse.FlagArg("v", long="v", action=@argparse.FlagAction::Version),
    ]).parse(argv=[], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|version action requires command version text
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "builtin and custom help/version dispatch edge paths" {
  let versioned = @argparse.Command("demo", version="1.2.3")
  try versioned.parse(argv=["-V"], env=empty_env()) catch {
    @argparse.DisplayVersion::Message(text) => assert_true(text == "1.2.3")
    _ => panic()
  } noraise {
    _ => panic()
  }

  try versioned.parse(argv=["--help"], env=empty_env()) catch {
    @argparse.DisplayHelp::Message(text) =>
      assert_true(text.has_prefix("Usage: demo"))
    _ => panic()
  } noraise {
    _ => panic()
  }

  try versioned.parse(argv=["-hV"], env=empty_env()) catch {
    @argparse.DisplayHelp::Message(_) => ()
    _ => panic()
  } noraise {
    _ => panic()
  }

  try versioned.parse(argv=["-Vh"], env=empty_env()) catch {
    @argparse.DisplayVersion::Message(text) => assert_true(text == "1.2.3")
    _ => panic()
  } noraise {
    _ => panic()
  }

  let long_help = @argparse.Command("demo", args=[
    @argparse.FlagArg(
      "assist",
      long="assist",
      action=@argparse.FlagAction::Help,
    ),
  ])
  try long_help.parse(argv=["--assist"], env=empty_env()) catch {
    @argparse.DisplayHelp::Message(text) =>
      assert_true(text.has_prefix("Usage: demo"))
    _ => panic()
  } noraise {
    _ => panic()
  }

  let short_help = @argparse.Command("demo", args=[
    @argparse.FlagArg("assist", short='?', action=@argparse.FlagAction::Help),
  ])
  try short_help.parse(argv=["-?"], env=empty_env()) catch {
    @argparse.DisplayHelp::Message(text) =>
      assert_true(text.has_prefix("Usage: demo"))
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "subcommand lookup falls back to positional value" {
  let cmd = @argparse.Command(
    "demo",
    args=[@argparse.PositionalArg("input", index=0)],
    subcommands=[@argparse.Command("run")],
  )
  let parsed = cmd.parse(argv=["raw"], env=empty_env()) catch { _ => panic() }
  assert_true(parsed.values is { "input": ["raw"], .. })
  assert_true(parsed.subcommand is None)
}

///|
test "group validation catches unknown requires target" {
  try
    @argparse.Command("demo", groups=[
      @argparse.ArgGroup("g", requires=["missing"]),
    ]).parse(argv=[], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(msg, content="unknown group requires target: g -> missing")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "group validation catches unknown conflicts_with target" {
  try
    @argparse.Command("demo", groups=[
      @argparse.ArgGroup("g", conflicts_with=["missing"]),
    ]).parse(argv=[], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(msg, content="unknown group conflicts_with target: g -> missing")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "group assignment auto-creates missing group definition" {
  let cmd = @argparse.Command("demo", groups=[@argparse.ArgGroup("known")], args=[
    @argparse.FlagArg("x", long="x", group="missing"),
  ])
  let parsed = cmd.parse(argv=["--x"], env=empty_env()) catch { _ => panic() }
  assert_true(parsed.flags is { "x": true, .. })
  let help = cmd.render_help()
  assert_true(help.has_prefix("Usage: demo [options]"))
}

///|
test "arg validation catches unknown requires target" {
  try
    @argparse.Command("demo", args=[
      @argparse.OptionArg("mode", long="mode", requires=["missing"]),
    ]).parse(argv=["--mode", "fast"], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(msg, content="unknown requires target: mode -> missing")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "arg validation catches unknown conflicts_with target" {
  try
    @argparse.Command("demo", args=[
      @argparse.OptionArg("mode", long="mode", conflicts_with=["missing"]),
    ]).parse(argv=["--mode", "fast"], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(msg, content="unknown conflicts_with target: mode -> missing")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "empty groups without presence do not fail" {
  let grouped_ok = @argparse.Command(
    "demo",
    groups=[@argparse.ArgGroup("left"), @argparse.ArgGroup("right")],
    args=[
      @argparse.FlagArg("l", long="left", group="left"),
      @argparse.FlagArg("r", long="right", group="right"),
    ],
  )
  let parsed = grouped_ok.parse(argv=["--left"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.flags is { "l": true, .. })
}

///|
test "help rendering edge paths stay stable" {
  let required_many = @argparse.Command("demo", args=[
    @argparse.PositionalArg(
      "files",
      index=0,
      required=true,
      num_args=@argparse.ValueRange(lower=1),
    ),
  ])
  let required_help = required_many.render_help()
  assert_true(required_help.has_prefix("Usage: demo <files...>"))

  let short_only_builtin = @argparse.Command("demo", args=[
    @argparse.OptionArg("helpopt", long="help"),
  ])
  let short_only_text = short_only_builtin.render_help()
  assert_true(short_only_text.has_prefix("Usage: demo"))
  try short_only_builtin.parse(argv=["-h"], env=empty_env()) catch {
    @argparse.DisplayHelp::Message(_) => ()
    _ => panic()
  } noraise {
    _ => panic()
  }
  try short_only_builtin.parse(argv=["--help"], env=empty_env()) catch {
    @argparse.ArgParseError::MissingValue(name) => assert_true(name == "--help")
    _ => panic()
  } noraise {
    _ => panic()
  }

  let long_only_builtin = @argparse.Command("demo", args=[
    @argparse.FlagArg("custom_h", short='h'),
  ])
  let long_only_text = long_only_builtin.render_help()
  assert_true(long_only_text.has_prefix("Usage: demo"))
  try long_only_builtin.parse(argv=["--help"], env=empty_env()) catch {
    @argparse.DisplayHelp::Message(_) => ()
    _ => panic()
  } noraise {
    _ => panic()
  }
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

  let implicit_group = @argparse.Command("demo", args=[
    @argparse.PositionalArg("item", index=0, group="dyn"),
  ])
  let implicit_group_help = implicit_group.render_help()
  assert_true(implicit_group_help.has_prefix("Usage: demo [item]"))

  let sub_visible = @argparse.Command("demo", disable_help_subcommand=true, subcommands=[
    @argparse.Command("run"),
  ])
  let sub_help = sub_visible.render_help()
  assert_true(sub_help.has_prefix("Usage: demo <command>"))
}

///|
test "parse error formatting covers public variants" {
  assert_true(
    @argparse.ArgParseError::UnknownArgument("--oops", None).to_string() ==
    "error: unexpected argument '--oops' found",
  )
  assert_true(
    @argparse.ArgParseError::InvalidArgument("--bad").to_string() ==
    "error: unexpected argument '--bad' found",
  )
  assert_true(
    @argparse.ArgParseError::InvalidArgument("custom message").to_string() ==
    "error: custom message",
  )
  assert_true(
    @argparse.ArgParseError::MissingValue("--name").to_string() ==
    "error: a value is required for '--name' but none was supplied",
  )
  assert_true(
    @argparse.ArgParseError::MissingRequired("name").to_string() ==
    "error: the following required argument was not provided: 'name'",
  )
  assert_true(
    @argparse.ArgParseError::TooFewValues("tag", 1, 2).to_string() ==
    "error: 'tag' requires at least 2 values but only 1 were provided",
  )
  assert_true(
    @argparse.ArgParseError::TooManyValues("tag", 3, 2).to_string() ==
    "error: 'tag' allows at most 2 values but 3 were provided",
  )
  assert_true(
    @argparse.ArgParseError::InvalidValue("bad int").to_string() ==
    "error: bad int",
  )
  assert_true(
    @argparse.ArgParseError::MissingGroup("mode").to_string() ==
    "error: the following required argument group was not provided: 'mode'",
  )
  assert_true(
    @argparse.ArgParseError::GroupConflict("mode").to_string() ==
    "error: group conflict mode",
  )
}

///|
test "range constructors with open lower bound still validate shape rules" {
  try
    @argparse.Command("demo", args=[
      @argparse.OptionArg(
        "tag",
        long="tag",
        num_args=@argparse.ValueRange::new(upper=2),
      ),
    ]).parse(argv=["--tag", "x"], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(msg, content="option args require at least one value")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "short option with bounded values reports per occurrence too few values" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.OptionArg(
      "x",
      short='x',
      num_args=@argparse.ValueRange(lower=2, upper=2),
    ),
    @argparse.FlagArg("verbose", short='v'),
  ])
  try cmd.parse(argv=["-x", "a", "-v"], env=empty_env()) catch {
    @argparse.ArgParseError::TooFewValues(name, got, min) => {
      assert_true(name == "x")
      assert_true(got == 1)
      assert_true(min == 2)
    }
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "version action dispatches on custom long and short flags" {
  let cmd = @argparse.Command("demo", version="2.0.0", args=[
    @argparse.FlagArg(
      "show_long",
      long="show-version",
      action=@argparse.FlagAction::Version,
    ),
    @argparse.FlagArg(
      "show_short",
      short='S',
      action=@argparse.FlagAction::Version,
    ),
  ])

  try cmd.parse(argv=["--show-version"], env=empty_env()) catch {
    @argparse.DisplayVersion::Message(text) => assert_true(text == "2.0.0")
    _ => panic()
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["-S"], env=empty_env()) catch {
    @argparse.DisplayVersion::Message(text) => assert_true(text == "2.0.0")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "required and env-fed ranged values validate after parsing" {
  let required_cmd = @argparse.Command("demo", args=[
    @argparse.OptionArg("input", long="input", required=true),
  ])
  try required_cmd.parse(argv=[], env=empty_env()) catch {
    @argparse.ArgParseError::MissingRequired(name) =>
      assert_true(name == "input")
    _ => panic()
  } noraise {
    _ => panic()
  }

  let env_min_cmd = @argparse.Command("demo", args=[
    @argparse.OptionArg(
      "pair",
      long="pair",
      env="PAIR",
      num_args=@argparse.ValueRange(lower=2, upper=3),
    ),
  ])
  try env_min_cmd.parse(argv=[], env={ "PAIR": "one" }) catch {
    @argparse.ArgParseError::TooFewValues(name, got, min) => {
      assert_true(name == "pair")
      assert_true(got == 1)
      assert_true(min == 2)
    }
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "positionals hit balancing branches and explicit index sorting" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.PositionalArg(
      "first",
      index=0,
      num_args=@argparse.ValueRange(lower=2, upper=3),
    ),
    @argparse.PositionalArg("late", index=2, required=true),
    @argparse.PositionalArg(
      "mid",
      index=1,
      num_args=@argparse.ValueRange(lower=2, upper=2),
    ),
  ])

  try cmd.parse(argv=["a"], env=empty_env()) catch {
    @argparse.ArgParseError::TooFewValues(name, got, min) => {
      assert_true(name == "first")
      assert_true(got == 1)
      assert_true(min == 2)
    }
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "positional max clamp leaves trailing value for next positional" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.PositionalArg(
      "items",
      index=0,
      num_args=@argparse.ValueRange(lower=0, upper=2),
    ),
    @argparse.PositionalArg("tail", index=1),
  ])

  let parsed = cmd.parse(argv=["a", "b", "c"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "items": ["a", "b"], "tail": ["c"], .. })
}

///|
test "open upper range options consume option-like values with allow_hyphen_values" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.OptionArg(
      "arg",
      long="arg",
      allow_hyphen_values=true,
      num_args=@argparse.ValueRange(lower=1),
    ),
    @argparse.FlagArg("verbose", long="verbose"),
    @argparse.FlagArg("cache", long="cache", negatable=true),
    @argparse.FlagArg("quiet", short='q'),
  ])

  let known_long = cmd.parse(argv=["--arg", "x", "--verbose"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(known_long.values is { "arg": ["x", "--verbose"], .. })
  assert_true(known_long.flags is { "verbose"? : None, .. })

  let negated = cmd.parse(argv=["--arg", "x", "--no-cache"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(negated.values is { "arg": ["x", "--no-cache"], .. })
  assert_true(negated.flags is { "cache"? : None, .. })

  let unknown_long_value = cmd.parse(
    argv=["--arg", "x", "--mystery"],
    env=empty_env(),
  ) catch {
    _ => panic()
  }
  assert_true(unknown_long_value.values is { "arg": ["x", "--mystery"], .. })

  let known_short = cmd.parse(argv=["--arg", "x", "-q"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(known_short.values is { "arg": ["x", "-q"], .. })
  assert_true(known_short.flags is { "quiet"? : None, .. })

  let cmd_with_rest = @argparse.Command("demo", args=[
    @argparse.OptionArg(
      "arg",
      long="arg",
      allow_hyphen_values=true,
      num_args=@argparse.ValueRange(lower=1),
    ),
    @argparse.PositionalArg(
      "rest",
      index=0,
      num_args=@argparse.ValueRange(lower=0),
      allow_hyphen_values=true,
    ),
  ])
  let sentinel_stop = cmd_with_rest.parse(
    argv=["--arg", "x", "--", "tail"],
    env=empty_env(),
  ) catch {
    _ => panic()
  }
  assert_true(
    sentinel_stop.values is { "arg": ["x", "--", "tail"], "rest"? : None, .. },
  )
}

///|
test "fixed upper range avoids consuming additional option values" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.OptionArg(
      "one",
      long="one",
      num_args=@argparse.ValueRange(lower=1, upper=1),
    ),
    @argparse.FlagArg("verbose", long="verbose"),
  ])

  let parsed = cmd.parse(argv=["--one", "x", "--verbose"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "one": ["x"], .. })
  assert_true(parsed.flags is { "verbose": true, .. })
}

///|
test "bounded long options report too few values when next token is another option" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.OptionArg(
      "arg",
      long="arg",
      num_args=@argparse.ValueRange(lower=2, upper=2),
    ),
    @argparse.FlagArg("verbose", long="verbose"),
  ])

  let ok = cmd.parse(argv=["--arg", "x", "y", "--verbose"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(ok.values is { "arg": ["x", "y"], .. })
  assert_true(ok.flags is { "verbose": true, .. })

  try cmd.parse(argv=["--arg", "x", "--verbose"], env=empty_env()) catch {
    @argparse.ArgParseError::TooFewValues(name, got, min) => {
      assert_true(name == "arg")
      assert_true(got == 1)
      assert_true(min == 2)
    }
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "short-only set options use short label in duplicate errors" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.OptionArg("mode", short='m'),
  ])
  try cmd.parse(argv=["-m", "a", "-m", "b"], env=empty_env()) catch {
    @argparse.ArgParseError::InvalidArgument(msg) =>
      inspect(msg, content="argument '-m' cannot be used multiple times")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "unknown short suggestion can be absent" {
  let cmd = @argparse.Command("demo", disable_help_flag=true, args=[
    @argparse.OptionArg("name", long="name"),
  ])

  try cmd.parse(argv=["-x"], env=empty_env()) catch {
    @argparse.ArgParseError::UnknownArgument(arg, hint) => {
      assert_true(arg == "-x")
      assert_true(hint is None)
    }
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "setfalse flags apply false when present" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.FlagArg(
      "failfast",
      long="failfast",
      action=@argparse.FlagAction::SetFalse,
    ),
  ])
  let parsed = cmd.parse(argv=["--failfast"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.flags is { "failfast": false, .. })
  assert_true(parsed.sources is { "failfast": @argparse.ValueSource::Argv, .. })
}

///|
test "allow_hyphen positional treats unknown long token as value" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.PositionalArg("input", index=0, allow_hyphen_values=true),
    @argparse.FlagArg("known", long="known"),
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
    args=[
      @argparse.OptionArg(
        "mode",
        long="mode",
        default_values=["safe"],
        global=true,
      ),
      @argparse.OptionArg("unused", long="unused", global=true),
    ],
    subcommands=[@argparse.Command("run")],
  )

  let parsed = cmd.parse(argv=["run"], env=empty_env()) catch { _ => panic() }
  assert_true(parsed.values is { "mode": ["safe"], "unused"? : None, .. })
  assert_true(parsed.sources is { "mode": @argparse.ValueSource::Default, .. })
  assert_true(
    parsed.subcommand is Some(("run", sub)) &&
    sub.values is { "mode": ["safe"], .. } &&
    sub.sources is { "mode": @argparse.ValueSource::Default, .. },
  )
}

///|
test "child local arg with global name does not update parent global" {
  let cmd = @argparse.Command(
    "demo",
    args=[
      @argparse.OptionArg(
        "mode",
        long="mode",
        default_values=["safe"],
        global=true,
      ),
    ],
    subcommands=[
      @argparse.Command("run", args=[@argparse.OptionArg("mode", long="mode")]),
    ],
  )

  let parsed = cmd.parse(argv=["run", "--mode", "fast"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "mode": ["safe"], .. })
  assert_true(parsed.sources is { "mode": @argparse.ValueSource::Default, .. })
  assert_true(
    parsed.subcommand is Some(("run", sub)) &&
    sub.values is { "mode": ["fast"], .. } &&
    sub.sources is { "mode": @argparse.ValueSource::Argv, .. },
  )
}

///|
test "global append env value from child is merged back to parent" {
  let cmd = @argparse.Command(
    "demo",
    args=[
      @argparse.OptionArg(
        "tag",
        long="tag",
        action=@argparse.OptionAction::Append,
        env="TAG",
        global=true,
      ),
    ],
    subcommands=[@argparse.Command("run")],
  )

  let parsed = cmd.parse(argv=["run"], env={ "TAG": "env-tag" }) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "tag": ["env-tag"], .. })
  assert_true(parsed.sources is { "tag": @argparse.ValueSource::Env, .. })
  assert_true(
    parsed.subcommand is Some(("run", sub)) &&
    sub.values is { "tag": ["env-tag"], .. } &&
    sub.sources is { "tag": @argparse.ValueSource::Env, .. },
  )
}

///|
test "global flag set in child argv is merged back to parent" {
  let cmd = @argparse.Command(
    "demo",
    args=[@argparse.FlagArg("verbose", long="verbose", global=true)],
    subcommands=[@argparse.Command("run")],
  )

  let parsed = cmd.parse(argv=["run", "--verbose"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.flags is { "verbose": true, .. })
  assert_true(parsed.sources is { "verbose": @argparse.ValueSource::Argv, .. })
  assert_true(
    parsed.subcommand is Some(("run", sub)) &&
    sub.flags is { "verbose": true, .. } &&
    sub.sources is { "verbose": @argparse.ValueSource::Argv, .. },
  )
}
