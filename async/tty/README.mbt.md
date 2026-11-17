# Terminal (`@moonbitlang/core/async/tty`)

Minimal, cross-platform access to the controlling terminal: open it, enter and
leave raw mode, query its size, read input and resizes, write bytes.

Input is delivered as the raw VT byte stream the terminal sends. The package
does no key decoding, no escape-sequence parsing and no screen management;
those belong to libraries built on top of it.

```moonbit check
///|
/// Print the terminal size, then report input and resizes until `q` is pressed
pub async fn run() -> Unit {
  let tty = @tty.open()
  tty.enter_raw_mode()
  defer tty.leave_raw_mode()
  let (rows, cols) = tty.size()
  tty.write(@utf8.encode("\{rows}x\{cols}\r\n"))
  for ;; {
    match tty.handle_resize(() => tty.read()) {
      Resized => {
        let (rows, cols) = tty.size()
        tty.write(@utf8.encode("resized to \{rows}x\{cols}\r\n"))
      }
      Value(None) | Value(Some(b"q")) => break
      Value(Some(bytes)) =>
        tty.write(@utf8.encode("got \{bytes.length()} bytes\r\n"))
    }
  }
}
```

Notes:

- `open()` returns one `Tty` per event loop: the first call in a loop opens
  the terminal, later calls in the same loop return the same `Tty`. When the
  loop exits, the `Tty` is closed, like a closed file: later calls fail with
  `EBADF`. There is no `close`.
- The first `open()` saves the terminal state. Event loop cleanup attempts to
  restore it before closing the terminal, including when async work fails or
  is cancelled. Restoration errors propagate to event loop cleanup; terminal
  handles are still closed. Forced process termination can bypass cleanup.
- `enter_raw_mode()` applies raw mode derived from that saved state;
  `leave_raw_mode()` restores the saved state, which may itself already be raw.
  Both are idempotent and may raise OS errors. Calls do not nest: one leave
  restores the state regardless of how many times enter was called. The
  application should coordinate mode changes across users of the shared Tty.
- Use `defer tty.leave_raw_mode()` to restore when a scope exits before the
  event loop finishes. Reopening the Tty does not replace the saved state.
- In raw mode Ctrl-C no longer interrupts the program. It arrives as `b"\x03"`.
- Use Tty's read, peek, and drop methods inside a `handle_resize`
  callback. These methods return ordinary `@io.BinaryReader` results and raise
  `@io.ReaderError`. Tty's `@io.BinaryReader` implementation is private;
  writing uses its public `@io.BinaryWriter` implementation.
- `handle_resize` returns `MaybeResized[T]`: `Value(value)` contains the
  callback result, while `Resized` reports a window change without calling the
  callback. Call `size()` for the current size. Callback errors propagate
  unchanged.
- Pending resizes are retained and may be coalesced. Already observed resizes
  are delivered at scope entry before buffered input. After input is ready,
  the callback finishes before a resize is delivered by a later scope.
- Inside the callback, EOF follows normal `BinaryReader` semantics: `None`
  for `read`/`peek`/`read_until`/`peek_until`, `0` for `read_into`, and
  `@io.UnexpectedEof` for unsatisfied exact/minimum-length requests.
- Native only. On Windows `open()` opens the console
  (`CONIN$`/`CONOUT$`). Console input is converted to the same VT byte stream
  as on Unix, and resizes are only reported in raw mode, where input is read
  as console input records. Raw mode needs VT support. Cancelling a cooked
  read is not supported yet.

For parsing one input event, `handle_resize` first waits for input, EOF,
or a resize without consuming bytes. A resize already observed by the event
loop takes priority over buffered input and returns `Resized` without calling
the callback. Once input or EOF is ready, the callback reads directly from the
Tty. Resizes during the callback stay pending until the next scope; the callback
completes with `Value(result)` or propagates its error. The protection delays
resize delivery only; ordinary task cancellation still applies.

For example, a fixed-length parser can peek and then commit its consumption:

```moonbit check
///|
/// Read a three-byte event without consuming an incomplete prefix.
pub async fn read_three_bytes(tty : @tty.Tty) -> @tty.MaybeResized[Bytes] {
  tty.handle_resize() <| () => {
    let bytes = tty.peek_exactly(3).to_owned()
    tty.drop_exactly(3)
    bytes
  }
}
```

A VT parser can keep a byte offset, peek enough bytes to inspect the next one,
and drop only the bytes belonging to the completed event. Extra lookahead stays
in the terminal buffer for the next scope. Copy returned payloads before the
drop; a peek view must not be reused after another reader operation.

- Keep each scope short, normally one low-level input event. A callback that
  loops forever or waits indefinitely for a sequence also defers resize forever.
- Put a timeout for the first input around `handle_resize`; put
  Escape/sequence timeouts inside the callback. EOF is available to the
  callback as ordinary reader EOF, not as a resize.
- Errors and cancellation release the scope but do not undo successful reads.
  Peek-then-drop avoids consuming an incomplete event before it is recognized.
- Nested or concurrent `handle_resize` calls abort, as do overlapping
  reads and accessing terminal input or its buffer outside a protection scope.
  Writing and querying terminal size remain available.
- Coordinate all input through the protection callback. Other tasks holding
  the same Tty must not read it while the callback is running; the scope check
  does not distinguish which task is calling a read method. Any tasks started
  by the callback that read the Tty must finish before the callback returns.
- Resize notifications can be coalesced. On Windows, a resize must first be
  observed while reading console input records to become pending; scope entry
  does not poll the console for notifications that have not yet been read.
