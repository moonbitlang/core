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
async test "one way" {
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    let (client_read_from_server, server_write_to_client) = @pipe.pipe()
    let (server_read_from_client, client_write_to_server) = @pipe.pipe()
    // server
    root.spawn_bg() <| () => {
      defer {
        server_read_from_client.close()
        server_write_to_client.close()
      }
      let server = test_server(server_read_from_client, server_write_to_client)
      defer server.close()
      while server.read() is Some(data) {
        let data = @utf8.decode(data)
        log <+ "server received: \{data}\n"
      } nobreak {
        server.shutdown()
      }
    }
    // client
    root.spawn_bg() <| () => {
      defer {
        client_read_from_server.close()
        client_write_to_server.close()
      }
      let client = Tls::client_from_pair(
        client_read_from_server,
        client_write_to_server,
        trust=NoVerification,
      )
      defer client.close()
      client.write(b"abcd")
      @async.sleep(50)
      client.write(b"efgh")
      @async.sleep(50)
      client.write(b"ijkl")
      client.shutdown()
      inspect(@utf8.decode(client.read_all()), content="")
    }
  }
  inspect(
    log.to_string(),
    content=(
      #|server received: abcd
      #|server received: efgh
      #|server received: ijkl
      #|
    ),
  )
}

///|
async test "echo" {
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    let (client_read_from_server, server_write_to_client) = @pipe.pipe()
    let (server_read_from_client, client_write_to_server) = @pipe.pipe()
    // server
    root.spawn_bg() <| () => {
      defer {
        server_read_from_client.close()
        server_write_to_client.close()
      }
      let server = test_server(server_read_from_client, server_write_to_client)
      defer server.close()
      while server.read() is Some(data) {
        log <+ "server received: \{@utf8.decode(data)}\n"
        server.write(data)
      } nobreak {
        server.shutdown()
      }
    }
    // client
    root.spawn_bg() <| () => {
      defer {
        client_read_from_server.close()
        client_write_to_server.close()
      }
      let client = Tls::client_from_pair(
        client_read_from_server,
        client_write_to_server,
        trust=NoVerification,
      )
      defer client.close()
      for data in [b"abcd", b"efgh", b"ijkl"] {
        client.write(data)
        @test.assert_eq(client.read_exactly(4), data)
        @async.sleep(50)
      }
      client.shutdown()
      inspect(@utf8.decode(client.read_all()), content="")
    }
  }
  inspect(
    log.to_string(),
    content=(
      #|server received: abcd
      #|server received: efgh
      #|server received: ijkl
      #|
    ),
  )
}

///|
async test "`connect` accidental close" {
  @async.with_task_group() <| root => {
    let (client_read_from_server, server_write_to_client) = @pipe.pipe()
    let (server_read_from_client, client_write_to_server) = @pipe.pipe()
    // server
    root.spawn_bg() <| () => {
      defer {
        server_read_from_client.close()
        server_write_to_client.close()
      }
      let _ = server_read_from_client.read()
      @async.sleep(100)
    }
    // client
    root.spawn_bg() <| () => {
      defer {
        client_read_from_server.close()
        client_write_to_server.close()
      }
      @debug.debug_inspect(
        @test.expect_error_async <| () => {
          Tls::client_from_pair(
            client_read_from_server,
            client_write_to_server,
            trust=NoVerification,
          )
        },
        content="ConnectionClosed",
      )
    }
  }
}

///|
async test "`read` already closed require_shutdown=false" {
  @async.with_task_group() <| root => {
    let (client_read_from_server, server_write_to_client) = @pipe.pipe()
    let (server_read_from_client, client_write_to_server) = @pipe.pipe()
    // server
    root.spawn_bg() <| () => {
      defer {
        server_read_from_client.close()
        server_write_to_client.close()
      }
      let server = test_server(server_read_from_client, server_write_to_client)
      server.close()
    }
    // client
    root.spawn_bg() <| () => {
      defer {
        client_read_from_server.close()
        client_write_to_server.close()
      }
      let client = Tls::client_from_pair(
        client_read_from_server,
        client_write_to_server,
        require_shutdown=false,
        trust=NoVerification,
      )
      defer client.close()
      @debug.debug_inspect(client.read(), content="None")
    }
  }
}

///|
async test "`read` already closed require_shutdown=true" {
  @async.with_task_group() <| root => {
    let (client_read_from_server, server_write_to_client) = @pipe.pipe()
    let (server_read_from_client, client_write_to_server) = @pipe.pipe()
    // server
    root.spawn_bg() <| () => {
      defer {
        server_read_from_client.close()
        server_write_to_client.close()
      }
      let server = test_server(server_read_from_client, server_write_to_client)
      server.close()
    }
    // client
    root.spawn_bg() <| () => {
      defer {
        client_read_from_server.close()
        client_write_to_server.close()
      }
      let client = Tls::client_from_pair(
        client_read_from_server,
        client_write_to_server,
        trust=NoVerification,
      )
      defer client.close()
      @debug.debug_inspect(
        @test.expect_error_async(() => client.read()),
        content=(
          #|TransportError(UnexpectedEof, context="@tls.Tls")
        ),
      )
    }
  }
}

///|
async test "client custom root certificate" {
  @async.with_task_group() <| root => {
    let (client_read_from_server, server_write_to_client) = @pipe.pipe()
    let (server_read_from_client, client_write_to_server) = @pipe.pipe()
    root.spawn_bg() <| () => {
      defer {
        server_read_from_client.close()
        server_write_to_client.close()
      }
      let server = custom_root_test_server(
        server_read_from_client, server_write_to_client, "async/tls/test_keys/valid_root_key.pem",
        "async/tls/test_keys/valid_root_cert.pem", "async/tls/test_keys/valid_root_cert.pfx",
      )
      defer server.close()
      @test.assert_eq(server.read_exactly(2), b"ok")
      server.shutdown()
    }
    root.spawn_bg() <| () => {
      defer {
        client_read_from_server.close()
        client_write_to_server.close()
      }
      let client = Tls::client_from_pair(
        client_read_from_server,
        client_write_to_server,
        host="whatever",
        trust=CustomPemFile("async/tls/test_keys/valid_root_cert.pem"),
      )
      defer client.close()
      client.write(b"ok")
      client.shutdown()
      inspect(@utf8.decode(client.read_all()), content="")
    }
  }
}

///|
async test "client custom root certificate rejects different root" {
  @async.with_task_group() <| root => {
    let (client_read_from_server, server_write_to_client) = @pipe.pipe()
    let (server_read_from_client, client_write_to_server) = @pipe.pipe()
    root.spawn_bg() <| () => {
      defer {
        server_read_from_client.close()
        server_write_to_client.close()
      }
      @test.assert_raise_async <| () => {
        custom_root_test_server(
          server_read_from_client, server_write_to_client, "async/tls/test_keys/other_root_key.pem",
          "async/tls/test_keys/other_root_cert.pem", "async/tls/test_keys/other_root_cert.pfx",
        )
      }
    }
    root.spawn_bg() <| () => {
      defer {
        client_read_from_server.close()
        client_write_to_server.close()
      }
      @test.assert_raise_async <| () => {
        Tls::client_from_pair(
          client_read_from_server,
          client_write_to_server,
          host="whatever",
          trust=CustomPemFile("async/tls/test_keys/valid_root_cert.pem"),
        )
      }
    }
  }
}

///|
#derive(@debug.Debug)
priv suberror ReadFailed

///|
/// A pipe reader that, once `fail` is set, fails every read,
/// or with `eof` reaches the end of input
priv struct FailingRead {
  inner : @pipe.PipeRead
  ctrl : @io.BinaryReaderController
  eof : Bool
  mut fail : Bool
}

///|
impl @io.BinaryReader for FailingRead

///|
impl @io.BinaryReaderImpl for FailingRead with fn raw_read_impl(
  self,
  buf,
  offset~,
  max_len~,
) {
  guard !self.fail else { if self.eof { 0 } else { raise ReadFailed } }
  self.inner.read_into(buf, offset~, max_len~)
}

///|
impl @io.BinaryReaderImpl for FailingRead with fn name(_self) {
  "FailingRead"
}

///|
impl @io.BinaryReaderImpl for FailingRead with fn get_controller(self) {
  self.ctrl
}

///|
/// Returns what a large `write` raises
/// when a concurrent `read` fails, or with `eof` reaches the end of input
async fn write_after_failed_read(eof~ : Bool) -> Error {
  let (client_read_from_server, server_write_to_client) = @pipe.pipe()
  let (server_read_from_client, client_write_to_server) = @pipe.pipe()
  defer {
    client_read_from_server.close()
    client_write_to_server.close()
    server_read_from_client.close()
    server_write_to_client.close()
  }
  let mut result = None
  @async.with_task_group() <| root => {
    root.spawn_bg() <| () => {
      test_server(server_read_from_client, server_write_to_client).close()
    }
    let reader = FailingRead::{
      inner: client_read_from_server,
      ctrl: BinaryReaderController(),
      eof,
      fail: false,
    }
    let client = Tls::client_from_pair(
      reader,
      client_write_to_server,
      trust=NoVerification,
    )
    defer client.close()
    reader.fail = true
    // Runs once the write below waits for the full pipe:
    // fail a read, then let the write continue.
    root.spawn_bg() <| () => {
      ignore(client.read()) catch {
        _ => ()
      }
      ignore(server_read_from_client.read_all())
    }
    result = Some(
      @test.expect_error_async(() => client.write(Bytes::make(1 << 20, b'x'))),
    )
    // Ends the drain above
    client_write_to_server.close()
  }
  result.unwrap()
}

///|
async test "`write` after a concurrent `read` failed or reached EOF" {
  @debug.debug_inspect(
    write_after_failed_read(eof=false),
    content=(
      #|TransportError(
      #|  TransportError(ReadFailed, context="FailingRead"),
      #|  context="@tls.Tls",
      #|)
    ),
  )
  @debug.debug_inspect(
    write_after_failed_read(eof=true),
    content=(
      #|TransportError(ConnectionClosed, context="@tls.Tls")
    ),
  )
}
