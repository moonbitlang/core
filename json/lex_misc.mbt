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
    let c1 = ctx.input.unsafe_get(ctx.offset).to_int()
    ctx.offset += 1
    if c1 >= 0xD800 && c1 <= 0xDBFF {
      if ctx.offset < ctx.end_offset {
        let c2 = ctx.input.unsafe_get(ctx.offset).to_int()
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
/// Lower bound of the UTF-16 surrogate range.
const SURROGATE_LOW_CHAR = 0xD800

///|
/// Upper bound of the UTF-16 surrogate range.
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
  let c1 = ctx.input.unsafe_get(ctx.offset).to_int()
  ctx.offset += 1
  let c0 = c.to_int()
  if c0 <= 0xFFFF {
    // c0 is a valid character in the BMP.
    if c0 != c1 {
      ctx.invalid_char(shift=-1)
    }
  } else {
    // c0 is not bmp code point
    // c1 has to be surrogate pair otherwise it is invalid
    guard c1 is (SURROGATE_LOW_CHAR..<=SURROGATE_HIGH_CHAR) &&
      ctx.offset < ctx.end_offset else {
      ctx.invalid_char(shift=-1)
    }
    let c2 = ctx.input.unsafe_get(ctx.offset).to_int()
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
  let c1 = ctx.input.unsafe_get(ctx.offset).to_int()
  ctx.offset += 1
  if c.to_int() != c1 {
    ctx.invalid_char(shift=-1)
  }
}

///|
test "expect_char" {
  let ctx = ParseContext::make("abc")
  ctx.expect_char('a')
  ctx.expect_char('b')
  ctx.expect_char('c')
  try ctx.expect_char('d') catch {
    err => json_inspect(err, content="InvalidEof")
  } noraise {
    _ => fail("expected InvalidEof")
  }
}

///|
test "expect_char with surrogate pair" {
  let ctx = ParseContext::make("a\u{1F600}bc\u{1F600}c")
  ctx.expect_char('a')
  ctx.expect_char((0x1F600).unsafe_to_char())
  ctx.expect_char('b')
  ctx.expect_char('c')
  ctx.expect_char((0x1F600).unsafe_to_char())
  ctx.expect_char('c')
  try ctx.expect_char('d') catch {
    err => json_inspect(err, content="InvalidEof")
  } noraise {
    _ => fail("expected InvalidEof")
  }
}

///|
// Skips JSON whitespace (ASCII only, RFC 8259 §2). The token lexers skip
// whitespace inside their `lexscan` DFAs; this is used by their slow paths
// and by `parse` after the top-level value.
//
// `offset` is held in a local for the duration of the scan so each
// consumed whitespace character is one `local.set` instead of a
// `struct.set` against the context.
fn ParseContext::lex_skip_whitespace(ctx : ParseContext) -> Unit {
  let end = ctx.end_offset
  ctx.offset = for offset = ctx.offset {
    if offset >= end {
      break offset
    }
    match ctx.input.unsafe_get(offset) {
      ' ' | '\t' | '\r' | '\n' => continue offset + 1
      _ => break offset
    }
  }
}

///|
test "lex_skip_whitespace" {
  // Empty input: nothing to skip.
  let ctx = ParseContext::make("")
  ctx.lex_skip_whitespace()
  json_inspect(ctx.offset, content=0)
  // Only whitespace: offset advances to end.
  let ctx = ParseContext::make("   \t\r\n")
  ctx.lex_skip_whitespace()
  json_inspect(ctx.offset, content=6)
  // Mixed whitespace before a token: stops at the first non-ws byte.
  let ctx = ParseContext::make(" \t\r\n{")
  ctx.lex_skip_whitespace()
  json_inspect(ctx.offset, content=4)
  // No leading whitespace: offset unchanged.
  let ctx = ParseContext::make("{}")
  ctx.lex_skip_whitespace()
  json_inspect(ctx.offset, content=0)
  // Non-ASCII / Unicode whitespace (e.g. U+00A0 NBSP) must NOT be
  // treated as JSON whitespace — RFC 8259 limits the set to the four
  // ASCII chars handled above.
  let ctx = ParseContext::make("\u{00A0}x")
  ctx.lex_skip_whitespace()
  json_inspect(ctx.offset, content=0)
}

///|
/// Reports the error for an unexpected token: skips whitespace, then raises
/// `InvalidChar` for the next character, or `InvalidEof` at the end of the
/// input. The punctuation lexers call it from their `lexscan` fallback, which
/// leaves the cursor before the whitespace, so the next character is never
/// one they accept.
fn[T] ParseContext::unexpected_token(ctx : ParseContext) -> T raise ParseError {
  ctx.lex_skip_whitespace()
  match ctx.read_char() {
    Some(c) => ctx.invalid_char(shift=-c.utf16_len())
    None => raise InvalidEof
  }
}

///|
test "expect_char at the upper BMP boundary" {
  let ctx = ParseContext::make("\u{FFFF}😀")
  ctx.expect_char('\u{FFFF}')
  ctx.expect_char('😀')
  json_inspect(ctx.offset, content=3)
}

///|
/// In the context of `[`, lexes the `]` of an empty array, skipping leading
/// whitespace, and returns whether it was there. Otherwise the cursor stays
/// before the first element.
fn ParseContext::lex_empty_array_end(ctx : ParseContext) -> Bool {
  lexscan ctx {
    re"^[ \t\r\n]*\]" => true
    _ => false
  }
}

///|
/// Lexes `,` or `]` after an array element, skipping leading whitespace.
/// Anything else is an error, reported by `unexpected_token`.
fn ParseContext::lex_after_array_value(
  ctx : ParseContext,
) -> Token raise ParseError {
  lexscan ctx {
    re"^[ \t\r\n]*," => Comma
    re"^[ \t\r\n]*\]" => RBracket
    _ => ctx.unexpected_token()
  }
}

///|
/// Lexes the `:` after a property name, skipping leading whitespace.
/// Anything else is an error, reported by `unexpected_token`.
fn ParseContext::lex_after_property_name(
  ctx : ParseContext,
) -> Unit raise ParseError {
  lexscan ctx {
    re"^[ \t\r\n]*:" => ()
    _ => ctx.unexpected_token()
  }
}

///|
/// Lexes `,` or `}` after a property value, skipping leading whitespace.
/// Anything else is an error, reported by `unexpected_token`.
fn ParseContext::lex_after_object_value(
  ctx : ParseContext,
) -> Token raise ParseError {
  lexscan ctx {
    re"^[ \t\r\n]*," => Comma
    re"^[ \t\r\n]*[}]" => RBrace
    _ => ctx.unexpected_token()
  }
}

///|
/// A property name with the offset of its opening quote, or `}` (`name` is
/// `None`) with its offset. `#valtype` keeps it out of the heap on native.
#valtype
priv struct PropertyName {
  name : String?
  offset : Int32
}

///|
/// In the context of `{`, lexes `}` or a property name, skipping leading
/// whitespace. Anything else is an error, reported by `unexpected_token`.
fn ParseContext::lex_property_name(
  ctx : ParseContext,
) -> PropertyName raise ParseError {
  lexscan ctx {
    re"^[ \t\r\n]*\"" => {
      let offset = ctx.offset - 1
      { name: Some(ctx.lex_string()), offset, }
    }
    re"^[ \t\r\n]*[}]" => { name: None, offset: ctx.offset - 1, }
    _ => ctx.unexpected_token()
  }
}

///|
/// In the context of `{ ...,`, lexes a property name, skipping leading
/// whitespace. Anything else is an error, reported by `unexpected_token`.
fn ParseContext::lex_property_name2(
  ctx : ParseContext,
) -> PropertyName raise ParseError {
  lexscan ctx {
    re"^[ \t\r\n]*\"" => {
      let offset = ctx.offset - 1
      { name: Some(ctx.lex_string()), offset, }
    }
    _ => ctx.unexpected_token()
  }
}
