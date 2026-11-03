# Process Management (`@moonbitlang/core/async/process`)

Asynchronous process spawning and management for MoonBit with support for pipes, environment variables, and I/O redirection.

## Quick Start

### Running Simple Commands

Execute commands and collect their output:

```moonbit check
///|
#cfg(all(target="native", not(platform="windows")))
async test "simple command execution" {
  let result = @process.run("echo", ["Hello, World!"], stdout=Collect)
  inspect(result.exit_code, content="0")
  inspect(result.stdout_text().has_prefix("Hello"), content="true")
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "command with exit code" {
  let result = @process.run("sh", ["-c", "exit 42"])
  inspect(result.exit_code, content="42")
}
```

### Spawn a Process in a Task Group

Use `@process.spawn` to start a process without blocking the current task. It
registers the process with a task group and returns a `Process` handle for
waiting, cancellation, and parent-side pipe access:

```moonbit check
///|
#cfg(all(target="native", not(platform="windows")))
async test "spawn command in background" {
  @async.with_task_group(group => {
    let process = @process.spawn(group, "sh", ["-c", "sleep 0.5; exit 42"])
    // do other stuff while the process is running in the background
    @async.sleep(250)
    // use `.wait()` to wait for the child process, or `.try_wait()` to peek its status
    inspect(process.wait(), content="42")
  })
}
```

Child processes follow the rules of structured concurrency:

- by default, the task group waits for the child process before returning normally,
  unless `no_wait=true` is passed to `@process.spawn`
- in any case, `with_task_group` will wait for the child process before exitting.
  If the task group decides to exit regardless of the child (for example due to fatal error or external cancellation),
  it will cancel the child process automatically, and wait for the child process to finish its cleanup
- `process.cancel()` can be used to manually cancel the child process,
  and `process.wait()` waits for actual termination.

## Collecting Process Output

`run()` collects a stream when it is redirected with `stdout=Collect` or `stderr=Collect`.
Use `.stdout_binary()`/`.stderr_binary()` on the returned `struct ProcessResult` for raw `Bytes`,
or `.stdout_text()`/`.stderr_text()` to decode the corresponding stream as UTF-8.
An output accessor fails if that stream was not redirected with `Collect`.

### Collect Standard Output

Capture stdout from a process:

```moonbit check
///|
#cfg(all(target="native", not(platform="windows")))
async test "collect stdout" {
  let result = @process.run("printf", ["test output"], stdout=Collect)
  inspect(result.exit_code, content="0")
  inspect(result.stdout_text(), content="test output")
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "collect stdout with args" {
  let result = @process.run(
    "sh",
    ["-c", "echo 'line 1'; echo 'line 2'"],
    stdout=Collect,
  )
  let output = result.stdout_text()
  inspect(result.exit_code, content="0")
  inspect(output.contains("line 1"), content="true")
  inspect(output.contains("line 2"), content="true")
}
```

### Collect Standard Error

Capture stderr from a process:

```moonbit check
///|
#cfg(all(target="native", not(platform="windows")))
async test "collect stderr" {
  let result = @process.run(
    "sh",
    ["-c", "printf 'error message' >&2"],
    stderr=Collect,
  )
  inspect(result.exit_code, content="0")
  inspect(result.stderr_text(), content="error message")
}
```

### Collect Both Stdout and Stderr

Capture both output streams separately:

```moonbit check
///|
#cfg(all(target="native", not(platform="windows")))
async test "collect both streams" {
  let result = @process.run(
    "sh",
    ["-c", "printf 'out msg'; printf 'err msg' >&2"],
    stdout=Collect,
    stderr=Collect,
  )
  inspect(result.exit_code, content="0")
  inspect(result.stdout_text(), content="out msg")
  inspect(result.stderr_text(), content="err msg")
}
```

### Collect Merged Output

Merge stdout and stderr into a single stream:

```moonbit check
///|
#cfg(all(target="native", not(platform="windows")))
async test "collect merged output" {
  let result = @process.run(
    "sh",
    ["-c", "printf 'ab'; printf 'cd' >&2; printf 'ef'"],
    stdout=Collect,
    stderr=DuplicateStdout,
  )
  inspect(result.exit_code, content="0")
  inspect(result.stdout_text(), content="abcdef")
}
```

## Process I/O with Pipes

### Reading from Process

Use `stdout=Collect` or `stderr=Collect` with `@process.spawn` to collect child output from parent.
Output is available through `.stdout` or `.stderr` on the returned process handle.
`.stdout` and `.stderr` also has a builtin `.text` field providing text view for the corresponding stream:

```moonbit check
///|
#cfg(all(target="native", not(platform="windows")))
async test "read from process with pipe" {
  @async.with_task_group(group => {
    let child = @process.spawn(
      group,
      "echo",
      ["Hello from process"],
      stdout=Collect,
    )
    defer child.stdout.close()
    let output = child.stdout.text.read_all()
    inspect(output.has_prefix("Hello"), content="true")
  })
}
```

### Writing to Process

Use `FeedFromParent` with `@process.spawn` to create feed input to child's `stdin` from parent.
Input can be written through `.stdin` on the returned process handle.
Close `.stdin` when writing is complete so the child observes end-of-file:

```moonbit check
///|
#cfg(all(target="native", not(platform="windows")))
async test "write to process with pipe" {
  @async.with_task_group(group => {
    let child = @process.spawn(
      group,
      "cat",
      ["-"],
      stdin=FeedFromParent,
      stdout=Collect,
    )
    group.spawn_bg(() => {
      defer child.stdin.close()
      child.stdin.text.write("test input\n")
    })
    group.spawn_bg(() => {
      defer child.stdout.close()
      let output = child.stdout.text.read_all()
      inspect(output.contains("test input"), content="true")
    })
  })
}
```

`Collect` and `FeedFromParent` are the convenient choices for one child created
with `spawn()` or `spawn_orphan()`. Their child-side pipe endpoints are closed
automatically after process creation. The corresponding `Process.stdin`,
`Process.stdout`, and `Process.stderr` channels are caller-owned and must be
closed when no longer needed.

## File Redirection

### Redirect from File

Use a file as process input:

```moonbit check
///|
#cfg(all(target="native", not(platform="windows")))
async test "redirect input from file" {
  @async.with_task_group(root => {
    let input_file = "_build/process_test_input.txt"
    @fs.write_text(input_file, "file content")
    root.add_defer(() => @fs.remove(input_file))
    let result = @process.run(
      "cat",
      [],
      stdin=FromFile(input_file),
      stdout=Collect,
    )
    inspect(result.exit_code, content="0")
    inspect(result.stdout_text(), content="file content")
  })
}
```

### Redirect to File

Write process output to a file:

```moonbit check
///|
#cfg(all(target="native", not(platform="windows")))
async test "redirect output to file" {
  @async.with_task_group(root => {
    let output_file = "_build/process_test_output.txt"
    root.add_defer(() => @fs.remove(output_file))
    let result = @process.run(
      "echo",
      ["test output"],
      stdout=ToFile(output_file),
    )
    inspect(result.exit_code, content="0")
    let content = @fs.read_text(output_file)
    inspect(content.has_prefix("test output"), content="true")
  })
}
```

### File to File Redirection

Copy file content using process redirection:

```moonbit check
///|
#cfg(all(target="native", not(platform="windows")))
async test "file to file redirection" {
  @async.with_task_group(root => {
    let input_file = "_build/process_redirect_in.txt"
    let output_file = "_build/process_redirect_out.txt"
    @fs.write_text(input_file, "redirect test")
    root.add_defer(() => @fs.remove(input_file))
    root.add_defer(() => @fs.remove(output_file))
    let _ = @process.run(
      "cat",
      [],
      stdin=FromFile(input_file),
      stdout=ToFile(output_file),
    )
    inspect(@fs.read_text(output_file), content="redirect test")
  })
}
```

`FromFile(path)`, `ToFile(path)`, and `AppendFile(path)` are automatically
managed, single-process redirections. The file is opened while the process is
created and the process API closes its copy of the file handle afterward.

### Share a File Redirection

Use `redirect_to_file()` when multiple children must share the same open output
file, or when custom creation modes or permissions are needed. Unlike
`ToFile(path)` and `AppendFile(path)`, it opens the file immediately and returns
a caller-owned `SharedProcessOutput`. Pass it as `Shared(output)`, and close it
after it has been passed to the last child or if spawning is abandoned:

```moonbit check
///|
#cfg(all(target="native", not(platform="windows")))
async test "redirect multiple processes to one file" {
  let output_file = "_build/process_shared_output.txt"
  defer @fs.remove(output_file)
  let output = @process.redirect_to_file(output_file)
  {
    defer output.close()
    @async.with_task_group(group => {
      @process.spawn(group, "printf", ["first"], stdout=Shared(output))
      |> ignore
      @process.spawn(group, "printf", ["second"], stdout=Shared(output))
      |> ignore
    })
  }
  let content = @fs.read_text(output_file)
  inspect(content.contains("first"), content="true")
  inspect(content.contains("second"), content="true")
}
```

`redirect_from_file()` similarly returns a caller-owned `SharedProcessInput`.
Pass it as `Shared(input)`. Children using it share one open file description
and therefore one file offset: data consumed by one child is no longer
available to the others. Always close the value after its last use.

## Environment Variables

### Setting Environment Variables

Pass custom environment variables to processes:

```moonbit check
///|
#cfg(all(target="native", not(platform="windows")))
async test "set environment variable" {
  let result = @process.run(
    "sh",
    ["-c", "echo $MY_VAR"],
    extra_env={ "MY_VAR": "my_value" },
    stdout=Collect,
  )
  inspect(result.exit_code, content="0")
  inspect(result.stdout_text().trim(), content="my_value")
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "multiple environment variables" {
  let result = @process.run(
    "sh",
    ["-c", "echo $VAR1-$VAR2"],
    extra_env={ "VAR1": "first", "VAR2": "second" },
    stdout=Collect,
  )
  inspect(result.exit_code, content="0")
  inspect(result.stdout_text().trim(), content="first-second")
}
```

### Isolated Environment

Run process without inheriting parent environment:

```moonbit check
///|
#cfg(all(target="native", not(platform="windows")))
async test "isolated environment" {
  let result = @process.run(
    "env",
    [],
    extra_env={ "ONLY_VAR": "only_value" },
    inherit_env=false,
    stdout=Collect,
  )
  let output = result.stdout_text()
  inspect(result.exit_code, content="0")
  inspect(output.contains("ONLY_VAR=only_value"), content="true")
  // Parent environment variables won't be present
  inspect(output.contains("PATH="), content="false")
}
```

## Working Directory

### Change Working Directory

Execute processes in a specific directory:

```moonbit check
///|
#cfg(all(target="native", not(platform="windows")))
async test "set working directory" {
  let result = @process.run("pwd", [], cwd="async", stdout=Collect)
  inspect(result.exit_code, content="0")
  let text = result.stdout_text().trim()
  // Check that the path ends with "src" (works across OSes)
  inspect(text.has_suffix("async"), content="true")
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "relative path in cwd" {
  let result = @process.run("ls", [], cwd="async", stdout=Collect)
  inspect(result.exit_code, content="0")
  let text = result.stdout_text()
  // Should list contents of src directory
  let has_content = text.length() > 0
  inspect(has_content, content="true")
}
```

## Asynchronous Process Management

### Spawn and Wait

`run()` waits in the current task. `spawn()` starts the process in a task group
and returns a handle immediately:

```moonbit check
///|
#cfg(all(target="native", not(platform="windows")))
async test "spawn and wait" {
  @async.with_task_group(group => {
    let child = @process.spawn(group, "sleep", ["0.1"])
    inspect(child.pid > 0, content="true")
    inspect(child.try_wait() is None, content="true")
    inspect(child.wait(), content="0")
  })
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "wait for specific exit code" {
  let result = @process.run("sh", ["-c", "exit 5"])
  inspect(result.exit_code, content="5")
}
```

The `Process` handle exposes:

- `pid`, the operating-system process identifier
- `stdin`, when `stdin=FeedFromParent` was requested
- `stdout` and `stderr`, when the corresponding stream uses `Collect`
- `wait()`, `try_wait()`, and `cancel()` for lifecycle management

Only use the pipe fields configured during `spawn()`, and close each configured
field when it is no longer needed.

### Cancellation

Cancelling the task running `run()`, cancelling the task group containing a
spawned process, or calling `Process.cancel()` invokes the process cancellation
handler. The default is `graceful_cancel(timeout=5000)`: it sends `SIGTERM` on
POSIX systems or `SIGBREAK` on Windows, waits up to five seconds, and then kills
the process if necessary.

Use `hard_cancel()` to kill immediately, or construct
`graceful_cancel(timeout~, signal?)` to select a timeout and, on POSIX systems,
a signal. `Process.cancel()` initiates cancellation; call `Process.wait()` when
the code must wait until the process has actually terminated.

### Spawn Orphan Process

Start an orphan process with an unbounded lifetime.
The orphan process will not be automatically cancelled,
and may live longer than the main process.
It is recommended to use `@process.spawn` or `@process.run` whenever possible,
use `@process.spawn_orphan` only when it is absolutely necessary:

```moonbit check
///|
#cfg(all(target="native", not(platform="windows")))
async test "spawn orphan and wait later" {
  let proc = @process.spawn_orphan("sh", ["-c", "sleep 0.1; exit 7"])

  // Unlike `@process.spawn`,
  // the handle returned by `@process.spawn_orphan` must be closed manually
  defer proc.close()

  // Do other work...
  @async.sleep(50)

  // Wait for the process to complete
  let exit_code = proc.wait()
  inspect(exit_code, content="7")
}
```

## Advanced Usage

### Merge Output Streams

Use `DuplicateStdout` to redirect `stderr` to the same destination as `stdout`
for a child process:

```moonbit check
///|
#cfg(all(target="native", not(platform="windows")))
async test "merge stdout and stderr" {
  @async.with_task_group(group => {
    let child = @process.spawn(
      group,
      "sh",
      ["-c", "echo 'to stdout'; echo 'to stderr' >&2"],
      stdout=Collect,
      stderr=DuplicateStdout,
    )
    defer child.stdout.close()
    let output = child.stdout.text.read_all()
    inspect(output.contains("to stdout"), content="true")
    inspect(output.contains("to stderr"), content="true")
  })
}
```

### Multiple Processes Sharing Output

`read_from_process()` creates a parent reader and a `SharedProcessOutput` that
can be passed to multiple children as `Shared(writer)`, allowing the parent to
collect their merged output. Both ends are explicit and caller-owned.

```moonbit check
///|
#cfg(all(target="native", not(platform="windows")))
async test "multiple processes to one pipe" {
  @async.with_task_group(root => {
    let (reader, writer) = @process.read_from_process()
    root.spawn_bg(no_wait=true, () => {
      defer reader.close()
      let output = reader.text.read_all()
      inspect(output.contains("first"), content="true")
      inspect(output.contains("second"), content="true")
    })
    @async.with_task_group(group => {
      // Close the shared child-side handle after spawning the last child.
      defer writer.close()
      @process.spawn(group, "echo", ["first"], stdout=Shared(writer)) |> ignore
      @process.spawn(group, "echo", ["second"], stdout=Shared(writer)) |> ignore
    })
  })
}
```

### Other Shared Pipes

`write_to_process()` returns a `SharedProcessInput` for children and a
`WriteToProcess` for the parent. Pass the input endpoint as `Shared(input)`. It
is useful when the same input stream must be passed to multiple children, or
when using `run()` without a `Process.stdin` handle. Children share the stream:
each byte is consumed by only one reader.

`pipe()` returns a `(SharedProcessInput, SharedProcessOutput)` pair for direct
child-to-child communication. Pass the output to the producer and the input to
the consumer. Both handles remain caller-owned and must be closed after the
last corresponding child has been spawned, or if spawning fails.

For every shared pipe, also close the parent-facing `ReadFromProcess` or
`WriteToProcess` when reading or writing is complete. Failing to close the last
writer can prevent readers from observing end-of-file.

## Types Reference

`ProcessInput` and `ProcessOutput` are the redirection types accepted by
`run()`, `spawn()`, and `spawn_orphan()`.

Parent-facing process pipes are binary readers or writers. Use their `.text`
view for UTF-8 text I/O, as in `child.stdout.text.read_all()` and
`child.stdin.text.write(...)`.

| API or value | Redirection role | Ownership and closing |
|---|---|---|
| `Inherit` | Inherit the corresponding stream from the current execution context | No caller-owned handle |
| `Stdin`, `Stdout`, `Stderr` | Select a parent-process standard stream explicitly | No caller-owned handle |
| `FeedFromParent` | Feed one child's stdin through `Process.stdin` | Close `Process.stdin` after writing |
| `Collect` | Collect one output stream through a process handle or `ProcessResult` | With `spawn()`, close `Process.stdout` or `.stderr` after reading |
| `FromFile(path)` | Read one child's stdin from a file | Managed automatically |
| `ToFile(path)`, `AppendFile(path)` | Write one child's output to a file | Managed automatically |
| `DuplicateStdout` | Send a child's stderr to its stdout destination | No separate handle; valid only as `stderr` |
| `Shared(endpoint)` | Use a caller-owned input or output endpoint | Close the endpoint after passing it to its last child |
| `write_to_process()` | `SharedProcessInput` plus parent writer | Caller closes both ends |
| `read_from_process()` | Parent reader plus `SharedProcessOutput` | Caller closes both ends |
| `pipe()` | `SharedProcessInput` plus `SharedProcessOutput` | Caller closes both ends |
| `redirect_from_file(path)` | Shared file-backed input endpoint | Caller closes it after its last use |
| `redirect_to_file(path, ...)` | Shared file-backed output endpoint | Caller closes it after its last use |

## Best Practices

1. **Close every caller-owned channel**, preferably immediately after acquiring
   it with `defer channel.close()`.
2. **Use `run()`** for simple output capture.
3. **Use `spawn()` for interactive pipes**, because the parent endpoints are
   returned on the `Process` handle.
4. **Use shared redirections only when sharing is required**, and close them
   after the last child has been spawned.
5. **Handle exit codes** explicitly; a nonzero exit is not a spawning error.
6. **Prefer `spawn()` or `run()`** and use `spawn_orphan()` only when the process
   must outlive structured concurrency.

## Error Handling

Failure to create a process or initialize a redirection raises an error. Once a
process starts successfully, its exit status is returned in
`ProcessResult.exit_code`; a nonzero status is not raised as an error. If a
process is killed by a signal on POSIX systems, its status is the negative
signal number.

```moonbit check
///|
#cfg(any(target="native", target="wasm"))
async test "handle process errors" {
  // Non-existent command fails
  @test.assert_raise_async(() => @process.run("nonexistent_command", []))
}

///|
#cfg(any(target="native", target="wasm"))
async test "exit code indicates failure" {
  let result = if @async.platform is Windows {
    @process.run("cmd.exe", ["/c", "exit", "1"])
  } else {
    @process.run("sh", ["-c", "exit 1"])
  }
  let is_failure = result.exit_code != 0
  inspect(is_failure, content="true")
}
```

For complete examples, see the test files in `src/process/`.
