# moonbitlang/core/arg_parser

A small clap-style (builder API) argument parser for MoonBit.

Design goals:

- Builder-style API (`Command`, `Arg`) inspired by Rust clap (no derive macros).
- Subcommands.
- Built-in help/man generation (`-h`, `--help`, `--help=man`) + `help` subcommand.
- Structured decoding from `Matches` via `FromMatches` (you control parsing).
- No special treatment for `--version` (define it yourself if you want it).
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

- `Command::parse(argv?=..., env?=...) -> Matches raise CommandError`
  - Returns `matches` on success.
  - Raises `CommandError::Help(help_text)` when `-h/--help/--help=man` is present.
  - Raises `CommandError::Help(help_text)` for the `help` subcommand.
  - Raises `CommandError::Build(ArgBuildError::Unsupported(_))` for invalid arg specs.

If `argv` is omitted, `parse()` reads the current process arguments
(`@env.args()[1:]`). For tests, pass `argv=[...]`.
If `env` is omitted, it defaults to the current process environment via
`@env.get_env_vars()`. Pass `env={...}` to override.

On help (`-h/--help/--help=man`), `parse` raises `CommandError::Help`. Decide in
your app whether to print and exit, or show help in some other way.

## Help / Manpage

Help text is generated from the command definition:

- `-h` / `--help`: short help
- `--help=man`: a manpage-like text
- `help [command...]`: subcommand form of help (enabled when a command has subcommands)

You can also render help without parsing:

- `Command::render_help(mode? : HelpMode = HelpMode::Plain) -> String`
  - Use `HelpMode::Man` for a manpage-like output.

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
your own subcommand.

## Options and Positionals

### Constructors

Start with `Arg::new("name")` and chain setters like
`.short(...)`, `.long(...)`, `.option()`, `.help(...)`, `.env(...)`,
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
