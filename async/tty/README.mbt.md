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
  let saved = tty.get_state()
  tty.set_state(saved.make_raw())
  defer tty.set_state(saved)
  let (rows, cols) = tty.size()
  tty.write(@utf8.encode("\{rows}x\{cols}\r\n"))
  for ;; {
    try tty.read(raise_on_resize=true) catch {
      Resized => {
        let (rows, cols) = tty.size()
        tty.write(@utf8.encode("resized to \{rows}x\{cols}\r\n"))
      }
      err => raise err
    } noraise {
      None | Some(b"q") => break
      Some(bytes) => tty.write(@utf8.encode("got \{bytes.length()} bytes\r\n"))
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
- In raw mode Ctrl-C no longer interrupts the program. It arrives as `b"\x03"`.
- `get_state`, `set_state` and `State::make_raw` work like `tcgetattr`,
  `tcsetattr` and `cfmakeraw`. A `State` is an opaque value; other modes, such
  as reading a password, are built on raw mode.
- The read methods of `Tty` take `raise_on_resize`: with `true`, a resize
  raises `Resized`, which carries no size, call `size()`. A resize that comes
  while no such read is in progress stays pending for the next one. A resize
  is never lost, but several resizes in a row may be reported once, and a
  resize may be reported after input typed later.
- The read methods are cancellation safe: when one raises `Resized` or is
  cancelled, the input read so far is kept for later reads.
- `Tty` implements `@io.BinaryReader` and `@io.BinaryWriter`. As a reader it
  never reports resizes, they stay pending. Only one read, through `Tty`'s own
  methods or `@io.BinaryReader`, may be in progress at a time; starting
  another one aborts the program, as with any other reader.
- Native only. On Windows `open()` opens the console
  (`CONIN$`/`CONOUT$`). Console input is converted to the same VT byte stream
  as on Unix, and resizes are only reported in raw mode, where input is read
  as console input records. Raw mode needs VT support. Cancelling a cooked
  read is not supported yet.
