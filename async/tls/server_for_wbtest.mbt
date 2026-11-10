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
/// Encoding type for a X509 certificate file
#warnings("-unused_constructor")
enum X509FileType {
  PEM = 1
  DER = 2
}

///|
async fn test_server(r : &@io.BinaryReader, w : &@io.BinaryWriter) -> Tls {
  Tls::server_from_pair(
    r,
    w,
    private_key_file="async/tls/test_keys/key.pem",
    private_key_type=PEM,
    certificate_file="async/tls/test_keys/cert.pem",
    certificate_type=PEM,
    pfx_file="async/tls/test_keys/cert.pfx",
  )
}

///|
async fn custom_root_test_server(
  r : &@io.BinaryReader,
  w : &@io.BinaryWriter,
  private_key_file : String,
  certificate_file : String,
  pfx_file : String,
) -> Tls {
  Tls::server_from_pair(
    r,
    w,
    private_key_file~,
    private_key_type=PEM,
    certificate_file~,
    certificate_type=PEM,
    pfx_file~,
  )
}

///|
#cfg(all(target="native", not(platform="windows")))
#borrow(file)
extern "C" fn SSL::use_certificate_file(
  self : SSL,
  file : @os_string.OsString,
  file_type : X509FileType,
) -> Int32 = "moonbit_rt_tls_ssl_use_certificate_file"

///|
#cfg(all(target="native", not(platform="windows")))
#borrow(file)
extern "C" fn SSL::use_private_key_file(
  self : SSL,
  file : @os_string.OsString,
  file_type : X509FileType,
) -> Int32 = "moonbit_rt_tls_ssl_use_private_key_file"

///|
#cfg(all(target="native", not(platform="windows")))
extern "C" fn SSL::accept(self : SSL) -> Int32 = "moonbit_rt_tls_ssl_accept"

///|
#cfg(all(target="native", not(platform="windows")))
async fn[R : @io.BinaryReader, W : @io.BinaryWriter] Tls::server_from_pair(
  r : R,
  w : W,
  private_key_file~ : String,
  private_key_type~ : X509FileType,
  certificate_file~ : String,
  certificate_type~ : X509FileType,
  pfx_file~ : String,
) -> Tls {
  ignore(pfx_file)
  load_openssl()
  let private_key_file = @os_string.from_string(private_key_file)
  let certificate_file = @os_string.from_string(certificate_file)
  let ctx = server_ctx.force()
  guard !ctx.is_null() else {
    raise TlsError("failed to initialize SSL server context")
  }
  let self = Tls::from_pair(ctx, r, w, is_client=false, host=None)
  errdefer self.close()
  if self.ssl.use_certificate_file(certificate_file, certificate_type) != 1 {
    raise TlsError(@tls_util.get_tls_error())
  }
  if self.ssl.use_private_key_file(private_key_file, private_key_type) != 1 {
    raise TlsError(@tls_util.get_tls_error())
  }
  while self.ssl.accept() is ret && ret <= 0 {
    self.handle_error(self.ssl.get_error(ret))
  }
  self.transport.flush_write()
  self
}

///|
#cfg(platform="windows")
#borrow(pfx_content)
extern "C" fn Schannel::init_server(
  ch : Schannel,
  pfx_content : Bytes,
) -> Int32 = "moonbit_rt_schannel_init_server"

///|
#cfg(platform="windows")
async fn[R : @io.BinaryReader, W : @io.BinaryWriter] Tls::server_from_pair(
  reader : R,
  writer : W,
  private_key_file~ : String,
  private_key_type~ : X509FileType,
  certificate_file~ : String,
  certificate_type~ : X509FileType,
  pfx_file~ : String,
) -> Tls {
  ignore(private_key_file)
  ignore(private_key_type)
  ignore(certificate_file)
  ignore(certificate_type)
  ignore((_ : @os_string.OsString) => ())
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
#cfg(target="wasm")
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
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(pfx_content)
fn TlsConnectionHandle::set_server_pfx(
  self : TlsConnectionHandle,
  pfx_content : Bytes,
  pfx_content_len~ : Int32 = pfx_content.length(),
) -> Int32 = "moonbitlang/async" "tls/connection/set_server_pfx"

///|
#cfg(target="wasm")
async fn[R : @io.BinaryReader, W : @io.BinaryWriter] Tls::server_from_pair(
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
  let status = if @async.platform is Windows {
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
