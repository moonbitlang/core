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
pub suberror HttpProtocolError {
  BadRequest
  HttpVersionNotSupported(String)
  NotImplemented
} derive(@debug.Debug, @json.ToJson)

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
      guard self.transport.read_until(b"\r\n") is Some(len_bytes) else {
        raise @io.ReaderClosed
      }
      let len_str = @utf8.decode(len_bytes)
      let len_str = if len_str.find(";") is Some(semi_index) {
        validate_chunk_extension(len_str[semi_index:])
        len_str[:semi_index].trim_end(chars=" \t")
      } else {
        len_str
      }
      let next_chunk_len = @string.parse_uint64(len_str, base=16) catch {
        _ => raise BadRequest
      }
      guard next_chunk_len > 0 else {
        let (trailer, cookies) = self.read_headers()
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
async fn Reader::read_headers(self : Reader) -> (Headers, Array[Cookie]) {
  let headers : Headers = Map([])
  let cookies = []
  for ;; {
    guard self.transport.read_until(b"\r\n") is Some(header_line) else {
      raise @io.ReaderClosed
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
      cookies.push(Cookie::parse(value))
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
    Some(value) => Some(@string.parse_uint64(value, base=10))
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
async fn Reader::read_request(self : Reader) -> Request {
  guard! self.body is Empty
  self.trailer = None
  guard self.transport.read_until(b"\r\n") is Some(request_line) else {
    raise @io.ReaderClosed
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
    _ => raise BadRequest
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
) -> Response {
  self.auto_decompress = auto_decompress
  guard! self.body is Empty
  self.trailer = None
  guard self.transport.read_until(b"\r\n") is Some(response_line) else {
    raise @io.ReaderClosed
  }
  guard response_line.find(b" ") is Some(protocol_len) else { raise BadRequest }
  match response_line[:protocol_len] {
    b"HTTP/1.1" | b"HTTP/1.0" => ()
    protocol => raise HttpVersionNotSupported(@utf8.decode(protocol))
  }
  let response_line = response_line[protocol_len + 1:]
  guard response_line.find(b" ") is Some(code_len) else { raise BadRequest }
  let code = @string.parse_int(@utf8.decode(response_line[:code_len]), base=10) catch {
    _ => raise BadRequest
  }
  let reason = @utf8.decode(response_line[code_len + 1:])
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
