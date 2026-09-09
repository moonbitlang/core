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
/// Error type for malformed percent-encoded input.
///
/// `Malformed(input)` reports that `input` contains a `%` that is not
/// followed by two hexadecimal digits, or a run of escaped bytes that is not
/// valid UTF-8.
pub suberror Malformed {
  Malformed(StringView)
} derive(@debug.Debug)

///|
fn hex_value(code_unit : Int) -> Int {
  match code_unit {
    '0'..='9' => code_unit - '0'
    'a'..='f' => code_unit - 'a' + 10
    'A'..='F' => code_unit - 'A' + 10
    _ => -1
  }
}

///|
/// Decodes a percent-encoded URI component back to text.
///
/// Every `%XX` escape (hexadecimal digits in either case) is decoded to one
/// byte, and each maximal run of consecutive escapes is decoded as UTF-8.
/// Everything else, including unescaped non-ASCII characters, is copied
/// through unchanged: a `+` stays a `+`, and a byte order mark is kept.
/// Escapes are decoded exactly once, so `%2520` decodes to `%20`.
///
/// Raises `Malformed` if a `%` is not followed by two hexadecimal digits or
/// if a run of escaped bytes is not valid UTF-8 (truncated or overlong
/// sequences, encoded surrogates, and code points above U+10FFFF). This is
/// the input that makes JavaScript's `decodeURIComponent` throw.
pub fn decode(text : StringView) -> String raise Malformed {
  match decode_impl(text, lossy=false) {
    Some(decoded) => decoded
    None => raise Malformed(text)
  }
}

///|
/// Decodes a percent-encoded URI component, repairing malformed input
/// instead of raising.
///
/// A `%` that is not followed by two hexadecimal digits is kept as a literal
/// `%` and decoding resumes at the next character, so `%2%41` decodes to
/// `%2A`. A run of escaped bytes that is not valid UTF-8 is decoded like
/// `@utf8.decode_lossy`, with each malformed subsequence replaced by U+FFFD.
/// Whenever `decode` succeeds, `decode_lossy` returns the same string.
pub fn decode_lossy(text : StringView) -> String {
  // The implementation only reports failure in strict mode.
  decode_impl(text, lossy=true).unwrap()
}

///|
/// Shared scanner for `decode` and `decode_lossy`. Returns `None` when
/// `lossy` is false and the input is malformed; with `lossy` set it always
/// returns `Some`.
fn decode_impl(text : StringView, lossy~ : Bool) -> String? {
  let length = text.length()
  // size_hint is measured in bytes; the output has at most `length` code
  // units of two bytes each.
  let builder = StringBuilder(size_hint=2 * length)
  let bytes = @buffer.Buffer()
  let mut i = 0
  // Start of the pending span of literal characters, copied in one piece.
  let mut literal_start = 0
  while i < length {
    if text.unsafe_get(i) != '%' {
      i += 1
      continue
    }
    builder.write_view(text.view(start_offset=literal_start, end_offset=i))
    // Collect the maximal run of well-formed escapes into `bytes`.
    bytes.reset()
    let mut resume_after_percent = false
    while i < length && text.unsafe_get(i) == '%' {
      if i + 2 < length {
        let hi = hex_value(text.unsafe_get(i + 1).to_int())
        let lo = hex_value(text.unsafe_get(i + 2).to_int())
        if hi >= 0 && lo >= 0 {
          bytes.write_byte(((hi << 4) | lo).to_byte())
          i += 3
          continue
        }
      }
      guard lossy else { return None }
      resume_after_percent = true
      break
    }
    if lossy {
      builder.write_string(@utf8.decode_lossy(bytes.contents()))
    } else {
      let decoded = @utf8.decode(bytes.contents()) catch { _ => return None }
      builder.write_string(decoded)
    }
    if resume_after_percent {
      // The bytes decoded above precede the malformed escape, whose `%` is
      // kept literally; scanning resumes at the character after it.
      builder.write_char('%')
      i += 1
    }
    literal_start = i
  }
  builder.write_view(text.view(start_offset=literal_start, end_offset=length))
  Some(builder.to_string())
}
