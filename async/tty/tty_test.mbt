// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
/// `pty` and `ttyd` from `async/test_programs`: each test runs `ttyd` on its
/// own controlling terminal, created by `pty`.
let programs : @async.Lazy[(String, String)] = Lazy() <| () => {
  let pty = @test_util.build_test_program("pty")
  (pty, @test_util.build_test_program("ttyd"))
}

///|
/// A terminal created by `pty`, see `async/test_programs/pty`.
priv struct Pty(@process.Process)

///|
/// Wait for the `ok` line that `pty` reports on stderr.
async fn Pty::expect_ok(self : Pty) -> Unit {
  guard self.0.stderr.read_until(b"\n") is Some(line) else {
    fail("pty exited: \{@utf8.decode_lossy(self.0.stderr.read_all())}")
  }
  guard line is b"ok" else { fail("pty failed: \{@utf8.decode_lossy(line)}") }
}

///|
/// Wait for the program to exit and return its exit code.
async fn Pty::wait(self : Pty) -> Int32 {
  let process = self.0
  guard process.wait() is 0 else { fail("pty failed") }
  let output = @utf8.decode_lossy(process.stderr.read_all())
  guard output.strip_suffix("\n") is Some(line) &&
    line.strip_prefix("exit ") is Some(code) else {
    fail("pty failed: \{output}")
  }
  @string.parse_int(code)
}

///|
/// Type `bytes` into the terminal.
async fn Pty::write(self : Pty, bytes : Bytes) -> Unit {
  self.0.stdin.write(@utf8.encode("input \{@base64.encode(bytes)}\n"))
}

///|
/// Resize the terminal.
async fn Pty::resize(self : Pty, rows : Int32, cols : Int32) -> Unit {
  self.0.stdin.write(@utf8.encode("resize \{rows} \{cols}\n"))
  self.expect_ok()
}

///|
/// Read the terminal output available, or `None` once the terminal closes.
async fn Pty::read_some(self : Pty) -> Bytes? {
  self.0.stdout.read()
}

///|
/// Read exactly `len` bytes of terminal output.
async fn Pty::read_exactly(self : Pty, len : Int32) -> Bytes {
  self.0.stdout.read_exactly(len)
}

///|
/// A running ttyd. See `main`.
priv struct Ttyd {
  pty : Pty
  rpc : @socket.Tcp
  mut next_id : Int32
}

///|
async fn Ttyd::call(self : Ttyd, name : String, params~ : Json) -> Json {
  let id = self.next_id
  self.next_id += 1
  let request : Json = {
    "jsonrpc": "2.0",
    "id": id,
    "method": name,
    "params": params,
  }
  self.rpc.write(@utf8.encode("\{request.stringify()}\n"))
  guard self.rpc.read_until(b"\n") is Some(line) else {
    fail("ttyd closed the connection")
  }
  match @json.parse(@utf8.decode_lossy(line)) {
    { "id": Number(response_id, ..), "result": result, .. } if response_id ==
      id.to_double() => result
    response => fail("`\{name}` failed: \{response.stringify()}")
  }
}

///|
async fn Ttyd::make_raw(self : Ttyd) -> Unit {
  self.call("make_raw", params={}) |> ignore()
}

///|
/// `@tty.Tty::size` in `ttyd`.
async fn Ttyd::size(self : Ttyd) -> (Int32, Int32) {
  guard self.call("size", params={}) is [Number(rows, ..), Number(cols, ..)] else {
    fail("unexpected `size` result")
  }
  (rows.to_int(), cols.to_int())
}

///|
/// `@tty.Tty::read` in `ttyd`, or `@tty.Tty::read_into` a `max_len`-byte
/// buffer with `max_len`. Raise `Resized` for `@tty.Resized`.
///
/// With `timeout`, the read is cancelled inside `ttyd` after `timeout`
/// milliseconds and `Timeout` is raised. The timeout must not be applied
/// here with `@async.with_timeout`: cancelling the call would leave the
/// late response on the connection, to be taken by the next call.
async fn Ttyd::read(self : Ttyd, max_len? : Int32, timeout? : Int32) -> Bytes? {
  let params : Map[String, Json] = Map([])
  if max_len is Some(max_len) {
    params["max_len"] = Json(max_len)
  }
  if timeout is Some(timeout) {
    params["timeout"] = Json(timeout)
  }
  read_result("read", self.call("read", params=Json(params)))
}

///|
/// `@tty.Tty::read_exactly` in `ttyd`. Raise `Resized` for `@tty.Resized`.
async fn Ttyd::read_exactly(self : Ttyd, len : Int32) -> Bytes {
  let result = self.call("read_exactly", params={ "len": len })
  guard read_result("read_exactly", result) is Some(bytes) else {
    fail("unexpected EOF from `read_exactly`")
  }
  bytes
}

///|
fn read_result(name : String, result : Json) -> Bytes? raise {
  match result {
    { "type": "input", "bytes": String(bytes), .. } =>
      Some(@base64.decode(bytes))
    { "type": "resize", .. } => raise Resized
    { "type": "eof", .. } => None
    { "type": "timeout", .. } => raise Timeout
    _ => fail("unexpected `\{name}` result: \{result.stringify()}")
  }
}

///|
/// Raised by `Ttyd::read` when its `timeout` expires.
#derive(Debug)
priv suberror Timeout

///|
/// Raised by the reads of `Ttyd` for `@tty.Resized`.
#derive(Debug)
priv suberror Resized

///|
/// Run the read `f`, which should raise `Resized`.
async fn expect_resize(f : async () -> Unit) -> Unit {
  try f() catch {
    Resized => ()
    error => raise error
  } noraise {
    _ => fail("expect the read to raise Resized")
  }
}

///|
/// Read with `timeout`, which should expire.
async fn expect_read_to_timeout(ttyd : Ttyd, timeout~ : Int32) -> Unit {
  try ttyd.read(timeout~) catch {
    Timeout => ()
    error => raise error
  } noraise {
    bytes => fail("expect read to timeout, got: \{@debug.Repr(bytes)}")
  }
}

///|
/// `@io.Writer::write` on the `@tty.Tty` in `ttyd`.
async fn Ttyd::write(self : Ttyd, bytes : Bytes) -> Unit {
  self.call("write", params={ "bytes": @base64.encode(bytes) }) |> ignore
}

///|
async fn Ttyd::send_input(self : Ttyd, bytes : Bytes) -> Unit {
  self.pty.write(bytes)
}

///|
async fn Ttyd::resize(self : Ttyd, rows : Int32, cols : Int32) -> Unit {
  self.pty.resize(rows, cols)
}

///|
/// ConPTY emits screen initialization and cursor controls. Discard output until
/// quiet before testing whether new input echoes; do not mistake setup for echo.
async fn Ttyd::drain_output(self : Ttyd) -> Unit {
  while @async.with_timeout_opt(100, () => self.pty.read_some())
        is Some(Some(_)) {
    ()
  }
}

///|
/// ConPTY renders a screen instead of preserving the original output bytes.
/// Text may be split across reads, so accumulate until the expected text appears.
async fn Ttyd::expect_output_text(self : Ttyd, expected : String) -> Unit {
  let output = @buffer.Buffer()
  while !@utf8.decode_lossy(output.to_bytes()).contains(expected) {
    guard self.pty.read_some() is Some(bytes) else {
      fail(
        "terminal closed before displaying \{expected}: \{@utf8.decode_lossy(output.to_bytes())}",
      )
    }
    output.write_bytes(bytes)
  }
}

///|
async fn with_ttyd(f : async (Ttyd) -> Unit, exit_with~ : Int32 = 0) -> Unit {
  let (pty_path, ttyd_path) = programs.wait()
  @async.with_timeout(10000, () => {
    let server = @socket.TcpServer(@socket.Addr::parse("127.0.0.1:0"))
    defer server.close()
    // If the test fails or times out, cancelling `pty` closes the terminal,
    // which kills `ttyd`.
    @async.with_task_group(group => {
      let process = @process.spawn(
        group,
        pty_path,
        [ttyd_path],
        extra_env={ "TTYD_PORT": server.addr.port.to_string() },
        stdin=FeedFromParent,
        stdout=Collect,
        stderr=Collect,
      )
      defer process.stdin.close()
      defer process.stdout.close()
      defer process.stderr.close()
      let pty = Pty(process)
      pty.expect_ok()
      let (rpc, _) = server.accept()
      {
        defer rpc.close()
        f({ pty, rpc, next_id: 0, })
      }
      // Keep draining the output: the last close of a terminal waits for
      // unread output, such as echoed input, so ttyd could not exit otherwise.
      group.spawn_bg(no_wait=true, () => {
        while pty.read_some() is Some(_) {
          ()
        }
      })
      let exit_code = pty.wait()
      guard exit_code == exit_with else {
        fail("ttyd exited with \{exit_code}, expecting \{exit_with}")
      }
    })
  })
}

///|
async test "tty can be resized" {
  with_ttyd() <| ttyd => {
    assert_eq(ttyd.size(), (24, 80))
    ttyd.resize(25, 81)
    assert_eq(ttyd.size(), (25, 81))
  }
}

///|
async test "resize can interrupt a pending read" {
  with_ttyd() <| ttyd => {
    ttyd.make_raw()
    @async.with_task_group() <| group => {
      group.spawn_bg() <| () => { expect_resize(() => ttyd.read() |> ignore) }
      group.spawn_bg() <| () => {
        @async.sleep(100)
        ttyd.resize(25, 81)
      }
    }
  }
}

///|
async test "multiple resize events collapse into one" {
  let sizes = [(25, 81), (26, 82), (27, 83)]
  with_ttyd() <| ttyd => {
    ttyd.make_raw()
    for (rows, cols) in sizes {
      ttyd.resize(rows, cols)
    }
    // ConPTY applies resize requests asynchronously. Wait for the final size
    // before checking that the queued notifications are coalesced.
    while ttyd.size() != (27, 83) {
      @async.sleep(1)
    }
    expect_resize(() => ttyd.read() |> ignore)
    expect_read_to_timeout(ttyd, timeout=200)
  }
}

///|
async test "cooked mode respects line discipline" {
  with_ttyd() <| ttyd => {
    @async.with_task_group(group => {
      ttyd.send_input(b"hello")
      let reading = group.spawn(() => ttyd.read())
      @async.sleep(200)
      assert_true(reading.try_wait() is None)
      let (enter, line) = if @async.platform is Windows {
        (b", world!\r", b"hello, world!\r\n")
      } else {
        (b", world!\n", b"hello, world!\n")
      }
      ttyd.send_input(enter)
      assert_eq(reading.wait(), Some(line))
    })
  }
}

///|
async test "raw mode delivers input without line buffering" {
  with_ttyd() <| ttyd => {
    ttyd.make_raw()
    let text = b"\x1b[A"
    ttyd.send_input(text)
    assert_eq(ttyd.read_exactly(text.length()), text)
  }
}

///|
async test "read delivers bytes left by read_exactly first" {
  with_ttyd() <| ttyd => {
    ttyd.make_raw()
    ttyd.send_input(b"abcdef")
    assert_eq(ttyd.read_exactly(3), b"abc")
    assert_eq(ttyd.read(), Some(b"def"))
  }
}

///|
async test "read_exactly keeps partial input on resize" {
  with_ttyd() <| ttyd => {
    ttyd.make_raw()
    ttyd.send_input(b"abc")
    @async.with_task_group() <| group => {
      group.spawn_bg() <| () => {
        expect_resize(() => ttyd.read_exactly(6) |> ignore)
      }
      group.spawn_bg() <| () => {
        @async.sleep(100)
        ttyd.resize(25, 81)
      }
    }
    ttyd.send_input(b"def")
    assert_eq(ttyd.read_exactly(6), b"abcdef")
  }
}

///|
async test "resize stays pending until the next read" {
  with_ttyd() <| ttyd => {
    ttyd.make_raw()
    ttyd.resize(25, 81)
    expect_resize(() => ttyd.read() |> ignore)
    expect_read_to_timeout(ttyd, timeout=200)
  }
}

///|
async test "drop_exactly keeps partial input on resize and can be retried" {
  with_ttyd() <| ttyd => {
    ttyd.make_raw()
    ttyd.send_input(b"abc")
    @async.with_task_group() <| group => {
      group.spawn_bg() <| () => {
        json_inspect(ttyd.call("drop_exactly", params={ "len": 6 }), content={
          "type": "resize",
        })
      }
      group.spawn_bg() <| () => {
        @async.sleep(100)
        ttyd.resize(25, 81)
      }
    }
    ttyd.send_input(b"defghi")
    json_inspect(ttyd.call("drop_exactly", params={ "len": 6 }), content={
      "type": "dropped",
    })
    assert_eq(ttyd.read_exactly(3), b"ghi")
  }
}

///|
#cfg(not(platform="windows"))
async test "cooked mode handles EOF" {
  with_ttyd() <| ttyd => {
    ttyd.send_input(b"\x04")
    guard ttyd.read() is None else {
      fail("expect read to return None for \\x04 in cooked mode")
    }
  }
}

///|
async test "^C interrupt cooked mode program" {
  let sigint = match @async.platform {
    Windows => -1073741510 // STATUS_CONTROL_C_EXIT (0xC000013A)
    _ => -2 // SIGINT
  }
  with_ttyd(exit_with=sigint) <| ttyd => {
    ttyd.send_input(b"\x03")
    // Wait for `ttyd` to die. Returning right away would close the
    // connection, and `ttyd` could exit normally before `^C` reaches it.
    guard ttyd.rpc.read() is None else {
      fail("expect ttyd to be killed by Ctrl-C")
    }
  }
}

///|
async test "^C does not interrupt raw mode program" {
  with_ttyd() <| ttyd => {
    ttyd.make_raw()
    ttyd.send_input(b"\x03")
    guard ttyd.read_exactly(1) is b"\x03" else {
      fail("expected to read ^C as \\x03")
    }
  }
}

///|
async test "cooked mode echoes back" {
  with_ttyd() <| ttyd => {
    if @async.platform is Windows {
      ttyd.drain_output()
      @async.with_task_group(group => {
        let reading = group.spawn(() => ttyd.read_exactly(15))
        ttyd.send_input(b"hello, world!\r")
        ttyd.expect_output_text("hello, world!")
        assert_eq(reading.wait(), b"hello, world!\r\n")
      })
    } else {
      ttyd.send_input(b"hello, world!\n")
      assert_eq(ttyd.pty.read_exactly(15), b"hello, world!\r\n")
    }
  }
}

///|
async test "raw mode does not echo back" {
  with_ttyd() <| ttyd => {
    ttyd.make_raw()
    if @async.platform is Windows {
      ttyd.drain_output()
    }
    let text = b"hello, world!\n"
    ttyd.send_input(text)
    assert_eq(ttyd.read_exactly(text.length()), text)
    let output = @async.with_timeout_opt(200, () => ttyd.pty.read_some())
    if output is Some(output) {
      fail("raw mode echos back something: \{@debug.Repr(output)}")
    }
  }
}

///|
#cfg(not(platform="windows"))
async test "@io.Writer writes bytes as is under raw mode" {
  with_ttyd() <| ttyd => {
    ttyd.make_raw()
    let text = b"hello,\nworld!"
    ttyd.write(text)
    guard ttyd.pty.read_exactly(text.length()) == text else {
      fail("@io.Writer fails to write text as is under raw mode")
    }
  }
}

///|
async test "raw mode delivers UTF-8 input" {
  with_ttyd() <| ttyd => {
    ttyd.make_raw()
    let text = b"\xc3\xa9\xe4\xb8\xad\xf0\x9f\x98\x80"
    ttyd.send_input(text)
    assert_eq(ttyd.read_exactly(text.length()), text)
  }
}

///|
async test "raw mode delivers NUL input from Ctrl+Space" {
  with_ttyd() <| ttyd => {
    ttyd.make_raw()
    let text = b"\x00a\x00"
    ttyd.send_input(text)
    assert_eq(ttyd.read_exactly(text.length()), text)
  }
}

///|
/// On Windows, the bytes of one character that do not fit the reader's buffer
/// are kept for the next read.
async test "raw mode delivers a character across small reads" {
  with_ttyd() <| ttyd => {
    ttyd.make_raw()
    let text = b"\xf0\x9f\x98\x80"
    ttyd.send_input(text)
    for byte in text {
      assert_eq(ttyd.read(max_len=1), Some(Bytes::from_array([byte])))
    }
  }
}

///|
async test "cancelling a parked read keeps the terminal usable" {
  with_ttyd() <| ttyd => {
    ttyd.make_raw()
    for input in [b"a", b"b", b"c"] {
      expect_read_to_timeout(ttyd, timeout=100)
      ttyd.send_input(input)
      assert_eq(ttyd.read(), Some(input))
    }
  }
}

///|
/// TODO: skipped on Windows, where cancelling the cooked console read reports
/// end of input instead of a timeout. Cooked reads use the generic console
/// read, not `@tty`'s own code.
#cfg(not(platform="windows"))
async test "a cooked read can be cancelled" {
  with_ttyd() <| ttyd => {
    ttyd.send_input(b"partial")
    expect_read_to_timeout(ttyd, timeout=100)
  }
}

///|
#cfg(platform="windows")
async test "writer displays UTF-8 text through ConPTY" {
  with_ttyd() <| ttyd => {
    ttyd.make_raw()
    ttyd.drain_output()
    ttyd.write(@utf8.encode("héllo 😀"))
    ttyd.expect_output_text("héllo 😀")
  }
}

///|
#cfg(platform="windows")
async test "cooked console preserves Ctrl-Z as input" {
  with_ttyd() <| ttyd => {
    // ReadConsoleW does not apply the CRT's Ctrl-Z-to-EOF translation.
    ttyd.send_input(b"\x1a\r")
    assert_eq(ttyd.read(), Some(b"\x1a\r\n"))
  }
}

///|
async test "peek then drop consumes only the peeked prefix" {
  with_ttyd() <| ttyd => {
    ttyd.make_raw()
    ttyd.send_input(b"abcdef")
    json_inspect(ttyd.call("peek_exactly", params={ "len": 3 }), content={
      "type": "input",
      "bytes": "YWJj",
    })
    json_inspect(ttyd.call("drop_exactly", params={ "len": 3 }), content={
      "type": "dropped",
    })
    assert_eq(ttyd.read_exactly(3), b"def")
  }
}

///|
async test "read_into reports resize without opting in" {
  with_ttyd() <| ttyd => {
    ttyd.make_raw()
    ttyd.resize(25, 81)
    expect_resize(() => ttyd.read(max_len=8) |> ignore)
    ttyd.send_input(b"abc")
    assert_eq(ttyd.read(max_len=8), Some(b"abc"))
  }
}

///|
async test "read_until preserves partial input on resize" {
  with_ttyd() <| ttyd => {
    ttyd.make_raw()
    ttyd.send_input(b"abc")
    @async.with_task_group() <| group => {
      group.spawn_bg() <| () => {
        json_inspect(ttyd.call("read_until", params={}), content={
          "type": "resize",
        })
      }
      group.spawn_bg() <| () => {
        @async.sleep(100)
        ttyd.resize(25, 81)
      }
    }
    ttyd.send_input(b"def\n")
    json_inspect(ttyd.call("read_until", params={}), content={
      "type": "input",
      "bytes": "YWJjZGVm",
    })
  }
}

///|
#cfg(not(platform="windows"))
async test "exact reads raise io UnexpectedEof" {
  with_ttyd() <| ttyd => {
    ttyd.send_input(b"\x04")
    json_inspect(ttyd.call("expect_unexpected_eof", params={}), content={
      "type": "unexpected_eof",
    })
  }
}
