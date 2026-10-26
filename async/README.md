# Asynchronous programming library for MoonBit

Packages under this directory provide basic asynchronous IO functionality for MoonBit,
as well as useful asynchronous programming facilities.
Currently, this library has full support for native backend and wasm backend.
JavaScript backend has browser-compatible support for a limited set of API (most notably HTTP client, backed by fetch API),
and wasm-gc backend is not supported.
All operating systems supported by MoonBit (Linux/MacOS/Windows) are supported.
API document is available at <https://mooncakes.io/docs/moonbitlang/core/async>.

WARNING: this library is current experimental, API is subject to future change.

## Installation
Asynchronous programming support is part of the MoonBit standard library `moonbitlang/core`,
so there is no need to explicitly install any library.
In order to use asynchronous programming API, users do need to import specific packages, though:

- `moonbitlang/core/async`: basic asynchronous operations, asynchronous control flow primitives.
  This package must be imported in order to use `async fn main` or `async test`
- `moonbitlang/core/async/socket`: TCP and UDP socket
- `moonbitlang/core/async/stdio`: operations on standard output channels
- `moonbitlang/core/async/fs`: file system operations, such as file IO and directory reading
- `moonbitlang/core/async/process`: spawning system process
- `moonbitlang/core/async/shell`: shell-free commands, pipelines, redirection, and glob expansion
- `moonbitlang/core/async/http`: HTTP client and server support. Features:
    - HTTPS client support
    - `CONNECT` based HTTP/HTTPS proxy support
- `moonbitlang/core/async/websocket`: WebSocket client and server support. Features:
    - TLS encrypted WebSocket (`wss://`) support
    - `CONNECT` based HTTP/HTTPS proxy support
    - native integration with `moonbitlang/core/async/http`
- `moonbitlang/core/async/io`: generic IO abstraction & utilities, such as in-memory pipe
- `moonbitlang/core/async/signal`: control signal handling behavior
- `moonbitlang/core/async/raw_fd`: integrate arbitrary file descriptor into `moonbitlang/core/async`'s event loop.
    Only supports native backend
- `moonbitlang/core/async/gzip`: wrap async stream with gzip compression/decompression
- `moonbitlang/core/async/tls`: TLS support via OpenSSL/Schannel
- `moonbitlang/core/async/pipe`: operations on operating system pipes
- `moonbitlang/core/async/js_async`: integration with JavaScript promise and readable stream.
    Only supports JavaScript backend.

To use these packages, add them to the `import` field of `moon.pkg`.

## Runtime model
Currently, `moonbitlang/core/async` features a single-threaded, cooperative multitasking model.
With this single-threaded model,
code without suspension point (i.e. code that does not call `async` functions)
can always be considered atomic.
This model eliminates the need for many locks and bugs. However, it also come with some caveats:

- task scheduling can only happen when current task suspend itself,
  by performing some asynchronous IO operation or manually calling `@async.pause`.
  If you perform heavy computation loop without pausing from time to time,
  the whole program will be blocked until the loop terminates,
  and other task will not get executed before that.
  Similarly, performing blocking IO operation **not** provided by `moonbitlang/core/async`
  may block the whole program as well

- in the same way, task cancellation can only happen when a task is in suspended state
  (blocked by IO operation or manually `pause`'ed)

- although internally `moonbitlang/core/async` may use OS threads to perform some IO job,
  user code can only utilize one hardware processor

## Task cancellation
In `moonbitlang/core/async`, every suspension point
(a sleep, a wait operation, asynchronous IO operations or `@async.pause`) are cancellable by default.
Therefore, asynchronous operations built from these basic primitives are also cancellable by default,
so there is no need to worry about accidentally creating uncancellable task.
As a consequence, a blocking `async fn` is fully modular and does not lose any generality in `moonbitlang/core/async`,
and we encourage libraries built around `moonbitlang/core/async` to provide public API in simple, blocking style whenever possible.

In `moonbitlang/core/async`, when a task is cancelled,
it will receive a special signal at where it suspended.
This cancellation signal is similar to, but not the same as an error.
The cancellation signal propogates like an error, and can trigger `defer` and `errdefer` blocks.
However, `catch` can **not** capture the cancellation signal.

In most cases, users don't need to handle cancellation specially.
Cleanup related logic can be put in `defer` or `errdefer`,
while other error handlers usually don't need to handle cancellation anyway.
If special handling of cancellation is indeed necessary,
`@async.handle_cancellation` can be used.

Cancellation is a sticky state attached to every task in `moonbitlang/core/async`.
The aforementioned cancellation signal is merely a notification for the cancelled task,
capturing that signal via `@async.handle_cancellation` does *not* revert cancellation.
The task will stay in cancelled state,
and the next unprotected async operation will get cancelled immediately.
To truly protect a piece of critical code from cancellation, use `@async.protect_from_cancel`.

`async` function types are cancellable by default in MoonBit.
Non-cancellable operations (i.e. all asynchronous code are wrapped in `@async.protect_from_cancel`)
can be explicitly annotated with `nocancel` at the end of the signature,
to indicate that the function cannot be cancelled from type level.
Calling cancellable function from `noconcel` context is a type error.

## Structured concurrency and error propagation
`moonbitlang/core/async` features *structured concurrency*.
In `moonbitlang/core/async`, every asynchronous task must be spawned in a *task group*.
Task groups can be created with the `with_task_group` function

```moonbit
async fn with_task_group(async (TaskGroup) -> Unit)  -> Unit
```

`with_task_group(f)` will create a new task group and run `f` in the new group.
`f` will receive the new group itself as argument, and may spawn new task using that group.
Spawned tasks run concurrently with other code
(subjected to the single threaded execution model's restriction mentioned above).

By default, `with_task_group(f)` will wait for all child tasks,
including `f` itself to complete before returning normally.
If any of the child task failed, `with_task_group` will fail with the same error as well.

In any case, when `with_task_group` decides that it wants to exit immediately,
it will automatically cancel all remaining child tasks,
and wait for their cancellation cleanup logic's completion before actually returning.
So When `with_task_group` returns,
it is guaranteed that all tasks spawned in the group have terminated completely,
leaving no room for orphan task and resource leak.

For more behavior detail and useful API, consult the API document of `@async.with_task_group` and methods on `@async.TaskGroup`.
