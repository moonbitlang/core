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
/// A generic HTTP client
struct Client {
  headers : Headers
}

///|
/// Create a new HTTP client.
///
/// `headers`, if present, set common headers for all requests going through this client.
/// The ownership of `headers` will be transferred to the new client,
/// so `headers` should not be used by the caller later.
/// The following headers is automatically set,
/// and must not be specified in `headers`:
///
/// - Host
/// - Content-Encoding, Transfer-Encoding
pub fn Client::Client(headers~ : Headers = {}) -> Client {
  { headers, }
}

///|
/// Close a HTTP client, release associated resource
pub fn Client::close(_ : Client) -> Unit {

}

///|
/// Make a request using a HTTP client.
/// `meth` specifies the request method and `url` specifies the target URL of request.
/// Currently only `http` and `https` protocols are supported.
///
/// The client will find or allocate a new network connection to fulfill the request.
/// If the request is sent successfully, that connection will be returned.
/// Subsequent workflow with the returned connection is as follows:
/// 1. request message body can be written to the connection through `@io.BinaryWriter` interface
///    (or `@io.TextWriter` interface through the builtin `.text` view on the connection)
/// 2. after finish writing all request body content, `.end_request()` should be invoked
///    on the connection to finish the request and obtain the response header
/// 3. after obtaining the response header, content of response body can be read through the
///    `@io.BinaryReader` interface (or `@io.TextReader` interface through the builtin `.text` view)
///    on the connection
/// 4. after finishing the whole request, `.close()` must be called on the connection
///    to return it to the client
///
/// In addition to common headers specified on client creation,
/// extra HTTP headers can be passed via `extra_headers`.
/// In addition to the forbidden headers in `@http.Client(..)`,
/// `User-Agent` must not be specified in `extra_headers`: it can only be specified on client creation.
///
/// If `Content-Length` is present in `extra_headers`,
/// it should be the total length of the request body.
/// The request body can still be sent incrementally,
/// but if the actual body being sent is shorter and longer than the provided length,
/// an error will be raised.
pub async fn Client::request(
  self : Client,
  meth : RequestMethod,
  url : StringView,
  extra_headers~ : Headers = {},
) -> ClientConnection {
  let (protocol, host, path) = resolve_url(url)
  let conn = ClientConnection::connect(host, protocol~, headers=self.headers)
  errdefer conn.close()
  conn.request(meth, path, extra_headers~)
  conn
}

///|
/// Perform a `GET` request on `url` through a HTTP client.
/// Return the response header and the client connection assigned for the request.
/// Content of response body can be read through the
/// `@io.BinaryReader` interface (or `@io.TextReader` interface through the builtin `.text` view)
/// on the connection. The connection must be closed after the connection become unused.
///
/// See `@http.Client::request` for more details on the optional parameters.
pub async fn Client::get(
  self : Client,
  url : StringView,
  extra_headers~ : Headers = {},
) -> (ResponseHeader, ClientConnection) {
  let conn = self.request(Get, url, extra_headers~)
  errdefer conn.close()
  let response = conn.end_request()
  (response, conn)
}

///|
/// Perform a HTTP `GET` request to `uri`,
/// collect response body as plain binary automatically.
///
/// See `@http.Client::request` for more details.
pub async fn Client::get_binary(
  self : Client,
  uri : StringView,
  extra_headers~ : Headers = Map([]),
) -> (ResponseHeader, Bytes) {
  let (response, conn) = self.get(uri, extra_headers~)
  defer conn.close()
  (response, conn.read_all())
}

///|
/// Perform a HTTP `GET` request to `uri`,
/// collect response body as UTF-8 encoded text automatically.
///
/// See `@http.Client::request` for more details.
pub async fn Client::get_text(
  self : Client,
  uri : StringView,
  extra_headers~ : Headers = Map([]),
) -> (ResponseHeader, String) {
  let (response, conn) = self.get(uri, extra_headers~)
  defer conn.close()
  (response, conn.text.read_all())
}

///|
/// Perform a HTTP `GET` request to `uri`,
/// collect response body as UTF-8 encoded JSON automatically.
///
/// See `@http.Client::request` for more details.
pub async fn Client::get_json(
  self : Client,
  uri : StringView,
  extra_headers~ : Headers = Map([]),
) -> (ResponseHeader, Json) {
  let (response, conn) = self.get(uri, extra_headers~)
  defer conn.close()
  (response, @json.parse(conn.text.read_all()))
}

///|
/// Perform a `PUT` request on `url` through a HTTP client.
/// Return the client connection assigned for this request.
/// Request body can be written through the `@io.BinaryWriter` interface on the connection,
/// or through the `@io.TextWriter` interface using the builtin `.text` view on the connection.
/// When the request body is completely written, `end_request()` should be called on the connection
/// to terminate the request and obtain response header from the server.
/// After receiving the response header,
/// Response body can be read through the `@io.BinaryReader` interface
/// (or `@io.TextReader` interface through the builtin `.text` view) on the connection.
/// The connection must be closed after the connection become unused.
///
/// See `@http.Client::request` for more details on the optional parameters.
pub async fn Client::put(
  self : Client,
  url : StringView,
  extra_headers~ : Headers = {},
) -> ClientConnection {
  self.request(Put, url, extra_headers~)
}

///|
/// Perform a `POST` request on `url` through a HTTP client.
/// Return the client connection assigned for this request.
/// Request body can be written through the `@io.BinaryWriter` interface on the connection,
/// or through the `@io.TextWriter` interface using the builtin `.text` view on the connection.
/// When the request body is completely written, `end_request()` should be called on the connection
/// to terminate the request and obtain response header from the server.
/// After receiving the response header,
/// Response body can be read through the `@io.BinaryReader` interface
/// (or `@io.TextReader` interface through the builtin `.text` view) on the connection.
/// The connection must be closed after the connection become unused.
///
/// See `@http.Client::request` for more details on the optional parameters.
pub async fn Client::post(
  self : Client,
  url : StringView,
  extra_headers~ : Headers = {},
) -> ClientConnection {
  self.request(Post, url, extra_headers~)
}
