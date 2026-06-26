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
test "lex_string with forward slash escape" {
  debug_inspect(
    @json.parse("\"\\/\""),
    content=(
      #|String("/")
    ),
  )
}

///|
test "lex_string_slow rejects raw control char after an escape" {
  // A valid '\t' escape switches lexing to the slow path; the following
  // raw newline must still be rejected by the control-char check.
  debug_inspect(
    expect_parse_error("\"\\t\nbreak\"", "expected InvalidChar"),
    content=(
      #|InvalidChar({ line: 1, column: 3 }, '\n')
    ),
  )
}

///|
test "lex_hex_digits incomplete hex digits" {
  debug_inspect(
    expect_parse_error("\"\\u123", "expected InvalidEof"),
    content=(
      #|InvalidEof
    ),
  )
}

///|
test "lex_hex_digits rejects non-hex characters near the letter range" {
  // '`' (0x60) case-folds to '@' (0x40) and was previously accepted as
  // hex digit 9, so "\u`bcd" parsed as U+9BCD instead of raising.
  debug_inspect(
    expect_parse_error("\"\\u`bcd\"", "expected InvalidChar"),
    content=(
      #|InvalidChar({ line: 1, column: 3 }, '`')
    ),
  )
  debug_inspect(
    expect_parse_error("\"\\u@bcd\"", "expected InvalidChar"),
    content=(
      #|InvalidChar({ line: 1, column: 3 }, '@')
    ),
  )
  debug_inspect(
    expect_parse_error("\"\\u1G23\"", "expected InvalidChar"),
    content=(
      #|InvalidChar({ line: 1, column: 4 }, 'G')
    ),
  )
  debug_inspect(
    expect_parse_error("\"\\u1g23\"", "expected InvalidChar"),
    content=(
      #|InvalidChar({ line: 1, column: 4 }, 'g')
    ),
  )
}

///|
test "lex_hex_digits accepts all hex digit ranges" {
  debug_inspect(
    @json.parse("\"\\u09aF\""),
    content=(
      #|String("য")
    ),
  )
  debug_inspect(
    @json.parse("\"\\uAbfa\""),
    content=(
      #|String("꯺")
    ),
  )
}
