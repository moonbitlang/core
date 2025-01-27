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
fn peek(self : ParseContext) -> Char? {
  match self.view {
    [] => None
    [c, ..] => Some(c)
  }
}

///|
fn bump(self : ParseContext, builder? : Builder) -> Unit {
  match self.view {
    [] =>
      // this should be a misuse of the peek & bump api
      abort("empty view")
    [c, .. rest] => {
      if c == '\n' {
        self.line += 1
        self.column = 0
      } else {
        self.column += 1
      }
      self.view = rest
      match builder {
        None => ()
        Some(builder) => builder.builder.write_char(c)
      }
    }
  }
}

///|
fn position(self : ParseContext) -> Position {
  Position::{ line: self.line, column: self.column }
}

///|
fn lex_skip_whitespace(ctx : ParseContext) -> Unit {
  for {
    match ctx.peek() {
      Some('\t' | '\u000B' | '\u000C' | ' ' | '\n' | '\r') => {
        ctx.bump()
        continue
      }
      Some(c) => {
        if c > '\x7f' && non_ascii_whitespace.contains(c) {
          ctx.bump()
          continue
        }
        break
      }
      None => break
    }
  }
}

///|
fn lex_after_array_value(ctx : ParseContext) -> Token!ParseError {
  lex_skip_whitespace(ctx)
  match ctx.peek() {
    Some(']') => {
      ctx.bump()
      RBracket
    }
    Some(',') => {
      ctx.bump()
      Comma
    }
    Some(c) => invalid_char!(ctx, c)
    None => raise InvalidEof
  }
}

///|
fn lex_after_property_name(ctx : ParseContext) -> Token!ParseError {
  lex_skip_whitespace(ctx)
  match ctx.peek() {
    Some(':') => {
      ctx.bump()
      Colon
    }
    Some(c) => invalid_char!(ctx, c)
    None => raise InvalidEof
  }
}

///|
fn lex_after_object_value(ctx : ParseContext) -> Token!ParseError {
  lex_skip_whitespace(ctx)
  match ctx.peek() {
    Some('}') => {
      ctx.bump()
      RBrace
    }
    Some(',') => {
      ctx.bump()
      Comma
    }
    Some(c) => invalid_char!(ctx, c)
    None => raise InvalidEof
  }
}

///|
fn lex_assert_char(ctx : ParseContext, c : Char) -> Unit!ParseError {
  match ctx.peek() {
    Some(c2) => if c == c2 { ctx.bump() } else { invalid_char!(ctx, c2) }
    None => raise InvalidEof
  }
}

///|
fn lex_property_name(ctx : ParseContext) -> Token!ParseError {
  lex_skip_whitespace(ctx)
  match ctx.peek() {
    Some('}') => {
      ctx.bump()
      RBrace
    }
    Some('"') => {
      ctx.bump()
      let s = lex_string!(ctx)
      String(s)
    }
    Some(c) => invalid_char!(ctx, c)
    None => raise InvalidEof
  }
}

///|
fn lex_property_name2(ctx : ParseContext) -> Token!ParseError {
  lex_skip_whitespace(ctx)
  match ctx.peek() {
    Some('"') => {
      ctx.bump()
      let s = lex_string!(ctx)
      String(s)
    }
    Some(c) => invalid_char!(ctx, c)
    None => raise InvalidEof
  }
}
