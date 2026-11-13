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
/// Type for a HTTP/HTTPS proxy configuration.
/// A `Proxy` object itself merely holds proxy configuration,
/// it does not own any resource,
/// and the same `Proxy` object can be reused for multiple requests.
struct Proxy {
  setup : async (StringView, UInt16) -> ClientConnection
}

///|
/// Create a HTTP proxy by specifying a custom tunnel setup function.
/// The callback receive the target hostname and port number to connect to,
/// and should return a client connection in passthrough mode
/// (see `@http.ClientConnection::passthrough` for more details).
/// Usually, the callback should perform some custom handshake/authentication
/// and perform a `CONNECT` request to the proxy server,
/// and call `enter_passthrough_mode()` on succeess to setup a tunnel.
pub fn Proxy::custom_tunnel(
  f : async (StringView, UInt16) -> ClientConnection,
) -> Proxy {
  { setup: f, }
}

///|
/// Create a simple proxy from a proxy server URL.
/// The proxy will perform a plain `CONNECT` to the proxy server.
///
/// If `username` or `password` is present, HTTP Basic proxy authentication is
/// used. An omitted username or password is encoded as an empty string.
#cfg(any(target="native", target="wasm"))
pub fn Proxy::Proxy(
  url : StringView,
  username? : StringView,
  password? : StringView,
) -> Proxy {
  let proxy_authorization = match (username, password) {
    (None, None) => None
    (username, password) => {
      let username = username.unwrap_or("")
      let password = password.unwrap_or("")
      Some("Basic \{@base64.encode(@utf8.encode("\{username}:\{password}"))}")
    }
  }
  async fn setup(target : StringView, port : UInt16) {
    let conn = ClientConnection(url)
    errdefer conn.close()
    let extra_headers : Headers = match proxy_authorization {
      Some(value) => { "Proxy-Authorization": value }
      None => {}
    }
    let response = conn
      ..request(Connect, "\{target}:\{port}", extra_headers~)
      .end_request()
    guard response.code is (200..<300) else { raise ProxyError(response) }
    conn..skip_response_body()..enter_passthrough_mode()
  }
  { setup, }
}

///|
/// Create a simple proxy from a proxy server URL.
///
/// HTTP proxies are unsupported on the JavaScript backend, so this
/// configuration has no effect there.
#cfg(target="js")
#warnings("-unused_async")
pub fn Proxy::Proxy(
  url : StringView,
  username? : StringView,
  password? : StringView,
) -> Proxy {
  ignore(url)
  ignore(username)
  ignore(password)
  async fn setup(_target : StringView, _port : UInt16) -> ClientConnection {
    abort("HTTP proxies are unsupported on the JavaScript backend")
  }
  { setup, }
}
