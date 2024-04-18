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

fn lex_value(
  ctx : ParseContext,
  ~allow_rbracket : Bool = false
) -> Result[Token, ParseError] {
  for ; ; {
    match read_char(ctx) {
      Some('\t' | '\u000B' | '\u000C' | ' ' | '\n' | '\r') => continue
      Some('/') => {
        lex_comment(ctx)?
        continue
      }
      Some('{') => return Ok(LBrace)
      Some('[') => return Ok(LBracket)
      Some(']') =>
        if allow_rbracket {
          return Ok(RBracket)
        } else {
          return Err(invalid_char(ctx, shift=-1))
        }
      Some('n') => {
        lex_assert_char(ctx, 'u')?
        lex_assert_char(ctx, 'l')?
        lex_assert_char(ctx, 'l')?
        return Ok(Null)
      }
      Some('t') => {
        lex_assert_char(ctx, 'r')?
        lex_assert_char(ctx, 'u')?
        lex_assert_char(ctx, 'e')?
        return Ok(True)
      }
      Some('f') => {
        lex_assert_char(ctx, 'a')?
        lex_assert_char(ctx, 'l')?
        lex_assert_char(ctx, 's')?
        lex_assert_char(ctx, 'e')?
        return Ok(False)
      }
      Some('-' | '+' as c) =>
        match read_char(ctx) {
          Some('I') => {
            lex_infinity(ctx)?
            return Ok(Number(Double::inf(if c == '-' { -1 } else { 1 })))
          }
          Some('N') => {
            lex_assert_char(ctx, 'a')?
            lex_assert_char(ctx, 'N')?
            return Ok(Number(Double::nan()))
          }
          Some('0') => {
            let n = lex_zero(ctx, neg=c == '-', start=ctx.offset - 2)?
            return Ok(Number(n))
          }
          Some('.') => {
            let n = lex_decimal_point_leading(ctx, start=ctx.offset - 2)?
            return Ok(Number(n))
          }
          Some(c2) => {
            if c2 >= '1' && c2 <= '9' {
              let n = lex_decimal_integer(ctx, start=ctx.offset - 2)?
              return Ok(Number(n))
            }
            return Err(invalid_char(ctx, shift=-1))
          }
          None => return Err(InvalidEof)
        }
      Some('.') => {
        let n = lex_decimal_point_leading(ctx, start=ctx.offset - 1)?
        return Ok(Number(n))
      }
      Some('0') => {
        let n = lex_zero(ctx, neg=false, start=ctx.offset - 1)?
        return Ok(Number(n))
      }
      Some('1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9') => {
        let n = lex_decimal_integer(ctx, start=ctx.offset - 1)?
        return Ok(Number(n))
      }
      Some('I') => {
        lex_infinity(ctx)?
        return Ok(Number(Double::inf(1)))
      }
      Some('N') => {
        lex_assert_char(ctx, 'a')?
        lex_assert_char(ctx, 'N')?
        return Ok(Number(Double::nan()))
      }
      Some('"') => {
        let s = lex_string(ctx, '"')?
        return Ok(String(s))
      }
      Some('\'') => {
        let s = lex_string(ctx, '\'')?
        return Ok(String(s))
      }
      Some(c) => {
        if c > '\x7f' && non_ascii_whitespace.contains(c) {
          continue
        }
        return Err(invalid_char(ctx, shift=-1))
      }
      None => return Err(InvalidEof)
    }
  }
}
