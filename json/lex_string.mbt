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
fn ParseContext::lex_string(ctx : ParseContext) -> String raise ParseError {
  let string_start = ctx.offset
  // Fast path for ordinary strings: scan raw UTF-16 code units and materialize
  // the slice directly when there are no escapes or control characters.
  for i in string_start..<ctx.end_offset {
    let c = ctx.input.unsafe_get(i)
    if c == '"' {
      ctx.offset = i + 1
      // The scan bounds guarantee these offsets are inside the input. Preserve
      // raw code units, including unmatched surrogates, when copying the text.
      let base = ctx.input.start_offset()
      return ctx.input
        .data()
        .unsafe_substring(start=base + string_start, end=base + i)
    } else if c == '\\' {
      ctx.offset = i
      return ctx.lex_string_slow(string_start)
    } else if c < ' ' {
      // Unescaped control characters (U+0000..U+001F, including \n, \r,
      // \t) are invalid inside a JSON string.
      ctx.offset = i + 1
      ctx.invalid_char(shift=-1)
    }
  }
  raise InvalidEof
}

///|
/// Lexes the rest of a string that contains escapes. `ctx.offset` is at a
/// backslash, and `run_start..ctx.offset` is literal content not yet copied.
fn ParseContext::lex_string_slow(
  ctx : ParseContext,
  run_start : Int,
) -> String raise ParseError {
  let buf = StringBuilder()
  let mut start = run_start
  fn flush(end : Int) {
    if start > 0 && end > start {
      buf.write_view(ctx.input[start:end])
    }
  }

  let end = ctx.end_offset
  // Everything before the next `"`, `\` or control character is literal
  // content, and none of those code units is a surrogate, so scanning code
  // units stops at the same place as decoding one character at a time.
  for i = ctx.offset {
    guard i < end else { raise InvalidEof }
    let c = ctx.input.unsafe_get(i)
    if c == '"' {
      ctx.offset = i + 1
      flush(i)
      break
    } else if c == '\\' {
      ctx.offset = i + 1
      flush(i)
      match ctx.read_char() {
        Some('b') => buf.write_char('\b')
        Some('f') => buf.write_char('\u{0C}')
        Some('n') => buf.write_char('\n')
        Some('r') => buf.write_char('\r')
        Some('t') => buf.write_char('\t')
        Some('"') => buf.write_char('"')
        Some('\\') => buf.write_char('\\')
        Some('/') => buf.write_char('/')
        Some('u') => {
          // The backslash that opened this escape. `ctx.offset` is just
          // past the `u`, and `\` and `u` are one code unit each.
          let escape_start = ctx.offset - 2
          let c = ctx.lex_hex_digits(4)
          if c is (0xD800..=0xDBFF) {
            // A leading-surrogate escape is only meaningful as the first
            // half of an escaped surrogate pair; combine it with the
            // immediately following trailing-surrogate escape into one
            // Unicode scalar value. Anything else would manufacture a
            // string containing an unpaired surrogate, which MoonBit
            // strings disallow (RFC 8259 calls the behavior for such
            // escapes unpredictable; I-JSON forbids them).
            match ctx.read_char() {
              Some('\\') => ()
              Some(_) => ctx.unpaired_surrogate(escape_start)
              None => raise InvalidEof
            }
            match ctx.read_char() {
              Some('u') => ()
              Some(_) => ctx.unpaired_surrogate(escape_start)
              None => raise InvalidEof
            }
            let c2 = ctx.lex_hex_digits(4)
            if c2 is (0xDC00..=0xDFFF) {
              let combined = (c << 10) + c2 - 0x35fdc00
              buf.write_char(combined.unsafe_to_char())
            } else {
              ctx.unpaired_surrogate(escape_start)
            }
          } else if c is (0xDC00..=0xDFFF) {
            // A bare trailing-surrogate escape can never form a scalar
            // value.
            ctx.unpaired_surrogate(escape_start)
          } else {
            buf.write_char(c.unsafe_to_char())
          }
        }
        Some(c) => ctx.invalid_char(shift=-c.utf16_len())
        None => raise InvalidEof
      }
      start = ctx.offset
      continue ctx.offset
    } else if c < ' ' {
      // An unescaped control character.
      ctx.offset = i + 1
      ctx.invalid_char(shift=-1)
    } else {
      continue i + 1
    }
  }
  buf.to_string()
}

///|
/// Reports the `\uXXXX` escape that begins at `escape_start` as invalid.
///
/// Every rejection of an unpaired surrogate points here — at the backslash
/// opening the offending escape — rather than at whichever character the
/// scan happened to stop on. Blaming the stopping point would name a
/// perfectly valid hex digit for `"\uDC00"`, and for a leading surrogate
/// followed by a non-BMP character it would name a position inside that
/// character.
fn[T] ParseContext::unpaired_surrogate(
  ctx : ParseContext,
  escape_start : Int,
) -> T raise ParseError {
  ctx.invalid_char(shift=escape_start - ctx.offset)
}

///|
fn ParseContext::lex_hex_digits(
  ctx : ParseContext,
  n : Int,
) -> Int raise ParseError {
  for _ in 0..<n; r = 0 {
    let d = match ctx.read_char() {
      Some('0'..='9' as c) => c.to_int() - '0'
      Some('A'..='F' as c) => c.to_int() - 'A' + 10
      Some('a'..='f' as c) => c.to_int() - 'a' + 10
      // `-1` would land inside the character when it is not in the BMP,
      // reporting a broken half at the wrong column.
      Some(c) => ctx.invalid_char(shift=-c.utf16_len())
      None => raise InvalidEof
    }
    continue (r << 4) | d
  } nobreak {
    r
  }
}
