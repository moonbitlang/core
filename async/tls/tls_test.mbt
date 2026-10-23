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
#cfg(all(not(target="wasm"), not(platform="windows")))
async fn test_server(r : &@io.BinaryReader, w : &@io.BinaryWriter) -> @tls.Tls {
  @tls.Tls::server_from_pair(
    r,
    w,
    private_key_file="async/tls/test_keys/key.pem",
    private_key_type=PEM,
    certificate_file="async/tls/test_keys/cert.pem",
    certificate_type=PEM,
  )
}

///|
#cfg(all(not(target="wasm"), platform="windows"))
async fn test_server(r : &@io.BinaryReader, w : &@io.BinaryWriter) -> @tls.Tls {
  @tls.Tls::server_from_pair(r, w, pfx_file="async/tls/test_keys/cert.pfx")
}

///|
#cfg(target="wasm")
async fn test_server(r : &@io.BinaryReader, w : &@io.BinaryWriter) -> @tls.Tls {
  @tls.Tls::server_from_pair(
    r,
    w,
    private_key_file="async/tls/test_keys/key.pem",
    private_key_type=PEM,
    certificate_file="async/tls/test_keys/cert.pem",
    certificate_type=PEM,
    pfx_file="async/tls/test_keys/cert.pfx",
  )
}

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
        log.write_string("server received: \{data}\n")
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
      let client = @tls.Tls::client_from_pair(
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
        log.write_string("server received: \{@utf8.decode(data)}\n")
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
      let client = @tls.Tls::client_from_pair(
        client_read_from_server,
        client_write_to_server,
        trust=NoVerification,
      )
      defer client.close()
      for data in [b"abcd", b"efgh", b"ijkl"] {
        client.write(data)
        assert_eq(client.read_exactly(4), data)
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
      debug_inspect(
        @test.expect_error_async <| () => {
          @tls.Tls::client_from_pair(
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
async test "`read` already closed" {
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
      let client = @tls.Tls::client_from_pair(
        client_read_from_server,
        client_write_to_server,
        trust=NoVerification,
      )
      defer client.close()
      debug_inspect(client.read(), content="None")
    }
  }
}

///|
#cfg(all(not(target="wasm"), not(platform="windows")))
async fn custom_root_test_server(
  r : &@io.BinaryReader,
  w : &@io.BinaryWriter,
  private_key_file : String,
  certificate_file : String,
  _pfx_file : String,
) -> @tls.Tls {
  @tls.Tls::server_from_pair(
    r,
    w,
    private_key_file~,
    private_key_type=PEM,
    certificate_file~,
    certificate_type=PEM,
  )
}

///|
#cfg(all(not(target="wasm"), platform="windows"))
async fn custom_root_test_server(
  r : &@io.BinaryReader,
  w : &@io.BinaryWriter,
  _private_key_file : String,
  _certificate_file : String,
  pfx_file : String,
) -> @tls.Tls {
  @tls.Tls::server_from_pair(r, w, pfx_file~)
}

///|
#cfg(target="wasm")
async fn custom_root_test_server(
  r : &@io.BinaryReader,
  w : &@io.BinaryWriter,
  private_key_file : String,
  certificate_file : String,
  pfx_file : String,
) -> @tls.Tls {
  @tls.Tls::server_from_pair(
    r,
    w,
    private_key_file~,
    private_key_type=PEM,
    certificate_file~,
    certificate_type=PEM,
    pfx_file~,
  )
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
      assert_eq(server.read_exactly(2), b"ok")
      server.shutdown()
    }
    root.spawn_bg() <| () => {
      defer {
        client_read_from_server.close()
        client_write_to_server.close()
      }
      let client = @tls.Tls::client_from_pair(
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
        @tls.Tls::client_from_pair(
          client_read_from_server,
          client_write_to_server,
          host="whatever",
          trust=CustomPemFile("async/tls/test_keys/valid_root_cert.pem"),
        )
      }
    }
  }
}
