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

///|
fn lex_string(ctx : ParseContext) -> String!ParseError {
  let buf = StringBuilder::new()
  let mut start = ctx.offset
  fn flush(end : Int) {
    if start > 0 && end > start {
      buf.write_substring(ctx.input, start, end - start)
    }
  }

  for {
    match read_char(ctx) {
      Some('"') => {
        flush(ctx.offset - 1)
        break
      }
      Some('\n' | '\r') => invalid_char!(ctx, shift=-1)
      Some('\\') => {
        flush(ctx.offset - 1)
        match read_char(ctx) {
          Some('b') => buf.write_char('\b')
          Some('f') => buf.write_char('\x0C')
          Some('n') => buf.write_char('\n')
          Some('r') => buf.write_char('\r')
          Some('t') => buf.write_char('\t')
          Some('"') => buf.write_char('"')
          Some('\\') => buf.write_char('\\')
          Some('/') => buf.write_char('/')
          Some('u') => {
            let c = lex_hex_digits!(ctx, 4)
            buf.write_char(Char::from_int(c))
          }
          Some(_) => invalid_char!(ctx, shift=-1)
          None => raise InvalidEof
        }
        start = ctx.offset
      }
      Some(ch) =>
        if ch.to_int() < 32 {
          invalid_char!(ctx, shift=-1)
        } else {
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
    match read_char(ctx) {
      Some(c) =>
        if c >= 'A' {
          let d = (c.to_int() & (32).lnot()) - 'A'.to_int() + 10
          if d > 15 {
            invalid_char!(ctx, shift=-1)
          }
          r = (r << 4) | d
        } else if c >= '0' {
          let d = c.to_int() - '0'.to_int()
          if d > 9 {
            invalid_char!(ctx, shift=-1)
          }
          r = (r << 4) | d
        } else {
          invalid_char!(ctx, shift=-1)
        }
      None => raise InvalidEof
    }
  }
  r
}
