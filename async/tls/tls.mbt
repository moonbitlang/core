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
suberror TlsError {
  TlsError(String)
} derive(@debug.Debug, @json.ToJson)

///|
pub impl Show for TlsError with fn to_string(self) {
  let TlsError(msg) = self
  msg
}

///|
pub extend TlsError with Show::{to_string}

///|
/// Error raised when the peer abnormally close the underlying transport
/// in a TLS connection.
pub suberror ConnectionClosed derive(@debug.Debug, @json.ToJson)

///|
const PEM_BEGIN = "-----BEGIN CERTIFICATE-----"

///|
const PEM_END = "-----END CERTIFICATE-----"

///|
// Wasm TLS dispatches server credential shape from the host runtime platform.
let _target_specific_imports : Unit = ignore(@event_loop.platform)

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
/// If `host` is present, it will be used to verify the peer's certificate.
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
