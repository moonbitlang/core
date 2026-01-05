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
fn ParseContext::read_char(ctx : ParseContext) -> Char? {
  if ctx.offset < ctx.end_offset {
    let c1 = ctx.input.unsafe_charcode_at(ctx.offset)
    ctx.offset += 1
    if c1 >= 0xD800 && c1 <= 0xDBFF {
      if ctx.offset < ctx.end_offset {
        let c2 = ctx.input.unsafe_charcode_at(ctx.offset)
        if c2 >= 0xDC00 && c2 <= 0xDFFF {
          ctx.offset += 1
          let c3 = (c1 << 10) + c2 - 0x35fdc00
          return Some(c3.unsafe_to_char())
        }
      }
    }
    Some(c1.unsafe_to_char())
  } else {
    None
  }
}

///|
/// low surrogate
const SURROGATE_LOW_CHAR = 0xD800

///|
/// high surrogate
const SURROGATE_HIGH_CHAR = 0xDFFF

///|
/// `ctx.expect_char(c)` check the current context is c,
/// if it is, consume the character and return `()`,
/// otherwise raise an error, when it is an error, the position is unspecified.
fn ParseContext::expect_char(
  ctx : ParseContext,
  c : Char,
) -> Unit raise ParseError {
  guard ctx.offset < ctx.end_offset else { raise InvalidEof }
  let c1 = ctx.input.unsafe_charcode_at(ctx.offset)
  ctx.offset += 1
  let c0 = c.to_int()
  if c0 < 0xFFFF {
    // c0 < SURROGATE_LOW_CHAR || c0 is (0xE000..=0XFFFF)  
    // c0 is a valid char so only need check if c0<0xFFFF is BMP code point
    if c0 != c1 {
      ctx.invalid_char(shift=-1)
    }
  } else {
    // c0 is not bmp code point
    // c1 has to be surrogate pair otherwise it is invalid
    guard c1 is (SURROGATE_LOW_CHAR..=SURROGATE_HIGH_CHAR) &&
      ctx.offset < ctx.end_offset else {
      ctx.invalid_char(shift=-1)
    }
    let c2 = ctx.input.unsafe_charcode_at(ctx.offset)
    let c3 = (c1 << 10) + c2 - 0x35fdc00
    if c3 != c0 {
      ctx.invalid_char(shift=-1)
    } else {
      ctx.offset += 1 // consume and move forward
    }
  }
}

///|
/// `ctx.expect_ascii_char(c)` check the current context is c,
/// 
fn ParseContext::expect_ascii_char(
  ctx : ParseContext,
  c : Byte,
) -> Unit raise ParseError {
  guard ctx.offset < ctx.end_offset else { raise InvalidEof }
  let c1 = ctx.input.unsafe_charcode_at(ctx.offset)
  ctx.offset += 1
  if c.to_int() != c1 {
    ctx.invalid_char(shift=-1)
  }
}

///|
test "expect_char" {
  let ctx = ParseContext::make("abc", 1)
  ctx.expect_char('a')
  ctx.expect_char('b')
  ctx.expect_char('c')
  inspect(try? ctx.expect_char('d'), content={ "Err": "InvalidEof" })
}

///|
test "expect_char with surrogate pair" {
  // "\uD83D\uDE00" // todo: shall we allow this?
  let ctx = ParseContext::make("a\u{1F600}bc\u{1F600}c", 1)
  ctx.expect_char('a')
  ctx.expect_char((0x1F600).unsafe_to_char())
  ctx.expect_char('b')
  ctx.expect_char('c')
  ctx.expect_char((0x1F600).unsafe_to_char())
  ctx.expect_char('c')
  inspect(try? ctx.expect_char('d'), content={ "Err": "InvalidEof" })
}

///|
fn ParseContext::lex_skip_whitespace(ctx : ParseContext) -> Unit {
  for {
    match ctx.read_char() {
      Some('\t' | ' ' | '\n' | '\r') => continue
      Some(_) => {
        ctx.offset -= 1
        break
      }
      None => break
    }
  }
}

///|
fn ParseContext::lex_after_array_value(
  ctx : ParseContext,
) -> Token raise ParseError {
  ctx.lex_skip_whitespace()
  match ctx.read_char() {
    Some(']') => RBracket
    Some(',') => Comma
    Some(_) => ctx.invalid_char(shift=-1)
    None => raise InvalidEof
  }
}

///|
fn ParseContext::lex_after_property_name(
  ctx : ParseContext,
) -> Unit raise ParseError {
  ctx.lex_skip_whitespace()
  match ctx.read_char() {
    Some(':') => ()
    Some(_) => ctx.invalid_char(shift=-1)
    None => raise InvalidEof
  }
}

///|
fn ParseContext::lex_after_object_value(
  ctx : ParseContext,
) -> Token raise ParseError {
  ctx.lex_skip_whitespace()
  match ctx.read_char() {
    Some('}') => RBrace
    Some(',') => Comma
    Some(_) => ctx.invalid_char(shift=-1)
    None => raise InvalidEof
  }
}

///|
/// In the context of `{`, try to lex token `}` or a property name,
/// otherwise raise an error.
fn ParseContext::lex_property_name(
  ctx : ParseContext,
) -> Token raise ParseError {
  ctx.lex_skip_whitespace()
  match ctx.read_char() {
    Some('}') => RBrace
    Some('"') => {
      let s = ctx.lex_string()
      String(s)
    }
    Some(_) => ctx.invalid_char(shift=-1)
    None => raise InvalidEof
  }
}

///|
/// In the context of `{ ...,` try to lex a property name,
/// otherwise raise an error.
/// since it is in comma context, `}` is not allowed.
fn ParseContext::lex_property_name2(
  ctx : ParseContext,
) -> Token raise ParseError {
  ctx.lex_skip_whitespace()
  match ctx.read_char() {
    Some('"') => {
      let s = ctx.lex_string()
      String(s)
    }
    Some(_) => ctx.invalid_char(shift=-1)
    None => raise InvalidEof
  }
}
