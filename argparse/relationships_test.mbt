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
test "relationships and num args" {
  let requires_cmd = @argparse.Command("demo", options=[
    OptionArg("mode", long="mode", requires=["config"]),
    OptionArg("config", long="config"),
  ])

  inspect(
    @test.expect_error(() => {
      requires_cmd.parse(argv=["--mode", "fast"], env=empty_env())
    }),
    content=(
      #|error: the following required argument was not provided: 'config' (required by 'mode')
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

  inspect(
    @test.expect_error(() => cmd.parse(argv=[], env=empty_env())),
    content=(
      #|error: the following required arguments were not provided:
      #|  <--fast|--slow>
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|  --fast      
      #|  --slow      
      #|
      #|Groups:
      #|  mode [required] [exclusive]  --fast, --slow
      #|
    ),
  )

  inspect(
    @test.expect_error(() => {
      cmd.parse(argv=["--fast", "--slow"], env=empty_env())
    }),
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
      #|  mode [required] [exclusive]  --fast, --slow
      #|
    ),
  )
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

  inspect(
    @test.expect_error(() => {
      requires_cmd.parse(argv=["--fast"], env=empty_env())
    }),
    content=(
      #|error: the following required arguments were not provided:
      #|  <--json>
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

  let conflict_cmd = @argparse.Command(
    "demo",
    groups=[
      ArgGroup("mode", args=["fast"], conflicts_with=["output"]),
      ArgGroup("output", args=["json"]),
    ],
    flags=[FlagArg("fast", long="fast"), FlagArg("json", long="json")],
  )

  inspect(
    @test.expect_error(() => {
      conflict_cmd.parse(argv=["--fast", "--json"], env=empty_env())
    }),
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

  inspect(
    @test.expect_error(() => {
      cmd.parse(argv=["--verbose", "--quiet"], env=empty_env())
    }),
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

  inspect(
    @test.expect_error(() => {
      requires_cmd.parse(argv=["--fast"], env=empty_env())
    }),
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

  let conflicts_cmd = @argparse.Command(
    "demo",
    groups=[ArgGroup("mode", args=["fast"], conflicts_with=["config"])],
    flags=[FlagArg("fast", long="fast")],
    options=[OptionArg("config", long="config")],
  )

  inspect(
    @test.expect_error(() => {
      conflicts_cmd.parse(
        argv=["--fast", "--config", "cfg.toml"],
        env=empty_env(),
      )
    }),
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
test "required and env-fed ranged values validate after parsing" {
  let required_cmd = @argparse.Command("demo", options=[
    OptionArg("input", long="input", required=true),
  ])
  inspect(
    @test.expect_error(() => required_cmd.parse(argv=[], env=empty_env())),
    content=(
      #|error: the following required argument was not provided: 'input'
      #|
      #|Usage: demo --input <input>
      #|
      #|Options:
      #|  -h, --help       Show help information.
      #|  --input <input>  
      #|
    ),
  )

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
test "required group with only hidden members reports a plain message" {
  let cmd = @argparse.Command(
    "demo",
    groups=[ArgGroup("mode", required=true, args=["fast"])],
    flags=[FlagArg("fast", long="fast", hidden=true)],
  )
  inspect(
    @test.expect_error(() => cmd.parse(argv=[], env=empty_env())),
    content=(
      #|error: the following required argument group was not provided: 'mode'
      #|
      #|Usage: demo
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|
    ),
  )
}

///|
/// Parse `argv` and summarise the outcome on one line: the parsed flags and
/// values on success, or the first line of the error message on failure.
fn parse_outcome(
  cmd : @argparse.Command,
  argv : Array[String],
  env? : Map[String, String] = Map([]),
) -> String {
  try cmd.parse(argv~, env~) catch {
    err => err.to_string().split("\n").next().unwrap_or("").to_owned()
  } noraise {
    m => "ok \{@debug.to_string((m.flags, m.values))}"
  }
}

///|
test "default values do not trigger relationships or exclusive groups" {
  let exclusive = @argparse.Command(
    "demo",
    groups=[ArgGroup("fmt", args=["format", "json"], multiple=false)],
    options=[OptionArg("format", long="format", default_values=["text"])],
    flags=[FlagArg("json", long="json")],
  )
  // The default value of `format` does not make it a second group member.
  inspect(
    parse_outcome(exclusive, ["--json"]),
    content=(
      #|ok ({ "json": true }, { "format": ["text"] })
    ),
  )
  // Two members passed explicitly: a real conflict.
  inspect(
    parse_outcome(exclusive, ["--format", "csv", "--json"]),
    content=(
      #|error: group conflict fmt
    ),
  )

  let conflicts = @argparse.Command("demo", options=[
    OptionArg("mode", long="mode", default_values=["fast"], conflicts_with=[
      "other",
    ]),
    OptionArg("other", long="other"),
  ])
  // `mode` only holds its default value, so it does not conflict.
  inspect(
    parse_outcome(conflicts, ["--other", "x"]),
    content=(
      #|ok ({}, { "mode": ["fast"], "other": ["x"] })
    ),
  )
  // Both passed explicitly: a real conflict.
  inspect(
    parse_outcome(conflicts, ["--mode", "slow", "--other", "x"]),
    content=(
      #|error: conflicting arguments: mode and other
    ),
  )

  let conflicts_target = @argparse.Command("demo", options=[
    OptionArg("mode", long="mode", default_values=["fast"]),
    OptionArg("other", long="other", conflicts_with=["mode"]),
  ])
  // The conflict target `mode` only holds its default value.
  inspect(
    parse_outcome(conflicts_target, ["--other", "x"]),
    content=(
      #|ok ({}, { "mode": ["fast"], "other": ["x"] })
    ),
  )

  let requires = @argparse.Command("demo", options=[
    OptionArg("mode", long="mode", default_values=["fast"], requires=["config"]),
    OptionArg("config", long="config"),
  ])
  // `mode` only holds its default value, so it requires nothing.
  inspect(
    parse_outcome(requires, []),
    content=(
      #|ok ({}, { "mode": ["fast"] })
    ),
  )
  // `mode` passed explicitly: `config` really is required.
  inspect(
    parse_outcome(requires, ["--mode", "slow"]),
    content=(
      #|error: the following required argument was not provided: 'config' (required by 'mode')
    ),
  )

  let group_requires = @argparse.Command(
    "demo",
    groups=[ArgGroup("g", args=["mode"], requires=["config"])],
    options=[
      OptionArg("mode", long="mode", default_values=["fast"]),
      OptionArg("config", long="config"),
    ],
  )
  // The only member of `g` holds its default value, so `g` requires nothing.
  inspect(
    parse_outcome(group_requires, []),
    content=(
      #|ok ({}, { "mode": ["fast"] })
    ),
  )

  let group_conflicts = @argparse.Command(
    "demo",
    groups=[ArgGroup("g", args=["mode"], conflicts_with=["other"])],
    options=[
      OptionArg("mode", long="mode", default_values=["fast"]),
      OptionArg("other", long="other"),
    ],
  )
  // The only member of `g` holds its default value, so `g` conflicts with
  // nothing.
  inspect(
    parse_outcome(group_conflicts, ["--other", "x"]),
    content=(
      #|ok ({}, { "mode": ["fast"], "other": ["x"] })
    ),
  )

  // A value from the environment counts as passed, like an argv value.
  let env_conflicts = @argparse.Command("demo", options=[
    OptionArg("mode", long="mode", env="MODE", default_values=["fast"], conflicts_with=[
      "other",
    ]),
    OptionArg("other", long="other"),
  ])
  inspect(
    parse_outcome(env_conflicts, ["--other", "x"], env={ "MODE": "slow" }),
    content=(
      #|error: conflicting arguments: mode and other
    ),
  )
}

///|
test "defaults satisfy requirements while env and argv values trigger relations" {
  let required_group = @argparse.Command(
    "demo",
    groups=[ArgGroup("g", required=true, args=["mode"])],
    options=[OptionArg("mode", long="mode", default_values=["fast"])],
  )
  inspect(
    parse_outcome(required_group, []),
    content=(
      #|ok ({}, { "mode": ["fast"] })
    ),
  )

  let requires_default = @argparse.Command("demo", options=[
    OptionArg("mode", long="mode", requires=["config"]),
    OptionArg("config", long="config", default_values=["cfg.toml"]),
  ])
  inspect(
    parse_outcome(requires_default, ["--mode", "slow"]),
    content=(
      #|ok ({}, { "mode": ["slow"], "config": ["cfg.toml"] })
    ),
  )

  let group_to_group = @argparse.Command(
    "demo",
    groups=[
      ArgGroup("a", args=["x"], conflicts_with=["b"]),
      ArgGroup("b", args=["mode"]),
    ],
    flags=[FlagArg("x", long="x")],
    options=[OptionArg("mode", long="mode", default_values=["fast"])],
  )
  inspect(
    parse_outcome(group_to_group, ["--x"]),
    content=(
      #|ok ({ "x": true }, { "mode": ["fast"] })
    ),
  )
  inspect(
    parse_outcome(group_to_group, ["--x", "--mode", "slow"]),
    content=(
      #|error: group conflict a conflicts with b
    ),
  )

  // An env value makes a group member explicit.
  let env_group = @argparse.Command(
    "demo",
    groups=[ArgGroup("fmt", args=["format", "json"], multiple=false)],
    options=[
      OptionArg("format", long="format", env="FORMAT", default_values=["text"]),
    ],
    flags=[FlagArg("json", long="json")],
  )
  inspect(
    parse_outcome(env_group, ["--json"], env={ "FORMAT": "csv" }),
    content=(
      #|error: group conflict fmt
    ),
  )

  // Global defaults propagated into a subcommand stay implicit.
  let global_cmd = @argparse.Command(
    "demo",
    options=[
      OptionArg("mode", long="mode", default_values=["fast"], global=true, conflicts_with=[
        "other",
      ]),
      OptionArg("other", long="other", global=true),
    ],
    subcommands=[Command("run")],
  )
  inspect(
    parse_outcome(global_cmd, ["run", "--other", "x"]),
    content=(
      #|ok ({}, { "mode": ["fast"], "other": ["x"] })
    ),
  )
  inspect(
    parse_outcome(global_cmd, ["--mode", "slow", "run", "--other", "x"]),
    content=(
      #|error: conflicting arguments: mode and other
    ),
  )
}

///|
test "negated flags do not trigger relationships or exclusive groups" {
  let conflicts = @argparse.Command("demo", flags=[
    FlagArg("color", long="color", env="COLOR", negatable=true, conflicts_with=[
      "plain",
    ]),
    FlagArg("plain", long="plain"),
  ])
  // BUG: should parse with color=false; `--no-color` turns the flag off.
  inspect(
    parse_outcome(conflicts, ["--no-color", "--plain"]),
    content=(
      #|error: conflicting arguments: color and plain
    ),
  )
  // BUG: should parse with color=false; COLOR=0 turns the flag off.
  inspect(
    parse_outcome(conflicts, ["--plain"], env={ "COLOR": "0" }),
    content=(
      #|error: conflicting arguments: color and plain
    ),
  )
  // The flag turned on: a real conflict.
  inspect(
    parse_outcome(conflicts, ["--color", "--plain"]),
    content=(
      #|error: conflicting arguments: color and plain
    ),
  )

  let conflicts_target = @argparse.Command("demo", flags=[
    FlagArg("color", long="color", negatable=true),
    FlagArg("plain", long="plain", conflicts_with=["color"]),
  ])
  // BUG: should parse; the conflict target `color` is turned off.
  inspect(
    parse_outcome(conflicts_target, ["--plain", "--no-color"]),
    content=(
      #|error: conflicting arguments: plain and color
    ),
  )

  let requires = @argparse.Command("demo", flags=[
    FlagArg("verbose", long="verbose", env="VERBOSE", negatable=true, requires=[
      "x",
    ]),
    FlagArg("x", long="x"),
  ])
  // BUG: should parse with verbose=false; nothing requires `x`.
  inspect(
    parse_outcome(requires, ["--no-verbose"]),
    content=(
      #|error: the following required argument was not provided: 'x' (required by 'verbose')
    ),
  )
  // BUG: should parse with verbose=false; nothing requires `x`.
  inspect(
    parse_outcome(requires, [], env={ "VERBOSE": "false" }),
    content=(
      #|error: the following required argument was not provided: 'x' (required by 'verbose')
    ),
  )
  // The flag turned on: `x` really is required.
  inspect(
    parse_outcome(requires, ["--verbose"]),
    content=(
      #|error: the following required argument was not provided: 'x' (required by 'verbose')
    ),
  )

  // For a `SetFalse` flag, `--no-<flag>` stores `true`: the unset state.
  let set_false = @argparse.Command("demo", flags=[
    FlagArg("failfast", long="failfast", action=SetFalse, negatable=true, conflicts_with=[
      "plain",
    ]),
    FlagArg("plain", long="plain"),
  ])
  // BUG: should parse with failfast=true.
  inspect(
    parse_outcome(set_false, ["--no-failfast", "--plain"]),
    content=(
      #|error: conflicting arguments: failfast and plain
    ),
  )
  // `--failfast` stores `false`, the set state: a real conflict.
  inspect(
    parse_outcome(set_false, ["--failfast", "--plain"]),
    content=(
      #|error: conflicting arguments: failfast and plain
    ),
  )

  let count = @argparse.Command("demo", flags=[
    FlagArg("v", long="v", action=Count, env="V", negatable=true, requires=["x"]),
    FlagArg("x", long="x"),
  ])
  // BUG: should parse with v=false; the count is 0.
  inspect(
    parse_outcome(count, ["--v", "--no-v"]),
    content=(
      #|error: the following required argument was not provided: 'x' (required by 'v')
    ),
  )
  // BUG: should parse with v=false; the count is 0.
  inspect(
    parse_outcome(count, [], env={ "V": "0" }),
    content=(
      #|error: the following required argument was not provided: 'x' (required by 'v')
    ),
  )

  let exclusive = @argparse.Command(
    "demo",
    groups=[ArgGroup("style", args=["color", "plain"], multiple=false)],
    flags=[
      FlagArg("color", long="color", negatable=true),
      FlagArg("plain", long="plain"),
    ],
  )
  // BUG: should parse; only `plain` is turned on.
  inspect(
    parse_outcome(exclusive, ["--no-color", "--plain"]),
    content=(
      #|error: group conflict style
    ),
  )
}
