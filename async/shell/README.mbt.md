# Shell-Style Scripting (`@moonbitlang/core/async/shell`)

`@shell` is a small, shell-free process EDSL: everything you use a shell for —
running commands, pipes, redirects, exit-code logic, glob expansion — as a
library, minus the shell itself. It is meant for scripts, sandboxed programs,
and agents that need a familiar process API without receiving a shell as
ambient authority.

## The invariant

`Cmd` never invokes a shell. The executable and argument vector stay separate,
and every argument is passed literally. `|`, `>`, `&&`, `$()`, and `*` have no
special meaning. Use `Pipeline` for pipes and ordinary MoonBit for control flow.
Embedded NUL characters in process metadata are rejected before spawning rather
than being truncated by an operating-system argv boundary.

The package supports the `native` and `wasm` targets. On `wasm`, process
creation is delegated through the host operations used by
`moonbitlang/core/async/process`.

## The whole API

A process is described by one constructor and executed in one of four modes.
There are no builder chains: a `Cmd` is written the way it is read.

```moonbit nocheck
///|
Cmd(
  program,                 // executable name or path
  arguments,               // Array[String], each passed literally
  cwd? : String,           // default: inherited working directory
  env? : Map[String, String], // default: {}
  inherit_env? : Bool,     // default: true
  stdin? : Stdin,          // default: closed
  stdout? : Redirect,      // default: Capture
  stderr? : Redirect,      // default: Capture
) -> Cmd

Pipeline(commands : Array[Cmd]) -> Pipeline
```

```moonbit nocheck
///|
enum Stdin {
  Text(String)
  Binary(Bytes)
  FromFile(String) // `< path`
  Inherit
}

///|
enum Redirect {
  Capture
  Inherit
  ToFile(String) // `> path`
  AppendToFile(String) // `>> path`
  Discard // `> /dev/null`
}
```

Execution: `output` collects the streams, `status` returns only the exit code,
`run` is the checked form of `status` — quiet on success and raising on a
non-zero exit — and `each_line` follows standard output as it is produced. All
four exist on both `Cmd` and `Pipeline`.

`Cmd` and `Pipeline` are abstract and immutable. Their derived `Debug`
representations support logging and snapshot review without exposing one
getter per constructor option. `Output` is abstract too; scripts consume it
through `exit_code()`, `stdout()`, `stdout_bytes()`, and `stderr()`. Its
`check() -> Unit raise` only checks an already completed result. `Stdin` and
`Redirect` expose their variants because callers construct those choices.

## 1. Run one command

```mbt check
///|
async test {
  let output = @shell.Cmd("moonx", ["bobzhang/printf@0.1.0", "hello"]).output()
  assert_eq(output.exit_code(), 0)
  assert_eq(output.stdout(), "hello")
}
```

## 2. Pass shell characters literally

This prints the characters; it does not execute `echo` and does not create a
pipe.

```mbt check
///|
async test {
  let output = @shell.Cmd("moonx", [
    "bobzhang/printf@0.1.0", "%s", "$(echo no) | *",
  ]).output()
  assert_eq(output.stdout(), "$(echo no) | *")
}
```

## 3. Set cwd and environment

Options are labelled arguments on the constructor, so the whole plan is one
expression.

```mbt check
///|
test {
  let command = @shell.Cmd("moon", ["check"], cwd="workspace", env={
    "NO_COLOR": "1",
  })
  debug_inspect(
    command,
    content=(
      #|{
      #|  program: "moon",
      #|  arguments: ["check"],
      #|  cwd: Some("workspace"),
      #|  env: { "NO_COLOR": "1" },
      #|  inherit_env: true,
      #|  stdin: None,
      #|  stdout: Capture,
      #|  stderr: Capture,
      #|}
    ),
  )
}
```

Pass `inherit_env=false` to start from an empty environment instead of adding
to the parent's.

## 4. Inspect a plan before running it

A plan can be logged, diffed, or snapshot-reviewed before anything is spawned.
Because `Cmd` is immutable, the value shown by its derived `Debug`
representation is the value that runs. Its fields stay private: inspection does
not add another programmable API for every constructor option.

```mbt check
///|
test {
  let command = @shell.Cmd("rm", ["-rf", "/"])
  debug_inspect(
    command,
    content=(
      #|{
      #|  program: "rm",
      #|  arguments: ["-rf", "/"],
      #|  cwd: None,
      #|  env: {},
      #|  inherit_env: true,
      #|  stdin: None,
      #|  stdout: Capture,
      #|  stderr: Capture,
      #|}
    ),
  )
}
```

Building a command list is ordinary MoonBit; there is no builder to learn.

```mbt check
///|
test {
  let arguments = ["check"]
  if true {
    arguments.push("--target")
    arguments.push("wasm")
  }
  let command = @shell.Cmd("moon", arguments)
  debug_inspect(
    command,
    content=(
      #|{
      #|  program: "moon",
      #|  arguments: ["check", "--target", "wasm"],
      #|  cwd: None,
      #|  env: {},
      #|  inherit_env: true,
      #|  stdin: None,
      #|  stdout: Capture,
      #|  stderr: Capture,
      #|}
    ),
  )
}
```

## 5. Pipe commands

Every stage is separately visible to the process host, and all stages run
concurrently in one structured task group. Adjacent children share one blocking
operating-system pipe created by `@process.pipe()`: payload bytes stay in the
host pipe rather than crossing this process through a relay task. Each end is
owned by the spawn that receives it, so the parent does not keep an extra copy
that could delay EOF.

```mbt check
///|
async test {
  let output = @shell.Pipeline([
    Cmd("moonx", ["bobzhang/printf@0.1.0", "alpha\nbeta\n"]),
    Cmd("moonx", ["bobzhang/tail@0.1.0", "-n", "1"]),
    Cmd("moonx", ["bobzhang/tr@0.1.0", "a-z", "A-Z"]),
  ]).output()
  assert_eq(output.stdout(), "BETA\n")
  assert_eq(output.exit_code(), 0)
}
```

## 6. Supply standard input

Standard input is closed by default, so non-interactive runs cannot
accidentally wait on ambient input. `stdin` on the first stage also feeds a
pipeline; giving it to a later stage is rejected.

```mbt check
///|
async test {
  let output = @shell.Pipeline([
    Cmd("moonx", ["bobzhang/tr@0.1.0", "a-z", "A-Z"], stdin=Text("hello")),
    Cmd("moonx", ["bobzhang/tr@0.1.0", "A-Z", "a-z"]),
  ]).output()
  assert_eq(output.stdout(), "hello")
}
```

Use `Binary` when the input is not text:

```mbt check
///|
async test {
  let output = @shell.Cmd(
    "moonx",
    ["bobzhang/cat@0.1.0"],
    stdin=Binary(b"\x00\xff"),
  ).output()
  assert_eq(output.stdout_bytes(), b"\x00\xff")
}
```

## 7. Redirect to and from files

`ToFile` and `AppendToFile` replace a shell's `> path` and `>> path`, and
`FromFile` replaces `< path`. Without them the only shell-free option would be
to capture in memory and write the file yourself.

```mbt check
///|
async test {
  let directory = @fs.tmpdir(prefix="shell-readme")
  let path = "\{directory}/log.txt"
  @shell.Cmd("moonx", ["bobzhang/printf@0.1.1", "one\n"], stdout=ToFile(path)).run()
  @shell.Cmd(
    "moonx",
    ["bobzhang/printf@0.1.1", "two\n"],
    stdout=AppendToFile(path),
  ).run()
  let back = @shell.Cmd("moonx", ["bobzhang/cat@0.1.0"], stdin=FromFile(path)).output()
  assert_eq(back.stdout(), "one\ntwo\n")
  @fs.rmdir(directory, recursive=true)
}
```

A redirected stream is not captured, so it arrives empty in `Output` and does
not count against `max_output_bytes`. Use `Inherit` to hand a stream to the
parent's own descriptor. Only the last stage of a pipeline may redirect stdout,
since every earlier stage's stdout is the pipe.

## 8. Follow output as it is produced

`output` returns nothing until the command finishes. `each_line` delivers
standard output line by line while the command runs, which is what a
long-running build or test needs in order to report progress. Completed lines
are not retained, so total output is unbounded; `max_line_bytes` (8 MiB by
default) caps one line's content exactly, so a child that never emits a newline
cannot exhaust memory. Both `\n` and `\r\n` are recognised as terminators, and
a CRLF's CR does not count against the limit.

```mbt check
///|
async test {
  let seen = []
  let code = @shell.Cmd("moonx", ["bobzhang/printf@0.1.0", "alpha\nbeta\n"]).each_line(line => {
      seen.push(line)
    },
  )
  assert_eq(code, 0)
  assert_eq(seen, ["alpha", "beta"])
}
```

`Pipeline::each_line` follows the last stage the same way.

## 9. Run without capturing output

Use `status` when stdout and stderr should be inherited by the current process.
It returns only the exit code and has no capture limit. `run` is the same
execution with failure checked: the common verb of a script that just wants
the command to have worked.

```mbt check
///|
async test {
  assert_eq(@shell.Cmd("moonx", ["bobzhang/false@0.1.0"]).status(), 1)
  @shell.Cmd("moonx", ["bobzhang/true@0.1.0"]).run()
  try @shell.Cmd("moonx", ["bobzhang/false@0.1.0"]).run() catch {
    _ => ()
  } noraise {
    _ => fail("expected a non-zero exit to raise")
  }
}
```

## 10. Inspect exit status

`Cmd::output` does not turn a non-zero exit status into an exception. Use
ordinary MoonBit control flow or call `check()` when failure should raise.

```mbt check
///|
async test {
  let output = @shell.Cmd("moonx", ["bobzhang/false@0.1.0"]).output()
  if output.exit_code() != 0 {
    assert_eq(output.exit_code(), 1)
  }
}
```

## 11. Pipeline status uses pipefail

`exit_code` is the rightmost non-zero stage status, or zero when all stages
succeed. This is the portable `pipefail` result for the pipeline as a whole.

```mbt check
///|
async test {
  let output = @shell.Pipeline([
    Cmd("moonx", ["bobzhang/false@0.1.0"]),
    Cmd("moonx", ["bobzhang/cat@0.1.0"]),
  ]).output()
  assert_eq(output.exit_code(), 1)
}
```

## 12. Capture stderr

For pipelines, `stderr` concatenates captured standard error in stage order.
Text uses lossy UTF-8 decoding so arbitrary process output cannot cancel
sibling stages; exact standard output remains available through
`stdout_bytes`.

```mbt check
///|
async test {
  let output = @shell.Cmd(
    "moonx",
    ["bobzhang/jq@0.1.1", "."],
    stdin=Text("not json"),
  ).output()
  assert_true(!output.stderr().is_empty())
}
```

## 13. Add a timeout

A timeout cancels the structured task and kills each direct child immediately:
a sandboxed runtime never waits on an untrusted process. A timeout is not a
process-tree deadline: descendants must be contained and reaped by the host's
native process sandbox.

```mbt check
///|
async test {
  try
    @shell.Cmd("moonx", ["bobzhang/sleep@0.1.0", "5"]).output(timeout_ms=100)
  catch {
    @async.TimeoutError => ()
    _ => fail("expected TimeoutError")
  } noraise {
    _ => fail("expected TimeoutError")
  }
}
```

Captured stdout plus stderr is limited to 8 MiB by default, to keep an
untrusted child from growing this process without bound. Override it when
needed:

```mbt nocheck
///|
let output = command.output(max_output_bytes=32 * 1024 * 1024)
```

If all captured streams together exceed the limit, execution raises and
cancels the structured process group.

## 14. Expand paths without a shell

A shell expands `*.mbt` into arguments before the command ever runs. `glob` does
the same expansion as an ordinary value, so the result can be inspected, and
each match reaches the child as one literal argument — a filename containing a
space, a quote, or a `*` cannot be re-split or re-expanded on the way.

```mbt check
///|
async test {
  let sources = @shell.glob("*.mbt", cwd="async/shell")
  assert_true(sources.contains("execute.mbt"))
  let output = @shell.Cmd(
    "moonx",
    ["bobzhang/wc@0.1.0", "-l", ..sources],
    cwd="async/shell",
  ).output()
  assert_eq(output.exit_code(), 0)
}
```

`*` and `?` stay within one path segment, `[a-z]` and `[!a-z]` match a character
from a set, and `**` as a whole segment spans any number of segments. A leading
`.` is matched only by a literal `.`, so neither `*` nor `**` reaches hidden
entries. A trailing separator restricts the result to directories and is kept.
Matches come back in code-unit order with no duplicates, and a pattern that
matches nothing returns an empty array rather than the pattern itself.

Paths are parsed into a root and a list of names, so the same code serves both
platforms. `/` always separates. On Windows a backslash separates too, and a
drive (`C:/x`, `C:\x`), a drive-relative prefix (`C:x`), and a share
(`\\server\share\x`) are recognised as roots; on Unix, where a backslash is not
a separator, it escapes the next character instead.

Matching follows the platform's own rules: on Windows, where filesystems do not
distinguish case, `*.TXT` matches `foo.txt`. Only ASCII case is folded — a
name differing solely in the case of a non-ASCII letter matches exactly, as
full Unicode case folding is deliberately out of scope.

`**` does not descend symbolic links, which is what keeps a link pointing at an
ancestor from looping forever; a component you name yourself resolves links
normally. A wildcard never produces `.` or `..`, though a pattern may name them,
so `../*` reaches the parent — confining an expansion to a subtree is the
sandbox policy's job rather than this function's. A cancelled expansion stops
rather than returning a partial result as though it were complete.

For filtering names already in hand — without touching the disk — MoonBit's
own `str =~ regex` is the more general tool, so this package deliberately does
not export a second pattern-matching predicate.

## Security boundary

This package removes shell parsing and keeps each process invocation structured;
it does not decide which executables or effects are safe. Because a `Cmd` is
immutable and fully readable, a caller can apply its own policy to a plan
before calling `output` or `status` — the description and the execution are
separate steps.

On `wasm`, the host still owns executable authorization and the native process
sandbox. A strong deployment should grant each child only the filesystem,
network, environment, and secret capabilities required for that invocation.
