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
/// Perform a generic HTTP request to `uri`. Return the connection assigned for this request.
/// The caller should first write request body to the connection through the `@io.BinaryWriter` interface
/// (or through the `@io.TextWriter` interface using the builtin `.text` view),
/// then call `.end_request()` to finish the request and obtain server response,
/// and finally read response message body through the `@io.BinaryReader` interface
/// (or through the `@io.TextReader` interface using the builtin `.text` view) on the connection.
/// 
/// The returned connection must be closed after finishing the request.
///
/// For requests with short message body,
/// `@http.request_binary`/`@http.request_text`/`@http.request_json` can be used to
/// automatically collect request/response body.
///
/// For common request methods, `@http.get`, `@http.post` etc. can be used instead.
pub async fn request(
  meth : RequestMethod,
  uri : StringView,
  headers~ : Headers = {},
  proxy? : ClientConnection,
) -> ClientConnection {
  let (protocol, host, path) = resolve_url(uri)
  let client = ClientConnection::connect(host, headers~, protocol~, proxy?)
  errdefer client.close()
  client.request(meth, path)
  client
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
  meth : RequestMethod,
  uri : StringView,
  body : BytesView,
  headers~ : Headers = {},
  proxy? : ClientConnection,
) -> (Response, Bytes) {
  let conn = request(meth, uri, headers~, proxy?)
  defer conn.close()
  let response = conn..write(body).end_request()
  (response, conn.read_all())
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
  meth : RequestMethod,
  uri : StringView,
  body : StringView,
  headers~ : Headers,
  proxy? : ClientConnection,
) -> (Response, String) {
  let conn = request(meth, uri, headers~, proxy?)
  defer conn.close()
  conn.text.write(body)
  let response = conn.end_request()
  (response, conn.text.read_all())
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
  meth : RequestMethod,
  uri : StringView,
  body : Json?,
  headers~ : Headers,
  proxy? : ClientConnection,
) -> (Response, Json) {
  let conn = request(meth, uri, headers~, proxy?)
  defer conn.close()
  if body is Some(body) {
    conn.text.write(body.stringify())
  }
  let response = conn.end_request()
  (response, @json.parse(conn.text.read_all()))
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
  uri : StringView,
  headers~ : Headers = Map([]),
  proxy? : ClientConnection,
) -> (Response, Bytes) {
  request_binary(Get, uri, b"", headers~, proxy?)
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
  uri : StringView,
  headers~ : Headers = Map([]),
  proxy? : ClientConnection,
) -> (Response, String) {
  request_text(Get, uri, "", headers~, proxy?)
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
  uri : StringView,
  headers~ : Headers = Map([]),
  proxy? : ClientConnection,
) -> (Response, Json) {
  request_json(Get, uri, None, headers~, proxy?)
}

///|
/// Similar to `get_binary`, but performs a `PUT` request instead.
pub async fn put_binary(
  uri : StringView,
  content : BytesView,
  headers~ : Headers = Map([]),
  proxy? : ClientConnection,
) -> (Response, Bytes) {
  request_binary(Put, uri, content, headers~, proxy?)
}

///|
/// Similar to `get_text`, but performs a `PUT` request instead.
pub async fn put_text(
  uri : StringView,
  content : StringView,
  headers~ : Headers = Map([]),
  proxy? : ClientConnection,
) -> (Response, String) {
  request_text(Put, uri, content, headers~, proxy?)
}

///|
/// Similar to `get_json`, but performs a `PUT` request instead.
pub async fn put_json(
  uri : StringView,
  content : Json,
  headers~ : Headers = Map([]),
  proxy? : ClientConnection,
) -> (Response, Json) {
  request_json(Put, uri, Some(content), headers~, proxy?)
}

///|
/// Similar to `get_binary`, but performs a `POST` request instead.
pub async fn post_binary(
  uri : StringView,
  content : BytesView,
  headers~ : Headers = Map([]),
  proxy? : ClientConnection,
) -> (Response, Bytes) {
  request_binary(Post, uri, content, headers~, proxy?)
}

///|
/// Similar to `get_text`, but performs a `POST` request instead.
pub async fn post_text(
  uri : StringView,
  content : StringView,
  headers~ : Headers = Map([]),
  proxy? : ClientConnection,
) -> (Response, String) {
  request_text(Post, uri, content, headers~, proxy?)
}

///|
/// Similar to `get_json`, but performs a `POST` request instead.
pub async fn post_json(
  uri : StringView,
  content : Json,
  headers~ : Headers = Map([]),
  proxy? : ClientConnection,
) -> (Response, Json) {
  request_json(Post, uri, Some(content), headers~, proxy?)
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
  uri : StringView,
  headers~ : Headers = Map([]),
  proxy? : ClientConnection,
) -> (Response, ClientConnection) {
  let conn = request(Get, uri, headers~, proxy?)
  errdefer conn.close()
  (conn.end_request(), conn)
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
  uri : StringView,
  headers~ : Headers = Map([]),
  proxy? : ClientConnection,
) -> ClientConnection {
  request(Put, uri, headers~, proxy?)
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
  uri : StringView,
  headers~ : Headers = Map([]),
  proxy? : ClientConnection,
) -> ClientConnection {
  request(Post, uri, headers~, proxy?)
}
