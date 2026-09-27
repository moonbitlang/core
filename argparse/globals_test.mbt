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
    flags=[FlagArg("verbose", short='v', action=Count, global=true)],
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
test "env-only global is propagated to nested subcommand matches" {
  let cmd = @argparse.Command(
    "demo",
    options=[OptionArg("level", long="", env="LEVEL", global=true)],
    subcommands=[Command("run", subcommands=[Command("leaf")])],
  )

  let parsed = cmd.parse(argv=["run", "leaf"], env={ "LEVEL": "5" }) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "level": ["5"], .. })
  assert_true(parsed.sources is { "level": Env, .. })
  assert_true(
    parsed.subcommand is Some(("run", sub_run)) &&
    sub_run.values is { "level": ["5"], .. } &&
    sub_run.sources is { "level": Env, .. } &&
    sub_run.subcommand is Some(("leaf", sub_leaf)) &&
    sub_leaf.values is { "level": ["5"], .. } &&
    sub_leaf.sources is { "level": Env, .. },
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
test "child global override env/default win over inherited definition" {
  let cmd = @argparse.Command(
    "demo",
    options=[
      OptionArg(
        "mode",
        long="mode",
        env="ROOT_MODE",
        default_values=["safe"],
        global=true,
      ),
    ],
    subcommands=[
      Command("run", options=[
        OptionArg(
          "mode",
          long="mode",
          env="RUN_MODE",
          default_values=["fast"],
          global=true,
        ),
      ]),
    ],
  )

  let from_env = cmd.parse(argv=["run"], env={
    "ROOT_MODE": "root-env",
    "RUN_MODE": "run-env",
  }) catch {
    _ => panic()
  }
  assert_true(from_env.values is { "mode": ["run-env"], .. })
  assert_true(from_env.sources is { "mode": Env, .. })
  assert_true(
    from_env.subcommand is Some(("run", sub)) &&
    sub.values is { "mode": ["run-env"], .. } &&
    sub.sources is { "mode": Env, .. },
  )

  let from_default = cmd.parse(argv=["run"], env=Map([])) catch { _ => panic() }
  assert_true(from_default.values is { "mode": ["fast"], .. })
  assert_true(from_default.sources is { "mode": Default, .. })
  assert_true(
    from_default.subcommand is Some(("run", sub)) &&
    sub.values is { "mode": ["fast"], .. } &&
    sub.sources is { "mode": Default, .. },
  )
}

///|
test "inherited argv global satisfies child required global override" {
  let cmd = @argparse.Command(
    "demo",
    options=[OptionArg("mode", long="mode", global=true)],
    subcommands=[
      Command("run", options=[
        OptionArg("mode", long="mode", required=true, global=true),
      ]),
    ],
  )

  let parsed = cmd.parse(argv=["--mode", "fast", "run"], env=empty_env()) catch {
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
  inspect(
    @test.expect_error(() => {
      cmd.parse(argv=["--mode", "a", "run", "--mode", "b"], env=empty_env())
    }),
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
test "compatible global flag can be redeclared in a subcommand" {
  let cmd = @argparse.Command(
    "demo",
    flags=[FlagArg("v", short='v', long="", global=true)],
    subcommands=[
      Command("child", flags=[FlagArg("v", short='v', long="", global=true)]),
    ],
  )
  let parsed = cmd.parse(argv=["-v", "child"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.flags is { "v": true, .. })
  assert_true(
    parsed.subcommand is Some(("child", sub)) && sub.flags is { "v": true, .. },
  )
}

///|
test "global set option used in both parent and child argv conflicts" {
  let cmd = @argparse.Command(
    "demo",
    options=[OptionArg("mode", short='m', long="", global=true)],
    subcommands=[Command("run")],
  )
  inspect(
    @test.expect_error(() => {
      cmd.parse(argv=["-m", "a", "run", "-m", "b"], env=empty_env())
    }),
    content=(
      #|error: argument '-m' cannot be used multiple times
      #|
      #|Usage: demo [options] [command]
      #|
      #|Commands:
      #|  run   
      #|  help  Print help for the subcommand(s).
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|  -m <mode>   
      #|
    ),
  )
}

///|
/// Renders the state of global `name` at every matches level, root first.
fn nested_global_levels(
  cmd : @argparse.Command,
  name : String,
  argv : Array[String],
) -> String {
  let parsed = cmd.parse(argv~, env=empty_env()) catch {
    err => return "\{"\{err}".split("\n").next().unwrap_or("")}"
  }
  let levels = []
  let mut current = Some(parsed)
  while current is Some(m) {
    let level = match
      (m.flags.get(name), m.flag_counts.get(name), m.values.get(name)) {
      (Some(flag), None, _) => "\{flag}"
      (Some(flag), Some(count), _) => "\{flag} x\{count}"
      (None, _, Some(values)) => values.join(",")
      (None, _, None) => "-"
    }
    levels.push(level)
    current = match m.subcommand {
      Some((_, sub)) => Some(sub)
      None => None
    }
  }
  levels.join(" | ")
}

///|
/// Parses each row with `root > mid` when it does not mention `leaf`, and with
/// `root > mid > leaf` otherwise; the global is declared on `root` only.
fn nested_global_table(
  name : String,
  rows : Array[Array[String]],
  flags? : Array[@argparse.FlagArg] = [],
  options? : Array[@argparse.OptionArg] = [],
) -> String {
  let one_level = @argparse.Command("root", flags~, options~, subcommands=[
    Command("mid"),
  ])
  let two_levels = @argparse.Command("root", flags~, options~, subcommands=[
    Command("mid", subcommands=[Command("leaf")]),
  ])
  let lines = []
  for argv in rows {
    let cmd = if argv.contains("leaf") { two_levels } else { one_level }
    lines.push("\{argv.join(" ")} => \{nested_global_levels(cmd, name, argv)}")
  }
  lines.join("\n")
}

///|
test "global flags merge across one and two subcommand levels" {
  let rows = [
    ["-v", "mid"],
    ["-v", "-v", "mid"],
    ["mid", "-v"],
    ["-v", "mid", "-v"],
    ["-v", "mid", "leaf"],
    ["-v", "-v", "mid", "leaf"],
    ["mid", "-v", "leaf"],
    ["mid", "leaf", "-v"],
    ["-v", "mid", "-v", "leaf"],
    ["-v", "mid", "leaf", "-v"],
    ["mid", "-v", "leaf", "-v"],
    ["-v", "mid", "-v", "leaf", "-v"],
    ["mid", "leaf"],
  ]
  inspect(
    nested_global_table("v", rows, flags=[
      FlagArg("v", short='v', long="", action=Count, global=true),
    ]),
    content=(
      #|-v mid => true x1 | true x1
      #|-v -v mid => true x2 | true x2
      #|mid -v => true x1 | true x1
      #|-v mid -v => true x2 | true x2
      #|-v mid leaf => true x1 | true x1 | true x1
      #|-v -v mid leaf => true x2 | true x2 | true x2
      #|mid -v leaf => true x1 | true x1 | true x1
      #|mid leaf -v => true x1 | true x1 | true x1
      #|-v mid -v leaf => true x2 | true x2 | true x2
      #|-v mid leaf -v => true x2 | true x2 | true x2
      #|mid -v leaf -v => true x2 | true x2 | true x2
      #|-v mid -v leaf -v => true x3 | true x3 | true x3
      #|mid leaf => - | - | -
    ),
  )
  inspect(
    nested_global_table("v", rows, flags=[
      FlagArg("v", short='v', long="", action=SetTrue, global=true),
    ]),
    content=(
      #|-v mid => true | true
      #|-v -v mid => true | true
      #|mid -v => true | true
      #|-v mid -v => true | true
      #|-v mid leaf => true | true | true
      #|-v -v mid leaf => true | true | true
      #|mid -v leaf => true | true | true
      #|mid leaf -v => true | true | true
      #|-v mid -v leaf => true | true | true
      #|-v mid leaf -v => true | true | true
      #|mid -v leaf -v => true | true | true
      #|-v mid -v leaf -v => true | true | true
      #|mid leaf => - | - | -
    ),
  )
  inspect(
    nested_global_table("v", rows, flags=[
      FlagArg("v", short='v', long="", action=SetFalse, global=true),
    ]),
    content=(
      #|-v mid => false | false
      #|-v -v mid => false | false
      #|mid -v => false | false
      #|-v mid -v => false | false
      #|-v mid leaf => false | false | false
      #|-v -v mid leaf => false | false | false
      #|mid -v leaf => false | false | false
      #|mid leaf -v => false | false | false
      #|-v mid -v leaf => false | false | false
      #|-v mid leaf -v => false | false | false
      #|mid -v leaf -v => false | false | false
      #|-v mid -v leaf -v => false | false | false
      #|mid leaf => - | - | -
    ),
  )
}

///|
test "global options merge across one and two subcommand levels" {
  let rows = [
    ["-m", "a", "mid"],
    ["mid", "-m", "b"],
    ["-m", "a", "mid", "-m", "b"],
    ["-m", "a", "mid", "leaf"],
    ["mid", "-m", "b", "leaf"],
    ["mid", "leaf", "-m", "c"],
    ["-m", "a", "mid", "-m", "b", "leaf"],
    ["-m", "a", "mid", "leaf", "-m", "c"],
    ["mid", "-m", "b", "leaf", "-m", "c"],
    ["-m", "a", "mid", "-m", "b", "leaf", "-m", "c"],
    ["mid", "leaf"],
  ]
  inspect(
    nested_global_table("m", rows, options=[
      OptionArg("m", short='m', long="", global=true),
    ]),
    content=(
      #|-m a mid => a | a
      #|mid -m b => b | b
      #|-m a mid -m b => error: argument '-m' cannot be used multiple times
      #|-m a mid leaf => a | a | a
      #|mid -m b leaf => b | b | b
      #|mid leaf -m c => c | c | c
      #|-m a mid -m b leaf => error: argument '-m' cannot be used multiple times
      #|-m a mid leaf -m c => error: argument '-m' cannot be used multiple times
      #|mid -m b leaf -m c => error: argument '-m' cannot be used multiple times
      #|-m a mid -m b leaf -m c => error: argument '-m' cannot be used multiple times
      #|mid leaf => - | - | -
    ),
  )
  inspect(
    nested_global_table("m", rows, options=[
      OptionArg("m", short='m', long="", action=Append, global=true),
    ]),
    content=(
      #|-m a mid => a | a
      #|mid -m b => b | b
      #|-m a mid -m b => a,b | a,b
      #|-m a mid leaf => a | a | a
      #|mid -m b leaf => b | b | b
      #|mid leaf -m c => c | c | c
      #|-m a mid -m b leaf => a,b | a,b | a,b
      #|-m a mid leaf -m c => a,c | a,c | a,c
      #|mid -m b leaf -m c => b,c | b,c | b,c
      #|-m a mid -m b leaf -m c => a,b,c | a,b,c | a,b,c
      #|mid leaf => - | - | -
    ),
  )
}

///|
test "global flag negation followed by occurrences across subcommand levels" {
  let rows = [
    ["-v", "--no-v", "-v", "mid"],
    ["-v", "mid", "--no-v"],
    ["--no-v", "mid", "-v"],
    ["-v", "mid", "--no-v", "-v"],
    ["-v", "mid", "--no-v", "leaf"],
    ["-v", "mid", "leaf", "--no-v"],
    ["--no-v", "mid", "leaf", "-v"],
    ["-v", "mid", "--no-v", "-v", "leaf"],
    ["-v", "mid", "leaf", "--no-v", "-v"],
    ["-v", "-v", "mid", "--no-v", "leaf", "-v"],
    ["-v", "mid", "-v", "leaf", "--no-v", "-v"],
  ]
  // BUG: occurrences after a `--no-v` inside a subcommand are added to the
  // count from before the reset. Every row whose last `--no-v` is followed by
  // exactly one `-v` should report `true x1` at every level, as
  // `-v --no-v -v mid` does; rows 4, 8, 9, 10 and 11 report x2, x2, x2, x3
  // and x3 instead.
  inspect(
    nested_global_table("v", rows, flags=[
      FlagArg(
        "v",
        short='v',
        long="v",
        action=Count,
        negatable=true,
        global=true,
      ),
    ]),
    content=(
      #|-v --no-v -v mid => true x1 | true x1
      #|-v mid --no-v => false | false
      #|--no-v mid -v => true x1 | true x1
      #|-v mid --no-v -v => true x2 | true x2
      #|-v mid --no-v leaf => false | false | false
      #|-v mid leaf --no-v => false | false | false
      #|--no-v mid leaf -v => true x1 | true x1 | true x1
      #|-v mid --no-v -v leaf => true x2 | true x2 | true x2
      #|-v mid leaf --no-v -v => true x2 | true x2 | true x2
      #|-v -v mid --no-v leaf -v => true x3 | true x3 | true x3
      #|-v mid -v leaf --no-v -v => true x3 | true x3 | true x3
    ),
  )
  inspect(
    nested_global_table("v", rows, flags=[
      FlagArg(
        "v",
        short='v',
        long="v",
        action=SetTrue,
        negatable=true,
        global=true,
      ),
    ]),
    content=(
      #|-v --no-v -v mid => true | true
      #|-v mid --no-v => false | false
      #|--no-v mid -v => true | true
      #|-v mid --no-v -v => true | true
      #|-v mid --no-v leaf => false | false | false
      #|-v mid leaf --no-v => false | false | false
      #|--no-v mid leaf -v => true | true | true
      #|-v mid --no-v -v leaf => true | true | true
      #|-v mid leaf --no-v -v => true | true | true
      #|-v -v mid --no-v leaf -v => true | true | true
      #|-v mid -v leaf --no-v -v => true | true | true
    ),
  )
  inspect(
    nested_global_table("v", rows, flags=[
      FlagArg(
        "v",
        short='v',
        long="v",
        action=SetFalse,
        negatable=true,
        global=true,
      ),
    ]),
    content=(
      #|-v --no-v -v mid => false | false
      #|-v mid --no-v => true | true
      #|--no-v mid -v => false | false
      #|-v mid --no-v -v => false | false
      #|-v mid --no-v leaf => true | true | true
      #|-v mid leaf --no-v => true | true | true
      #|--no-v mid leaf -v => false | false | false
      #|-v mid --no-v -v leaf => false | false | false
      #|-v mid leaf --no-v -v => false | false | false
      #|-v -v mid --no-v leaf -v => false | false | false
      #|-v mid -v leaf --no-v -v => false | false | false
    ),
  )
}
