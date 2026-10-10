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
test "execute/nullable loops preserve ordered first-match paths" {
  let cases : Array[(String, String, String, String)] = [
    ("^(?:a*?b*?)*a", "baaa", "baa", "a"),
    ("^(?:a*?b*?)+a", "baaa", "baa", "a"),
    ("^(?:a*?b*?){2,}a", "baaa", "baa", "a"),
    ("^(?:a*?b*?){3,}a", "baaa", "baa", "a"),
    ("^(?:(?:a*?b*?)*a)*", "baaa!", "baaa", "!"),
    ("^(?:(?:|a)*a)*", "aaa!", "aaa", "!"),
    ("^(?:a?b??)*", "ab", "a", "b"),
    ("^(?:a?b??)+", "ab", "a", "b"),
    ("^(?:a?b??){2,}", "aab", "aa", "b"),
    ("^(?:a?b??){3,}", "ab", "a", "b"),
    ("^(?:a?b??){2,3}", "ab", "a", "b"),
    ("^(?:a*?b*?)*b", "abb", "ab", "b"),
    ("^(?:(?:|a)(?:|b))*b", "abb", "ab", "b"),
    ("^(?:$|a)+?", "aa", "a", "a"),
    ("^(?:a?|b)*$", "ab", "ab", ""),
    ("^(?:(?:)*)*", "aa", "", "aa"),
    ("^(?:(?:a?)*)*b", "aab!", "aab", "!"),
    ("^(?:|a){2,3}b", "aab!", "aab", "!"),
    ("^a*b", "aab!", "aab", "!"),
    ("^a*?b", "aab!", "aab", "!"),
    (
      "^(?:\u{1F600}*?b*?)*\u{1F600}", "b\u{1F600}\u{1F600}\u{1F600}", "b\u{1F600}\u{1F600}",
      "\u{1F600}",
    ),
  ]
  for (pattern, input, expected, after) in cases {
    let regex = @string.Regex(pattern)
    for _ in 0..<2 {
      guard regex.execute(input) is Some(m) else { fail(pattern) }
      if m.content().to_owned() != expected {
        fail("wrong match: " + pattern + " got=" + m.content().to_owned())
      }
      assert_eq(m.after().to_owned(), after)
    }
  }
}

///|
test "execute/nullable-loop captures follow the selected path" {
  let cases : Array[(String, String, String, String, Array[String?])] = [
    (
      "^(?<body>(?<item>a*?b*?))*(?<tail>a)",
      "baaa",
      "baa",
      "a",
      [Some("a"), Some("a"), Some("a")],
    ),
    ("^(?<body>(?<item>(?:|a)))*", "aa", "", "aa", [Some(""), Some("")]),
    ("^(?<body>(?<item>(?:|a)))+", "aa", "", "aa", [Some(""), Some("")]),
    ("^(?<item>a?){0}b", "b!", "b", "!", [None]),
    ("^(?:(?<item>a*?b*?)*a){2}", "baaaa", "baaa", "a", [Some("")]),
    ("^(?:(?<item>a*?b*?)+a){2}", "baaaa", "baaa", "a", [Some("")]),
    ("^(?:(?<item>a*?b*?)*a){0,2}", "baaaa", "baaa", "a", [Some("")]),
    ("^(?:(?<item>a*?b*?)+a){0,2}", "baaaa", "baaa", "a", [Some("")]),
    ("^(?:(?<item>a*?b*?)*a){2}?", "baaaa", "baaa", "a", [Some("")]),
    ("^(?<body>(?<item>a?))*$", "a", "a", "", [Some("a"), Some("a")]),
    ("^(?<item>a?|b)*b", "aabb!", "aabb", "!", [Some("b")]),
  ]
  for (pattern, input, expected, after, captures) in cases {
    let regex = @string.Regex(pattern)
    for _ in 0..<2 {
      guard regex.execute(input) is Some(m) else { fail(pattern) }
      assert_eq(m.content().to_owned(), expected)
      assert_eq(m.after().to_owned(), after)
      for i, capture in captures {
        assert_eq(m.group(i + 1).map(v => v.to_owned()), capture)
      }
    }
  }
}

///|
test "execute/nullable loop modes and counts retain first-match priority" {
  for (body, greedy) in [("|a", ""), ("a|", "aa"), ("a?", "aa"), ("a*?b*?", "")] {
    for quantifier in ["*", "+", "{2,}", "{2,}?", "{2,3}", "{2,3}?"] {
      let regex = @string.Regex("^(?:\{body})\{quantifier}")
      guard regex.execute("aa!") is Some(m) else { fail(body) }
      assert_eq(m.content().to_owned(), greedy)
      guard regex.execute("") is Some(m) else { fail(body) }
      assert_eq(m.content().to_owned(), "")
    }
    guard @string.Regex("^(?:\{body})*?").execute("aa!") is Some(m) else {
      fail(body)
    }
    assert_eq(m.content().to_owned(), "")
    guard @string.Regex("^(?:\{body})+?").execute("aa!") is Some(m) else {
      fail(body)
    }
    assert_eq(m.content().to_owned(), if greedy == "" { "" } else { "a" })
  }
}

///|
test "execute/deep nullable loops preserve first-match traversal" {
  for prefix_length in [0, 600] {
    let mut repeated = @string.Regex("a?")
    for _ in 0..<800 {
      repeated = repeated.repeat(min=0, greedy=true)
    }
    let prefix = "x".repeat(prefix_length)
    let regex = @string.Regex("^") + @string.Regex::string(prefix) + repeated
    let input = prefix + "aa"
    for _ in 0..<2 {
      guard regex.execute(input) is Some(m) else { fail("expected a match") }
      assert_eq(m.content().to_owned(), input)
      assert_eq(m.after().length(), 0)
    }
  }
}
