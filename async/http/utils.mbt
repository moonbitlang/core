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
/// A token of RFC 9110 section 5.6.2: one or more `tchar`.
const TOKEN : @string.Regex = re"[!#$%&'*+\-.^_`|~0-9A-Za-z]+"

///|
/// `TOKEN` for bytes input.
#cfg(any(target="native", target="wasm"))
const TOKEN_BYTES : @bytes.BytesRegex = reb"[!#$%&'*+\-.^_`|~0-9A-Za-z]+"

///|
/// The chunk extensions after a chunk size (RFC 9112 section 7.1.1), from the
/// first `;`. Each is `;` and a token, optionally followed by `=` and a token
/// or a quoted string; spaces and tabs may surround the name, the `=` and the
/// value. In a quoted string, a character is a visible ASCII character, a
/// space, a tab or one of U+0080 to U+00FF, and `\` escapes the next one.
#cfg(any(target="native", target="wasm"))
const CHUNK_EXTENSIONS : @string.Regex = re"(?:;[ \t]*[!#$%&'*+\-.^_`|~0-9A-Za-z]+[ \t]*(?:=[ \t]*(?:[!#$%&'*+\-.^_`|~0-9A-Za-z]+|\"(?:[\t !#-\[\]-~\u{80}-\u{ff}]|\\[\t -~\u{80}-\u{ff}])*\")[ \t]*)?)+"

///|
#cfg(any(target="native", target="wasm"))
fn is_valid_http_header_field_name(name : StringView) -> Bool {
  name =~ (re"^" + TOKEN + re"$")
}
