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
  for i = string_start {
    if i >= ctx.end_offset {
      break
    }
    let c = ctx.input.unsafe_get(i)
    if c == '"' {
      ctx.offset = i + 1
      return ctx.input.view(start_offset=string_start, end_offset=i).to_owned()
    } else if c == '\\' {
      return ctx.lex_string_slow()
    } else if c < ' ' {
      // Unescaped control characters (U+0000..U+001F, including \n, \r,
      // \t) are invalid inside a JSON string.
      ctx.offset = i + 1
      ctx.invalid_char(shift=-1)
    } else if c.is_leading_surrogate() {
      if i + 1 < ctx.end_offset &&
        ctx.input.unsafe_get(i + 1).is_trailing_surrogate() {
        continue i + 2
      }
      // MoonBit strings stay Unicode well-formed, so a raw unpaired
      // surrogate must be rejected rather than smuggled into the parsed
      // string. (Well-formed input cannot contain one, but unsafe code can
      // manufacture such a String; a clean error beats undefined behavior.)
      ctx.offset = i + 1
      ctx.invalid_char(shift=-1)
    } else if c.is_trailing_surrogate() {
      // A bare trailing surrogate can never start a surrogate pair.
      ctx.offset = i + 1
      ctx.invalid_char(shift=-1)
    }
    continue i + 1
  }
  raise InvalidEof
}

///|
fn ParseContext::lex_string_slow(ctx : ParseContext) -> String raise ParseError {
  let buf = StringBuilder()
  let mut start = ctx.offset
  fn flush(end : Int) {
    if end > start {
      // `view(start_offset~, end_offset~)` only bounds-checks. The checked
      // `ctx.input[start:end]` would abort on a trailing surrogate at a
      // slice boundary, which a raw lone surrogate inside the string could
      // place there; unpaired surrogates now raise a ParseError before any
      // flush spans them, and the unchecked slice keeps this loop's
      // totality independent of that validation order.
      buf.write_view(ctx.input.view(start_offset=start, end_offset=end))
    }
  }

  for ;; {
    match ctx.read_char() {
      Some('"') => {
        flush(ctx.offset - 1)
        break
      }
      Some('\\') => {
        flush(ctx.offset - 1)
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
      }
      Some(ch) => {
        let code = ch.to_int()
        if code < 32 {
          ctx.invalid_char(shift=-1)
        } else if code is (0xD800..=0xDFFF) {
          // `read_char` only yields a surrogate-range value when the raw
          // code unit is unpaired; keep parsed strings Unicode well-formed
          // by rejecting it (previously this aborted the process when a
          // later flush sliced across the surrogate).
          ctx.invalid_char(shift=-1)
        } else {
          continue
        }
      }
      None => raise InvalidEof
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
