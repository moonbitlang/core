# moonbitlang/core/argparse

Declarative argument parsing for MoonBit.

This package is inspired by [`clap`](https://github.com/clap-rs/clap) and keeps a
small, predictable feature set.

`long` defaults to the argument name. Pass `long=""` to disable long alias.

## 1. Basic Command

```mbt check
///|
test "basic option + positional success snapshot" {
  let matches = @argparse.parse(
    Command("demo", options=[OptionArg("name", long="name")], positionals=[
      PositionalArg("target"),
    ]),
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
  let cmd = @argparse.Command(
    "demo",
    options=[OptionArg("name", long="name")],
    positionals=[PositionalArg("target")],
  )
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

## 2. Flags And Negation

`flags` stay as `Map[String, Bool]`, so negated flags preserve explicit `false`
states.

```mbt check
///|
test "negatable flag success snapshot" {
  let cmd = @argparse.Command("demo", flags=[
    FlagArg("cache", long="cache", negatable=true),
  ])

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
  let cmd = @argparse.Command("demo", flags=[
    FlagArg("cache", long="cache", negatable=true),
  ])
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

## 3. Subcommands And Globals

```mbt check
///|
test "global count flag success snapshot" {
  let cmd = @argparse.Command(
    "demo",
    flags=[
      FlagArg("verbose", short='v', long="verbose", action=Count, global=true),
    ],
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
  let child = match parsed.subcommand {
    Some(("run", sub)) => sub
    _ => panic()
  }
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
    flags=[
      FlagArg("verbose", short='v', long="verbose", action=Count, global=true),
    ],
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

## 4. Positional Value Ranges

Positionals are parsed in declaration order (no explicit index).

```mbt check
///|
test "bounded non-last positional success snapshot" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionalArg("first", num_args=ValueRange(lower=1, upper=2)),
    PositionalArg("second", required=true),
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
    PositionalArg("first", num_args=ValueRange(lower=1, upper=2)),
    PositionalArg("second", required=true),
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
          #|  first...  required
          #|  second    required
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

## 5. Error Snapshot Pattern

`parse` now emits one string error payload (`ArgError::Message`) that already
contains the full contextual help text.

```mbt check
///|
test "root invalid option snapshot" {
  let cmd = @argparse.Command("demo", options=[
    OptionArg("count", long="count", about="repeat count"),
  ])

  try cmd.parse(argv=["--bad"], env={}) catch {
    Message(msg) =>
      inspect(
        msg,
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
  } noraise {
    _ => panic()
  }
}

///|
test "subcommand invalid option snapshot" {
  let cmd = @argparse.Command("demo", subcommands=[
    Command("echo", options=[OptionArg("times", long="times")]),
  ])

  try cmd.parse(argv=["echo", "--oops"], env={}) catch {
    Message(msg) =>
      inspect(
        msg,
        content=(
          #|error: unexpected argument '--oops' found
          #|
          #|Usage: demo echo [options]
          #|
          #|Options:
          #|  -h, --help       Show help information.
          #|  --times <times>  
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}
```

## 6. Rendering Help Without Parsing

```mbt check
///|
test "render_help remains pure" {
  let cmd = @argparse.Command("demo", about="demo app", options=[
    OptionArg("count", long="count"),
  ])
  let help = cmd.render_help()
  inspect(
    help,
    content=(
      #|Usage: demo [options]
      #|
      #|demo app
      #|
      #|Options:
      #|  -h, --help       Show help information.
      #|  --count <count>  
      #|
    ),
  )
}
```
