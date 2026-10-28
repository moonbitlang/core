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
/// A single HTTP server connection
pub struct ServerConnection {
  /// A builtin text view for reading UTF-8 request bodies
  /// and writing UTF-8 response payloads
  text : @io.Utf8TextView
  priv reader : Reader
  priv conn : @socket.Tcp
  priv sender : Sender
  priv mut closed : Bool
  priv mut request_method : RequestMethod
}

///|
/// Create a new HTTP server connection from a TCP connection.
///
/// `headers` can be used to specify persistent headers for the connection,
/// i.e. all response sent by this connection will share these headers.
/// The following headers is automatically set,
/// and must not be specified in `headers`:
/// 
/// - Content-Length, Transfer-Encoding
pub fn ServerConnection::new(
  conn : @socket.Tcp,
  headers~ : Headers = Map([]),
) -> ServerConnection {
  let conn = {
    text: @io.Utf8TextView::new_uninitialized(),
    reader: Reader::new(conn),
    conn,
    sender: Sender::new(conn, headers~),
    closed: false,
    request_method: Get,
  }
  conn.text.set_inner(conn)
  conn
}

///|
/// Close the connection, the underlying TCP connection will be closed as well.
/// This function is idempotent: it is safe to call `.close()` multiple times,
/// only the first `.close()` call takes effect.
pub fn ServerConnection::close(self : ServerConnection) -> Unit {
  self.text.close()
  if !self.closed {
    self.closed = true
    self.conn.close()
  }
}

///|
/// Get the address of client from a HTTP server connection
pub fn ServerConnection::client_addr(self : ServerConnection) -> @socket.Addr {
  self.conn.addr()
}

///|
pub impl @io.BinaryReader for ServerConnection

///|
impl @io.BinaryReaderImpl for ServerConnection with fn raw_read_impl(
  self,
  buf,
  offset~,
  max_len~,
) {
  @io.BinaryReaderImpl::raw_read_impl(self.reader, buf, offset~, max_len~)
}

///|
impl @io.BinaryReaderImpl for ServerConnection with fn get_controller(self) {
  @io.BinaryReaderImpl::get_controller(self.reader)
}

///|
pub extend ServerConnection with @io.BinaryReader::{
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
/// Get the trailer of current request message.
///
/// MUST be called AFTER all content of current message body has been read,
/// and BEFORE reading the next request, otherwise this method will crash immediately.
///
/// If the message is not chunk encoded, an empty header map will be returned.
pub fn ServerConnection::trailer(self : ServerConnection) -> Headers {
  self.reader.trailer.unwrap()
}

///|
/// Read a single request from the connection.
/// If the body of the last request is not consumed yet,
/// it will be discarded.
///
/// After calling `read_request`,
/// the body of the request can be obtained by using `ServerConnection`
/// as an `@io.BinaryReader`, or through `.text` as an `@io.TextReader`.
pub async fn ServerConnection::read_request(
  self : ServerConnection,
) -> RequestHeader {
  self.reader.skip_body()
  let request = self.reader.read_request()
  self.request_method = request.meth
  request
}

///|
/// Manually discard the body of the request currently being processed.
pub async fn ServerConnection::skip_request_body(
  self : ServerConnection,
) -> Unit {
  self.reader.skip_body()
}

///|
/// Write data to the body of the response currently being sent.
/// Writer API must be called after `send_response`.
/// `end_response` must be called after all content of response body has been sent.
///
/// Writing to `@http.ServerConnection` MAY be buffered,
/// call `flush` manually to ensure data is delivered to the remote peer.
pub impl @io.BinaryWriter for ServerConnection

///|
impl @io.BinaryWriterImpl for ServerConnection with fn raw_write_impl(
  self,
  buf,
  offset~,
  len~,
) {
  guard! !(self.sender.mode is SendingHeader)
  @io.BinaryWriterImpl::raw_write_impl(self.sender, buf, offset~, len~)
}

///|
impl @io.BinaryWriterImpl for ServerConnection with fn get_controller(self) {
  @io.BinaryWriterImpl::get_controller(self.sender)
}

///|
/// Integrate a `@http.ServerConnection` with string interpolation syntax
pub async fn[X : Show] ServerConnection::write_string_interpolation(
  self : ServerConnection,
  data : X,
) -> Unit {
  self.text.write(data.to_string())
}

///|
/// Introduced so that the sugar `writer <+ "hello \{world}"` can work on `ServerConnection`.
/// Performance will be improved in the future
pub async fn ServerConnection::write_string(
  self : ServerConnection,
  s : String,
) -> Unit {
  self.text.write(s)
}

///|
pub impl @io.BinaryWriter for ServerConnection with fn write_reader(
  self,
  reader,
) {
  guard! !(self.sender.mode is SendingHeader)
  self.sender.write_reader(reader)
}

///|
pub extend ServerConnection with @io.BinaryWriter::{write, write_reader}

///|
/// Flush buffered data in the response body being sent, if any.
pub async fn ServerConnection::flush(self : ServerConnection) -> Unit {
  self.sender.flush()
}

///|
/// End the body of the response currently being sent.
/// Should be called immediately after response body is fully sent.
pub async fn ServerConnection::end_response(self : ServerConnection) -> Unit {
  self.sender.end_body()
}

///|
/// Send a response to the peer.
/// The response body can then be sent through `ServerConnection` as an
/// `@io.BinaryWriter`, or through `.text` as an `@io.TextWriter`.
/// After calling `send_response`,
/// `end_response` must be called before sending the next response.
///
/// `cookies`, if present, specify a list of cookies that the server wish the client to set.
/// They will be transferred to the client via the `Set-Cookie` HTTP header.
/// Users should always set cookies via `cookies` instead of filling `Set-Cookie` header directly.
///
/// If `Content-Length` is present in `extra_headers`,
/// it should be the total length of the request body.
/// This useful for, for example, file servers to allow
/// clients to know the progress of download, perform multipart download etc.
///
/// The request body can still be sent incrementally,
/// but if the actual body being sent is shorter and longer than the provided length,
/// an error will be raised.
pub async fn ServerConnection::send_response(
  self : ServerConnection,
  code : Int32,
  reason : String,
  extra_headers~ : Headers = Map([]),
  cookies~ : Array[Cookie] = [],
) -> Unit {
  self.sender.send_response(
    code,
    reason,
    extra_headers~,
    cookies~,
    request_method=self.request_method,
  )
}

///|
/// A HTTP server
pub struct Server {
  addr : @socket.Addr
  priv server : @socket.TcpServer
  priv headers : Headers
}

///|
/// Create a new HTTP server listening on `addr`.
///
/// The meaning of `dual_stack` and `reuse_addr` is the same as
/// `@socket.TcpServer::new()`, see there for more details.
///
/// `headers` can be used to specify common headers
/// shared by all responses sent by this server.
#alias(new, deprecated)
pub async fn Server::Server(
  addr : @socket.Addr,
  dual_stack? : Bool,
  reuse_addr? : Bool,
  headers~ : Headers = Map([]),
) -> Server {
  let server = @socket.TcpServer(addr, dual_stack?, reuse_addr?)
  { addr: server.addr, server, headers, }
}

///|
/// Close a HTTP server, release associated resource
pub fn Server::close(self : Server) -> Unit {
  self.server.close()
}

///|
/// Accept a new connection from a HTTP server.
/// Return the new HTTP connection and the address of peer.
pub async fn Server::accept(self : Server) -> (ServerConnection, @socket.Addr) {
  let (conn, addr) = self.server.accept()
  (ServerConnection::new(conn, headers=self.headers), addr)
}

///|
/// Start the main loop of a HTTP server,
/// the server will keep listening for new connections
/// and new requests from existing connections.
/// Requests are handled by the callback function `f`.
///
/// - header of the request to process
/// - a `@http.ServerConnection` that can be used to read request body or send response.
///
/// Content of the incoming request body can be read streamingly
/// using `@io.BinaryReader` interface (or `@io.TextReader` interface through the builtin `.text` view)
/// on the `@http.ServerConnection` directly.
///
/// The procedure to send a response is:
/// 1. initiate a response and send response header via `.send_response()`
/// 2. send the response body through `@http.ServerConnection` as an
///    `@io.BinaryWriter`, or through `.text` as an `@io.TextWriter`
/// 3. (optional) complete the response via `.end_response()`.
///     If `.end_response()` is not called, it will be called automatically
///     after `f` returns.
///
/// If `allow_failure` is `true` (`true` by default),
/// error raised by `f` will not crash the whole server.
/// In this case, `run_forever` will only terminate when cancelled externally.
/// Note that if `f` fails, the connection used by `f` will still get aborted.
///
/// If `max_connections` is present,
/// at most `max_connections` clients are allowed in parallel.
/// New clients will only get handled after a previous client terminates.
///
/// If `f` fails without closing the connection, 
/// `run_forever` will close each connection automatically.
/// If `f` manually closes the connection,
/// the connection will be dropped after `f` returns.
/// On error or cancellation, the server will be closed automatically.
pub async fn Server::run_forever(
  self : Server,
  f : async (RequestHeader, ServerConnection) -> Unit,
  allow_failure? : Bool,
  max_connections? : Int32,
) -> Unit {
  self.server.run_forever(allow_failure?, max_connections?) <| ((conn, _) => {
    let conn = ServerConnection::new(conn, headers=self.headers)
    defer conn.close()
    for ;; {
      let request = conn.read_request()
      f(request, conn)
      if conn.closed {
        break
      } else if conn.sender.mode
        is (WaitingResponseBody | SendingFixed(_) | SendingBody) {
        conn.end_response()
      }
    }
  })
}

///|
/// Let the server enter "pass through" mode,
/// where the server serve as a TCP tunnel (maybe TLS encrypted) directly.
/// This is useful for handling the special `CONNECT` HTTP request and HTTP protcol upgrade.
///
/// In passthrough mode,
/// Read/write the server becomes direct read/write on the underlying connection,
/// and only its `@io.BinaryReader` and `@io.BinaryWriter` APIs may be used.
///
/// When entering pass through mode,
/// the server must be in a clean state
/// (i.e. not in the middle of sending a response).
/// Unread data from the body of the last request will be discarded.
pub async fn ServerConnection::enter_passthrough_mode(self : Self) -> Unit {
  guard! self.sender.mode is SendingHeader
  self.reader.enter_passthrough_mode()
  self.sender.enter_passthrough_mode()
}
