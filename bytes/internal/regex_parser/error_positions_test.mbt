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
fn error_message(pattern : StringView) -> String? {
  try parse(pattern) catch {
    e => Some("\{e}")
  } noraise {
    _ => None
  }
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
  let pattern = "xxa\\u0041"
  assert_eq(
    error_message(pattern[2:]),
    Some(
      "ParserError at position \{1}: Unicode escape sequences are not allowed in a bytes pattern, use \\xHH for a byte",
    ),
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
  let pattern = "xxa(b"
  assert_eq(
    error_message(pattern[2:]),
    Some("ParserError at position \{1}: Unclosed group"),
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
  // accepted.
  for pattern in ["\\x41", "[\\xff]", "a{256}", "a{0,256}", "[a-z]"] {
    assert_eq(error_message(pattern), None)
  }
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
  ]
  for (pattern, at, hint) in cases {
    assert_eq(
      error_message(pattern),
      Some("ParserError at position \{at}: \{hint}"),
    )
  }
}

///|
test "parse/error_positions/bytes_rules" {
  // A Unicode escape or a non-ASCII character is reported at its start, so
  // the position is also a byte offset of the pattern.
  let unicode = "Unicode escape sequences are not allowed in a bytes pattern, use \\xHH for a byte"
  let non_ascii = "Non-ASCII characters are not allowed in a bytes pattern, use \\xHH for a byte"
  let cases = [
    ("\\u0041", 0, unicode),
    ("a\\u{41}", 1, unicode),
    ("[a\\u0041]", 2, unicode),
    ("\\u", 0, unicode),
    ("ab\u{e9}", 2, non_ascii),
    ("[\u{e9}]", 1, non_ascii),
    ("[a-\u{e9}]", 3, non_ascii),
    ("a\u{1F600}", 1, non_ascii),
    ("\\x4", 0, "Invalid escape sequence"),
    ("[\\xg0]", 1, "Invalid escape sequence"),
    ("[\\x42-\\x41]", 1, "Invalid character class range"),
  ]
  for (pattern, at, hint) in cases {
    assert_eq(
      error_message(pattern),
      Some("ParserError at position \{at}: \{hint}"),
    )
  }
}

///|
test "parse/error_positions/unclosed_group_start" {
  // An unclosed group is reported at its `(`, like an unclosed class. When
  // several are open, the innermost one is reported, as in the compiler.
  let cases = [
    ("(", 0),
    ("(a", 0),
    ("ab(cd", 2),
    ("(?:a", 0),
    ("(?i:a", 0),
    ("(?<x>", 0),
    ("(a|(b)", 0),
    ("((a)", 0),
    ("((a", 1),
    ("(a)(b", 3),
    ("\\xff(a", 4),
  ]
  for (pattern, at) in cases {
    assert_eq(
      error_message(pattern),
      Some("ParserError at position \{at}: Unclosed group"),
    )
  }
  assert_eq(
    error_message("(a[b"),
    Some("ParserError at position \{2}: Unclosed character class"),
  )
}
