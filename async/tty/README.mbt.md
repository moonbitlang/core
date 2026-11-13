# Terminal (`@moonbitlang/core/async/tty`)

Minimal, cross-platform access to the controlling terminal: open it, get and
set its state, query its size, read input and resizes, write bytes.

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
    match tty.read() {
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
- Read methods return `MaybeResized[T]`: `Value(value)` contains the original
  read result, while `Resized` reports a window change. Call `size()` for the
  current size. Real read failures raise `@io.ReaderError`.
- Pending resizes are retained, but consecutive resizes may be reported once.
  Buffered input may be returned before a pending resize; notification order
  need not match the order of input and window changes.
- Reads preserve input when returning `Resized` or being cancelled. In
  particular, `read_exactly` and `drop_exactly` consume input only after the
  requested length is available, so they can be retried with the same length.
- EOF remains `Value(None)` for `read`/`peek`/`read_until`/`peek_until`, and
  `Value(0)` for `read_into`. Exact/minimum-length operations raise
  `@io.UnexpectedEof` when insufficient input remains.
- `Tty` implements `@io.BinaryWriter`, but not `@io.BinaryReader`: callers
  handle resize notifications explicitly. Only one read may be in progress
  at a time; starting another one aborts the program.
- Native only. On Windows `open()` opens the console
  (`CONIN$`/`CONOUT$`). Console input is converted to the same VT byte stream
  as on Unix, and resizes are only reported in raw mode, where input is read
  as console input records. Raw mode needs VT support. Cancelling a cooked
  read is not supported yet.
