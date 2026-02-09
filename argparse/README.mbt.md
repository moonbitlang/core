# moonbitlang/core/argparse

Declarative argument parsing for MoonBit with constructor-style APIs.

## Quick Start

```mbt nocheck
///|
let cmd = @argparse.Command(
  "demo",
  about="demo app",
  args=[
    @argparse.FlagArg(
      "verbose",
      short='v',
      long="verbose",
    ),
    @argparse.OptionArg(
      "count",
      long="count",
      env="COUNT",
    ),
    @argparse.PositionalArg("name", index=0),
  ],
)

let matches = cmd.parse(argv=["-v", "--count=2", "alice"], env={}) catch {
  _ => panic()
}

assert_true(matches.flags.get("verbose").unwrap_or(false))
assert_eq(matches.values.get("count").unwrap_or([])[0], "2")
assert_eq(matches.values.get("name").unwrap_or([])[0], "alice")
```

## Handle Help and Version

`parse` raises instead of exiting, so callers decide what to do:

```mbt nocheck
///|
let cmd = @argparse.Command("demo", about="demo app", version="1.2.3")

try cmd.parse(argv=["--help"], env={}) catch {
  @argparse.DisplayHelp::Long(text) => println(text)
  @argparse.DisplayVersion::Long(text) => println(text)
  @argparse.ArgParseError::UnknownArgument(arg, _) => {
    println("Unknown argument: " + arg)
  }
  _ => panic()
} noraise {
  _ => ()
}
```

## Destructuring Matches

Use raw maps if you prefer pattern matching:

```mbt nocheck
///|
let echo = @argparse.Command(
  "echo",
  args=[@argparse.PositionalArg("msg", index=0)],
)
let cmd = @argparse.Command(
  "demo",
  args=[
    @argparse.FlagArg("verbose", long="verbose"),
    @argparse.OptionArg("name", long="name"),
  ],
  subcommands=[echo],
)
let matches = cmd.parse(argv=["--verbose", "--name", "alice", "echo", "hi"], env={}) catch {
  _ => panic()
}

match matches.flags.get("verbose") {
  Some(v) => assert_true(v)
  None => panic()
}

match matches.values.get("name") {
  Some(values) => assert_eq(values[0], "alice")
  None => panic()
}

match matches.subcommand {
  Some(("echo", sub)) => assert_eq(sub.values.get("msg").unwrap_or([])[0], "hi")
  _ => panic()
}
```

## Argument Groups

Define group rules declaratively:

```mbt nocheck
///|
let cmd = @argparse.Command(
  "demo",
  groups=[
    @argparse.ArgGroup("mode", required=true, multiple=false),
    @argparse.ArgGroup("output", args=["json"]),
  ],
  args=[
    @argparse.FlagArg("fast", long="fast", group="mode"),
    @argparse.FlagArg("slow", long="slow", group="mode"),
    @argparse.FlagArg("json", long="json"),
  ],
)
```
