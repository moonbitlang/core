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
fn lex_string(ctx : ParseContext) -> String!ParseError {
  // the first quotation mark is already consumed
  let buf = StringBuilder::new()
  fn bump_and_write(char : Char) {
    ctx.bump()
    buf.write_char(char)
  }

  for {
    match ctx.peek() {
      Some('"') => {
        ctx.bump()
        break
      }
      Some('\n' | '\r' as ch) => invalid_char!(ctx, ch)
      Some('\\') => {
        ctx.bump()
        match ctx.peek() {
          Some('b') => bump_and_write('\b')
          Some('f') => bump_and_write('\x0C')
          Some('n') => bump_and_write('\n')
          Some('r') => bump_and_write('\r')
          Some('t') => bump_and_write('\t')
          Some('"') => bump_and_write('"')
          Some('\\') => bump_and_write('\\')
          Some('/') => bump_and_write('/')
          Some('u') => {
            ctx.bump()
            let c = lex_hex_digits!(ctx, 4)
            buf.write_char(Char::from_int(c))
          }
          Some(c) => invalid_char!(ctx, c)
          None => raise InvalidEof
        }
      }
      Some(ch) =>
        if ch.to_int() < 32 {
          invalid_char!(ctx, ch)
        } else {
          bump_and_write(ch)
          continue
        }
      None => raise InvalidEof
    }
  }
  buf.to_string()
}

///|
fn lex_hex_digits(ctx : ParseContext, n : Int) -> Int!ParseError {
  let mut r = 0
  for i = 0; i < n; i = i + 1 {
    match ctx.peek() {
      Some(c) =>
        if c >= 'A' {
          let d = (c.to_int() & (32).lnot()) - 'A'.to_int() + 10
          if d > 15 {
            invalid_char!(ctx, c)
          }
          ctx.bump()
          r = (r << 4) | d
        } else if c >= '0' {
          let d = c.to_int() - '0'.to_int()
          if d > 9 {
            invalid_char!(ctx, c)
          }
          ctx.bump()
          r = (r << 4) | d
        } else {
          invalid_char!(ctx, c)
        }
      None => raise InvalidEof
    }
  }
  r
}
