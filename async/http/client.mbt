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
///
/// If `Content-Length` is present in `extra_headers`,
/// it should be the total length of the request body.
/// The request body can still be sent incrementally,
/// but if the actual body being sent is shorter and longer than the provided length,
/// an error will be raised.
pub async fn Client::request_stream(
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
/// Perform a generic HTTP request with binary request body.
/// Server response header and collected response body will be returned.
///
/// See `@http.Client::request_stream` for more details on the optional parameters.
pub async fn Client::request_binary(
  self : Client,
  meth : RequestMethod,
  url : StringView,
  body : BytesView,
  extra_headers~ : Headers = {},
) -> (ResponseHeader, MessageBody) {
  let conn = self.request_stream(meth, url, extra_headers~)
  defer conn.close()
  conn.write(body)
  let response = conn.end_request()
  (response, conn.read_all())
}

///|
/// Perform a generic HTTP request with UTF-8 encoded text request body.
/// Server response header and collected response body will be returned.
///
/// See `@http.Client::request_stream` for more details on the optional parameters.
pub async fn Client::request_text(
  self : Client,
  meth : RequestMethod,
  url : StringView,
  body : StringView,
  extra_headers~ : Headers = {},
) -> (ResponseHeader, MessageBody) {
  let conn = self.request_stream(meth, url, extra_headers~)
  defer conn.close()
  conn.text.write(body)
  let response = conn.end_request()
  (response, conn.read_all())
}

///|
/// Perform a generic HTTP request with UTF-8 encoded JSON request body.
/// Server response header and collected response body will be returned.
///
/// See `@http.Client::request_stream` for more details on the optional parameters.
pub async fn Client::request_json(
  self : Client,
  meth : RequestMethod,
  url : StringView,
  body : @json.Json,
  extra_headers~ : Headers = {},
) -> (ResponseHeader, MessageBody) {
  let conn = self.request_stream(meth, url, extra_headers~)
  defer conn.close()
  conn.text.write(body.stringify())
  let response = conn.end_request()
  (response, conn.read_all())
}

///|
/// Perform a `GET` request on `url` through a HTTP client.
/// Return the response header and the client connection assigned for the request.
/// Content of response body can be read through the
/// `@io.BinaryReader` interface (or `@io.TextReader` interface through the builtin `.text` view)
/// on the connection. The connection must be closed after the connection become unused.
///
/// See `@http.Client::request` for more details on the optional parameters.
pub async fn Client::get_stream(
  self : Client,
  url : StringView,
  extra_headers~ : Headers = {},
) -> (ResponseHeader, ClientConnection) {
  let conn = self.request_stream(Get, url, extra_headers~)
  errdefer conn.close()
  let response = conn.end_request()
  (response, conn)
}

///|
/// Perform a HTTP `GET` request to `uri`.
/// Return response header and collect whole response body.
///
/// See `@http.Client::request` for more details.
pub async fn Client::get(
  self : Client,
  uri : StringView,
  extra_headers~ : Headers = Map([]),
) -> (ResponseHeader, MessageBody) {
  let (response, conn) = self.get_stream(uri, extra_headers~)
  defer conn.close()
  (response, conn.read_all())
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
pub async fn Client::put_stream(
  self : Client,
  url : StringView,
  extra_headers~ : Headers = {},
) -> ClientConnection {
  self.request_stream(Put, url, extra_headers~)
}

///|
/// Perform a `PUT` request on `url` with binary request body through a HTTP client.
/// Return the response header and collected response body.
///
/// See `@http.Client::request` for more details on the optional parameters.
pub async fn Client::put_binary(
  self : Client,
  uri : StringView,
  content : BytesView,
  extra_headers~ : Headers = Map([]),
) -> (ResponseHeader, MessageBody) {
  self.request_binary(Put, uri, content, extra_headers~)
}

///|
/// Perform a `PUT` request on `url` with UTF-8 encoded text request body through a HTTP client.
/// Return the response header and collected response body.
///
/// See `@http.Client::request` for more details on the optional parameters.
pub async fn Client::put_text(
  self : Client,
  uri : StringView,
  content : StringView,
  extra_headers~ : Headers = Map([]),
) -> (ResponseHeader, MessageBody) {
  self.request_text(Put, uri, content, extra_headers~)
}

///|
/// Perform a `PUT` request on `url` with UTF-8 encoded JSON request body through a HTTP client.
/// Return the response header and collected response body.
///
/// See `@http.Client::request` for more details on the optional parameters.
pub async fn Client::put_json(
  self : Client,
  uri : StringView,
  content : @json.Json,
  extra_headers~ : Headers = Map([]),
) -> (ResponseHeader, MessageBody) {
  self.request_json(Put, uri, content, extra_headers~)
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
pub async fn Client::post_stream(
  self : Client,
  url : StringView,
  extra_headers~ : Headers = {},
) -> ClientConnection {
  self.request_stream(Post, url, extra_headers~)
}

///|
/// Perform a `POST` request on `url` with binary request body through a HTTP client.
/// Return the response header and collected response body.
///
/// See `@http.Client::request` for more details on the optional parameters.
pub async fn Client::post_binary(
  self : Client,
  uri : StringView,
  content : BytesView,
  extra_headers~ : Headers = Map([]),
) -> (ResponseHeader, MessageBody) {
  self.request_binary(Post, uri, content, extra_headers~)
}

///|
/// Perform a `POST` request on `url` with UTF-8 encoded text request body through a HTTP client.
/// Return the response header and collected response body.
///
/// See `@http.Client::request` for more details on the optional parameters.
pub async fn Client::post_text(
  self : Client,
  uri : StringView,
  content : StringView,
  extra_headers~ : Headers = Map([]),
) -> (ResponseHeader, MessageBody) {
  self.request_text(Post, uri, content, extra_headers~)
}

///|
/// Perform a `POST` request on `url` with UTF-8 encoded JSON request body through a HTTP client.
/// Return the response header and collected response body.
///
/// See `@http.Client::request` for more details on the optional parameters.
pub async fn Client::post_json(
  self : Client,
  uri : StringView,
  content : @json.Json,
  extra_headers~ : Headers = Map([]),
) -> (ResponseHeader, MessageBody) {
  self.request_json(Post, uri, content, extra_headers~)
}
