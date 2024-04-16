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

fn lex_string(ctx : ParseContext, quote : Char) -> Result[String, ParseError] {
  let buf = Buffer::make(0)
  let mut start = ctx.offset
  fn flush(end : Int) {
    if start > 0 && end > start {
      buf.write_sub_string(ctx.input, start, end - start)
    }
  }

  for ; ; {
    match read_char(ctx) {
      Some('\'' | '"' as c) =>
        if c == quote {
          flush(ctx.offset - 1)
          break
        }
      Some('\n' | '\r') => return Err(invalid_char(ctx, shift=-1))
      Some('\\') => {
        flush(ctx.offset - 1)
        match read_char(ctx) {
          Some('b') => buf.write_char('\b')
          Some('f') => buf.write_char('\x0C')
          Some('n') => buf.write_char('\n')
          Some('r') => buf.write_char('\r')
          Some('t') => buf.write_char('\t')
          Some('v') => buf.write_char('\x0B')
          Some('\'') => buf.write_char('\'')
          Some('"') => buf.write_char('"')
          Some('\\') => buf.write_char('\\')
          Some('0') => {
            match read_char(ctx) {
              None => ()
              Some(c) => {
                ctx.offset -= 1
                if c >= '0' && c <= '9' {
                  return Err(invalid_char(ctx))
                }
              }
            }
            buf.write_char('\x00')
          }
          Some('x') => {
            let c = lex_hex_digits(ctx, 2)?
            buf.write_char(Char::from_int(c))
          }
          Some('u') => {
            let c = lex_hex_digits(ctx, 4)?
            buf.write_char(Char::from_int(c))
          }
          Some(c) => {
            if c >= '1' && c <= '9' {
              return Err(invalid_char(ctx, shift=-1))
            }
            buf.write_char(c)
          }
          None => return Err(InvalidEof)
        }
        start = ctx.offset
      }
      Some(_) => continue
      None => return Err(InvalidEof)
    }
  }
  Ok(buf.to_string())
}

fn lex_hex_digits(ctx : ParseContext, n : Int) -> Result[Int, ParseError] {
  let mut r = 0
  for i = 0; i < n; i = i + 1 {
    match read_char(ctx) {
      Some(c) =>
        if c >= 'A' {
          let d = c.to_int().land((32).lnot()) - 'A'.to_int() + 10
          if d > 15 {
            return Err(invalid_char(ctx, shift=-1))
          }
          r = r.lsl(4).lor(d)
        } else if c >= '0' {
          let d = c.to_int() - '0'.to_int()
          if d > 9 {
            return Err(invalid_char(ctx, shift=-1))
          }
          r = r.lsl(4).lor(d)
        } else {
          return Err(invalid_char(ctx, shift=-1))
        }
      None => return Err(InvalidEof)
    }
  }
  Ok(r)
}
