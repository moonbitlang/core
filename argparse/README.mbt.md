# moonbitlang/core/argparse

Declarative argument parsing for MoonBit.

## Argument Shape Rule

If an argument has neither `short` nor `long`, it is parsed as a positional
argument.

This applies even for `OptionArg("name")`. For readability, prefer
`PositionalArg("name", index=...)` when you mean positional input.

```mbt check
///|
test "name-only option behaves as positional" {
  let cmd = @argparse.Command("demo", args=[@argparse.OptionArg("input")])
  let matches = cmd.parse(argv=["file.txt"], env={}) catch { _ => panic() }
  assert_true(matches.values is { "input": ["file.txt"], .. })
}
```

## Core Patterns

```mbt check
///|
test "flag option positional" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.FlagArg("verbose", short='v', long="verbose"),
    @argparse.OptionArg("count", long="count"),
    @argparse.PositionalArg("name", index=0),
  ])
  let matches = cmd.parse(argv=["-v", "--count", "2", "alice"], env={}) catch {
    _ => panic()
  }
  assert_true(matches.flags is { "verbose": true, .. })
  assert_true(matches.values is { "count": ["2"], "name": ["alice"], .. })
}

///|
test "subcommand with global flag" {
  let echo = @argparse.Command("echo", args=[
    @argparse.PositionalArg("msg", index=0),
  ])
  let cmd = @argparse.Command(
    "demo",
    args=[@argparse.FlagArg("verbose", short='v', long="verbose", global=true)],
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
  let cmd = @argparse.Command("demo", about="demo app", version="1.0.0", args=[
    @argparse.FlagArg(
      "verbose",
      short='v',
      long="verbose",
      about="verbose mode",
    ),
    @argparse.OptionArg("count", long="count", about="repeat count"),
  ])
  try cmd.parse(argv=["--help"], env={}) catch {
    @argparse.DisplayHelp::Long(text) =>
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
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "custom version option overrides built-in version flag" {
  let cmd = @argparse.Command("demo", version="1.0.0", args=[
    @argparse.FlagArg(
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
    ),
  )
}
```
