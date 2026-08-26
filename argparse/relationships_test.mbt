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
