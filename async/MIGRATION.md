# Migrating from `moonbitlang/async` to `moonbitlang/core/async`

This is a package-by-package summary of the public API differences between `moonbitlang/async` and `moonbitlang/core/async`.
All packages moved from `moonbitlang/async[/<package>]` to `moonbitlang/core/async[/<package>]`,
so the user should first update package imports accordingly before migrating to `moonbitlang/core/async`.
This document covers all breaking changes in non-deprecated API,
but some new features and removal of deprecated API may not be listed here.

## Root package (`async`)

- `all` and `any` rename `max_concurrent` to `max_concurrency`.
- `TaskGroup[X]` is now non-generic. `with_task_group` takes
  `async (TaskGroup) -> Unit` and returns `Unit`; `return_immediately` no longer
  takes a result.
- the `@async.CondVar` alias is renamed to `@async.Cond`
- `Timer` is now an abstract type; its `duration` field is no longer public.

## `types`
- file descriptors are now represented as an abstract type,
  All file descriptor related API are affected.
  The ABI of `@types.Fd` is still guaranteed to be the same as OS file handle
  (i.e. `Int32` on Unix and an opaque pointer on Windows).
- `Platform` is now non-exhaustive.

## `aqueue`

- `Queue.kind` is no longer public; `Queue` is now abstract.

## `io`

- The `@io.Reader` trait is now split into three traits:
  - `@io.BinaryReader` exposes binary IO methods for end users.
    All methods in `@io.BinaryReader` have a default implementation.
    Implementors are recommended to lift `@io.BinaryReader` API into actual methods via `extend`
  - the `@io.BinaryReaderImpl` trait contains methods that an implementator should provide
    in order to implement `@io.BinaryReader`. This trait is required by `@io.BinaryReader`
  - `@io.TextReader` contains text IO methods for end users.
    It is now completely independent of `@io.BinaryReader`

  Similarly, `@io.Writer` is split into `@io.BinaryWriter`/`@io.BinaryWriterImpl`/`@io.TextWriter`.

  For implementators, the recommended API shape is:
  - implement `@io.BinaryReaderImpl`/`@io.BinaryWriterImpl` privately
  - implement `@io.BinaryReader`/`@io.BinaryWriter` (no need to actually implement any method,
    just add a `impl` declaration without `with fn`),
    and use `extend` to lift all API into methods
  - Do not implement `@io.TextReader`/`@io.TextWriter` for the reader/writer object directly.
    For types where text IO is common, optionally provide a `.text` field,
    which is a `@io.Utf8Reader`/`@io.Utf8Writer`/`@io.Utf8TextView` (bidirectional) wrapper
    over the binary reader/writer object

  All implementators in `moonbitlang/core/async` follow this pattern.

- compared to `@io.Reader`, `@io.BinaryReader`:
  - renames `read` to `read_into`. `read_into` accepts `MutArrayView[Byte]` instead of
    separated buffer/offset/length
  - renames `read_some` to `read`
  - split `drop` into `drop_exactly` and `drop_all`
  - adds a new method `read_at_least`
  - `read_all()` now return `Bytes` directly (the text version of `read_all` is available in `@io.TextReader`)
  - `read_until` now performs binary IO (the text version of `read_until` is available in `@io.TextReader`)
  - adds new methods `peek`, `peek_at_least`, `peek_exactly` and `peek_until`.
    These methods have the same semantic as the corresponding `read` variant,
    except that they do not consume data from the reader
- compared to `@io.Reader`, `@io.BinaryReaderImpl`:
  - requires a new method `name()`, which return the name of the reader for error reporting
  - replaces `_get_internal_buffer()` with `get_controller()`,
    whose return type is an abstract type `@io.BinaryReaderController`,
    which can be created via `@io.BinaryReaderController()`
  - renames `_direct_read` to `raw_read_impl`
- compared to the text part of `@io.Reader`, `@io.TextReader`:
  - adds a new method `read(Self) -> String?`
  - `read_all()` in `@io.TextReader` now returns `String` directly
  - adds a new method `read_line`, which read the next line from the reader
  - adds a new method `read_lines`, which read all remaining input from the reader into an array of lines
- all API in `@io.BinaryReader`/`@io.TextReader` now raises `@io.ReaderError` exclusively, which contains:
  - `UnexpectedEof`, replacing old `ReaderClosed`
  - `LengthLimitExceeded` when requested input is too large (e.g. overflows maximal length of `Bytes`)
  - `MalformedText` when the text reader sees invalid input
  - `TransportError(err, context~)`, which is used to wrap all error raised by the underlying
    `@io.BinaryReaderImpl` implementation.
    `err` is the actual error and `context` is the name of the reader.

  Thanks to the `TransportError` wrapper, `UnexpectedEof` can now be used to reliably
  detect early EOF in `read_exactly` etc.

  `@io.ReaderError` is marked as `#non_exhaustive`, so new variants may be added in the future.
- compared to `io.Writer`, `@io.BinaryWriter`:
  - only allows `BytesView` as argument of `write` (the text version is moved to `@io.TextWriter`,
    the JSON version is available via `write_json` is `@io.TextWriter`)
  - add a new method `flush_partial_data`, which flush all buffered partial data immediately.
    For a stacked writer (e.g. gzip over TCP), every writer in the stack will be flushed.
    Note that `flush_partial_data` only flushes data buffered by MoonBit.
    It does not, for example, flush content to physical storage for a file writer.
    `flush_partial_data` is best-effort only and does not provdie any hard guarantee
- compared to `io.Writer`, `@io.BinaryWriterImpl`:
  - requires a new method `name()`, which return the name of the reader for error reporting
  - requires a new method `get_controller()`,
    whose return type is an abstract type `@io.BinaryWriterController`,
    which can be created via `@io.BinaryWriterController()`
  - renames `write_once` to `raw_write_impl`
  - requires a new method `flush_partial_data`, see `flush_partial_data` in `@io.BinaryWriter` above
- compared to the text part of `io.Writer`, `@io.TextWriter`:
  - allows only `StringView` as argument of `write`
  - adds a new method `write_json` for writing JSON
  - adds new methods `write_string` and `write_string_interpolation` (with default implementation),
    so that every text writer can use MoonBit's `obj <+ "string template .."` syntax
- all API in `@io.BinaryWriter`/`@io.TextWriter` except `write_reader` now raises `@io.WriterError` exclusively.
  Currently `@io.WriterError` only contains `TransportError`,
  similar to `TransportError` in `@io.ReaderError` above.
  `write_reader` may raise `@io.WriterError` or forward `@io.ReaderError` from the reader.

  `@io.WriterError` is marked as `#non_exhaustive`, so new variants may be added in the future.
- `pipe`, `PipeRead`, and `PipeWrite` become `memory_pipe`, `MemoryPipeRead`,
  and `MemoryPipeWrite`.
- `Utf8Reader`, `Utf8Writer`, and `Utf8TextView` provide text adapters.
- The `@io.Data` trait is removed. Methods accepting or returning `&@io.Data`
  are replaced by separated methods for different input formats.
  See the change in `@io.Reader`/`@io.Writer` above.
- `Encoding` and `ReaderBuffer` are removed.

## `fs`

- `atime`, `ctime`, and `mtime` now return `Timestamp` instead of `(Int64, Int32)`.
  `Timestamp` is an abstract type with `.sec()`, `.msec()`, `.subsec_nanos()` methods.
  `Timestamp` also provides subtraction, comparison, equality, and hashing.
- `read_file` is replaced by `read_binary`, `read_text` and  `read_lines`
- `write_file` is replaced by `write_binary`, and `write_text`.
  The default create mode is now `OpenOrCreate` if `append=true`,
  or `CreateOrTruncate` if `append=false`
- `remove` now has `recursive` and `allow_missing` options and can remove both directories and files now,
  `rmdir` become a deprecated alias of `remove`.
  `Directory::remove` receives a similar change.
- `mkdir` renames `allow_exist` to `allow_existing`.
- `File` now exposes a `.text` field for text IO
- Positional `read_at`/`write_at` are replaced by `File::at(position) -> FileView`,
  where `FileView` implements `@io.BinaryReader` and `@io.BinaryWriter`.
  Reading/writing a `FileView` is independent of IO on the original file and any other `FileView`.
  `FileView` is borrowed: closing the original file invalidates all views.
- `FileKind` is now marked as non-exhaustive, and has a new `Console` variant.

## `http`

- All non-streaming toplevel helpers in `@http`, such as `@http.get`,
  now return `(ResponseHeader, MessageBody)`,
  where `MessageBody` is an abstract type with `.binary()`, `.text()` and `.json()` accessors,
  similar to `&@io.Data` in `moonbitlang/async`.
- `@http.get` no longer accepts a request body
- `@http.put`/`@http.post`/`@http.request` are split into separated `_binary`/`_text`/`_json` variants.
  These variants only differ in request body format,
  response body is still represented as `MessageBody` and is decoded lazily.
- All streaming toplevel helpers now uniformly uses `_stream` suffix
- `Request` and `Response` become `RequestHeader` and `ResponseHeader`.
  `RequestMethod` adds `Extension(String)` for extension methods.
  `RequestHeader` and `ResponseHeader` are now read-only
- `Client` is now a reusable high-level client created from default headers.
  The old per-connection streaming API moves to `ClientConnection`, which
  implements `BinaryReader`/`BinaryWriter` and supports text IO via `.text`.
- Proxy arguments now use the new `Proxy` type rather than `Client`.
  `@http.Proxy(url, ..)` creates a simple proxy configuration with proxy server `url`,
  and has optional username/password parameters for basic authentication.
  Arbitrary custom proxy configuration can be created via `Proxy::custom_tunnel(..)`.
- `Server::accept` returns only `ServerConnection`, Obtain addresses through
  `Server::local_addr` and `ServerConnection::remote_addr`.
- The callback of `Server::run_forever` now receives `(RequestHeader, ServerConnection)`.
  Request body should be read from the `ServerConnection` directly.
- `InvalidMethod` and `IncorrectBodyLength` are merged into an abstract error type `InvalidMessage`.
- `HttpProtocolError` is renamed to `ProtocolError` and marked as `#non_exhaustive`
- `URIParseError` is renamed to `UriParseError` and become abstract
- The stale `Protocol` type is removed

## `socket`

- Add a new `IpAddr` enum represents IPv4 and IPv6 addresses without port.
  `IpAddr` can be constructed via `IpAddr(repr)` where `repr` is a string representation of the address.
  IPv6 address may or may not be wrapped in brackets in `IpAddr(..)`.
- `Addr` is now `pub struct { ip : IpAddr, port : UInt16 }` instead of an abstract type.
  `Addr` no longer has the same ABI as underlying address type of the OS.
  `Addr` can be created via `Addr(ip, port)`, in addition to existing `parse()` and `resolve()`.
- All port values' type change from `Int32` to `UInt16`
- `.addr` field of `Tcp`/`TcpServer`/`UdpClient`/`UdpServer` are replaced by a `.local_addr()` method,
  and all these types become abstract.
- `Tcp` now has a new `.remote_addr()` method.
  The return value of `TcpServer::accept` and parameters of the callback of `TcpServer::run_forever`
  no longer has an extra address value: use `.remote_addr()` to retrieve it instead.
- changes in `UdpClient` methods:
  - `recv()` => `recv_into()`. `recv_into()` accepts `MutArrayView[Byte]` instead of
    separated buffer/offset/length
  - add a new `recv()` method, which returns a `Bytes` for received packet directly
  - `recvfrom()` => `recv_into_with_addr()`. `recv_into_with_addr()` similarly accepts `MutArrayView`
  - add a new `recv_with_addr()` method, same as the new `recv()`,
    but additionally returns source address of the incoming packet
  - `send()` now receives `BytesView` instead of separated buffer/offset/length as input
- changes in `UdpServer` methods:
  - `recvfrom()` => `recv_into()`. `recv_into()` accepts `MutArrayView[Byte]` instead of
    separated buffer/offset/length
  - add a new `recv()` method, which returns a `Bytes` for received packet directly
    together with source address of the packet
  - `sendto()` => `send()`, and `send()` now receives `BytesView` instead of separated buffer/offset/length as input
- Multicast related APIs now use `IpAddr` instead of `Addr` for multicast group and IPv4 interface.
- `ResolveHostnameError` is now an abstract error type.

## `os_error`

- `OSError(code, context~)` is replaced by opaque `OsError(kind, raw_code~, context~)`,
  `kind` is a cross-platform view for common error kinds of type `@os_error.Kind`,
  and `raw_code` is the platform-specific raw error code.
  The value and meaning of `context` remains.
- `is_*` methods on `OSError` are removed in favor of matching the error kind directly.
  File an issue if you find that some useful error codes are absent from `@os_error.Kind`
- several error number related helpers for internal use are removed from the public interface

## `process`

- all redirection API (`stdin=`, `stdout=` and `stderr=`) now accepts
  a new `ProcessInput`/`ProcessOutput` enum instead of a trait object.
  `ProcessInput`/`ProcessOutput` contains the following variants:
  - `Collect` can be used to collect output of the child process via a temporary pipe.
    The parent side of the pipe is available via `.stdout` or `.stderr` of `Process`.
    `Collect` covers use case of previous `@process.read_from_process(shared=false)`
  - `FeedFromParent` can be used to supply input to the child process via a temporary pipe.
    The parent side of the pipe is available via `.stdin` of `Process`.
    `FeedFromParent` covers use case of previous `@process.write_to_process()`
  - `Inherit` (usually the default value): inherit the corresponding channel from the context.
    Usually this means the same stdio channel from the parent,
    but when using `@process.Cmd`, `Inherit` has richer semantic.
    See `@process.Cmd` for more details.
  - `Stdin`/`Stdout`/`Stderr` replaces passing `@stdio.stdin`/`@stdio.stdout`/`@stdio.stderr` directly
  - `ToFile`/`AppendFile` can be used to redirect output of a child process to a file.
    It replaces previous `@process.redirect_to_file(shared=false)`
    with `create_mode=CreateOrTruncate, append=false` or `create_mode=OpenOrCreate, append=true`
    and no other special configuration.
  - `FromFile` can be used to redirect input of a child process from a file.
    It replaces previous `@process.redirect_from_file()`
  - `Empty`: redirect child process' stdin to empty input (i.e. immediate EOF)
  - `Discard`: discard output of the child process
  - `DuplicateStdout`: only available when redirecting `stderr` of a child process,
    make the `stderr` channel of the child the same as its final `stdout` channel
  - `Shared(_)` can be used to redirect process input/output to a
    shared `SharedProcessInput` or `SharedProcessOutput` channel.
    `SharedProcessInput` or `SharedProcessOutput` objects can be share between multiple children.
    They can be created via the following functions:
    - `@process.read_from_process()`: replaces previous `@process.read_from_process(shared=true)`
    - `@process.write_to_process()`
    - `@process.redirect_to_file()`: replaces previous `@process.redirect_to_file(shared=true)`.
      The default create mode is now `OpenOrCreate` if `append=true`,
      or `CreateOrTruncate` if `append=false`
    - `@process.redirect_from_file()`
    - `@process.pipe_between_process()`, replaces previous `@process.pipe()`

    Notice that `SharedProcessInput`/`SharedProcessOutput` channels must be closed manually,
    and should be closed after being passed to the last child process.

- `run` and `spawn` now receives an optional `accepted_exit_code` predicate.
  If the process fail with an exit code where `accepted_exit_code` returns `false`,
  the API will fail with `CommandFailed`, which contains information about the failing child process.

  For `spawn`, if the child process is cancelled:
  - the task group will not fail even if the exit code is not acceptable
  - `.wait()` on the returned `Process` will fail if the exit code is not acceptable,
    even if the child process is cancelled

- `Process` now has three additional fields `.stdin`/`.stdout`/`.stderr`.
  When the corresponding channel is redirected to `FeedFromParent` or `Collect` in `spawn`,
  `.stdin`/`.stdout`/`.stderr` contains the parent end of the created temporary pipe,
  must be manually closed, and can be used to streamingly read from/write to the child process.
  When the corresponding channel is not redirected to `FeedFromParent` or `Collect`,
  the corresponding field must not be used.
- `run` now returns `struct ProcessResult` instead of a plain exit code.
  The exit code is available through `.exit_code` in `ProcessResult`.
  When `run` receives `stdout=Collect` or `stderr=Collect`,
  it collects the corresponding channel's content automatically.
  The result is available through `.stdout_binary()`/`.stdout_text()`/`.stderr_binary()`/`.stderr_text()`
  on `ProcessResult`. These methods panic if `stdout`/`stderr` is not redirected to `Collect`.
- `@process.collect_*` helpers are now removed because their usage can now be covered by `run`:
  - `@process.collect_stdout()` => `@process.run(stdout=Collect)`
  - `@process.collect_stderr()` => `@process.run(stderr=Collect)`
  - `@process.collect_output()` => `@process.run(stdout=Collect, stderr=Collect)`
  - `@process.collect_output_merged()` => `@process.run(stdout=Collect, stderr=DuplicateStdout)`
- `spawn_orphan` returns `struct OrphanProcess` instead of a PID.
  The PID is available via `.pid` on `OrphanProcess`.
  `OrphanProcess` also provides `.stdin`/`.stdout`/`.stderr`,
  whose semantic is the same as `struct Process` for `spawn`.
  `OrphanProcess` must be closed manually
- add a new `Cmd` type for shell-like reusable, composable commands.
  `Cmd(..)` creates a single-process command,
  `Cmd::sequence(..)` creates a composite command that execute each child command in order.
  `cmd1 | cmd2` or `Cmd::pipe(cmd1, cmd2)` creates a composite command that
  pipes the `stdout` of the first command to the `stdin` of the second command.
  There is also `cmd.with_context(stdin?, stdout?, stderr?, cwd?)`,
  which overides stdio channel or working directory locally for a (potentially composite) sub command.

  `Cmd` can be executed via `.run()` or `.spawn()`.
  The semantic is similar to `@process.run()`/`@process.spawn()`.
  The same `Cmd` object can be executed multiple times.
  See the document for more semantic details.
- `ReadFromProcess` and `WriteToProcess` adopt `BinaryReader`/`BinaryWriter`
  and provides text IO via a builtin `.text` field
- `CancellationHandler` is now opaque.

## `raw_fd`

- `RawFd::read`/`write` become `read_into_once`/`write_once`.
  `read_into_once()` accepts `MutArrayView[Byte]` instead of separated buffer/offset/length

## `semaphore`

- `Semaphore.size` is no longer public; `Semaphore` is opaque.

## `shell`

- The entire package is deprecated. New code can use `process.Cmd` and its pipeline API.

## `signal`

- `Signal` is now non-exhaustive.

## `tls`

- test-only TLS server API is now removed completely instead of marked `#internal`
- TLS client now requires TLS shutdown by default.
  If the server closes the underlying transport without performing TLS shutdown,
  the client will fail with error.
  Pass `require_shutdown=false` on client creation if shutdown is explicitly not required.
- `@tls.TlsError` become an abstract error type
- `@tls.ConnectionClosed` is removed. The TLS connection will raise something else on unexpected EOF.
  This error is fatal for the TLS layer and should not be handled by user anyway.

## `websocket`

- `Conn` implements `BinaryWriter`, and provides text IO via a builtin `.text` field
- `Message` implements `BinaryReader`, and provides text IO via a builtin `.text` field

## `gzip`

- The package is removed.
  `Decoder` and `Encoder` are moved to `moonbitlang/core/compress/gzip`,
  and renamed to `StreamDecoder`/`StreamEncoder`.
  The encoder no longer allows custom timestamp/operating system values,
  but has configurable compression level now.

## `pipe`

- The package is removed. Use `io.memory_pipe` for an in-memory pipe or
  `process.pipe_between_process` for process plumbing.
