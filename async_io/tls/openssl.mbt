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
#cfg(not(platform="windows"))
#external
priv type SSL_CTX

///|
#cfg(not(platform="windows"))
extern "C" fn SSL_CTX::is_null(self : SSL_CTX) -> Bool = "moonbit_rt_tls_ssl_ctx_is_null"

///|
#cfg(not(platform="windows"))
extern "C" fn SSL_CTX::client(load_default_verify_path~ : Bool) -> SSL_CTX = "moonbit_rt_tls_client_ctx"

///|
#cfg(not(platform="windows"))
extern "C" fn SSL_CTX::server() -> SSL_CTX = "moonbit_rt_tls_server_ctx"

///|
#cfg(not(platform="windows"))
extern "C" fn SSL_CTX::free_ffi(self : SSL_CTX) = "moonbit_rt_tls_ssl_ctx_free"

///|
#cfg(not(platform="windows"))
#borrow(der)
extern "C" fn SSL_CTX::add_root_certificate(
  self : SSL_CTX,
  der : Bytes,
) -> Int32 = "moonbit_rt_tls_ssl_ctx_add_root_certificate"

// Lazy singletons: the shared client/server contexts (and the system CA read
// they trigger) are built on first use, not before a TLS connection is made.

///|
#cfg(not(platform="windows"))
let client_ctx : @lazy.Lazy[SSL_CTX] = Lazy(() => {
  SSL_CTX::client(load_default_verify_path=true)
})

///|
#cfg(not(platform="windows"))
let server_ctx : @lazy.Lazy[SSL_CTX] = Lazy(() => SSL_CTX::server())

///|
#cfg(not(platform="windows"))
fn SSL_CTX::free(self : SSL_CTX) -> Unit {
  // Never free the shared singletons. Compare against the CACHED contexts without
  // forcing their creation (a `free` must not lazily spin up a context just to check).
  if client_ctx.peek() is Some(c) && physical_equal(self, c) {
    return
  }
  if server_ctx.peek() is Some(s) && physical_equal(self, s) {
    return
  }
  self.free_ffi()
}

///|
#cfg(not(platform="windows"))
#external
priv type SSL

///|
#cfg(not(platform="windows"))
extern "C" fn SSL::new(ctx : SSL_CTX, rbio : BIO, wbio : BIO) -> SSL = "moonbit_rt_tls_ssl_new"

///|
#cfg(not(platform="windows"))
extern "C" fn SSL::connect(self : SSL) -> Int32 = "moonbit_rt_tls_ssl_connect"

///|
#cfg(not(platform="windows"))
#borrow(host)
extern "C" fn SSL::set_host(self : SSL, host : Bytes) -> Int32 = "moonbit_rt_tls_ssl_set_host"

///|
#cfg(not(platform="windows"))
#borrow(host)
extern "C" fn SSL::set_sni(self : SSL, host : Bytes) -> Int32 = "moonbit_rt_tls_ssl_set_sni"

///|
#cfg(not(platform="windows"))
extern "C" fn SSL::set_verify(self : SSL, verify : Bool) = "moonbit_rt_tls_ssl_set_verify"

///|
#cfg(not(platform="windows"))
extern "C" fn SSL::accept(self : SSL) -> Int32 = "moonbit_rt_tls_ssl_accept"

///|
#cfg(not(platform="windows"))
priv struct PeerCertificate(@c_buffer.Buffer)

///|
#cfg(not(platform="windows"))
extern "C" fn PeerCertificate::free(self : PeerCertificate) -> Unit = "moonbit_rt_tls_free_peer_certificate"

///|
#cfg(not(platform="windows"))
extern "C" fn PeerCertificate::length(self : PeerCertificate) -> Int32 = "moonbit_rt_tls_peer_certificate_length"

///|
#cfg(not(platform="windows"))
#borrow(buf)
extern "C" fn PeerCertificate::blit_to(
  self : PeerCertificate,
  buf : FixedArray[Byte],
  len~ : Int32,
) -> Unit = "moonbit_rt_tls_peer_certificate_blit_to"

///|
#cfg(not(platform="windows"))
#borrow(len)
extern "C" fn PeerCertificate::server_endpoint_hash(
  self : PeerCertificate,
  len~ : @ref.Ref[Int32],
) -> @c_buffer.Buffer = "moonbit_rt_tls_hash_server_endpoint_certificate"

///|
#cfg(not(platform="windows"))
extern "C" fn SSL::get_certificate(
  self : SSL,
  is_client~ : Bool,
) -> PeerCertificate = "moonbit_rt_tls_ssl_get_certificate"

///|
#cfg(not(platform="windows"))
extern "C" fn SSL::unique_channel_binding_length(
  self : SSL,
  is_client~ : Bool,
) -> Int32 = "moonbit_rt_tls_ssl_unique_channel_binding_length"

///|
#cfg(not(platform="windows"))
#borrow(buf)
extern "C" fn SSL::unique_channel_binding(
  self : SSL,
  buf : FixedArray[Byte],
  len~ : Int32,
  is_client~ : Bool,
) -> Unit = "moonbit_rt_tls_ssl_unique_channel_binding"

///|
#cfg(not(platform="windows"))
#borrow(file)
extern "C" fn SSL::use_certificate_file(
  self : SSL,
  file : Bytes,
  file_type : X509FileType,
) -> Int32 = "moonbit_rt_tls_ssl_use_certificate_file"

///|
#cfg(not(platform="windows"))
#borrow(file)
extern "C" fn SSL::use_private_key_file(
  self : SSL,
  file : Bytes,
  file_type : X509FileType,
) -> Int32 = "moonbit_rt_tls_ssl_use_private_key_file"

///|
#cfg(not(platform="windows"))
#borrow(buf)
extern "C" fn SSL::read(
  self : SSL,
  buf : FixedArray[Byte],
  offset : Int32,
  len : Int32,
) -> Int32 = "moonbit_rt_tls_ssl_read"

///|
#cfg(not(platform="windows"))
#borrow(buf)
extern "C" fn SSL::write(
  self : SSL,
  buf : Bytes,
  offset : Int32,
  len : Int32,
) -> Int32 = "moonbit_rt_tls_ssl_write"

///|
#cfg(not(platform="windows"))
extern "C" fn SSL::shutdown(self : SSL) -> Int32 = "moonbit_rt_tls_ssl_shutdown"

///|
#cfg(not(platform="windows"))
extern "C" fn SSL::free(self : SSL) = "moonbit_rt_tls_ssl_free"

///|
#cfg(not(platform="windows"))
extern "C" fn SSL::get_error(self : SSL, ret : Int32) -> Int32 = "moonbit_rt_tls_ssl_get_error"

///|
#cfg(not(platform="windows"))
const SSL_ERROR_SSL = 1

///|
#cfg(not(platform="windows"))
const SSL_ERROR_WANT_READ = 2

///|
#cfg(not(platform="windows"))
const SSL_ERROR_WANT_WRITE = 3

///|
#cfg(not(platform="windows"))
const SSL_ERROR_SYSCALL = 5

///|
#cfg(not(platform="windows"))
const SSL_ERROR_ZERO_RETURN = 6

///|
#cfg(not(platform="windows"))
extern "C" fn err_peek_error_code() -> UInt64 = "moonbit_rt_tls_peek_error_code"

///|
#cfg(not(platform="windows"))
#borrow(buf)
extern "C" fn err_get_error_ffi(buf : Bytes) -> Int32 = "moonbit_rt_tls_get_error"

///|
#cfg(not(platform="windows"))
fn err_get_error() -> String {
  let buf = Bytes::make(256, 0)
  let len = err_get_error_ffi(buf)
  @bytes_util.ascii_to_string(buf[:len])
}

///|
#cfg(not(platform="windows"))
#external
priv type BIO

///|
#cfg(not(platform="windows"))
extern "C" fn BIO::get_endpoint(bio : BIO) -> Transport = "moonbit_rt_tls_bio_get_endpoint"

///|
#cfg(not(platform="windows"))
extern "C" fn BIO::set_flags(bio : BIO, flags : Int32) = "moonbit_rt_tls_bio_set_flags"

///|
// Also the sole consumer of the BIO method table `load_openssl` registers.
#cfg(not(platform="windows"))
#owned(data)
extern "C" fn create_bio(data : Transport) -> BIO = "moonbit_rt_tls_create_bio"

///|
#cfg(not(platform="windows"))
const BIO_FLAGS_READ = 0x01

///|
#cfg(not(platform="windows"))
const BIO_FLAGS_WRITE = 0x02

///|
#cfg(not(platform="windows"))
const BIO_FLAGS_SHOULD_RETRY = 0x08

///|
#cfg(not(platform="windows"))
fn BIO::read(bio : BIO, dst : @c_buffer.Buffer, len : Int32) -> Int32 {
  let ep = bio.get_endpoint()
  match ep.state {
    Normal => ()
    Closed => return 0
    Error(_) => return -1
  }
  let controller = @io.BinaryReaderImpl::get_controller(ep.reader)
  let buffered = controller.buffered()
  guard buffered.length() > 0 else {
    bio.set_flags(BIO_FLAGS_READ | BIO_FLAGS_SHOULD_RETRY)
    -1
  }
  let len = @cmp.minimum(buffered.length(), len)
  dst.blit_from_bytes(
    src=buffered.data(),
    src_offset=buffered.start_offset(),
    len~,
  )
  controller.drop(len)
  len
}

///|
#cfg(not(platform="windows"))
fn BIO::write(bio : BIO, src : @c_buffer.Buffer, len : Int32) -> Int32 {
  let ep = bio.get_endpoint()
  guard ep.state is Normal else { -1 }
  let end = ep.write_buf.start + ep.write_buf.len
  let remaining = ep.write_buf.buf.length() - end
  guard remaining > 0 else {
    bio.set_flags(BIO_FLAGS_WRITE | BIO_FLAGS_SHOULD_RETRY)
    -1
  }
  let len = @cmp.minimum(len, remaining)
  src.blit_to_bytes(dst=ep.write_buf.buf, dst_offset=end, len~)
  ep.write_buf.len += len
  len
}

///|
/// A TLS-encrypted connection
#cfg(not(platform="windows"))
struct Tls {
  ssl : SSL
  ctx : SSL_CTX
  host : String?
  is_client : Bool
  transport : Transport
  reader_ctrl : @io.BinaryReaderController
  writer_ctrl : @io.BinaryWriterController
  mut shutdown : Bool
  mut closed : Bool
}

///|
#cfg(not(platform="windows"))
fn[R : @io.BinaryReader, W : @io.BinaryWriter] Tls::from_pair(
  ctx : SSL_CTX,
  r : R,
  w : W,
  is_client~ : Bool,
  host~ : String?,
) -> Tls {
  let transport = Transport::new(r, w)
  let rbio = create_bio(transport)
  let wbio = create_bio(transport)
  let ssl = SSL::new(ctx, rbio, wbio)
  {
    ssl,
    ctx,
    host,
    is_client,
    transport,
    reader_ctrl: BinaryReaderController(),
    writer_ctrl: BinaryWriterController(),
    shutdown: false,
    closed: false,
  }
}

///|
#cfg(not(platform="windows"))
async fn SSL_CTX::client_with_custom_root(root_cert : String) -> SSL_CTX {
  let ctx = SSL_CTX::client(load_default_verify_path=false)
  if ctx.is_null() {
    return ctx
  }
  errdefer ctx.free()
  let pem = @fs.read_text(root_cert)
  for cert in decode_pem_certificates(pem) {
    if ctx.add_root_certificate(cert) != 1 {
      raise TlsError(err_get_error())
    }
  }
  ctx
}

///|
#cfg(not(platform="windows"))
async fn Tls::handle_error(self : Tls, err : Int32) -> Unit {
  match err {
    SSL_ERROR_WANT_READ => {
      self.transport.flush_write()
      self.transport.read_more()
    }
    SSL_ERROR_WANT_WRITE => {
      self.transport.flush_write()
      self.transport.write_buf.enlarge_to(1)
    }
    SSL_ERROR_SSL | SSL_ERROR_SYSCALL => raise TlsError(err_get_error())
    SSL_ERROR_ZERO_RETURN => raise ConnectionClosed
    err => abort("unexpected error code \{err} from OpenSSL")
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
#cfg(not(platform="windows"))
#label_migration(verify, fill=false, msg="use `trust` instead")
pub async fn[R : @io.BinaryReader, W : @io.BinaryWriter] Tls::client_from_pair(
  r : R,
  w : W,
  verify~ : Bool = true,
  host? : String,
  sni~ : Bool = true,
  trust? : TrustedRoot,
) -> Tls {
  load_openssl()
  let trust = match trust {
    Some(trust) => trust
    None => if verify { SystemRoot } else { NoVerification }
  }
  let ctx = match trust {
    NoVerification | SystemRoot => client_ctx.force()
    CustomPemFile(root_cert) => SSL_CTX::client_with_custom_root(root_cert)
  }
  guard !ctx.is_null() else {
    raise TlsError("failed to initialize SSL client context")
  }
  let self = Tls::from_pair(ctx, r, w, is_client=true, host~)
  errdefer self.close()
  if trust is NoVerification {
    self.ssl.set_verify(false)
  }
  if host is Some(host) {
    let host = @utf8.encode(host)
    guard self.ssl.set_host(host) > 0 else { raise TlsError(err_get_error()) }
    if sni {
      guard self.ssl.set_sni(host) > 0 else { raise TlsError(err_get_error()) }
    }
  }
  while self.ssl.connect() is ret && ret <= 0 {
    self.handle_error(self.ssl.get_error(ret))
  }
  self.transport.flush_write()
  self
}

///|
/// WARNING: this API is currently for testing only,
/// it may block the whole thread while reading certificate,
/// and may break any time in the future. DO NOT USE.
///
/// Create a TLS server connection that read from `r` and write to `w`.
/// `server_from_pair` will block until TLS handshake with client completed.
///
/// `private_key_file`, `private_key_type` specifies the private key of the server.
/// `certificate_file` and `certificate_type` specifies the certificate of the server.
#cfg(not(platform="windows"))
#internal(internal, "do not use, for internal testing only")
pub async fn[R : @io.BinaryReader, W : @io.BinaryWriter] Tls::server_from_pair(
  r : R,
  w : W,
  private_key_file~ : String,
  private_key_type~ : X509FileType,
  certificate_file~ : String,
  certificate_type~ : X509FileType,
) -> Tls {
  load_openssl()
  let private_key_file = @utf8.encode(private_key_file)
  let certificate_file = @utf8.encode(certificate_file)
  let ctx = server_ctx.force()
  guard !ctx.is_null() else {
    raise TlsError("failed to initialize SSL server context")
  }
  let self = Tls::from_pair(ctx, r, w, is_client=false, host=None)
  errdefer self.close()
  if self.ssl.use_certificate_file(certificate_file, certificate_type) != 1 {
    raise TlsError(err_get_error())
  }
  if self.ssl.use_private_key_file(private_key_file, private_key_type) != 1 {
    raise TlsError(err_get_error())
  }
  while self.ssl.accept() is ret && ret <= 0 {
    self.handle_error(self.ssl.get_error(ret))
  }
  self.transport.flush_write()
  self
}

///|
/// WARNING: this API is currently for testing only,
/// it may block the whole thread while reading certificate,
/// and may break any time in the future. DO NOT USE.
///
/// Create a TLS server connection that read from and write to `inner`.
/// `server` will block until TLS handshake with client completed.
///
/// `private_key_file`, `private_key_type` specifies the private key of the server.
/// `certificate_file` and `certificate_type` specifies the certificate of the server.
#cfg(not(platform="windows"))
#internal(internal, "do not use, for internal testing only")
pub async fn[Inner : @io.BinaryReader + @io.BinaryWriter] Tls::server(
  inner : Inner,
  private_key_file~ : String,
  private_key_type~ : X509FileType,
  certificate_file~ : String,
  certificate_type~ : X509FileType,
) -> Tls {
  Tls::server_from_pair(
    inner,
    inner,
    private_key_file~,
    private_key_type~,
    certificate_file~,
    certificate_type~,
  )
}

///|
#cfg(not(platform="windows"))
impl @io.BinaryReaderImpl for Tls with fn raw_read_impl(
  self,
  buf,
  offset~,
  max_len~,
) {
  let controller = @io.BinaryReaderImpl::get_controller(self.transport.reader)
  let n = while self.ssl.read(buf, offset, max_len) is ret {
    if ret > 0 {
      break ret
    }
    let err = self.ssl.get_error(ret)
    if err is SSL_ERROR_ZERO_RETURN {
      // the peer initiates closure
      self.shutdown()
      break 0
    }
    if self.transport.state is Closed && controller.buffered().length() is 0 {
      // Not all TLS client/servers close the connection properly.
      // Some peers just close the underlying TCP connection
      // without performing a TLS closure.
      // So we treat this case as normal here.
      break 0
    }
    self.handle_error(err)
  } nobreak {
    0
  }
  // imposible
  self.transport.flush_write()
  n
}

///|
#cfg(not(platform="windows"))
impl @io.BinaryReaderImpl for Tls with fn get_controller(self) {
  self.reader_ctrl
}

///|
#cfg(not(platform="windows"))
impl @io.BinaryWriterImpl for Tls with fn raw_write_impl(
  self,
  buf,
  offset~,
  len~,
) {
  let n = while self.ssl.write(buf, offset, len) is ret {
    if ret > 0 {
      break ret
    }
    self.handle_error(self.ssl.get_error(ret))
  } nobreak {
    0
  }
  // imposible
  self.transport.flush_write()
  n
}

///|
#cfg(not(platform="windows"))
impl @io.BinaryWriterImpl for Tls with fn get_controller(self) {
  self.writer_ctrl
}

///|
/// Close a TLS connection and release related resource.
/// THIS FUNCTION MUST BE CALLED BEFORE CLOSING UNDERLYING TRANSPORT!!!
///
/// Note that `.close()` does not provide reliable termination indication for the remote peer.
/// If protected termination is desirable, call `.terminate()` before `.close()`.
#cfg(not(platform="windows"))
pub fn Tls::close(self : Tls) -> Unit {
  guard !self.closed else {  }
  self.closed = true
  if self.transport.state is Normal {
    self.transport.state = Closed
  }
  self.ssl.free()
  self.ctx.free()
  // We must make sure the host string lives longer than `self.ssl`
  ignore(self.host)
}

///|
/// Shutdown a TLS connection gracefully.
/// This function MUST be called before `close`,
/// and MUST NOT be called if the TLS connection fail with other error.
///
/// `shutdown` is used to initiate the closure of a TLS connection.
/// So there is no need to call `shutdown` if you receive EOF from the peer.
///
/// When calling `shutdown`,
/// there may still be pending data sent by the peer on the wire.
/// So to close a TLS connection cleanly,
/// make sure you read from the connection until EOF after calling `shutdown`.
///
/// Note that the main purpose of TLS shutdown is to ensure integrity
/// before closing the underlying transport.
/// So if your application protocol has its own way of ensuring integrity
/// (e.g. `Content-Length` in HTTP/1.1),
/// it is not necessary to call `shutdown`.
#cfg(not(platform="windows"))
pub async fn Tls::shutdown(self : Tls) -> Unit {
  guard !self.shutdown else {  }
  self.shutdown = true
  match self.transport.state {
    Normal => ()
    Closed => raise ConnectionClosed
    Error(err) => raise err
  }
  while self.ssl.shutdown() is ret && ret < 0 {
    let err = self.ssl.get_error(ret)
    self.handle_error(err)
  } nobreak {
    self.transport.flush_write()
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
#cfg(not(platform="windows"))
pub fn Tls::get_peer_certificate(self : Tls) -> Bytes? raise {
  guard self.is_client else { None }
  let cert = self.ssl.get_certificate(is_client=true)
  if cert.0.is_null() {
    if err_peek_error_code() != 0 {
      raise TlsError(err_get_error())
    } else {
      return None
    }
  }
  defer cert.free()
  let len = cert.length()
  guard! len > 0
  let result = FixedArray::make(len, b'\x00')
  cert.blit_to(result, len~)
  Some(result.unsafe_reinterpret_as_bytes())
}

///|
/// Return `tls-unique` type of channel binding data for this TLS connection,
/// according to RFC 5929
#cfg(not(platform="windows"))
pub fn Tls::unique_channel_binding(self : Tls) -> Bytes raise {
  let len = self.ssl.unique_channel_binding_length(is_client=self.is_client)
  guard len > 0 else {
    if err_peek_error_code() != 0 {
      raise TlsError(err_get_error())
    } else {
      raise TlsError("tls-unique channel binding unavailable")
    }
  }
  let result = FixedArray::make(len, b'\x00')
  self.ssl.unique_channel_binding(result, len~, is_client=self.is_client)
  result.unsafe_reinterpret_as_bytes()
}

///|
/// Return `tls-server-endpoint` type of channel binding data for this TLS connection,
/// according to RFC 5929.
/// Not all TLS connection has such thing as a server certificate,
/// so `tls-unique` is the more recommended approach when available.
#cfg(not(platform="windows"))
pub fn Tls::server_endpoint_channel_binding(self : Tls) -> Bytes raise {
  let cert = self.ssl.get_certificate(is_client=self.is_client)
  if cert.0.is_null() {
    if err_peek_error_code() != 0 {
      raise TlsError(err_get_error())
    } else {
      raise TlsError("tls-server-endpoint channel binding unavailable")
    }
  }
  // for the server, the result is obtained by `SSL_get_certificate`,
  // which should not be freed by us according to https://docs.openssl.org/3.3/man3/SSL_get_certificate
  defer (if self.is_client { cert.free() })
  let len = @ref.Ref(0)
  let hash = cert.server_endpoint_hash(len~)
  if hash.is_null() {
    raise TlsError(err_get_error())
  }
  let result = FixedArray::make(len.val, b'\x00')
  hash.blit_to_bytes(dst=result, len=len.val)
  result.unsafe_reinterpret_as_bytes()
}

///|
// mute unused warning
#cfg(not(platform="windows"))
let _unused : Unit = {
  ignore(@os_error.check_errno)
  ignore(@os_string.from_string)
  ignore((_ : @fs.File) => ())
  ignore(@errno_util.errno_to_string)
}
