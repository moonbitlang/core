# moonbitlang/core/argparse

Declarative argument parsing for MoonBit.

This package is inspired by [`clap`](https://github.com/clap-rs/clap) and keeps a
small, predictable feature set.

`long` defaults to the argument name. Pass `long=""` to disable long alias.


## Quick Start

```mbt check
///|
test "basic option + positional success snapshot" {
  let matches = @argparse.parse(
    Command("demo", options=[Option("name")], positionals=[Positional("target")]),
    argv=["--name", "alice", "file.txt"],
  )
  @debug.debug_inspect(
    matches.values,
    content=(
      #|{ "name": ["alice"], "target": ["file.txt"] }
    ),
  )
}

///|
test "basic option + positional failure snapshot" {
  let cmd = @argparse.Command("demo", options=[Option("name")], positionals=[
    Positional("target"),
  ])
  try cmd.parse(argv=["--bad"], env={}) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unexpected argument '--bad' found
          #|
          #|Usage: demo [options] [target]
          #|
          #|Arguments:
          #|  target  
          #|
          #|Options:
          #|  -h, --help     Show help information.
          #|  --name <name>  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}
```


## Flags And Negation

`flags` stay as `Map[String, Bool]`, so negated flags preserve explicit `false`
states.

```mbt check
///|
test "negatable flag success snapshot" {
  let cmd = @argparse.Command("demo", flags=[Flag("cache", negatable=true)])

  let parsed = cmd.parse(argv=["--no-cache"], env={}) catch { _ => panic() }
  @debug.debug_inspect(
    parsed.flags,
    content=(
      #|{ "cache": false }
    ),
  )
}

///|
test "negatable flag failure snapshot" {
  let cmd = @argparse.Command("demo", flags=[Flag("cache", negatable=true)])
  try cmd.parse(argv=["--oops"], env={}) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unexpected argument '--oops' found
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help    Show help information.
          #|  --[no-]cache  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}
```

## Subcommands And Globals

```mbt check
///|
test "global count flag success snapshot" {
  let cmd = @argparse.Command(
    "demo",
    flags=[Flag("verbose", short='v', action=Count, global=true)],
    subcommands=[Command("run")],
  )

  let parsed = cmd.parse(argv=["-v", "run", "-v"], env={}) catch {
    _ => panic()
  }
  @debug.debug_inspect(
    parsed.flag_counts,
    content=(
      #|{ "verbose": 2 }
    ),
  )
  guard parsed.subcommand is Some(("run", child)) else { panic() }
  @debug.debug_inspect(
    child.flag_counts,
    content=(
      #|{ "verbose": 2 }
    ),
  )
}

///|
test "subcommand context failure snapshot" {
  let cmd = @argparse.Command(
    "demo",
    flags=[Flag("verbose", short='v', action=Count, global=true)],
    subcommands=[Command("run")],
  )
  try cmd.parse(argv=["run", "--oops"], env={}) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unexpected argument '--oops' found
          #|
          #|Usage: demo run [options]
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
```

## Value Sources (argv > env > default_values)

Value precedence is `argv > env > default_values`.

```mbt check
///|
test "value source precedence snapshots" {
  let cmd = @argparse.Command("demo", options=[
    Option("level", env="LEVEL", default_values=["1"]),
  ])

  let from_default = cmd.parse(argv=[], env={}) catch { _ => panic() }
  @debug.debug_inspect(
    from_default.values,
    content=(
      #|{ "level": ["1"] }
    ),
  )
  @debug.debug_inspect(
    from_default.sources,
    content=(
      #|{ "level": Default }
    ),
  )

  let from_env = cmd.parse(argv=[], env={ "LEVEL": "2" }) catch { _ => panic() }
  @debug.debug_inspect(
    from_env.values,
    content=(
      #|{ "level": ["2"] }
    ),
  )
  @debug.debug_inspect(
    from_env.sources,
    content=(
      #|{ "level": Env }
    ),
  )

  let from_argv = cmd.parse(argv=["--level", "3"], env={ "LEVEL": "2" }) catch {
    _ => panic()
  }
  @debug.debug_inspect(
    from_argv.values,
    content=(
      #|{ "level": ["3"] }
    ),
  )
  @debug.debug_inspect(
    from_argv.sources,
    content=(
      #|{ "level": Argv }
    ),
  )
}
```

## Input Forms

```mbt check
///|
test "option input forms snapshot" {
  let cmd = @argparse.Command("demo", options=[Option("count", short='c')])

  let long_split = cmd.parse(argv=["--count", "2"], env={}) catch {
    _ => panic()
  }
  @debug.debug_inspect(
    long_split.values,
    content=(
      #|{ "count": ["2"] }
    ),
  )

  let long_inline = cmd.parse(argv=["--count=3"], env={}) catch { _ => panic() }
  @debug.debug_inspect(
    long_inline.values,
    content=(
      #|{ "count": ["3"] }
    ),
  )

  let short_split = cmd.parse(argv=["-c", "4"], env={}) catch { _ => panic() }
  @debug.debug_inspect(
    short_split.values,
    content=(
      #|{ "count": ["4"] }
    ),
  )

  let short_attached = cmd.parse(argv=["-c5"], env={}) catch { _ => panic() }
  @debug.debug_inspect(
    short_attached.values,
    content=(
      #|{ "count": ["5"] }
    ),
  )
}

///|
test "double-dash separator snapshot" {
  let cmd = @argparse.Command("demo", positionals=[
    Positional("tail", num_args=ValueRange(lower=0), allow_hyphen_values=true),
  ])
  let parsed = cmd.parse(argv=["--", "--x", "-y"], env={}) catch {
    _ => panic()
  }
  @debug.debug_inspect(
    parsed.values,
    content=(
      #|{ "tail": ["--x", "-y"] }
    ),
  )
}
```

## Constraints And Policies

`parse` raises a single string error (`ArgError::Message`) that includes the
error and full contextual help.

```mbt check
///|
test "requires relationship success and failure snapshots" {
  let cmd = @argparse.Command("demo", options=[
    Option("mode", requires=["config"]),
    Option("config"),
  ])

  let ok = cmd.parse(argv=["--mode", "fast", "--config", "cfg.toml"], env={}) catch {
    _ => panic()
  }
  @debug.debug_inspect(
    ok.values,
    content=(
      #|{ "mode": ["fast"], "config": ["cfg.toml"] }
    ),
  )

  try cmd.parse(argv=["--mode", "fast"], env={}) catch {
    Message(msg) =>
      inspect(
        msg,
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
  } noraise {
    _ => panic()
  }
}

///|
test "arg group required and exclusive failure snapshot" {
  let cmd = @argparse.Command(
    "demo",
    groups=[
      ArgGroup("mode", required=true, multiple=false, args=["fast", "slow"]),
    ],
    flags=[Flag("fast"), Flag("slow")],
  )

  try cmd.parse(argv=[], env={}) catch {
    Message(msg) =>
      inspect(
        msg,
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
          #|  mode (required, exclusive)  --fast, --slow
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "subcommand required policy failure snapshot" {
  let cmd = @argparse.Command("demo", subcommand_required=true, subcommands=[
    Command("echo"),
  ])

  try cmd.parse(argv=[], env={}) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: the following required argument was not provided: 'subcommand'
          #|
          #|Usage: demo <command>
          #|
          #|Commands:
          #|  echo  
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
```

```mbt check
///|
test "conflicts_with success and failure snapshots" {
  let cmd = @argparse.Command("demo", flags=[
    Flag("verbose", conflicts_with=["quiet"]),
    Flag("quiet"),
  ])

  let ok = cmd.parse(argv=["--verbose"], env={}) catch { _ => panic() }
  @debug.debug_inspect(
    ok.flags,
    content=(
      #|{ "verbose": true }
    ),
  )

  try cmd.parse(argv=["--verbose", "--quiet"], env={}) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: conflicting arguments: verbose and quiet
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|  --verbose   
          #|  --quiet     
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}
```

## Positional Value Ranges

Positionals are parsed in declaration order (no explicit index).

```mbt check
///|
test "bounded non-last positional success snapshot" {
  let cmd = @argparse.Command("demo", positionals=[
    Positional("first", num_args=ValueRange(lower=1, upper=2)),
    Positional("second", num_args=@argparse.ValueRange::single()),
  ])

  let parsed = cmd.parse(argv=["a", "b", "c"], env={}) catch { _ => panic() }
  @debug.debug_inspect(
    parsed.values,
    content=(
      #|{ "first": ["a", "b"], "second": ["c"] }
    ),
  )
}

///|
test "bounded non-last positional failure snapshot" {
  let cmd = @argparse.Command("demo", positionals=[
    Positional("first", num_args=ValueRange(lower=1, upper=2)),
    Positional("second", num_args=@argparse.ValueRange::single()),
  ])
  try cmd.parse(argv=["a", "b", "c", "d"], env={}) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: too many positional arguments were provided
          #|
          #|Usage: demo <first...> <second>
          #|
          #|Arguments:
          #|  first...  
          #|  second    
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
test "positional passthrough keeps child argv after double-dash snapshot" {
  let cmd = @argparse.Command(
    "wrap",
    options=[Option("config"), Option("mode")],
    positionals=[
      Positional("child_argv", num_args=ValueRange(lower=0), allow_hyphen_values=true),
    ],
  )

  let parsed = cmd.parse(argv=[
    "--config",
    "cfg.toml",
    "--",
    "child",
    "--mode",
    "fast",
    "--",
    "--flag",
  ], env={}) catch {
    _ => panic()
  }
  @debug.debug_inspect(
    parsed.values,
    content=(
      #|{
      #|  "config": ["cfg.toml"],
      #|  "child_argv": ["child", "--mode", "fast", "--", "--flag"],
      #|}
    ),
  )
}

///|
test "without separator outer parser still consumes its own option names snapshot" {
  let cmd = @argparse.Command(
    "wrap",
    options=[Option("config"), Option("mode")],
    positionals=[
      Positional("child_argv", num_args=ValueRange(lower=0), allow_hyphen_values=true),
    ],
  )

  let parsed = cmd.parse(argv=[
    "--config",
    "cfg.toml",
    "child",
    "--mode",
    "fast",
  ], env={}) catch {
    _ => panic()
  }
  @debug.debug_inspect(
    parsed.values,
    content=(
      #|{ "config": ["cfg.toml"], "mode": ["fast"], "child_argv": ["child"] }
    ),
  )
}
```
