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
fn resolve_url(uri : String) -> (Protocol, String, StringView) raise {
  guard uri.find("://") is Some(protocol_len) else { raise InvalidFormat }
  let protocol = match uri[:protocol_len] {
    "http" => Http
    "https" => Https
    protocol => raise UnsupportedProtocol(protocol.to_owned())
  }
  let uri = uri[protocol_len + 3:]
  let (host, path) = if uri.find("/") is Some(i) {
    (uri[:i], uri[i:])
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
/// See `@http.Client::new` for more details.
/// `proxy` is not supported on JavaScript backend.
///
/// See `Client::request` for more details.
pub async fn request_binary(
  uri : String,
  meth : RequestMethod,
  headers : Headers,
  body : BytesView,
  proxy? : Client,
) -> (Response, Bytes) {
  let (protocol, host, path) = resolve_url(uri)
  let client = Client::connect(host, headers~, protocol~, proxy?)
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
/// See `@http.Client::new` for more details.
/// `proxy` is not supported on JavaScript backend.
///
/// See `Client::request` for more details.
pub async fn request_text(
  uri : String,
  meth : RequestMethod,
  headers : Headers,
  body : StringView,
  proxy? : Client,
) -> (Response, String) {
  let (protocol, host, path) = resolve_url(uri)
  let client = Client::connect(host, headers~, protocol~, proxy?)
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
/// See `@http.Client::new` for more details.
/// `proxy` is not supported on JavaScript backend.
///
/// See `Client::request` for more details.
pub async fn request_json(
  uri : String,
  meth : RequestMethod,
  headers : Headers,
  body : Json?,
  proxy? : Client,
) -> (Response, Json) {
  let (protocol, host, path) = resolve_url(uri)
  let client = Client::connect(host, headers~, protocol~, proxy?)
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
/// See `@http.Client::new` for more details.
/// `proxy` is not supported on JavaScript backend.
///
/// See `Client::request` for more details.
pub async fn get_binary(
  uri : String,
  headers~ : Headers = Map([]),
  proxy? : Client,
) -> (Response, Bytes) {
  request_binary(uri, Get, headers, b"", proxy?)
}

///|
/// Perform a HTTP `GET` request to `uri` with UTF-8 encoded response.
/// Supported protocols are `http://` and `https://`.
/// The HTTP response message and the whole response body will be returned.
///
/// `proxy`, if present, specifies the proxy to use for this request.
/// See `@http.Client::new` for more details.
/// `proxy` is not supported on JavaScript backend.
///
/// See `Client::request` for more details.
pub async fn get_text(
  uri : String,
  headers~ : Headers = Map([]),
  proxy? : Client,
) -> (Response, String) {
  request_text(uri, Get, headers, "", proxy?)
}

///|
/// Perform a HTTP `GET` request to `uri` with UTF-8 encoded JSON response.
/// Supported protocols are `http://` and `https://`.
/// The HTTP response message and the whole response body will be returned.
///
/// `proxy`, if present, specifies the proxy to use for this request.
/// See `@http.Client::new` for more details.
/// `proxy` is not supported on JavaScript backend.
///
/// See `Client::request` for more details.
pub async fn get_json(
  uri : String,
  headers~ : Headers = Map([]),
  proxy? : Client,
) -> (Response, Json) {
  request_json(uri, Get, headers, None, proxy?)
}

///|
/// Similar to `get_binary`, but performs a `PUT` request instead.
pub async fn put_binary(
  uri : String,
  content : BytesView,
  headers~ : Headers = Map([]),
  proxy? : Client,
) -> (Response, Bytes) {
  request_binary(uri, Put, headers, content, proxy?)
}

///|
/// Similar to `get_text`, but performs a `PUT` request instead.
pub async fn put_text(
  uri : String,
  content : StringView,
  headers~ : Headers = Map([]),
  proxy? : Client,
) -> (Response, String) {
  request_text(uri, Put, headers, content, proxy?)
}

///|
/// Similar to `get_json`, but performs a `PUT` request instead.
pub async fn put_json(
  uri : String,
  content : Json,
  headers~ : Headers = Map([]),
  proxy? : Client,
) -> (Response, Json) {
  request_json(uri, Put, headers, Some(content), proxy?)
}

///|
/// Similar to `get_binary`, but performs a `POST` request instead.
pub async fn post_binary(
  uri : String,
  content : BytesView,
  headers~ : Headers = Map([]),
  proxy? : Client,
) -> (Response, Bytes) {
  request_binary(uri, Post, headers, content, proxy?)
}

///|
/// Similar to `get_text`, but performs a `POST` request instead.
pub async fn post_text(
  uri : String,
  content : StringView,
  headers~ : Headers = Map([]),
  proxy? : Client,
) -> (Response, String) {
  request_text(uri, Post, headers, content, proxy?)
}

///|
/// Similar to `get_json`, but performs a `POST` request instead.
pub async fn post_json(
  uri : String,
  content : Json,
  headers~ : Headers = Map([]),
  proxy? : Client,
) -> (Response, Json) {
  request_json(uri, Post, headers, Some(content), proxy?)
}

///|
/// Similar to `@http.get_xxx`, but allow reading response body streamingly.
/// A pair `(response, client)` will be returned,
/// where `response` is the response header from the server,
/// and `client` is the HTTP client that performs the request.
/// `client` can be used to read the content of response body
/// via `@io.BinaryReader` or `@io.TextReader` interface.
/// See `@http.Client` and its `.text` field for more details.
///
/// Note that the returned client must be manually closed via `.close()`
/// to close the underlying connection used for the request.
pub async fn get_stream(
  uri : String,
  headers~ : Headers = Map([]),
  proxy? : Client,
) -> (Response, Client) {
  let (protocol, host, path) = resolve_url(uri)
  let client = Client::connect(host, headers~, protocol~, proxy?)
  errdefer client.close()
  let response = client..request(Get, path).end_request()
  (response, client)
}

///|
/// Similar to `@http.put_xxx`, but allow writing request body streamingly.
/// The return value `client` is the HTTP client that performs the request,
/// it can be used to write the content of request body via `@io.BinaryWriter`.
/// Text content can be written via `client.text` through the `@io.TextWriter` interface as well.
/// See `@http.Client` and its `.text` field for more details.
///
/// Notice that writing to `@http.Client` is buffered,
/// so if you need to send data to the server immediately, `.flush()` must be called.
/// After writing all the content, `.end_request()` must be called
/// to complete the request and obtain response from the server.
/// After that, the response body from the server can be obtained 
/// by using `client` as `@io.BinaryReader` or `client.text` as `@io.TextReader`.
/// See `@http.Client` and its `.text` field for more details.
///
/// Note that the returned `client` must be manually closed via `.close()`
/// to close the underlying connection used for the request.
pub async fn put_stream(
  uri : String,
  headers~ : Headers = Map([]),
  proxy? : Client,
) -> Client {
  let (protocol, host, path) = resolve_url(uri)
  let client = Client::connect(host, protocol~, headers~, proxy?)
  errdefer client.close()
  client.request(Put, path)
  client
}

///|
/// Similar to `@http.post_xxx`, but allow writing request body streamingly.
/// The return value `client` is the HTTP client that performs the request,
/// it can be used to write the content of request body via `@io.BinaryWriter`.
/// Text content can be written via `client.text` through the `@io.TextWriter` interface as well.
/// See `@http.Client` and its `.text` field for more details.
///
/// Notice that writing to `@http.Client` is buffered,
/// so if you need to send data to the server immediately, `.flush()` must be called.
/// After writing all the content, `.end_request()` must be called
/// to complete the request and obtain response from the server.
/// After that, the response body from the server can be obtained 
/// by using `client` as `@io.BinaryReader` or `client.text` as `@io.TextReader`.
/// See `@http.Client` and its `.text` field for more details.
///
/// Note that the returned `client` must be manually closed via `.close()`
/// to close the underlying connection used for the request.
pub async fn post_stream(
  uri : String,
  headers~ : Headers = Map([]),
  proxy? : Client,
) -> Client {
  let (protocol, host, path) = resolve_url(uri)
  let client = Client::connect(host, protocol~, headers~, proxy?)
  errdefer client.close()
  client.request(Post, path)
  client
}
