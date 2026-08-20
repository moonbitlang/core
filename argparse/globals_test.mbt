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
  try
    cmd.parse(argv=["--mode", "a", "run", "--mode", "b"], env=empty_env())
  catch {
    err =>
      inspect(
        err,
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
  try cmd.parse(argv=["-m", "a", "run", "-m", "b"], env=empty_env()) catch {
    err =>
      inspect(
        err,
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
  } noraise {
    _ => panic()
  }
}
