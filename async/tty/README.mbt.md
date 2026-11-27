# Terminal (`@moonbitlang/core/async/tty`)

Use `@tty` on native targets to read and write the controlling terminal's VT
byte stream and handle window resizes. On Windows, resize events require raw
mode and cooked reads do not support cancellation.

Calls to `open()` in the same event loop share one `Tty`. On exit, the event
loop automatically restores the terminal state saved by the first `open()`
(including raw mode and echo) before closing the terminal. The example uses
`defer tty.leave_raw_mode()` to restore that state as soon as `run` returns.

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
    match tty.wait_resize() {
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

One task must coordinate all waits and reads on the shared terminal.
`wait_resize()` returns `Input` when bytes or EOF are ready. The available bytes
may contain only the beginning of a VT sequence. A resize already observed by
the event loop takes priority over buffered input. Direct reads, peeks and
drops defer resize notifications until the next `wait_resize()`.
