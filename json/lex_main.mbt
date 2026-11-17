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
/// Lexes the token that starts a value, skipping leading whitespace. A single
/// DFA skips the whitespace, recognizes the token and validates a whole
/// number, so a number is converted by `lex_number_end` without being lexed
/// again.
///
/// Malformed input is reported where the previous character-by-character
/// lexer reported it: at the first character that cannot continue a token.
/// The `with longest` rule makes that position the end of the longest match,
/// so the error cases only have to match far enough.
fn ParseContext::lex_value(
  ctx : ParseContext,
  allow_rbracket~ : Bool,
) -> Token raise ParseError {
  lexscan ctx with longest {
    re"^[ \t\r\n]*" + re"[{]" => LBrace
    re"^[ \t\r\n]*" + re"\[" => LBracket
    re"^[ \t\r\n]*" + re"\"" => String(ctx.lex_string())
    re"^[ \t\r\n]*" +
    ((re"-?(0|[1-9][0-9]*)" + re"(\.[0-9]+)?" + re"([eE][+\-]?[0-9]+)?") as num) => {
      let num_end = ctx.offset
      let { value: n, repr, } = ctx.lex_number_end(
        num_end - num.length(),
        num_end,
      )
      Number(n, repr.map(repr => repr.to_owned()))
    }
    re"^[ \t\r\n]*" + re"null" => Null
    re"^[ \t\r\n]*" + re"true" => True
    re"^[ \t\r\n]*" + re"false" => False
    re"^[ \t\r\n]*" + re"\]" =>
      if allow_rbracket {
        RBracket
      } else {
        ctx.invalid_char(shift=-1)
      }
    // Malformed input: a token cut short. None of these is a token, so
    // `with longest` picks one of them only when it matches more than any
    // token case. The input then stops being a token right after the match,
    // and the cursor is at the character to report (or at the end of input).
    //
    // `-` with no digits after it.
    re"^[ \t\r\n]*" + re"-" => ctx.unexpected_char()
    // A number with no digits after its `.`.
    re"^[ \t\r\n]*" + re"-?(0|[1-9][0-9]*)" + re"\." => ctx.unexpected_char()
    // A number with no digits after its `e` or the exponent sign.
    re"^[ \t\r\n]*" +
    re"-?(0|[1-9][0-9]*)" +
    re"(\.[0-9]+)?" +
    re"[eE][+\-]?" => ctx.unexpected_char()
    // A prefix of `null`, `true` or `false`.
    re"^[ \t\r\n]*" + re"(n|nu|nul|t|tr|tru|f|fa|fal|fals)" =>
      ctx.unexpected_char()
    _ => ctx.unexpected_token()
  }
}
