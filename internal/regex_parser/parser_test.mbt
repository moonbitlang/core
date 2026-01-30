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
fn profile_unicode() -> @re.Profile {
  @re.Profile::new(
    valid=@re.RecharSet::char_range(0, 0x10FFFF),
    word=@re.RecharSet::char_range('a', 'z') +
      @re.RecharSet::char_range('A', 'Z') +
      @re.RecharSet::char_range('0', '9') +
      @re.RecharSet::char('_'),
    category=fn(c) {
      match c {
        'a'..='z' | 'A'..='Z' | '0'..='9' | '_' => @re.Category::word()
        '\n' => @re.Category::newline()
        _ => @re.Category::not_word()
      }
    },
  )
}

///|
fn profile_bytes() -> @re.Profile {
  @re.Profile::new(
    valid=@re.RecharSet::char_range(0, 255),
    word=@re.RecharSet::char_range('a', 'z') +
      @re.RecharSet::char_range('A', 'Z') +
      @re.RecharSet::char_range('0', '9') +
      @re.RecharSet::char('_'),
    category=fn(c) {
      match c {
        'a'..='z' | 'A'..='Z' | '0'..='9' | '_' => @re.Category::word()
        '\n' => @re.Category::newline()
        _ => @re.Category::not_word()
      }
    },
  )
}

///|
fn parse(
  profile~ : @re.Profile,
  mode~ : @regex_parser.Mode,
  pattern : StringView,
) -> @re.Pattern raise @regex_parser.ParserError {
  @regex_parser.parse(profile~, mode~, pattern)
}

// Basic parsing tests

///|
test "parse/simple_char" {
  let pat = parse(profile=profile_unicode(), mode=String, "abc")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content=(
      #|Sequence(
      #|  <ReadOnlyArray:
      #|    [
      #|      Char([(97, 97)]),
      #|      Char([(98, 98)]),
      #|      Char([(99, 99)]),
      #|    ]>,
      #|)
    ),
  )
}

///|
test "parse/dot_wildcard" {
  let pat = parse(profile=profile_unicode(), mode=String, "a.b")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content=(
      #|Sequence(
      #|  <ReadOnlyArray:
      #|    [
      #|      Char([(97, 97)]),
      #|      Char([(0, 1114111)]),
      #|      Char([(98, 98)]),
      #|    ]>,
      #|)
    ),
  )
}

///|
test "parse/quantifiers" {
  let pat = parse(profile=profile_unicode(), mode=String, "a*b+c?")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content=(
      #|Sequence(
      #|  <ReadOnlyArray:
      #|    [
      #|      Quantifier(
      #|        {
      #|          min: 0,
      #|          max: None,
      #|          mode: Greedy,
      #|        },
      #|        Char([(97, 97)]),
      #|      ),
      #|      Quantifier(
      #|        {
      #|          min: 1,
      #|          max: None,
      #|          mode: Greedy,
      #|        },
      #|        Char([(98, 98)]),
      #|      ),
      #|      Quantifier(
      #|        {
      #|          min: 0,
      #|          max: Some(1),
      #|          mode: Greedy,
      #|        },
      #|        Char([(99, 99)]),
      #|      ),
      #|    ]>,
      #|)
    ),
  )
}

///|
test "parse/quantifier_range" {
  let pat1 = parse(profile=profile_unicode(), mode=String, "a{3}")
  inspect(
    @debug.render(pat1.to_repr(), max_depth=10),
    content=(
      #|Quantifier(
      #|  {
      #|    min: 3,
      #|    max: Some(3),
      #|    mode: Greedy,
      #|  },
      #|  Char([(97, 97)]),
      #|)
    ),
  )
  let pat2 = parse(profile=profile_unicode(), mode=String, "a{2,}")
  inspect(
    @debug.render(pat2.to_repr(), max_depth=10),
    content=(
      #|Quantifier(
      #|  {
      #|    min: 2,
      #|    max: None,
      #|    mode: Greedy,
      #|  },
      #|  Char([(97, 97)]),
      #|)
    ),
  )
  let pat3 = parse(profile=profile_unicode(), mode=String, "a{1,5}")
  inspect(
    @debug.render(pat3.to_repr(), max_depth=10),
    content=(
      #|Quantifier(
      #|  {
      #|    min: 1,
      #|    max: Some(5),
      #|    mode: Greedy,
      #|  },
      #|  Char([(97, 97)]),
      #|)
    ),
  )
}

///|
test "parse/non_greedy_quantifier" {
  let pat1 = parse(profile=profile_unicode(), mode=String, "a*?")
  inspect(
    @debug.render(pat1.to_repr(), max_depth=10),
    content=(
      #|Quantifier(
      #|  {
      #|    min: 0,
      #|    max: None,
      #|    mode: NonGreedy,
      #|  },
      #|  Char([(97, 97)]),
      #|)
    ),
  )
  let pat2 = parse(profile=profile_unicode(), mode=String, "a+?")
  inspect(
    @debug.render(pat2.to_repr(), max_depth=10),
    content=(
      #|Quantifier(
      #|  {
      #|    min: 1,
      #|    max: None,
      #|    mode: NonGreedy,
      #|  },
      #|  Char([(97, 97)]),
      #|)
    ),
  )
}

///|
test "parse/alternation" {
  let pat = parse(profile=profile_unicode(), mode=String, "a|b|c")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content=(
      #|Alternation(
      #|  <ReadOnlyArray:
      #|    [
      #|      Char([(97, 97)]),
      #|      Char([(98, 98)]),
      #|      Char([(99, 99)]),
      #|    ]>,
      #|)
    ),
  )
}

///|
test "parse/groups" {
  let pat1 = parse(profile=profile_unicode(), mode=String, "(abc)")
  inspect(
    @debug.render(pat1.to_repr(), max_depth=10),
    content=(
      #|Capture(
      #|  name=None,
      #|  Sequence(
      #|    <ReadOnlyArray:
      #|      [
      #|        Char([(97, 97)]),
      #|        Char([(98, 98)]),
      #|        Char([(99, 99)]),
      #|      ]>,
      #|  ),
      #|)
    ),
  )
  let pat2 = parse(profile=profile_unicode(), mode=String, "(a|b)")
  inspect(
    @debug.render(pat2.to_repr(), max_depth=10),
    content=(
      #|Capture(
      #|  name=None,
      #|  Alternation(
      #|    <ReadOnlyArray:
      #|      [
      #|        Char([(97, 97)]),
      #|        Char([(98, 98)]),
      #|      ]>,
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/non_capture_group" {
  let pat1 = parse(profile=profile_unicode(), mode=String, "(?:abc)")
  inspect(
    @debug.render(pat1.to_repr(), max_depth=10),
    content=(
      #|Sequence(
      #|  <ReadOnlyArray:
      #|    [
      #|      Char([(97, 97)]),
      #|      Char([(98, 98)]),
      #|      Char([(99, 99)]),
      #|    ]>,
      #|)
    ),
  )
  let pat2 = parse(profile=profile_unicode(), mode=String, "a(?:b|c)d")
  inspect(
    @debug.render(pat2.to_repr(), max_depth=10),
    content=(
      #|Sequence(
      #|  <ReadOnlyArray:
      #|    [
      #|      Char([(97, 97)]),
      #|      Alternation(
      #|        <ReadOnlyArray:
      #|          [
      #|            Char([(98, 98)]),
      #|            Char([(99, 99)]),
      #|          ]>,
      #|      ),
      #|      Char([(100, 100)]),
      #|    ]>,
      #|)
    ),
  )
}

///|
test "parse/named_groups" {
  let pat = parse(profile=profile_unicode(), mode=String, "(?<name>abc)")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content=(
      #|Capture(
      #|  name=Some("name"),
      #|  Sequence(
      #|    <ReadOnlyArray:
      #|      [
      #|        Char([(97, 97)]),
      #|        Char([(98, 98)]),
      #|        Char([(99, 99)]),
      #|      ]>,
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/character_class" {
  let pat1 = parse(profile=profile_unicode(), mode=String, "[abc]")
  inspect(
    @debug.render(pat1.to_repr(), max_depth=10),
    content="Char([(97, 99)])",
  )
  let pat2 = parse(profile=profile_unicode(), mode=String, "[a-z]")
  inspect(
    @debug.render(pat2.to_repr(), max_depth=10),
    content="Char([(97, 122)])",
  )
  let pat3 = parse(profile=profile_unicode(), mode=String, "[^abc]")
  inspect(
    @debug.render(pat3.to_repr(), max_depth=10),
    content="Char([(0, 96), (100, 1114111)])",
  )
}

///|
test "parse/error_nested_character_class" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "[[a-z][0-9]]"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=1,
      #|    hint="Unsupported nested character class",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/posix_classes" {
  let pat_digit = parse(profile=profile_unicode(), mode=String, "[[:digit:]]")
  inspect(
    @debug.render(pat_digit.to_repr(), max_depth=10),
    content="Char([(48, 57)])",
  )
  let pat_alpha = parse(profile=profile_unicode(), mode=String, "[[:alpha:]]")
  inspect(
    @debug.render(pat_alpha.to_repr(), max_depth=10),
    content="Char([(65, 90), (97, 122)])",
  )
  let pat_space = parse(profile=profile_unicode(), mode=String, "[[:space:]]")
  inspect(
    @debug.render(pat_space.to_repr(), max_depth=10),
    content="Char([(9, 13), (32, 32)])",
  )
  let pat_word = parse(profile=profile_unicode(), mode=String, "[[:word:]]")
  inspect(
    @debug.render(pat_word.to_repr(), max_depth=10),
    content=(
      #|Char(
      #|  [
      #|    (48, 57),
      #|    (65, 90),
      #|    (95, 95),
      #|    (97, 122),
      #|  ],
      #|)
    ),
  )
}

///|
test "parse/escape_sequences" {
  let pat1 = parse(profile=profile_unicode(), mode=String, "\\n\\r\\t")
  inspect(
    @debug.render(pat1.to_repr(), max_depth=10),
    content=(
      #|Sequence(
      #|  <ReadOnlyArray:
      #|    [
      #|      Char([(10, 10)]),
      #|      Char([(13, 13)]),
      #|      Char([(9, 9)]),
      #|    ]>,
      #|)
    ),
  )
  let pat2 = parse(profile=profile_unicode(), mode=String, "\\f\\v")
  inspect(
    @debug.render(pat2.to_repr(), max_depth=10),
    content=(
      #|Sequence(
      #|  <ReadOnlyArray:
      #|    [
      #|      Char([(12, 12)]),
      #|      Char([(11, 11)]),
      #|    ]>,
      #|)
    ),
  )
}

///|
test "parse/unicode_escape" {
  let pat1 = parse(profile=profile_unicode(), mode=String, "\\u0041")
  inspect(
    @debug.render(pat1.to_repr(), max_depth=10),
    content="Char([(65, 65)])",
  )
  let pat2 = parse(profile=profile_unicode(), mode=String, "\\u{1F600}")
  inspect(
    @debug.render(pat2.to_repr(), max_depth=10),
    content="Char([(128512, 128512)])",
  )
}

///|
test "parse/hex_escape_bytes_mode" {
  let pat = parse(profile=profile_bytes(), mode=Bytes, "\\x41")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content="Char([(65, 65)])",
  )
}

///|
test "parse/escaped_metacharacters" {
  let pat = parse(
    profile=profile_unicode(),
    mode=String,
    "\\^\\$\\.\\*\\+\\?\\(\\)\\[\\]\\{\\}\\|",
  )
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content=(
      #|Sequence(
      #|  <ReadOnlyArray:
      #|    [
      #|      Char([(94, 94)]),
      #|      Char([(36, 36)]),
      #|      Char([(46, 46)]),
      #|      Char([(42, 42)]),
      #|      Char([(43, 43)]),
      #|      Char([(63, 63)]),
      #|      Char([(40, 40)]),
      #|      Char([(41, 41)]),
      #|      Char([(91, 91)]),
      #|      Char([(93, 93)]),
      #|      Char([(123, 123)]),
      #|      Char([(125, 125)]),
      #|      Char([(124, 124)]),
      #|    ]>,
      #|)
    ),
  )
}

///|
test "parse/anchors" {
  let pat = parse(profile=profile_unicode(), mode=String, "^abc$")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content=(
      #|Sequence(
      #|  <ReadOnlyArray:
      #|    [
      #|      Assertion(StartOfInput),
      #|      Char([(97, 97)]),
      #|      Char([(98, 98)]),
      #|      Char([(99, 99)]),
      #|      Assertion(EndOfInput),
      #|    ]>,
      #|)
    ),
  )
}

///|
test "parse/word_boundary" {
  let pat1 = parse(profile=profile_unicode(), mode=String, "\\bword\\b")
  inspect(
    @debug.render(pat1.to_repr(), max_depth=10),
    content=(
      #|Sequence(
      #|  <ReadOnlyArray:
      #|    [
      #|      Alternation(
      #|        <ReadOnlyArray:
      #|          [
      #|            Assertion(StartOfWord),
      #|            Assertion(EndOfWord),
      #|          ]>,
      #|      ),
      #|      Char([(119, 119)]),
      #|      Char([(111, 111)]),
      #|      Char([(114, 114)]),
      #|      Char([(100, 100)]),
      #|      Alternation(
      #|        <ReadOnlyArray:
      #|          [
      #|            Assertion(StartOfWord),
      #|            Assertion(EndOfWord),
      #|          ]>,
      #|      ),
      #|    ]>,
      #|)
    ),
  )
  let pat2 = parse(profile=profile_unicode(), mode=String, "\\B")
  inspect(
    @debug.render(pat2.to_repr(), max_depth=10),
    content="Assertion(NotWordBoundary)",
  )
}

///|
test "parse/ignore_case_flag" {
  let pat = parse(profile=profile_unicode(), mode=String, "(?i:abc)")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content=(
      #|Sequence(
      #|  <ReadOnlyArray:
      #|    [
      #|      Char([(65, 65), (97, 97)]),
      #|      Char([(66, 66), (98, 98)]),
      #|      Char([(67, 67), (99, 99)]),
      #|    ]>,
      #|)
    ),
  )
}

///|
test "parse/practical_date_ymd" {
  // ^([[:digit:]]{4})-([[:digit:]]{2})-([[:digit:]]{2})$
  let pat = parse(
    profile=profile_unicode(),
    mode=String,
    "^([[:digit:]]{4})-([[:digit:]]{2})-([[:digit:]]{2})$",
  )
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content=(
      #|Sequence(
      #|  <ReadOnlyArray:
      #|    [
      #|      Assertion(StartOfInput),
      #|      Capture(
      #|        name=None,
      #|        Quantifier(
      #|          {
      #|            min: 4,
      #|            max: Some(4),
      #|            mode: Greedy,
      #|          },
      #|          Char([(48, 57)]),
      #|        ),
      #|      ),
      #|      Char([(45, 45)]),
      #|      Capture(
      #|        name=None,
      #|        Quantifier(
      #|          {
      #|            min: 2,
      #|            max: Some(2),
      #|            mode: Greedy,
      #|          },
      #|          Char([(48, 57)]),
      #|        ),
      #|      ),
      #|      Char([(45, 45)]),
      #|      Capture(
      #|        name=None,
      #|        Quantifier(
      #|          {
      #|            min: 2,
      #|            max: Some(2),
      #|            mode: Greedy,
      #|          },
      #|          Char([(48, 57)]),
      #|        ),
      #|      ),
      #|      Assertion(EndOfInput),
      #|    ]>,
      #|)
    ),
  )
}

///|
test "parse/practical_identifier" {
  // ^[A-Za-z_][A-Za-z0-9_]*$
  let pat = parse(
    profile=profile_unicode(),
    mode=String,
    "^[A-Za-z_][A-Za-z0-9_]*$",
  )
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content=(
      #|Sequence(
      #|  <ReadOnlyArray:
      #|    [
      #|      Assertion(StartOfInput),
      #|      Char(
      #|        [
      #|          (65, 90),
      #|          (95, 95),
      #|          (97, 122),
      #|        ],
      #|      ),
      #|      Quantifier(
      #|        {
      #|          min: 0,
      #|          max: None,
      #|          mode: Greedy,
      #|        },
      #|        Char(
      #|          [
      #|            (48, 57),
      #|            (65, 90),
      #|            (95, 95),
      #|            (97, 122),
      #|          ],
      #|        ),
      #|      ),
      #|      Assertion(EndOfInput),
      #|    ]>,
      #|)
    ),
  )
}

///|
test "parse/escaped_in_char_class" {
  let pat1 = parse(profile=profile_unicode(), mode=String, "[\\n\\r\\t]")
  inspect(
    @debug.render(pat1.to_repr(), max_depth=10),
    content="Char([(9, 10), (13, 13)])",
  )
  let pat2 = parse(profile=profile_unicode(), mode=String, "[\\-\\]]")
  inspect(
    @debug.render(pat2.to_repr(), max_depth=10),
    content="Char([(45, 45), (93, 93)])",
  )
}

///|
test "parse/char_class_with_unicode_escape" {
  let pat1 = parse(profile=profile_unicode(), mode=String, "[\\u0041-\\u005A]")
  inspect(
    @debug.render(pat1.to_repr(), max_depth=10),
    content="Char([(65, 90)])",
  )
  let pat2 = parse(profile=profile_unicode(), mode=String, "[\\u{41}-\\u{5A}]")
  inspect(
    @debug.render(pat2.to_repr(), max_depth=10),
    content="Char([(65, 90)])",
  )
}

// Error tests using try-catch

///|
test "parse/error_use_posix_class" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "\\d"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=0,
      #|    hint="Use POSIX character class instead of \\w, \\W, \\d, \\D, \\s, \\S",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_use_posix_class_in_char_class" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "[\\d]"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=1,
      #|    hint="Use POSIX character class instead of \\w, \\W, \\d, \\D, \\s, \\S",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_byte_escape_in_string_mode" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "[\\x41]"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=5,
      #|    hint="Byte escape sequences are not allowed",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_byte_escape_in_string_mode_term" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "\\x41"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=4,
      #|    hint="Byte escape sequences are not allowed",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_unicode_escape_in_bytes_mode" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_bytes(), mode=Bytes, "[\\u0041]"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=1,
      #|    hint="Unicode escape sequences are not allowed",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_unicode_escape_out_of_range_in_class" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_bytes(), mode=String, "[\\u0100]"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=1,
      #|    hint="Character out of range",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_unicode_escape_in_bytes_mode_term" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_bytes(), mode=Bytes, "\\u0041"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=6,
      #|    hint="Unicode escape sequences are not allowed",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_unicode_brace_escape_in_bytes_mode" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_bytes(), mode=Bytes, "[\\u{41}]"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=7,
      #|    hint="Unicode escape sequences are not allowed",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_unsupported_posix_class" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "[[:foo:]]"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=1,
      #|    hint="Unsupported POSIX character class",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_unclosed_char_class" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "[abc"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=4,
      #|    hint="Unclosed character class",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_unclosed_group" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "("),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=1,
      #|    hint="Unclosed group",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_invalid_quantifier" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "a{abc}"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=1,
      #|    hint="Invalid quantifier",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_invalid_quantifier_range" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "a{5,2}"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=6,
      #|    hint="Invalid quantifier",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_quantifier_too_large" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "a{999}"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=2,
      #|    hint="Quantifier too large",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_quantifier_too_large_overflow" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(
          profile=profile_unicode(),
          mode=String,
          "a{99999999999999999999}",
        ),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=2,
      #|    hint="Quantifier too large",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_max_quantifier_too_large" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "a{1,999}"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=4,
      #|    hint="Quantifier too large",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_possessive_quantifier" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "a++"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=2,
      #|    hint="Unsupported possessive quantifier",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_lookahead" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "(?=abc)"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=0,
      #|    hint="Unsupported lookahead assertion",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_negative_lookahead" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "(?!abc)"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=0,
      #|    hint="Unsupported negative lookahead assertion",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_lookbehind" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "(?<=abc)"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=0,
      #|    hint="Unsupported lookbehind assertion",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_negative_lookbehind" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "(?<!abc)"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=0,
      #|    hint="Unsupported negative lookbehind assertion",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_invalid_group" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "(?<>abc)"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=0,
      #|    hint="Invalid group",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_invalid_flags" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "(?xyz:abc)"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=6,
      #|    hint="Invalid group",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_bare_posix_class" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "[:digit:]"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=0,
      #|    hint="Invalid character class, bare POSIX character class not allowed",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_invalid_char_range" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "[z-a]"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=3,
      #|    hint="Invalid character class range",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_char_range_over_sets" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "[a-[:digit:]]"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=4,
      #|    hint="Character class range over sets",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_unsupported_class_set_expression" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "[a--b]"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=2,
      #|    hint="Unsupported character class set expression",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_class_set_ampersand" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "[a&&b]"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=2,
      #|    hint="Unsupported character class set expression",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_unexpected_char_in_range" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "[a-]"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=3,
      #|    hint="Unexpected character",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_invalid_escape" {
  // \q is not a valid escape sequence
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "\\q"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=0,
      #|    hint="Invalid escape sequence",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_unicode_out_of_range" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_bytes(), mode=String, "[\\u{FFFFFF}]"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=11,
      #|    hint="Character out of range",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_unicode_brace_out_of_range_term" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "\\u{110000}"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=10,
      #|    hint="Character out of range",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_invalid_posix_class" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "[[:abc"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=1,
      #|    hint="Invalid POSIX character class",
      #|  ),
      #|)
    ),
  )
}

// Additional tests for more coverage

///|
test "parse/hex_escape_in_char_class_bytes_mode" {
  let pat = parse(profile=profile_bytes(), mode=Bytes, "[\\x41\\x5A]")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content="Char([(65, 65), (90, 90)])",
  )
}

///|
test "parse/hex_escape_lowercase_in_char_class_bytes_mode" {
  let pat = parse(profile=profile_bytes(), mode=Bytes, "[\\x4f]")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content="Char([(79, 79)])",
  )
}

///|
test "parse/escape_sequences_in_char_class" {
  let pat = parse(profile=profile_unicode(), mode=String, "[\\n\\r\\t]")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content="Char([(9, 10), (13, 13)])",
  )
}

///|
test "parse/unicode_escape_in_char_class" {
  let pat = parse(profile=profile_unicode(), mode=String, "[\\u0041\\u{1f600}]")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content="Char([(65, 65), (128512, 128512)])",
  )
}

///|
test "parse/unicode_escape_lowercase_in_char_class" {
  let pat = parse(profile=profile_unicode(), mode=String, "[\\u00af]")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content="Char([(175, 175)])",
  )
}

///|
test "parse/lowercase_hex_unicode" {
  let pat1 = parse(profile=profile_unicode(), mode=String, "\\u00ab")
  inspect(
    @debug.render(pat1.to_repr(), max_depth=10),
    content="Char([(171, 171)])",
  )
  let pat2 = parse(profile=profile_unicode(), mode=String, "\\u{abc}")
  inspect(
    @debug.render(pat2.to_repr(), max_depth=10),
    content="Char([(2748, 2748)])",
  )
}

///|
test "parse/ignore_case_alternation" {
  // Cover alternation inside ignore case
  let pat = parse(profile=profile_unicode(), mode=String, "(?i:a|b|c)")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content=(
      #|Alternation(
      #|  <ReadOnlyArray:
      #|    [
      #|      Char([(65, 65), (97, 97)]),
      #|      Char([(66, 66), (98, 98)]),
      #|      Char([(67, 67), (99, 99)]),
      #|    ]>,
      #|)
    ),
  )
}

///|
test "parse/ignore_case_with_groups" {
  let pat = parse(profile=profile_unicode(), mode=String, "(?i:(abc))")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content=(
      #|Capture(
      #|  name=None,
      #|  Sequence(
      #|    <ReadOnlyArray:
      #|      [
      #|        Char([(65, 65), (97, 97)]),
      #|        Char([(66, 66), (98, 98)]),
      #|        Char([(67, 67), (99, 99)]),
      #|      ]>,
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/ignore_case_with_anchors" {
  let pat = parse(profile=profile_unicode(), mode=String, "(?i:^abc$)")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content=(
      #|Sequence(
      #|  <ReadOnlyArray:
      #|    [
      #|      Assertion(StartOfInput),
      #|      Char([(65, 65), (97, 97)]),
      #|      Char([(66, 66), (98, 98)]),
      #|      Char([(67, 67), (99, 99)]),
      #|      Assertion(EndOfInput),
      #|    ]>,
      #|)
    ),
  )
}

///|
test "parse/parser_error_show" {
  // Cover syntax_error.mbt line 8: Show for ParserError
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "\\d"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=0,
      #|    hint="Use POSIX character class instead of \\w, \\W, \\d, \\D, \\s, \\S",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/double_dash_at_start_of_class" {
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "[a-z--[aeiou]]"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=4,
      #|    hint="Unsupported character class set expression",
      #|  ),
      #|)
    ),
  )
}

// Additional POSIX character class tests for coverage

///|
test "parse/posix_class_ascii" {
  let pat = parse(profile=profile_unicode(), mode=String, "[[:ascii:]]")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content="Char([(0, 127)])",
  )
}

///|
test "parse/posix_class_upper" {
  let pat = parse(profile=profile_unicode(), mode=String, "[[:upper:]]")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content="Char([(65, 90)])",
  )
}

///|
test "parse/posix_class_lower" {
  let pat = parse(profile=profile_unicode(), mode=String, "[[:lower:]]")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content="Char([(97, 122)])",
  )
}

///|
test "parse/posix_class_alnum" {
  let pat = parse(profile=profile_unicode(), mode=String, "[[:alnum:]]")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content=(
      #|Char(
      #|  [
      #|    (48, 57),
      #|    (65, 90),
      #|    (97, 122),
      #|  ],
      #|)
    ),
  )
}

///|
test "parse/posix_class_xdigit" {
  let pat = parse(profile=profile_unicode(), mode=String, "[[:xdigit:]]")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content=(
      #|Char(
      #|  [
      #|    (48, 57),
      #|    (65, 70),
      #|    (97, 102),
      #|  ],
      #|)
    ),
  )
}

///|
test "parse/posix_class_blank" {
  let pat = parse(profile=profile_unicode(), mode=String, "[[:blank:]]")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content="Char([(9, 9), (32, 32)])",
  )
}

///|
test "parse/backspace_in_char_class" {
  // \b in character class means backspace (0x08)
  let pat = parse(profile=profile_unicode(), mode=String, "[\\b]")
  inspect(@debug.render(pat.to_repr(), max_depth=10), content="Char([(8, 8)])")
}

///|
test "parse/formfeed_in_char_class" {
  // \f in character class means formfeed (0x0c = 12)
  let pat = parse(profile=profile_unicode(), mode=String, "[\\f]")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content="Char([(12, 12)])",
  )
}

///|
test "parse/parser_error_show_impl" {
  // Show for ParserError via debug rendering
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "\\d"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=0,
      #|    hint="Use POSIX character class instead of \\w, \\W, \\d, \\D, \\s, \\S",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/parser_error_to_string" {
  let result = try? parse(profile=profile_unicode(), mode=String, "\\d")
  match result {
    Err(err) =>
      inspect(
        err.to_string(),
        content="ParserError at position 0: Use POSIX character class instead of \\w, \\W, \\d, \\D, \\s, \\S",
      )
    Ok(_) => panic()
  }
}

///|
test "parse/escaped_special_chars_in_class" {
  // Cover more escape sequences in character class: / " : &
  let pat1 = parse(profile=profile_unicode(), mode=String, "[\\/]")
  inspect(
    @debug.render(pat1.to_repr(), max_depth=10),
    content="Char([(47, 47)])",
  )
  let pat2 = parse(profile=profile_unicode(), mode=String, "[\\:]")
  inspect(
    @debug.render(pat2.to_repr(), max_depth=10),
    content="Char([(58, 58)])",
  )
  let pat3 = parse(profile=profile_unicode(), mode=String, "[\\&]")
  inspect(
    @debug.render(pat3.to_repr(), max_depth=10),
    content="Char([(38, 38)])",
  )
}

///|
test "parse/error_triple_ampersand" {
  // Triple ampersand triggers set expression error
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "[a&&&b]"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=2,
      #|    hint="Unsupported character class set expression",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/non_capture_group_inside_capture" {
  let pat = parse(profile=profile_unicode(), mode=String, "(a(?:b)c)")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content=(
      #|Capture(
      #|  name=None,
      #|  Sequence(
      #|    <ReadOnlyArray:
      #|      [
      #|        Char([(97, 97)]),
      #|        Char([(98, 98)]),
      #|        Char([(99, 99)]),
      #|      ]>,
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/quantifier_non_greedy_question" {
  let pat = parse(profile=profile_unicode(), mode=String, "a??")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content=(
      #|Quantifier(
      #|  {
      #|    min: 0,
      #|    max: Some(1),
      #|    mode: NonGreedy,
      #|  },
      #|  Char([(97, 97)]),
      #|)
    ),
  )
}

///|
test "parse/quantifier_range_non_greedy" {
  let pat = parse(profile=profile_unicode(), mode=String, "a{2,5}?")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content=(
      #|Quantifier(
      #|  {
      #|    min: 2,
      #|    max: Some(5),
      #|    mode: NonGreedy,
      #|  },
      #|  Char([(97, 97)]),
      #|)
    ),
  )
}

///|
test "parse/nested_ignore_case" {
  // Test nested (?i:...) where ignore_case is already true
  let pat = parse(profile=profile_unicode(), mode=String, "(?i:(?i:abc))")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content=(
      #|Sequence(
      #|  <ReadOnlyArray:
      #|    [
      #|      Char([(65, 65), (97, 97)]),
      #|      Char([(66, 66), (98, 98)]),
      #|      Char([(67, 67), (99, 99)]),
      #|    ]>,
      #|)
    ),
  )
}

///|
test "parse/error_unmatched_paren" {
  // Extra closing paren should trigger unexpected char error
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "abc)"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=3,
      #|    hint="Unexpected character",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_empty_quantifier" {
  // Quantifier on empty pattern should trigger error
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "*"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=0,
      #|    hint="Unexpected character",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/unicode_4digit_in_char_class" {
  // \u0041 inside character class
  let pat = parse(profile=profile_unicode(), mode=String, "[\\u0041]")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content="Char([(65, 65)])",
  )
}

///|
test "parse/unicode_brace_in_char_class" {
  // \u{41} inside character class
  let pat = parse(profile=profile_unicode(), mode=String, "[\\u{41}]")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content="Char([(65, 65)])",
  )
}

///|
test "parse/error_dDsSwW_in_char_class" {
  // \d, \D, \s, \S, \w, \W should error inside character class too
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_unicode(), mode=String, "[\\w]"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=1,
      #|    hint="Use POSIX character class instead of \\w, \\W, \\d, \\D, \\s, \\S",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/ignore_case_quantifier" {
  // (?i:a+) should work
  let pat = parse(profile=profile_unicode(), mode=String, "(?i:a+)")
  inspect(
    @debug.render(pat.to_repr(), max_depth=10),
    content=(
      #|Quantifier(
      #|  {
      #|    min: 1,
      #|    max: None,
      #|    mode: Greedy,
      #|  },
      #|  Char([(65, 65), (97, 97)]),
      #|)
    ),
  )
}

///|
test "parse/error_non_ascii_in_bytes_mode" {
  // Non-ASCII character in bytes mode should trigger CHARACTER_OUT_OF_RANGE
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_bytes(), mode=Bytes, "中"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=0,
      #|    hint="Character out of range",
      #|  ),
      #|)
    ),
  )
}

///|
test "parse/error_non_ascii_in_bytes_mode_char_class" {
  // Non-ASCII character in character class in bytes mode
  inspect(
    @debug.render(
      @debug.Debug::to_repr(
        try? parse(profile=profile_bytes(), mode=Bytes, "[中]"),
      ),
      max_depth=10,
    ),
    content=(
      #|Err(
      #|  ParserError(
      #|    at=2,
      #|    hint="Character out of range",
      #|  ),
      #|)
    ),
  )
}
