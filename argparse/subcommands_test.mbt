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
test "subcommand parsing" {
  let echo = @argparse.Command("echo", positionals=[PositionArg("msg")])
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
test "default subcommand dispatches through normal child parsing" {
  let tui = @argparse.Command(
    "tui",
    about="Start interactive UI",
    flags=[FlagArg("trace", short='t')],
    options=[OptionArg("theme", long="theme")],
    positionals=[PositionArg("workspace")],
  )
  let mcp = @argparse.Command("mcp", about="Run MCP server", options=[
    OptionArg("port", long="port"),
  ])
  let cmd = @argparse.Command(
    "openseek",
    options=[OptionArg("config", long="config", global=true)],
    flags=[FlagArg("verbose", short='v', action=Count, global=true)],
    subcommands=[tui, mcp],
    default_subcommand="tui",
  )

  let bare = cmd.parse(argv=[], env=empty_env()) catch { _ => panic() }
  assert_true(bare.subcommand is Some(("tui", _)))

  let defaulted = cmd.parse(
    argv=["--config", "config.toml", "--theme", "dark", "workspace"],
    env=empty_env(),
  ) catch {
    _ => panic()
  }
  assert_true(defaulted.values is { "config": ["config.toml"], .. })
  assert_true(
    defaulted.subcommand is Some(("tui", sub)) &&
    sub.values
    is {
      "config": ["config.toml"],
      "theme": ["dark"],
      "workspace": ["workspace"],
      ..
    },
  )

  let short_global = cmd.parse(argv=["-v", "--theme", "dark"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(short_global.flag_counts is { "verbose": 1, .. })
  assert_true(
    short_global.subcommand is Some(("tui", sub)) &&
    sub.values is { "theme": ["dark"], .. } &&
    sub.flag_counts is { "verbose": 1, .. },
  )

  let mixed_short = cmd.parse(argv=["-vt"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(mixed_short.flag_counts is { "verbose": 1, .. })
  assert_true(
    mixed_short.subcommand is Some(("tui", sub)) &&
    sub.flags is { "trace": true, .. } &&
    sub.flag_counts is { "verbose": 1, .. },
  )

  let explicit = cmd.parse(argv=["mcp", "--port", "9000"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(
    explicit.subcommand is Some(("mcp", sub)) &&
    sub.values is { "port": ["9000"], .. },
  )
}

///|
test "default subcommand gives exact subcommands precedence over positionals" {
  let cmd = @argparse.Command(
    "openseek",
    subcommands=[
      Command("tui", positionals=[PositionArg("workspace")]),
      Command("mcp"),
    ],
    default_subcommand="tui",
  )

  let explicit = cmd.parse(argv=["mcp"], env=empty_env()) catch { _ => panic() }
  assert_true(explicit.subcommand is Some(("mcp", _)))

  let positional = cmd.parse(argv=["project"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(
    positional.subcommand is Some(("tui", sub)) &&
    sub.values is { "workspace": ["project"], .. },
  )

  let explicit_default = cmd.parse(argv=["tui", "mcp"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(
    explicit_default.subcommand is Some(("tui", sub)) &&
    sub.values is { "workspace": ["mcp"], .. },
  )

  let after_dash_dash = cmd.parse(argv=["--", "mcp"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(
    after_dash_dash.subcommand is Some(("tui", sub)) &&
    sub.values is { "workspace": ["mcp"], .. },
  )
}

///|
test "subcommand cannot follow positional arguments" {
  let cmd = @argparse.Command("demo", positionals=[PositionArg("input")], subcommands=[
    Command("run"),
  ])
  try cmd.parse(argv=["raw", "run"], env=empty_env()) catch {
    err =>
      inspect(
        err,
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
test "subcommand suggestions are only reported for parse failures" {
  let cmd = @argparse.Command(
    "demo",
    positionals=[PositionArg("input", about="input file")],
    subcommands=[Command("serve", about="serve")],
  )
  let positional = cmd.parse(argv=["serv"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(positional.values is { "input": ["serv"], .. })
  assert_true(positional.subcommand is None)

  try cmd.parse(argv=["input.txt", "serv"], env=empty_env()) catch {
    err =>
      inspect(
        err,
        content=(
          #|error: unexpected value 'serv' for '<input>' found; no more were expected
          #|
          #|  tip: a similar subcommand exists: 'serve'
          #|
          #|Usage: demo [input] [command]
          #|
          #|Commands:
          #|  serve  serve
          #|  help   Print help for the subcommand(s).
          #|
          #|Arguments:
          #|  input  input file
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  let no_positionals = @argparse.Command("demo", subcommands=[
    Command("serve", about="serve"),
  ])
  try no_positionals.parse(argv=["hel"], env=empty_env()) catch {
    err =>
      inspect(
        err,
        content=(
          #|error: unexpected value 'hel' found; no more were expected
          #|
          #|  tip: a similar subcommand exists: 'help'
          #|
          #|Usage: demo [command]
          #|
          #|Commands:
          #|  serve  serve
          #|  help   Print help for the subcommand(s).
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|
        ),
      )
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["help", "serv"], env=empty_env()) catch {
    err =>
      inspect(
        err,
        content=(
          #|error: unknown subcommand: serv
          #|
          #|  tip: a similar subcommand exists: 'serve'
          #|
          #|Usage: demo [input] [command]
          #|
          #|Commands:
          #|  serve  serve
          #|  help   Print help for the subcommand(s).
          #|
          #|Arguments:
          #|  input  input file
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
test "subcommand lookup falls back to positional value" {
  let cmd = @argparse.Command("demo", positionals=[PositionArg("input")], subcommands=[
    Command("run"),
  ])
  let parsed = cmd.parse(argv=["raw"], env=empty_env()) catch { _ => panic() }
  assert_true(parsed.values is { "input": ["raw"], .. })
  assert_true(parsed.subcommand is None)
}
