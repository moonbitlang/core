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

// Regression for #4062. The parser used to decode every `\uXXXX` escape by
// writing the hex value into the result unchecked, manufacturing an
// ill-formed lone-surrogate string out of valid ASCII JSON input. MoonBit
// strings stay well-formed Unicode, so an escaped leading surrogate must be
// followed immediately by an escaped trailing surrogate — the pair decodes
// to the one character it denotes — and every unpaired spelling is a
// `ParseError`.
//
// The cases are split by shape so that one failing assertion cannot mask the
// rest. The old parser accepted the *unpaired-surrogate* spellings below —
// it already rejected the ones that also run out of input or misspell the
// second escape — and aborted the process outright on the escaped-leading +
// raw-trailing one, which is why that case is kept last.

///|
test "unpaired leading-surrogate escape is rejected" {
  // A closing quote after it, and nothing after it at all. (The second was
  // already an EOF error before the surrogate rule.)
  assert_false(@json.valid("\"\\uD800\""))
  assert_false(@json.valid("\"\\uD800"))
  // A character that is not the start of an escape.
  assert_false(@json.valid("\"\\uD800x\""))
  // An escape that is not `\u`.
  assert_false(@json.valid("\"\\uD800\\n\""))
  // Two leading-surrogate escapes in a row.
  assert_false(@json.valid("\"\\uD800\\uD800\""))
  // A second escape that is present but malformed or cut short.
  assert_false(@json.valid("\"\\uD800\\uZZZZ\""))
  assert_false(@json.valid("\"\\uD800\\u00\""))
  assert_false(@json.valid("\"\\uD800\\u\""))
  assert_false(@json.valid("\"\\uD800\\u"))
}

///|
test "bare trailing-surrogate escape is rejected" {
  assert_false(@json.valid("\"\\uDC00\""))
  assert_false(@json.valid("\"a\\uDFFF b\""))
  // An escaped pair in reverse order: the trailing half is bare.
  assert_false(@json.valid("\"\\uDE00\\uD83D\""))
}

///|
test "unpaired surrogate escapes are rejected in object keys too" {
  assert_false(@json.valid("{\"\\uD800\": 1}"))
  assert_false(@json.valid("{\"a\": 1, \"\\uDC00\": 2}"))
  // ...and a valid pair in a key still works.
  assert_true(@json.valid("{\"\\uD83D\\uDE00\": 1}"))
}

///|
test "the surrogate error names the escape that could not pair up" {
  // The position is the backslash opening the offending escape, not
  // whichever character the scan stopped on — that would blame the last,
  // perfectly valid, hex digit. Columns count code units from zero, so the
  // backslash after the opening quote is column 1.
  debug_inspect(
    expect_parse_error("\"\\uDC00\"", "expected InvalidChar"),
    content=(
      #|InvalidChar({ line: 1, column: 1 }, '\\')
    ),
  )
  debug_inspect(
    expect_parse_error("\"ab\\uD800x\"", "expected InvalidChar"),
    content=(
      #|InvalidChar({ line: 1, column: 3 }, '\\')
    ),
  )
  // A non-BMP character after the escape occupies two code units; the
  // reported column must not land inside it.
  debug_inspect(
    expect_parse_error("\"\\uD800\u{1F600}\"", "expected InvalidChar"),
    content=(
      #|InvalidChar({ line: 1, column: 1 }, '\\')
    ),
  )
  // The same position whichever way the pairing fails: a follower that is
  // not a backslash, a backslash not followed by `u`, and a second escape
  // that is well formed but is not a trailing surrogate.
  debug_inspect(
    expect_parse_error("\"\\uD800\\n\"", "expected InvalidChar"),
    content=(
      #|InvalidChar({ line: 1, column: 1 }, '\\')
    ),
  )
  debug_inspect(
    expect_parse_error("\"\\uD800\\u0041\"", "expected InvalidChar"),
    content=(
      #|InvalidChar({ line: 1, column: 1 }, '\\')
    ),
  )
  // Running out of input is still an EOF error rather than a character one,
  // including on a trailing backslash where the second escape should start.
  debug_inspect(
    expect_parse_error("\"\\uD800", "expected InvalidEof"),
    content="InvalidEof",
  )
  debug_inspect(
    expect_parse_error("\"\\uD800\\", "expected InvalidEof"),
    content="InvalidEof",
  )
}

///|
test "an escape naming a non-BMP character reports it whole" {
  // These two arms read a character and then step back by its width. Using
  // a fixed step of one code unit landed inside a non-BMP character and
  // reported a broken half one column further on.
  debug_inspect(
    expect_parse_error("\"\\\u{1F600}\"", "expected InvalidChar"),
    content=(
      #|InvalidChar({ line: 1, column: 2 }, '😀')
    ),
  )
  debug_inspect(
    expect_parse_error("\"\\u1\u{1F600}23\"", "expected InvalidChar"),
    content=(
      #|InvalidChar({ line: 1, column: 4 }, '😀')
    ),
  )
}

///|
test "valid surrogate pairs decode to one scalar value" {
  // Both ends of the supplementary range.
  assert_true(@json.parse("\"\\uD800\\uDC00\"") == Json::string("\u{10000}"))
  assert_true(@json.parse("\"\\udbff\\udfff\"") == Json::string("\u{10FFFF}"))
  // Any hex digit case, and in any position within the string.
  assert_true(@json.parse("\"\\uD83D\\uDE00\"") == Json::string("\u{1F600}"))
  assert_true(
    @json.parse("\"a\\uD83D\\uDE00b\\n\"") == Json::string("a\u{1F600}b\n"),
  )
  // Two pairs running together are decoded independently.
  assert_true(
    @json.parse("\"\\uD83D\\uDE00\\uD83D\\uDE01\"") ==
    Json::string("\u{1F600}\u{1F601}"),
  )
  // Non-surrogate escapes are unaffected, including the replacement
  // character, which is a scalar value like any other.
  assert_true(@json.parse("\"\\u0041\\uFFFD\"") == Json::string("A\u{FFFD}"))
}

///|
test "slow path copies astral characters in plain runs" {
  // The escapes force the slow path; the runs around them contain characters
  // outside the BMP, which the scan must traverse as surrogate pairs rather
  // than stopping at (or splitting) either half.
  assert_true(
    @json.parse("\"\u{1F600}a\\n\u{1D11E}b\u{1F600}\"") ==
    Json::string("\u{1F600}a\n\u{1D11E}b\u{1F600}"),
  )
  // A run that is nothing but astral characters, delimited by escapes.
  assert_true(
    @json.parse("\"\\t\u{1F600}\u{1F601}\\t\"") ==
    Json::string("\t\u{1F600}\u{1F601}\t"),
  )
}

///|
test "escaped and raw surrogate halves do not pair up" {
  // Kept last: before the surrogate rule this input aborted the process
  // rather than raising, so a regression here would take the whole test
  // binary with it.
  let lone_low = String::from_array([(0xDC00).unsafe_to_char()])
  assert_false(@json.valid("\"\\uD800" + lone_low + "\""))
}
