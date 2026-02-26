# moonbitlang/core/argparse

Declarative argument parsing for MoonBit.

This package is inspired by [`clap`](https://github.com/clap-rs/clap) and intentionally implements a small,
predictable subset of its behavior.

## Positional Semantics

Positional behavior is deterministic and intentionally strict:

- `index` is zero-based.
- Indexed positionals are ordered by ascending `index`.
- Unindexed positionals are appended after indexed ones in declaration order.
- For indexed positionals that are not last, `num_args` must be omitted or exactly
  `ValueRange::single()` (`1..1`).
- If a positional has `num_args.lower > 0` and no value is provided, parsing raises
  `ArgParseError::TooFewValues`.

## Argument Shape Rule

`FlagArg` and `OptionArg` must provide at least one of `short` or `long`.
Arguments without both are positional-only and should be declared with
`PositionalArg`.

```mbt check
///|
test "name-only option is rejected" {
  let cmd = @argparse.Command("demo", options=[OptionArg("input")])
  try cmd.parse(argv=["file.txt"], env={}) catch {
    @argparse.ArgBuildError::Unsupported(msg) =>
      inspect(msg, content="flag/option args require short/long")
    _ => panic()
  } noraise {
    _ => panic()
  }
}
```

## Core Patterns

```mbt check
///|
test "flag option positional" {
  let cmd = @argparse.Command(
    "demo",
    flags=[FlagArg("verbose", short='v', long="verbose")],
    options=[OptionArg("count", long="count")],
    positionals=[PositionalArg("name", index=0)],
  )
  let matches = cmd.parse(argv=["-v", "--count", "2", "alice"], env={}) catch {
    _ => panic()
  }
  assert_true(matches.flags is { "verbose": true, .. })
  assert_true(matches.values is { "count": ["2"], "name": ["alice"], .. })
}

///|
test "subcommand with global flag" {
  let echo = @argparse.Command("echo", positionals=[
    PositionalArg("msg", index=0),
  ])
  let cmd = @argparse.Command(
    "demo",
    flags=[FlagArg("verbose", short='v', long="verbose", global=true)],
    subcommands=[echo],
  )
  let matches = cmd.parse(argv=["--verbose", "echo", "hi"], env={}) catch {
    _ => panic()
  }
  assert_true(matches.flags is { "verbose": true, .. })
  assert_true(
    matches.subcommand is Some(("echo", sub)) &&
    sub.flags is { "verbose": true, .. } &&
    sub.values is { "msg": ["hi"], .. },
  )
}
```

## Help and Version Snapshots

`parse` raises display events instead of exiting. Snapshot tests work well for
help text:

```mbt check
///|
test "help snapshot" {
  let cmd = @argparse.Command(
    "demo",
    about="demo app",
    version="1.0.0",
    flags=[FlagArg("verbose", short='v', long="verbose", about="verbose mode")],
    options=[OptionArg("count", long="count", about="repeat count")],
  )
  try cmd.parse(argv=["--help"], env={}) catch {
    @argparse.DisplayHelp::Message(text) =>
      inspect(
        text,
        content=(
          #|Usage: demo [options]
          #|
          #|demo app
          #|
          #|Options:
          #|  -h, --help       Show help information.
          #|  -V, --version    Show version information.
          #|  -v, --verbose    verbose mode
          #|  --count <count>  repeat count
          #|
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "custom version option overrides built-in version flag" {
  let cmd = @argparse.Command("demo", version="1.0.0", flags=[
    FlagArg(
      "custom_version",
      short='V',
      long="version",
      about="custom version flag",
    ),
  ])
  let matches = cmd.parse(argv=["--version"], env={}) catch { _ => panic() }
  assert_true(matches.flags is { "custom_version": true, .. })
  inspect(
    cmd.render_help(),
    content=(
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help     Show help information.
      #|  -V, --version  custom version flag
      #|
    ),
  )
}
```
