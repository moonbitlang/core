# Terminal (`@moonbitlang/core/async/tty`)

Minimal, cross-platform access to the controlling terminal: open it, get and
set its state, query its size, wait for input or resize, write bytes.

Input is delivered as the raw VT byte stream the terminal sends. The package
does no key decoding, no escape-sequence parsing and no screen management;
those belong to libraries built on top of it.

```moonbit check
///|
/// Print the terminal size, then report input and resizes until `q` is pressed
pub async fn run() -> Unit {
  let tty = @tty.open()
  let saved = tty.get_state()
  tty.set_state(saved.make_raw())
  defer tty.set_state(saved)
  let (rows, cols) = tty.size()
  tty.write(@utf8.encode("\{rows}x\{cols}\r\n"))
  while tty.read_event() is Some(event) {
    match event {
      Input(b"q") => break
      Input(bytes) => tty.write(@utf8.encode("got \{bytes.length()} bytes\r\n"))
      Resize => {
        let (rows, cols) = tty.size()
        tty.write(@utf8.encode("resized to \{rows}x\{cols}\r\n"))
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
- The state is not restored when the loop exits. Restore it with `defer`, as
  in the example above, which also runs on errors and cancellation.
- In raw mode Ctrl-C no longer interrupts the program. It arrives as `Input(b"\x03")`.
- `get_state`, `set_state` and `State::make_raw` work like `tcgetattr`,
  `tcsetattr` and `cfmakeraw`. A `State` is an opaque value; other modes, such
  as reading a password, are built on raw mode.
- `Resize` carries no size, call `size()`. A resize is never lost, but
  several resizes in a row may be reported as one event, and a resize may be
  reported after input typed later.
- `Tty` implements `@io.BinaryReader` and `@io.BinaryWriter`. Only one read, through
  `read_event` or the reader methods, may be in progress at a time;
  starting another one aborts the program, as with any other reader.
- Native only. On Windows `open()` opens the console
  (`CONIN$`/`CONOUT$`). Console input is converted to the same VT byte stream
  as on Unix, and `Resize` is only reported in raw mode, where input is read
  as console input records. Raw mode needs VT support.
