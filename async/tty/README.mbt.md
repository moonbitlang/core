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
    match tty.wait_event() {
      Resize => {
        let (rows, cols) = tty.size()
        tty.write(@utf8.encode("resized to \{rows}x\{cols}\r\n"))
      }
      Input =>
        match tty.read() {
          None | Some(b"q") => break
          Some(bytes) =>
            tty.write(@utf8.encode("got \{bytes.length()} bytes\r\n"))
        }
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
- One task must coordinate all waits and reads on the shared Tty.
  `wait_event()` returns `Input` when bytes or EOF are ready for the reader.
  Repeated waits preserve that input. An already observed resize takes priority
  over buffered input and returns `Resize`. Call `size()` for the current size.
- Read, peek and drop can also be called directly. They use ordinary
  `BinaryReader` results and errors, including EOF. During a read, resize
  notifications stay pending for the next wait and may be coalesced.
  Reads can still be cancelled. The reader impl is private, and Tty implements
  the public `@io.BinaryWriter` trait.
- Native only. On Windows `open()` opens the console
  (`CONIN$`/`CONOUT$`). Console input is converted to the same VT byte stream
  as on Unix, and resizes are only reported in raw mode, where input is read
  as console input records. Raw mode needs VT support. Cancelling a cooked
  read is not supported yet.

After `Input`, a VT parser can peek ahead and drop only the bytes belonging
to a completed event. Copy a peek view before another reader operation.
For example, a parser expecting a three-byte event can use:

```moonbit check
///|
/// Consume the event only after all three bytes arrive.
pub async fn read_three_bytes(tty : @tty.Tty) -> Bytes {
  let bytes = tty.peek_exactly(3).to_owned()
  tty.drop_exactly(3)
  bytes
}
```

`Input` can represent a single byte. Requests for a longer sequence may
still suspend, so apply any Escape/sequence timeout to the parser and any
first-input timeout to `wait_event()`. A resize arriving mid-sequence is
reported on a subsequent wait. On Windows, a resize becomes pending when
its console input record is observed.
