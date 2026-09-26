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
  // the slice directly when there are no escapes or control characters. This
  // loop checks the first `LEX_STRING_SCALAR_UNITS` code units, so a key or
  // value shorter than that is lexed without leaving it; the rest of a longer
  // string is scanned by `lex_string_long`.
  let end = ctx.end_offset
  let scalar_end = if end - string_start > LEX_STRING_SCALAR_UNITS {
    string_start + LEX_STRING_SCALAR_UNITS
  } else {
    end
  }
  for i in string_start..<scalar_end {
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
  ctx.lex_string_long(string_start, scalar_end)
}

///|
/// How many code units `lex_string` checks one at a time before
/// `lex_string_long` takes over; after each escape, `lex_string_slow` checks
/// one more literal unit than this before switching to
/// `find_string_special_long`. Only which scan runs depends on it, never the
/// result.
#cfg(any(target="native", target="wasm"))
const LEX_STRING_SCALAR_UNITS = 16

///|
/// Without SIMD, `find_string_special_long` is the same one-unit-at-a-time
/// scan, so runs of any practical length stay in the lexer's own loops.
#cfg(not(any(target="native", target="wasm")))
const LEX_STRING_SCALAR_UNITS = 0x3FFFFFFF

///|
/// Continues `lex_string` from `from`, where `string_start..from` is known to
/// be literal content, using `find_string_special_long` (eight code units at a
/// time on native and wasm).
fn ParseContext::lex_string_long(
  ctx : ParseContext,
  string_start : Int,
  from : Int,
) -> String raise ParseError {
  let base = ctx.input.start_offset()
  let i = find_string_special_long(
      ctx.input.data(),
      base + from,
      base + ctx.end_offset,
    ) -
    base
  guard i < ctx.end_offset else { raise InvalidEof }
  let c = ctx.input.unsafe_get(i)
  if c == '"' {
    ctx.offset = i + 1
    ctx.input.data().unsafe_substring(start=base + string_start, end=base + i)
  } else if c == '\\' {
    ctx.offset = i
    ctx.lex_string_slow(string_start)
  } else {
    ctx.offset = i + 1
    ctx.invalid_char(shift=-1)
  }
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
  // units stops at the same place as decoding one character at a time. After
  // an escape, this loop checks literal units up to offset `scalar_limit`,
  // and `find_string_special_long` scans the rest of the run. (The first unit
  // is the backslash, which sets `scalar_limit`. If the addition wraps, the
  // switch just happens sooner; either scan finds the same unit.)
  for i = ctx.offset, scalar_limit = ctx.offset {
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
      continue ctx.offset, ctx.offset + LEX_STRING_SCALAR_UNITS
    } else if c < ' ' {
      // An unescaped control character.
      ctx.offset = i + 1
      ctx.invalid_char(shift=-1)
    } else if i < scalar_limit {
      continue i + 1, scalar_limit
    } else {
      // Lands on the next `"`, `\` or control character, or on `end`.
      let base = ctx.input.start_offset()
      continue find_string_special_long(
          ctx.input.data(),
          base + i + 1,
          base + end,
        ) -
        base,
        scalar_limit
    }
  }
  buf.to_string()
}

///|
/// Scalar reference for `find_string_special_long`: the first index in
/// `start..<end` of `str` holding `"`, `\` or a control character below
/// U+0020, or `end` if there is none.
fn find_string_special_scalar(str : String, start : Int, end : Int) -> Int {
  for i in start..<end {
    let c = str.unsafe_get(i)
    if c == '"' || c == '\\' || c < ' ' {
      break i
    }
  } nobreak {
    end
  }
}

///|
#cfg(not(any(target="native", target="wasm")))
fn find_string_special_long(str : String, start : Int, end : Int) -> Int {
  find_string_special_scalar(str, start, end)
}

///|
/// Checks eight UTF-16 code units at a time on linear-memory backends, then
/// the remaining tail one code unit at a time. Callers pass
/// `0 <= start <= end <= str.length()`; every load covers `pos..<pos + 8`
/// with `start <= pos` and `end - pos >= 8` (written as a difference so it
/// cannot overflow near `Int::max_value`).
#cfg(any(target="native", target="wasm"))
fn find_string_special_long(str : String, start : Int, end : Int) -> Int {
  let control_limit = @v128.i16x8_splat(' ')
  let quote = @v128.i16x8_splat('"')
  let backslash = @v128.i16x8_splat('\\')
  let tail_start = for pos = start; end - pos >= 8; {
    let block = @v128.v128_load_i16x8(str, pos)
    let special = @v128.v128_or_(
      @v128.i16x8_lt_u(block, control_limit),
      @v128.v128_or_(
        @v128.i16x8_eq(block, quote),
        @v128.i16x8_eq(block, backslash),
      ),
    )
    if @v128.v128_any_true(special) {
      // Bit `k` of the mask is lane `k`, the code unit at `pos + k`.
      return pos + @v128.i16x8_bitmask(special).ctz()
    }
    continue pos + 8
  } nobreak {
    pos
  }
  find_string_special_scalar(str, tail_start, end)
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
