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
fn ParseContext::lex_value(
  ctx : ParseContext,
  allow_rbracket~ : Bool,
) -> Token raise ParseError {
  for {
    match ctx.read_char() {
      Some('\t' | ' ' | '\n' | '\r') => continue
      Some('{') => return LBrace
      Some('[') => return LBracket
      Some(']') =>
        if allow_rbracket {
          return RBracket
        } else {
          ctx.invalid_char(shift=-1)
        }
      Some('n') => {
        ctx.expect_ascii_char('u')
        ctx.expect_ascii_char('l')
        ctx.expect_ascii_char('l')
        return Null
      }
      Some('t') => {
        ctx.expect_ascii_char('r')
        ctx.expect_ascii_char('u')
        ctx.expect_ascii_char('e')
        return True
      }
      Some('f') => {
        ctx.expect_ascii_char('a')
        ctx.expect_ascii_char('l')
        ctx.expect_ascii_char('s')
        ctx.expect_ascii_char('e')
        return False
      }
      Some('-') =>
        match ctx.read_char() {
          Some('0') => {
            let (n, repr) = ctx.lex_zero(start=ctx.offset - 2)
            return Number(n, repr.map(_.to_string()))
          }
          Some(c2) => {
            if c2 is ('1'..='9') {
              let (n, repr) = ctx.lex_decimal_integer(start=ctx.offset - 2)
              return Number(n, repr.map(_.to_string()))
            }
            ctx.invalid_char(shift=-1)
          }
          None => raise InvalidEof
        }
      Some('0') => {
        let (n, repr) = ctx.lex_zero(start=ctx.offset - 1)
        return Number(n, repr.map(_.to_string()))
      }
      Some('1'..='9') => {
        let (n, repr) = ctx.lex_decimal_integer(start=ctx.offset - 1)
        return Number(n, repr.map(_.to_string()))
      }
      Some('"') => {
        let s = ctx.lex_string()
        return String(s)
      }
      Some(c) => {
        let shift = -c.utf16_len()
        ctx.invalid_char(shift~)
      }
      None => raise InvalidEof
    }
  }
}
