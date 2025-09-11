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
  let regex = parse("a(b|c)*d")
  let { instructions, capture: capture_count, .. } = regex.compile()
  let result = vm(instructions, "abbd", capture_count)
  inspect(result, content="[0, 4, 2, 3]")
}

///|
test "parse multi-branch alternation expression" {
  let regex = parse("abc|def|ghi")
  let { instructions, capture: capture_count, .. } = regex.compile()
  let result = vm(instructions, "abcdefghi", capture_count)
  inspect(result, content="[0, 3]")
}

///|
test "parse dot character (any character match)" {
  let regex = parse("a.c")
  let { instructions, capture: capture_count, .. } = regex.compile()
  let result = vm(instructions, "abc", capture_count)
  inspect(result, content="[0, 3]")
  let result = vm(instructions, "axc", capture_count)
  inspect(result, content="[0, 3]")
  let result = vm(instructions, "a1c", capture_count)
  inspect(result, content="[0, 3]")
}

///|
test "parse character class range syntax" {
  let regex = parse("[a-z]")
  let { instructions, capture: capture_count, .. } = regex.compile()
  let result = vm(instructions, "hello", capture_count)
  inspect(result, content="[0, 1]")
}

///|
test "parse multiple character class ranges" {
  let regex = parse("[a-zA-Z]")
  let { instructions, capture: capture_count, .. } = regex.compile()
  let result = vm(instructions, "Hello123", capture_count)
  inspect(result, content="[0, 1]")
}

///|
test "parse mixed character class (ranges and individual characters)" {
  let regex = parse("[a-z0-9_]")
  let { instructions, capture: capture_count, .. } = regex.compile()
  let result = vm(instructions, "_test123", capture_count)
  inspect(result, content="[0, 1]")
}

///|
test "parse literal hyphen in character class" {
  let regex = parse("[abc-]")
  let { instructions, capture: capture_count, .. } = regex.compile()
  let result = vm(instructions, "-", capture_count)
  inspect(result, content="[0, 1]")
}

///|
test "parse character class range with escaped characters" {
  let regex = parse("[\\]-a]")
  let { instructions, capture: capture_count, .. } = regex.compile()
  let result = vm(instructions, "]", capture_count)
  inspect(result, content="[0, 1]")

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
  let regex = parse("a{3}")
  let { instructions, capture: capture_count, .. } = regex.compile()
  let result = vm(instructions, "aaa", capture_count)
  inspect(result, content="[0, 3]")

  // Should not match if there are fewer than 3 'a's
  let result = vm(instructions, "aa", capture_count)
  inspect(result, content="[]")

  // Should match if there are more than 3 'a's (matches the first 3)
  let result = vm(instructions, "aaaa", capture_count)
  inspect(result, content="[0, 3]")
}

///|
test "parse minimum repeat quantifier {n,}" {
  let regex = parse("b{2,}")
  let { instructions, capture: capture_count, .. } = regex.compile()

  // Match exactly 2 'b's
  let result = vm(instructions, "bb", capture_count)
  inspect(result, content="[0, 2]")

  // Match 3 'b's
  let result = vm(instructions, "bbb", capture_count)
  inspect(result, content="[0, 3]")

  // Should not match if there are fewer than 2 'b's
  let result = vm(instructions, "b", capture_count)
  inspect(result, content="[]")
}

///|
test "parse range repeat quantifier {n,m}" {
  let regex = parse("c{2,4}")
  let { instructions, capture: capture_count, .. } = regex.compile()

  // Match 2 'c's
  let result = vm(instructions, "cc", capture_count)
  inspect(result, content="[0, 2]")

  // Match 3 'c's
  let result = vm(instructions, "ccc", capture_count)
  inspect(result, content="[0, 3]")

  // Match 4 'c's
  let result = vm(instructions, "cccc", capture_count)
  inspect(result, content="[0, 4]")

  // Should match if there are more than 4 'c's (matches the first 4)
  let result = vm(instructions, "ccccc", capture_count)
  inspect(result, content="[0, 4]")

  // Should not match if there are fewer than 2 'c's
  let result = vm(instructions, "c", capture_count)
  inspect(result, content="[]")
}

///|
test "parse lazy minimum repeat quantifier {n,}?" {
  let regex = parse("d{2,}?")
  let { instructions, capture: capture_count, .. } = regex.compile()

  // Lazy mode matches the minimum number of characters
  let result = vm(instructions, "ddd", capture_count)
  inspect(result, content="[0, 2]")
}

///|
test "parse complex repeat quantifier expression" {
  let regex = parse("a{2}b{1,3}c{2,}")
  let { instructions, capture: capture_count, .. } = regex.compile()

  // Match "aabccc"
  let result = vm(instructions, "aabccc", capture_count)
  inspect(result, content="[0, 6]")

  // Should not match "aabbbbcc" (more than 3 'b's)
  let result = vm(instructions, "aabbbbcc", capture_count)
  inspect(result, content="[]")
}

///|
test "parse repeat quantifier with groups" {
  let regex = parse("(ab){2}")
  let { instructions, capture: capture_count, .. } = regex.compile()

  // Match "abab"
  let result = vm(instructions, "abab", capture_count)
  inspect(result, content="[0, 4, 2, 4]")
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
  let regex = parse("(?:abc)")
  let { instructions, capture: capture_count, .. } = regex.compile()
  let result = vm(instructions, "abc", capture_count)
  inspect(result, content="[0, 3]")
}

///|
test "parse named capture group" {
  let regex = parse("(?<name>abc)")
  let { instructions, capture: capture_count, map, .. } = regex.compile()
  let result = vm(instructions, "abc", capture_count)
  inspect(result, content="[0, 3, 0, 3]")

  // Validate named group map
  inspect(map.get("name"), content="Some(1)")
}

///|
test "parse complex named capture group expression" {
  let regex = parse("(?<first>a+)(?<second>b+)")
  let { instructions, capture: capture_count, map, .. } = regex.compile()
  let result = vm(instructions, "aaabbb", capture_count)
  inspect(result, content="[0, 6, 0, 3, 3, 6]")

  // Validate named group map
  inspect(map.get("first"), content="Some(1)")
  inspect(map.get("second"), content="Some(2)")
}

///|
test "parse nested named capture groups" {
  let regex = parse("(?<outer>a(?<inner>bc)d)")
  let { instructions, capture: capture_count, map, .. } = regex.compile()
  let result = vm(instructions, "abcd", capture_count)
  inspect(result, content="[0, 4, 0, 4, 1, 3]")

  // Validate named group map
  inspect(map.get("outer"), content="Some(1)")
  inspect(map.get("inner"), content="Some(2)")
}

///|
test "parse mixed named and regular capture groups" {
  let regex = parse("(a)(?<named>b)(c)")
  let { instructions, capture: capture_count, map, .. } = regex.compile()
  let result = vm(instructions, "abc", capture_count)
  inspect(result, content="[0, 3, 0, 1, 1, 2, 2, 3]")

  // Validate named group map (second capture group, index 2)
  inspect(map.get("named"), content="Some(2)")
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
  let regex = parse("(?<group>abc)").ast
  @json.inspect((regex : Ast), content=[
    "Capture 1",
    [
      ["CharClass neg=false", ["'a'", "'a'"]],
      ["CharClass neg=false", ["'b'", "'b'"]],
      ["CharClass neg=false", ["'c'", "'c'"]],
    ],
  ])

  // Starts with an underscore
  let regex = parse("(?<_group>abc)").ast
  @json.inspect((regex : Ast), content=[
    "Capture 1",
    [
      ["CharClass neg=false", ["'a'", "'a'"]],
      ["CharClass neg=false", ["'b'", "'b'"]],
      ["CharClass neg=false", ["'c'", "'c'"]],
    ],
  ])

  // Contains digits
  let regex = parse("(?<group1>abc)").ast
  @json.inspect((regex : Ast), content=[
    "Capture 1",
    [
      ["CharClass neg=false", ["'a'", "'a'"]],
      ["CharClass neg=false", ["'b'", "'b'"]],
      ["CharClass neg=false", ["'c'", "'c'"]],
    ],
  ])

  // Contains multiple underscores
  let regex = parse("(?<my_group_1>abc)").ast
  @json.inspect((regex : Ast), content=[
    "Capture 1",
    [
      ["CharClass neg=false", ["'a'", "'a'"]],
      ["CharClass neg=false", ["'b'", "'b'"]],
      ["CharClass neg=false", ["'c'", "'c'"]],
    ],
  ])
}

///|
test "parse line begin assertion ^" {
  let regex = parse("^abc", flags={ ..Flags::default(), multiline: true })
  let { instructions, capture: capture_count, .. } = regex.compile()

  // Test matching at the beginning of a line
  let result = vm(instructions, "abc", capture_count)
  inspect(result, content="[0, 3]")

  // Test matching the first line in a multiline string
  let result = vm(instructions, "abc\ndef", capture_count)
  inspect(result, content="[0, 3]")
  // Test matching the second line in a multiline string
  let result = vm(instructions, "def\nabc", capture_count)
  inspect(result, content="[4, 7]")

  // Test not matching when not at the beginning of a line (should not match)
  let result = vm(instructions, "xabc", capture_count)
  inspect(result, content="[]")
}

///|
test "parse line end assertion $" {
  let regex = parse("abc$", flags={ ..Flags::default(), multiline: true })
  let { instructions, capture: capture_count, .. } = regex.compile()

  // Test matching at the end of a line
  let result = vm(instructions, "abc", capture_count)
  inspect(result, content="[0, 3]")

  // Test matching the first line in a multiline string
  let result = vm(instructions, "abc\ndef", capture_count)
  inspect(result, content="[0, 3]")

  // Test matching the second line in a multiline string
  let result = vm(instructions, "def\nabc", capture_count)
  inspect(result, content="[4, 7]")

  // Test not matching when not at the end of a line (should not match)
  let result = vm(instructions, "abcx", capture_count)
  inspect(result, content="[]")
}

///|
test "parse line begin and end assertion ^...$" {
  let regex = parse("^abc$")
  let { instructions, capture: capture_count, .. } = regex.compile()

  // Test matching the entire line
  let result = vm(instructions, "abc", capture_count)
  inspect(result, content="[0, 3]")

  // Test with extra characters at the end (should not match)
  let result = vm(instructions, "abcd", capture_count)
  inspect(result, content="[]")

  // Test with extra characters at the beginning (should not match)
  let result = vm(instructions, "xabc", capture_count)
  inspect(result, content="[]")
}

///|
test "parse multiline assertions" {
  let regex = parse("^line", flags={ ..Flags::default(), multiline: true })
  let { instructions, capture: capture_count, .. } = regex.compile()

  // Test matching the first line in multiline text
  let result = vm(instructions, "line1\nline2\nnot line", capture_count)
  inspect(result, content="[0, 4]")

  // Test matching line end assertion in multiline text
  let regex = parse("line$", flags={ ..Flags::default(), multiline: true })
  let { instructions, capture: capture_count, .. } = regex.compile()
  let result = vm(instructions, "not line\nline2\nthis line", capture_count)
  inspect(result, content="[4, 8]") // Matches "line" on the first line
}

///|
test "parse assertion with quantifiers" {
  let regex = parse("^a+$")
  let { instructions, capture: capture_count, .. } = regex.compile()

  // Test matching a line full of 'a's
  let result = vm(instructions, "aaa", capture_count)
  inspect(result, content="[0, 3]")

  // Test with a single 'a'
  let result = vm(instructions, "a", capture_count)
  inspect(result, content="[0, 1]")

  // Test with other characters (should not match)
  let result = vm(instructions, "aab", capture_count)
  inspect(result, content="[]")
}

///|
test "parse assertion with capture groups" {
  let regex = parse("^(abc)$")
  let { instructions, capture: capture_count, .. } = regex.compile()

  // Test matching and capturing the entire line
  let result = vm(instructions, "abc", capture_count)
  inspect(result, content="[0, 3, 0, 3]")

  // Test non-matching case
  let result = vm(instructions, "abcd", capture_count)
  inspect(result, content="[]")
}

///|
test "parse escaped assertion characters" {
  let regex = parse("\\^abc\\$")
  let { instructions, capture: capture_count, .. } = regex.compile()

  // Test matching the literal "^abc$"
  let result = vm(instructions, "^abc$", capture_count)
  inspect(result, content="[0, 5]")

  // Test non-matching case without literal symbols
  let result = vm(instructions, "abc", capture_count)
  inspect(result, content="[]")
}

///|
test "parse assertion characters in character class" {
  let regex = parse("[^$]")
  let { instructions, capture: capture_count, .. } = regex.compile()

  // Test matching a normal character
  let result = vm(instructions, "a", capture_count)
  inspect(result, content="[0, 1]")

  // Test matching '^' character (since it's not '$')
  let result = vm(instructions, "^", capture_count)
  inspect(result, content="[0, 1]")

  // Test not matching '$' character
  let result = vm(instructions, "$", capture_count)
  inspect(result, content="[]")
}

///|
test "parse complex assertion expression" {
  let regex = parse("^(hello|world)$")
  let { instructions, capture: capture_count, .. } = regex.compile()

  // Test matching "hello"
  let result = vm(instructions, "hello", capture_count)
  inspect(result, content="[0, 5, 0, 5]")

  // Test matching "world"
  let result = vm(instructions, "world", capture_count)
  inspect(result, content="[0, 5, 0, 5]")

  // Test not matching other content
  let result = vm(instructions, "hello world", capture_count)
  inspect(result, content="[]")
}

///|
test "parse word boundary assertion \\b" {
  let regex = parse("\\bword\\b")
  let { instructions, capture: capture_count, .. } = regex.compile()

  // Test matching a standalone word
  let result = vm(instructions, "word", capture_count)
  inspect(result, content="[0, 4]")

  // Test matching a whole word in a sentence
  let result = vm(instructions, "the word is", capture_count)
  inspect(result, content="[4, 8]")

  // Test not matching part of a word
  let result = vm(instructions, "password", capture_count)
  inspect(result, content="[]")

  // Test not matching the beginning of a word
  let result = vm(instructions, "words", capture_count)
  inspect(result, content="[]")
}

///|
test "parse non-word boundary assertion \\B" {
  let regex = parse("\\Bword\\B")
  let { instructions, capture: capture_count, .. } = regex.compile()

  // Test matching "word" surrounded by letters
  let result = vm(instructions, "passwords", capture_count)
  inspect(result, content="[4, 8]")

  // Test not matching a standalone word
  let result = vm(instructions, "word", capture_count)
  inspect(result, content="[]")

  // Test not matching at a word boundary
  let result = vm(instructions, "the word", capture_count)
  inspect(result, content="[]")
}

///|
test "parse combined word boundary assertions" {
  let regex = parse("\\btest|\\btesting\\b")
  let { instructions, capture: capture_count, .. } = regex.compile()

  // Test matching a word starting with "test"
  let result = vm(instructions, "testing", capture_count)
  inspect(result, content="[0, 4]") // Matches "test" part

  // Test matching the whole word "testing"
  let result = vm(instructions, "a testing b", capture_count)
  inspect(result, content="[2, 6]")

  // Test matching the standalone word "test"
  let result = vm(instructions, "test", capture_count)
  inspect(result, content="[0, 4]")
}

///|
test "parse word boundary with character class" {
  let regex = parse("\\b[a-z]+\\b")
  let { instructions, capture: capture_count, .. } = regex.compile()

  // Test matching a lowercase word
  let result = vm(instructions, "hello world", capture_count)
  inspect(result, content="[0, 5]")

  // Test not matching a word with uppercase letters
  let result = vm(instructions, "Hello", capture_count)
  inspect(result, content="[]")

  // Test not matching a word with digits
  let result = vm(instructions, "test123", capture_count)
  inspect(result, content="[]")
}

///|
test "parse word boundary with quantifiers" {
  let regex = parse("\\b\\w{3,5}\\b")
  let { instructions, capture: capture_count, .. } = regex.compile()

  // Test matching a 3-character word
  let result = vm(instructions, "cat", capture_count)
  inspect(result, content="[0, 3]")

  // Test matching a 5-character word
  let result = vm(instructions, "hello", capture_count)
  inspect(result, content="[0, 5]")

  // Test not matching a 2-character word
  let result = vm(instructions, "go", capture_count)
  inspect(result, content="[]")

  // Test not matching a 6-character word
  let result = vm(instructions, "longer", capture_count)
  inspect(result, content="[]")
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
  let regex = parse("\\b(\\w+)\\b")
  let { instructions, capture: capture_count, .. } = regex.compile()

  // Test capturing a single word
  let result = vm(instructions, "hello", capture_count)
  inspect(result, content="[0, 5, 0, 5]")

  // Test capturing the first word in a sentence
  let result = vm(instructions, "hello world", capture_count)
  inspect(result, content="[0, 5, 0, 5]")
}

///|
test "parse complex word boundary expression" {
  // Simplified version, only tests basic word boundary functionality
  let regex = parse("\\bthe\\b")
  let { instructions, capture: capture_count, .. } = regex.compile()

  // Test matching standalone "the"
  let result = vm(instructions, "the", capture_count)
  inspect(result, content="[0, 3]")

  // Test matching "the" in a sentence
  let result = vm(instructions, "the cat", capture_count)
  inspect(result, content="[0, 3]")

  // Test not matching "the" as part of another word
  let result = vm(instructions, "them", capture_count)
  inspect(result, content="[]")
  let result = vm(instructions, "other", capture_count)
  inspect(result, content="[]")
}

///|
test "parse unicode general property" {
  let regex = parse("\\p{Ll}")
  let { instructions, capture: capture_count, .. } = regex.compile()

  // Test matching a letter character
  let result = vm(instructions, "a", capture_count)
  inspect(result, content="[0, 1]")

  // Test matching a non-letter character
  let result = vm(instructions, "1", capture_count)
  inspect(result, content="[]")

  // Test matching a Unicode letter character
  let result = vm(instructions, "é", capture_count)
  inspect(result, content="[0, 1]")

  // Test matching a composed class
  let regex = parse("\\p{L}")
  let { instructions, capture: capture_count, .. } = regex.compile()
  let result = vm(instructions, "é", capture_count)
  inspect(result, content="[0, 1]")

  // Negated matching
  let regex = parse("\\P{L}")
  let { instructions, capture: capture_count, .. } = regex.compile()
  let result = vm(instructions, "é", capture_count)
  inspect(result, content="[]")
  let result = vm(instructions, "\t", capture_count)
  inspect(result, content="[0, 1]")
}

///|
test "parse unmatched curly brace" {
  let regex = parse("a|b}").ast
  @json.inspect(regex, content=[
    "Alternate",
    ["CharClass neg=false", ["'a'", "'a'"]],
    [
      ["CharClass neg=false", ["'b'", "'b'"]],
      ["CharClass neg=false", ["'}'", "'}'"]],
    ],
  ])
}

///|
test "parse backreference" {
  // Test with a valid backreference
  let regex = parse("(a)(b)\\1").ast
  @json.inspect(regex, content=[
    ["Capture 1", ["CharClass neg=false", ["'a'", "'a'"]]],
    ["Capture 2", ["CharClass neg=false", ["'b'", "'b'"]]],
    ["Backreference", 1],
  ])

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
