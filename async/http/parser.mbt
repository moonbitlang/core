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
  GzipEnd
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
#non_exhaustive
pub suberror HttpProtocolError {
  BadRequest
  HttpVersionNotSupported(String)
  NotImplemented
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
    let n = self.transport.read_into(
      buf.mut_view(start=offset, end=offset + max_len),
    )
    (n, n)
  }

  let output = buf.mut_view(start=offset, end=offset + max_len)
  for consumed = 0 {
    // Pending plaintext never requires more compressed input.
    let drained = gzip.step(b"", output)
    if drained.produced > 0 {
      break (consumed, drained.produced)
    }
    match drained.status {
      Done => break (consumed, 0)
      NeedMoreOutput => panic()
      NeedMoreInput => ()
    }

    // Reaching `limit` may only be a chunk boundary. The caller decides when
    // it is the end of the complete encoded HTTP body and calls `check_end`.
    guard consumed < limit else { break (consumed, 0) }
    guard self.transport.peek() is Some(data) else { raise @io.UnexpectedEof }
    let available = @cmp.minimum(data.length(), limit - consumed)
    let result = gzip.step(data[:available], output)
    self.transport.drop_exactly(result.consumed)
    let consumed = consumed + result.consumed
    if result.produced > 0 {
      break (consumed, result.produced)
    }
    match result.status {
      Done => break (consumed, 0)
      NeedMoreInput => continue consumed
      NeedMoreOutput => panic()
    }
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
        raise @io.UnexpectedEof
      }
      let remaining = remaining - consumed.to_uint64()
      self.body = if remaining == 0 {
        self.trailer = Some({})
        if self.gzip is Some(_) {
          GzipEnd
        } else {
          Empty
        }
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
      if self.gzip is Some(_) {
        let (_, produced) = self.decode_chunk(buf, offset~, max_len~, limit=0)
        if produced > 0 {
          return produced
        }
      }
      guard self.transport.read_until(b"\r\n") is Some(len_bytes) else {
        raise @io.UnexpectedEof
      }
      let len_str = @utf8.decode(len_bytes)
      let len_str = if len_str.find(";") is Some(semi_index) {
        validate_chunk_extension(len_str[semi_index:])
        len_str[:semi_index].trim_end(chars=" \t")
      } else {
        len_str
      }
      guard len_str =~ re"^[0-9A-Fa-f]+$" else { raise BadRequest }
      let next_chunk_len = @string.parse_uint64(len_str, radix=16) catch {
        _ => raise BadRequest
      }
      guard next_chunk_len > 0 else {
        let (trailer, cookies) = self.read_headers()
        guard cookies.is_empty() else { raise BadRequest }
        self.trailer = Some(trailer)
        if self.gzip is Some(_) {
          self.body = GzipEnd
          return @io.BinaryReaderImpl::raw_read_impl(
            self,
            buf,
            offset~,
            max_len~,
          )
        } else {
          self.body = Empty
          return 0
        }
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
        raise @io.UnexpectedEof
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
    GzipEnd => {
      guard! self.gzip is Some(gzip)
      let output = buf.mut_view(start=offset, end=offset + max_len)
      let result = gzip.step(b"", output)
      if result.produced > 0 {
        return result.produced
      }
      match result.status {
        Done => {
          self.gzip = None
          self.body = Empty
          0
        }
        NeedMoreOutput => panic()
        NeedMoreInput => raise @io.UnexpectedEof
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
impl @io.BinaryReaderImpl for Reader with fn name(_self) {
  "@http.Reader"
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
async fn Reader::read_headers(self : Reader) -> (Headers, Array[Cookie]) {
  let headers : Headers = Map([])
  let cookies = []
  for ;; {
    guard self.transport.read_until(b"\r\n") is Some(header_line) else {
      raise @io.UnexpectedEof
    }
    if header_line.length() is 0 {
      // empty line indicates end of header
      break
    }
    guard header_line.find(b":") is Some(colon_index) else { raise BadRequest }
    let key = CaseInsensitiveString(@utf8.decode(header_line[:colon_index]))
    if !is_valid_http_header_field_name(key.0) {
      raise BadRequest
    }
    let value = if colon_index + 1 == header_line.length() {
      ""
    } else if header_line[colon_index + 1] == b' ' {
      @utf8.decode(header_line[colon_index + 2:])
    } else {
      @utf8.decode(header_line[colon_index + 1:])
    }
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
  }
  (headers, cookies)
}

///|
fn Reader::setup_message_body(
  self : Reader,
  headers : Headers,
  default~ : BodyKind,
) -> Unit raise {
  let content_length = match headers.get("Content-Length") {
    None => None
    Some(value) => {
      guard value =~ re"^[0-9]+$" else { raise BadRequest }
      Some(
        @string.parse_uint64(value, radix=10) catch {
          _ => raise BadRequest
        },
      )
    }
  }
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
  guard self.transport.read_until(b"\r\n") is Some(request_line) else {
    raise @io.UnexpectedEof
  }
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
  guard request_line.find(b" ") is Some(path_len) else { raise BadRequest }
  let path = @utf8.decode(request_line[:path_len])
  match request_line[path_len + 1:] {
    b"HTTP/1.1" | b"HTTP/1.0" => ()
    protocol => raise HttpVersionNotSupported(@utf8.decode(protocol))
  }
  let (headers, cookies) = self.read_headers()
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
  guard self.transport.read_until(b"\r\n") is Some(response_line) else {
    raise @io.UnexpectedEof
  }
  guard response_line.find(b" ") is Some(protocol_len) else { raise BadRequest }
  match response_line[:protocol_len] {
    b"HTTP/1.1" | b"HTTP/1.0" => ()
    protocol => raise HttpVersionNotSupported(@utf8.decode(protocol))
  }
  let response_line = response_line[protocol_len + 1:]
  guard response_line
    is [
      b'0'..<=b'9' as hundreds,
      b'0'..<=b'9' as tens,
      b'0'..<=b'9' as ones,
      b' ',
      .. reason,
    ] else {
    raise BadRequest
  }
  let code = (hundreds.to_int() - '0') * 100 +
    (tens.to_int() - '0') * 10 +
    (ones.to_int() - '0')
  let reason = @utf8.decode(reason)
  let (headers, cookies) = self.read_headers()
  if should_not_have_body(request_method, code) {
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
