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
#cfg(platform="windows")
#external
priv type Schannel

///|
#cfg(platform="windows")
extern "C" fn Schannel::new() -> Schannel = "moonbit_rt_schannel_new"

///|
#cfg(platform="windows")
extern "C" fn Schannel::free(ch : Schannel) = "moonbit_rt_schannel_free"

///|
#cfg(platform="windows")
extern "C" fn Schannel::init_client(ch : Schannel, verify~ : Bool) -> Int32 = "moonbit_rt_schannel_init_client"

///|
#cfg(platform="windows")
#borrow(der)
extern "C" fn Schannel::add_root_certificate(
  ch : Schannel,
  der : Bytes,
) -> Int32 = "moonbit_rt_schannel_add_root_certificate"

///|
#cfg(platform="windows")
#borrow(pfx_content)
extern "C" fn Schannel::init_server(
  ch : Schannel,
  pfx_content : Bytes,
) -> Int32 = "moonbit_rt_schannel_init_server"

///|
#cfg(platform="windows")
extern "C" fn Schannel::bytes_read(ch : Schannel) -> Int32 = "moonbit_rt_schannel_bytes_read"

///|
#cfg(platform="windows")
extern "C" fn Schannel::bytes_to_write(ch : Schannel) -> Int32 = "moonbit_rt_schannel_bytes_to_write"

///|
#cfg(platform="windows")
extern "C" fn Schannel::header_size(ch : Schannel) -> Int32 = "moonbit_rt_schannel_header_size"

///|
#cfg(platform="windows")
extern "C" fn Schannel::trailer_size(ch : Schannel) -> Int32 = "moonbit_rt_schannel_trailer_size"

///|
#cfg(platform="windows")
fn Schannel::record_overhead(ch : Schannel) -> Int32 {
  ch.header_size() + ch.trailer_size()
}

///|
#cfg(platform="windows")
priv enum TlsState {
  Completed = 0
  WantRead = 1
  WantWrite = 2
  Error = 3
  Eof = 4
  ReNegotiation = 5
}

///|
#cfg(platform="windows")
#borrow(ch, host, in_buffer, out_buffer)
extern "C" fn Schannel::connect(
  ch : Schannel,
  host : @os_string.OsString?,
  in_buffer~ : Bytes,
  in_buffer_offset~ : Int32,
  in_buffer_len~ : Int32,
  out_buffer~ : FixedArray[Byte],
  out_buffer_offset~ : Int32,
  out_buffer_len~ : Int32,
) -> TlsState = "moonbit_rt_schannel_connect"

///|
#cfg(platform="windows")
#borrow(ch, host)
extern "C" fn Schannel::verify_peer_certificate(
  ch : Schannel,
  host : @os_string.OsString?,
) -> Int32 = "moonbit_rt_schannel_verify_peer_certificate"

///|
#cfg(platform="windows")
#borrow(ch, in_buffer, out_buffer)
extern "C" fn Schannel::accept(
  ch : Schannel,
  in_buffer~ : Bytes,
  in_buffer_offset~ : Int32,
  in_buffer_len~ : Int32,
  out_buffer~ : FixedArray[Byte],
  out_buffer_offset~ : Int32,
  out_buffer_len~ : Int32,
) -> TlsState = "moonbit_rt_schannel_accept"

///|
#cfg(platform="windows")
struct Tls {
  context : Schannel
  is_client : Bool
  host : String?
  reader_ctrl : @io.BinaryReaderController
  writer_ctrl : @io.BinaryWriterController
  transport : Transport
  mut curr_msg_remaining : Int32
  mut curr_msg_trailer : Int32
  mut shutdown : Bool
  mut closed : Bool
}

///|
/// Close a TLS connection and release related resource.
/// THIS FUNCTION MUST BE CALLED BEFORE CLOSING UNDERLYING TRANSPORT!!!
///
/// Note that `.close()` does not provide reliable termination indication for the remote peer.
/// If protected termination is desirable, call `.terminate()` before `.close()`.
#cfg(platform="windows")
pub fn Tls::close(self : Tls) -> Unit {
  guard !self.closed else {  }
  self.closed = true
  if self.transport.state is Normal {
    self.transport.state = Closed
  }
  self.context.free()
}

///|
#cfg(platform="windows")
async fn Tls::connect(self : Tls) -> Unit {
  let host = match self.host {
    None => None
    Some(str) => Some(@os_string.from_string(str))
  }
  let controller = @io.BinaryReaderImpl::get_controller(self.transport.reader)
  let write_buf = self.transport.write_buf
  for ;; {
    let read_buf = controller.buffered()
    let ret = self.context.connect(
      host,
      in_buffer=read_buf.data(),
      in_buffer_offset=read_buf.start_offset(),
      in_buffer_len=read_buf.length(),
      out_buffer=write_buf.buf,
      out_buffer_offset=write_buf.start,
      out_buffer_len=write_buf.buf.length() - write_buf.start - write_buf.len,
    )
    controller.drop(self.context.bytes_read())
    write_buf.len += self.context.bytes_to_write()
    match ret {
      Completed | Eof => {
        self.transport.flush_write()
        break
      }
      WantRead => self.transport.read_more()
      WantWrite => self.transport.flush_write()
      Error => {
        let errno = @errno_util.get_errno()
        raise TlsError(@errno_util.errno_to_string(errno))
      }
      ReNegotiation => panic()
    }
  }
}

///|
/// Create a TLS client that read from `r` and write to `w`.
/// `client_from_pair` will block until TLS handshake to remote server completed.
///
/// `trust` specifies which servers are trusted and how certificate validation is performed.
/// See `TrustedRoot` for more details. The default is `SystemRoot`.
///
/// If `host` is present, it will be used to verify the peer's certificate.
///
/// If `host` is present and `sni` is `true` (`true` by default),
/// Server Name Indication (SNI) field of TLS will be set to `host`.
/// `sni=false` is currently unsupported on Windows.
#cfg(platform="windows")
pub async fn[R : @io.BinaryReader, W : @io.BinaryWriter] Tls::client_from_pair(
  reader : R,
  writer : W,
  host? : String,
  sni~ : Bool = true,
  trust~ : TrustedRoot = SystemRoot,
) -> Tls {
  ignore(sni)
  let context = Schannel::new()
  let transport = Transport::new(reader, writer)
  let tls = {
    context,
    is_client: true,
    host,
    reader_ctrl: BinaryReaderController(),
    writer_ctrl: BinaryWriterController(),
    curr_msg_remaining: 0,
    curr_msg_trailer: 0,
    transport,
    shutdown: false,
    closed: false,
  }
  errdefer tls.close()
  if context.init_client(verify=trust is SystemRoot) is err && err != 0 {
    raise TlsError(@errno_util.errno_to_string(err))
  }
  if trust is CustomPemFile(root_cert) {
    let pem = @fs.read_text(root_cert)
    for cert in decode_pem_certificates(pem) {
      if context.add_root_certificate(cert) is err && err != 0 {
        raise TlsError(@errno_util.errno_to_string(err))
      }
    }
  }
  tls.connect()
  if trust is CustomPemFile(_) {
    let host = match host {
      None => None
      Some(str) => Some(@os_string.from_string(str))
    }
    if tls.context.verify_peer_certificate(host) is err && err != 0 {
      raise TlsError(@errno_util.errno_to_string(err))
    }
  }
  tls
}

///|
#cfg(platform="windows")
async fn Tls::accept(self : Tls) -> Unit {
  let controller = @io.BinaryReaderImpl::get_controller(self.transport.reader)
  let write_buf = self.transport.write_buf
  for ;; {
    let read_buf = controller.buffered()
    let ret = self.context.accept(
      in_buffer=read_buf.data(),
      in_buffer_offset=read_buf.start_offset(),
      in_buffer_len=read_buf.length(),
      out_buffer=write_buf.buf,
      out_buffer_offset=write_buf.start + write_buf.len,
      out_buffer_len=write_buf.buf.length() - write_buf.start - write_buf.len,
    )
    controller.drop(self.context.bytes_read())
    write_buf.len += self.context.bytes_to_write()
    match ret {
      Completed | Eof => {
        self.transport.flush_write()
        break
      }
      WantRead => self.transport.read_more()
      WantWrite => self.transport.flush_write()
      Error => {
        let errno = @errno_util.get_errno()
        raise TlsError(@errno_util.errno_to_string(errno))
      }
      ReNegotiation => panic()
    }
  }
}

///|
#internal(internal, "do not use, for internal testing only")
#cfg(platform="windows")
pub async fn[R : @io.BinaryReader, W : @io.BinaryWriter] Tls::server_from_pair(
  reader : R,
  writer : W,
  pfx_file~ : String,
) -> Tls {
  let context = Schannel::new()
  let pfx_content = @fs.read_binary(pfx_file)
  if context.init_server(pfx_content) is err && err != 0 {
    context.free()
    raise TlsError(@errno_util.errno_to_string(err))
  }
  let transport = Transport::new(reader, writer)
  let tls = {
    context,
    is_client: false,
    host: None,
    reader_ctrl: BinaryReaderController(),
    writer_ctrl: BinaryWriterController(),
    transport,
    curr_msg_remaining: 0,
    curr_msg_trailer: 0,
    shutdown: false,
    closed: false,
  }
  errdefer tls.close()
  tls.accept()
  tls
}

///|
#cfg(platform="windows")
impl @io.BinaryReaderImpl for Tls with fn get_controller(self) {
  self.reader_ctrl
}

///|
#cfg(platform="windows")
#borrow(self, buf)
extern "C" fn Schannel::read(
  self : Schannel,
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
) -> TlsState = "moonbit_rt_schannel_read"

///|
#cfg(platform="windows")
extern "C" fn Schannel::msg_trailer(ch : Schannel) -> Int32 = "moonbit_rt_schannel_msg_trailer"

///|
#cfg(platform="windows")
impl @io.BinaryReaderImpl for Tls with fn raw_read_impl(
  self,
  buf,
  offset~,
  max_len~,
) {
  if self.closed {
    return 0
  }
  let controller = @io.BinaryReaderImpl::get_controller(self.transport.reader)
  while self.curr_msg_remaining == 0 {
    let read_buf = controller.buffered()
    let ret = self.context.read(
      controller.raw_buffer(),
      offset=read_buf.start_offset(),
      len=read_buf.length(),
    )
    match ret {
      Completed => {
        let msg_size = self.context.bytes_read()
        controller.drop(self.context.header_size())
        self.curr_msg_trailer = self.context.msg_trailer()
        self.curr_msg_remaining = msg_size -
          self.context.header_size() -
          self.curr_msg_trailer
      }
      WantRead if read_buf.length() == 0 && self.transport.state is Closed =>
        return 0
      WantRead => self.transport.read_more()
      Eof => {
        self.shutdown()
        return 0
      }
      WantWrite => panic()
      Error => {
        let errno = @errno_util.get_errno()
        raise TlsError(@errno_util.errno_to_string(errno))
      }
      ReNegotiation =>
        if self.is_client {
          self.connect()
        } else {
          self.accept()
        }
    }
  }

  // check if there is remaining data
  let len = @cmp.minimum(self.curr_msg_remaining, max_len)
  let read_buf = controller.buffered()
  controller
  .raw_buffer()
  .blit_to(buf, len~, src_offset=read_buf.start_offset(), dst_offset=offset)
  controller.drop(len)
  self.curr_msg_remaining -= len
  if self.curr_msg_remaining == 0 {
    controller.drop(self.curr_msg_trailer)
  }
  len
}

///|
#cfg(platform="windows")
#borrow(self, buf)
extern "C" fn Schannel::write(
  self : Schannel,
  buf : FixedArray[Byte],
  offset~ : Int32, // `offset` marks the start of the whole message
  len~ : Int32, // `len` is the length of payload
) -> TlsState = "moonbit_rt_schannel_write"

///|
#cfg(platform="windows")
impl @io.BinaryWriterImpl for Tls with fn raw_write_impl(
  self,
  buf,
  offset~,
  len~,
) {
  let write_buf = self.transport.write_buf
  guard! write_buf.len == 0
  let max_len = write_buf.buf.length() -
    write_buf.start -
    self.context.record_overhead()
  let len = @cmp.minimum(len, max_len)
  write_buf.buf.blit_from_bytes(
    write_buf.start + self.context.header_size(), // dst offset
    buf, // dst
    offset, // src offset
    len, // length
  )
  let ret = self.context.write(write_buf.buf, offset=write_buf.start, len~)
  write_buf.len += self.context.bytes_to_write()
  if ret is WantWrite {
    self.transport.flush_write()
    len
  } else {
    let errno = @errno_util.get_errno()
    raise TlsError(@errno_util.errno_to_string(errno))
  }
}

///|
#cfg(platform="windows")
impl @io.BinaryWriterImpl for Tls with fn get_controller(self) {
  self.writer_ctrl
}

///|
#cfg(platform="windows")
#borrow(ch)
extern "C" fn Schannel::shutdown(ch : Schannel) -> Int32 = "moonbit_rt_schannel_shutdown"

///|
/// Start the TLS termination procedure for a TLS connection.
/// `.close()` must still be called after `.shutdown()` to release resources.
/// `.shutdown()` is necessary to reliably terminate a TLS stream
/// and provide protection for truncation attack.
///
/// `.shutdown()` is not necessary for security sake
/// if the application protocol has its own termination indication.
#cfg(platform="windows")
pub async fn Tls::shutdown(self : Tls) -> Unit {
  guard !self.shutdown else {  }
  self.shutdown = true
  match self.transport.state {
    Normal => ()
    Closed => return
    Error(err) => raise err
  }
  if self.context.shutdown() is err && err != 0 {
    raise TlsError(@errno_util.errno_to_string(err))
  }
  if self.is_client {
    self.connect()
  } else {
    self.accept()
  }
}

///|
#cfg(platform="windows")
priv struct PeerCertificate(@c_buffer.Buffer)

///|
#cfg(platform="windows")
extern "C" fn PeerCertificate::free(self : PeerCertificate) -> Unit = "moonbit_rt_schannel_free_peer_certificate"

///|
#cfg(platform="windows")
extern "C" fn PeerCertificate::length(self : PeerCertificate) -> Int32 = "moonbit_rt_schannel_peer_certificate_length"

///|
#cfg(platform="windows")
#borrow(buf)
extern "C" fn PeerCertificate::blit_to(
  self : PeerCertificate,
  buf : FixedArray[Byte],
  len~ : Int32,
) -> Unit = "moonbit_rt_schannel_peer_certificate_blit_to"

///|
#cfg(platform="windows")
#borrow(ch)
extern "C" fn Schannel::get_peer_certificate(ch : Schannel) -> PeerCertificate = "moonbit_rt_schannel_get_peer_certificate"

///|
#cfg(platform="windows")
priv struct ChannelBinding(@c_buffer.Buffer)

///|
#cfg(platform="windows")
extern "C" fn ChannelBinding::free(self : ChannelBinding) -> Unit = "moonbit_rt_schannel_free_channel_binding"

///|
#cfg(platform="windows")
extern "C" fn ChannelBinding::length(self : ChannelBinding) -> Int32 = "moonbit_rt_schannel_channel_binding_length"

///|
#cfg(platform="windows")
#borrow(buf)
extern "C" fn ChannelBinding::blit_to(
  self : ChannelBinding,
  buf : FixedArray[Byte],
  len~ : Int32,
) -> Unit = "moonbit_rt_schannel_channel_binding_blit_to"

///|
#cfg(platform="windows")
#borrow(ch)
extern "C" fn Schannel::unique_channel_binding(ch : Schannel) -> ChannelBinding = "moonbit_rt_schannel_unique_channel_binding"

///|
#cfg(platform="windows")
#borrow(ch)
extern "C" fn Schannel::server_endpoint_channel_binding(
  ch : Schannel,
) -> ChannelBinding = "moonbit_rt_schannel_server_endpoint_channel_binding"

///|
/// Get the certificate of remote peer for a TLS connection in DER format.
/// Note that even if nothing goes wrong, the certificate may not exist:
///
/// - although rare, some TLS algorithm choice does not have a certificate
/// - for connection without client certificate, the server does not have any peer certificate
///
/// Therefore the return type is `Bytes?` instead of `Bytes`.
#cfg(platform="windows")
pub fn Tls::get_peer_certificate(self : Tls) -> Bytes? raise {
  let cert = self.context.get_peer_certificate()
  if cert.0.is_null() {
    @os_error.check_errno("@tls.Tls::get_peer_certificate()")
    // if the error number is 0,
    // no error is happening, the certificate simply does not exist
    return None
  }
  defer cert.free()
  let len = cert.length()
  guard! len > 0
  let result = FixedArray::make(len, b'\x00')
  cert.blit_to(result, len~)
  Some(result.unsafe_reinterpret_as_bytes())
}

///|
#cfg(platform="windows")
fn ChannelBinding::to_bytes(self : ChannelBinding) -> Bytes {
  defer self.free()
  let len = self.length()
  guard! len > 0
  let buf = FixedArray::make(len, b'\x00')
  self.blit_to(buf, len~)
  buf.unsafe_reinterpret_as_bytes()
}

///|
/// Return `tls-unique` type of channel binding data for this TLS connection,
/// according to RFC 5929
#cfg(platform="windows")
pub fn Tls::unique_channel_binding(self : Tls) -> Bytes raise {
  let binding = self.context.unique_channel_binding()
  if binding.0.is_null() {
    let errno = @errno_util.get_errno()
    if errno != 0 {
      raise TlsError(@errno_util.errno_to_string(errno))
    } else {
      raise TlsError("tls-unique channel binding unavailable")
    }
  }
  binding.to_bytes()
}

///|
/// Return `tls-server-endpoint` type of channel binding data for this TLS connection,
/// according to RFC 5929.
/// Not all TLS connection has such thing as a server certificate,
/// so `tls-unique` is the more recommended approach when available.
#cfg(platform="windows")
pub fn Tls::server_endpoint_channel_binding(self : Tls) -> Bytes raise {
  let binding = self.context.server_endpoint_channel_binding()
  if binding.0.is_null() {
    let errno = @errno_util.get_errno()
    if errno != 0 {
      raise TlsError(@errno_util.errno_to_string(errno))
    } else {
      raise TlsError("tls-server-endpoint channel binding unavailable")
    }
  }
  binding.to_bytes()
}

///|
// mute unused warning
#cfg(platform="windows")
let _unused : Unit = {
  ignore(@bytes_util.ascii_to_string)
  ignore(@utf8.encode(""))
  ignore((_ : @lazy.Lazy[Int32]) => ())
  ignore((_ : @ref.Ref[Int32]) => ())
}
