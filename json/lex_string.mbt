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
fn @lexbuf.StringScanner::lex_string(
  ctx : @lexbuf.StringScanner,
) -> String raise ParseError {
  let string_start = ctx.cursor
  // Fast path for ordinary strings: scan raw UTF-16 code units and materialize
  // the slice directly when there are no escapes or control characters.
  for i in string_start..<ctx.data.length() {
    let c = ctx.data.unsafe_get(i)
    if c == '"' {
      ctx.cursor = i + 1
      return ctx.data.view(start_offset=string_start, end_offset=i).to_owned()
    } else if c == '\\' {
      return ctx.lex_string_slow()
    } else if c < ' ' {
      // Unescaped control characters (U+0000..U+001F, including \n, \r,
      // \t) are invalid inside a JSON string.
      ctx.cursor = i + 1
      ctx.invalid_char(shift=-1)
    }
  }
  raise InvalidEof
}

///|
/// Slow path for strings that contain escapes: re-scans from the start of the
/// string contents, copying ordinary runs and decoding one escape at a time.
/// Each `lexscan` case is one form from RFC 8259 §7; anything else falls to
/// the wildcard, which leaves the cursor at the failure point and raises with
/// the same positions as the per-character lexer this replaced.
fn @lexbuf.StringScanner::lex_string_slow(
  ctx : @lexbuf.StringScanner,
) -> String raise ParseError {
  let buf = StringBuilder()
  for ;; {
    lexscan ctx {
      re"^\"" => break
      // The longest run of ordinary characters: anything but the closing
      // quote, a backslash, or an unescaped control character. Lone
      // surrogates in the input pass through here unchanged, as they did
      // with the per-character scan.
      re"^[^\"\\\x00-\x1f]+" as run => buf.write_view(run)
      re"^\\\"" => buf.write_char('"')
      re"^\\\\" => buf.write_char('\\')
      re"^\\/" => buf.write_char('/')
      re"^\\b" => buf.write_char('\b')
      re"^\\f" => buf.write_char('\u{0C}')
      re"^\\n" => buf.write_char('\n')
      re"^\\r" => buf.write_char('\r')
      re"^\\t" => buf.write_char('\t')
      // A `\uXXXX` escape denoting a BMP scalar value: the first digit rules
      // out the surrogate range D800–DFFF.
      re"^\\u([0-9A-Ca-cE-Fe-f][0-9A-Fa-f]{3}|[Dd][0-7][0-9A-Fa-f]{2})" as esc =>
        buf.write_char(hex_quad_value(esc[2:]).unsafe_to_char())
      // An escaped surrogate pair — a leading half immediately followed by a
      // trailing half — decodes to the one character it stands for. An
      // escaped half that cannot pair up this way matches no case and is
      // rejected by the wildcard, because decoding it would manufacture a
      // string containing an unpaired surrogate, which MoonBit strings
      // disallow (RFC 8259 calls the behavior for such escapes
      // unpredictable; I-JSON forbids them).
      re"^\\u[Dd][89ABab][0-9A-Fa-f]{2}\\u[Dd][C-Fc-f][0-9A-Fa-f]{2}" as esc => {
        let lead = hex_quad_value(esc[2:6])
        let trail = hex_quad_value(esc[8:12])
        buf.write_char(((lead << 10) + trail - 0x35fdc00).unsafe_to_char())
      }
      _ => ctx.lex_string_failure()
    }
  }
  buf.to_string()
}

///|
/// Decodes exactly four UTF-16 code units of hex digits. The regexes in
/// `lex_string_slow` guarantee the digits, so this cannot fail.
fn hex_quad_value(quad : StringView) -> Int {
  for c in quad; r = 0 {
    let d = match c {
      '0'..='9' => c.to_int() - '0'
      'A'..='F' => c.to_int() - 'A' + 10
      'a'..='f' => c.to_int() - 'a' + 10
      _ => abort("hex_quad_value: caller guarantees hex digits")
    }
    continue (r << 4) | d
  } nobreak {
    r
  }
}

///|
/// Diagnoses the point where `lex_string_slow`'s scan stopped and raises the
/// matching error. The regex cases cover every valid form, so the cursor can
/// only be at the end of input, at an unescaped control character, or at a
/// malformed escape. Re-reading with the same per-character primitives as the
/// old lexer keeps every error position unchanged: a bad escape character or
/// hex digit is blamed itself, while an escape rejected as an unpaired
/// surrogate is blamed at its opening backslash (see `unpaired_surrogate`).
fn[T] @lexbuf.StringScanner::lex_string_failure(
  ctx : @lexbuf.StringScanner,
) -> T raise ParseError {
  let escape_start = ctx.cursor
  match ctx.read_char() {
    Some('\\') =>
      match ctx.read_char() {
        Some('u') => {
          let c = ctx.lex_hex_digits(4)
          if c is (0xD800..=0xDBFF) {
            // A leading half whose pair failed to close. Whatever follows
            // cannot complete it — the pair case would have matched — but
            // scanning it finds where things went wrong: a malformed second
            // escape is still reported as its own error, anything else as
            // the unpaired surrogate it leaves behind.
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
            ctx.lex_hex_digits(4) |> ignore
            ctx.unpaired_surrogate(escape_start)
          } else if c is (0xDC00..=0xDFFF) {
            // A bare trailing-surrogate escape can never form a scalar
            // value.
            ctx.unpaired_surrogate(escape_start)
          } else {
            abort("unreachable: the BMP escape case matches this")
          }
        }
        Some(c) => ctx.invalid_char(shift=-c.utf16_len())
        None => raise InvalidEof
      }
    Some(ch) =>
      if ch.to_int() < 32 {
        ctx.invalid_char(shift=-1)
      } else {
        abort("unreachable: ordinary characters match the run case")
      }
    None => raise InvalidEof
  }
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
fn[T] @lexbuf.StringScanner::unpaired_surrogate(
  ctx : @lexbuf.StringScanner,
  escape_start : Int,
) -> T raise ParseError {
  ctx.invalid_char(shift=escape_start - ctx.cursor)
}

///|
fn @lexbuf.StringScanner::lex_hex_digits(
  ctx : @lexbuf.StringScanner,
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
