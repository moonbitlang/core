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
test "simple regex test" {
  let regex = @regexp.compile("abc")
  inspect(
    regex.execute("abc").results(),
    content=(
      #|[Some("abc")]
    ),
  )
  inspect(regex.execute("ab").results(), content="[]")
  inspect(
    regex.execute("abcd").results(),
    content=(
      #|[Some("abc")]
    ),
  )
}

///|
test "unicode escape sequences" {
  // Test basic \u{aaaa} format
  let regex = @regexp.compile("\\u{41}")
  inspect(
    regex.execute("A").results(),
    content=(
      #|[Some("A")]
    ),
  )
  inspect(regex.execute("B").matched(), content="false")

  // Test \uaaaa format (exactly 4 digits)
  let regex = @regexp.compile("\\u0041")
  inspect(
    regex.execute("A").results(),
    content=(
      #|[Some("A")]
    ),
  )

  // Test Unicode characters beyond ASCII
  let regex = @regexp.compile("\\u{4e16}\\u{754c}")
  inspect(
    regex.execute("世界").results(),
    content=(
      #|[Some("世界")]
    ),
  )
  let regex = @regexp.compile("\\u4e16\\u754C")
  inspect(
    regex.execute("世界").results(),
    content=(
      #|[Some("世界")]
    ),
  )

  // Test large Unicode escape
  let regex = @regexp.compile("\\u{10348}")
  inspect(
    regex.execute("𐍈").results(),
    content=(
      #|[Some("𐍈")]
    ),
  )

  // Test in character classes
  let regex = @regexp.compile("[\\u{41}-\\u{43}]")
  inspect(regex.execute("B").results(), content="[]")
  inspect(regex.execute("D").matched(), content="false")

  // Test with \uaaaa format in character classes
  let regex = @regexp.compile("[\\u0041\\u0042]")
  inspect(
    regex.execute("A").results(),
    content=(
      #|[Some("A")]
    ),
  )
  inspect(
    regex.execute("B").results(),
    content=(
      #|[Some("B")]
    ),
  )
  inspect(regex.execute("C").matched(), content="false")

  // Test combining with other patterns
  let regex = @regexp.compile("\\u{48}ello \\u{4E16}\\u754C")
  inspect(
    regex.execute("Hello 世界").results(),
    content=(
      #|[Some("Hello 世界")]
    ),
  )

  // Test error cases
  guard (try? @regexp.compile("\\u{}")) is Err(error)
  error
  |> inspect(
    content=(
      #|RegexpError(err=InvalidEscape, source_fragment="}")
    ),
  )
  guard (try? @regexp.compile("\\u{1234567}")) is Err(error)
  error
  |> inspect(
    content=(
      #|RegexpError(err=InvalidEscape, source_fragment="1234567}")
    ),
  )
  guard (try? @regexp.compile("\\u{GGGG}")) is Err(error)
  error
  |> inspect(
    content=(
      #|RegexpError(err=InvalidEscape, source_fragment="GGGG}")
    ),
  )
  guard (try? @regexp.compile("\\u123")) is Err(error)
  error
  |> inspect(
    content=(
      #|RegexpError(err=InvalidEscape, source_fragment="")
    ),
  )
  guard (try? @regexp.compile("\\uGGGG")) is Err(error)
  error
  |> inspect(
    content=(
      #|RegexpError(err=InvalidEscape, source_fragment="GGGG")
    ),
  )
  guard (try? @regexp.compile("\\u{110000}")) is Err(error)
  error
  |> inspect(
    content=(
      #|RegexpError(err=InvalidEscape, source_fragment="110000}")
    ),
  )
}

///|
test "simple regex test matching leftmost" {
  let regex = @regexp.compile("a(bc|de)f")
  inspect(
    regex.execute("xxabcf").results(),
    content=(
      #|[Some("abcf"), Some("bc")]
    ),
  )
}

///|
test "simple regex test with repeat" {
  let regex = @regexp.compile("a(bc|de){2,}f")
  inspect(
    regex.execute("xxabcdebcf").results(),
    content=(
      #|[Some("abcdebcf"), Some("bc")]
    ),
  )
}

///|
test "character classes" {
  // Email validation (simplified)
  let email = @regexp.compile(
    (
      #|[\w-]+@[\w-]+\.\w+
    ),
  )
  let email_result = email.execute("user@example.com").results()
  inspect(
    email_result,
    content=(
      #|[Some("user@example.com")]
    ),
  )
  // Extract numbers
  let numbers = @regexp.compile(
    (
      #|\d+\.\d{2}
    ),
  )
  let result = numbers.execute("Price: $42.99").results()
  inspect(
    result,
    content=(
      #|[Some("42.99")]
    ),
  )

  // Named captures for parsing
  let parser = @regexp.compile(
    (
      #|(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})
    ),
  )
  let date_result = parser.execute("2024-03-15")
  inspect(
    date_result.groups(),
    content=(
      #|{"year": "2024", "month": "03", "day": "15"}
    ),
  )
}

///|
test "regexp with flags" {
  // singleline flag
  let regexp = compile(".")
  inspect(regexp.execute("\n").matched(), content="false")
  let regexp = compile(".", flags="s")
  inspect(regexp.execute("\n").matched(), content="true")
  let regexp = compile("(?s:.)")
  inspect(regexp.execute("\n").matched(), content="true")

  // multiline flag
  let regexp = compile("$")
  inspect(regexp.execute("\n").matched(), content="true")
  inspect(regexp.execute("\n").results().length(), content="1")
  inspect(
    regexp.execute("\n").results().map(r => r.unwrap().start_offset()),
    content="[1]",
  )
  let regexp = compile("$", flags="m")
  inspect(regexp.execute("\n").matched(), content="true")
  inspect(
    regexp.execute("\n").results().map(r => r.unwrap().start_offset()),
    content="[0]",
  )
  let regexp = compile("(?m:$)")
  inspect(regexp.execute("\n").matched(), content="true")
  inspect(
    regexp.execute("\n").results().map(r => r.unwrap().start_offset()),
    content="[0]",
  )
  let regexp = compile("(?m-m:$)")
  inspect(regexp.execute("\n").matched(), content="true")
  inspect(
    regexp.execute("\n").results().map(r => r.unwrap().start_offset()),
    content="[1]",
  )
}

///|
test "invalid regex test" {
  guard (try? @regexp.compile("a(b")) is Err(error)
  error
  |> inspect(
    content=(
      #|RegexpError(err=MissingParenthesis, source_fragment="")
    ),
  )
  guard (try? @regexp.compile("a(b|c")) is Err(error)
  error
  |> inspect(
    content=(
      #|RegexpError(err=MissingParenthesis, source_fragment="")
    ),
  )
  guard (try? @regexp.compile("a|b)")) is Err(error)
  error
  |> inspect(
    content=(
      #|RegexpError(err=UnexpectedParenthesis, source_fragment=")")
    ),
  )
  guard (try? @regexp.compile("a|b|c)")) is Err(error)
  error
  |> inspect(
    content=(
      #|RegexpError(err=UnexpectedParenthesis, source_fragment=")")
    ),
  )
}

///|
test "quantifiers and repetition" {
  // Test * quantifier (zero or more)
  let regex = @regexp.compile("ab*c")
  inspect(
    regex.execute("ac").results(),
    content=(
      #|[Some("ac")]
    ),
  )
  inspect(
    regex.execute("abc").results(),
    content=(
      #|[Some("abc")]
    ),
  )
  inspect(
    regex.execute("abbbbc").results(),
    content=(
      #|[Some("abbbbc")]
    ),
  )
  inspect(regex.execute("bc").matched(), content="false")

  // Test + quantifier (one or more)
  let regex = @regexp.compile("ab+c")
  inspect(regex.execute("ac").matched(), content="false")
  inspect(
    regex.execute("abc").results(),
    content=(
      #|[Some("abc")]
    ),
  )
  inspect(
    regex.execute("abbbbc").results(),
    content=(
      #|[Some("abbbbc")]
    ),
  )

  // Test ? quantifier (zero or one)
  let regex = @regexp.compile("ab?c")
  inspect(
    regex.execute("ac").results(),
    content=(
      #|[Some("ac")]
    ),
  )
  inspect(
    regex.execute("abc").results(),
    content=(
      #|[Some("abc")]
    ),
  )
  inspect(regex.execute("abbc").matched(), content="false")

  // Test specific count {n}
  let regex = @regexp.compile("a{3}")
  inspect(regex.execute("aa").matched(), content="false")
  inspect(
    regex.execute("aaa").results(),
    content=(
      #|[Some("aaa")]
    ),
  )
  inspect(
    regex.execute("aaaa").results(),
    content=(
      #|[Some("aaa")]
    ),
  )

  // Test range {n,m}
  let regex = @regexp.compile("a{2,4}")
  inspect(regex.execute("a").matched(), content="false")
  inspect(
    regex.execute("aa").results(),
    content=(
      #|[Some("aa")]
    ),
  )
  inspect(
    regex.execute("aaa").results(),
    content=(
      #|[Some("aaa")]
    ),
  )
  inspect(
    regex.execute("aaaa").results(),
    content=(
      #|[Some("aaaa")]
    ),
  )
  inspect(
    regex.execute("aaaaa").results(),
    content=(
      #|[Some("aaaa")]
    ),
  )

  // Test minimum count {n,}
  let regex = @regexp.compile("a{3,}")
  inspect(regex.execute("aa").matched(), content="false")
  inspect(
    regex.execute("aaa").results(),
    content=(
      #|[Some("aaa")]
    ),
  )
  inspect(
    regex.execute("aaaaa").results(),
    content=(
      #|[Some("aaaaa")]
    ),
  )
}

///|
test "character classes and sets" {
  // Test digit class \d
  let regex = @regexp.compile("\\d+")
  inspect(
    regex.execute("123").results(),
    content=(
      #|[Some("123")]
    ),
  )
  inspect(
    regex.execute("abc123def").results(),
    content=(
      #|[Some("123")]
    ),
  )
  inspect(regex.execute("abc").matched(), content="false")

  // Test word class \w
  let regex = @regexp.compile("\\w+")
  inspect(
    regex.execute("hello123").results(),
    content=(
      #|[Some("hello123")]
    ),
  )
  inspect(
    regex.execute("hello-world").results(),
    content=(
      #|[Some("hello")]
    ),
  )

  // Test whitespace class \s
  let regex = @regexp.compile("\\s+")
  inspect(
    regex.execute("  \t\n").results(),
    content=(
      #|[Some("  \t\n")]
    ),
  )
  inspect(
    regex.execute("a b").results(),
    content=(
      #|[Some(" ")]
    ),
  )

  // Test negated classes
  let regex = @regexp.compile("\\D+")
  inspect(
    regex.execute("abc123").results(),
    content=(
      #|[Some("abc")]
    ),
  )
  let regex = @regexp.compile("\\W+")
  inspect(
    regex.execute("hello-world!").results(),
    content=(
      #|[Some("-")]
    ),
  )
  let regex = @regexp.compile("\\S+")
  inspect(
    regex.execute("hello world").results(),
    content=(
      #|[Some("hello")]
    ),
  )

  // Test custom character sets
  let regex = @regexp.compile("[abc]")
  inspect(
    regex.execute("apple").results(),
    content=(
      #|[Some("a")]
    ),
  )
  inspect(
    regex.execute("banana").results(),
    content=(
      #|[Some("b")]
    ),
  )
  inspect(regex.execute("xyz").matched(), content="false")

  // Test character ranges
  let regex = @regexp.compile("[a-z]+")
  inspect(
    regex.execute("hello123").results(),
    content=(
      #|[Some("hello")]
    ),
  )
  inspect(
    regex.execute("Hello").results(),
    content=(
      #|[Some("ello")]
    ),
  )
  let regex = @regexp.compile("[0-9]+")
  inspect(
    regex.execute("abc123def").results(),
    content=(
      #|[Some("123")]
    ),
  )

  // Test negated character sets
  let regex = @regexp.compile("[^abc]+")
  inspect(
    regex.execute("abcdef").results(),
    content=(
      #|[Some("def")]
    ),
  )
  inspect(
    regex.execute("xyz").results(),
    content=(
      #|[Some("xyz")]
    ),
  )

  // Test mixed character sets
  let regex = @regexp.compile("[a-zA-Z0-9_]+")
  inspect(
    regex.execute("Hello_World123").results(),
    content=(
      #|[Some("Hello_World123")]
    ),
  )
  inspect(
    regex.execute("test-case").results(),
    content=(
      #|[Some("test")]
    ),
  )
}

///|
test "anchors and boundaries" {
  // Test start anchor ^
  let regex = @regexp.compile("^hello")
  inspect(
    regex.execute("hello world").results(),
    content=(
      #|[Some("hello")]
    ),
  )
  inspect(regex.execute("say hello").matched(), content="false")

  // Test end anchor $
  let regex = @regexp.compile("world$")
  inspect(
    regex.execute("hello world").results(),
    content=(
      #|[Some("world")]
    ),
  )
  inspect(regex.execute("world peace").matched(), content="false")

  // Test both anchors
  let regex = @regexp.compile("^hello$")
  inspect(
    regex.execute("hello").results(),
    content=(
      #|[Some("hello")]
    ),
  )
  inspect(regex.execute("hello world").matched(), content="false")
  inspect(regex.execute("say hello").matched(), content="false")

  // Test word boundaries \b
  let regex = @regexp.compile("\\bword\\b")
  inspect(
    regex.execute("a word here").results(),
    content=(
      #|[Some("word")]
    ),
  )
  inspect(
    regex.execute("word").results(),
    content=(
      #|[Some("word")]
    ),
  )
  inspect(regex.execute("sword").matched(), content="false")
  inspect(regex.execute("words").matched(), content="false")

  // Test non-word boundaries \B
  let regex = @regexp.compile("\\Bor\\B")
  inspect(
    regex.execute("words").results(),
    content=(
      #|[Some("or")]
    ),
  )
  inspect(regex.execute("or").matched(), content="false")
  inspect(regex.execute("for you").matched(), content="false")
}

///|
test "alternation and grouping" {
  // Test simple alternation
  let regex = @regexp.compile("cat|dog")
  inspect(
    regex.execute("I have a cat").results(),
    content=(
      #|[Some("cat")]
    ),
  )
  inspect(
    regex.execute("I have a dog").results(),
    content=(
      #|[Some("dog")]
    ),
  )
  inspect(regex.execute("I have a bird").matched(), content="false")

  // Test alternation with groups
  let regex = @regexp.compile("(cat|dog) food")
  let result = regex.execute("cat food").results()
  inspect(
    result,
    content=(
      #|[Some("cat food"), Some("cat")]
    ),
  )

  // Test nested groups
  let regex = @regexp.compile("((a|b)(c|d))")
  let result = regex.execute("ac").results()
  inspect(
    result,
    content=(
      #|[Some("ac"), Some("ac"), Some("a"), Some("c")]
    ),
  )

  // Test non-capturing groups
  let regex = @regexp.compile("(?:cat|dog) food")
  inspect(
    regex.execute("cat food").results(),
    content=(
      #|[Some("cat food")]
    ),
  )

  // Test multiple alternations
  let regex = @regexp.compile("red|green|blue")
  inspect(
    regex.execute("red car").results(),
    content=(
      #|[Some("red")]
    ),
  )
  inspect(
    regex.execute("green light").results(),
    content=(
      #|[Some("green")]
    ),
  )
  inspect(
    regex.execute("blue sky").results(),
    content=(
      #|[Some("blue")]
    ),
  )
}

///|
test "advanced capture groups" {
  // Test multiple groups
  let regex = @regexp.compile("([a-z]+) ([0-9]+)")
  let result = regex.execute("hello 123")
  inspect(
    result.get(0),
    content=(
      #|Some("hello 123")
    ),
  )
  inspect(
    result.get(1),
    content=(
      #|Some("hello")
    ),
  )
  inspect(
    result.get(2),
    content=(
      #|Some("123")
    ),
  )
  inspect(result.get(3), content="None")

  // Test nested groups
  let regex = @regexp.compile("((\\w+)-(\\w+))")
  let result = regex.execute("first-second")
  inspect(
    result.get(0),
    content=(
      #|Some("first-second")
    ),
  )
  inspect(
    result.get(1),
    content=(
      #|Some("first-second")
    ),
  )
  inspect(
    result.get(2),
    content=(
      #|Some("first")
    ),
  )
  inspect(
    result.get(3),
    content=(
      #|Some("second")
    ),
  )

  // Test optional groups
  let regex = @regexp.compile("(\\w+)(-\\w+)?")
  let result1 = regex.execute("hello-world")
  inspect(
    result1.get(1),
    content=(
      #|Some("hello")
    ),
  )
  inspect(
    result1.get(2),
    content=(
      #|Some("-world")
    ),
  )
  let result2 = regex.execute("hello")
  inspect(
    result2.get(1),
    content=(
      #|Some("hello")
    ),
  )
  // Optional group that didn't match should still be accessible but empty
  inspect(result2.get(2), content="None")
}

///|
test "complex named capture groups" {
  // Test multiple named groups
  let regex = @regexp.compile("(?<first>\\w+)\\s+(?<last>\\w+)")
  let result = regex.execute("John Doe")
  inspect(
    result.groups(),
    content=(
      #|{"first": "John", "last": "Doe"}
    ),
  )

  // Test group names iteration
  let names = regex.group_names()
  inspect(names.contains("first"), content="true")
  inspect(names.contains("last"), content="true")

  // Test URL parsing with named groups
  let url_regex = @regexp.compile(
    "(?<protocol>https?)://(?<domain>[^/]+)(?<path>/.*)?",
  )
  let result = url_regex.execute("https://example.com/path/to/page")
  inspect(
    result.groups(),
    content=(
      #|{"protocol": "https", "domain": "example.com", "path": "/path/to/page"}
    ),
  )

  // Test mixed named and unnamed groups
  let regex = @regexp.compile("(\\w+)@(?<domain>\\w+\\.\\w+)")
  let result = regex.execute("user@example.com")
  inspect(
    result.get(1),
    content=(
      #|Some("user")
    ),
  )
  inspect(
    result.groups(),
    content=(
      #|{"domain": "example.com"}
    ),
  )
}

///|
test "escape sequences and special characters" {
  // Test literal special characters
  let regex = @regexp.compile("\\.")
  inspect(
    regex.execute("3.14").results(),
    content=(
      #|[Some(".")]
    ),
  )
  inspect(regex.execute("314").matched(), content="false")
  let regex = @regexp.compile("\\*")
  inspect(
    regex.execute("2*3").results(),
    content=(
      #|[Some("*")]
    ),
  )
  let regex = @regexp.compile("\\+")
  inspect(
    regex.execute("1+1").results(),
    content=(
      #|[Some("+")]
    ),
  )
  let regex = @regexp.compile("\\?")
  inspect(
    regex.execute("what?").results(),
    content=(
      #|[Some("?")]
    ),
  )

  // Test escaped brackets
  let regex = @regexp.compile("\\[\\]")
  inspect(
    regex.execute("array[]").results(),
    content=(
      #|[Some("[]")]
    ),
  )
  let regex = @regexp.compile("\\(\\)")
  inspect(
    regex.execute("func()").results(),
    content=(
      #|[Some("()")]
    ),
  )

  // Test escaped backslash
  let regex = @regexp.compile("\\\\")
  inspect(
    regex.execute("path\\file").results(),
    content=(
      #|[Some("\\")]
    ),
  )

  // Test tab, newline, etc.
  let regex = @regexp.compile("\\t")
  inspect(
    regex.execute("a\tb").results(),
    content=(
      #|[Some("\t")]
    ),
  )
  let regex = @regexp.compile("\\n")
  inspect(
    regex.execute("line1\nline2").results(),
    content=(
      #|[Some("\n")]
    ),
  )
  let regex = @regexp.compile("\\r")
  inspect(
    regex.execute("line1\rline2").results(),
    content=(
      #|[Some("\r")]
    ),
  )
  let regex = @regexp.compile("[\\t\\n\\r]")
  inspect(
    regex.execute("a\tb").results(),
    content=(
      #|[Some("\t")]
    ),
  )
  inspect(
    regex.execute("line1\nline2").results(),
    content=(
      #|[Some("\n")]
    ),
  )
  inspect(
    regex.execute("line1\rline2").results(),
    content=(
      #|[Some("\r")]
    ),
  )
}

///|
test "greedy vs non-greedy matching" {
  // Test greedy quantifiers
  let regex = @regexp.compile("<.*>")
  inspect(
    regex.execute("<div><span></span></div>").results(),
    content=(
      #|[Some("<div><span></span></div>")]
    ),
  )

  // Test non-greedy quantifiers
  let regex = @regexp.compile("<.*?>")
  inspect(
    regex.execute("<div><span></span></div>").results(),
    content=(
      #|[Some("<div>")]
    ),
  )

  // Test non-greedy +
  let regex = @regexp.compile("a.+?b")
  inspect(
    regex.execute("axxxbyyybzzz").results(),
    content=(
      #|[Some("axxxb")]
    ),
  )

  // Test non-greedy *
  let regex = @regexp.compile("a.*?b")
  inspect(
    regex.execute("axxxbyyybzzz").results(),
    content=(
      #|[Some("axxxb")]
    ),
  )

  // Test non-greedy ?
  let regex = @regexp.compile("a??b")
  inspect(
    regex.execute("b").results(),
    content=(
      #|[Some("b")]
    ),
  )
}

// ///|
// test "lookahead and lookbehind assertions" {
//   // Test positive lookahead
//   let regex = @regexp.compile("\\w+(?=ing)")
//   let result = regex.execute("running jumping walking")
//   if result.matched() {
//     inspect(
//       result.results(),
//       content=
//         #|["runn", "jump", "walk"]
//       ,
//     )
//   }

//   // Test negative lookahead  
//   let regex = @regexp.compile("\\w+(?!ing)")
//   let result = regex.execute("running jump walking")
//   if result.matched() {
//     // Should match words not followed by "ing"
//     inspect(result.results().take(0), content="jump")
//   }

//   // Test positive lookbehind
//   let regex = @regexp.compile("(?<=\\$)\\d+")
//   let result = regex.execute("Price: $100 and €200")
//   if result.matched() {
//     inspect(
//       result.results(),
//       content=
//         #|["100"]
//       ,
//     )
//   }

//   // Test negative lookbehind
//   let regex = @regexp.compile("(?<!\\$)\\d+")
//   let result = regex.execute("Price: $100 and 200")
//   if result.matched() {
//     inspect(
//       result.results(),
//       content=
//         #|["200"]
//       ,
//     )
//   }
// }

///|
test "case sensitivity and flags" {
  // Test case insensitive flag
  let regex = @regexp.compile("hello", flags="i")
  inspect(
    regex.execute("HELLO").results(),
    content=(
      #|[Some("HELLO")]
    ),
  )
  inspect(
    regex.execute("Hello").results(),
    content=(
      #|[Some("Hello")]
    ),
  )
  inspect(
    regex.execute("hElLo").results(),
    content=(
      #|[Some("hElLo")]
    ),
  )

  // Test inline case insensitive
  let regex = @regexp.compile("(?i:hello)")
  inspect(
    regex.execute("HELLO world").results(),
    content=(
      #|[Some("HELLO")]
    ),
  )

  // Test case sensitive (default)
  let regex = @regexp.compile("hello")
  inspect(
    regex.execute("hello").results(),
    content=(
      #|[Some("hello")]
    ),
  )
  inspect(regex.execute("HELLO").matched(), content="false")

  // Test mixed case sensitivity
  let regex = @regexp.compile("(?i:hello) world")
  inspect(
    regex.execute("HELLO world").results(),
    content=(
      #|[Some("HELLO world")]
    ),
  )
  inspect(regex.execute("HELLO WORLD").matched(), content="false")
}

// ///|

///|
test "unicode and international characters" {
  // Test basic unicode
  let regex = @regexp.compile("café")
  inspect(
    regex.execute("I love café").results(),
    content=(
      #|[Some("café")]
    ),
  )

  // Test unicode word boundaries
  let regex = @regexp.compile("\\w+")
  inspect(
    regex.execute("hello 世界").results(),
    content=(
      #|[Some("hello")]
    ),
  )

  // Test unicode character classes
  let regex = @regexp.compile("[\\u4e00-\\u9fff]+")
  if regex.execute("Hello 世界 World").matched() {
    inspect(
      regex.execute("Hello 世界 World").results(),
      content=(
        #|["世界"]
      ),
    )
  }

  // Test emoji (if supported)
  let regex = @regexp.compile("😀")
  let result = regex.execute("Happy 😀 face")
  guard result.matched()
  inspect(
    result.get(0),
    content=(
      #|Some("😀")
    ),
  )
}

///|
test "complex real-world patterns" {
  // Email validation (comprehensive)
  let email_regex = @regexp.compile(
    "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}",
  )
  inspect(
    email_regex.execute("user@example.com").results(),
    content=(
      #|[Some("user@example.com")]
    ),
  )
  inspect(
    email_regex.execute("test.email+tag@domain.co.uk").results(),
    content=(
      #|[Some("test.email+tag@domain.co.uk")]
    ),
  )
  inspect(email_regex.execute("invalid.email").matched(), content="false")

  // Phone number patterns
  let phone_regex = @regexp.compile("\\(?\\d{3}\\)?[ -.]?\\d{3}[-.]?\\d{4}")
  inspect(
    phone_regex.execute("(123)456-7890").results(),
    content=(
      #|[Some("(123)456-7890")]
    ),
  )
  inspect(
    phone_regex.execute("123.456.7890").results(),
    content=(
      #|[Some("123.456.7890")]
    ),
  )
  inspect(
    phone_regex.execute("1234567890").results(),
    content=(
      #|[Some("1234567890")]
    ),
  )

  // URL matching
  let url_regex = @regexp.compile("https?://[^\\s]+")
  inspect(
    url_regex.execute("Visit https://example.com for more").results(),
    content=(
      #|[Some("https://example.com")]
    ),
  )
  inspect(
    url_regex.execute("Go to http://test.org/path?query=1").results(),
    content=(
      #|[Some("http://test.org/path?query=1")]
    ),
  )

  // IP address validation
  let ip_regex = @regexp.compile(
    "\\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\b",
  )
  inspect(
    ip_regex.execute("Server IP: 192.168.1.1").results(),
    content=(
      #|[Some("192.168.1.1")]
    ),
  )

  // Credit card number (simple pattern)
  let cc_regex = @regexp.compile(
    "\\d{4}[-\\s]?\\d{4}[-\\s]?\\d{4}[-\\s]?\\d{4}",
  )
  inspect(
    cc_regex.execute("1234 5678 9012 3456").results(),
    content=(
      #|[Some("1234 5678 9012 3456")]
    ),
  )
  inspect(
    cc_regex.execute("1234-5678-9012-3456").results(),
    content=(
      #|[Some("1234-5678-9012-3456")]
    ),
  )

  // HTML tag matching
  let html_regex = @regexp.compile("<([a-zA-Z]+)[^>]*>(.*?)</\\1>")
  let result = html_regex.execute("<div class='test'>content</div>")
  inspect(
    result.get(1),
    content=(
      #|Some("div")
    ),
  )
  inspect(
    result.get(2),
    content=(
      #|Some("content")
    ),
  )
}

///|
test "edge cases and boundary conditions" {
  // Empty string matching
  let regex = @regexp.compile("")
  inspect(
    regex.execute("").results(),
    content=(
      #|[Some("")]
    ),
  )
  inspect(
    regex.execute("abc").results(),
    content=(
      #|[Some("")]
    ),
  )

  // Very long strings
  let long_string = "a".repeat(1000) + "b"
  let regex = @regexp.compile("a+b")
  inspect(
    regex.execute(long_string).results(),
    content=(
      #|[Some("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaab")]
    ),
  )

  // Pattern at string boundaries
  let regex = @regexp.compile("^a|b$")
  inspect(
    regex.execute("a").results(),
    content=(
      #|[Some("a")]
    ),
  )
  inspect(
    regex.execute("b").results(),
    content=(
      #|[Some("b")]
    ),
  )
  inspect(
    regex.execute("ab").results(),
    content=(
      #|[Some("a")]
    ),
  )
  inspect(regex.execute("ba").results(), content="[]")

  // Zero-width assertions
  let regex = @regexp.compile("\\b")
  let result = regex.execute("hello world")
  inspect(result.matched(), content="true")
  // Word boundaries are zero-width, so match should be empty string
  if result.matched() {
    inspect(result.get(0), content="Some(\"\")")
  }

  // Overlapping matches (should get first/leftmost)
  let regex = @regexp.compile("aa")
  inspect(
    regex.execute("aaa").results(),
    content=(
      #|[Some("aa")]
    ),
  )

  // Pattern with all quantifiers
  let regex = @regexp.compile("a*b+c?d{2}e{2,4}f{3,}")
  inspect(
    regex.execute("bbcddeeefffff").results(),
    content=(
      #|[Some("bbcddeeefffff")]
    ),
  )
}

///|
test "backreference" {
  let regex = @regexp.compile("((?:a|b)*)\\1\\1")
  inspect(
    regex.execute("aaabbb").results(),
    content=(
      #|[Some("aaa"), Some("a")]
    ),
  )
  inspect(
    regex.execute("aaa").results(),
    content=(
      #|[Some("aaa"), Some("a")]
    ),
  )
  inspect(
    regex.execute("aaaa").results(),
    content=(
      #|[Some("aaa"), Some("a")]
    ),
  )
  inspect(
    regex.execute("aaaaaa").results(),
    content=(
      #|[Some("aaaaaa"), Some("aa")]
    ),
  )

  // Example that needs exponential backtracking
  let regex = @regexp.compile("(?:((?:a|b)*)\\1\\1)+")
  inspect(
    regex.execute("aaabbb").results(),
    content=(
      #|[Some("aaabbb"), Some("b")]
    ),
  )

  // Palindrome detection
  let palindrome = @regexp.compile("^(.)(.)\\2\\1")
  inspect(
    palindrome.execute("abba").results(),
    content=(
      #|[Some("abba"), Some("a"), Some("b")]
    ),
  )
}

///|
test "invalid backreferences" {
  let regex = try? @regexp.compile("\\1000")
  inspect(
    regex.map(ignore),
    content=(
      #|Err(RegexpError(err=InvalidEscape, source_fragment="\\1000"))
    ),
  )
  let regex = try? @regexp.compile("\\01")
  inspect(
    regex.map(ignore),
    content=(
      #|Err(RegexpError(err=InvalidEscape, source_fragment="\\01"))
    ),
  )
}

///|
test "named backreferences with \\k<name>" {
  // Basic named backreference test
  let regex = @regexp.compile("(?<word>\\w+) \\k<word>")
  inspect(
    regex.execute("hello hello").results(),
    content=(
      #|[Some("hello hello"), Some("hello")]
    ),
  )
  inspect(regex.execute("hello world").matched(), content="false")

  // Multiple named backreferences
  let regex = @regexp.compile(
    "(?<first>\\w+) (?<second>\\w+) \\k<first> \\k<second>",
  )
  inspect(
    regex.execute("cat dog cat dog").results(),
    content=(
      #|[Some("cat dog cat dog"), Some("cat"), Some("dog")]
    ),
  )

  // Named backreference with repetition
  let regex = @regexp.compile("(?<char>.)\\k<char>{2}")
  inspect(
    regex.execute("aaa").results(),
    content=(
      #|[Some("aaa"), Some("a")]
    ),
  )
  inspect(regex.execute("abb").matched(), content="false")

  // Using \k<name> with alternation
  let regex = @regexp.compile("(?<tag>\\w+)\\s*\\|\\s*\\k<tag>")
  inspect(
    regex.execute("div | div").results(),
    content=(
      #|[Some("div | div"), Some("div")]
    ),
  )

  // HTML-like tag matching
  let regex = @regexp.compile("<(?<tag>[a-z]+)>.*?</\\k<tag>>")
  inspect(
    regex.execute("<div>content</div>").results(),
    content=(
      #|[Some("<div>content</div>"), Some("div")]
    ),
  )
  inspect(regex.execute("<div>content</span>").matched(), content="false")

  // Case-insensitive named backreference
  let regex = @regexp.compile("(?i:(?<word>[a-z]+) \\k<word>)")
  inspect(regex.execute("Hello HELLO").results(), content="[]")
}

///|
test "named backreference errors" {
  // Undefined name
  let regex = try? @regexp.compile("\\k<undefined>")
  inspect(
    regex.map(ignore),
    content=(
      #|Err(RegexpError(err=InvalidEscape, source_fragment="\\k<undefined>"))
    ),
  )

  // Recursive reference - reference to a capture group that is currently being defined
  let regex = try? @regexp.compile("(?<recur>.\\k<recur>)")
  inspect(
    regex.map(ignore),
    content=(
      #|Err(RegexpError(err=InvalidEscape, source_fragment="\\k<recur>)"))
    ),
  )

  // Reference to a named group that doesn't exist yet
  let regex = try? @regexp.compile("\\k<name> (?<name>\\w+)")
  inspect(
    regex.map(ignore),
    content=(
      #|Err(RegexpError(err=InvalidEscape, source_fragment="\\k<name> (?<name>\\w+)"))
    ),
  )

  // Invalid syntax for named backreference
  let regex = try? @regexp.compile("\\k<name")
  inspect(
    regex.map(ignore),
    content=(
      #|Err(RegexpError(err=InvalidEscape, source_fragment=""))
    ),
  )
  let regex = try? @regexp.compile("\\k name>")
  inspect(
    regex.map(ignore),
    content=(
      #|Err(RegexpError(err=InvalidEscape, source_fragment=" name>"))
    ),
  )
}

///|
test "unicode general category properties" {
  // Test Unicode property \p{L} (letter)
  let regex = @regexp.compile("\\p{Letter}+")
  inspect(
    regex.execute("Hello 世界").results(),
    content=(
      #|[Some("Hello")]
    ),
  )

  // Test Unicode property \p{N} (number)
  let regex = @regexp.compile("\\p{Number}+")
  inspect(
    regex.execute("123 and 456").results(),
    content=(
      #|[Some("123")]
    ),
  )

  // Test Unicode property \p{Z} (separator)
  let regex = @regexp.compile("\\p{Z}+")
  inspect(
    regex.execute("Hello 世界 ").results(),
    content=(
      #|[Some(" ")]
    ),
  )
}

///|
test "char classes" {
  // negated case insensitive
  let regex = @regexp.compile("(?i:[^a-z]+)")
  inspect(
    regex.execute("1234").results(),
    content=(
      #|[Some("1234")]
    ),
  )
  inspect(regex.execute("a").results(), content="[]")
  inspect(regex.execute("A").results(), content="[]")
  inspect(regex.execute("K").results(), content="[]")

  // digits
  let regex = @regexp.compile("[\\d]+")
  inspect(
    regex.execute("123abc").results(),
    content=(
      #|[Some("123")]
    ),
  )
  // non-digits
  let regex = @regexp.compile("[\\D]+")
  inspect(
    regex.execute("abc123").results(),
    content=(
      #|[Some("abc")]
    ),
  )

  // words
  let regex = @regexp.compile("[\\w]+")
  inspect(
    regex.execute("hello_world123 ").results(),
    content=(
      #|[Some("hello_world123")]
    ),
  )
  let regex = @regexp.compile("[\\W]+")
  inspect(
    regex.execute("中文abc").results(),
    content=(
      #|[Some("中文")]
    ),
  )

  // unicode properties
  let regex = @regexp.compile("[\\p{L}\\p{N}]+")
  inspect(
    regex.execute("Hello世界123\n").results(),
    content=(
      #|[Some("Hello世界123")]
    ),
  )
  let regex = @regexp.compile("[^\\p{L}\\p{N}]+")
  inspect(
    regex.execute("Hello世界123\n").results(),
    content=(
      #|[Some("\n")]
    ),
  )
  let regex = @regexp.compile("[\\P{L}]+")
  inspect(
    regex.execute("Hello世界123\n").results(),
    content=(
      #|[Some("123\n")]
    ),
  )
}
