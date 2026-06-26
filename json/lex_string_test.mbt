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
test "lex_hex_digits incomplete hex digits" {
  debug_inspect(
    expect_parse_error("\"\\u123", "expected InvalidEof"),
    content=(
      #|InvalidEof
    ),
  )
}

///|
test "lex_hex_digits rejects backtick as hex digit" {
  // '`' (0x60) case-folds to '@' (0x40) via `c & ~32`, yielding d == 9,
  // so "\u`bcd" is accepted as U+9BCD instead of raising. This test
  // asserts the desired InvalidChar and FAILS on the current lexer,
  // pinning down the bug before the fix.
  debug_inspect(
    expect_parse_error("\"\\u`bcd\"", "expected InvalidChar"),
    content=(
      #|InvalidChar({ line: 1, column: 3 }, '`')
    ),
  )
}
