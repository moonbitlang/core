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
fn ParseContext::read_char(ctx : ParseContext) -> Char? {
  if ctx.offset < ctx.end_offset {
    let c = ctx.input[ctx.offset]
    ctx.offset += 1
    let c1 = c.to_int()
    if c1 >= 0xD800 && c1 <= 0xDBFF {
      if ctx.offset < ctx.end_offset {
        let c2 = ctx.input[ctx.offset].to_int()
        if c2 >= 0xDC00 && c2 <= 0xDFFF {
          ctx.offset += 1
          let c3 = (c1 << 10) + c2 - 0x35fdc00
          return Some(Char::from_int(c3))
        }
      }
    }
    Some(c)
  } else {
    None
  }
}

///|
fn ParseContext::lex_skip_whitespace(ctx : ParseContext) -> Unit {
  for {
    match ctx.read_char() {
      Some('\t' | ' ' | '\n' | '\r') => continue
      Some(c) => {
        if c > '\x7f' && non_ascii_whitespace.contains(c) {
          continue
        }
        ctx.offset -= 1
        break
      }
      None => break
    }
  }
}

///|
fn ParseContext::lex_after_array_value(ctx : ParseContext) -> Token!ParseError {
  ctx.lex_skip_whitespace()
  match ctx.read_char() {
    Some(']') => RBracket
    Some(',') => Comma
    Some(_) => ctx.invalid_char!(shift=-1)
    None => raise InvalidEof
  }
}

///|
fn ParseContext::lex_after_property_name(ctx : ParseContext) -> Unit!ParseError {
  ctx.lex_skip_whitespace()
  match ctx.read_char() {
    Some(':') => ()
    Some(_) => ctx.invalid_char!(shift=-1)
    None => raise InvalidEof
  }
}

///|
fn ParseContext::lex_after_object_value(ctx : ParseContext) -> Token!ParseError {
  ctx.lex_skip_whitespace()
  match ctx.read_char() {
    Some('}') => RBrace
    Some(',') => Comma
    Some(_) => ctx.invalid_char!(shift=-1)
    None => raise InvalidEof
  }
}

///|
fn ParseContext::lex_assert_char(
  ctx : ParseContext,
  c : Char
) -> Unit!ParseError {
  match ctx.read_char() {
    Some(c2) => if c != c2 { ctx.invalid_char!(shift=-1) }
    None => raise InvalidEof
  }
}

///|
/// In the context of `{`, try to lex token `}` or a property name,
/// otherwise raise an error.
fn ParseContext::lex_property_name(ctx : ParseContext) -> Token!ParseError {
  ctx.lex_skip_whitespace()
  match ctx.read_char() {
    Some('}') => RBrace
    Some('"') => {
      let s = ctx.lex_string!()
      String(s)
    }
    Some(_) => ctx.invalid_char!(shift=-1)
    None => raise InvalidEof
  }
}

///|
/// In the context of `{ ...,` try to lex a property name,
/// otherwise raise an error.
/// since it is in comma context, `}` is not allowed.
fn ParseContext::lex_property_name2(ctx : ParseContext) -> Token!ParseError {
  ctx.lex_skip_whitespace()
  match ctx.read_char() {
    Some('"') => {
      let s = ctx.lex_string!()
      String(s)
    }
    Some(_) => ctx.invalid_char!(shift=-1)
    None => raise InvalidEof
  }
}
