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
fn error_message(
  pattern : StringView,
  mode~ : @regex_parser.Mode = String,
) -> String? {
  let profile = if mode is Bytes { profile_bytes() } else { profile_unicode() }
  try parse(profile~, mode~, pattern) catch {
    e => Some("\{e}")
  } noraise {
    _ => None
  }
}

///|
test "parse/error_positions/escape_start" {
  // Diagnostics must point to the backslash, including after a prefix or in a
  // character class, rather than to the suffix left after reading the escape.
  let cases = [
    ("\\x41", 0, "Byte escape sequences are not allowed"),
    ("a\\x41", 1, "Byte escape sequences are not allowed"),
    ("[\\x41]", 1, "Byte escape sequences are not allowed"),
    ("a[\\x41]", 2, "Byte escape sequences are not allowed"),
    ("\\u{110000}", 0, "Character out of range"),
    ("a\\u{110000}", 1, "Character out of range"),
    ("[\\u{110000}]", 1, "Character out of range"),
    ("\\ud800", 0, "Character out of range"),
    ("a\\ud800", 1, "Character out of range"),
    ("[\\ud800]", 1, "Character out of range"),
    ("\\u{D800}", 0, "Character out of range"),
    ("[\\u{D800}]", 1, "Character out of range"),
    ("😀\\x41", 2, "Byte escape sequences are not allowed"),
  ]
  for (pattern, at, hint) in cases {
    assert_eq(
      error_message(pattern),
      Some("ParserError at position \{at}: \{hint}"),
    )
  }
  for pattern in ["\\u0041", "\\u{41}"] {
    assert_eq(
      error_message(pattern, mode=Bytes),
      Some(
        "ParserError at position \{0}: Unicode escape sequences are not allowed",
      ),
    )
  }
  for pattern in ["[\\u0041]", "[\\u{41}]"] {
    assert_eq(
      error_message(pattern, mode=Bytes),
      Some(
        "ParserError at position \{1}: Unicode escape sequences are not allowed",
      ),
    )
  }
  assert_eq(
    error_message("[中]", mode=Bytes),
    Some("ParserError at position \{1}: Character out of range"),
  )
}

///|
test "parse/error_positions/quantifier_start" {
  // Both numeric bounds belong to the same quantifier. Their errors must use
  // its opening brace, even for an upper-bound error or an inverted range.
  let cases = [
    ("a{257}", "Quantifier too large"),
    ("a{257,}", "Quantifier too large"),
    ("a{0,257}", "Quantifier too large"),
    ("a{256,257}", "Quantifier too large"),
    ("a{257,256}", "Quantifier too large"),
    ("a{0000257}", "Quantifier too large"),
    ("a{3,2}", "Invalid quantifier"),
    ("a{,3}", "Invalid quantifier"),
    ("a{1,3", "Invalid quantifier"),
  ]
  for (pattern, hint) in cases {
    assert_eq(
      error_message(pattern),
      Some("ParserError at position \{1}: \{hint}"),
    )
  }
  assert_eq(
    error_message("😀a{257}"),
    Some("ParserError at position \{3}: Quantifier too large"),
  )
}

///|
test "parse/error_positions/unclosed_class_start" {
  // The opening bracket, not EOF, identifies a class which was never closed.
  // A missing right-hand range atom must retain the enclosing class's start.
  let cases = [
    ("[", 0),
    ("[^", 0),
    ("[a", 0),
    ("[a-", 0),
    ("x[a-", 1),
    ("😀[a-", 2),
    ("(?:a[", 4),
    ("[[:digit:]", 0),
  ]
  for (pattern, at) in cases {
    assert_eq(
      error_message(pattern),
      Some("ParserError at position \{at}: Unclosed character class"),
    )
  }
}

///|
test "parse/error_positions/relative_to_input_view" {
  // The parser's public input is a view, so the position is relative to the
  // supplied view, not the start of its backing string.
  let pattern = "xxa\\x41"
  assert_eq(
    error_message(pattern[2:]),
    Some("ParserError at position \{1}: Byte escape sequences are not allowed"),
  )
  let pattern = "xxa{257}"
  assert_eq(
    error_message(pattern[2:]),
    Some("ParserError at position \{1}: Quantifier too large"),
  )
  let pattern = "xxa[b-"
  assert_eq(
    error_message(pattern[2:]),
    Some("ParserError at position \{1}: Unclosed character class"),
  )
}

///|
test "parse/error_positions/other_escape_diagnostics_unchanged" {
  // An incomplete escape still points to its backslash; changing all EOF
  // diagnostics to EOF would lose the construct-start convention.
  assert_eq(
    error_message("a\\"),
    Some("ParserError at position \{1}: Unexpected character"),
  )
  assert_eq(
    error_message("[a\\"),
    Some("ParserError at position \{2}: Invalid escape sequence"),
  )
  assert_eq(
    error_message("a\\q"),
    Some("ParserError at position \{1}: Invalid escape sequence"),
  )
  // Valid escapes, boundary repetition counts and complete classes remain
  // accepted, in both string and byte modes.
  for pattern in ["\\u0041", "[\\u{1f600}]", "a{256}", "a{0,256}", "[a-z]"] {
    assert_eq(error_message(pattern), None)
  }
  assert_eq(error_message("[\\x41]", mode=Bytes), None)
}

///|
test "parse/error_positions/construct_start" {
  // An invalid range is reported at its first character, and an invalid
  // group modifier at its `?`, as in the compiler's regex literals.
  let cases = [
    ("[z-a]", 1, "Invalid character class range"),
    ("x[^z-a]", 3, "Invalid character class range"),
    ("[a-cz-a]", 4, "Invalid character class range"),
    ("(?<x", 1, "Invalid group"),
    ("(?<x)", 1, "Invalid group"),
    ("a(?<>b)", 2, "Invalid group"),
    ("(?xyz:a)", 1, "Invalid group"),
    ("😀(?xyz:a)", 3, "Invalid group"),
  ]
  for (pattern, at, hint) in cases {
    assert_eq(
      error_message(pattern),
      Some("ParserError at position \{at}: \{hint}"),
    )
  }
}
