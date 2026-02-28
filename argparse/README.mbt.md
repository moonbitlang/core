# moonbitlang/core/argparse

Declarative argument parsing for MoonBit.

This package is inspired by [`clap`](https://github.com/clap-rs/clap) and intentionally implements a small,
predictable subset of its behavior.

## Positional Semantics

Positional behavior is deterministic and intentionally strict:

- `index` is zero-based.
- Positionals without `index` get inferred indices in declaration order.
- All positionals are ordered by the resolved index.
- Positional indices cannot skip values.
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
  let matches = @argparse.parse(
    Command(
      "demo",
      // FlagArg("verbose")
      // OptionArg("count")
      flags=[FlagArg("verbose", short='v', long="verbose")],
      options=[OptionArg("count", long="count")],
      // Test: 0 but passed args
      // add docs 0,1,2, N
      positionals=[PositionalArg("name", index=0)],
    ),
    argv=["-v", "--count", "2", "alice"],
  )
  // CR: Map[String,Bool] -> Set[String]?
  debug_inspect(
    matches,
    content=(
      #|{
      #|  flags: { "verbose": true },
      #|  values: { "count": ["2"], "name": ["alice"] },
      #|  flag_counts: {},
      #|  sources: { "verbose": Argv, "count": Argv, "name": Argv },
      #|  subcommand: None,
      #|  counts: {},
      #|  flag_sources: {},
      #|  value_sources: {},
      #|  parsed_subcommand: None,
      #|}
    ),
  )
}

///|
test "subcommand with global flag" {
  let matches = @argparse.parse(
    Command(
      "demo",
      flags=[FlagArg("verbose", short='v', long="verbose", global=true)],
      subcommands=[
        Command("echo", positionals=[PositionalArg("msg", index=0)]),
        Command("repeat", positionals=[PositionalArg("msg", index=0)], options=[
          OptionArg("count", long="count"),
        ]),
      ],
    ),
    argv=["--verbose", "echo", "hi"],
  )
  // FIXME: (upstream) format introduced a new line
  debug_inspect(
    matches,
    content=(
      #|{
      #|  flags: { "verbose": true },
      #|  values: {},
      #|  flag_counts: {},
      #|  sources: { "verbose": Argv },
      #|  subcommand: Some(
      #|    (
      #|      "echo",
      #|      {
      #|        flags: { "verbose": true },
      #|        values: { "msg": ["hi"] },
      #|        flag_counts: {},
      #|        sources: { "verbose": Argv, "msg": Argv },
      #|        subcommand: None,
      #|        counts: {},
      #|        flag_sources: {},
      #|        value_sources: {},
      #|        parsed_subcommand: None,
      #|      },
      #|    ),
      #|  ),
      #|  counts: {},
      #|  flag_sources: {},
      #|  value_sources: {},
      #|  parsed_subcommand: None,
      #|}
    ),
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
  //CR: we need handle `--help` implicitly for the user
  try cmd.parse(argv=["--help"]) catch {
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
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected help display event")
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

<!-- TODO: add a subcommand `--help` test case, `--x` -->