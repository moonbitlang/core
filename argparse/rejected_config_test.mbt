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
/// Rejected command definitions, not argv parse failures.
///
/// Flags/options without an argv spelling or env source are dead config: they
/// can appear in relationships and help, but users can never set them.
test "flag and option config requires an argv or env spelling" {
  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", options=[OptionArg("input", long="")]).parse(
        argv=[],
        env=empty_env(),
      )
    }),
    content=(
      #|error: command definition validation failed: flag/option args require short/long/env
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", flags=[FlagArg("verbose", long="")]).parse(
        argv=[],
        env=empty_env(),
      )
    }),
    content=(
      #|error: command definition validation failed: flag/option args require short/long/env
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", flags=[FlagArg("f", long="", action=Help)]).parse(
        argv=[],
        env=empty_env(),
      )
    }),
    content=(
      #|error: command definition validation failed: flag/option args require short/long/env
    ),
  )
}

///|
/// Default dispatch must have one visible target and must not conflict with
/// root-level policies that also claim bare argv or leading tokens.
test "default subcommand config rejects ambiguous root dispatch" {
  inspect(
    @test.expect_error(() => {
      @argparse.Command(
        "demo",
        subcommands=[Command("run")],
        default_subcommand="missing",
      ).parse(argv=[], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: default_subcommand must name a visible subcommand: missing
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command(
        "demo",
        subcommands=[Command("secret", hidden=true)],
        default_subcommand="secret",
      ).parse(argv=[], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: default_subcommand must name a visible subcommand: secret
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command(
        "demo",
        subcommands=[Command("run")],
        subcommand_required=true,
        default_subcommand="run",
      ).parse(argv=[], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: default_subcommand cannot be used with subcommand_required
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command(
        "demo",
        subcommands=[Command("run")],
        arg_required_else_help=true,
        default_subcommand="run",
      ).parse(argv=[], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: default_subcommand cannot be used with arg_required_else_help
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command(
        "demo",
        options=[OptionArg("mode", long="mode")],
        subcommands=[Command("run")],
        default_subcommand="run",
      ).parse(argv=[], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: default_subcommand only supports global root flags/options
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command(
        "demo",
        flags=[FlagArg("verbose", long="verbose", global=true)],
        groups=[ArgGroup("verbosity", args=["verbose"])],
        subcommands=[Command("run")],
        default_subcommand="run",
      ).parse(argv=[], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: default_subcommand does not support root groups
    ),
  )
}

///|
/// Value ranges must describe a non-empty, non-negative interval. Otherwise
/// positional allocation and usage output would encode impossible counts.
test "value range config rejects impossible counts" {
  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", positionals=[
        PositionArg("skip", num_args=ValueRange(lower=0, upper=0)),
        PositionArg("name", num_args=@argparse.ValueRange::single()),
      ]).parse(argv=["alice"], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: empty value range (0..0) is unsupported
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", positionals=[
        PositionArg("x", num_args=ValueRange(lower=3, upper=2)),
      ]).parse(argv=[], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: max values must be >= min values
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", positionals=[
        PositionArg("x", num_args=ValueRange(lower=-1, upper=2)),
      ]).parse(argv=[], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: min values must be >= 0
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", positionals=[
        PositionArg("x", num_args=ValueRange(lower=0, upper=-1)),
      ]).parse(argv=[], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: max values must be >= 0
    ),
  )
}

///|
/// Terminal actions and defaults need unambiguous triggers and output: no
/// negated help/version, no env-triggered terminal action, no multi-default Set.
test "action config rejects unsupported implicit behavior" {
  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", flags=[
        FlagArg("f", long="f", action=Help, negatable=true),
      ]).parse(argv=[], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: help/version actions do not support negatable
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", flags=[
        FlagArg("f", long="f", action=Help, env="F"),
      ]).parse(argv=[], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: help/version actions do not support env/defaults
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", options=[
        OptionArg("x", long="x", default_values=["a", "b"]),
      ]).parse(argv=[], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: default_values with multiple entries require action=Append
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", flags=[FlagArg("v", long="v", action=Version)]).parse(
        argv=[],
        env=empty_env(),
      )
    }),
    content=(
      #|error: command definition validation failed: version action requires command version text
    ),
  )
}

///|
/// Groups form a relationship graph. Duplicate names, self-edges, and missing
/// targets make that graph ambiguous, unsatisfiable, or impossible to report.
test "group config rejects circular or unknown relationships" {
  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", groups=[ArgGroup("g"), ArgGroup("g")]).parse(
        argv=[],
        env=empty_env(),
      )
    }),
    content=(
      #|error: command definition validation failed: duplicate group: g
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", groups=[ArgGroup("g", requires=["g"])]).parse(
        argv=[],
        env=empty_env(),
      )
    }),
    content=(
      #|error: command definition validation failed: group cannot require itself: g
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", groups=[ArgGroup("g", conflicts_with=["g"])]).parse(
        argv=[],
        env=empty_env(),
      )
    }),
    content=(
      #|error: command definition validation failed: group cannot conflict with itself: g
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", groups=[ArgGroup("g", args=["missing"])]).parse(
        argv=[],
        env=empty_env(),
      )
    }),
    content=(
      #|error: command definition validation failed: unknown group arg: g -> missing
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", groups=[ArgGroup("g", requires=["missing"])]).parse(
        argv=[],
        env=empty_env(),
      )
    }),
    content=(
      #|error: command definition validation failed: unknown group requires target: g -> missing
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", groups=[
        ArgGroup("g", conflicts_with=["missing"]),
      ]).parse(argv=[], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: unknown group conflicts_with target: g -> missing
    ),
  )
}

///|
/// Argument names and option aliases are parser keys. Duplicates make result
/// slots or argv tokens ambiguous; negatable flags also reserve `--no-<long>`.
test "argument config rejects duplicate names and aliases" {
  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", options=[
        OptionArg("x", long="x"),
        OptionArg("x", long="y"),
      ]).parse(argv=[], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: duplicate arg name: x
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", options=[
        OptionArg("x", long="same"),
        OptionArg("y", long="same"),
      ]).parse(argv=[], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: duplicate long option: --same
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", flags=[
        FlagArg("hello", long="hello", negatable=true),
        FlagArg("x", long="no-hello"),
      ]).parse(argv=[], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: duplicate long option: --no-hello
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", options=[
        OptionArg("x", short='s'),
        OptionArg("y", short='s'),
      ]).parse(argv=[], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: duplicate short option: -s
    ),
  )
}

///|
/// Argument relationships also form a graph over known args/groups. Self edges
/// and missing nodes create unsatisfiable or unreportable requirements.
test "argument relationship config rejects circular or unknown targets" {
  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", flags=[FlagArg("x", long="x", requires=["x"])]).parse(
        argv=[],
        env=empty_env(),
      )
    }),
    content=(
      #|error: command definition validation failed: arg cannot require itself: x
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", flags=[
        FlagArg("x", long="x", conflicts_with=["x"]),
      ]).parse(argv=[], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: arg cannot conflict with itself: x
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", options=[
        OptionArg("mode", long="mode", requires=["missing"]),
      ]).parse(argv=["--mode", "fast"], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: unknown requires target: mode -> missing
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", flags=[
        FlagArg("fast", long="fast", requires=["missing"]),
      ]).parse(argv=[], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: unknown requires target: fast -> missing
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", options=[
        OptionArg("mode", long="mode", conflicts_with=["missing"]),
      ]).parse(argv=["--mode", "fast"], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: unknown conflicts_with target: mode -> missing
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", subcommands=[
        Command("child", flags=[FlagArg("x", long="x", requires=["missing"])]),
      ]).parse(argv=[], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: unknown requires target: x -> missing
    ),
  )
}

///|
/// Subcommand names are dispatch keys, and built-in help owns its route.
/// Required-subcommand config must also provide at least one possible target.
test "subcommand config rejects ambiguous command surfaces" {
  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", subcommands=[Command("x"), Command("x")]).parse(
        argv=[],
        env=empty_env(),
      )
    }),
    content=(
      #|error: command definition validation failed: duplicate subcommand: x
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", subcommand_required=true).parse(
        argv=[],
        env=empty_env(),
      )
    }),
    content=(
      #|error: command definition validation failed: subcommand_required requires at least one subcommand
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", subcommands=[Command("help")]).parse(
        argv=[],
        env=empty_env(),
      )
    }),
    content=(
      #|error: command definition validation failed: subcommand name reserved for built-in help: help (disable with disable_help_subcommand)
    ),
  )
}

///|
/// Inherited globals share one Matches key across parent and child scopes.
/// Shadowing, alias reuse, or incompatible redeclarations would make merging
/// and dispatch depend on where the token appears.
test "global config rejects shadowing and incompatible redeclarations" {
  inspect(
    @test.expect_error(() => {
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
    }),
    content=(
      #|error: command definition validation failed: arg 'mode' shadows an inherited global; rename the arg or mark it global
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command(
        "demo",
        options=[OptionArg("mode", long="mode", required=true, global=true)],
        subcommands=[
          Command("run", flags=[FlagArg("mode", long="mode", global=true)]),
        ],
      ).parse(argv=["run", "--mode"], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: global arg 'mode' is incompatible with inherited global definition
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command(
        "demo",
        flags=[FlagArg("verbose", long="verbose", global=true)],
        subcommands=[
          Command("run", options=[OptionArg("local", long="verbose")]),
        ],
      ).parse(argv=["run", "--verbose"], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: arg 'local' long option --verbose conflicts with inherited global 'verbose'
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command(
        "demo",
        flags=[FlagArg("verbose", short='v', global=true)],
        subcommands=[Command("run", options=[OptionArg("local", short='v')])],
      ).parse(argv=["run", "-v"], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: arg 'local' short option -v conflicts with inherited global 'verbose'
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command(
        "demo",
        flags=[FlagArg("verbose", long="verbose", negatable=true, global=true)],
        subcommands=[
          Command("run", flags=[
            FlagArg("verbose", long="verbose", negatable=false, global=true),
          ]),
        ],
      ).parse(argv=["run"], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: global arg 'verbose' is incompatible with inherited global definition
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command(
        "demo",
        flags=[FlagArg("shared", long="shared", global=true)],
        subcommands=[
          Command("child", options=[
            OptionArg("shared", long="shared", global=true),
          ]),
        ],
      ).parse(argv=[], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: global arg 'shared' is incompatible with inherited global definition
    ),
  )

  inspect(
    @test.expect_error(() => {
      @argparse.Command(
        "demo",
        options=[OptionArg("opt", long="dup", global=true)],
        subcommands=[Command("child", flags=[FlagArg("other", long="dup")])],
      ).parse(argv=[], env=empty_env())
    }),
    content=(
      #|error: command definition validation failed: arg 'other' long option --dup conflicts with inherited global 'opt'
    ),
  )
}
