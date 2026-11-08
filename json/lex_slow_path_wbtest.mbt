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
/// `lex_value` sends only malformed input to `lex_value_slow`, so `parse`
/// never reaches its success branches. It is still a complete lexer: if the
/// DFA missed a valid form, `lex_value_slow` would lex it correctly. This test
/// calls it directly on valid input to keep that property checked.
fn slow_path_token(token : Token) -> String {
  match token {
    Null => "null"
    True => "true"
    False => "false"
    Number(n, repr) => "Number(\{n}, repr=\{repr.unwrap_or("-")})"
    String(s) => "String(\{s})"
    LBrace => "{"
    RBrace => "}"
    LBracket => "["
    RBracket => "]"
    Comma => ","
  }
}

///|
test "lex_value_slow lexes every valid value token" {
  let results = [
    " {", "[", "]", "null", "true", "false", "\"s\"", "0", "-0", "-0.5", "0e1", "7",
    "-7", "12.5", "12e3", "12.5E-3", "1e+2", "12,", "12.5]", "12e3}", "0 ", "12e34",
    "01",
  ].map(input => {
    let ctx = ParseContext::make(input, preserve_number_repr=true)
    let token = slow_path_token(ctx.lex_value_slow(allow_rbracket=true)) catch {
      err => err.to_string()
    }
    (input, token, ctx.sc.cursor)
  })
  // `]` only closes an array that has no elements yet.
  let ctx = ParseContext::make("]")
  let closing = slow_path_token(ctx.lex_value_slow(allow_rbracket=false)) catch {
    err => err.to_string()
  }
  results.push(("] (not allowed)", closing, ctx.sc.cursor))
  @debug.debug_inspect(
    results,
    content=(
      #|[
      #|  (" {", "{", 2),
      #|  ("[", "[", 1),
      #|  ("]", "]", 1),
      #|  ("null", "null", 4),
      #|  ("true", "true", 4),
      #|  ("false", "false", 5),
      #|  ("\"s\"", "String(s)", 3),
      #|  ("0", "Number(0, repr=0)", 1),
      #|  ("-0", "Number(0, repr=-0)", 2),
      #|  ("-0.5", "Number(-0.5, repr=-0.5)", 4),
      #|  ("0e1", "Number(0, repr=0e1)", 3),
      #|  ("7", "Number(7, repr=7)", 1),
      #|  ("-7", "Number(-7, repr=-7)", 2),
      #|  ("12.5", "Number(12.5, repr=12.5)", 4),
      #|  ("12e3", "Number(12000, repr=12e3)", 4),
      #|  ("12.5E-3", "Number(0.0125, repr=12.5E-3)", 7),
      #|  ("1e+2", "Number(100, repr=1e+2)", 4),
      #|  ("12,", "Number(12, repr=12)", 2),
      #|  ("12.5]", "Number(12.5, repr=12.5)", 4),
      #|  ("12e3}", "Number(12000, repr=12e3)", 4),
      #|  ("0 ", "Number(0, repr=0)", 1),
      #|  ("12e34", "Number(1.2e+35, repr=12e34)", 5),
      #|  ("01", "Invalid character '1' at line 1, column 1", 1),
      #|  ("] (not allowed)", "Invalid character ']' at line 1, column 0", 1),
      #|]
    ),
  )
}
