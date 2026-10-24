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
fn is_VCHAR(c : UInt16) -> Bool {
  c is (0x21..<=0x7E | ' ' | '\t' | 0x80..<=0xFF)
}

///|
fn is_valid_http_header_field_name(name : StringView) -> Bool {
  for c in name.code_units() {
    guard is_token_char(c) else { return false }
  } nobreak {
    !name.is_empty()
  }
}

///|
fn trim_OWS(input : ArrayView[UInt16]) -> ArrayView[UInt16] {
  for input = input {
    match input {
      [' ' | '\t', .. rest] => continue rest
      _ => break input
    }
  }
}

///|
fn validate_token(input : ArrayView[UInt16]) -> ArrayView[UInt16] raise {
  guard input is [first, .. input] && is_token_char(first) else {
    raise BadRequest
  }
  for input = input; input is [first, .. rest]; input = rest {
    guard is_token_char(first) else { break input }
  } nobreak {
    input
  }
}

///|
/// Validate a quoted string, `input` should not contain the first character
fn validate_quoted_string(input : ArrayView[UInt16]) -> ArrayView[UInt16] raise {
  for input = input; input is [first, .. rest]; input = rest {
    match first {
      '\\' => {
        guard rest is [next, .. rest] else { raise BadRequest }
        guard is_VCHAR(next.to_int().to_uint16()) else { raise BadRequest }
        continue rest
      }
      '"' => break rest
      _ if is_VCHAR(first) => ()
      _ => raise BadRequest
    }
  } nobreak {
    raise BadRequest
  }
}

///|
fn validate_chunk_extension(extension : StringView) -> Unit raise {
  guard extension.code_units() is [';', .. start] else { raise BadRequest }
  for rest = start {
    let rest = trim_OWS(rest)
    let rest = validate_token(rest)
    let rest = match trim_OWS(rest) {
      ['=', .. rest] => {
        let rest = match trim_OWS(rest) {
          ['"', .. rest] => validate_quoted_string(rest)
          rest => validate_token(rest)
        }
        trim_OWS(rest)
      }
      rest => rest
    }
    match rest {
      [] => return
      [';', .. rest] => continue rest
      _ => raise BadRequest
    }
  }
}
