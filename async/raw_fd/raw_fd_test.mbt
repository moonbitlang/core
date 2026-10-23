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
async test "pipe as raw fd" {
  let log = []
  let (r, w) = @fd_util.pipe(
    read_end_is_async=false,
    write_end_is_async=false,
    context="pipe as raw fd",
  )
  assert_true(@event_loop.kind_of_fd(r, context="kind_of_fd") is Pipe)
  assert_true(@event_loop.kind_of_fd(w, context="kind_of_fd") is Pipe)
  @async.with_task_group <| group => {
    group.spawn_bg() <| () => {
      let r = @raw_fd.RawFd(r)
      defer r.close()
      let buf = FixedArray::make(1024, b'\x00')
      for ;; {
        let n = r.read(buf)
        guard n > 0 else { break }
        @async.sleep(50)
        let data = buf.unsafe_reinterpret_as_bytes()[:n]
        log.push("read() => \{@utf8.decode(data).escape()}")
      }
    }
    group.spawn_bg() <| () => {
      let w = @raw_fd.RawFd(w)
      defer w.close()
      for data in [b"abcd", b"1234", b"ABCD"] {
        @async.sleep(200)
        for written = 0; written < data.length(); {
          let n = w.write(data, offset=written)
          continue written + n
        }
        log.push("write(\{@utf8.decode(data).escape()})")
      }
    }
  }
  json_inspect(log, content=[
    "write(\"abcd\")", "read() => \"abcd\"", "write(\"1234\")", "read() => \"1234\"",
    "write(\"ABCD\")", "read() => \"ABCD\"",
  ])
}

///|
async test "pipe as raw fd stream" {
  let log = []
  let (r, w) = @fd_util.pipe(
    read_end_is_async=false,
    write_end_is_async=false,
    context="pipe as raw fd",
  )
  assert_true(@event_loop.kind_of_fd(r, context="kind_of_fd") is Pipe)
  assert_true(@event_loop.kind_of_fd(w, context="kind_of_fd") is Pipe)
  @async.with_task_group <| group => {
    group.spawn_bg() <| () => {
      let r = @raw_fd.RawFdStream(r)
      defer r.close()
      while r.read() is Some(data) {
        @async.sleep(50)
        log.push("read() => \{@utf8.decode(data).escape()}")
      }
    }
    group.spawn_bg() <| () => {
      let w = @raw_fd.RawFdStream(w)
      defer w.close()
      for data in [b"abcd", b"1234", b"ABCD"] {
        @async.sleep(200)
        w.write(data)
        log.push("write(\{@utf8.decode(data).escape()})")
      }
    }
  }
  json_inspect(log, content=[
    "write(\"abcd\")", "read() => \"abcd\"", "write(\"1234\")", "read() => \"1234\"",
    "write(\"ABCD\")", "read() => \"ABCD\"",
  ])
}

///|
async test "file as raw fd" {
  let truth = @fs.read_binary("LICENSE")
  let (io, _) = @event_loop.open(
    "LICENSE",
    0,
    create=0,
    append=false,
    sync=0,
    mode=0,
    context="file as raw fd test",
  )
  let fd = io.fd()
  io.detach_from_event_loop()
  let file = @raw_fd.RawFd(fd)
  defer file.close()
  assert_true(@event_loop.kind_of_fd(fd, context="kind_of_fd") is Regular)
  let buf = FixedArray::make(truth.length() + 1, b'\x00')
  let len = for n = 0; n < buf.length(); {
    let delta = file.read(buf, offset=n)
    guard delta > 0 else { break n }
    continue n + delta
  } nobreak {
    raise Failure::Failure("too many data")
  }
  assert_eq(len, truth.length())
  let raw_fd_result = buf.unsafe_reinterpret_as_bytes()[:len]
  assert_eq(truth[:], raw_fd_result)
}

///|
async test "file as raw fd stream" {
  let truth = @fs.read_binary("LICENSE")
  let (io, _) = @event_loop.open(
    "LICENSE",
    0,
    create=0,
    append=false,
    sync=0,
    mode=0,
    context="file as raw fd test",
  )
  let fd = io.fd()
  io.detach_from_event_loop()
  let file = @raw_fd.RawFdStream(fd)
  defer file.close()
  assert_true(@event_loop.kind_of_fd(fd, context="kind_of_fd") is Regular)
  let actual = file.read_all()
  assert_eq(actual.length(), truth.length())
  assert_eq(truth, actual)
}

///|
async test "socket as raw fd" {
  let log = []
  let server = @socket.UdpServer(@socket.Addr::parse("127.0.0.1:0"))
  let port = server.addr.port()
  @async.with_task_group <| group => {
    group.spawn_bg(no_wait=true) <| () => {
      defer server.close()
      let buf = FixedArray::make(1024, b'\x00')
      for ;; {
        let (n, addr) = server.recvfrom(buf)
        let buf_bytes = buf.unsafe_reinterpret_as_bytes()
        let data = buf_bytes[:n]
        @async.sleep(50)
        log.push("server received \{@utf8.decode(data).escape()}")
        server.sendto(buf_bytes, addr, len=n)
      }
    }
    let sock = @raw_fd_test_util.make_udp_socket()
    guard @fd_util.fd_is_valid(sock) else {
      @os_error.check_errno("make_udp_socket()")
    }
    let client = @raw_fd.RawFd(sock)
    defer client.close()
    assert_true(@event_loop.kind_of_fd(sock, context="kind_of_fd") is Socket)
    let server_addr = @socket.Addr::parse("127.0.0.1:\{port}")
    if @raw_fd_test_util.connect(sock, server_addr) < 0 {
      @os_error.check_errno("connect()")
    }
    let buf = FixedArray::make(1024, b'\x00')
    for data in [b"abcd", b"1234", b"ABCD"] {
      @async.sleep(200)
      guard client.write(data) == data.length() else {
        raise Failure::Failure("UDP packet not fully sent")
      }
      let n = client.read(buf)
      let data = buf.unsafe_reinterpret_as_bytes()[:n]
      @async.sleep(50)
      log.push("client received \{@utf8.decode(data).escape()}")
    }
  }
  json_inspect(log, content=[
    "server received \"abcd\"", "client received \"abcd\"", "server received \"1234\"",
    "client received \"1234\"", "server received \"ABCD\"", "client received \"ABCD\"",
  ])
}
