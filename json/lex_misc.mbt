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
fn lex_skip_whitespace(ctx : @context.ParseContext) -> Unit {
  for {
    match ctx.read_char() {
      Some('\t' | '\u000B' | '\u000C' | ' ' | '\n' | '\r') => continue
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
fn lex_after_array_value(ctx : @context.ParseContext) -> Token!ParseError {
  lex_skip_whitespace(ctx)
  match ctx.read_char() {
    Some(']') => RBracket
    Some(',') => Comma
    Some(_) => ctx.invalid_char!(shift=-1)
    None => @context.invalid_eof!()
  }
}

///|
fn lex_after_property_name(ctx : @context.ParseContext) -> Token!ParseError {
  lex_skip_whitespace(ctx)
  match ctx.read_char() {
    Some(':') => Colon
    Some(_) => ctx.invalid_char!(shift=-1)
    None => @context.invalid_eof!()
  }
}

///|
fn lex_after_object_value(ctx : @context.ParseContext) -> Token!ParseError {
  lex_skip_whitespace(ctx)
  match ctx.read_char() {
    Some('}') => Token::RBrace
    Some(',') => Token::Comma
    Some(_) => ctx.invalid_char!(shift=-1)
    None => @context.invalid_eof!()
  }
}

///|
fn lex_assert_char(ctx : @context.ParseContext, c : Char) -> Unit!ParseError {
  match ctx.read_char() {
    Some(c2) => if c == c2 { () } else { ctx.invalid_char!(shift=-1) }
    None => @context.invalid_eof!()
  }
}

///|
fn lex_property_name(ctx : @context.ParseContext) -> Token!ParseError {
  lex_skip_whitespace(ctx)
  match ctx.read_char() {
    Some('}') => RBrace
    Some('"') => {
      let s = lex_string!(ctx)
      String(s)
    }
    Some(_) => ctx.invalid_char!(shift=-1)
    None => @context.invalid_eof!()
  }
}

///|
fn lex_property_name2(ctx : @context.ParseContext) -> Token!ParseError {
  lex_skip_whitespace(ctx)
  match ctx.read_char() {
    Some('"') => {
      let s = lex_string!(ctx)
      String(s)
    }
    Some(_) => ctx.invalid_char!(shift=-1)
    None => @context.invalid_eof!()
  }
}
