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
/// Regression for #4049. MoonBit strings must stay Unicode well-formed, so
/// the string lexer rejects raw unpaired surrogates with a ParseError.
/// Previously the escape-free fast path silently accepted them (producing
/// ill-formed strings), and combining one with an escape sequence aborted
/// the process: the slow path's `flush` sliced with the checked
/// `[start:end]`, which panics when a slice boundary lands on a trailing
/// surrogate. Well-formed input cannot contain raw lone surrogates, but
/// unsafe code can manufacture such a String; a clean error beats an abort.
test "raw unpaired surrogates are rejected with a clean parse error" {
  let lone_high = String::from_array([(0xD800).unsafe_to_char()])
  let lone_low = String::from_array([(0xDC00).unsafe_to_char()])
  // Escape-free strings (fast path; used to be silently accepted).
  assert_false(@json.valid("\"" + lone_high + "\""))
  assert_false(@json.valid("\"" + lone_low + "\""))
  // A reversed pair (low then high) is two unpaired surrogates.
  assert_false(@json.valid("\"" + lone_low + lone_high + "\""))
  // Next to escapes (slow path; used to abort the process).
  assert_false(@json.valid("\"" + lone_low + "\\n\""))
  assert_false(@json.valid("\"\\n" + lone_low + "\""))
  assert_false(@json.valid("\"" + lone_high + "\\t\""))
  // The failure is the documented ParseError, not an abort.
  debug_inspect(
    expect_parse_error("\"" + lone_low + "\"", "expected InvalidChar"),
    content=(
      #|InvalidChar({ line: 1, column: 1 }, '�')
    ),
  )
  // Well-formed surrogate pairs still parse, raw or next to escapes.
  assert_true(@json.parse("\"\u{1F600}\"") == Json::string("\u{1F600}"))
  let json = Json::string("\u{10FFFF}\\\u{1F600}\n")
  assert_true(@json.parse(json.stringify()) == json)
}
