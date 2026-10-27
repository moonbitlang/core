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
// A single TLS session: handshake state, encrypted/plain buffers, and wants flags.
priv struct TlsConnectionHandle(UInt64)

///|
priv enum TlsTrustMode {
  TrustNoVerification = 0
  TrustSystemRoot = 1
  TrustCustomRoot = 2
}

///|
priv enum TlsState {
  Completed = 0
  WantRead = 1
  WantWrite = 2
  Error = 3
  Eof = 4
  ReNegotiation = 5
}

///|
// Host TLS calls return non-negative byte counts and these negative status
// sentinels through the same Int. Values must match moonrun's Rust TLS status
// constants.
const TLS_ERROR = -1

///|
const TLS_CLOSED = -2

///|
const TLS_WOULD_BLOCK = -3

///|
const TLS_RENEGOTIATION = -4

///|
fn TrustedRoot::mode(self : TrustedRoot) -> TlsTrustMode {
  match self {
    NoVerification => TrustNoVerification
    SystemRoot => TrustSystemRoot
    CustomPemFile(_) => TrustCustomRoot
  }
}

///|
#unsafe_skip_stub_check
#borrow(buf)
fn tls_buffer_length(buf : @c_buffer.Buffer) -> Int32 = "moonbitlang/async" "c_buffer/length"

///|
// Returns a live handle containing pending configuration. TLS initialization
// errors are reported by the client and server setup calls.
#unsafe_skip_stub_check
fn TlsConnectionHandle::new() -> TlsConnectionHandle = "moonbitlang/async" "tls/connection/new"

///|
#unsafe_skip_stub_check
#borrow(host)
fn TlsConnectionHandle::set_client(
  self : TlsConnectionHandle,
  host : String,
  host_len~ : Int32 = host.length(),
  sni~ : Bool,
  trust : TlsTrustMode,
) -> Int32 = "moonbitlang/async" "tls/connection/set_client"

///|
#unsafe_skip_stub_check
#borrow(root)
fn TlsConnectionHandle::add_root_certificate(
  self : TlsConnectionHandle,
  root : Bytes,
  root_len~ : Int32 = root.length(),
) -> Int32 = "moonbitlang/async" "tls/connection/add_root_certificate"

///|
#unsafe_skip_stub_check
#borrow(private_key_file, certificate_file)
fn TlsConnectionHandle::set_server_files(
  self : TlsConnectionHandle,
  private_key_file : @os_string.OsString,
  private_key_file_len~ : Int32 = private_key_file.to_string().length(),
  private_key_type : X509FileType,
  certificate_file : @os_string.OsString,
  certificate_file_len~ : Int32 = certificate_file.to_string().length(),
  certificate_type : X509FileType,
) -> Int32 = "moonbitlang/async" "tls/connection/set_server_files"

///|
#unsafe_skip_stub_check
#borrow(pfx_content)
fn TlsConnectionHandle::set_server_pfx(
  self : TlsConnectionHandle,
  pfx_content : Bytes,
  pfx_content_len~ : Int32 = pfx_content.length(),
) -> Int32 = "moonbitlang/async" "tls/connection/set_server_pfx"

///|
#unsafe_skip_stub_check
fn TlsConnectionHandle::free(self : TlsConnectionHandle) -> Unit = "moonbitlang/async" "tls/connection/free"

///|
#unsafe_skip_stub_check
fn TlsConnectionHandle::take_error(
  self : TlsConnectionHandle,
) -> @c_buffer.Buffer = "moonbitlang/async" "tls/connection/take_error"

///|
fn TlsConnectionHandle::take_error_message(
  self : TlsConnectionHandle,
) -> String {
  let buf = self.take_error()
  defer buf.free()
  buf.decode_as_os_string()
}

///|
#unsafe_skip_stub_check
#borrow(in_buffer, out_buffer, plain_buffer)
fn TlsConnectionHandle::read_plain(
  self : TlsConnectionHandle,
  in_buffer~ : FixedArray[Byte],
  in_buffer_offset~ : Int32,
  in_buffer_len~ : Int32,
  out_buffer~ : FixedArray[Byte],
  out_buffer_offset~ : Int32,
  out_buffer_len~ : Int32,
  plain_buffer~ : FixedArray[Byte],
  plain_buffer_offset~ : Int32,
  plain_buffer_len~ : Int32,
) -> Int32 = "moonbitlang/async" "tls/connection/read_plain"

///|
#unsafe_skip_stub_check
#borrow(in_buffer, out_buffer, plain_buffer)
fn TlsConnectionHandle::write_plain(
  self : TlsConnectionHandle,
  in_buffer~ : FixedArray[Byte],
  in_buffer_offset~ : Int32,
  in_buffer_len~ : Int32,
  out_buffer~ : FixedArray[Byte],
  out_buffer_offset~ : Int32,
  out_buffer_len~ : Int32,
  plain_buffer~ : Bytes,
  plain_buffer_offset~ : Int32,
  plain_buffer_len~ : Int32,
) -> Int32 = "moonbitlang/async" "tls/connection/write_plain"

///|
#unsafe_skip_stub_check
#borrow(in_buffer, out_buffer)
fn TlsConnectionHandle::connect(
  self : TlsConnectionHandle,
  in_buffer~ : FixedArray[Byte],
  in_buffer_offset~ : Int32,
  in_buffer_len~ : Int32,
  out_buffer~ : FixedArray[Byte],
  out_buffer_offset~ : Int32,
  out_buffer_len~ : Int32,
) -> TlsState = "moonbitlang/async" "tls/connection/connect"

///|
#unsafe_skip_stub_check
#borrow(in_buffer, out_buffer)
fn TlsConnectionHandle::accept(
  self : TlsConnectionHandle,
  in_buffer~ : FixedArray[Byte],
  in_buffer_offset~ : Int32,
  in_buffer_len~ : Int32,
  out_buffer~ : FixedArray[Byte],
  out_buffer_offset~ : Int32,
  out_buffer_len~ : Int32,
) -> TlsState = "moonbitlang/async" "tls/connection/accept"

///|
#unsafe_skip_stub_check
fn TlsConnectionHandle::bytes_read(self : TlsConnectionHandle) -> Int32 = "moonbitlang/async" "tls/connection/bytes_read"

///|
#unsafe_skip_stub_check
fn TlsConnectionHandle::bytes_to_write(self : TlsConnectionHandle) -> Int32 = "moonbitlang/async" "tls/connection/bytes_to_write"

///|
#unsafe_skip_stub_check
fn TlsConnectionHandle::wants_read(self : TlsConnectionHandle) -> Bool = "moonbitlang/async" "tls/connection/wants_read"

///|
#unsafe_skip_stub_check
fn TlsConnectionHandle::wants_write(self : TlsConnectionHandle) -> Bool = "moonbitlang/async" "tls/connection/wants_write"

///|
#unsafe_skip_stub_check
fn TlsConnectionHandle::shutdown(self : TlsConnectionHandle) -> Int32 = "moonbitlang/async" "tls/connection/shutdown"

///|
#unsafe_skip_stub_check
fn TlsConnectionHandle::peer_certificate(
  self : TlsConnectionHandle,
) -> @c_buffer.Buffer = "moonbitlang/async" "tls/connection/peer_certificate"

///|
#unsafe_skip_stub_check
fn TlsConnectionHandle::unique_channel_binding(
  self : TlsConnectionHandle,
) -> @c_buffer.Buffer = "moonbitlang/async" "tls/connection/unique_channel_binding"

///|
#unsafe_skip_stub_check
fn TlsConnectionHandle::server_endpoint_channel_binding(
  self : TlsConnectionHandle,
) -> @c_buffer.Buffer = "moonbitlang/async" "tls/connection/server_endpoint_channel_binding"

///|
struct Tls {
  conn : TlsConnectionHandle
  host : String?
  is_client : Bool
  transport : Transport
  reader_ctrl : @io.BinaryReaderController
  writer_ctrl : @io.BinaryWriterController
  mut shutdown : Bool
  mut closed : Bool
}

///|
fn[R : @io.BinaryReader, W : @io.BinaryWriter] Tls::from_pair(
  conn : TlsConnectionHandle,
  r : R,
  w : W,
  is_client~ : Bool,
  host~ : String?,
) -> Tls {
  {
    conn,
    host,
    is_client,
    transport: Transport::new(r, w),
    reader_ctrl: BinaryReaderController(),
    writer_ctrl: BinaryWriterController(),
    shutdown: false,
    closed: false,
  }
}

///|
async fn Tls::connect(self : Tls) -> Unit {
  let controller = @io.BinaryReaderImpl::get_controller(self.transport.reader)
  let write_buf = self.transport.write_buf
  for ;; {
    let read_buf = controller.buffered()
    let ret = self.conn.connect(
      in_buffer=controller.raw_buffer(),
      in_buffer_offset=read_buf.start_offset(),
      in_buffer_len=read_buf.length(),
      out_buffer=write_buf.buf,
      out_buffer_offset=write_buf.start + write_buf.len,
      out_buffer_len=write_buf.buf.length() - write_buf.start - write_buf.len,
    )
    controller.drop(self.conn.bytes_read())
    write_buf.len += self.conn.bytes_to_write()
    match ret {
      Completed => {
        self.transport.flush_write()
        break
      }
      WantRead => {
        self.transport.flush_write()
        self.transport.read_more()
      }
      WantWrite => self.transport.flush_write()
      Eof => raise ConnectionClosed
      Error => raise TlsError(self.conn.take_error_message())
      ReNegotiation => panic()
    }
  }
}

///|
async fn Tls::accept(self : Tls) -> Unit {
  let controller = @io.BinaryReaderImpl::get_controller(self.transport.reader)
  let write_buf = self.transport.write_buf
  for ;; {
    let read_buf = controller.buffered()
    let ret = self.conn.accept(
      in_buffer=controller.raw_buffer(),
      in_buffer_offset=read_buf.start_offset(),
      in_buffer_len=read_buf.length(),
      out_buffer=write_buf.buf,
      out_buffer_offset=write_buf.start + write_buf.len,
      out_buffer_len=write_buf.buf.length() - write_buf.start - write_buf.len,
    )
    controller.drop(self.conn.bytes_read())
    write_buf.len += self.conn.bytes_to_write()
    match ret {
      Completed => {
        self.transport.flush_write()
        break
      }
      WantRead => {
        self.transport.flush_write()
        self.transport.read_more()
      }
      WantWrite => self.transport.flush_write()
      Eof => raise ConnectionClosed
      Error => raise TlsError(self.conn.take_error_message())
      ReNegotiation => panic()
    }
  }
}

///|
/// Create a generic TLS client from a reader and a writer.
/// See `@tls.Tls::client` for more details.
pub async fn[R : @io.BinaryReader, W : @io.BinaryWriter] Tls::client_from_pair(
  r : R,
  w : W,
  host? : String,
  sni~ : Bool = true,
  trust~ : TrustedRoot = SystemRoot,
) -> Tls {
  let host_name = match host {
    Some(host) => host
    None => ""
  }
  let conn = TlsConnectionHandle::new()
  let self = Tls::from_pair(conn, r, w, is_client=true, host~)
  errdefer self.close()
  if trust is CustomPemFile(path) {
    let pem = @fs.read_text(path)
    for cert in decode_pem_certificates(pem) {
      let status = conn.add_root_certificate(cert)
      if status != 0 {
        raise TlsError(conn.take_error_message())
      }
    }
  }
  let status = conn.set_client(host_name, sni~, trust.mode())
  if status != 0 {
    raise TlsError(conn.take_error_message())
  }
  self.connect()
  self
}

///|
#internal(internal, "do not use, for internal testing only")
pub async fn[R : @io.BinaryReader, W : @io.BinaryWriter] Tls::server_from_pair(
  r : R,
  w : W,
  private_key_file? : String,
  private_key_type? : X509FileType,
  certificate_file? : String,
  certificate_type? : X509FileType,
  pfx_file? : String,
) -> Tls {
  let conn = TlsConnectionHandle::new()
  let self = Tls::from_pair(conn, r, w, is_client=false, host=None)
  errdefer self.close()
  let status = if @event_loop.platform is Windows {
    let pfx_file = match pfx_file {
      Some(pfx_file) => pfx_file
      None =>
        raise TlsError("pfx_file is required for TLS servers on Windows hosts")
    }
    let pfx_content = @fs.read_binary(pfx_file)
    conn.set_server_pfx(pfx_content)
  } else {
    let private_key_file = match private_key_file {
      Some(private_key_file) => private_key_file
      None =>
        raise TlsError(
          "private_key_file is required for TLS servers on non-Windows hosts",
        )
    }
    let certificate_file = match certificate_file {
      Some(certificate_file) => certificate_file
      None =>
        raise TlsError(
          "certificate_file is required for TLS servers on non-Windows hosts",
        )
    }
    let private_key_type = match private_key_type {
      Some(private_key_type) => private_key_type
      None =>
        raise TlsError(
          "private_key_type is required for TLS servers on non-Windows hosts",
        )
    }
    let certificate_type = match certificate_type {
      Some(certificate_type) => certificate_type
      None =>
        raise TlsError(
          "certificate_type is required for TLS servers on non-Windows hosts",
        )
    }
    conn.set_server_files(
      @os_string.from_string(private_key_file),
      private_key_type,
      @os_string.from_string(certificate_file),
      certificate_type,
    )
  }
  if status != 0 {
    raise TlsError(conn.take_error_message())
  }
  self.accept()
  self
}

///|
#internal(internal, "do not use, for internal testing only")
pub async fn[Inner : @io.BinaryReader + @io.BinaryWriter] Tls::server(
  inner : Inner,
  private_key_file? : String,
  private_key_type? : X509FileType,
  certificate_file? : String,
  certificate_type? : X509FileType,
  pfx_file? : String,
) -> Tls {
  Tls::server_from_pair(
    inner,
    inner,
    private_key_file?,
    private_key_type?,
    certificate_file?,
    certificate_type?,
    pfx_file?,
  )
}

///|
impl @io.BinaryReaderImpl for Tls with fn raw_read_impl(
  self,
  buf,
  offset~,
  max_len~,
) {
  let controller = @io.BinaryReaderImpl::get_controller(self.transport.reader)
  let write_buf = self.transport.write_buf
  while controller.buffered() is read_buf &&
        self.conn.read_plain(
          in_buffer=controller.raw_buffer(),
          in_buffer_offset=read_buf.start_offset(),
          in_buffer_len=read_buf.length(),
          out_buffer=write_buf.buf,
          out_buffer_offset=write_buf.start + write_buf.len,
          out_buffer_len=write_buf.buf.length() -
            write_buf.start -
            write_buf.len,
          plain_buffer=buf,
          plain_buffer_offset=offset,
          plain_buffer_len=max_len,
        )
        is n {
    let bytes_read = self.conn.bytes_read()
    controller.drop(bytes_read)
    let bytes_to_write = self.conn.bytes_to_write()
    write_buf.len += bytes_to_write
    if bytes_to_write > 0 {
      self.transport.flush_write()
    }
    match n {
      n if n > 0 => return n
      TLS_CLOSED => {
        self.shutdown()
        return 0
      }
      TLS_RENEGOTIATION =>
        if self.is_client {
          self.connect()
        } else {
          self.accept()
        }
      TLS_WOULD_BLOCK =>
        if bytes_read > 0 || bytes_to_write > 0 {
          continue
        } else if self.transport.state is Closed &&
          controller.buffered().length() == 0 {
          return 0
        } else if self.conn.wants_read() {
          self.transport.read_more()
        } else if self.conn.wants_write() {
          self.transport.flush_write()
        } else {
          return 0
        }
      TLS_ERROR => raise TlsError(self.conn.take_error_message())
      _ => abort("unexpected status code \{n} from TLS read")
    }
  } nobreak {
    0
  }
}

///|
impl @io.BinaryReaderImpl for Tls with fn get_controller(self) {
  self.reader_ctrl
}

///|
impl @io.BinaryWriterImpl for Tls with fn raw_write_impl(
  self,
  buf,
  offset~,
  len~,
) {
  self.transport.flush_write()
  let controller = @io.BinaryReaderImpl::get_controller(self.transport.reader)
  let write_buf = self.transport.write_buf
  while controller.buffered() is read_buf &&
        self.conn.write_plain(
          in_buffer=controller.raw_buffer(),
          in_buffer_offset=read_buf.start_offset(),
          in_buffer_len=read_buf.length(),
          out_buffer=write_buf.buf,
          out_buffer_offset=write_buf.start + write_buf.len,
          out_buffer_len=write_buf.buf.length() -
            write_buf.start -
            write_buf.len,
          plain_buffer=buf,
          plain_buffer_offset=offset,
          plain_buffer_len=len,
        )
        is n {
    let bytes_read = self.conn.bytes_read()
    controller.drop(bytes_read)
    let bytes_to_write = self.conn.bytes_to_write()
    write_buf.len += bytes_to_write
    if bytes_to_write > 0 {
      self.transport.flush_write()
    }
    match n {
      n if n >= 0 => return n
      TLS_RENEGOTIATION =>
        if self.is_client {
          self.connect()
        } else {
          self.accept()
        }
      TLS_WOULD_BLOCK =>
        if bytes_read > 0 || bytes_to_write > 0 {
          continue
        } else if self.conn.wants_read() {
          self.transport.read_more()
        } else if self.conn.wants_write() {
          return 0
        } else {
          return 0
        }
      TLS_CLOSED => raise ConnectionClosed
      TLS_ERROR => raise TlsError(self.conn.take_error_message())
      _ => abort("unexpected status code \{n} from TLS write")
    }
  } nobreak {
    0
  }
}

///|
impl @io.BinaryWriterImpl for Tls with fn get_controller(self) {
  self.writer_ctrl
}

///|
/// Close a TLS connection and release related resource.
/// THIS FUNCTION MUST BE CALLED BEFORE CLOSING UNDERLYING TRANSPORT!!!
///
/// Note that `.close()` does not provide reliable termination indication for the remote peer.
/// If protected termination is desirable, call `.terminate()` before `.close()`.
pub fn Tls::close(self : Tls) -> Unit {
  guard !self.closed else {  }
  self.closed = true
  if self.transport.state is Normal {
    self.transport.state = Closed
  }
  self.conn.free()
  ignore(self.host)
}

///|
/// Start the TLS termination procedure for a TLS connection.
/// `.close()` must still be called after `.shutdown()` to release resources.
/// `.shutdown()` is necessary to reliably terminate a TLS stream
/// and provide protection for truncation attack.
///
/// `.shutdown()` is not necessary for security sake
/// if the application protocol has its own termination indication.
pub async fn Tls::shutdown(self : Tls) -> Unit {
  guard !self.shutdown else {  }
  self.shutdown = true
  match self.transport.state {
    Normal => ()
    Closed => return
    Error(err) => raise err
  }
  self.transport.flush_write()
  match self.conn.shutdown() {
    0 => ()
    TLS_CLOSED => return
    TLS_ERROR => raise TlsError(self.conn.take_error_message())
    status => abort("unexpected status code \{status} from TLS shutdown")
  }
  if self.is_client {
    self.connect()
  } else {
    self.accept()
  }
}

///|
/// Get the certificate of remote peer for a TLS connection in DER format.
/// Note that even if nothing goes wrong, the certificate may not exist:
///
/// - although rare, some TLS algorithm choice does not have a certificate
/// - for connection without client certificate, the server does not have any peer certificate
///
/// Therefore the return type is `Bytes?` instead of `Bytes`.
pub fn Tls::get_peer_certificate(self : Tls) -> Bytes? raise {
  guard self.is_client else { None }
  let cert = self.conn.peer_certificate()
  guard !cert.is_null() else { raise TlsError(self.conn.take_error_message()) }
  defer cert.free()
  let len = tls_buffer_length(cert)
  guard len > 0 else { return None }
  let result = FixedArray::make(len, b'\x00')
  cert.blit_to_bytes(dst=result, len~)
  Some(result.unsafe_reinterpret_as_bytes())
}

///|
/// Return `tls-unique` type of channel binding data for this TLS connection,
/// according to RFC 5929
pub fn Tls::unique_channel_binding(self : Tls) -> Bytes raise {
  let binding = self.conn.unique_channel_binding()
  guard !binding.is_null() else {
    raise TlsError(self.conn.take_error_message())
  }
  defer binding.free()
  let len = tls_buffer_length(binding)
  guard len > 0 else {
    raise TlsError("tls-unique channel binding unavailable")
  }
  let result = FixedArray::make(len, b'\x00')
  binding.blit_to_bytes(dst=result, len~)
  result.unsafe_reinterpret_as_bytes()
}

///|
/// Return `tls-server-endpoint` type of channel binding data for this TLS connection,
/// according to RFC 5929.
/// Not all TLS connection has such thing as a server certificate,
/// so `tls-unique` is the more recommended approach when available.
pub fn Tls::server_endpoint_channel_binding(self : Tls) -> Bytes raise {
  let binding = self.conn.server_endpoint_channel_binding()
  guard !binding.is_null() else {
    raise TlsError(self.conn.take_error_message())
  }
  defer binding.free()
  let len = tls_buffer_length(binding)
  guard len > 0 else {
    raise TlsError("tls-server-endpoint channel binding unavailable")
  }
  let result = FixedArray::make(len, b'\x00')
  binding.blit_to_bytes(dst=result, len~)
  result.unsafe_reinterpret_as_bytes()
}

///|
let _unused : Unit = {
  ignore((tls : Tls) => tls.is_client)
  ignore((transport : Transport) => transport.flush_write())
}
