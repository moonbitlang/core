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
let non_ascii_whitespace : CharClass = CharClass::of([
  ('\u00A0', '\u00A0'),
  ('\u1680', '\u1680'),
  ('\u2000', '\u200A'),
  ('\u2028', '\u2029'),
  ('\u202F', '\u202F'),
  ('\u205F', '\u205F'),
  ('\u3000', '\u3000'),
  ('\uFEFF', '\uFEFF'),
])

///|
fn lex_value(
  ctx : ParseContext,
  allow_rbracket~ : Bool = false
) -> Token!ParseError {
  for {
    match ctx.read_char() {
      Some('\t' | ' ' | '\n' | '\r') => continue
      Some('{') => return LBrace
      Some('[') => return LBracket
      Some(']') =>
        if allow_rbracket {
          return RBracket
        } else {
          invalid_char!(ctx, shift=-1)
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
            let n = lex_zero!(ctx, start=ctx.offset - 2)
            return Number(n)
          }
          Some(c2) => {
            if c2 >= '1' && c2 <= '9' {
              let n = lex_decimal_integer!(ctx, start=ctx.offset - 2)
              return Number(n)
            }
            invalid_char!(ctx, shift=-1)
          }
          None => raise InvalidEof
        }
      Some('0') => {
        let n = lex_zero!(ctx, start=ctx.offset - 1)
        return Number(n)
      }
      Some('1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9') => {
        let n = lex_decimal_integer!(ctx, start=ctx.offset - 1)
        return Number(n)
      }
      Some('"') => {
        let s = lex_string!(ctx)
        return String(s)
      }
      Some(c) => {
        if c > '\x7f' && non_ascii_whitespace.contains(c) {
          continue
        }
        invalid_char!(ctx, shift=-1)
      }
      None => raise InvalidEof
    }
  }
}
