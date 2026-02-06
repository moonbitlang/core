# moonbitlang/core/argparse

Declarative argument parsing for MoonBit with constructor-style APIs.

## Quick Start

```mbt nocheck
///|
let cmd = @argparse.Command::new(
  "demo",
  about="demo app",
  args=[
    @argparse.ArgSpec::flag(
      @argparse.FlagArg::new(
        "verbose",
        short=Some('v'),
        long=Some("verbose"),
      ),
    ),
    @argparse.ArgSpec::option(
      @argparse.OptionArg::new(
        "count",
        long=Some("count"),
        env=Some("COUNT"),
      ),
    ),
    @argparse.ArgSpec::positional(
      @argparse.PositionalArg::new("name", index=Some(0)),
    ),
  ],
)

let matches = cmd.parse(argv=["-v", "--count=2", "alice"], env={}) catch {
  _ => panic()
}

assert_true(matches.get_flag("verbose"))
assert_eq(matches.get_one("name").unwrap_or(""), "alice")
```

## Parsing

- `Command::parse(argv?=..., env?=...) -> Matches raise { DisplayHelp, DisplayVersion, ArgumentError, ArgBuildError }`
- `DisplayHelp::Short/Long` for `-h` / `--help`
- `DisplayVersion::Short/Long` for `-V` / `--version`

## Destructuring Matches

Use raw maps if you prefer pattern matching:

```mbt nocheck
///|
let cmd = @argparse.Command::new(
  "demo",
  args=[
    @argparse.ArgSpec::flag(
      @argparse.FlagArg::new("verbose", long=Some("verbose")),
    ),
    @argparse.ArgSpec::option(
      @argparse.OptionArg::new("name", long=Some("name")),
    ),
  ],
)
let matches = cmd.parse(argv=["--verbose", "--name", "alice"], env={}) catch {
  _ => panic()
}

match matches.flags_map().get("verbose") {
  Some(v) => assert_true(v)
  None => panic()
}

match matches.values_map().get("name") {
  Some(values) => assert_eq(values[0], "alice")
  None => panic()
}
```
