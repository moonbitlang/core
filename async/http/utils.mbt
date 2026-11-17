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
#cfg(any(target="native", target="wasm"))
fn encode_int(value : Int32, base~ : Int32) -> Bytes {
  let len = for x = value, len = 1; x >= base; {
    continue x / base, len + 1
  } nobreak {
    len
  }
  let out = FixedArray::make(len, b'0')
  for x = value, i = len - 1; i >= 0; x = x / base, i = i - 1 {
    let digit = x % base
    let chr = if digit < 10 { digit + '0' } else { digit - 10 + 'a' }
    out[i] = chr.to_byte()
  }
  out.unsafe_reinterpret_as_bytes()
}

///|
fn is_token_char(c : UInt16) -> Bool {
  match c {
    'A'..<='Z' => true
    'a'..<='z' => true
    '0'..<='9' => true
    '!'
    | '#'
    | '$'
    | '%'
    | '&'
    | '\''
    | '*'
    | '+'
    | '-'
    | '.'
    | '^'
    | '_'
    | '`'
    | '|'
    | '~' => true
    _ => return false
  }
}

///|
/// A `token` (RFC 9110 §5.6.2): one or more `tchar`.
#cfg(any(target="native", target="wasm"))
const TOKEN = re"[!#$%&'*+\-.^_`|~0-9A-Za-z]+"

///|
/// Optional whitespace, `OWS` (RFC 9110 §5.6.3). `BWS` has the same syntax.
#cfg(any(target="native", target="wasm"))
const OWS = re"[ \t]*"

///|
/// A `quoted-string` (RFC 9110 §5.6.4): `qdtext` and `quoted-pair` between
/// double quotes. `obs-text` is the code units 0x80 to 0xFF.
#cfg(any(target="native", target="wasm"))
const QUOTED_STRING = re"\"([\t !#-\[\]-~\u{80}-\u{ff}]|\\[\t -~\u{80}-\u{ff}])*\""

///|
#cfg(any(target="native", target="wasm"))
fn is_valid_http_header_field_name(name : StringView) -> Bool {
  lexmatch name {
    re"^" + TOKEN + re"$" => true
    _ => false
  }
}

///|
/// Validates the extensions after a chunk size, starting at their first `;`
/// (RFC 9112 §7.1.1):
///
/// ```text
/// chunk-ext = *( BWS ";" BWS chunk-ext-name [ BWS "=" BWS chunk-ext-val ] )
/// chunk-ext-name = token
/// chunk-ext-val  = token / quoted-string
/// ```
///
/// Each step matches one extension: its name, then an optional value.
#cfg(any(target="native", target="wasm"))
fn validate_chunk_extension(extension : StringView) -> Unit raise {
  guard extension is [';', ..] else { raise BadRequest }
  for rest = extension {
    lexmatch rest with longest {
      re"^$" => return
      (re"^;" + OWS + TOKEN + OWS, after=rest) =>
        lexmatch rest with longest {
          (re"^=" + OWS + TOKEN + OWS, after=rest) => continue rest
          (re"^=" + OWS + QUOTED_STRING + OWS, after=rest) => continue rest
          _ => continue rest
        }
      _ => raise BadRequest
    }
  }
}
