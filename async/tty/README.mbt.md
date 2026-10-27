# Terminal (`@moonbitlang/core/async/tty`)

Minimal, cross-platform access to the controlling terminal: open it, enter and
leave raw mode, query its size, wait for input or resize, write bytes.

Input is delivered as the raw VT byte stream the terminal sends. The package
does no key decoding, no escape-sequence parsing and no screen management;
those belong to libraries built on top of it.

```moonbit nocheck
///|
async fn run() -> Unit {
  let tty = @tty.open()
  tty.enter_raw_mode()
  defer tty.leave_raw_mode()
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
  loop exits, raw mode is left and the `Tty` is closed, like a closed file:
  later calls fail with `EBADF`. There is no `close`.
- In raw mode Ctrl-C no longer interrupts the program. It arrives as `Input(b"\x03")`.
- `Resize` carries no size, call `size()`. A resize is never lost, but
  several resizes in a row may be reported as one event, and a resize may be
  reported after input typed later.
- `Tty` implements `@io.BinaryReader` and `@io.BinaryWriter`. Only one read, through
  `read_event` or the reader methods, may be in progress at a time;
  starting another one aborts the program, as with any other reader.
- Native, and wasm on a Unix host through moonrun. On Windows `open()` opens
  the console (`CONIN$`/`CONOUT$`). Console input is converted to the same VT
  byte stream as on Unix, and `Resize` is only reported in raw mode. Raw mode
  needs VT support, so it fails on the legacy console (conhost v1).
