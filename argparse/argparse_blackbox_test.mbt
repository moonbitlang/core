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
test "render long help snapshot with groups and hidden entries" {
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
      @argparse.PositionalArg("rest", index=1, multiple=true),
      @argparse.PositionalArg("secret", index=2, hidden=true),
    ],
  )
  inspect(
    cmd.render_long_help(),
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
        default_value="1",
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
        default_value="p",
        default_values=["p1", "p2"],
        num_args=@argparse.ValueRange(lower=0, upper=2),
        multiple=true,
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
        multiple=true,
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
  assert_true(matches.subcommand is Some(("run", _)))
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
  assert_true(matches.subcommand is Some(("run", _)))
}

///|
test "help subcommand styles and errors" {
  let leaf = @argparse.Command("echo", about="echo")
  let cmd = @argparse.Command("demo", subcommands=[leaf])

  try cmd.parse(argv=["help", "echo", "-h"], env=empty_env()) catch {
    @argparse.DisplayHelp::Short(text) =>
      inspect(
        text,
        content=(
          #|Usage: echo
          #|
          #|echo
          #|
          #|Options:
          #|  -h, --help  Show help information.

        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["help", "echo", "--help"], env=empty_env()) catch {
    @argparse.DisplayHelp::Long(text) =>
      inspect(
        text,
        content=(
          #|Usage: echo
          #|
          #|echo
          #|
          #|Options:
          #|  -h, --help  Show help information.

        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["help"], env=empty_env()) catch {
    @argparse.DisplayHelp::Long(text) =>
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
}

///|
test "positionals force mode and dash handling" {
  let force_cmd = @argparse.Command("demo", args=[
    @argparse.PositionalArg(
      "tail",
      index=0,
      multiple=true,
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
  assert_true(dashed.values is { "tail": ["--", "p", "q"], .. })

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
          #|invalid bool: bad

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
          #|invalid bool: bad

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
          #|invalid int: bad

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
    @argparse.OptionArg("mode", long="mode", multiple=true, default_values=[
      "a", "b",
    ]),
    @argparse.OptionArg("one", long="one", default_value="x"),
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
      multiple=true,
      num_args=@argparse.ValueRange(upper=2),
    ),
  ])
  try
    upper_only.parse(
      argv=["--tag", "a", "--tag", "b", "--tag", "c"],
      env=empty_env(),
    )
  catch {
    @argparse.ArgParseError::TooManyValues(name, got, max) => {
      assert_true(name == "tag")
      assert_true(got == 3)
      assert_true(max == 2)
    }
    _ => panic()
  } noraise {
    _ => panic()
  }

  let lower_only = @argparse.Command("demo", args=[
    @argparse.OptionArg(
      "tag",
      long="tag",
      multiple=true,
      num_args=@argparse.ValueRange(lower=1),
    ),
  ])
  try lower_only.parse(argv=[], env=empty_env()) catch {
    @argparse.ArgParseError::TooFewValues(name, got, min) => {
      assert_true(name == "tag")
      assert_true(got == 0)
      assert_true(min == 1)
    }
    _ => panic()
  } noraise {
    _ => panic()
  }

  let empty_range = @argparse.ValueRange::empty()
  let single_range = @argparse.ValueRange::single()
  inspect(
    (empty_range, single_range),
    content=(
      #|({lower: Some(0), upper: Some(0), lower_inclusive: true, upper_inclusive: true}, {lower: Some(1), upper: Some(1), lower_inclusive: true, upper_inclusive: true})
    ),
  )
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
    @argparse.PositionalArg("rest", multiple=true, allow_hyphen_values=true),
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
          #|help/version actions require short/long option

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
    ]).parse(argv=[], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|multiple values require multiple/append

        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", args=[
      @argparse.FlagArg("f", long="f", default_value="1"),
    ]).parse(argv=[], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|default values require value-taking arguments

        ),
      )
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
          #|default_values require multiple/append arguments

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
        multiple=true,
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

  try
    @argparse.Command("demo", args=[@argparse.FlagArg("h", long="help")]).parse(
      argv=[],
      env=empty_env(),
    )
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|option name reserved for built-in help: --help (disable with disable_help_flag)

        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", args=[@argparse.FlagArg("h", short='h')]).parse(
      argv=[],
      env=empty_env(),
    )
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|option name reserved for built-in help: -h (disable with disable_help_flag)

        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", version="1.0", args=[
      @argparse.FlagArg("v", long="version"),
    ]).parse(argv=[], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|option name reserved for built-in version: --version (disable with disable_version_flag)

        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    @argparse.Command("demo", version="1.0", args=[
      @argparse.FlagArg("v", short='V'),
    ]).parse(argv=[], env=empty_env())
  catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|option name reserved for built-in version: -V (disable with disable_version_flag)

        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }

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
