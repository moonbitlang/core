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
test "parse failure message contains error and contextual help" {
  let cmd = @argparse.Command("demo", options=[
    OptionArg("count", long="count", about="repeat count"),
  ])

  inspect(
    @test.expect_error(() => cmd.parse(argv=["--bad"], env=empty_env())),
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
}

///|
test "subcommand parse errors include subcommand help" {
  let cmd = @argparse.Command("demo", subcommands=[
    Command("echo", options=[OptionArg("times", long="times")]),
  ])

  inspect(
    @test.expect_error(() => cmd.parse(argv=["echo", "--bad"], env=empty_env())),
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
}

///|
test "render_help remains available for pure formatting" {
  let cmd = @argparse.Command(
    "demo",
    about="Demo command",
    flags=[FlagArg("verbose", short='v', long="verbose")],
    options=[OptionArg("count", long="count")],
    positionals=[PositionArg("name")],
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

  inspect(
    @test.expect_error(() => cmd.parse(argv=["--oops"], env=empty_env())),
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
    positionals=[PositionArg("name", about="Target name")],
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
      #|  --count <count>  Repeat count [default: 1]
      #|
    ),
  )
}

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
      PositionArg("target", num_args=@argparse.ValueRange::single()),
      PositionArg("rest", num_args=ValueRange(lower=0)),
      PositionArg("secret", hidden=true),
    ],
  )
  inspect(
    cmd.render_help(),
    content=(
      #|Usage: render --path <path> [options] <target> [rest...] [command]
      #|
      #|Commands:
      #|  run   run
      #|  help  Print help for the subcommand(s).
      #|
      #|Arguments:
      #|  target   
      #|  rest...  
      #|
      #|Options:
      #|  -h, --help         Show help information.
      #|  -f, --fast         
      #|  --[no-]cache       cache
      #|  -p, --path <path>  [env: PATH_ENV] [default: a, b]
      #|
      #|Groups:
      #|  mode [required] [exclusive]  -f, --fast, -p, --path <path>
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
      PositionArg(
        "pos",
        about="pos",
        env="POS_ENV",
        default_values=["p1", "p2"],
        num_args=ValueRange(lower=0, upper=2),
        allow_hyphen_values=true,
        requires=["opt"],
        conflicts_with=["f"],
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
test "default subcommand help annotation and child error context" {
  let cmd = @argparse.Command(
    "openseek",
    options=[OptionArg("config", long="config", about="config", global=true)],
    subcommands=[
      Command("tui", about="Start interactive UI", options=[
        OptionArg("theme", long="theme", about="theme"),
      ]),
      Command("mcp", about="Run MCP server"),
    ],
    default_subcommand="tui",
  )

  inspect(
    cmd.render_help(),
    content=(
      #|Usage: openseek [options] [command]
      #|
      #|Commands:
      #|  tui   Start interactive UI (default)
      #|  mcp   Run MCP server
      #|  help  Print help for the subcommand(s).
      #|
      #|Options:
      #|  -h, --help         Show help information.
      #|  --config <config>  config
      #|
    ),
  )

  inspect(
    @test.expect_error(() => cmd.parse(argv=["--unknown"], env=empty_env())),
    content=(
      #|error: unexpected argument '--unknown' found
      #|
      #|Usage: openseek tui [options]
      #|
      #|Start interactive UI
      #|
      #|Options:
      #|  -h, --help         Show help information.
      #|  --config <config>  config
      #|  --theme <theme>    theme
      #|
    ),
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

  inspect(
    @test.expect_error(() => cmd.parse(argv=["help", "--bad"], env=empty_env())),
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

  inspect(
    @test.expect_error(() => {
      cmd.parse(argv=["help", "missing"], env=empty_env())
    }),
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

  inspect(
    @test.expect_error(() => cmd.parse(argv=["echo", "--bad"], env=empty_env())),
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
}

///|
test "help subcommand suggestions exclude hidden commands" {
  let cmd = @argparse.Command("demo", subcommands=[
    Command("serve", about="serve"),
    Command("secret", about="secret", hidden=true),
  ])
  inspect(
    @test.expect_error(() => cmd.parse(argv=["help", "secrt"], env=empty_env())),
    content=(
      #|error: unknown subcommand: secrt
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
}

///|
test "builtin and custom help/version dispatch edge paths" {
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

  inspect(
    @test.expect_error(() => versioned.parse(argv=["--oops"], env=empty_env())),
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
test "help rendering edge paths stay stable" {
  let required_many = @argparse.Command("demo", positionals=[
    PositionArg("files", num_args=ValueRange(lower=1)),
  ])
  let required_help = required_many.render_help()
  assert_true(required_help.has_prefix("Usage: demo <files...>"))

  let short_only_builtin = @argparse.Command("demo", options=[
    OptionArg("helpopt", long="help"),
  ])
  let short_only_text = short_only_builtin.render_help()
  assert_true(short_only_text.has_prefix("Usage: demo"))
  inspect(
    @test.expect_error(() => {
      short_only_builtin.parse(argv=["--help"], env=empty_env())
    }),
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
    PositionArg("item"),
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

  inspect(
    @test.expect_error(() => cmd.parse(argv=["--oops"], env=empty_env())),
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

  inspect(
    @test.expect_error(() => cmd.parse(argv=["--oops"], env=empty_env())),
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

  inspect(
    @test.expect_error(() => cmd.parse(argv=["run", "--oops"], env=empty_env())),
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
}

///|
test "subcommand help puts required options in usage" {
  let cmd = @argparse.Command("demo", subcommands=[
    Command(
      "run",
      about="Run a file",
      options=[OptionArg("mode", short='m', required=true)],
      positionals=[PositionArg("file", num_args=@argparse.ValueRange::single())],
    ),
  ])

  inspect(
    @test.expect_error(() => cmd.parse(argv=["run", "--oops"], env=empty_env())),
    content=(
      #|error: unexpected argument '--oops' found
      #|
      #|Usage: demo run --mode <mode> <file>
      #|
      #|Run a file
      #|
      #|Arguments:
      #|  file  
      #|
      #|Options:
      #|  -h, --help         Show help information.
      #|  -m, --mode <mode>  
      #|
    ),
  )
}

///|
test "required_option_usage covers option/flag/hidden/short-only" {
  let cmd = @argparse.Command(
    "demo",
    flags=[
      FlagArg("verbose", short='v', long="verbose", required=true),
      FlagArg("secret", short='s', long="secret", required=true, hidden=true),
    ],
    options=[
      OptionArg("mode", long="mode", required=true),
      OptionArg("tag", short='t', long="", required=true),
      OptionArg("optional", long="optional"),
    ],
    positionals=[
      PositionArg("required_pos", num_args=@argparse.ValueRange::single()),
    ],
  )
  let help = cmd.render_help()
  assert_true(
    help.has_prefix(
      "Usage: demo --verbose --mode <mode> -t <tag> [options] <required_pos>",
    ),
  )
}

///|
test "required_option_usage returns empty when nothing required" {
  let cmd = @argparse.Command(
    "demo",
    flags=[FlagArg("verbose", short='v', long="verbose")],
    options=[OptionArg("mode", long="mode")],
  )
  let help = cmd.render_help()
  assert_true(help.has_prefix("Usage: demo [options]"))
}

///|
test "positional range 0..1 renders as single optional value" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionArg("x", num_args=ValueRange(lower=0, upper=1)),
  ])
  inspect(
    cmd.render_help(),
    content=(
      #|Usage: demo [x]
      #|
      #|Arguments:
      #|  x  
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|
    ),
  )
}

///|
test "required group usage lists every member shape" {
  let cmd = @argparse.Command(
    "demo",
    groups=[
      ArgGroup("g", required=true, args=["opt", "posm", "poss", "sf", "ef"]),
    ],
    flags=[FlagArg("sf", short='s', long=""), FlagArg("ef", long="", env="EF")],
    options=[OptionArg("opt", long="opt")],
    positionals=[
      PositionArg("posm", num_args=ValueRange(lower=0)),
      PositionArg("poss", num_args=ValueRange(lower=0, upper=1)),
    ],
  )
  inspect(
    @test.expect_error(() => cmd.parse(argv=[], env=empty_env())),
    content=(
      #|error: the following required arguments were not provided:
      #|  <--opt <opt>|<posm...>|<poss>|-s|ef>
      #|
      #|Usage: demo [options] [posm...] [poss]
      #|
      #|Arguments:
      #|  posm...  
      #|  poss     
      #|
      #|Options:
      #|  -h, --help   Show help information.
      #|  -s           
      #|  --opt <opt>  
      #|
      #|Groups:
      #|  g [required]  -s, ef, --opt <opt>, posm, poss
      #|
    ),
  )
}

///|
test "help subcommand cannot follow positional arguments" {
  let cmd = @argparse.Command("demo", positionals=[PositionArg("input")], subcommands=[
    Command("run"),
  ])
  inspect(
    @test.expect_error(() => cmd.parse(argv=["raw", "help"], env=empty_env())),
    content=(
      #|error: subcommand 'help' cannot be used with positional arguments
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
}

///|
test "render_help lists positional members inside argument groups" {
  let cmd = @argparse.Command(
    "demo",
    groups=[ArgGroup("inputs", args=["src"])],
    positionals=[PositionArg("src")],
  )
  inspect(
    cmd.render_help(),
    content=(
      #|Usage: demo [src]
      #|
      #|Arguments:
      #|  src  
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|
      #|Groups:
      #|  inputs  src
      #|
    ),
  )
}

///|
test "render_help tolerates a required env-only option" {
  let cmd = @argparse.Command("demo", options=[
    OptionArg("token", long="", env="TOKEN", required=true),
  ])
  inspect(
    cmd.render_help(),
    content=(
      #|Usage: demo
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|
    ),
  )
}
