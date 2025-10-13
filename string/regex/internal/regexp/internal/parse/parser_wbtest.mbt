// Copyright 2025 International Digital Economy Academy
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
test "parse complex regex with capture group and quantifier" {
  @json.inspect(parse("a(b|c)*d"), content={
    "ast": [
      ["CharClass neg=false", ["'a'", "'a'"]],
      [
        "ZeroOrMore greedy=true",
        [
          "Capture 1",
          [
            "Alternate",
            ["CharClass neg=false", ["'b'", "'b'"]],
            ["CharClass neg=false", ["'c'", "'c'"]],
          ],
        ],
      ],
      ["CharClass neg=false", ["'d'", "'d'"]],
    ],
    "captures": 2,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse multi-branch alternation expression" {
  @json.inspect(parse("abc|def|ghi"), content={
    "ast": [
      "Alternate",
      [
        "Alternate",
        [
          ["CharClass neg=false", ["'a'", "'a'"]],
          ["CharClass neg=false", ["'b'", "'b'"]],
          ["CharClass neg=false", ["'c'", "'c'"]],
        ],
        [
          ["CharClass neg=false", ["'d'", "'d'"]],
          ["CharClass neg=false", ["'e'", "'e'"]],
          ["CharClass neg=false", ["'f'", "'f'"]],
        ],
      ],
      [
        ["CharClass neg=false", ["'g'", "'g'"]],
        ["CharClass neg=false", ["'h'", "'h'"]],
        ["CharClass neg=false", ["'i'", "'i'"]],
      ],
    ],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse dot character (any character match)" {
  @json.inspect(parse("a.c"), content={
    "ast": [
      ["CharClass neg=false", ["'a'", "'a'"]],
      [
        "CharClass neg=false",
        ["'\\u{00}'", "'\\t'", "'\\u{11}'", "'\\u{10ffff}'"],
      ],
      ["CharClass neg=false", ["'c'", "'c'"]],
    ],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse character class range syntax" {
  @json.inspect(parse("[a-z]"), content={
    "ast": ["CharClass neg=false", ["'a'", "'z'"]],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse multiple character class ranges" {
  @json.inspect(parse("[a-zA-Z]"), content={
    "ast": ["CharClass neg=false", ["'a'", "'z'", "'A'", "'Z'"]],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse mixed character class (ranges and individual characters)" {
  @json.inspect(parse("[a-z0-9_]"), content={
    "ast": ["CharClass neg=false", ["'a'", "'z'", "'0'", "'9'", "'_'", "'_'"]],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse literal hyphen in character class" {
  @json.inspect(parse("[abc-]"), content={
    "ast": [
      "CharClass neg=false",
      ["'a'", "'a'", "'b'", "'b'", "'c'", "'c'", "'-'", "'-'"],
    ],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse character class range with escaped characters" {
  @json.inspect(parse("[\\]-a]"), content={
    "ast": ["CharClass neg=false", ["']'", "'a'"]],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })

  // Test invalid case: end character is less than start character
  let regex = try? parse("[a-\\]]")
  inspect(
    regex.map(ignore),
    content=(
      #|Err(RegexpError(err=InvalidCharClass, source_fragment="]"))
    ),
  )
}

///|
test "parse exact repeat quantifier {n}" {
  @json.inspect(parse("a{3}"), content={
    "ast": [
      "Repeat {3, 3} greedy=true",
      ["CharClass neg=false", ["'a'", "'a'"]],
    ],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse minimum repeat quantifier {n,}" {
  @json.inspect(parse("b{2,}"), content={
    "ast": ["Repeat {2,} greedy=true", ["CharClass neg=false", ["'b'", "'b'"]]],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse range repeat quantifier {n,m}" {
  @json.inspect(parse("c{2,4}"), content={
    "ast": [
      "Repeat {2, 4} greedy=true",
      ["CharClass neg=false", ["'c'", "'c'"]],
    ],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse lazy minimum repeat quantifier {n,}?" {
  @json.inspect(parse("d{2,}?"), content={
    "ast": ["Repeat {2,} greedy=false", ["CharClass neg=false", ["'d'", "'d'"]]],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse complex repeat quantifier expression" {
  @json.inspect(parse("a{2}b{1,3}c{2,}"), content={
    "ast": [
      ["Repeat {2, 2} greedy=true", ["CharClass neg=false", ["'a'", "'a'"]]],
      ["Repeat {1, 3} greedy=true", ["CharClass neg=false", ["'b'", "'b'"]]],
      ["Repeat {2,} greedy=true", ["CharClass neg=false", ["'c'", "'c'"]]],
    ],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse repeat quantifier with groups" {
  @json.inspect(parse("(ab){2}"), content={
    "ast": [
      "Repeat {2, 2} greedy=true",
      [
        "Capture 1",
        [
          ["CharClass neg=false", ["'a'", "'a'"]],
          ["CharClass neg=false", ["'b'", "'b'"]],
        ],
      ],
    ],
    "captures": 2,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse repeat quantifier error cases" {
  // Test case where {m,n} has m > n
  let regex = try? parse("a{5,2}")
  inspect(
    regex.map(ignore),
    content=(
      #|Err(RegexpError(err=InvalidRepeatSize, source_fragment=""))
    ),
  )

  // Test case with missing number
  let regex = try? parse("a{}")
  inspect(
    regex.map(ignore),
    content=(
      #|Err(RegexpError(err=MissingRepeatArgument, source_fragment="}"))
    ),
  )

  // Test case with missing right brace
  let regex = try? parse("a{2")
  inspect(
    regex.map(ignore),
    content=(
      #|Err(RegexpError(err=InvalidRepeatOp, source_fragment=""))
    ),
  )

  // Test case with invalid format
  let regex = try? parse("a{2,3,4}")
  inspect(
    regex.map(ignore),
    content=(
      #|Err(RegexpError(err=InvalidRepeatOp, source_fragment=",4}"))
    ),
  )
}

///|
test "parse non-capturing group" {
  @json.inspect(parse("(?:abc)"), content={
    "ast": [
      ["CharClass neg=false", ["'a'", "'a'"]],
      ["CharClass neg=false", ["'b'", "'b'"]],
      ["CharClass neg=false", ["'c'", "'c'"]],
    ],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse named capture group" {
  @json.inspect(parse("(?<name>abc)"), content={
    "ast": [
      "Capture 1",
      [
        ["CharClass neg=false", ["'a'", "'a'"]],
        ["CharClass neg=false", ["'b'", "'b'"]],
        ["CharClass neg=false", ["'c'", "'c'"]],
      ],
    ],
    "captures": 2,
    "capture_map": { "name": 1 },
    "has_backreference": false,
  })
}

///|
test "parse complex named capture group expression" {
  @json.inspect(parse("(?<first>a+)(?<second>b+)"), content={
    "ast": [
      [
        "Capture 1",
        ["OneOrMore greedy=true", ["CharClass neg=false", ["'a'", "'a'"]]],
      ],
      [
        "Capture 2",
        ["OneOrMore greedy=true", ["CharClass neg=false", ["'b'", "'b'"]]],
      ],
    ],
    "captures": 3,
    "capture_map": { "first": 1, "second": 2 },
    "has_backreference": false,
  })
}

///|
test "parse nested named capture groups" {
  @json.inspect(parse("(?<outer>a(?<inner>bc)d)"), content={
    "ast": [
      "Capture 1",
      [
        ["CharClass neg=false", ["'a'", "'a'"]],
        [
          "Capture 2",
          [
            ["CharClass neg=false", ["'b'", "'b'"]],
            ["CharClass neg=false", ["'c'", "'c'"]],
          ],
        ],
        ["CharClass neg=false", ["'d'", "'d'"]],
      ],
    ],
    "captures": 3,
    "capture_map": { "inner": 2, "outer": 1 },
    "has_backreference": false,
  })
}

///|
test "parse mixed named and regular capture groups" {
  @json.inspect(parse("(a)(?<named>b)(c)"), content={
    "ast": [
      ["Capture 1", ["CharClass neg=false", ["'a'", "'a'"]]],
      ["Capture 2", ["CharClass neg=false", ["'b'", "'b'"]]],
      ["Capture 3", ["CharClass neg=false", ["'c'", "'c'"]]],
    ],
    "captures": 4,
    "capture_map": { "named": 2 },
    "has_backreference": false,
  })
}

///|
test "parse named capture group error cases" {
  // Test empty group name
  let regex = try? parse("(?<>abc)")
  inspect(
    regex.map(ignore),
    content=(
      #|Err(RegexpError(err=InvalidNamedCapture, source_fragment=">abc)"))
    ),
  )

  // Test group name starting with a digit
  let regex = try? parse("(?<1invalid>abc)")
  inspect(
    regex.map(ignore),
    content=(
      #|Err(RegexpError(err=InvalidNamedCapture, source_fragment="1invalid>abc)"))
    ),
  )

  // Test group name with illegal characters
  let regex = try? parse("(?<na-me>abc)")
  inspect(
    regex.map(ignore),
    content=(
      #|Err(RegexpError(err=InvalidNamedCapture, source_fragment="-me>abc)"))
    ),
  )

  // Test missing right angle bracket
  let regex = try? parse("(?<name abc)")
  inspect(
    regex.map(ignore),
    content=(
      #|Err(RegexpError(err=InvalidNamedCapture, source_fragment=" abc)"))
    ),
  )

  // Test missing right parenthesis
  let regex = try? parse("(?<name>abc")
  inspect(
    regex.map(ignore),
    content=(
      #|Err(RegexpError(err=MissingParenthesis, source_fragment=""))
    ),
  )
}

///|
test "parse valid group name formats" {
  // Starts with a letter
  @json.inspect(parse("(?<group>abc)"), content={
    "ast": [
      "Capture 1",
      [
        ["CharClass neg=false", ["'a'", "'a'"]],
        ["CharClass neg=false", ["'b'", "'b'"]],
        ["CharClass neg=false", ["'c'", "'c'"]],
      ],
    ],
    "captures": 2,
    "capture_map": { "group": 1 },
    "has_backreference": false,
  })

  // Starts with an underscore
  @json.inspect(parse("(?<_group>abc)"), content={
    "ast": [
      "Capture 1",
      [
        ["CharClass neg=false", ["'a'", "'a'"]],
        ["CharClass neg=false", ["'b'", "'b'"]],
        ["CharClass neg=false", ["'c'", "'c'"]],
      ],
    ],
    "captures": 2,
    "capture_map": { "_group": 1 },
    "has_backreference": false,
  })

  // Contains digits
  @json.inspect(parse("(?<group1>abc)"), content={
    "ast": [
      "Capture 1",
      [
        ["CharClass neg=false", ["'a'", "'a'"]],
        ["CharClass neg=false", ["'b'", "'b'"]],
        ["CharClass neg=false", ["'c'", "'c'"]],
      ],
    ],
    "captures": 2,
    "capture_map": { "group1": 1 },
    "has_backreference": false,
  })

  // Contains multiple underscores
  @json.inspect(parse("(?<my_group_1>abc)"), content={
    "ast": [
      "Capture 1",
      [
        ["CharClass neg=false", ["'a'", "'a'"]],
        ["CharClass neg=false", ["'b'", "'b'"]],
        ["CharClass neg=false", ["'c'", "'c'"]],
      ],
    ],
    "captures": 2,
    "capture_map": { "my_group_1": 1 },
    "has_backreference": false,
  })
}

///|
test "parse line begin assertion ^" {
  @json.inspect(parse("^abc", flags={ ..Flags::default(), multiline: true }), content={
    "ast": [
      "Assertion BeginLine",
      ["CharClass neg=false", ["'a'", "'a'"]],
      ["CharClass neg=false", ["'b'", "'b'"]],
      ["CharClass neg=false", ["'c'", "'c'"]],
    ],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse line end assertion $" {
  @json.inspect(parse("abc$", flags={ ..Flags::default(), multiline: true }), content={
    "ast": [
      ["CharClass neg=false", ["'a'", "'a'"]],
      ["CharClass neg=false", ["'b'", "'b'"]],
      ["CharClass neg=false", ["'c'", "'c'"]],
      "Assertion EndLine",
    ],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse line begin and end assertion ^...$" {
  @json.inspect(parse("^abc$"), content={
    "ast": [
      "Assertion BeginText",
      ["CharClass neg=false", ["'a'", "'a'"]],
      ["CharClass neg=false", ["'b'", "'b'"]],
      ["CharClass neg=false", ["'c'", "'c'"]],
      "Assertion EndText",
    ],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse multiline assertions" {
  @json.inspect(parse("^line", flags={ ..Flags::default(), multiline: true }), content={
    "ast": [
      "Assertion BeginLine",
      ["CharClass neg=false", ["'l'", "'l'"]],
      ["CharClass neg=false", ["'i'", "'i'"]],
      ["CharClass neg=false", ["'n'", "'n'"]],
      ["CharClass neg=false", ["'e'", "'e'"]],
    ],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
  @json.inspect(parse("line$", flags={ ..Flags::default(), multiline: true }), content={
    "ast": [
      ["CharClass neg=false", ["'l'", "'l'"]],
      ["CharClass neg=false", ["'i'", "'i'"]],
      ["CharClass neg=false", ["'n'", "'n'"]],
      ["CharClass neg=false", ["'e'", "'e'"]],
      "Assertion EndLine",
    ],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse assertion with quantifiers" {
  @json.inspect(parse("^a+$"), content={
    "ast": [
      "Assertion BeginText",
      ["OneOrMore greedy=true", ["CharClass neg=false", ["'a'", "'a'"]]],
      "Assertion EndText",
    ],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse assertion with capture groups" {
  @json.inspect(parse("^(abc)$"), content={
    "ast": [
      "Assertion BeginText",
      [
        "Capture 1",
        [
          ["CharClass neg=false", ["'a'", "'a'"]],
          ["CharClass neg=false", ["'b'", "'b'"]],
          ["CharClass neg=false", ["'c'", "'c'"]],
        ],
      ],
      "Assertion EndText",
    ],
    "captures": 2,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse escaped assertion characters" {
  @json.inspect(parse("\\^abc\\$"), content={
    "ast": [
      ["CharClass neg=false", ["'^'", "'^'"]],
      ["CharClass neg=false", ["'a'", "'a'"]],
      ["CharClass neg=false", ["'b'", "'b'"]],
      ["CharClass neg=false", ["'c'", "'c'"]],
      ["CharClass neg=false", ["'$'", "'$'"]],
    ],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse assertion characters in character class" {
  @json.inspect(parse("[^$]"), content={
    "ast": ["CharClass neg=true", ["'$'", "'$'"]],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse complex assertion expression" {
  @json.inspect(parse("^(hello|world)$"), content={
    "ast": [
      "Assertion BeginText",
      [
        "Capture 1",
        [
          "Alternate",
          [
            ["CharClass neg=false", ["'h'", "'h'"]],
            ["CharClass neg=false", ["'e'", "'e'"]],
            ["CharClass neg=false", ["'l'", "'l'"]],
            ["CharClass neg=false", ["'l'", "'l'"]],
            ["CharClass neg=false", ["'o'", "'o'"]],
          ],
          [
            ["CharClass neg=false", ["'w'", "'w'"]],
            ["CharClass neg=false", ["'o'", "'o'"]],
            ["CharClass neg=false", ["'r'", "'r'"]],
            ["CharClass neg=false", ["'l'", "'l'"]],
            ["CharClass neg=false", ["'d'", "'d'"]],
          ],
        ],
      ],
      "Assertion EndText",
    ],
    "captures": 2,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse word boundary assertion \\b" {
  @json.inspect(parse("\\bword\\b"), content={
    "ast": [
      "Assertion WordBoundary",
      ["CharClass neg=false", ["'w'", "'w'"]],
      ["CharClass neg=false", ["'o'", "'o'"]],
      ["CharClass neg=false", ["'r'", "'r'"]],
      ["CharClass neg=false", ["'d'", "'d'"]],
      "Assertion WordBoundary",
    ],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse non-word boundary assertion \\B" {
  @json.inspect(parse("\\Bword\\B"), content={
    "ast": [
      "Assertion NoWordBoundary",
      ["CharClass neg=false", ["'w'", "'w'"]],
      ["CharClass neg=false", ["'o'", "'o'"]],
      ["CharClass neg=false", ["'r'", "'r'"]],
      ["CharClass neg=false", ["'d'", "'d'"]],
      "Assertion NoWordBoundary",
    ],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse combined word boundary assertions" {
  @json.inspect(parse("\\btest|\\btesting\\b"), content={
    "ast": [
      "Alternate",
      [
        "Assertion WordBoundary",
        ["CharClass neg=false", ["'t'", "'t'"]],
        ["CharClass neg=false", ["'e'", "'e'"]],
        ["CharClass neg=false", ["'s'", "'s'"]],
        ["CharClass neg=false", ["'t'", "'t'"]],
      ],
      [
        "Assertion WordBoundary",
        ["CharClass neg=false", ["'t'", "'t'"]],
        ["CharClass neg=false", ["'e'", "'e'"]],
        ["CharClass neg=false", ["'s'", "'s'"]],
        ["CharClass neg=false", ["'t'", "'t'"]],
        ["CharClass neg=false", ["'i'", "'i'"]],
        ["CharClass neg=false", ["'n'", "'n'"]],
        ["CharClass neg=false", ["'g'", "'g'"]],
        "Assertion WordBoundary",
      ],
    ],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse word boundary with character class" {
  @json.inspect(parse("\\b[a-z]+\\b"), content={
    "ast": [
      "Assertion WordBoundary",
      ["OneOrMore greedy=true", ["CharClass neg=false", ["'a'", "'z'"]]],
      "Assertion WordBoundary",
    ],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse word boundary with quantifiers" {
  @json.inspect(parse("\\b\\w{3,5}\\b"), content={
    "ast": [
      "Assertion WordBoundary",
      [
        "Repeat {3, 5} greedy=true",
        [
          "CharClass neg=false",
          ["'0'", "'9'", "'A'", "'Z'", "'_'", "'_'", "'a'", "'z'"],
        ],
      ],
      "Assertion WordBoundary",
    ],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
/// Test case: Word boundary combined with capture groups
///
/// Test regex "\\b(\\w+)\\b":
/// - Word boundary assertion: \b
/// - Capture group: (\w+) captures one or more word characters
/// - Word boundary assertion: \b
///
/// Expected to capture a whole word
test "parse word boundary with capture groups" {
  @json.inspect(parse("\\b(\\w+)\\b"), content={
    "ast": [
      "Assertion WordBoundary",
      [
        "Capture 1",
        [
          "OneOrMore greedy=true",
          [
            "CharClass neg=false",
            ["'0'", "'9'", "'A'", "'Z'", "'_'", "'_'", "'a'", "'z'"],
          ],
        ],
      ],
      "Assertion WordBoundary",
    ],
    "captures": 2,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse complex word boundary expression" {
  // Simplified version, only tests basic word boundary functionality
  @json.inspect(parse("\\bthe\\b"), content={
    "ast": [
      "Assertion WordBoundary",
      ["CharClass neg=false", ["'t'", "'t'"]],
      ["CharClass neg=false", ["'h'", "'h'"]],
      ["CharClass neg=false", ["'e'", "'e'"]],
      "Assertion WordBoundary",
    ],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse unicode general property" {
  @json.inspect(parse("\\p{Ll}"), content={
    "ast": [
      "CharClass neg=false",
      [
        "'a'", "'z'", "'µ'", "'µ'", "'ß'", "'ö'", "'ø'", "'ÿ'", "'ā'", "'ā'",
        "'ă'", "'ă'", "'ą'", "'ą'", "'ć'", "'ć'", "'ĉ'", "'ĉ'", "'ċ'", "'ċ'",
        "'č'", "'č'", "'ď'", "'ď'", "'đ'", "'đ'", "'ē'", "'ē'", "'ĕ'", "'ĕ'",
        "'ė'", "'ė'", "'ę'", "'ę'", "'ě'", "'ě'", "'ĝ'", "'ĝ'", "'ğ'", "'ğ'",
        "'ġ'", "'ġ'", "'ģ'", "'ģ'", "'ĥ'", "'ĥ'", "'ħ'", "'ħ'", "'ĩ'", "'ĩ'",
        "'ī'", "'ī'", "'ĭ'", "'ĭ'", "'į'", "'į'", "'ı'", "'ı'", "'ĳ'", "'ĳ'",
        "'ĵ'", "'ĵ'", "'ķ'", "'ĸ'", "'ĺ'", "'ĺ'", "'ļ'", "'ļ'", "'ľ'", "'ľ'",
        "'ŀ'", "'ŀ'", "'ł'", "'ł'", "'ń'", "'ń'", "'ņ'", "'ņ'", "'ň'", "'ŉ'",
        "'ŋ'", "'ŋ'", "'ō'", "'ō'", "'ŏ'", "'ŏ'", "'ő'", "'ő'", "'œ'", "'œ'",
        "'ŕ'", "'ŕ'", "'ŗ'", "'ŗ'", "'ř'", "'ř'", "'ś'", "'ś'", "'ŝ'", "'ŝ'",
        "'ş'", "'ş'", "'š'", "'š'", "'ţ'", "'ţ'", "'ť'", "'ť'", "'ŧ'", "'ŧ'",
        "'ũ'", "'ũ'", "'ū'", "'ū'", "'ŭ'", "'ŭ'", "'ů'", "'ů'", "'ű'", "'ű'",
        "'ų'", "'ų'", "'ŵ'", "'ŵ'", "'ŷ'", "'ŷ'", "'ź'", "'ź'", "'ż'", "'ż'",
        "'ž'", "'ƀ'", "'ƃ'", "'ƃ'", "'ƅ'", "'ƅ'", "'ƈ'", "'ƈ'", "'ƌ'", "'ƍ'",
        "'ƒ'", "'ƒ'", "'ƕ'", "'ƕ'", "'ƙ'", "'ƛ'", "'ƞ'", "'ƞ'", "'ơ'", "'ơ'",
        "'ƣ'", "'ƣ'", "'ƥ'", "'ƥ'", "'ƨ'", "'ƨ'", "'ƪ'", "'ƫ'", "'ƭ'", "'ƭ'",
        "'ư'", "'ư'", "'ƴ'", "'ƴ'", "'ƶ'", "'ƶ'", "'ƹ'", "'ƺ'", "'ƽ'", "'ƿ'",
        "'ǆ'", "'ǆ'", "'ǉ'", "'ǉ'", "'ǌ'", "'ǌ'", "'ǎ'", "'ǎ'", "'ǐ'", "'ǐ'",
        "'ǒ'", "'ǒ'", "'ǔ'", "'ǔ'", "'ǖ'", "'ǖ'", "'ǘ'", "'ǘ'", "'ǚ'", "'ǚ'",
        "'ǜ'", "'ǝ'", "'ǟ'", "'ǟ'", "'ǡ'", "'ǡ'", "'ǣ'", "'ǣ'", "'ǥ'", "'ǥ'",
        "'ǧ'", "'ǧ'", "'ǩ'", "'ǩ'", "'ǫ'", "'ǫ'", "'ǭ'", "'ǭ'", "'ǯ'", "'ǰ'",
        "'ǳ'", "'ǳ'", "'ǵ'", "'ǵ'", "'ǹ'", "'ǹ'", "'ǻ'", "'ǻ'", "'ǽ'", "'ǽ'",
        "'ǿ'", "'ǿ'", "'ȁ'", "'ȁ'", "'ȃ'", "'ȃ'", "'ȅ'", "'ȅ'", "'ȇ'", "'ȇ'",
        "'ȉ'", "'ȉ'", "'ȋ'", "'ȋ'", "'ȍ'", "'ȍ'", "'ȏ'", "'ȏ'", "'ȑ'", "'ȑ'",
        "'ȓ'", "'ȓ'", "'ȕ'", "'ȕ'", "'ȗ'", "'ȗ'", "'ș'", "'ș'", "'ț'", "'ț'",
        "'ȝ'", "'ȝ'", "'ȟ'", "'ȟ'", "'ȡ'", "'ȡ'", "'ȣ'", "'ȣ'", "'ȥ'", "'ȥ'",
        "'ȧ'", "'ȧ'", "'ȩ'", "'ȩ'", "'ȫ'", "'ȫ'", "'ȭ'", "'ȭ'", "'ȯ'", "'ȯ'",
        "'ȱ'", "'ȱ'", "'ȳ'", "'ȹ'", "'ȼ'", "'ȼ'", "'ȿ'", "'ɀ'", "'ɂ'", "'ɂ'",
        "'ɇ'", "'ɇ'", "'ɉ'", "'ɉ'", "'ɋ'", "'ɋ'", "'ɍ'", "'ɍ'", "'ɏ'", "'ʓ'",
        "'ʕ'", "'ʯ'", "'ͱ'", "'ͱ'", "'ͳ'", "'ͳ'", "'ͷ'", "'ͷ'", "'ͻ'", "'ͽ'",
        "'ΐ'", "'ΐ'", "'ά'", "'ώ'", "'ϐ'", "'ϑ'", "'ϕ'", "'ϗ'", "'ϙ'", "'ϙ'",
        "'ϛ'", "'ϛ'", "'ϝ'", "'ϝ'", "'ϟ'", "'ϟ'", "'ϡ'", "'ϡ'", "'ϣ'", "'ϣ'",
        "'ϥ'", "'ϥ'", "'ϧ'", "'ϧ'", "'ϩ'", "'ϩ'", "'ϫ'", "'ϫ'", "'ϭ'", "'ϭ'",
        "'ϯ'", "'ϳ'", "'ϵ'", "'ϵ'", "'ϸ'", "'ϸ'", "'ϻ'", "'ϼ'", "'а'", "'џ'",
        "'ѡ'", "'ѡ'", "'ѣ'", "'ѣ'", "'ѥ'", "'ѥ'", "'ѧ'", "'ѧ'", "'ѩ'", "'ѩ'",
        "'ѫ'", "'ѫ'", "'ѭ'", "'ѭ'", "'ѯ'", "'ѯ'", "'ѱ'", "'ѱ'", "'ѳ'", "'ѳ'",
        "'ѵ'", "'ѵ'", "'ѷ'", "'ѷ'", "'ѹ'", "'ѹ'", "'ѻ'", "'ѻ'", "'ѽ'", "'ѽ'",
        "'ѿ'", "'ѿ'", "'ҁ'", "'ҁ'", "'ҋ'", "'ҋ'", "'ҍ'", "'ҍ'", "'ҏ'", "'ҏ'",
        "'ґ'", "'ґ'", "'ғ'", "'ғ'", "'ҕ'", "'ҕ'", "'җ'", "'җ'", "'ҙ'", "'ҙ'",
        "'қ'", "'қ'", "'ҝ'", "'ҝ'", "'ҟ'", "'ҟ'", "'ҡ'", "'ҡ'", "'ң'", "'ң'",
        "'ҥ'", "'ҥ'", "'ҧ'", "'ҧ'", "'ҩ'", "'ҩ'", "'ҫ'", "'ҫ'", "'ҭ'", "'ҭ'",
        "'ү'", "'ү'", "'ұ'", "'ұ'", "'ҳ'", "'ҳ'", "'ҵ'", "'ҵ'", "'ҷ'", "'ҷ'",
        "'ҹ'", "'ҹ'", "'һ'", "'һ'", "'ҽ'", "'ҽ'", "'ҿ'", "'ҿ'", "'ӂ'", "'ӂ'",
        "'ӄ'", "'ӄ'", "'ӆ'", "'ӆ'", "'ӈ'", "'ӈ'", "'ӊ'", "'ӊ'", "'ӌ'", "'ӌ'",
        "'ӎ'", "'ӏ'", "'ӑ'", "'ӑ'", "'ӓ'", "'ӓ'", "'ӕ'", "'ӕ'", "'ӗ'", "'ӗ'",
        "'ә'", "'ә'", "'ӛ'", "'ӛ'", "'ӝ'", "'ӝ'", "'ӟ'", "'ӟ'", "'ӡ'", "'ӡ'",
        "'ӣ'", "'ӣ'", "'ӥ'", "'ӥ'", "'ӧ'", "'ӧ'", "'ө'", "'ө'", "'ӫ'", "'ӫ'",
        "'ӭ'", "'ӭ'", "'ӯ'", "'ӯ'", "'ӱ'", "'ӱ'", "'ӳ'", "'ӳ'", "'ӵ'", "'ӵ'",
        "'ӷ'", "'ӷ'", "'ӹ'", "'ӹ'", "'ӻ'", "'ӻ'", "'ӽ'", "'ӽ'", "'ӿ'", "'ӿ'",
        "'ԁ'", "'ԁ'", "'ԃ'", "'ԃ'", "'ԅ'", "'ԅ'", "'ԇ'", "'ԇ'", "'ԉ'", "'ԉ'",
        "'ԋ'", "'ԋ'", "'ԍ'", "'ԍ'", "'ԏ'", "'ԏ'", "'ԑ'", "'ԑ'", "'ԓ'", "'ԓ'",
        "'ԕ'", "'ԕ'", "'ԗ'", "'ԗ'", "'ԙ'", "'ԙ'", "'ԛ'", "'ԛ'", "'ԝ'", "'ԝ'",
        "'ԟ'", "'ԟ'", "'ԡ'", "'ԡ'", "'ԣ'", "'ԣ'", "'ԥ'", "'ԥ'", "'ԧ'", "'ԧ'",
        "'ԩ'", "'ԩ'", "'ԫ'", "'ԫ'", "'ԭ'", "'ԭ'", "'ԯ'", "'ԯ'", "'ՠ'", "'ֈ'",
        "'ა'", "'ჺ'", "'ჽ'", "'ჿ'", "'ᏸ'", "'ᏽ'", "'ᲀ'", "'ᲈ'", "'ᲊ'",
        "'ᲊ'", "'ᴀ'", "'ᴫ'", "'ᵫ'", "'ᵷ'", "'ᵹ'", "'ᶚ'", "'ḁ'", "'ḁ'",
        "'ḃ'", "'ḃ'", "'ḅ'", "'ḅ'", "'ḇ'", "'ḇ'", "'ḉ'", "'ḉ'", "'ḋ'",
        "'ḋ'", "'ḍ'", "'ḍ'", "'ḏ'", "'ḏ'", "'ḑ'", "'ḑ'", "'ḓ'", "'ḓ'",
        "'ḕ'", "'ḕ'", "'ḗ'", "'ḗ'", "'ḙ'", "'ḙ'", "'ḛ'", "'ḛ'", "'ḝ'",
        "'ḝ'", "'ḟ'", "'ḟ'", "'ḡ'", "'ḡ'", "'ḣ'", "'ḣ'", "'ḥ'", "'ḥ'",
        "'ḧ'", "'ḧ'", "'ḩ'", "'ḩ'", "'ḫ'", "'ḫ'", "'ḭ'", "'ḭ'", "'ḯ'",
        "'ḯ'", "'ḱ'", "'ḱ'", "'ḳ'", "'ḳ'", "'ḵ'", "'ḵ'", "'ḷ'", "'ḷ'",
        "'ḹ'", "'ḹ'", "'ḻ'", "'ḻ'", "'ḽ'", "'ḽ'", "'ḿ'", "'ḿ'", "'ṁ'",
        "'ṁ'", "'ṃ'", "'ṃ'", "'ṅ'", "'ṅ'", "'ṇ'", "'ṇ'", "'ṉ'", "'ṉ'",
        "'ṋ'", "'ṋ'", "'ṍ'", "'ṍ'", "'ṏ'", "'ṏ'", "'ṑ'", "'ṑ'", "'ṓ'",
        "'ṓ'", "'ṕ'", "'ṕ'", "'ṗ'", "'ṗ'", "'ṙ'", "'ṙ'", "'ṛ'", "'ṛ'",
        "'ṝ'", "'ṝ'", "'ṟ'", "'ṟ'", "'ṡ'", "'ṡ'", "'ṣ'", "'ṣ'", "'ṥ'",
        "'ṥ'", "'ṧ'", "'ṧ'", "'ṩ'", "'ṩ'", "'ṫ'", "'ṫ'", "'ṭ'", "'ṭ'",
        "'ṯ'", "'ṯ'", "'ṱ'", "'ṱ'", "'ṳ'", "'ṳ'", "'ṵ'", "'ṵ'", "'ṷ'",
        "'ṷ'", "'ṹ'", "'ṹ'", "'ṻ'", "'ṻ'", "'ṽ'", "'ṽ'", "'ṿ'", "'ṿ'",
        "'ẁ'", "'ẁ'", "'ẃ'", "'ẃ'", "'ẅ'", "'ẅ'", "'ẇ'", "'ẇ'", "'ẉ'",
        "'ẉ'", "'ẋ'", "'ẋ'", "'ẍ'", "'ẍ'", "'ẏ'", "'ẏ'", "'ẑ'", "'ẑ'",
        "'ẓ'", "'ẓ'", "'ẕ'", "'ẝ'", "'ẟ'", "'ẟ'", "'ạ'", "'ạ'", "'ả'",
        "'ả'", "'ấ'", "'ấ'", "'ầ'", "'ầ'", "'ẩ'", "'ẩ'", "'ẫ'", "'ẫ'",
        "'ậ'", "'ậ'", "'ắ'", "'ắ'", "'ằ'", "'ằ'", "'ẳ'", "'ẳ'", "'ẵ'",
        "'ẵ'", "'ặ'", "'ặ'", "'ẹ'", "'ẹ'", "'ẻ'", "'ẻ'", "'ẽ'", "'ẽ'",
        "'ế'", "'ế'", "'ề'", "'ề'", "'ể'", "'ể'", "'ễ'", "'ễ'", "'ệ'",
        "'ệ'", "'ỉ'", "'ỉ'", "'ị'", "'ị'", "'ọ'", "'ọ'", "'ỏ'", "'ỏ'",
        "'ố'", "'ố'", "'ồ'", "'ồ'", "'ổ'", "'ổ'", "'ỗ'", "'ỗ'", "'ộ'",
        "'ộ'", "'ớ'", "'ớ'", "'ờ'", "'ờ'", "'ở'", "'ở'", "'ỡ'", "'ỡ'",
        "'ợ'", "'ợ'", "'ụ'", "'ụ'", "'ủ'", "'ủ'", "'ứ'", "'ứ'", "'ừ'",
        "'ừ'", "'ử'", "'ử'", "'ữ'", "'ữ'", "'ự'", "'ự'", "'ỳ'", "'ỳ'",
        "'ỵ'", "'ỵ'", "'ỷ'", "'ỷ'", "'ỹ'", "'ỹ'", "'ỻ'", "'ỻ'", "'ỽ'",
        "'ỽ'", "'ỿ'", "'ἇ'", "'ἐ'", "'ἕ'", "'ἠ'", "'ἧ'", "'ἰ'", "'ἷ'",
        "'ὀ'", "'ὅ'", "'ὐ'", "'ὗ'", "'ὠ'", "'ὧ'", "'ὰ'", "'ώ'", "'ᾀ'",
        "'ᾇ'", "'ᾐ'", "'ᾗ'", "'ᾠ'", "'ᾧ'", "'ᾰ'", "'ᾴ'", "'ᾶ'", "'ᾷ'",
        "'ι'", "'ι'", "'ῂ'", "'ῄ'", "'ῆ'", "'ῇ'", "'ῐ'", "'ΐ'", "'ῖ'",
        "'ῗ'", "'ῠ'", "'ῧ'", "'ῲ'", "'ῴ'", "'ῶ'", "'ῷ'", "'ℊ'", "'ℊ'",
        "'ℎ'", "'ℏ'", "'ℓ'", "'ℓ'", "'ℯ'", "'ℯ'", "'ℴ'", "'ℴ'", "'ℹ'",
        "'ℹ'", "'ℼ'", "'ℽ'", "'ⅆ'", "'ⅉ'", "'ⅎ'", "'ⅎ'", "'ↄ'", "'ↄ'",
        "'ⰰ'", "'ⱟ'", "'ⱡ'", "'ⱡ'", "'ⱥ'", "'ⱦ'", "'ⱨ'", "'ⱨ'", "'ⱪ'",
        "'ⱪ'", "'ⱬ'", "'ⱬ'", "'ⱱ'", "'ⱱ'", "'ⱳ'", "'ⱴ'", "'ⱶ'", "'ⱻ'",
        "'ⲁ'", "'ⲁ'", "'ⲃ'", "'ⲃ'", "'ⲅ'", "'ⲅ'", "'ⲇ'", "'ⲇ'", "'ⲉ'",
        "'ⲉ'", "'ⲋ'", "'ⲋ'", "'ⲍ'", "'ⲍ'", "'ⲏ'", "'ⲏ'", "'ⲑ'", "'ⲑ'",
        "'ⲓ'", "'ⲓ'", "'ⲕ'", "'ⲕ'", "'ⲗ'", "'ⲗ'", "'ⲙ'", "'ⲙ'", "'ⲛ'",
        "'ⲛ'", "'ⲝ'", "'ⲝ'", "'ⲟ'", "'ⲟ'", "'ⲡ'", "'ⲡ'", "'ⲣ'", "'ⲣ'",
        "'ⲥ'", "'ⲥ'", "'ⲧ'", "'ⲧ'", "'ⲩ'", "'ⲩ'", "'ⲫ'", "'ⲫ'", "'ⲭ'",
        "'ⲭ'", "'ⲯ'", "'ⲯ'", "'ⲱ'", "'ⲱ'", "'ⲳ'", "'ⲳ'", "'ⲵ'", "'ⲵ'",
        "'ⲷ'", "'ⲷ'", "'ⲹ'", "'ⲹ'", "'ⲻ'", "'ⲻ'", "'ⲽ'", "'ⲽ'", "'ⲿ'",
        "'ⲿ'", "'ⳁ'", "'ⳁ'", "'ⳃ'", "'ⳃ'", "'ⳅ'", "'ⳅ'", "'ⳇ'", "'ⳇ'",
        "'ⳉ'", "'ⳉ'", "'ⳋ'", "'ⳋ'", "'ⳍ'", "'ⳍ'", "'ⳏ'", "'ⳏ'", "'ⳑ'",
        "'ⳑ'", "'ⳓ'", "'ⳓ'", "'ⳕ'", "'ⳕ'", "'ⳗ'", "'ⳗ'", "'ⳙ'", "'ⳙ'",
        "'ⳛ'", "'ⳛ'", "'ⳝ'", "'ⳝ'", "'ⳟ'", "'ⳟ'", "'ⳡ'", "'ⳡ'", "'ⳣ'",
        "'ⳤ'", "'ⳬ'", "'ⳬ'", "'ⳮ'", "'ⳮ'", "'ⳳ'", "'ⳳ'", "'ⴀ'", "'ⴥ'",
        "'ⴧ'", "'ⴧ'", "'ⴭ'", "'ⴭ'", "'ꙁ'", "'ꙁ'", "'ꙃ'", "'ꙃ'", "'ꙅ'",
        "'ꙅ'", "'ꙇ'", "'ꙇ'", "'ꙉ'", "'ꙉ'", "'ꙋ'", "'ꙋ'", "'ꙍ'", "'ꙍ'",
        "'ꙏ'", "'ꙏ'", "'ꙑ'", "'ꙑ'", "'ꙓ'", "'ꙓ'", "'ꙕ'", "'ꙕ'", "'ꙗ'",
        "'ꙗ'", "'ꙙ'", "'ꙙ'", "'ꙛ'", "'ꙛ'", "'ꙝ'", "'ꙝ'", "'ꙟ'", "'ꙟ'",
        "'ꙡ'", "'ꙡ'", "'ꙣ'", "'ꙣ'", "'ꙥ'", "'ꙥ'", "'ꙧ'", "'ꙧ'", "'ꙩ'",
        "'ꙩ'", "'ꙫ'", "'ꙫ'", "'ꙭ'", "'ꙭ'", "'ꚁ'", "'ꚁ'", "'ꚃ'", "'ꚃ'",
        "'ꚅ'", "'ꚅ'", "'ꚇ'", "'ꚇ'", "'ꚉ'", "'ꚉ'", "'ꚋ'", "'ꚋ'", "'ꚍ'",
        "'ꚍ'", "'ꚏ'", "'ꚏ'", "'ꚑ'", "'ꚑ'", "'ꚓ'", "'ꚓ'", "'ꚕ'", "'ꚕ'",
        "'ꚗ'", "'ꚗ'", "'ꚙ'", "'ꚙ'", "'ꚛ'", "'ꚛ'", "'ꜣ'", "'ꜣ'", "'ꜥ'",
        "'ꜥ'", "'ꜧ'", "'ꜧ'", "'ꜩ'", "'ꜩ'", "'ꜫ'", "'ꜫ'", "'ꜭ'", "'ꜭ'",
        "'ꜯ'", "'ꜱ'", "'ꜳ'", "'ꜳ'", "'ꜵ'", "'ꜵ'", "'ꜷ'", "'ꜷ'", "'ꜹ'",
        "'ꜹ'", "'ꜻ'", "'ꜻ'", "'ꜽ'", "'ꜽ'", "'ꜿ'", "'ꜿ'", "'ꝁ'", "'ꝁ'",
        "'ꝃ'", "'ꝃ'", "'ꝅ'", "'ꝅ'", "'ꝇ'", "'ꝇ'", "'ꝉ'", "'ꝉ'", "'ꝋ'",
        "'ꝋ'", "'ꝍ'", "'ꝍ'", "'ꝏ'", "'ꝏ'", "'ꝑ'", "'ꝑ'", "'ꝓ'", "'ꝓ'",
        "'ꝕ'", "'ꝕ'", "'ꝗ'", "'ꝗ'", "'ꝙ'", "'ꝙ'", "'ꝛ'", "'ꝛ'", "'ꝝ'",
        "'ꝝ'", "'ꝟ'", "'ꝟ'", "'ꝡ'", "'ꝡ'", "'ꝣ'", "'ꝣ'", "'ꝥ'", "'ꝥ'",
        "'ꝧ'", "'ꝧ'", "'ꝩ'", "'ꝩ'", "'ꝫ'", "'ꝫ'", "'ꝭ'", "'ꝭ'", "'ꝯ'",
        "'ꝯ'", "'ꝱ'", "'ꝸ'", "'ꝺ'", "'ꝺ'", "'ꝼ'", "'ꝼ'", "'ꝿ'", "'ꝿ'",
        "'ꞁ'", "'ꞁ'", "'ꞃ'", "'ꞃ'", "'ꞅ'", "'ꞅ'", "'ꞇ'", "'ꞇ'", "'ꞌ'",
        "'ꞌ'", "'ꞎ'", "'ꞎ'", "'ꞑ'", "'ꞑ'", "'ꞓ'", "'ꞕ'", "'ꞗ'", "'ꞗ'",
        "'ꞙ'", "'ꞙ'", "'ꞛ'", "'ꞛ'", "'ꞝ'", "'ꞝ'", "'ꞟ'", "'ꞟ'", "'ꞡ'",
        "'ꞡ'", "'ꞣ'", "'ꞣ'", "'ꞥ'", "'ꞥ'", "'ꞧ'", "'ꞧ'", "'ꞩ'", "'ꞩ'",
        "'ꞯ'", "'ꞯ'", "'ꞵ'", "'ꞵ'", "'ꞷ'", "'ꞷ'", "'ꞹ'", "'ꞹ'", "'ꞻ'",
        "'ꞻ'", "'ꞽ'", "'ꞽ'", "'ꞿ'", "'ꞿ'", "'ꟁ'", "'ꟁ'", "'ꟃ'", "'ꟃ'",
        "'ꟈ'", "'ꟈ'", "'ꟊ'", "'ꟊ'", "'ꟍ'", "'ꟍ'", "'ꟑ'", "'ꟑ'", "'ꟓ'",
        "'ꟓ'", "'ꟕ'", "'ꟕ'", "'ꟗ'", "'ꟗ'", "'ꟙ'", "'ꟙ'", "'ꟛ'", "'ꟛ'",
        "'ꟶ'", "'ꟶ'", "'ꟺ'", "'ꟺ'", "'ꬰ'", "'ꭚ'", "'ꭠ'", "'ꭨ'", "'ꭰ'",
        "'ꮿ'", "'ﬀ'", "'ﬆ'", "'ﬓ'", "'ﬗ'", "'ａ'", "'ｚ'", "'𐐨'",
        "'𐑏'", "'𐓘'", "'𐓻'", "'𐖗'", "'𐖡'", "'𐖣'", "'𐖱'", "'𐖳'",
        "'𐖹'", "'𐖻'", "'𐖼'", "'𐳀'", "'𐳲'", "'𐵰'", "'𐶅'", "'𑣀'",
        "'𑣟'", "'𖹠'", "'𖹿'", "'𝐚'", "'𝐳'", "'𝑎'", "'𝑔'", "'𝑖'",
        "'𝑧'", "'𝒂'", "'𝒛'", "'𝒶'", "'𝒹'", "'𝒻'", "'𝒻'", "'𝒽'",
        "'𝓃'", "'𝓅'", "'𝓏'", "'𝓪'", "'𝔃'", "'𝔞'", "'𝔷'", "'𝕒'",
        "'𝕫'", "'𝖆'", "'𝖟'", "'𝖺'", "'𝗓'", "'𝗮'", "'𝘇'", "'𝘢'",
        "'𝘻'", "'𝙖'", "'𝙯'", "'𝚊'", "'𝚥'", "'𝛂'", "'𝛚'", "'𝛜'",
        "'𝛡'", "'𝛼'", "'𝜔'", "'𝜖'", "'𝜛'", "'𝜶'", "'𝝎'", "'𝝐'",
        "'𝝕'", "'𝝰'", "'𝞈'", "'𝞊'", "'𝞏'", "'𝞪'", "'𝟂'", "'𝟄'",
        "'𝟉'", "'𝟋'", "'𝟋'", "'𝼀'", "'𝼉'", "'𝼋'", "'𝼞'", "'𝼥'",
        "'𝼪'", "'𞤢'", "'𞥃'",
      ],
    ],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })

  // Test matching a composed class
  @json.inspect(parse("\\p{L}"), content={
    "ast": [
      "CharClass neg=false",
      [
        "'A'", "'Z'", "'a'", "'z'", "'ª'", "'ª'", "'µ'", "'µ'", "'º'", "'º'",
        "'À'", "'Ö'", "'Ø'", "'ö'", "'ø'", "'ˁ'", "'ˆ'", "'ˑ'", "'ˠ'", "'ˤ'",
        "'ˬ'", "'ˬ'", "'ˮ'", "'ˮ'", "'Ͱ'", "'ʹ'", "'Ͷ'", "'ͷ'", "'ͺ'", "'ͽ'",
        "'Ϳ'", "'Ϳ'", "'Ά'", "'Ά'", "'Έ'", "'Ί'", "'Ό'", "'Ό'", "'Ύ'", "'Ρ'",
        "'Σ'", "'ϵ'", "'Ϸ'", "'ҁ'", "'Ҋ'", "'ԯ'", "'Ա'", "'Ֆ'", "'ՙ'", "'ՙ'",
        "'ՠ'", "'ֈ'", "'א'", "'ת'", "'ׯ'", "'ײ'", "'ؠ'", "'ي'", "'ٮ'", "'ٯ'",
        "'ٱ'", "'ۓ'", "'ە'", "'ە'", "'ۥ'", "'ۦ'", "'ۮ'", "'ۯ'", "'ۺ'", "'ۼ'",
        "'ۿ'", "'ۿ'", "'ܐ'", "'ܐ'", "'ܒ'", "'ܯ'", "'ݍ'", "'ޥ'", "'ޱ'", "'ޱ'",
        "'ߊ'", "'ߪ'", "'ߴ'", "'ߵ'", "'ߺ'", "'ߺ'", "'ࠀ'", "'ࠕ'", "'ࠚ'",
        "'ࠚ'", "'ࠤ'", "'ࠤ'", "'ࠨ'", "'ࠨ'", "'ࡀ'", "'ࡘ'", "'ࡠ'", "'ࡪ'",
        "'ࡰ'", "'ࢇ'", "'ࢉ'", "'ࢎ'", "'ࢠ'", "'ࣉ'", "'ऄ'", "'ह'", "'ऽ'",
        "'ऽ'", "'ॐ'", "'ॐ'", "'क़'", "'ॡ'", "'ॱ'", "'ঀ'", "'অ'", "'ঌ'",
        "'এ'", "'ঐ'", "'ও'", "'ন'", "'প'", "'র'", "'ল'", "'ল'", "'শ'",
        "'হ'", "'ঽ'", "'ঽ'", "'ৎ'", "'ৎ'", "'ড়'", "'ঢ়'", "'য়'", "'ৡ'",
        "'ৰ'", "'ৱ'", "'ৼ'", "'ৼ'", "'ਅ'", "'ਊ'", "'ਏ'", "'ਐ'", "'ਓ'",
        "'ਨ'", "'ਪ'", "'ਰ'", "'ਲ'", "'ਲ਼'", "'ਵ'", "'ਸ਼'", "'ਸ'", "'ਹ'",
        "'ਖ਼'", "'ੜ'", "'ਫ਼'", "'ਫ਼'", "'ੲ'", "'ੴ'", "'અ'", "'ઍ'", "'એ'",
        "'ઑ'", "'ઓ'", "'ન'", "'પ'", "'ર'", "'લ'", "'ળ'", "'વ'", "'હ'",
        "'ઽ'", "'ઽ'", "'ૐ'", "'ૐ'", "'ૠ'", "'ૡ'", "'ૹ'", "'ૹ'", "'ଅ'",
        "'ଌ'", "'ଏ'", "'ଐ'", "'ଓ'", "'ନ'", "'ପ'", "'ର'", "'ଲ'", "'ଳ'",
        "'ଵ'", "'ହ'", "'ଽ'", "'ଽ'", "'ଡ଼'", "'ଢ଼'", "'ୟ'", "'ୡ'", "'ୱ'",
        "'ୱ'", "'ஃ'", "'ஃ'", "'அ'", "'ஊ'", "'எ'", "'ஐ'", "'ஒ'", "'க'",
        "'ங'", "'ச'", "'ஜ'", "'ஜ'", "'ஞ'", "'ட'", "'ண'", "'த'", "'ந'",
        "'ப'", "'ம'", "'ஹ'", "'ௐ'", "'ௐ'", "'అ'", "'ఌ'", "'ఎ'", "'ఐ'",
        "'ఒ'", "'న'", "'ప'", "'హ'", "'ఽ'", "'ఽ'", "'ౘ'", "'ౚ'", "'ౝ'",
        "'ౝ'", "'ౠ'", "'ౡ'", "'ಀ'", "'ಀ'", "'ಅ'", "'ಌ'", "'ಎ'", "'ಐ'",
        "'ಒ'", "'ನ'", "'ಪ'", "'ಳ'", "'ವ'", "'ಹ'", "'ಽ'", "'ಽ'", "'ೝ'",
        "'ೞ'", "'ೠ'", "'ೡ'", "'ೱ'", "'ೲ'", "'ഄ'", "'ഌ'", "'എ'", "'ഐ'",
        "'ഒ'", "'ഺ'", "'ഽ'", "'ഽ'", "'ൎ'", "'ൎ'", "'ൔ'", "'ൖ'", "'ൟ'",
        "'ൡ'", "'ൺ'", "'ൿ'", "'අ'", "'ඖ'", "'ක'", "'න'", "'ඳ'", "'ර'",
        "'ල'", "'ල'", "'ව'", "'ෆ'", "'ก'", "'ะ'", "'า'", "'ำ'", "'เ'",
        "'ๆ'", "'ກ'", "'ຂ'", "'ຄ'", "'ຄ'", "'ຆ'", "'ຊ'", "'ຌ'", "'ຣ'",
        "'ລ'", "'ລ'", "'ວ'", "'ະ'", "'າ'", "'ຳ'", "'ຽ'", "'ຽ'", "'ເ'",
        "'ໄ'", "'ໆ'", "'ໆ'", "'ໜ'", "'ໟ'", "'ༀ'", "'ༀ'", "'ཀ'", "'ཇ'",
        "'ཉ'", "'ཬ'", "'ྈ'", "'ྌ'", "'က'", "'ဪ'", "'ဿ'", "'ဿ'", "'ၐ'",
        "'ၕ'", "'ၚ'", "'ၝ'", "'ၡ'", "'ၡ'", "'ၥ'", "'ၦ'", "'ၮ'", "'ၰ'",
        "'ၵ'", "'ႁ'", "'ႎ'", "'ႎ'", "'Ⴀ'", "'Ⴥ'", "'Ⴧ'", "'Ⴧ'", "'Ⴭ'",
        "'Ⴭ'", "'ა'", "'ჺ'", "'ჼ'", "'ቈ'", "'ቊ'", "'ቍ'", "'ቐ'", "'ቖ'",
        "'ቘ'", "'ቘ'", "'ቚ'", "'ቝ'", "'በ'", "'ኈ'", "'ኊ'", "'ኍ'", "'ነ'",
        "'ኰ'", "'ኲ'", "'ኵ'", "'ኸ'", "'ኾ'", "'ዀ'", "'ዀ'", "'ዂ'", "'ዅ'",
        "'ወ'", "'ዖ'", "'ዘ'", "'ጐ'", "'ጒ'", "'ጕ'", "'ጘ'", "'ፚ'", "'ᎀ'",
        "'ᎏ'", "'Ꭰ'", "'Ᏽ'", "'ᏸ'", "'ᏽ'", "'ᐁ'", "'ᙬ'", "'ᙯ'", "'ᙿ'",
        "'ᚁ'", "'ᚚ'", "'ᚠ'", "'ᛪ'", "'ᛱ'", "'ᛸ'", "'ᜀ'", "'ᜑ'", "'ᜟ'",
        "'ᜱ'", "'ᝀ'", "'ᝑ'", "'ᝠ'", "'ᝬ'", "'ᝮ'", "'ᝰ'", "'ក'", "'ឳ'",
        "'ៗ'", "'ៗ'", "'ៜ'", "'ៜ'", "'ᠠ'", "'ᡸ'", "'ᢀ'", "'ᢄ'", "'ᢇ'",
        "'ᢨ'", "'ᢪ'", "'ᢪ'", "'ᢰ'", "'ᣵ'", "'ᤀ'", "'ᤞ'", "'ᥐ'", "'ᥭ'",
        "'ᥰ'", "'ᥴ'", "'ᦀ'", "'ᦫ'", "'ᦰ'", "'ᧉ'", "'ᨀ'", "'ᨖ'", "'ᨠ'",
        "'ᩔ'", "'ᪧ'", "'ᪧ'", "'ᬅ'", "'ᬳ'", "'ᭅ'", "'ᭌ'", "'ᮃ'", "'ᮠ'",
        "'ᮮ'", "'ᮯ'", "'ᮺ'", "'ᯥ'", "'ᰀ'", "'ᰣ'", "'ᱍ'", "'ᱏ'", "'ᱚ'",
        "'ᱽ'", "'ᲀ'", "'ᲊ'", "'Ა'", "'Ჺ'", "'Ჽ'", "'Ჿ'", "'ᳩ'", "'ᳬ'",
        "'ᳮ'", "'ᳳ'", "'ᳵ'", "'ᳶ'", "'ᳺ'", "'ᳺ'", "'ᴀ'", "'ᶿ'", "'Ḁ'",
        "'ἕ'", "'Ἐ'", "'Ἕ'", "'ἠ'", "'ὅ'", "'Ὀ'", "'Ὅ'", "'ὐ'", "'ὗ'",
        "'Ὑ'", "'Ὑ'", "'Ὓ'", "'Ὓ'", "'Ὕ'", "'Ὕ'", "'Ὗ'", "'ώ'", "'ᾀ'",
        "'ᾴ'", "'ᾶ'", "'ᾼ'", "'ι'", "'ι'", "'ῂ'", "'ῄ'", "'ῆ'", "'ῌ'",
        "'ῐ'", "'ΐ'", "'ῖ'", "'Ί'", "'ῠ'", "'Ῥ'", "'ῲ'", "'ῴ'", "'ῶ'",
        "'ῼ'", "'ⁱ'", "'ⁱ'", "'ⁿ'", "'ⁿ'", "'ₐ'", "'ₜ'", "'ℂ'", "'ℂ'",
        "'ℇ'", "'ℇ'", "'ℊ'", "'ℓ'", "'ℕ'", "'ℕ'", "'ℙ'", "'ℝ'", "'ℤ'",
        "'ℤ'", "'Ω'", "'Ω'", "'ℨ'", "'ℨ'", "'K'", "'ℭ'", "'ℯ'", "'ℹ'",
        "'ℼ'", "'ℿ'", "'ⅅ'", "'ⅉ'", "'ⅎ'", "'ⅎ'", "'Ↄ'", "'ↄ'", "'Ⰰ'",
        "'ⳤ'", "'Ⳬ'", "'ⳮ'", "'Ⳳ'", "'ⳳ'", "'ⴀ'", "'ⴥ'", "'ⴧ'", "'ⴧ'",
        "'ⴭ'", "'ⴭ'", "'ⴰ'", "'ⵧ'", "'ⵯ'", "'ⵯ'", "'ⶀ'", "'ⶖ'", "'ⶠ'",
        "'ⶦ'", "'ⶨ'", "'ⶮ'", "'ⶰ'", "'ⶶ'", "'ⶸ'", "'ⶾ'", "'ⷀ'", "'ⷆ'",
        "'ⷈ'", "'ⷎ'", "'ⷐ'", "'ⷖ'", "'ⷘ'", "'ⷞ'", "'ⸯ'", "'ⸯ'", "'々'",
        "'〆'", "'〱'", "'〵'", "'〻'", "'〼'", "'ぁ'", "'ゖ'", "'ゝ'", "'ゟ'",
        "'ァ'", "'ヺ'", "'ー'", "'ヿ'", "'ㄅ'", "'ㄯ'", "'ㄱ'", "'ㆎ'", "'ㆠ'",
        "'ㆿ'", "'ㇰ'", "'ㇿ'", "'㐀'", "'䶿'", "'一'", "'ꒌ'", "'ꓐ'", "'ꓽ'",
        "'ꔀ'", "'ꘌ'", "'ꘐ'", "'ꘟ'", "'ꘪ'", "'ꘫ'", "'Ꙁ'", "'ꙮ'", "'ꙿ'",
        "'ꚝ'", "'ꚠ'", "'ꛥ'", "'ꜗ'", "'ꜟ'", "'Ꜣ'", "'ꞈ'", "'Ꞌ'", "'ꟍ'",
        "'Ꟑ'", "'ꟑ'", "'ꟓ'", "'ꟓ'", "'ꟕ'", "'Ƛ'", "'ꟲ'", "'ꠁ'", "'ꠃ'",
        "'ꠅ'", "'ꠇ'", "'ꠊ'", "'ꠌ'", "'ꠢ'", "'ꡀ'", "'ꡳ'", "'ꢂ'", "'ꢳ'",
        "'ꣲ'", "'ꣷ'", "'ꣻ'", "'ꣻ'", "'ꣽ'", "'ꣾ'", "'ꤊ'", "'ꤥ'", "'ꤰ'",
        "'ꥆ'", "'ꥠ'", "'ꥼ'", "'ꦄ'", "'ꦲ'", "'ꧏ'", "'ꧏ'", "'ꧠ'", "'ꧤ'",
        "'ꧦ'", "'ꧯ'", "'ꧺ'", "'ꧾ'", "'ꨀ'", "'ꨨ'", "'ꩀ'", "'ꩂ'", "'ꩄ'",
        "'ꩋ'", "'ꩠ'", "'ꩶ'", "'ꩺ'", "'ꩺ'", "'ꩾ'", "'ꪯ'", "'ꪱ'", "'ꪱ'",
        "'ꪵ'", "'ꪶ'", "'ꪹ'", "'ꪽ'", "'ꫀ'", "'ꫀ'", "'ꫂ'", "'ꫂ'", "'ꫛ'",
        "'ꫝ'", "'ꫠ'", "'ꫪ'", "'ꫲ'", "'ꫴ'", "'ꬁ'", "'ꬆ'", "'ꬉ'", "'ꬎ'",
        "'ꬑ'", "'ꬖ'", "'ꬠ'", "'ꬦ'", "'ꬨ'", "'ꬮ'", "'ꬰ'", "'ꭚ'", "'ꭜ'",
        "'ꭩ'", "'ꭰ'", "'ꯢ'", "'가'", "'힣'", "'ힰ'", "'ퟆ'", "'ퟋ'", "'ퟻ'",
        "'豈'", "'舘'", "'並'", "'龎'", "'ﬀ'", "'ﬆ'", "'ﬓ'", "'ﬗ'", "'יִ'",
        "'יִ'", "'ײַ'", "'ﬨ'", "'שׁ'", "'זּ'", "'טּ'", "'לּ'", "'מּ'", "'מּ'",
        "'נּ'", "'סּ'", "'ףּ'", "'פּ'", "'צּ'", "'ﮱ'", "'ﯓ'", "'ﴽ'", "'ﵐ'",
        "'ﶏ'", "'ﶒ'", "'ﷇ'", "'ﷰ'", "'ﷻ'", "'ﹰ'", "'ﹴ'", "'ﹶ'", "'ﻼ'",
        "'Ａ'", "'Ｚ'", "'ａ'", "'ｚ'", "'ｦ'", "'ﾾ'", "'ￂ'", "'ￇ'", "'ￊ'",
        "'ￏ'", "'ￒ'", "'ￗ'", "'ￚ'", "'ￜ'", "'𐀀'", "'𐀋'", "'𐀍'",
        "'𐀦'", "'𐀨'", "'𐀺'", "'𐀼'", "'𐀽'", "'𐀿'", "'𐁍'", "'𐁐'",
        "'𐁝'", "'𐂀'", "'𐃺'", "'𐊀'", "'𐊜'", "'𐊠'", "'𐋐'", "'𐌀'",
        "'𐌟'", "'𐌭'", "'𐍀'", "'𐍂'", "'𐍉'", "'𐍐'", "'𐍵'", "'𐎀'",
        "'𐎝'", "'𐎠'", "'𐏃'", "'𐏈'", "'𐏏'", "'𐐀'", "'𐒝'", "'𐒰'",
        "'𐓓'", "'𐓘'", "'𐓻'", "'𐔀'", "'𐔧'", "'𐔰'", "'𐕣'", "'𐕰'",
        "'𐕺'", "'𐕼'", "'𐖊'", "'𐖌'", "'𐖒'", "'𐖔'", "'𐖕'", "'𐖗'",
        "'𐖡'", "'𐖣'", "'𐖱'", "'𐖳'", "'𐖹'", "'𐖻'", "'𐖼'", "'𐗀'",
        "'𐗳'", "'𐘀'", "'𐜶'", "'𐝀'", "'𐝕'", "'𐝠'", "'𐝧'", "'𐞀'",
        "'𐞅'", "'𐞇'", "'𐞰'", "'𐞲'", "'𐞺'", "'𐠀'", "'𐠅'", "'𐠈'",
        "'𐠈'", "'𐠊'", "'𐠵'", "'𐠷'", "'𐠸'", "'𐠼'", "'𐠼'", "'𐠿'",
        "'𐡕'", "'𐡠'", "'𐡶'", "'𐢀'", "'𐢞'", "'𐣠'", "'𐣲'", "'𐣴'",
        "'𐣵'", "'𐤀'", "'𐤕'", "'𐤠'", "'𐤹'", "'𐦀'", "'𐦷'", "'𐦾'",
        "'𐦿'", "'𐨀'", "'𐨀'", "'𐨐'", "'𐨓'", "'𐨕'", "'𐨗'", "'𐨙'",
        "'𐨵'", "'𐩠'", "'𐩼'", "'𐪀'", "'𐪜'", "'𐫀'", "'𐫇'", "'𐫉'",
        "'𐫤'", "'𐬀'", "'𐬵'", "'𐭀'", "'𐭕'", "'𐭠'", "'𐭲'", "'𐮀'",
        "'𐮑'", "'𐰀'", "'𐱈'", "'𐲀'", "'𐲲'", "'𐳀'", "'𐳲'", "'𐴀'",
        "'𐴣'", "'𐵊'", "'𐵥'", "'𐵯'", "'𐶅'", "'𐺀'", "'𐺩'", "'𐺰'",
        "'𐺱'", "'𐻂'", "'𐻄'", "'𐼀'", "'𐼜'", "'𐼧'", "'𐼧'", "'𐼰'",
        "'𐽅'", "'𐽰'", "'𐾁'", "'𐾰'", "'𐿄'", "'𐿠'", "'𐿶'", "'𑀃'",
        "'𑀷'", "'𑁱'", "'𑁲'", "'𑁵'", "'𑁵'", "'𑂃'", "'𑂯'", "'𑃐'",
        "'𑃨'", "'𑄃'", "'𑄦'", "'𑅄'", "'𑅄'", "'𑅇'", "'𑅇'", "'𑅐'",
        "'𑅲'", "'𑅶'", "'𑅶'", "'𑆃'", "'𑆲'", "'𑇁'", "'𑇄'", "'𑇚'",
        "'𑇚'", "'𑇜'", "'𑇜'", "'𑈀'", "'𑈑'", "'𑈓'", "'𑈫'", "'𑈿'",
        "'𑉀'", "'𑊀'", "'𑊆'", "'𑊈'", "'𑊈'", "'𑊊'", "'𑊍'", "'𑊏'",
        "'𑊝'", "'𑊟'", "'𑊨'", "'𑊰'", "'𑋞'", "'𑌅'", "'𑌌'", "'𑌏'",
        "'𑌐'", "'𑌓'", "'𑌨'", "'𑌪'", "'𑌰'", "'𑌲'", "'𑌳'", "'𑌵'",
        "'𑌹'", "'𑌽'", "'𑌽'", "'𑍐'", "'𑍐'", "'𑍝'", "'𑍡'", "'𑎀'",
        "'𑎉'", "'𑎋'", "'𑎋'", "'𑎎'", "'𑎎'", "'𑎐'", "'𑎵'", "'𑎷'",
        "'𑎷'", "'𑏑'", "'𑏑'", "'𑏓'", "'𑏓'", "'𑐀'", "'𑐴'", "'𑑇'",
        "'𑑊'", "'𑑟'", "'𑑡'", "'𑒀'", "'𑒯'", "'𑓄'", "'𑓅'", "'𑓇'",
        "'𑓇'", "'𑖀'", "'𑖮'", "'𑗘'", "'𑗛'", "'𑘀'", "'𑘯'", "'𑙄'",
        "'𑙄'", "'𑚀'", "'𑚪'", "'𑚸'", "'𑚸'", "'𑜀'", "'𑜚'", "'𑝀'",
        "'𑝆'", "'𑠀'", "'𑠫'", "'𑢠'", "'𑣟'", "'𑣿'", "'𑤆'", "'𑤉'",
        "'𑤉'", "'𑤌'", "'𑤓'", "'𑤕'", "'𑤖'", "'𑤘'", "'𑤯'", "'𑤿'",
        "'𑤿'", "'𑥁'", "'𑥁'", "'𑦠'", "'𑦧'", "'𑦪'", "'𑧐'", "'𑧡'",
        "'𑧡'", "'𑧣'", "'𑧣'", "'𑨀'", "'𑨀'", "'𑨋'", "'𑨲'", "'𑨺'",
        "'𑨺'", "'𑩐'", "'𑩐'", "'𑩜'", "'𑪉'", "'𑪝'", "'𑪝'", "'𑪰'",
        "'𑫸'", "'𑯀'", "'𑯠'", "'𑰀'", "'𑰈'", "'𑰊'", "'𑰮'", "'𑱀'",
        "'𑱀'", "'𑱲'", "'𑲏'", "'𑴀'", "'𑴆'", "'𑴈'", "'𑴉'", "'𑴋'",
        "'𑴰'", "'𑵆'", "'𑵆'", "'𑵠'", "'𑵥'", "'𑵧'", "'𑵨'", "'𑵪'",
        "'𑶉'", "'𑶘'", "'𑶘'", "'𑻠'", "'𑻲'", "'𑼂'", "'𑼂'", "'𑼄'",
        "'𑼐'", "'𑼒'", "'𑼳'", "'𑾰'", "'𑾰'", "'𒀀'", "'𒎙'", "'𒒀'",
        "'𒕃'", "'𒾐'", "'𒿰'", "'𓀀'", "'𓐯'", "'𓑁'", "'𓑆'", "'𓑠'",
        "'𔏺'", "'𔐀'", "'𔙆'", "'𖄀'", "'𖄝'", "'𖠀'", "'𖨸'", "'𖩀'",
        "'𖩞'", "'𖩰'", "'𖪾'", "'𖫐'", "'𖫭'", "'𖬀'", "'𖬯'", "'𖭀'",
        "'𖭃'", "'𖭣'", "'𖭷'", "'𖭽'", "'𖮏'", "'𖵀'", "'𖵬'", "'𖹀'",
        "'𖹿'", "'𖼀'", "'𖽊'", "'𖽐'", "'𖽐'", "'𖾓'", "'𖾟'", "'𖿠'",
        "'𖿡'", "'𖿣'", "'𖿣'", "'𗀀'", "'𘟷'", "'𘠀'", "'𘳕'", "'𘳿'",
        "'𘴈'", "'𚿰'", "'𚿳'", "'𚿵'", "'𚿻'", "'𚿽'", "'𚿾'", "'𛀀'",
        "'𛄢'", "'𛄲'", "'𛄲'", "'𛅐'", "'𛅒'", "'𛅕'", "'𛅕'", "'𛅤'",
        "'𛅧'", "'𛅰'", "'𛋻'", "'𛰀'", "'𛱪'", "'𛱰'", "'𛱼'", "'𛲀'",
        "'𛲈'", "'𛲐'", "'𛲙'", "'𝐀'", "'𝑔'", "'𝑖'", "'𝒜'", "'𝒞'",
        "'𝒟'", "'𝒢'", "'𝒢'", "'𝒥'", "'𝒦'", "'𝒩'", "'𝒬'", "'𝒮'",
        "'𝒹'", "'𝒻'", "'𝒻'", "'𝒽'", "'𝓃'", "'𝓅'", "'𝔅'", "'𝔇'",
        "'𝔊'", "'𝔍'", "'𝔔'", "'𝔖'", "'𝔜'", "'𝔞'", "'𝔹'", "'𝔻'",
        "'𝔾'", "'𝕀'", "'𝕄'", "'𝕆'", "'𝕆'", "'𝕊'", "'𝕐'", "'𝕒'",
        "'𝚥'", "'𝚨'", "'𝛀'", "'𝛂'", "'𝛚'", "'𝛜'", "'𝛺'", "'𝛼'",
        "'𝜔'", "'𝜖'", "'𝜴'", "'𝜶'", "'𝝎'", "'𝝐'", "'𝝮'", "'𝝰'",
        "'𝞈'", "'𝞊'", "'𝞨'", "'𝞪'", "'𝟂'", "'𝟄'", "'𝟋'", "'𝼀'",
        "'𝼞'", "'𝼥'", "'𝼪'", "'𞀰'", "'𞁭'", "'𞄀'", "'𞄬'", "'𞄷'",
        "'𞄽'", "'𞅎'", "'𞅎'", "'𞊐'", "'𞊭'", "'𞋀'", "'𞋫'", "'𞓐'",
        "'𞓫'", "'𞗐'", "'𞗭'", "'𞗰'", "'𞗰'", "'𞟠'", "'𞟦'", "'𞟨'",
        "'𞟫'", "'𞟭'", "'𞟮'", "'𞟰'", "'𞟾'", "'𞠀'", "'𞣄'", "'𞤀'",
        "'𞥃'", "'𞥋'", "'𞥋'", "'𞸀'", "'𞸃'", "'𞸅'", "'𞸟'", "'𞸡'",
        "'𞸢'", "'𞸤'", "'𞸤'", "'𞸧'", "'𞸧'", "'𞸩'", "'𞸲'", "'𞸴'",
        "'𞸷'", "'𞸹'", "'𞸹'", "'𞸻'", "'𞸻'", "'𞹂'", "'𞹂'", "'𞹇'",
        "'𞹇'", "'𞹉'", "'𞹉'", "'𞹋'", "'𞹋'", "'𞹍'", "'𞹏'", "'𞹑'",
        "'𞹒'", "'𞹔'", "'𞹔'", "'𞹗'", "'𞹗'", "'𞹙'", "'𞹙'", "'𞹛'",
        "'𞹛'", "'𞹝'", "'𞹝'", "'𞹟'", "'𞹟'", "'𞹡'", "'𞹢'", "'𞹤'",
        "'𞹤'", "'𞹧'", "'𞹪'", "'𞹬'", "'𞹲'", "'𞹴'", "'𞹷'", "'𞹹'",
        "'𞹼'", "'𞹾'", "'𞹾'", "'𞺀'", "'𞺉'", "'𞺋'", "'𞺛'", "'𞺡'",
        "'𞺣'", "'𞺥'", "'𞺩'", "'𞺫'", "'𞺻'", "'𠀀'", "'𪛟'", "'𪜀'",
        "'𫜹'", "'𫝀'", "'𫠝'", "'𫠠'", "'𬺡'", "'𬺰'", "'𮯠'", "'𮯰'",
        "'𮹝'", "'丽'", "'𪘀'", "'𰀀'", "'𱍊'", "'𱍐'", "'𲎯'",
      ],
    ],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })

  // Negated matching
  @json.inspect(parse("\\P{L}"), content={
    "ast": [
      "CharClass neg=true",
      [
        "'A'", "'Z'", "'a'", "'z'", "'ª'", "'ª'", "'µ'", "'µ'", "'º'", "'º'",
        "'À'", "'Ö'", "'Ø'", "'ö'", "'ø'", "'ˁ'", "'ˆ'", "'ˑ'", "'ˠ'", "'ˤ'",
        "'ˬ'", "'ˬ'", "'ˮ'", "'ˮ'", "'Ͱ'", "'ʹ'", "'Ͷ'", "'ͷ'", "'ͺ'", "'ͽ'",
        "'Ϳ'", "'Ϳ'", "'Ά'", "'Ά'", "'Έ'", "'Ί'", "'Ό'", "'Ό'", "'Ύ'", "'Ρ'",
        "'Σ'", "'ϵ'", "'Ϸ'", "'ҁ'", "'Ҋ'", "'ԯ'", "'Ա'", "'Ֆ'", "'ՙ'", "'ՙ'",
        "'ՠ'", "'ֈ'", "'א'", "'ת'", "'ׯ'", "'ײ'", "'ؠ'", "'ي'", "'ٮ'", "'ٯ'",
        "'ٱ'", "'ۓ'", "'ە'", "'ە'", "'ۥ'", "'ۦ'", "'ۮ'", "'ۯ'", "'ۺ'", "'ۼ'",
        "'ۿ'", "'ۿ'", "'ܐ'", "'ܐ'", "'ܒ'", "'ܯ'", "'ݍ'", "'ޥ'", "'ޱ'", "'ޱ'",
        "'ߊ'", "'ߪ'", "'ߴ'", "'ߵ'", "'ߺ'", "'ߺ'", "'ࠀ'", "'ࠕ'", "'ࠚ'",
        "'ࠚ'", "'ࠤ'", "'ࠤ'", "'ࠨ'", "'ࠨ'", "'ࡀ'", "'ࡘ'", "'ࡠ'", "'ࡪ'",
        "'ࡰ'", "'ࢇ'", "'ࢉ'", "'ࢎ'", "'ࢠ'", "'ࣉ'", "'ऄ'", "'ह'", "'ऽ'",
        "'ऽ'", "'ॐ'", "'ॐ'", "'क़'", "'ॡ'", "'ॱ'", "'ঀ'", "'অ'", "'ঌ'",
        "'এ'", "'ঐ'", "'ও'", "'ন'", "'প'", "'র'", "'ল'", "'ল'", "'শ'",
        "'হ'", "'ঽ'", "'ঽ'", "'ৎ'", "'ৎ'", "'ড়'", "'ঢ়'", "'য়'", "'ৡ'",
        "'ৰ'", "'ৱ'", "'ৼ'", "'ৼ'", "'ਅ'", "'ਊ'", "'ਏ'", "'ਐ'", "'ਓ'",
        "'ਨ'", "'ਪ'", "'ਰ'", "'ਲ'", "'ਲ਼'", "'ਵ'", "'ਸ਼'", "'ਸ'", "'ਹ'",
        "'ਖ਼'", "'ੜ'", "'ਫ਼'", "'ਫ਼'", "'ੲ'", "'ੴ'", "'અ'", "'ઍ'", "'એ'",
        "'ઑ'", "'ઓ'", "'ન'", "'પ'", "'ર'", "'લ'", "'ળ'", "'વ'", "'હ'",
        "'ઽ'", "'ઽ'", "'ૐ'", "'ૐ'", "'ૠ'", "'ૡ'", "'ૹ'", "'ૹ'", "'ଅ'",
        "'ଌ'", "'ଏ'", "'ଐ'", "'ଓ'", "'ନ'", "'ପ'", "'ର'", "'ଲ'", "'ଳ'",
        "'ଵ'", "'ହ'", "'ଽ'", "'ଽ'", "'ଡ଼'", "'ଢ଼'", "'ୟ'", "'ୡ'", "'ୱ'",
        "'ୱ'", "'ஃ'", "'ஃ'", "'அ'", "'ஊ'", "'எ'", "'ஐ'", "'ஒ'", "'க'",
        "'ங'", "'ச'", "'ஜ'", "'ஜ'", "'ஞ'", "'ட'", "'ண'", "'த'", "'ந'",
        "'ப'", "'ம'", "'ஹ'", "'ௐ'", "'ௐ'", "'అ'", "'ఌ'", "'ఎ'", "'ఐ'",
        "'ఒ'", "'న'", "'ప'", "'హ'", "'ఽ'", "'ఽ'", "'ౘ'", "'ౚ'", "'ౝ'",
        "'ౝ'", "'ౠ'", "'ౡ'", "'ಀ'", "'ಀ'", "'ಅ'", "'ಌ'", "'ಎ'", "'ಐ'",
        "'ಒ'", "'ನ'", "'ಪ'", "'ಳ'", "'ವ'", "'ಹ'", "'ಽ'", "'ಽ'", "'ೝ'",
        "'ೞ'", "'ೠ'", "'ೡ'", "'ೱ'", "'ೲ'", "'ഄ'", "'ഌ'", "'എ'", "'ഐ'",
        "'ഒ'", "'ഺ'", "'ഽ'", "'ഽ'", "'ൎ'", "'ൎ'", "'ൔ'", "'ൖ'", "'ൟ'",
        "'ൡ'", "'ൺ'", "'ൿ'", "'අ'", "'ඖ'", "'ක'", "'න'", "'ඳ'", "'ර'",
        "'ල'", "'ල'", "'ව'", "'ෆ'", "'ก'", "'ะ'", "'า'", "'ำ'", "'เ'",
        "'ๆ'", "'ກ'", "'ຂ'", "'ຄ'", "'ຄ'", "'ຆ'", "'ຊ'", "'ຌ'", "'ຣ'",
        "'ລ'", "'ລ'", "'ວ'", "'ະ'", "'າ'", "'ຳ'", "'ຽ'", "'ຽ'", "'ເ'",
        "'ໄ'", "'ໆ'", "'ໆ'", "'ໜ'", "'ໟ'", "'ༀ'", "'ༀ'", "'ཀ'", "'ཇ'",
        "'ཉ'", "'ཬ'", "'ྈ'", "'ྌ'", "'က'", "'ဪ'", "'ဿ'", "'ဿ'", "'ၐ'",
        "'ၕ'", "'ၚ'", "'ၝ'", "'ၡ'", "'ၡ'", "'ၥ'", "'ၦ'", "'ၮ'", "'ၰ'",
        "'ၵ'", "'ႁ'", "'ႎ'", "'ႎ'", "'Ⴀ'", "'Ⴥ'", "'Ⴧ'", "'Ⴧ'", "'Ⴭ'",
        "'Ⴭ'", "'ა'", "'ჺ'", "'ჼ'", "'ቈ'", "'ቊ'", "'ቍ'", "'ቐ'", "'ቖ'",
        "'ቘ'", "'ቘ'", "'ቚ'", "'ቝ'", "'በ'", "'ኈ'", "'ኊ'", "'ኍ'", "'ነ'",
        "'ኰ'", "'ኲ'", "'ኵ'", "'ኸ'", "'ኾ'", "'ዀ'", "'ዀ'", "'ዂ'", "'ዅ'",
        "'ወ'", "'ዖ'", "'ዘ'", "'ጐ'", "'ጒ'", "'ጕ'", "'ጘ'", "'ፚ'", "'ᎀ'",
        "'ᎏ'", "'Ꭰ'", "'Ᏽ'", "'ᏸ'", "'ᏽ'", "'ᐁ'", "'ᙬ'", "'ᙯ'", "'ᙿ'",
        "'ᚁ'", "'ᚚ'", "'ᚠ'", "'ᛪ'", "'ᛱ'", "'ᛸ'", "'ᜀ'", "'ᜑ'", "'ᜟ'",
        "'ᜱ'", "'ᝀ'", "'ᝑ'", "'ᝠ'", "'ᝬ'", "'ᝮ'", "'ᝰ'", "'ក'", "'ឳ'",
        "'ៗ'", "'ៗ'", "'ៜ'", "'ៜ'", "'ᠠ'", "'ᡸ'", "'ᢀ'", "'ᢄ'", "'ᢇ'",
        "'ᢨ'", "'ᢪ'", "'ᢪ'", "'ᢰ'", "'ᣵ'", "'ᤀ'", "'ᤞ'", "'ᥐ'", "'ᥭ'",
        "'ᥰ'", "'ᥴ'", "'ᦀ'", "'ᦫ'", "'ᦰ'", "'ᧉ'", "'ᨀ'", "'ᨖ'", "'ᨠ'",
        "'ᩔ'", "'ᪧ'", "'ᪧ'", "'ᬅ'", "'ᬳ'", "'ᭅ'", "'ᭌ'", "'ᮃ'", "'ᮠ'",
        "'ᮮ'", "'ᮯ'", "'ᮺ'", "'ᯥ'", "'ᰀ'", "'ᰣ'", "'ᱍ'", "'ᱏ'", "'ᱚ'",
        "'ᱽ'", "'ᲀ'", "'ᲊ'", "'Ა'", "'Ჺ'", "'Ჽ'", "'Ჿ'", "'ᳩ'", "'ᳬ'",
        "'ᳮ'", "'ᳳ'", "'ᳵ'", "'ᳶ'", "'ᳺ'", "'ᳺ'", "'ᴀ'", "'ᶿ'", "'Ḁ'",
        "'ἕ'", "'Ἐ'", "'Ἕ'", "'ἠ'", "'ὅ'", "'Ὀ'", "'Ὅ'", "'ὐ'", "'ὗ'",
        "'Ὑ'", "'Ὑ'", "'Ὓ'", "'Ὓ'", "'Ὕ'", "'Ὕ'", "'Ὗ'", "'ώ'", "'ᾀ'",
        "'ᾴ'", "'ᾶ'", "'ᾼ'", "'ι'", "'ι'", "'ῂ'", "'ῄ'", "'ῆ'", "'ῌ'",
        "'ῐ'", "'ΐ'", "'ῖ'", "'Ί'", "'ῠ'", "'Ῥ'", "'ῲ'", "'ῴ'", "'ῶ'",
        "'ῼ'", "'ⁱ'", "'ⁱ'", "'ⁿ'", "'ⁿ'", "'ₐ'", "'ₜ'", "'ℂ'", "'ℂ'",
        "'ℇ'", "'ℇ'", "'ℊ'", "'ℓ'", "'ℕ'", "'ℕ'", "'ℙ'", "'ℝ'", "'ℤ'",
        "'ℤ'", "'Ω'", "'Ω'", "'ℨ'", "'ℨ'", "'K'", "'ℭ'", "'ℯ'", "'ℹ'",
        "'ℼ'", "'ℿ'", "'ⅅ'", "'ⅉ'", "'ⅎ'", "'ⅎ'", "'Ↄ'", "'ↄ'", "'Ⰰ'",
        "'ⳤ'", "'Ⳬ'", "'ⳮ'", "'Ⳳ'", "'ⳳ'", "'ⴀ'", "'ⴥ'", "'ⴧ'", "'ⴧ'",
        "'ⴭ'", "'ⴭ'", "'ⴰ'", "'ⵧ'", "'ⵯ'", "'ⵯ'", "'ⶀ'", "'ⶖ'", "'ⶠ'",
        "'ⶦ'", "'ⶨ'", "'ⶮ'", "'ⶰ'", "'ⶶ'", "'ⶸ'", "'ⶾ'", "'ⷀ'", "'ⷆ'",
        "'ⷈ'", "'ⷎ'", "'ⷐ'", "'ⷖ'", "'ⷘ'", "'ⷞ'", "'ⸯ'", "'ⸯ'", "'々'",
        "'〆'", "'〱'", "'〵'", "'〻'", "'〼'", "'ぁ'", "'ゖ'", "'ゝ'", "'ゟ'",
        "'ァ'", "'ヺ'", "'ー'", "'ヿ'", "'ㄅ'", "'ㄯ'", "'ㄱ'", "'ㆎ'", "'ㆠ'",
        "'ㆿ'", "'ㇰ'", "'ㇿ'", "'㐀'", "'䶿'", "'一'", "'ꒌ'", "'ꓐ'", "'ꓽ'",
        "'ꔀ'", "'ꘌ'", "'ꘐ'", "'ꘟ'", "'ꘪ'", "'ꘫ'", "'Ꙁ'", "'ꙮ'", "'ꙿ'",
        "'ꚝ'", "'ꚠ'", "'ꛥ'", "'ꜗ'", "'ꜟ'", "'Ꜣ'", "'ꞈ'", "'Ꞌ'", "'ꟍ'",
        "'Ꟑ'", "'ꟑ'", "'ꟓ'", "'ꟓ'", "'ꟕ'", "'Ƛ'", "'ꟲ'", "'ꠁ'", "'ꠃ'",
        "'ꠅ'", "'ꠇ'", "'ꠊ'", "'ꠌ'", "'ꠢ'", "'ꡀ'", "'ꡳ'", "'ꢂ'", "'ꢳ'",
        "'ꣲ'", "'ꣷ'", "'ꣻ'", "'ꣻ'", "'ꣽ'", "'ꣾ'", "'ꤊ'", "'ꤥ'", "'ꤰ'",
        "'ꥆ'", "'ꥠ'", "'ꥼ'", "'ꦄ'", "'ꦲ'", "'ꧏ'", "'ꧏ'", "'ꧠ'", "'ꧤ'",
        "'ꧦ'", "'ꧯ'", "'ꧺ'", "'ꧾ'", "'ꨀ'", "'ꨨ'", "'ꩀ'", "'ꩂ'", "'ꩄ'",
        "'ꩋ'", "'ꩠ'", "'ꩶ'", "'ꩺ'", "'ꩺ'", "'ꩾ'", "'ꪯ'", "'ꪱ'", "'ꪱ'",
        "'ꪵ'", "'ꪶ'", "'ꪹ'", "'ꪽ'", "'ꫀ'", "'ꫀ'", "'ꫂ'", "'ꫂ'", "'ꫛ'",
        "'ꫝ'", "'ꫠ'", "'ꫪ'", "'ꫲ'", "'ꫴ'", "'ꬁ'", "'ꬆ'", "'ꬉ'", "'ꬎ'",
        "'ꬑ'", "'ꬖ'", "'ꬠ'", "'ꬦ'", "'ꬨ'", "'ꬮ'", "'ꬰ'", "'ꭚ'", "'ꭜ'",
        "'ꭩ'", "'ꭰ'", "'ꯢ'", "'가'", "'힣'", "'ힰ'", "'ퟆ'", "'ퟋ'", "'ퟻ'",
        "'豈'", "'舘'", "'並'", "'龎'", "'ﬀ'", "'ﬆ'", "'ﬓ'", "'ﬗ'", "'יִ'",
        "'יִ'", "'ײַ'", "'ﬨ'", "'שׁ'", "'זּ'", "'טּ'", "'לּ'", "'מּ'", "'מּ'",
        "'נּ'", "'סּ'", "'ףּ'", "'פּ'", "'צּ'", "'ﮱ'", "'ﯓ'", "'ﴽ'", "'ﵐ'",
        "'ﶏ'", "'ﶒ'", "'ﷇ'", "'ﷰ'", "'ﷻ'", "'ﹰ'", "'ﹴ'", "'ﹶ'", "'ﻼ'",
        "'Ａ'", "'Ｚ'", "'ａ'", "'ｚ'", "'ｦ'", "'ﾾ'", "'ￂ'", "'ￇ'", "'ￊ'",
        "'ￏ'", "'ￒ'", "'ￗ'", "'ￚ'", "'ￜ'", "'𐀀'", "'𐀋'", "'𐀍'",
        "'𐀦'", "'𐀨'", "'𐀺'", "'𐀼'", "'𐀽'", "'𐀿'", "'𐁍'", "'𐁐'",
        "'𐁝'", "'𐂀'", "'𐃺'", "'𐊀'", "'𐊜'", "'𐊠'", "'𐋐'", "'𐌀'",
        "'𐌟'", "'𐌭'", "'𐍀'", "'𐍂'", "'𐍉'", "'𐍐'", "'𐍵'", "'𐎀'",
        "'𐎝'", "'𐎠'", "'𐏃'", "'𐏈'", "'𐏏'", "'𐐀'", "'𐒝'", "'𐒰'",
        "'𐓓'", "'𐓘'", "'𐓻'", "'𐔀'", "'𐔧'", "'𐔰'", "'𐕣'", "'𐕰'",
        "'𐕺'", "'𐕼'", "'𐖊'", "'𐖌'", "'𐖒'", "'𐖔'", "'𐖕'", "'𐖗'",
        "'𐖡'", "'𐖣'", "'𐖱'", "'𐖳'", "'𐖹'", "'𐖻'", "'𐖼'", "'𐗀'",
        "'𐗳'", "'𐘀'", "'𐜶'", "'𐝀'", "'𐝕'", "'𐝠'", "'𐝧'", "'𐞀'",
        "'𐞅'", "'𐞇'", "'𐞰'", "'𐞲'", "'𐞺'", "'𐠀'", "'𐠅'", "'𐠈'",
        "'𐠈'", "'𐠊'", "'𐠵'", "'𐠷'", "'𐠸'", "'𐠼'", "'𐠼'", "'𐠿'",
        "'𐡕'", "'𐡠'", "'𐡶'", "'𐢀'", "'𐢞'", "'𐣠'", "'𐣲'", "'𐣴'",
        "'𐣵'", "'𐤀'", "'𐤕'", "'𐤠'", "'𐤹'", "'𐦀'", "'𐦷'", "'𐦾'",
        "'𐦿'", "'𐨀'", "'𐨀'", "'𐨐'", "'𐨓'", "'𐨕'", "'𐨗'", "'𐨙'",
        "'𐨵'", "'𐩠'", "'𐩼'", "'𐪀'", "'𐪜'", "'𐫀'", "'𐫇'", "'𐫉'",
        "'𐫤'", "'𐬀'", "'𐬵'", "'𐭀'", "'𐭕'", "'𐭠'", "'𐭲'", "'𐮀'",
        "'𐮑'", "'𐰀'", "'𐱈'", "'𐲀'", "'𐲲'", "'𐳀'", "'𐳲'", "'𐴀'",
        "'𐴣'", "'𐵊'", "'𐵥'", "'𐵯'", "'𐶅'", "'𐺀'", "'𐺩'", "'𐺰'",
        "'𐺱'", "'𐻂'", "'𐻄'", "'𐼀'", "'𐼜'", "'𐼧'", "'𐼧'", "'𐼰'",
        "'𐽅'", "'𐽰'", "'𐾁'", "'𐾰'", "'𐿄'", "'𐿠'", "'𐿶'", "'𑀃'",
        "'𑀷'", "'𑁱'", "'𑁲'", "'𑁵'", "'𑁵'", "'𑂃'", "'𑂯'", "'𑃐'",
        "'𑃨'", "'𑄃'", "'𑄦'", "'𑅄'", "'𑅄'", "'𑅇'", "'𑅇'", "'𑅐'",
        "'𑅲'", "'𑅶'", "'𑅶'", "'𑆃'", "'𑆲'", "'𑇁'", "'𑇄'", "'𑇚'",
        "'𑇚'", "'𑇜'", "'𑇜'", "'𑈀'", "'𑈑'", "'𑈓'", "'𑈫'", "'𑈿'",
        "'𑉀'", "'𑊀'", "'𑊆'", "'𑊈'", "'𑊈'", "'𑊊'", "'𑊍'", "'𑊏'",
        "'𑊝'", "'𑊟'", "'𑊨'", "'𑊰'", "'𑋞'", "'𑌅'", "'𑌌'", "'𑌏'",
        "'𑌐'", "'𑌓'", "'𑌨'", "'𑌪'", "'𑌰'", "'𑌲'", "'𑌳'", "'𑌵'",
        "'𑌹'", "'𑌽'", "'𑌽'", "'𑍐'", "'𑍐'", "'𑍝'", "'𑍡'", "'𑎀'",
        "'𑎉'", "'𑎋'", "'𑎋'", "'𑎎'", "'𑎎'", "'𑎐'", "'𑎵'", "'𑎷'",
        "'𑎷'", "'𑏑'", "'𑏑'", "'𑏓'", "'𑏓'", "'𑐀'", "'𑐴'", "'𑑇'",
        "'𑑊'", "'𑑟'", "'𑑡'", "'𑒀'", "'𑒯'", "'𑓄'", "'𑓅'", "'𑓇'",
        "'𑓇'", "'𑖀'", "'𑖮'", "'𑗘'", "'𑗛'", "'𑘀'", "'𑘯'", "'𑙄'",
        "'𑙄'", "'𑚀'", "'𑚪'", "'𑚸'", "'𑚸'", "'𑜀'", "'𑜚'", "'𑝀'",
        "'𑝆'", "'𑠀'", "'𑠫'", "'𑢠'", "'𑣟'", "'𑣿'", "'𑤆'", "'𑤉'",
        "'𑤉'", "'𑤌'", "'𑤓'", "'𑤕'", "'𑤖'", "'𑤘'", "'𑤯'", "'𑤿'",
        "'𑤿'", "'𑥁'", "'𑥁'", "'𑦠'", "'𑦧'", "'𑦪'", "'𑧐'", "'𑧡'",
        "'𑧡'", "'𑧣'", "'𑧣'", "'𑨀'", "'𑨀'", "'𑨋'", "'𑨲'", "'𑨺'",
        "'𑨺'", "'𑩐'", "'𑩐'", "'𑩜'", "'𑪉'", "'𑪝'", "'𑪝'", "'𑪰'",
        "'𑫸'", "'𑯀'", "'𑯠'", "'𑰀'", "'𑰈'", "'𑰊'", "'𑰮'", "'𑱀'",
        "'𑱀'", "'𑱲'", "'𑲏'", "'𑴀'", "'𑴆'", "'𑴈'", "'𑴉'", "'𑴋'",
        "'𑴰'", "'𑵆'", "'𑵆'", "'𑵠'", "'𑵥'", "'𑵧'", "'𑵨'", "'𑵪'",
        "'𑶉'", "'𑶘'", "'𑶘'", "'𑻠'", "'𑻲'", "'𑼂'", "'𑼂'", "'𑼄'",
        "'𑼐'", "'𑼒'", "'𑼳'", "'𑾰'", "'𑾰'", "'𒀀'", "'𒎙'", "'𒒀'",
        "'𒕃'", "'𒾐'", "'𒿰'", "'𓀀'", "'𓐯'", "'𓑁'", "'𓑆'", "'𓑠'",
        "'𔏺'", "'𔐀'", "'𔙆'", "'𖄀'", "'𖄝'", "'𖠀'", "'𖨸'", "'𖩀'",
        "'𖩞'", "'𖩰'", "'𖪾'", "'𖫐'", "'𖫭'", "'𖬀'", "'𖬯'", "'𖭀'",
        "'𖭃'", "'𖭣'", "'𖭷'", "'𖭽'", "'𖮏'", "'𖵀'", "'𖵬'", "'𖹀'",
        "'𖹿'", "'𖼀'", "'𖽊'", "'𖽐'", "'𖽐'", "'𖾓'", "'𖾟'", "'𖿠'",
        "'𖿡'", "'𖿣'", "'𖿣'", "'𗀀'", "'𘟷'", "'𘠀'", "'𘳕'", "'𘳿'",
        "'𘴈'", "'𚿰'", "'𚿳'", "'𚿵'", "'𚿻'", "'𚿽'", "'𚿾'", "'𛀀'",
        "'𛄢'", "'𛄲'", "'𛄲'", "'𛅐'", "'𛅒'", "'𛅕'", "'𛅕'", "'𛅤'",
        "'𛅧'", "'𛅰'", "'𛋻'", "'𛰀'", "'𛱪'", "'𛱰'", "'𛱼'", "'𛲀'",
        "'𛲈'", "'𛲐'", "'𛲙'", "'𝐀'", "'𝑔'", "'𝑖'", "'𝒜'", "'𝒞'",
        "'𝒟'", "'𝒢'", "'𝒢'", "'𝒥'", "'𝒦'", "'𝒩'", "'𝒬'", "'𝒮'",
        "'𝒹'", "'𝒻'", "'𝒻'", "'𝒽'", "'𝓃'", "'𝓅'", "'𝔅'", "'𝔇'",
        "'𝔊'", "'𝔍'", "'𝔔'", "'𝔖'", "'𝔜'", "'𝔞'", "'𝔹'", "'𝔻'",
        "'𝔾'", "'𝕀'", "'𝕄'", "'𝕆'", "'𝕆'", "'𝕊'", "'𝕐'", "'𝕒'",
        "'𝚥'", "'𝚨'", "'𝛀'", "'𝛂'", "'𝛚'", "'𝛜'", "'𝛺'", "'𝛼'",
        "'𝜔'", "'𝜖'", "'𝜴'", "'𝜶'", "'𝝎'", "'𝝐'", "'𝝮'", "'𝝰'",
        "'𝞈'", "'𝞊'", "'𝞨'", "'𝞪'", "'𝟂'", "'𝟄'", "'𝟋'", "'𝼀'",
        "'𝼞'", "'𝼥'", "'𝼪'", "'𞀰'", "'𞁭'", "'𞄀'", "'𞄬'", "'𞄷'",
        "'𞄽'", "'𞅎'", "'𞅎'", "'𞊐'", "'𞊭'", "'𞋀'", "'𞋫'", "'𞓐'",
        "'𞓫'", "'𞗐'", "'𞗭'", "'𞗰'", "'𞗰'", "'𞟠'", "'𞟦'", "'𞟨'",
        "'𞟫'", "'𞟭'", "'𞟮'", "'𞟰'", "'𞟾'", "'𞠀'", "'𞣄'", "'𞤀'",
        "'𞥃'", "'𞥋'", "'𞥋'", "'𞸀'", "'𞸃'", "'𞸅'", "'𞸟'", "'𞸡'",
        "'𞸢'", "'𞸤'", "'𞸤'", "'𞸧'", "'𞸧'", "'𞸩'", "'𞸲'", "'𞸴'",
        "'𞸷'", "'𞸹'", "'𞸹'", "'𞸻'", "'𞸻'", "'𞹂'", "'𞹂'", "'𞹇'",
        "'𞹇'", "'𞹉'", "'𞹉'", "'𞹋'", "'𞹋'", "'𞹍'", "'𞹏'", "'𞹑'",
        "'𞹒'", "'𞹔'", "'𞹔'", "'𞹗'", "'𞹗'", "'𞹙'", "'𞹙'", "'𞹛'",
        "'𞹛'", "'𞹝'", "'𞹝'", "'𞹟'", "'𞹟'", "'𞹡'", "'𞹢'", "'𞹤'",
        "'𞹤'", "'𞹧'", "'𞹪'", "'𞹬'", "'𞹲'", "'𞹴'", "'𞹷'", "'𞹹'",
        "'𞹼'", "'𞹾'", "'𞹾'", "'𞺀'", "'𞺉'", "'𞺋'", "'𞺛'", "'𞺡'",
        "'𞺣'", "'𞺥'", "'𞺩'", "'𞺫'", "'𞺻'", "'𠀀'", "'𪛟'", "'𪜀'",
        "'𫜹'", "'𫝀'", "'𫠝'", "'𫠠'", "'𬺡'", "'𬺰'", "'𮯠'", "'𮯰'",
        "'𮹝'", "'丽'", "'𪘀'", "'𰀀'", "'𱍊'", "'𱍐'", "'𲎯'",
      ],
    ],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse unmatched curly brace" {
  @json.inspect(parse("a|b}"), content={
    "ast": [
      "Alternate",
      ["CharClass neg=false", ["'a'", "'a'"]],
      [
        ["CharClass neg=false", ["'b'", "'b'"]],
        ["CharClass neg=false", ["'}'", "'}'"]],
      ],
    ],
    "captures": 1,
    "capture_map": {},
    "has_backreference": false,
  })
}

///|
test "parse backreference" {
  // Test with a valid backreference
  @json.inspect(parse("(a)(b)\\1"), content={
    "ast": [
      ["Capture 1", ["CharClass neg=false", ["'a'", "'a'"]]],
      ["Capture 2", ["CharClass neg=false", ["'b'", "'b'"]]],
      ["Backreference", 1],
    ],
    "captures": 3,
    "capture_map": {},
    "has_backreference": true,
  })

  // Test with an invalid backreference (no such group)
  let regex = try? parse("\\2")
  inspect(
    regex.map(ignore),
    content=(
      #|Err(RegexpError(err=InvalidEscape, source_fragment="\\2"))
    ),
  )
  let regex = try? parse("\\1(a)\\1")
  inspect(
    regex.map(ignore),
    content=(
      #|Err(RegexpError(err=InvalidEscape, source_fragment="\\1(a)\\1"))
    ),
  )

  // Test with a backreference to a recursive backreference
  let regex = try? parse("(\\1)")
  inspect(
    regex.map(ignore),
    content=(
      #|Err(RegexpError(err=InvalidEscape, source_fragment="\\1)"))
    ),
  )
}

///|
test "parse character class range with escaped end character" {
  // Test unicode escapes in ranges
  let regex = parse("[a-\\u007A]").ast // Should parse as range from 'a' to 'z' (U+007A)
  @json.inspect(regex, content=["CharClass neg=false", ["'a'", "'z'"]])
  let regex = parse("[a-\\u{7A}]").ast // Should parse as range from 'a' to 'z' (U+007A)
  @json.inspect(regex, content=["CharClass neg=false", ["'a'", "'z'"]])

  // Test with literal backslash in range - backslash (0x5C) < 'z' (0x7A)
  let regex = parse("[\\\\-z]").ast // Should parse as range from '\' to 'z'
  @json.inspect(regex, content=["CharClass neg=false", ["'\\\\'", "'z'"]])

  // Test invalid range (end char < start char) - tab comes before 'z', so this should error
  let result = try? parse("[z-\\t]")
  inspect(
    result.map(ignore),
    content="Err(RegexpError(err=InvalidCharClass, source_fragment=\"]\"))",
  )

  // Test invalid: character classes like \d cannot be used in ranges on right side
  let result = try? parse("[a-\\d]")
  inspect(
    result.map(ignore),
    content=(
      #|Err(RegexpError(err=InvalidCharClass, source_fragment="-\\d]"))
    ),
  )

  // Test escaped characters on both sides of range - newline (0x0A) to carriage return (0x0D)
  let regex = parse("[\\n-\\r]").ast
  @json.inspect(regex, content=["CharClass neg=false", ["'\\n'", "'\\r'"]])

  // Test range with special escape : \s-\s should be treated as literal characters '-'
  let regex = parse("[\\s-\\s]").ast
  @json.inspect(regex, content=[
    "CharClass neg=false",
    [
      "'\\t'", "'\\r'", "' '", "' '", "' '", "' '", "' '", "' '", "' '",
      "' '", "'\\u{2028}'", "'\\u{2029}'", "' '", "' '", "' '", "' '",
      "'　'", "'　'", "'\\u{feff}'", "'\\u{feff}'", "'-'", "'-'", "'\\t'", "'\\r'",
      "' '", "' '", "' '", "' '", "' '", "' '", "' '", "' '", "'\\u{2028}'",
      "'\\u{2029}'", "' '", "' '", "' '", "' '", "'　'", "'　'", "'\\u{feff}'",
      "'\\u{feff}'",
    ],
  ])
}
