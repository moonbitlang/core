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
/// Supported HTTP protocols
pub(all) enum Protocol {
  Http
  Https
} derive(@debug.Debug, Eq, Compare, Hash, @json.ToJson)

///|
/// The default port of a HTTP protocol
pub fn Protocol::default_port(p : Protocol) -> Int32 {
  match p {
    Http => 80
    Https => 443
  }
}

///|
/// Error raised when an invalid URI is specified
pub suberror UriParseError {
  InvalidFormat
  UnsupportedProtocol(String)
} derive(@debug.Debug, @json.ToJson)

///|
fn resolve_url(uri : StringView) -> (Protocol, String, StringView) raise {
  guard uri.find("://") is Some(protocol_len) else { raise InvalidFormat }
  let protocol = match uri[:protocol_len] {
    "http" => Http
    "https" => Https
    protocol => raise UnsupportedProtocol(protocol.to_owned())
  }
  let uri = uri[protocol_len + 3:]
  let (host, path) = if uri.find("/") is Some(i) {
    uri.split_at(i)
  } else {
    (uri, "/")
  }
  (protocol, host.to_owned(), path)
}

///|
#cfg(any(target="native", target="wasm"))
fn resolve_host(
  host : StringView,
  protocol~ : Protocol,
) -> (StringView, Int32) raise {
  if host =~ (
      re"^" +
      (re".*" as host) +
      re":" +
      (re"[0-9]+" as port_str) +
      re"$"
    ) {
    let port = @string.parse_int(port_str) catch { _ => raise InvalidFormat }
    guard port is (1..<65536) else { raise InvalidFormat }
    (host, port)
  } else {
    (host, protocol.default_port())
  }
}

///|
/// Perform a single HTTP request to `uri` with binary payload/response.
/// Supported protocols are `http://` and `https://`.
/// The HTTP response message and the whole response body will be returned.
///
/// `proxy`, if present, specifies the proxy to use for this request.
/// See `@http.ClientConnection(..)` for more details.
/// `proxy` is not supported on JavaScript backend.
///
/// See `ClientConnection::request` for more details.
pub async fn request_binary(
  uri : String,
  meth : RequestMethod,
  headers : Headers,
  body : BytesView,
  proxy? : ClientConnection,
) -> (Response, Bytes) {
  let (protocol, host, path) = resolve_url(uri)
  let client = ClientConnection::connect(host, headers~, protocol~, proxy?)
  defer client.close()
  let response = client..request(meth, path)..write(body).end_request()
  (response, client.read_all())
}

///|
/// Perform a single HTTP request to `uri` with UTF-8 encoded payload/response.
/// Supported protocols are `http://` and `https://`.
/// The HTTP response message and the whole response body will be returned.
///
/// `proxy`, if present, specifies the proxy to use for this request.
/// See `@http.ClientConnection(..)` for more details.
/// `proxy` is not supported on JavaScript backend.
///
/// See `ClientConnection::request` for more details.
pub async fn request_text(
  uri : String,
  meth : RequestMethod,
  headers : Headers,
  body : StringView,
  proxy? : ClientConnection,
) -> (Response, String) {
  let (protocol, host, path) = resolve_url(uri)
  let client = ClientConnection::connect(host, headers~, protocol~, proxy?)
  defer client.close()
  client.request(meth, path)
  client.text.write(body)
  let response = client.end_request()
  (response, client.text.read_all())
}

///|
/// Perform a single HTTP request to `uri` with UTF-8 encoded JSON payload/response.
/// Supported protocols are `http://` and `https://`.
/// The HTTP response message and the whole response body will be returned.
///
/// `proxy`, if present, specifies the proxy to use for this request.
/// See `@http.ClientConnection(..)` for more details.
/// `proxy` is not supported on JavaScript backend.
///
/// See `ClientConnection::request` for more details.
pub async fn request_json(
  uri : String,
  meth : RequestMethod,
  headers : Headers,
  body : Json?,
  proxy? : ClientConnection,
) -> (Response, Json) {
  let (protocol, host, path) = resolve_url(uri)
  let client = ClientConnection::connect(host, headers~, protocol~, proxy?)
  defer client.close()
  client.request(meth, path)
  if body is Some(body) {
    client.text.write(body.stringify())
  }
  let response = client.end_request()
  (response, @json.parse(client.text.read_all()))
}

///|
/// Perform a HTTP `GET` request to `uri` with binary response.
/// Supported protocols are `http://` and `https://`.
/// The HTTP response message and the whole response body will be returned.
///
/// `proxy`, if present, specifies the proxy to use for this request.
/// See `@http.ClientConnection::new` for more details.
/// `proxy` is not supported on JavaScript backend.
///
/// See `ClientConnection::request` for more details.
pub async fn get_binary(
  uri : String,
  headers~ : Headers = Map([]),
  proxy? : ClientConnection,
) -> (Response, Bytes) {
  request_binary(uri, Get, headers, b"", proxy?)
}

///|
/// Perform a HTTP `GET` request to `uri` with UTF-8 encoded response.
/// Supported protocols are `http://` and `https://`.
/// The HTTP response message and the whole response body will be returned.
///
/// `proxy`, if present, specifies the proxy to use for this request.
/// See `@http.ClientConnection::new` for more details.
/// `proxy` is not supported on JavaScript backend.
///
/// See `ClientConnection::request` for more details.
pub async fn get_text(
  uri : String,
  headers~ : Headers = Map([]),
  proxy? : ClientConnection,
) -> (Response, String) {
  request_text(uri, Get, headers, "", proxy?)
}

///|
/// Perform a HTTP `GET` request to `uri` with UTF-8 encoded JSON response.
/// Supported protocols are `http://` and `https://`.
/// The HTTP response message and the whole response body will be returned.
///
/// `proxy`, if present, specifies the proxy to use for this request.
/// See `@http.ClientConnection::new` for more details.
/// `proxy` is not supported on JavaScript backend.
///
/// See `ClientConnection::request` for more details.
pub async fn get_json(
  uri : String,
  headers~ : Headers = Map([]),
  proxy? : ClientConnection,
) -> (Response, Json) {
  request_json(uri, Get, headers, None, proxy?)
}

///|
/// Similar to `get_binary`, but performs a `PUT` request instead.
pub async fn put_binary(
  uri : String,
  content : BytesView,
  headers~ : Headers = Map([]),
  proxy? : ClientConnection,
) -> (Response, Bytes) {
  request_binary(uri, Put, headers, content, proxy?)
}

///|
/// Similar to `get_text`, but performs a `PUT` request instead.
pub async fn put_text(
  uri : String,
  content : StringView,
  headers~ : Headers = Map([]),
  proxy? : ClientConnection,
) -> (Response, String) {
  request_text(uri, Put, headers, content, proxy?)
}

///|
/// Similar to `get_json`, but performs a `PUT` request instead.
pub async fn put_json(
  uri : String,
  content : Json,
  headers~ : Headers = Map([]),
  proxy? : ClientConnection,
) -> (Response, Json) {
  request_json(uri, Put, headers, Some(content), proxy?)
}

///|
/// Similar to `get_binary`, but performs a `POST` request instead.
pub async fn post_binary(
  uri : String,
  content : BytesView,
  headers~ : Headers = Map([]),
  proxy? : ClientConnection,
) -> (Response, Bytes) {
  request_binary(uri, Post, headers, content, proxy?)
}

///|
/// Similar to `get_text`, but performs a `POST` request instead.
pub async fn post_text(
  uri : String,
  content : StringView,
  headers~ : Headers = Map([]),
  proxy? : ClientConnection,
) -> (Response, String) {
  request_text(uri, Post, headers, content, proxy?)
}

///|
/// Similar to `get_json`, but performs a `POST` request instead.
pub async fn post_json(
  uri : String,
  content : Json,
  headers~ : Headers = Map([]),
  proxy? : ClientConnection,
) -> (Response, Json) {
  request_json(uri, Post, headers, Some(content), proxy?)
}

///|
/// Performs a `GET` request to the target URL.
/// Return the response header and the connection assigned for this request.
/// Response body can be obtained by reading from the connection via the `@io.BinaryReader` interface,
/// or through the `@io.TextReader` interface using the builtin `.text` view on the connection.
/// For requests with simple, short response message,
/// `@http.get_binary`/`@http.get_text`/`@http.get_json` can be used to collect the body automatically.
///
/// The returned connection must be manually closed via `.close()`
/// after the caller no longer need to use it.
pub async fn get(
  uri : String,
  headers~ : Headers = Map([]),
  proxy? : ClientConnection,
) -> (Response, ClientConnection) {
  let (protocol, host, path) = resolve_url(uri)
  let client = ClientConnection::connect(host, headers~, protocol~, proxy?)
  errdefer client.close()
  let response = client..request(Get, path).end_request()
  (response, client)
}

///|
/// Performs a `PUT` request to the target URL.
/// Return the connection assigned for this request.
/// Request body can be written through the `@io.BinaryWriter` interface on the connection,
/// or through the `@io.TextWriter` interface using the builtin `.text` view on the connection.
///
/// When the request body is completely written, `end_request()` should be called on the connection
/// to terminate the request and obtain response header from the server.
/// After receiving the response header,
/// response body can be obtained by reading from the connection via the `@io.BinaryReader` interface,
/// or through the `@io.TextReader` interface using the builtin `.text` view on the connection.
///
/// For requests with simple, short message body,
/// `@http.put_binary`/`@http.put_text`/`@http.put_json` can be used to collect the body automatically.
///
/// The returned connection must be manually closed via `.close()`
/// after the caller no longer need to use it.
pub async fn put(
  uri : String,
  headers~ : Headers = Map([]),
  proxy? : ClientConnection,
) -> ClientConnection {
  let (protocol, host, path) = resolve_url(uri)
  let client = ClientConnection::connect(host, protocol~, headers~, proxy?)
  errdefer client.close()
  client.request(Put, path)
  client
}

///|
/// Performs a `POST` request to the target URL.
/// Return the connection assigned for this request.
/// Request body can be written through the `@io.BinaryWriter` interface on the connection,
/// or through the `@io.TextWriter` interface using the builtin `.text` view on the connection.
///
/// When the request body is completely written, `end_request()` should be called on the connection
/// to terminate the request and obtain response header from the server.
/// After receiving the response header,
/// response body can be obtained by reading from the connection via the `@io.BinaryReader` interface,
/// or through the `@io.TextReader` interface using the builtin `.text` view on the connection.
///
/// For requests with simple, short message body,
/// `@http.post_binary`/`@http.post_text`/`@http.post_json` can be used to collect the body automatically.
///
/// The returned connection must be manually closed via `.close()`
/// after the caller no longer need to use it.
pub async fn post(
  uri : String,
  headers~ : Headers = Map([]),
  proxy? : ClientConnection,
) -> ClientConnection {
  let (protocol, host, path) = resolve_url(uri)
  let client = ClientConnection::connect(host, protocol~, headers~, proxy?)
  errdefer client.close()
  client.request(Post, path)
  client
}
