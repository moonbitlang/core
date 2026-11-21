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
  // the slice directly when there are no escapes or control characters. On
  // SIMD targets, this loop checks `LEX_STRING_SCALAR_UNITS` code units, so a
  // shorter key or value is lexed without leaving it; the rest of a longer
  // string is scanned by `lex_string_long`. Scalar targets keep the full loop.
  let end = ctx.end_offset
  let scalar_end = if LEX_STRING_USE_SIMD &&
    end - string_start > LEX_STRING_SCALAR_UNITS {
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
  if LEX_STRING_USE_SIMD {
    ctx.lex_string_long(string_start, scalar_end)
  } else {
    raise InvalidEof
  }
}

///|
/// Native keeps short and medium strings in the scalar loop: switching after
/// 32 units regresses UUID-sized strings. Long strings still benefit from SIMD.
#cfg(target="native")
const LEX_STRING_SCALAR_UNITS = 128

///|
/// Wasm switches after a shorter prefix. Scalar-only targets compile out the
/// dispatch, so this constant has no effect on their scan.
#cfg(not(target="native"))
const LEX_STRING_SCALAR_UNITS = 32

///|
/// Compile out the SIMD dispatch and run-limit bookkeeping on scalar targets.
/// A large scalar threshold would still leave a comparison in the hot loop.
#cfg(any(target="native", target="wasm"))
const LEX_STRING_USE_SIMD = true

///|
#cfg(not(any(target="native", target="wasm")))
const LEX_STRING_USE_SIMD = false

///|
/// Wasm benefits from scanning long runs after escapes with SIMD as well.
#cfg(target="wasm")
const LEX_STRING_ESCAPE_SIMD = true

///|
/// Native retains the scalar escape loop: tracking the next SIMD threshold
/// on every literal unit penalizes densely escaped strings.
#cfg(not(target="wasm"))
const LEX_STRING_ESCAPE_SIMD = false

///|
/// Continues `lex_string` from `from`, where `string_start..from` is known to
/// be literal content, using `find_string_special_long` (eight code units at a
/// time on native and wasm).
fn ParseContext::lex_string_long(
  ctx : ParseContext,
  string_start : Int32,
  from : Int32,
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
  run_start : Int32,
) -> String raise ParseError {
  let end = ctx.end_offset
  // A short initial buffer avoids repeated growth for clustered escapes.
  let buf = StringBuilder(capacity=(end - run_start).min(32))
  let base = ctx.input.start_offset()
  let input = ctx.input.data()
  for i = ctx.offset, start = run_start, scalar_limit = 0 {
    guard i < end else { raise InvalidEof }
    let unit = input.unsafe_get(base + i)
    // A quote, backslash, or raw control is at most U+005C.
    if unit <= '\\' {
      if unit < ' ' {
        ctx.offset = i + 1
        ctx.invalid_char(shift=-1)
      }
      if unit == '"' || unit == '\\' {
        if start < i {
          buf.write_view(input.unsafe_view(start=base + start, end=base + i))
        }
        if unit == '"' {
          ctx.offset = i + 1
          break
        }
        ctx.offset = i + 1
        buf.write_char(ctx.lex_escape())
        continue ctx.offset, ctx.offset, ctx.offset + LEX_STRING_SCALAR_UNITS
      }
    }
    if LEX_STRING_ESCAPE_SIMD && i >= scalar_limit {
      let next = find_string_special_long(input, base + i + 1, base + end)
      continue next - base, start, scalar_limit
    }
    continue i + 1, start, scalar_limit
  }
  buf.to_string()
}

///|
/// The cursor is just past the opening backslash. JSON escape codes are ASCII.
fn ParseContext::lex_escape(ctx : ParseContext) -> Char raise ParseError {
  let i = ctx.offset
  guard i < ctx.end_offset else { raise InvalidEof }
  let escape = ctx.input.unsafe_get(i)
  ctx.offset = i + 1
  match escape {
    'b' => '\b'
    'f' => '\u{0C}'
    'n' => '\n'
    'r' => '\r'
    't' => '\t'
    '"' | '\\' | '/' => escape.unsafe_to_char()
    'u' => ctx.lex_unicode_escape()
    _ => {
      ctx.offset = i
      ctx.reject_char()
    }
  }
}

///|
/// Decode the four digits after `\u` and any required trailing surrogate.
fn ParseContext::lex_unicode_escape(
  ctx : ParseContext,
) -> Char raise ParseError {
  let escape_start = ctx.offset - 2
  let first = ctx.lex_hex_digits(4)
  match first {
    0xD800..<=0xDBFF => {
      guard ctx.input.get(ctx.offset) is Some('\\') else {
        ctx.reject_char(blame=escape_start)
      }
      lexscan ctx {
        re"^\\u" => ()
        _ => {
          ctx.offset += 1
          ctx.reject_char(blame=escape_start)
        }
      }
      let second = ctx.lex_hex_digits(4)
      guard second is (0xDC00..<=0xDFFF) else {
        ctx.unpaired_surrogate(escape_start)
      }
      ((first << 10) + second - 0x35fdc00).unsafe_to_char()
    }
    0xDC00..<=0xDFFF => ctx.unpaired_surrogate(escape_start)
    _ => first.unsafe_to_char()
  }
}

///|
/// Scalar reference for `find_string_special_long`: the first index in
/// `start..<end` of `str` holding `"`, `\` or a control character below
/// U+0020, or `end` if there is none.
fn find_string_special_scalar(
  str : String,
  start : Int32,
  end : Int32,
) -> Int32 {
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
fn find_string_special_long(str : String, start : Int32, end : Int32) -> Int32 {
  find_string_special_scalar(str, start, end)
}

///|
/// Checks eight UTF-16 code units at a time on linear-memory backends, then
/// the remaining tail one code unit at a time. Callers pass
/// `0 <= start <= end <= str.length()`; every load covers `pos..<pos + 8`
/// with `start <= pos` and `end - pos >= 8` (written as a difference so it
/// cannot overflow near `Int::max_value`).
#cfg(any(target="native", target="wasm"))
fn find_string_special_long(str : String, start : Int32, end : Int32) -> Int32 {
  let control_limit = @simd.i16x8_splat(' ')
  let quote = @simd.i16x8_splat('"')
  let backslash = @simd.i16x8_splat('\\')
  let tail_start = for pos = start; end - pos >= 8; {
    let block = @simd.v128_load_i16x8(str, pos)
    let special = @simd.v128_or_(
      @simd.i16x8_lt_u(block, control_limit),
      @simd.v128_or_(
        @simd.i16x8_eq(block, quote),
        @simd.i16x8_eq(block, backslash),
      ),
    )
    if @simd.v128_any_true(special) {
      // Bit `k` of the mask is lane `k`, the code unit at `pos + k`.
      return pos + @simd.i16x8_bitmask(special).ctz()
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
  escape_start : Int32,
) -> T raise ParseError {
  ctx.invalid_char(shift=escape_start - ctx.offset)
}

///|
fn ParseContext::lex_hex_digits(
  ctx : ParseContext,
  n : Int32,
) -> Int32 raise ParseError {
  for _ in 0..<n; r = 0 {
    guard ctx.offset < ctx.end_offset else { raise InvalidEof }
    let unit = ctx.input.unsafe_get(ctx.offset)
    let d = match unit {
      '0'..<='9' => unit.to_int() - '0'
      'A'..<='F' => unit.to_int() - 'A' + 10
      'a'..<='f' => unit.to_int() - 'a' + 10
      _ => ctx.reject_char()
    }
    ctx.offset += 1
    continue (r << 4) | d
  } nobreak {
    r
  }
}

///|
/// Consume the offending character, reporting the opening backslash when an
/// invalid continuation belongs to a surrogate escape.
fn[T] ParseContext::reject_char(
  ctx : ParseContext,
  blame~ : Int32 = ctx.offset,
) -> T raise ParseError {
  guard ctx.offset < ctx.end_offset else { raise InvalidEof }
  ctx.offset += match ctx.input.get_char(ctx.offset) {
    Some(c) => c.utf16_len()
    None => 1
  }
  ctx.invalid_char(shift=blame - ctx.offset)
}
