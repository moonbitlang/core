# moonbitlang/core/arg_parser

A small clap-style (builder API) argument parser for MoonBit.

Design goals:

- Builder-style API (`Command`, `Arg`) inspired by Rust clap (no derive macros).
- Subcommands.
- Built-in help generation (`-h` short, `--help` long) + `help` subcommand (disableable).
- Structured decoding from `Matches` via `FromMatches` (you control parsing).
- Built-in version flag (`-V`, `--version`) when version text is set (disableable).
- Optional env var fallbacks per argument.

## Quick Start

Define a command with options + a positional:

```mbt nocheck
let cmd = Command::new("demo")
  .about("demo app")
  .arg(Arg::new("verbose").short('v').long("verbose"))
  .arg(Arg::new("count").long("count").option().env("COUNT"))
  .arg(Arg::new("name").index(0))

let matches = cmd.parse(argv=["-v", "--count=2", "alice"]) catch {
  _ => panic()
}
assert_true(matches.get_flag("verbose"))
assert_eq(matches.value_of("name").unwrap(), "alice")
```

## Parsing APIs

There is one parsing entry point:

- `Command::parse(argv?=..., env?=...) -> Matches raise { Help, Version, ArgumentError, ArgBuildError }`
  - Returns `matches` on success.
  - Raises `Help::Short(help_text)` for `-h` and `Help::Long(help_text)` for `--help`.
  - Raises `Help::Long(help_text)` for the `help` subcommand (use `help ... -h` for short).
  - Raises `Version::Short(version_text)` for `-V` and `Version::Long(version_text)` for `--version`.
  - Raises `ArgBuildError::Unsupported(_)` for invalid arg specs.

If `argv` is omitted, `parse()` reads the current process arguments
(`@env.args()[1:]`). For tests, pass `argv=[...]`.
If `env` is omitted, it defaults to the current process environment via
`@env.get_env_vars()`. Pass `env={...}` to override.

On help (`-h/--help`), `parse` raises `Help::Short` or `Help::Long`. Decide in
your app whether to print and exit, or show help in some other way.

## Help

Help text is generated from the command definition:

- `-h`: short help
- `--help`: long help
- `help [command...]`: subcommand form of help (enabled when a command has subcommands)
  - Defaults to long help; pass `-h` for short help.

You can also render help without parsing:

- `Command::render_help() -> String` (short help)
- `Command::render_long_help() -> String` (long help)

Help text sources:

- `Command::about(...)` for short help, `Command::long_about(...)` for long help
- `Arg::help(...)` for short help, `Arg::long_help(...)` for long help
- If the short text is empty, long text is used as a fallback (and vice versa).

Visibility controls:

- `Command::hide()` hides a subcommand from help output (still parsed).
- `Arg::hide()` hides an argument from all help output.
- `Arg::hide_long_help()` hides an argument from long help only.

## Version

Version text is generated from the command definition (when set):

- `-V`: short version
- `--version`: long version

You can also disable the built-in help/version flags:

- `Command::disable_help_flag()`
- `Command::disable_version_flag()`

Version text sources:

- `Command::version(...)` for short version
- `Command::long_version(...)` for long version
- If the short text is empty, long text is used as a fallback (and vice versa).

## Subcommands

```mbt nocheck
let echo = Command::new("echo")
  .about("echo a message")
  .arg(Arg::new("msg").index(0))

let root = Command::new("root").subcommand(echo)
let m = root.parse(argv=["echo", "hi"]) catch { _ => panic() }

assert_eq(m.subcommand_name().unwrap(), "echo")
let sub = m.subcommand_matches("echo").unwrap()
assert_eq(sub.value_of("msg").unwrap(), "hi")
```

You can add aliases:

```mbt nocheck
///|
let run = Command::new("run").visible_alias("r")

///|
let root = Command::new("root").subcommand(run)
```

The built-in `help` subcommand is enabled by default when a command has
subcommands. Use `.disable_help_subcommand()` if you want to reserve `help` for
your own subcommand. Use `.disable_help_flag()` if you want to reserve `-h/--help`
for your own option (and to disable `help ... -h/--help` shortcuts).

your own subcommand.

## Options and Positionals

### Constructors

Start with `Arg::new("name")` and chain setters like
`.short(...)`, `.long(...)`, `.option()`, `.help(...)`, `.long_help(...)`, `.env(...)`,
`.default_value(...)`, `.required(...)`, `.min_values(...)`, etc.

### Options

- Long: `Arg::new("count").long("count").option()` parses `--count 3` and `--count=3`
- Short: `Arg::new("count").short('c').option()` parses `-c 3`, `-c=3`, and `-c3`
- Short groups: `-vv` is parsed as `-v -v` (flags only)
- Aliases: use `.alias_name(...)` / `.short_alias(...)`, plus `.visible_alias(...)` variants for help
- Env fallback: set `.env("NAME")` to read from the environment when not present in argv
- Default values: set `.default_value("x")` to use when neither argv nor env provides a value
- Required: set `.required()` to require the arg be present
- Arity: use `.min_values(n)`, `.max_values(n)`, or `.num_values(min, max)`

### Actions

Control how values are stored with `.action(...)`:

- `ArgAction::Set` (default for value-taking args)
- `ArgAction::SetTrue` / `ArgAction::SetFalse` (flags)
- `ArgAction::Count` (count repetitions)
- `ArgAction::Append` (collect multiple values)
- `ArgAction::Help` (emit help; short for short flag, long for long)
- `ArgAction::Version` (emit version; short for short flag, long for long)

### Counting Flags

Use `ArgAction::Count` to count repetitions (e.g. `-vvv`):

```mbt nocheck
let cmd = Command::new("demo").arg(
  Arg::new("verbose").short('v').action(ArgAction::Count),
)
let m = cmd.parse(argv=["-vvv"]) catch { _ => panic() }
assert_eq(m.count_of("verbose"), 3)
```

### Positionals

- Positional args are built by omitting `.short(...)` / `.long(...)` and using
  positional-only setters like `.index(...)`.
- `.index(...)` controls ordering; otherwise, positionals are appended in the order
  they are added.
- `.multiple()` on a positional captures the rest.
- `.allow_hyphen_values()` allows values like `-1` or `-foo` without `--`.
- `.last()` treats the positional as a trailing var-arg and stops option parsing.
- `.default_value(...)` can be used for a missing positional.
- `.required()` and `.min_values(...)` affect positional usage in help.

## Negation (`--no-...`)

For boolean flags, you can opt in to a clap-like `--no-<flag>` form:

```mbt nocheck
let cmd = Command::new("demo").arg(
  Arg::new("verbose").long("verbose").negatable(),
)
let m = cmd.parse(argv=["--no-verbose"]) catch { _ => panic() }
assert_false(m.get_flag("verbose"))
```

If `negatable=true` is not set, `--no-verbose` is treated as an unknown
argument.

## Global Args

Mark an option/flag as global so it is accepted in subcommands (including after
the subcommand name) and is visible from the subcommand `Matches`:

```mbt nocheck
let sub = Command::new("echo").arg(Arg::new("msg").index(0))
let root = Command::new("root")
  .arg(Arg::new("verbose").long("verbose").global())
  .subcommand(sub)

let m = root.parse(argv=["echo", "--verbose", "hi"]) catch { _ => panic() }
assert_true(m.get_flag("verbose"))
assert_true(m.subcommand_matches("echo").unwrap().get_flag("verbose"))
```

## Arg Groups (minimal)

Use groups for required or mutually exclusive options:

```mbt nocheck
///|
let cmd = Command::new("demo")
  .group(ArgGroup::new("mode").required())
  .group(ArgGroup::new("color").multiple(value=false))
  .arg(Arg::new("fast").long("fast").group("mode"))
  .arg(Arg::new("slow").long("slow").group("mode"))
  .arg(Arg::new("red").long("red").group("color"))
  .arg(Arg::new("blue").long("blue").group("color"))
```

## Reading Values (`Matches`)

Raw access:

- `matches.get_flag("flag") -> Bool`
- `matches.value_of("name") -> String?`
- `matches.values_of("name") -> Array[String]?`
- `matches.source_of("name") -> ValueSource?`
- `matches.value_sources_of("name") -> Array[ValueSource]?`
- `matches.count_of("flag") -> Int` (for `ArgAction::Count`)

Convenience access:

- `matches.get_one("count") : String`
- `matches.get_option("count") : String?`
- `matches.get_array("tag") : Array[String]`

## Value Sources

Each value/flag is tagged with where it came from:

- `ValueSource::Argv`
- `ValueSource::Env`
- `ValueSource::Default`

Use `matches.source_of(name)` for the overall source, or
`matches.value_sources_of(name)` for per-value sources. `ValueSource::Default`
is used when a value comes from `.default_value(...)` / `.default_values(...)`.

## Reconstructing Structured Configs

For more complicated “decode into a struct/enum” workflows, implement
`FromMatches` and call `matches.decode()`:

```mbt nocheck
///|
struct Config {
  count : Int
  name : String
}

///|
impl FromMatches for Config with from_matches(m : Matches) -> Config raise ArgumentError {
  let count_str = m.get_one("count")
  let count = @strconv.parse_int(count_str) catch {
    _ => raise ArgumentError::InvalidValue("invalid int: " + count_str)
  }
  let name = m.get_one("name")
  Config::{ count, name }
}

///|
let cfg : Config = matches.decode()
```

## Errors

Parsing and decoding errors are raised as `ArgumentError` (a `suberror`).
The current variants include:

- `UnknownArgument(arg, hint?)`, `InvalidArgument`, `MissingValue`, `TooManyPositionals`
- `MissingRequired`, `TooFewValues`, `TooManyValues`
- `InvalidValue`, `InvalidValueCount`
