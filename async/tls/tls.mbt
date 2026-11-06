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
/// TLS related error
#derive(@debug.Debug, @json.ToJson)
suberror TlsError {
  TlsError(String)
}

///|
pub impl Show for TlsError with fn to_string(self) {
  let TlsError(msg) = self
  msg
}

///|
pub extend TlsError with Show::{to_string}

///|
/// Raise if `self` has been closed.
/// `close` frees the native TLS state,
/// so every operation that touches it must call this first.
fn Tls::check_not_closed(self : Tls, context : String) -> Unit raise TlsError {
  guard !self.closed else {
    raise TlsError("\{context}: TLS connection is already closed")
  }
}

///|
/// Run `f`, which uses the native TLS state.
/// `close` may be called while `f` is suspended,
/// so the native state is kept alive until `f` returns,
/// and freed then if the connection has been closed meanwhile.
/// `f` should check `check_not_closed` again after each suspension.
async fn[T] Tls::with_native_state(
  self : Tls,
  context : String,
  f : async () -> T,
) -> T {
  self.check_not_closed(context)
  self.active_ops += 1
  defer {
    self.active_ops -= 1
    if self.closed && self.active_ops == 0 {
      self.free_native_state()
    }
  }
  f()
}

///|
/// A verified certificate chain only proves that a trusted root issued the
/// certificate. `host` is what ties the certificate to the intended server,
/// so a verifying client without `host` would accept any trusted certificate.
fn check_client_host(
  host : String?,
  trust : TrustedRoot,
) -> Unit raise TlsError {
  guard trust is NoVerification || (host is Some(host) && host != "") else {
    raise TlsError(
      "`@tls.Tls::client()`: `host` is required to verify the peer's certificate. Pass the expected server name or IP address as `host`, or `trust=NoVerification` to skip certificate verification entirely",
    )
  }
  // The native TLS libraries take `host` as a C string,
  // which would silently end at the first NUL and verify a different name
  // (or, with a leading NUL, no name at all).
  if host is Some(host) && host.contains("\u{0}") {
    raise TlsError(
      "`@tls.Tls::client()`: `host` must not contain NUL characters",
    )
  }
}

///|
/// Error raised when the peer abnormally close the underlying transport
/// in a TLS connection.
#derive(@debug.Debug, @json.ToJson)
pub suberror ConnectionClosed

///|
const PEM_BEGIN = "-----BEGIN CERTIFICATE-----"

///|
const PEM_END = "-----END CERTIFICATE-----"

///|
fn decode_pem_certificates(pem : String) -> Array[Bytes] raise TlsError {
  let certs = []
  for chunk in pem.split(PEM_BEGIN) {
    match chunk.split_once(PEM_END) {
      None => ()
      Some((base64_body, _)) => {
        let cert = @base64.decode(base64_body.trim(), ignore_whitespace=true) catch {
          _ =>
            raise TlsError(
              "invalid PEM certificate in custom root certificate file",
            )
        }
        certs.push(cert)
      }
    }
  }
  guard !certs.is_empty() else {
    raise TlsError("no PEM certificate found in custom root certificate file")
  }
  certs
}

///|
/// Encoding type for a X509 certificate file
pub(all) enum X509FileType {
  PEM = 1
  ANS1 = 2
}

///|
/// Create a TLS client that read from write to `inner`.
/// `client` will block until TLS handshake to remote server completed.
///
/// `trust` specifies which servers are trusted and how certificate validation is performed.
/// See `TrustedRoot` for more details. The default is `SystemRoot`.
///
/// `host` is the expected name of the server, and is used to verify the
/// peer's certificate. It is required unless `trust` is `NoVerification`:
/// without it, any certificate issued by a trusted root would be accepted,
/// whichever server it was issued to, so `client` raises `TlsError` instead.
///
/// If `host` is present and `sni` is `true` (`true` by default),
/// Server Name Indication (SNI) field of TLS will be set to `host`.
/// `sni=false` is currently unsupported on Windows.
pub async fn[Inner : @io.BinaryReader + @io.BinaryWriter] Tls::client(
  inner : Inner,
  host? : String,
  sni~ : Bool = true,
  trust? : TrustedRoot,
) -> Tls {
  Tls::client_from_pair(inner, inner, host?, sni~, trust?)
}

///|
pub impl @io.BinaryReader for Tls

///|
pub extend Tls with @io.BinaryReader::{
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
pub impl @io.BinaryWriter for Tls

///|
pub extend Tls with @io.BinaryWriter::{write, write_reader}
