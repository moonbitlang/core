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
priv enum SenderMode {
  SendingHeader
  WaitingRequestBody
  WaitingResponseBody
  SendingBody
  SendingFixed(mut remaining~ : Int64)
  PassThrough
}

///|
/// Provide send buffering & chunked encoding handling for sending HTTP request/response.
priv struct Sender {
  writer : &@io.BinaryWriter
  mut mode : SenderMode
  mut send_buf : FixedArray[Byte]
  mut send_len : Int32
  ctrl : @io.BinaryWriterController
  headers : Bytes
  has_accept_encoding : Bool
}

///|
let forbidden_headers : @set.Set[CaseInsensitiveString] = Set([
  "Content-Length", "Transfer-Encoding",
])

///|
fn sanitize_header_value(s : String) -> String {
  for c in s.code_units(); crlf_count = 0 {
    if c is ('\r' | '\n') {
      continue crlf_count + 1
    }
  } nobreak {
    guard crlf_count > 0 else {
      // fast path: no CRLF detected, return immediately
      s
    }
    let buf = StringBuilder(size_hint=s.length() - crlf_count)
    for c in s {
      match c {
        '\r' | '\n' => ()
        c => buf.write_char(c)
      }
    }
    buf.to_string()
  }
}

///|
fn[W : @io.BinaryWriter] Sender::new(
  w : W,
  headers~ : Headers = Map([]),
) -> Sender {
  let header_text = @buffer.Buffer()
  let mut has_accept_encoding = false
  for k, v in headers {
    if !is_valid_http_header_field_name(k.0) {
      continue
    }
    if !forbidden_headers.contains(k) {
      if k == "Accept-Encoding" {
        has_accept_encoding = true
      }
      header_text
      ..write_string_utf8(k.0)
      ..write_bytes(b": ")
      ..write_string_utf8(sanitize_header_value(v))
      .write_bytes(b"\r\n")
    }
  }
  {
    writer: w,
    mode: SendingHeader,
    send_buf: FixedArray::make(1024, 0),
    send_len: 0,
    ctrl: BinaryWriterController(),
    headers: header_text.contents(),
    has_accept_encoding,
  }
}

///|
async fn Sender::flush(self : Sender) -> Unit {
  if self.send_len > 0 {
    self.writer.write(
      self.send_buf.unsafe_reinterpret_as_bytes()[:self.send_len],
    )
    self.send_len = 0
  }
}

///|
const NON_EMPTY_MESSAGE_HEADER_END : Bytes = b"Transfer-Encoding: chunked\r\n\r\n"

///|
const EMPTY_MESSAGE_HEADER_END : Bytes = b"Content-Length: 0\r\n\r\n"

///|
/// Error raised when the user is sending a fixed length HTTP message body,
/// but the actual length of the message body is incorrect.
pub suberror IncorrectBodyLength derive(@debug.Debug, @json.ToJson)

///|
impl @io.BinaryWriter for Sender

///|
impl @io.BinaryWriterImpl for Sender with fn get_controller(self) {
  self.ctrl
}

///|
impl @io.BinaryWriterImpl for Sender with fn raw_write_impl(
  self,
  buf,
  offset~,
  len~,
) {
  match self.mode {
    SendingHeader => {
      if self.send_len >= self.send_buf.length() {
        self.flush()
      }
      let len = @cmp.minimum(len, self.send_buf.length() - self.send_len)
      self.send_buf.blit_from_bytes(self.send_len, buf, offset, len)
      self.send_len += len
      len
    }
    SendingFixed(remaining~) as mode => {
      guard len.to_int64() <= remaining else { raise IncorrectBodyLength }
      if self.send_len >= self.send_buf.length() {
        self.flush()
      }
      let len = @cmp.minimum(self.send_buf.length() - self.send_len, len)
      self.send_buf.blit_from_bytes(self.send_len, buf, offset, len)
      self.send_len += len
      mode.remaining -= len.to_int64()
      len
    }
    WaitingRequestBody | WaitingResponseBody => {
      if self.send_len + NON_EMPTY_MESSAGE_HEADER_END.length() >
        self.send_buf.length() {
        self.flush()
      }
      self.send_buf.blit_from_bytes(
        self.send_len,
        NON_EMPTY_MESSAGE_HEADER_END,
        0,
        NON_EMPTY_MESSAGE_HEADER_END.length(),
      )
      self.send_len += NON_EMPTY_MESSAGE_HEADER_END.length()
      self.mode = SendingBody
      @io.BinaryWriterImpl::raw_write_impl(self, buf, offset~, len~)
    }
    SendingBody => {
      // Reserve enough space for chunk length and '\r\n' in the buffer,
      // so that we can commit the whole chunk in a single write to avoid small writes
      if self.send_len + 7 >= self.send_buf.length() {
        self.flush()
      }
      let max_len = self.send_buf.length() - self.send_len - 7
      let len = @cmp.minimum(max_len, len)
      let len_str = encode_int(len, base=16)
      let len_str_len = len_str.length()
      self.send_buf.blit_from_bytes(self.send_len, len_str, 0, len_str_len)
      let curr_len = self.send_len + len_str_len
      self.send_buf[curr_len] = b'\r'
      self.send_buf[curr_len + 1] = b'\n'
      let curr_len = curr_len + 2
      self.send_buf.blit_from_bytes(curr_len, buf, offset, len)
      let curr_len = curr_len + len
      self.send_buf[curr_len] = b'\r'
      self.send_buf[curr_len + 1] = b'\n'
      self.send_len = curr_len + 2
      len
    }
    PassThrough =>
      @io.BinaryWriterImpl::raw_write_impl(self.writer, buf, offset~, len~)
  }
}

///|
impl @io.BinaryWriter for Sender with fn write_reader(self, reader) {
  match self.mode {
    SendingHeader =>
      for ;; {
        if self.send_len >= self.send_buf.length() {
          self.flush()
        }
        let n = reader.read_into(self.send_buf, offset=self.send_len)
        if n == 0 {
          break
        }
      }
    SendingFixed(remaining~) as mode =>
      for remaining = remaining {
        if self.send_len >= self.send_buf.length() {
          self.flush()
        }
        let n = reader.read_into(self.send_buf, offset=self.send_len)
        if n == 0 {
          mode.remaining = remaining
          break
        }
        let remaining = remaining - n.to_int64()
        if remaining < 0 {
          raise IncorrectBodyLength
        }
        self.send_len += n
        self.flush()
        continue remaining
      }
    WaitingRequestBody | WaitingResponseBody => {
      if self.send_len + NON_EMPTY_MESSAGE_HEADER_END.length() >
        self.send_buf.length() {
        self.flush()
      }
      self.send_buf.blit_from_bytes(
        self.send_len,
        NON_EMPTY_MESSAGE_HEADER_END,
        0,
        NON_EMPTY_MESSAGE_HEADER_END.length(),
      )
      self.send_len += NON_EMPTY_MESSAGE_HEADER_END.length()
      self.mode = SendingBody
      self.write_reader(reader)
    }
    SendingBody => {
      self.flush()
      self.send_buf[3] = b'\r'
      self.send_buf[4] = b'\n'
      let max_len = self.send_buf.length() - 7
      for ;; {
        let len = reader.read_into(self.send_buf, offset=5, max_len~)
        if len == 0 {
          break
        }
        self.send_buf[5 + len] = b'\r'
        self.send_buf[6 + len] = b'\n'
        let len_str = encode_int(len, base=16)
        let start = 3 - len_str.length()
        self.send_buf.blit_from_bytes(start, len_str, 0, len_str.length())
        self.writer.write(
          self.send_buf.unsafe_reinterpret_as_bytes()[start:len + 7],
        )
      }
    }
    PassThrough => self.writer.write_reader(reader)
  }
}

///|
extend Sender with @io.BinaryWriter::{write, write_reader}

///|
async fn Sender::end_body(self : Sender) -> Unit {
  match self.mode {
    SendingHeader | PassThrough =>
      abort("`end_body()` called outside a HTTP message")
    SendingFixed(remaining=0) => self.flush()
    SendingFixed(_) => raise IncorrectBodyLength
    WaitingRequestBody => {
      // Request body are empty by default, no need to emit body related headers
      self.mode = SendingHeader
      self..write(b"\r\n").flush()
    }
    WaitingResponseBody =>
      // Response body are close-delimited by default,
      // so we always emit message related headers,
      // except for special cases such as response to `HEAD` request.
      if self.send_len + EMPTY_MESSAGE_HEADER_END.length() >
        self.send_buf.length() {
        self.flush()
        self.writer.write(EMPTY_MESSAGE_HEADER_END)
      } else {
        self.send_buf.blit_from_bytes(
          self.send_len,
          EMPTY_MESSAGE_HEADER_END,
          0,
          EMPTY_MESSAGE_HEADER_END.length(),
        )
        self.send_len += EMPTY_MESSAGE_HEADER_END.length()
        self.flush()
      }
    SendingBody =>
      if self.send_len + 5 > self.send_buf.length() {
        self.flush()
        self.writer.write(b"0\r\n\r\n")
      } else {
        self.send_buf.blit_from_bytes(self.send_len, b"0\r\n\r\n", 0, 5)
        self.send_len += 5
        self.flush()
      }
  }
  self.mode = SendingHeader
}

///|
async fn Sender::send_headers(self : Sender, headers : Headers) -> Int64? {
  let mut content_length = None
  for k, v in headers {
    if !is_valid_http_header_field_name(k.0) {
      continue
    }
    if k == "Content-Length" {
      let len = @string.parse_int64(v.trim(), base=10)
      content_length = Some(len)
    } else if forbidden_headers.contains(k) {
      continue
    }
    self
    ..write(@utf8.encode(k.0))
    ..write(b": ")
    ..write(@utf8.encode(sanitize_header_value(v)))
    .write(b"\r\n")
  }
  content_length
}

///|
/// Return value indicate if automatic decompression should be enabled for the response of this request
async fn Sender::send_request(
  self : Sender,
  meth : RequestMethod,
  path : StringView,
  extra_headers~ : Headers,
) -> Bool {
  guard! self.mode is SendingHeader
  match meth {
    Get => self.write(b"GET ")
    Head => self.write(b"HEAD ")
    Post => self.write(b"POST ")
    Put => self.write(b"PUT ")
    Delete => self.write(b"DELETE ")
    Connect => self.write(b"CONNECT ")
    Options => self.write(b"OPTIONS ")
    Trace => self.write(b"TRACE ")
    Patch => self.write(b"PATCH ")
    Extension(ext) => {
      guard ext.length() > 0 else { raise InvalidMethod(ext) }
      for c in ext.code_units() {
        guard is_token_char(c) else { raise InvalidMethod(ext) }
      }
      self.write(@utf8.encode(ext))
      self.write(b" ")
    }
  }
  let content_length = self
    ..write(@utf8.encode(path))
    ..write(b" HTTP/1.1\r\n")
    ..write(self.headers)
    .send_headers(extra_headers)
  let auto_decompress = !self.has_accept_encoding &&
    !extra_headers.contains("Accept-Encoding")
  if auto_decompress {
    self.write(b"Accept-Encoding: gzip,identity\r\n")
  }
  if content_length is Some(len) {
    self.write(b"\r\n")
    self.mode = SendingFixed(remaining=len)
  } else {
    self.mode = WaitingRequestBody
  }
  auto_decompress
}

///|
async fn Sender::send_response(
  self : Sender,
  code : Int32,
  reason : String,
  extra_headers~ : Headers,
  cookies~ : Array[Cookie],
  request_method~ : RequestMethod,
) -> Unit {
  guard! self.mode is SendingHeader
  let content_length = self
    ..write(b"HTTP/1.1 ")
    ..write(encode_int(code, base=10))
    ..write(b" ")
    ..write(@utf8.encode(sanitize_header_value(reason)))
    ..write(b"\r\n")
    ..write(self.headers)
    .send_headers(extra_headers)
  for cookie in cookies {
    self.write(b"Set-Cookie: ")
    cookie.write_to(self)
    self.write(b"\r\n")
  }
  if should_not_have_body(Some(request_method), code) {
    self.write(b"\r\n")
    self.mode = SendingFixed(remaining=0)
  } else if content_length is Some(len) {
    self.write(b"\r\n")
    self.mode = SendingFixed(remaining=len)
  } else {
    self.mode = WaitingResponseBody
  }
}

///|
fn Sender::enter_passthrough_mode(self : Sender) -> Unit {
  self.send_buf = []
  self.send_len = 0
  self.mode = PassThrough
}
