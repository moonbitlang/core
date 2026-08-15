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

///|
/// Regression for #4062. The parser used to decode every `\uXXXX` escape by
/// writing the hex value into the result unchecked, manufacturing an
/// ill-formed lone-surrogate string out of valid ASCII JSON input. MoonBit
/// strings stay Unicode well-formed, so an escaped leading surrogate must be
/// immediately followed by an escaped trailing surrogate (the pair combines
/// into one scalar value); every unpaired spelling is now a ParseError.
/// RFC 8259 calls the behavior for unpaired surrogate escapes unpredictable
/// and RFC 7493 (I-JSON) forbids them; rejecting matches serde_json.
test "unpaired surrogate escapes are rejected with a clean parse error" {
  // An unpaired leading-surrogate escape.
  assert_false(@json.valid("\"\\uD800\""))
  assert_false(@json.valid("\"\\uD800x\""))
  assert_false(@json.valid("\"\\uD800\\n\""))
  // A bare trailing-surrogate escape.
  assert_false(@json.valid("\"\\uDC00\""))
  assert_false(@json.valid("\"a\\uDFFF b\""))
  // Two leading-surrogate escapes in a row.
  assert_false(@json.valid("\"\\uD800\\uD800\""))
  // An escaped pair in reverse order.
  assert_false(@json.valid("\"\\uDE00\\uD83D\""))
  // Mixed escaped/raw halves do not pair up.
  let lone_low = String::from_array([(0xDC00).unsafe_to_char()])
  assert_false(@json.valid("\"\\uD800" + lone_low + "\""))
  // The failure is the documented ParseError, not an ill-formed string.
  debug_inspect(
    expect_parse_error("\"\\uDC00\"", "expected InvalidChar"),
    content=(
      #|InvalidChar({ line: 1, column: 6 }, '0')
    ),
  )
  // Valid escaped pairs still combine into one scalar value, with any hex
  // digit case, in any position.
  assert_true(@json.parse("\"\\uD83D\\uDE00\"") == Json::string("\u{1F600}"))
  assert_true(@json.parse("\"\\udbff\\udfff\"") == Json::string("\u{10FFFF}"))
  assert_true(
    @json.parse("\"a\\uD83D\\uDE00b\\n\"") == Json::string("a\u{1F600}b\n"),
  )
  // Non-surrogate escapes are unaffected.
  assert_true(@json.parse("\"\\u0041\\uFFFD\"") == Json::string("A\u{FFFD}"))
}
