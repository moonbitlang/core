// Copyright 2025 International Digital Economy Academy
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
fn lex_value(
  ctx : @context.ParseContext,
  allow_rbracket~ : Bool = false
) -> Token!ParseError {
  for {
    ctx.lex_skip_whitespace()  
    match ctx.read_char() {
      // Some('\t' | ' ' | '\n' | '\r') => continue
      Some('{') => return LBrace
      Some('[') => return LBracket
      Some(']') =>
        if allow_rbracket {
          return RBracket
        } else {
          ctx.invalid_char!(shift=-1)
        }
      Some('n') => {
        lex_assert_char!(ctx, 'u')
        lex_assert_char!(ctx, 'l')
        lex_assert_char!(ctx, 'l')
        return Null
      }
      Some('t') => {
        lex_assert_char!(ctx, 'r')
        lex_assert_char!(ctx, 'u')
        lex_assert_char!(ctx, 'e')
        return True
      }
      Some('f') => {
        lex_assert_char!(ctx, 'a')
        lex_assert_char!(ctx, 'l')
        lex_assert_char!(ctx, 's')
        lex_assert_char!(ctx, 'e')
        return False
      }
      Some('-') =>
        match ctx.read_char() {
          Some('0') => {
            let n = ctx.lex_zero!(start=ctx.offset - 2)
            return Number(n)
          }
          Some(c2) => {
            if c2 >= '1' && c2 <= '9' {
              let n = ctx.lex_decimal_integer!(start=ctx.offset - 2)
              return Number(n)
            }
            ctx.invalid_char!(shift=-1)
          }
          None => @context.invalid_eof!()
        }
      Some('0') => {
        let n = ctx.lex_zero!(start=ctx.offset - 1)
        return Number(n)
      }
      Some('1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9') => {
        let n = ctx.lex_decimal_integer!(start=ctx.offset - 1) 
        return Number(n)
      }
      Some('"') => {
        let s = lex_string!(ctx)
        return String(s)
      }
      Some(_) => {
        // if c > '\x7f' && non_ascii_whitespace.contains(c) {
        //   continue
        // }
        ctx.invalid_char!(shift=-1)
      }
      None => @context.invalid_eof!()
    }
  }
}
