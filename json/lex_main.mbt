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
/// Character-by-character lexer for a value. `lex_value` calls it only for
/// input its DFA does not lex, which is always an error, so this function
/// decides which error is reported and where.
fn ParseContext::lex_value_slow(
  ctx : ParseContext,
  allow_rbracket~ : Bool,
) -> Token raise ParseError {
  ctx.lex_skip_whitespace()
  match ctx.read_char() {
    Some('{') => return LBrace
    Some('[') => return LBracket
    Some(']') =>
      if allow_rbracket {
        return RBracket
      } else {
        ctx.invalid_char(shift=-1)
      }
    Some('n') => {
      ctx.expect_ascii_char(b'u')
      ctx.expect_ascii_char(b'l')
      ctx.expect_ascii_char(b'l')
      return Null
    }
    Some('t') => {
      ctx.expect_ascii_char(b'r')
      ctx.expect_ascii_char(b'u')
      ctx.expect_ascii_char(b'e')
      return True
    }
    Some('f') => {
      ctx.expect_ascii_char(b'a')
      ctx.expect_ascii_char(b'l')
      ctx.expect_ascii_char(b's')
      ctx.expect_ascii_char(b'e')
      return False
    }
    Some('-') =>
      match ctx.read_char() {
        Some('0') => {
          let { value: n, repr, } = ctx.lex_zero(start=ctx.offset - 2)
          return Number(n, repr.map(repr => repr.to_owned()))
        }
        Some('1'..<='9') => {
          let { value: n, repr, } = ctx.lex_decimal_integer(
            start=ctx.offset - 2,
          )
          return Number(n, repr.map(repr => repr.to_owned()))
        }
        Some(c) => ctx.invalid_char(shift=-c.utf16_len())
        None => raise InvalidEof
      }
    Some('0') => {
      let { value: n, repr, } = ctx.lex_zero(start=ctx.offset - 1)
      return Number(n, repr.map(repr => repr.to_owned()))
    }
    Some('1'..<='9') => {
      let { value: n, repr, } = ctx.lex_decimal_integer(start=ctx.offset - 1)
      return Number(n, repr.map(repr => repr.to_owned()))
    }
    Some('"') => {
      let s = ctx.lex_string()
      return String(s)
    }
    Some(c) => ctx.invalid_char(shift=-c.utf16_len())
    None => raise InvalidEof
  }
}

///|
/// Lexes the token that starts a value, skipping leading whitespace. A single
/// DFA skips the whitespace, recognizes the token and validates a whole
/// number, so a number is converted by `lex_number_end` without being lexed
/// again. Every input the DFA does not lex is malformed; it goes to
/// `lex_value_slow` with the cursor before the token (before its leading
/// whitespace, or at the start of an incomplete number), so the error is the
/// one that lexer reports.
fn ParseContext::lex_value(
  ctx : ParseContext,
  allow_rbracket~ : Bool,
) -> Token raise ParseError {
  lexscan ctx with longest {
    re"^[ \t\r\n]*[{]" => LBrace
    re"^[ \t\r\n]*\[" => LBracket
    re"^[ \t\r\n]*\"" => String(ctx.lex_string())
    re"^[ \t\r\n]*" +
    (re"-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+\-]?[0-9]+)?" as num) => {
      let num_end = ctx.offset
      let { value: n, repr, } = ctx.lex_number_end(
        num_end - num.length(),
        num_end,
      )
      Number(n, repr.map(repr => repr.to_owned()))
    }
    re"^[ \t\r\n]*null" => Null
    re"^[ \t\r\n]*true" => True
    re"^[ \t\r\n]*false" => False
    re"^[ \t\r\n]*\]" =>
      if allow_rbracket {
        RBracket
      } else {
        ctx.invalid_char(shift=-1)
      }
    // A prefix that starts like a number but does not finish as one, such
    // as `1.` or `1e+`, is longer than any valid number match, so this case
    // wins. `lexscan` has already moved the cursor past the prefix; move it
    // back to the start of the number so `lex_value_slow` lexes it again and
    // reports the error at the usual position.
    re"^[ \t\r\n]*" +
    (re"-?(?:0|[1-9][0-9]*)(?:\.[0-9]*)?(?:[eE][+\-]?[0-9]*)?" as prefix) => {
      ctx.offset -= prefix.length()
      ctx.lex_value_slow(allow_rbracket~)
    }
    _ => ctx.lex_value_slow(allow_rbracket~)
  }
}
