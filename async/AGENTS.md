This is the official async runtime for [MoonBit](docs.moonbitlang.com).
For user-facing introduction of the runtime, see `README.md`.

# Overview

This library implements a single threaded asynchronous model,
with structured concurrency API for managing asynchronous tasks.

- scheduler etc. for userland coroutine is in `internal/coroutine`.
  Coroutines are all cancellable.
  Cancellation is implemented as a persistent mark on each coroutine.
  Cancelled code will receive a special error on cancellation,
  so that they can run cleanup code on cancellation.
  Swallowing the cancellation signal does not revert the cancelled state of current coroutine,
  and subsequent asynchronous operations will still get cancelled immediately
- event loop for IO etc. is in `internal/event_loop`.
  The event loop uses `epoll`/`kqueue`/`IOCP` on Linux/MacOS/Windows,
  Operations that are natively asynchronous, such as socket IO,
  are performed through the event loop directly.
  Blocking operations such as regular file IO are dispatched to a thread pool.
  Thread pool operations are made cancellable whenever possible.
  The cancellation mechanism used to cancel a blocking thread pool job is usually
  signal + `EINTR` on Unix systems and `CancelSynchronousIo` on Windows
- async control flow operations are implemented in `.mbt` source files directly under this directory.
  The main control flow primitive is structural task group.
  A task group will only terminate after all its children have terminated,
  and will automatically cancel remaining children when necessary.
  See `task_group.mbt` for semantic details.

## Multiple backend handling
`native` and `wasm` backends both have full feature support, but may have different implentation code.
`js` backend has support for some browser-compatible API such as HTTP client
and some unique JS integration features. But most other API are not supported.
`wasm-gc` backend is unsupported completely

Code under this library should type check without any warning under all backends,
although some APIs may be backend specific.
Run `moon check --target all` for a complete check.
Imports only needed on some backends go in a conditional import block in `moon.pkg`,
e.g. `#cfg(any(target="native", target="wasm")) import { ... }`,
so they don't cause unused import warnings on other backends.
Import conditions only support `target`, so an import that is unused on some `platform`
(e.g. only used on Windows) still needs a `#cfg(platform=...)` item that references it to mute the warning.

## Runtime stub
C/Wasm runtime stubs for this runtime are not managed under the `moonbitlang/core` repository.
Source code for `native` backend's C runtime can be found at `include` and `lib/runtime` under the MoonBit installation directory.
There is also a public snapshot at [](https://github.com/moonbitlang/moonbit-native-runtime), but that snapshot may be out dated.
Source code for the Wasm runtime is managed in the `moonrun` crate of [the build system](https://github.com/moonbitlang/moon).
Changes involving runtime stubs cannot be performed by modifying this repository alone.
