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
priv enum ClientTransport {
  Plain(@socket.Tcp)
  Proxy(Client)
}

///|
/// Simple HTTP client which connect to a remote host via TCP
pub struct Client {
  /// A builtin text view for reading UTF-8 encoded response body
  /// and writing UTF-8 encoded request payload directly
  text : @io.Utf8TextView
  priv reader : Reader
  priv transport : ClientTransport
  priv tls : @tls.Tls?
  priv sender : Sender
  priv mut request_method : RequestMethod?
  /// whether automatic decompression should be enabled for current request
  priv mut auto_decompress : Bool
}

///|
/// Error raised when the proxy responded with a non-2XX response code
pub suberror ProxyError {
  ProxyError(Response)
} derive(@debug.Debug, @json.ToJson)

///|
async fn Client::connect(
  host : StringView,
  headers~ : Headers = Map([]),
  protocol~ : Protocol = Https,
  proxy? : Client,
  trust~ : @tls.TrustedRoot = SystemRoot,
) -> Client {
  let (hostname, port) = resolve_host(host, protocol~)
  let transport = if proxy is Some(proxy) {
    errdefer proxy.close()
    // CONNECT uses an authority, which keeps the brackets of an IPv6 address.
    let authority = if hostname.contains(":") {
      "[\{hostname}]:\{port}"
    } else {
      "\{hostname}:\{port}"
    }
    let response = proxy..request(Connect, authority).end_request()
    guard response.code is (200..<300) else { raise ProxyError(response) }
    proxy..skip_response_body().enter_passthrough_mode()
    Proxy(proxy)
  } else {
    Plain(@socket.Tcp::connect_to_host(hostname, port~))
  }
  errdefer transport.close()
  headers["Host"] = host.to_owned()
  // TODO: case insensitive check
  if !headers.contains("User-Agent") {
    headers["User-Agent"] = "moonbit-http-client/1.1"
  }
  let (tls, reader, sender) = match (protocol, transport) {
    (Http, Plain(conn)) =>
      (None, Reader::new(conn), Sender::new(conn, headers~))
    (Https, Plain(conn)) => {
      let tls = @tls.Tls::client(conn, host=hostname.to_owned(), trust~)
      (Some(tls), Reader::new(tls), Sender::new(tls, headers~))
    }
    (Http, Proxy(proxy)) =>
      (None, Reader::new(proxy), Sender::new(proxy, headers~))
    (Https, Proxy(proxy)) => {
      let tls = @tls.Tls::client(proxy, host=hostname.to_owned(), trust~)
      (Some(tls), Reader::new(tls), Sender::new(tls, headers~))
    }
  }
  let client = {
    text: @io.Utf8TextView::new_uninitialized(),
    transport,
    tls,
    reader,
    sender,
    request_method: None,
    auto_decompress: false,
  }
  client.text.set_inner(client)
  client
}

///|
/// Create a new HTTP client by connecting to a remote host.
/// Host should be specified via `protocol://host[:port]`,
/// where `protocol` is one of `http` or `https`.
/// If `protocol` is `https`, a TLS connection will be established,
/// and the certificate of the remote peer will be verified.
///
/// If the protocol is `https`, `trust` will determine the trusted root for cert validation.
/// See `@tls.TrustedRoot` for more details.
///
/// `headers` can be used to specify persistent headers for the client,
/// i.e. all requests made from this client will share these headers.
/// The ownership of `headers` will be transferred to the new client,
/// so `headers` should not be used by the caller later.
/// The following headers is automatically set,
/// and must not be specified in `headers`:
///
/// - Host
/// - Content-Length, Transfer-Encoding
///
/// If `proxy` is present, it should be another HTTP client in a clean state.
/// The new client will send a `CONNECT` request via the proxy client
/// and try to establish a tunnel via the proxy client.
/// All subsequent requests made by the new client will go through the proxy tunnel.
/// The ownership of the proxy client is transferred to the new client,
/// so it must not be used nor closed anymore by the caller.
/// Using another HTTP client as proxy allows advanced features such as
/// proxy authentication and https `CONNECT` proxy.
#alias(new, deprecated)
pub async fn Client::Client(
  uri : String,
  headers~ : Headers = Map([]),
  proxy? : Client,
  trust? : @tls.TrustedRoot,
) -> Client {
  let (protocol, host, path) = resolve_url(uri)
  guard path is "/" else { raise InvalidFormat }
  Client::connect(host, protocol~, headers~, proxy?, trust?)
}

///|
fn ClientTransport::close(self : ClientTransport) -> Unit {
  match self {
    Plain(conn) => conn.close()
    Proxy(proxy) => proxy.close()
  }
}

///|
/// Close a HTTP client and release underlying resource.
/// In particular close the underlying TCP connection.
/// This function is idempotent: it is safe to call `.close()` multiple times,
/// only the first `.close()` call takes effect.
pub fn Client::close(self : Client) -> Unit {
  if self.tls is Some(tls) {
    tls.close()
  }
  self.text.close()
  self.transport.close()
}

///|
pub impl @io.BinaryReader for Client

///|
impl @io.BinaryReaderImpl for Client with fn raw_read_impl(
  self,
  buf,
  offset~,
  max_len~,
) {
  @io.BinaryReaderImpl::raw_read_impl(self.reader, buf, offset~, max_len~)
}

///|
impl @io.BinaryReaderImpl for Client with fn get_controller(self) {
  @io.BinaryReaderImpl::get_controller(self.reader)
}

///|
pub extend Client with @io.BinaryReader::{
  read_into,
  read,
  read_at_least,
  peek,
  peek_at_least,
  read_exactly,
  drop_exactly,
  peek_exactly,
  read_all,
  drop_all,
  read_until,
  peek_until,
}

///|
/// Get the trailer of current response message.
///
/// MUST be called AFTER all content of current message body has been read,
/// and BEFORE reading the next response, otherwise this method will crash immediately.
///
/// If the message is not chunk encoded, an empty header map will be returned.
pub fn Client::trailer(self : Client) -> Headers {
  self.reader.trailer.unwrap()
}

///|
/// Write data to the body of the request currently being sent.
/// All writer API must be called after `send_request`.
/// `end_request` must be called after all content of response body has been sent.
///
/// Writing to `@http.Client` MAY be buffered,
/// call `flush` manually to ensure data is delivered to the remote peer.
pub impl @io.BinaryWriter for Client

///|
impl @io.BinaryWriterImpl for Client with fn raw_write_impl(
  self,
  buf,
  offset~,
  len~,
) {
  guard! !(self.sender.mode is SendingHeader)
  @io.BinaryWriterImpl::raw_write_impl(self.sender, buf, offset~, len~)
}

///|
impl @io.BinaryWriterImpl for Client with fn get_controller(self) {
  @io.BinaryWriterImpl::get_controller(self.sender)
}

///|
pub impl @io.BinaryWriter for Client with fn write_reader(self, reader) {
  guard! !(self.sender.mode is SendingHeader)
  self.sender.write_reader(reader)
}

///|
pub extend Client with @io.BinaryWriter::{write, write_reader}

///|
/// Flush buffered data in the request body being sent, if any.
pub async fn Client::flush(self : Client) -> Unit {
  self.sender.flush()
}

///|
/// End the body of the request currently being sent,
/// and obtain response from the server.
/// Should be called immediately after request body is fully sent.
///
/// Only the header of the response will be received and returned,
/// the response body can be read through `Client` as an `@io.BinaryReader`,
/// or through `client.text` as an `@io.TextReader`.
///
/// If the body of the last response is still not consumed,
/// it will be discarded.
///
/// `1XX` response, except for `101 Switching Protocol`,
/// will be automatically processed and discarded,
/// and the returned response is always the final response (or `101`).
/// `on_informational_response`, if present,
/// will be invoked for every skipped `1XX` informational response.
pub async fn Client::end_request(
  self : Client,
  on_informational_response? : async (Response) -> Unit,
) -> Response {
  self.sender.end_body()
  for ;; {
    self.reader.skip_body()
    let response = self.reader.read_response(
      request_method=self.request_method,
      auto_decompress=self.auto_decompress,
    )
    if response.code is (100 | 102..<200) {
      if on_informational_response is Some(callback) {
        callback(response)
      }
      continue
    }
    self.request_method = None
    self.auto_decompress = false
    break response
  }
}

///|
/// Send a HTTP request to the server.
/// Only the header of the request will be sent,
/// the request body can be sent through `Client` as an `@io.BinaryWriter`,
/// or through `client.text` as an `@io.TextWriter`.
/// Once request body has been sent,
/// `end_request` must be called to complete the request and obtain response from the server.
///
/// After performing a request,
/// the next request MUST NOT be made before the request is completed via `end_request`.
///
/// In addition to headers in `Client::connect`,
/// extra HTTP headers can be passed via `extra_headers`.
/// The following headers is automatically set by `request`,
/// and must not be specified in `extra_headers`:
///
/// - Host
/// - Transfer-Encoding
///
/// The following headers can only be set globally for each client on initialization,
/// and must not be set on a per-request basis:
///
/// - User-Agent
///
/// If `Content-Length` is present in `extra_headers`,
/// it should be the total length of the request body.
/// The request body can still be sent incrementally,
/// but if the actual body being sent is shorter and longer than the provided length,
/// an error will be raised.
pub async fn Client::request(
  self : Client,
  meth : RequestMethod,
  path : StringView,
  extra_headers~ : Headers = Map([]),
) -> Unit {
  self.auto_decompress = self.sender.send_request(meth, path, extra_headers~)
  self.request_method = Some(meth)
}

///|
/// Skip the body of the response currently being produced,
/// so that the next request can be made.
pub async fn Client::skip_response_body(self : Client) -> Unit {
  self.reader.skip_body()
}

///|
/// Perform a `GET` request to the server, see `Client::request` for more details.
pub async fn Client::get(
  self : Client,
  path : String,
  extra_headers~ : Headers = Map([]),
) -> Response {
  self..request(Get, path, extra_headers~).end_request()
}

///|
/// Perform a `PUT` request to the server with binary payload.
/// See `Client::request` for more details.
pub async fn Client::put_binary(
  self : Client,
  path : String,
  body : BytesView,
  extra_headers~ : Headers = Map([]),
) -> Response {
  self..request(Put, path, extra_headers~)..write(body).end_request()
}

///|
/// Perform a `PUT` request to the server with UTF-8 encoded text payload.
/// See `Client::request` for more details.
pub async fn Client::put_text(
  self : Client,
  path : String,
  body : StringView,
  extra_headers~ : Headers = Map([]),
) -> Response {
  self.request(Put, path, extra_headers~)
  self.text.write(body)
  self.end_request()
}

///|
/// Perform a `PUT` request to the server with UTF-8 encoded text JSON payload.
/// See `Client::request` for more details.
pub async fn Client::put_json(
  self : Client,
  path : String,
  body : Json,
  extra_headers~ : Headers = Map([]),
) -> Response {
  self.request(Put, path, extra_headers~)
  self.text.write(body.stringify())
  self.end_request()
}

///|
/// Perform a `POST` request to the server with binary payload.
/// See `Client::request` for more details.
pub async fn Client::post_binary(
  self : Client,
  path : String,
  body : BytesView,
  extra_headers~ : Headers = Map([]),
) -> Response {
  self..request(Post, path, extra_headers~)..write(body).end_request()
}

///|
/// Perform a `POST` request to the server with UTF-8 encoded text payload.
/// See `Client::request` for more details.
pub async fn Client::post_text(
  self : Client,
  path : String,
  body : StringView,
  extra_headers~ : Headers = Map([]),
) -> Response {
  self.request(Post, path, extra_headers~)
  self.text.write(body)
  self.end_request()
}

///|
/// Perform a `POST` request to the server with UTF-8 encoded text JSON payload.
/// See `Client::request` for more details.
pub async fn Client::post_json(
  self : Client,
  path : String,
  body : Json,
  extra_headers~ : Headers = Map([]),
) -> Response {
  self.request(Post, path, extra_headers~)
  self.text.write(body.stringify())
  self.end_request()
}

///|
/// Let the client enter "pass through" mode,
/// where the client serve as a TCP tunnel (maybe TLS encrypted) directly.
/// This is useful for the special `CONNECT` HTTP request and HTTP protocol upgrade.
///
/// In passthrough mode,
/// Read/write the client becomes direct read/write on the underlying connection,
/// and only its `@io.BinaryReader` and `@io.BinaryWriter` APIs may be used.
///
/// When entering pass through mode,
/// the client must be in a clean state
/// (i.e. not in the middle of sending a request).
/// Unread data from the body of the last response will be discarded.
pub async fn Client::enter_passthrough_mode(self : Client) -> Unit {
  guard! self.sender.mode is SendingHeader
  self.reader.enter_passthrough_mode()
  self.sender.enter_passthrough_mode()
}
