// Copyright 2024 International Digital Economy Academy
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

fn lex_property_name(ctx : ParseContext) -> Result[Token, ParseError] {
  lex_skip_whitespace(ctx)?
  match read_char(ctx) {
    Some('}') => Ok(RBrace)
    Some('\'' | '"' as c) => {
      let s = lex_string(ctx, c)?
      Ok(String(s))
    }
    Some('$' | '_') => {
      let s = lex_ident(ctx, ctx.offset - 1)?
      Ok(String(s))
    }
    Some('\\') => {
      lex_assert_char(ctx, 'u')?
      let c = lex_hex_digits(ctx, 4)?
      let c = Char::from_int(c)
      if c == '$' || c == '_' || c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' ||
      c > '\x7f' && non_ascii_id_start.contains(c) {
        let buffer = StringBuilder::make()
        buffer.add_char(c)
        let s = lex_ident(ctx, ctx.offset, ~buffer)?
        Ok(String(s))
      } else {
        Err(InvalidIdentEscape(offset_to_position(ctx.input, ctx.offset - 6)))
      }
    }
    Some(c) => {
      if c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c > '\x7f' && non_ascii_id_start.contains(
        c,
      ) {
        let s = lex_ident(ctx, ctx.offset - 1)?
        return Ok(String(s))
      }
      Err(invalid_char(ctx, shift=-1))
    }
    None => Err(InvalidEof)
  }
}

fn lex_ident(
  ctx : ParseContext,
  start : Int,
  ~buffer : StringBuilder = StringBuilder::make()
) -> Result[String, ParseError] {
  let mut start = start
  fn flush(end : Int) {
    if start > 0 && end > start {
      buffer.add_substring(ctx.input, start, end)
    }
  }

  for ; ; {
    match read_char(ctx) {
      Some('\\') => {
        flush(ctx.offset - 1)
        lex_assert_char(ctx, 'u')?
        let c = lex_hex_digits(ctx, 4)?
        let c = Char::from_int(c)
        if c == '$' || c == '_' || c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' ||
        c >= '0' && c <= '9' || c > '\x7f' && non_ascii_id_continue.contains(c) {
          buffer.add_char(c)
          start = ctx.offset
          continue
        } else {
          return Err(
            InvalidIdentEscape(offset_to_position(ctx.input, ctx.offset - 6)),
          )
        }
      }
      Some('$' | '_') => continue
      Some(c) => {
        if c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c >= '0' && c <= '9' ||
        c > '\x7f' && non_ascii_id_continue.contains(c) {
          continue
        }
        ctx.offset -= 1
        break
      }
      None => break
    }
  }
  flush(ctx.offset)
  Ok(buffer.to_string())
}
