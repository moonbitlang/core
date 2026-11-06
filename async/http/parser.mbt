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
priv enum BodyKind {
  Empty
  Fixed(UInt64)
  Chunked(UInt64)
  PassThrough
  WaitConnectionClose
}

///|
/// A HTTP reader type that can parse and deliver HTTP request/response
priv struct Reader {
  mut body : BodyKind
  transport : &@io.BinaryReader
  ctrl : @io.BinaryReaderController
  mut auto_decompress : Bool
  mut gzip : @gzip.Decoder?
  mut trailer : Headers?
}

///|
/// Create a new HTTP reader wrapping around existing reader `transport`.
/// The HTTP reader will read data from `transport`.
fn[R : @io.BinaryReader] Reader::new(transport : R) -> Reader {
  {
    body: Empty,
    transport,
    ctrl: BinaryReaderController(),
    auto_decompress: false,
    gzip: None,
    trailer: None,
  }
}

///|
/// Error raised when an invalid HTTP message is processed
#derive(@debug.Debug, @json.ToJson)
pub suberror HttpProtocolError {
  BadRequest
  HttpVersionNotSupported(String)
  NotImplemented
}

///|
/// Maximum size in bytes of a header section as sent on the wire: the start
/// line and the header fields, or the trailer fields, each with its CRLF,
/// plus the empty line that ends the section.
const MAX_HEADER_SECTION_SIZE = 65536

///|
/// Maximum number of fields in a header section or a trailer section.
const MAX_HEADER_COUNT = 256

///|
/// Maximum size in bytes of a chunk-size line, including chunk extensions.
const MAX_CHUNK_LINE_SIZE = 4096

///|
/// Parse `1*DIGIT`, as used by `Content-Length` and the status code.
/// Unlike `@string.parse_uint64`, no sign, base prefix or `_` is accepted.
fn parse_http_decimal(s : StringView) -> UInt64 raise HttpProtocolError {
  guard !s.is_empty() else { raise BadRequest }
  let mut value = 0UL
  for c in s.code_units() {
    guard c is ('0'..<='9') else { raise BadRequest }
    let digit = (c.to_int() - '0'.to_int()).to_uint64()
    guard value <= (0xFFFF_FFFF_FFFF_FFFFUL - digit) / 10 else {
      raise BadRequest
    }
    value = value * 10 + digit
  }
  value
}

///|
/// Parse `1*HEXDIG`, as used by the chunk size.
/// Unlike `@string.parse_uint64`, no sign, `0x` prefix or `_` is accepted.
fn parse_http_hex(s : StringView) -> UInt64 raise HttpProtocolError {
  guard !s.is_empty() else { raise BadRequest }
  let mut value = 0UL
  for c in s.code_units() {
    let digit = match c {
      '0'..<='9' => c.to_int() - '0'.to_int()
      'a'..<='f' => c.to_int() - 'a'.to_int() + 10
      'A'..<='F' => c.to_int() - 'A'.to_int() + 10
      _ => raise BadRequest
    }
    guard value >> 60 == 0 else { raise BadRequest }
    value = (value << 4) | digit.to_uint64()
  }
  value
}

///|
/// Whether `b` is a control character not allowed in a field value or a
/// reason phrase (everything below SP except HTAB, and DEL).
fn is_forbidden_ctl(b : Byte) -> Bool {
  (b < b' ' && b != b'\t') || b == b'\x7f'
}

///|
/// Read a CRLF-terminated line from the transport, without the CRLF.
/// Raise `BadRequest` if the line is longer than `max_len` bytes,
/// and `ReaderClosed` if the transport ends before the CRLF.
async fn Reader::read_line(self : Reader, max_len : Int32) -> Bytes {
  let controller = @io.BinaryReaderImpl::get_controller(self.transport)
  for searched = 0 {
    let data = controller.buffered()
    if data[searched:].find(b"\r\n") is Some(index) {
      let len = searched + index
      guard len <= max_len else { raise BadRequest }
      let line = data[:len].to_owned()
      self.transport.drop_exactly(len + 2)
      break line
    }
    // a line of `max_len` bytes plus the CR of its CRLF
    guard data.length() <= max_len + 1 else { raise BadRequest }
    guard @io.BinaryReaderImpl::ensure_buffered(
      self.transport,
      data.length() + 1,
    ) else {
      raise @io.ReaderClosed
    }
    // the CR of the CRLF may be the last byte already searched
    continue @cmp.maximum(data.length() - 1, 0)
  }
}

///|
/// Decode some data from current chunk, perform gzip decompression if necessary.
/// At most `limit` bytes of data will be read from the underlying transport,
/// and decoded into `buf[offset:offset+max_len]`.
async fn Reader::decode_chunk(
  self : Reader,
  buf : FixedArray[Byte],
  offset~ : Int32,
  max_len~ : Int32,
  limit~ : Int32,
) -> (Int32, Int32) {
  guard self.gzip is Some(gzip) else {
    let max_len = @cmp.minimum(max_len, limit)
    let n = self.transport.read_into(buf, offset~, max_len~)
    (n, n)
  }

  let controller = @io.BinaryReaderImpl::get_controller(self.transport)
  for consumed = 0; !gzip.is_finished(); {
    let limit = limit - consumed
    let min_len = gzip.minimum_input_size()
    let target = @cmp.minimum(min_len, limit)

    // Read from underlying transport until we have enough data to make progress
    guard @io.BinaryReaderImpl::ensure_buffered(self.transport, target) else {
      raise BadRequest
    }

    let data = controller.buffered()
    let available = @cmp.minimum(data.length(), limit)
    if limit < min_len {
      gzip.write_partial_data(
        data.data(),
        input_offset=data.start_offset(),
        input_len=available,
      )
      self.transport.drop_exactly(available)
      let consumed = consumed + available
      break (consumed, 0)
    }

    // Perform the decoding
    let (new_consumed, produced) = gzip.write(
      data.data(),
      input_offset=data.start_offset(),
      input_len=available,
      buf,
      output_offset=offset,
      output_len=max_len,
    )
    self.transport.drop_exactly(new_consumed)
    let consumed = consumed + new_consumed
    if produced > 0 {
      break (consumed, produced)
    } else {
      continue consumed
    }
  } nobreak {
    guard consumed > 0 else { raise BadRequest }
    (consumed, 0)
  }
}

///|
impl @io.BinaryReader for Reader

///|
/// Read from the body of the HTTP request/response
/// that is currently being processed by the HTTP reader.
/// All reader related API of `HttpReader` should be called
/// after a successful call to `read_request` or `read_response`,
/// otherwise reading always result in EOF.
impl @io.BinaryReaderImpl for Reader with fn raw_read_impl(
  self,
  buf,
  offset~,
  max_len~,
) {
  match self.body {
    Empty => 0
    Fixed(remaining) => {
      let limit = @cmp.minimum(remaining, @int.MAX_VALUE.to_uint64()).to_int()
      let (consumed, produced) = self.decode_chunk(
        buf,
        offset~,
        max_len~,
        limit~,
      )
      if consumed is 0 && produced is 0 {
        raise @io.ReaderClosed
      }
      let remaining = remaining - consumed.to_uint64()
      self.body = if remaining == 0 {
        if self.gzip is Some(gzip) {
          guard gzip.is_finished() else { raise BadRequest }
          self.gzip = None
        }
        self.trailer = Some({})
        Empty
      } else {
        Fixed(remaining)
      }
      if produced == 0 && !(self.body is Empty) {
        @io.BinaryReaderImpl::raw_read_impl(self, buf, offset~, max_len~)
      } else {
        produced
      }
    }
    Chunked(0) => {
      let len_bytes = self.read_line(MAX_CHUNK_LINE_SIZE)
      let len_str = @utf8.decode(len_bytes)
      let len_str = if len_str.find(";") is Some(semi_index) {
        validate_chunk_extension(len_str[semi_index:])
        len_str[:semi_index].trim_end(chars=" \t")
      } else {
        len_str
      }
      let next_chunk_len = parse_http_hex(len_str)
      guard next_chunk_len > 0 else {
        let (trailer, cookies) = self.read_headers(MAX_HEADER_SECTION_SIZE)
        guard cookies.is_empty() else { raise BadRequest }
        if self.gzip is Some(gzip) {
          guard gzip.is_finished() else { raise BadRequest }
          self.gzip = None
        }
        self.body = Empty
        self.trailer = Some(trailer)
        return 0
      }
      let limit = @cmp.minimum(next_chunk_len, @int.MAX_VALUE.to_uint64()).to_int()
      let (consumed, produced) = self.decode_chunk(
        buf,
        offset~,
        max_len~,
        limit~,
      )
      let remaining = next_chunk_len - consumed.to_uint64()
      if remaining == 0 {
        guard self.transport.read_exactly(2) == b"\r\n" else {
          raise BadRequest
        }
      }
      self.body = Chunked(remaining)
      if produced == 0 {
        @io.BinaryReaderImpl::raw_read_impl(self, buf, offset~, max_len~)
      } else {
        produced
      }
    }
    Chunked(curr_chunk_remaining) => {
      let limit = @cmp.minimum(curr_chunk_remaining, @int.MAX_VALUE.to_uint64()).to_int()
      let (consumed, produced) = self.decode_chunk(
        buf,
        offset~,
        max_len~,
        limit~,
      )
      if consumed is 0 && produced is 0 {
        raise @io.ReaderClosed
      }
      let remaining = curr_chunk_remaining - consumed.to_uint64()
      if remaining == 0 {
        guard self.transport.read_exactly(2) == b"\r\n" else {
          raise BadRequest
        }
      }
      self.body = Chunked(remaining)
      if produced == 0 {
        @io.BinaryReaderImpl::raw_read_impl(self, buf, offset~, max_len~)
      } else {
        produced
      }
    }
    PassThrough =>
      @io.BinaryReaderImpl::raw_read_impl(
        self.transport,
        buf,
        offset~,
        max_len~,
      )
    WaitConnectionClose => {
      let (consumed, produced) = self.decode_chunk(
        buf,
        offset~,
        max_len~,
        limit=@int.MAX_VALUE,
      )
      if self.gzip is Some(gzip) {
        if gzip.is_finished() {
          guard self.transport.peek() is None else { raise BadRequest }
          self.gzip = None
          self.body = Empty
          self.trailer = Some({})
          produced
        } else if produced is 0 {
          guard consumed > 0 else { raise BadRequest }
          @io.BinaryReaderImpl::raw_read_impl(self, buf, offset~, max_len~)
        } else {
          produced
        }
      } else {
        if produced is 0 {
          self.body = Empty
          self.trailer = Some({})
        }
        produced
      }
    }
  }
}

///|
impl @io.BinaryReaderImpl for Reader with fn get_controller(self) {
  if self.body is PassThrough {
    @io.BinaryReaderImpl::get_controller(self.transport)
  } else {
    self.ctrl
  }
}

///|
extend Reader with @io.BinaryReader::{drop_all}

///|
/// Read header (or trailer) fields up to the empty line that ends them.
/// At most `budget` bytes, CRLFs included, and `MAX_HEADER_COUNT` fields are
/// accepted.
async fn Reader::read_headers(
  self : Reader,
  budget : Int32,
) -> (Headers, Array[Cookie]) {
  let headers : Headers = Map([])
  let cookies = []
  for remaining = budget, count = 0 {
    let header_line = self.read_line(remaining - 2)
    if header_line.length() is 0 {
      // empty line indicates end of header
      break
    }
    guard count < MAX_HEADER_COUNT else { raise BadRequest }
    guard header_line.find(b":") is Some(colon_index) else { raise BadRequest }
    let key = CaseInsensitiveString(@utf8.decode(header_line[:colon_index]))
    if !is_valid_http_header_field_name(key.0) {
      raise BadRequest
    }
    let raw_value = header_line[colon_index + 1:]
    for b in raw_value {
      guard !is_forbidden_ctl(b) else { raise BadRequest }
    }
    // only SP and HTAB are optional whitespace around a field value
    let value = @utf8.decode(raw_value).trim(chars=" \t").to_owned()
    if key == "Set-Cookie" {
      if Cookie::parse(value) is Some(cookie) {
        cookies.push(cookie)
      }
    } else {
      match headers.get(key) {
        None => headers[key] = value
        Some(value0) => headers[key] = "\{value0},\{value}"
      }
    }
    continue remaining - header_line.length() - 2, count + 1
  }
  (headers, cookies)
}

///|
/// Validate the headers that frame a message body, and return the parsed
/// `Content-Length`. This also applies to messages that have no body (such as
/// responses to HEAD, or 204 and 304 responses), so that they are rejected
/// exactly when a peer framing them differently would be confused.
fn validate_framing_headers(headers : Headers) -> UInt64? raise {
  let content_length = match headers.get("Content-Length") {
    None => None
    Some(value) => Some(parse_http_decimal(value))
  }
  // A message with both is a request smuggling vector (RFC 9112 section 6.3):
  // a peer that frames by Content-Length disagrees about where it ends.
  guard content_length is None || !headers.contains("Transfer-Encoding") else {
    raise BadRequest
  }
  content_length
}

///|
fn Reader::setup_message_body(
  self : Reader,
  headers : Headers,
  default~ : BodyKind,
) -> Unit raise {
  let content_length = validate_framing_headers(headers)
  let chunked = match headers.get("Transfer-Encoding") {
    None => false
    Some(encoding) if CaseInsensitiveString(encoding) == "chunked" => true
    Some(_) => raise NotImplemented
  }
  let auto_gzip = if self.auto_decompress {
    match headers.get("Content-Encoding") {
      None => false
      Some(encoding) if CaseInsensitiveString(encoding) == "gzip" => true
      Some(_) => raise NotImplemented
    }
  } else {
    false
  }
  if chunked {
    self.body = Chunked(0)
  } else if content_length is Some(len) {
    if len == 0 {
      self.body = Empty
      self.trailer = Some({})
    } else {
      self.body = Fixed(len)
    }
  } else {
    self.body = default
    if default is Empty {
      self.trailer = Some({})
    }
  }
  if auto_gzip && !(self.body is Empty) {
    // if automatic decompression is enabled, avoid reporting a wrong content-length value
    headers.remove("Content-Length")
    self.gzip = Some(Decoder())
  }
}

///|
/// Read the header of a HTTP/1.1 request from a HTTP reader.
/// This function must be called after the body of the last request is consumed,
/// otherwise it will abort the program immediately.
/// If the body is not needed, use `HttpReader::skip_body` to discard it.
///
/// After `read_request` successfully returned,
/// the HTTP reader itself can be used to extract the body of the request.
async fn Reader::read_request(self : Reader) -> RequestHeader {
  guard! self.body is Empty
  self.trailer = None
  let request_line = self.read_line(MAX_HEADER_SECTION_SIZE - 2)
  let budget = MAX_HEADER_SECTION_SIZE - request_line.length() - 2
  guard request_line.find(b" ") is Some(meth_len) else { raise BadRequest }
  let meth = match request_line[:meth_len] {
    b"GET" => Get
    b"HEAD" => Head
    b"POST" => Post
    b"PUT" => Put
    b"DELETE" => Delete
    b"CONNECT" => Connect
    b"OPTIONS" => Options
    b"TRACE" => Trace
    b"PATCH" => Patch
    name => {
      guard name.length() > 0 else { raise BadRequest }
      for c in name {
        guard is_token_char(c.to_uint16()) else { raise BadRequest }
      }
      Extension(@utf8.decode(name))
    }
  }
  let request_line = request_line[meth_len + 1:]
  guard request_line.find(b" ") is Some(path_len) && path_len > 0 else {
    raise BadRequest
  }
  for b in request_line[:path_len] {
    guard b > b' ' && b != b'\x7f' else { raise BadRequest }
  }
  let path = @utf8.decode(request_line[:path_len])
  match request_line[path_len + 1:] {
    b"HTTP/1.1" | b"HTTP/1.0" => ()
    protocol => raise HttpVersionNotSupported(@utf8.decode(protocol))
  }
  let (headers, cookies) = self.read_headers(budget)
  guard cookies.length() is 0 else { raise BadRequest }
  self.setup_message_body(headers, default=Empty)
  { meth, path, headers, }
}

///|
fn should_not_have_body(request_method : RequestMethod?, code : Int32) -> Bool {
  match (request_method, code) {
    (Some(Head), _) => true
    (Some(Connect), 200..<300) => true
    (_, 100..<200 | 204 | 304) => true
    _ => false
  }
}

///|
/// Read the header of a HTTP/1.1 response from a HTTP reader.
/// This function must be called after the body of the last response is consumed,
/// otherwise it will abort the program immediately.
/// If the body is not needed, use `HttpReader::skip_body` to discard it.
///
/// After `read_response` successfully returned,
/// the HTTP reader itself can be used to extract the body of the response.
async fn Reader::read_response(
  self : Reader,
  auto_decompress~ : Bool,
  request_method~ : RequestMethod?,
) -> ResponseHeader {
  self.auto_decompress = auto_decompress
  guard! self.body is Empty
  self.trailer = None
  let response_line = self.read_line(MAX_HEADER_SECTION_SIZE - 2)
  let budget = MAX_HEADER_SECTION_SIZE - response_line.length() - 2
  guard response_line.find(b" ") is Some(protocol_len) else { raise BadRequest }
  match response_line[:protocol_len] {
    b"HTTP/1.1" | b"HTTP/1.0" => ()
    protocol => raise HttpVersionNotSupported(@utf8.decode(protocol))
  }
  let response_line = response_line[protocol_len + 1:]
  guard response_line.find(b" ") is Some(code_len) && code_len == 3 else {
    raise BadRequest
  }
  let code = parse_http_decimal(@utf8.decode(response_line[:code_len])).to_int()
  for b in response_line[code_len + 1:] {
    guard !is_forbidden_ctl(b) else { raise BadRequest }
  }
  let reason = @utf8.decode(response_line[code_len + 1:])
  let (headers, cookies) = self.read_headers(budget)
  if should_not_have_body(request_method, code) {
    ignore(validate_framing_headers(headers))
    self.body = Empty
    self.trailer = Some({})
  } else {
    // response messages are close-delimited by default
    self.setup_message_body(headers, default=WaitConnectionClose)
  }

  { code, reason, headers, cookies, }
}

///|
/// Discard the body of current HTTP request/response,
/// so that the next request/response can be processed.
async fn Reader::skip_body(self : Reader) -> Unit {
  if self.body is Empty {
    // `peek`/`read_until` may have fetched the entire body into `ctrl`
    // while leaving part of it unconsumed; discard those bytes
    // so they do not leak into the next message.
    self.ctrl.clear()
    return
  }
  ignore(self.drop_all())
}

///|
async fn Reader::enter_passthrough_mode(self : Reader) -> Unit {
  self.skip_body()
  self.ctrl.clear()
  self.body = PassThrough
}
