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
#external
priv type JsHeaders

///|
extern "js" fn JsHeaders::new() -> JsHeaders =
  #| () => new Headers()

///|
extern "js" fn JsHeaders::append(
  headers : JsHeaders,
  name : String,
  value : String,
) =
  #| (headers, name, value) => headers.append(name, value)

///|
extern "js" fn JsHeaders::to_array(
  headers : JsHeaders,
) -> FixedArray[FixedArray[String]] =
  #| (headers) => Array.from(headers.entries())

///|
#external
priv type JsResponse

///|
extern "js" fn JsResponse::status(response : JsResponse) -> Int32 =
  #| (response) => response.status

///|
extern "js" fn JsResponse::status_text(response : JsResponse) -> String =
  #| (response) => response.statusText

///|
extern "js" fn JsResponse::headers(response : JsResponse) -> JsHeaders =
  #| (response) => response.headers

///|
extern "js" fn JsResponse::body(
  response : JsResponse,
) -> @js_async.JsReadableStream =
  #| (response) => response.body ?? new ReadableStream({
  #|   start(controller) { controller.close() },
  #| })

///|
priv struct OngoingRequest {
  meth : String
  uri : String
  body : @buffer.Buffer
  ctrl : @io.BinaryWriterController
  headers : JsHeaders
}

///|
/// Simple HTTP client which connect to a remote host, backed by JavaScript fetch API
pub struct ClientConnection {
  /// A builtin text view for reading UTF-8 response bodies
  /// and writing UTF-8 request payloads
  text : @io.Utf8TextView
  priv host : String
  priv protocol : Protocol
  priv headers : Headers
  priv mut request : OngoingRequest?
  priv mut response_body : @js_async.ReadableStream?
}

///|
/// Close a HTTP client connection and release underlying resource.
/// In particular close the underlying TCP connection.
/// This function is idempotent: it is safe to call `.close()` multiple times,
/// only the first `.close()` call takes effect.
pub fn ClientConnection::close(self : ClientConnection) -> Unit {
  self.text.close()
  self.request = None
  if self.response_body is Some(response_body) {
    response_body.close()
  }
}

///|
fn ClientConnection::connect(
  host : String,
  headers~ : Headers = Map([]),
  protocol~ : Protocol = Https,
  proxy? : ClientConnection,
  trust~ : @tls.TrustedRoot = SystemRoot,
) -> ClientConnection {
  ignore(proxy)
  ignore(trust)
  let client = {
    text: @io.Utf8TextView::new_uninitialized(),
    host,
    headers,
    protocol,
    request: None,
    response_body: None,
  }
  client.text.set_inner(client)
  client
}

///|
/// Create a new HTTP client by connecting to a remote host.
/// Host should be specified via `protocol://host[:port]`,
/// where `protocol` is one of `http` or `https`.
///
/// `headers` can be used to specify persistent headers for the client,
/// i.e. all requests made from this client will share these headers.
/// The ownership of `headers` will be transferred to the new client,
/// so `headers` should not be used by the caller later.
/// The headers mentioned in
/// https://developer.mozilla.org/en-US/docs/Glossary/Forbidden_request_header
/// must not be set in `headers`.
///
/// The HTTP client make requests using native fetch API.
///
/// The `proxy` argument is not supported on JavaScript backend and has no effect.
///
/// `trust` is ignored on JS backend
#warnings("-unused_async")
#alias(new, deprecated)
#label_migration(trust, fill=false, msg="`trust` is unsupported on JS backend")
pub async fn ClientConnection::ClientConnection(
  uri : String,
  headers~ : Headers = Map([]),
  proxy? : ClientConnection,
  trust~ : @tls.TrustedRoot = SystemRoot,
) -> ClientConnection {
  ignore(proxy)
  let (protocol, host, path) = resolve_url(uri)
  guard path is "/" else { raise InvalidFormat }
  ClientConnection::connect(host, protocol~, headers~, proxy?, trust~)
}

///|
pub impl @io.BinaryWriter for ClientConnection

///|
impl @io.BinaryWriterImpl for ClientConnection with fn raw_write_impl(
  self,
  buf,
  offset~,
  len~,
) {
  guard! self.request is Some(request)
  request.body.write_bytes(buf[offset:offset + len])
  len
}

///|
impl @io.BinaryWriterImpl for ClientConnection with fn get_controller(self) {
  guard! self.request is Some(request)
  request.ctrl
}

///|
pub extend ClientConnection with @io.BinaryWriter::{write, write_reader}

///|
/// Currently, HTTP client does not support streaming request body writing on JS backend.
/// So request body is always buffered and `.flush()` has no effect at all.
#warnings("-unused_async")
pub async fn ClientConnection::flush(_ : ClientConnection) -> Unit {
  // no need to flush in JS backend
  ()
}

///|
pub impl @io.BinaryReader for ClientConnection

///|
impl @io.BinaryReaderImpl for ClientConnection with fn get_controller(self) {
  guard! self.response_body is Some(stream)
  @io.BinaryReaderImpl::get_controller(stream as &@io.BinaryReader)
}

///|
impl @io.BinaryReaderImpl for ClientConnection with fn raw_read_impl(
  self,
  buf,
  offset~,
  max_len~,
) {
  guard! self.response_body is Some(stream)
  @io.BinaryReaderImpl::raw_read_impl(
    stream as &@io.BinaryReader,
    buf,
    offset~,
    max_len~,
  )
}

///|
pub extend ClientConnection with @io.BinaryReader::{
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
/// End the body of the request currently being sent,
/// and obtain response from the server.
/// Should be called immediately after request body is fully sent.
///
/// Only the header of the response will be received and returned,
/// the response body can be read through `ClientConnection` as an `@io.BinaryReader`,
/// or through `client.text` as an `@io.TextReader`.
///
/// If the body of the last response is still not consumed,
/// it will be discarded.
///
/// `on_informational_response` is not supported on JS backend,
/// and will be silently ignored.
pub async fn ClientConnection::end_request(
  self : ClientConnection,
  on_informational_response? : async (ResponseHeader) -> Unit,
) -> ResponseHeader {
  ignore(on_informational_response)
  guard! self.request is Some(request)
  self.request = None
  let abort_controller = @js_async.AbortController::new()
  let js_response = ClientConnection::request_ffi(
    request.uri,
    request.meth,
    headers=request.headers,
    body=request.body.contents(),
    signal=abort_controller.signal(),
  ).wait(abort_controller~)
  self.response_body = Some(
    @js_async.ReadableStream::from_js(js_response.body()),
  )
  let headers : Headers = Map([])
  for entry in js_response.headers().to_array() {
    headers[entry[0]] = entry[1]
  }
  {
    code: js_response.status(),
    reason: js_response.status_text(),
    headers,
    cookies: [],
  }
}

///|
extern "js" fn ClientConnection::request_ffi(
  uri : String,
  meth : String,
  headers~ : JsHeaders,
  body~ : Bytes,
  signal~ : @js_async.AbortSignal,
) -> @js_async.Promise[JsResponse] =
  #| (uri, method, headers, body, signal) => {
  #|   const fixed_body = (method === "GET" || method === "HEAD") ? null : body
  #|   return fetch(
  #|     uri,
  #|     {
  #|       body: fixed_body,
  #|       method: method,
  #|       headers: headers,
  #|       signal: signal,
  #|     },
  #|   )
  #| }

///|
/// Send a HTTP request to the server.
/// Only the header of the request will be sent,
/// the request body can be sent through `ClientConnection` as an `@io.BinaryWriter`,
/// or through `client.text` as an `@io.TextWriter`.
/// Once request body has been sent,
/// `end_request` must be called to complete the request and obtain response from the server.
///
/// After performing a request,
/// the next request MUST NOT be made before the request is completed via `end_request`.
///
/// In addition to headers in `ClientConnection::new`,
/// extra HTTP headers can be passed via `extra_headers`.
/// The headers mentioned in
/// https://developer.mozilla.org/en-US/docs/Glossary/Forbidden_request_header
/// must not be set in `extra_headers`.
#warnings("-unused_async")
pub async fn ClientConnection::request(
  self : ClientConnection,
  meth : RequestMethod,
  path : StringView,
  extra_headers~ : Headers = Map([]),
) -> Unit {
  guard! self.request is None
  let protocol = match self.protocol {
    Http => "http://"
    Https => "https://"
  }
  let path = if path is ['/', ..] { path } else { "/\{path}" }
  let uri = "\{protocol}\{self.host}\{path}"
  let meth = match meth {
    Get => "GET"
    Head => "HEAD"
    Post => "POST"
    Put => "PUT"
    Delete => "DELETE"
    Connect => "CONNECT"
    Options => "OPTIONS"
    Trace => "TRACE"
    Patch => "PATCH"
    Extension(ext) => {
      guard ext.length() > 0 else { raise InvalidMethod(ext) }
      for c in ext.code_units() {
        guard is_token_char(c) else { raise InvalidMethod(ext) }
      }
      ext
    }
  }
  let headers = JsHeaders::new()
  for k, v in self.headers {
    headers.append(k.0, v)
  }
  for k, v in extra_headers {
    headers.append(k.0, v)
  }
  let request : OngoingRequest = {
    meth,
    uri,
    headers,
    body: Buffer(),
    ctrl: BinaryWriterController(),
  }
  self.request = Some(request)
}
