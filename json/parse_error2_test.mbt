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
test "parse error" {
  debug_inspect(
    expect_parse_error("[1, 2, \u000c]", "expected InvalidChar"),
    content=(
      #|InvalidChar({ line: 1, column: 7 }, '\u{0c}')
    ),
  )
}

///|
test "astral parse errors point to the first UTF-16 code unit" {
  debug_inspect(
    expect_parse_error("[0😀]", "expected InvalidChar"),
    content="InvalidChar({ line: 1, column: 2 }, '😀')",
  )
  // Columns still count UTF-16 code units, including earlier astral characters.
  debug_inspect(
    expect_parse_error("[\n\"😀\"😀]", "expected InvalidChar"),
    content="InvalidChar({ line: 2, column: 4 }, '😀')",
  )
}

///|
test "invalid characters after numbers and structural tokens keep their start" {
  // Each prefix reaches a different lexer continuation or error branch.
  // Large numbers exercise the string-preserving conversion fallback.
  for
    prefix in [
      "", "-", "0", "1", "1.", "1.0", "1e", "1e+", "1e-", "1e0", "9007199254740992",
      "1.234567890123456789", "[0", "[null", "{", "{\"k\"", "{\"k\":null", "{\"k\":null,",
      "[\"😀\"", "t", "\"\\", "\"\\u",
    ] {
    for c in ['x', '界', '\u{10000}', '😀', '\u{10FFFF}'] {
      let text = prefix + c.to_string()
      let expected = @json.ParseError::InvalidChar(
        { line: 1, column: prefix.length(), },
        c,
      )
      // Parse a view inside a larger string as well as the full input.
      let padded = "😀prefix" + text + "suffix😀"
      for input in [text[:], padded[8:8 + text.length()]] {
        for preserve_number_repr in [false, true] {
          let error : @json.ParseError = expect_error(
            () => @json.parse(input, preserve_number_repr~) |> ignore,
            "expected InvalidChar",
          )
          assert_eq(error, expected, msg="input: \{text}")
        }
      }
    }
  }
}

///|
/// Number prefixes inside containers and after whitespace, where `lex_value`
/// lexes the number with a DFA and sends prefixes that do not finish as a
/// number to the character-by-character lexer. The errors must be the ones
/// that lexer reports.
test "number prefix errors inside containers" {
  let inputs = [
    "[1.]", "[1.,2]", "[1e]", "[1e+]", "[1E-,", "[-]", "[ -a]", "[01]", "[-01]",
    "[00]", "[1.e5]", "[1e5.3]", "[0x1]", "{\"a\":1.}", "{\"a\": 1e}", "{\"a\":00}",
    " 1.", "\t1e+ ", "\n-", " 1.5e",
  ]
  let results = inputs.map(input => {
    let result = try {
      @json.parse(input) |> ignore
      "ok"
    } catch {
      err => err.to_string()
    }
    (input, result)
  })
  debug_inspect(
    results,
    content=(
      #|[
      #|  ("[1.]", "Invalid character ']' at line 1, column 3"),
      #|  ("[1.,2]", "Invalid character ',' at line 1, column 3"),
      #|  ("[1e]", "Invalid character ']' at line 1, column 3"),
      #|  ("[1e+]", "Invalid character ']' at line 1, column 4"),
      #|  ("[1E-,", "Invalid character ',' at line 1, column 4"),
      #|  ("[-]", "Invalid character ']' at line 1, column 2"),
      #|  ("[ -a]", "Invalid character 'a' at line 1, column 3"),
      #|  ("[01]", "Invalid character '1' at line 1, column 2"),
      #|  ("[-01]", "Invalid character '1' at line 1, column 3"),
      #|  ("[00]", "Invalid character '0' at line 1, column 2"),
      #|  ("[1.e5]", "Invalid character 'e' at line 1, column 3"),
      #|  ("[1e5.3]", "Invalid character '.' at line 1, column 4"),
      #|  ("[0x1]", "Invalid character 'x' at line 1, column 2"),
      #|  ("{\"a\":1.}", "Invalid character '}' at line 1, column 7"),
      #|  ("{\"a\": 1e}", "Invalid character '}' at line 1, column 8"),
      #|  ("{\"a\":00}", "Invalid character '0' at line 1, column 6"),
      #|  (" 1.", "Unexpected end of file"),
      #|  ("\t1e+ ", "Invalid character ' ' at line 1, column 4"),
      #|  ("\n-", "Unexpected end of file"),
      #|  (" 1.5e", "Unexpected end of file"),
      #|]
    ),
  )
}
