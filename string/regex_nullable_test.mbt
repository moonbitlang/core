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
test "nullable repetition preserves first alternative priority" {
  for
    pattern in [
      "^(?:|a)*", "^(?:|a)+", "^(?:|a){2,}", "^(?:|ab)*", "^(?:|a){0,2}",
    ] {
    let regex = @string.Regex(pattern)
    for input in ["", "a", "ab", "aa", "b"] {
      guard regex.execute(input) is Some(m) else { fail("expected a match") }
      assert_eq(m.content(), "", msg=pattern)
      assert_eq(m.after(), input, msg=pattern)
    }
  }
}

///|
test "nullable repetition retries consuming alternatives for its suffix" {
  for
    pattern in [
      "^(?:|a)*b", "^(?:|a)+b", "^(?:|a){2,}b", "^(?:|a)*?b", "^(?:|a)+?b",
    ] {
    let regex = @string.Regex(pattern)
    guard regex.execute("aab!") is Some(m) else { fail("expected a match") }
    assert_eq(m.content(), "aab", msg=pattern)
    assert_eq(m.after(), "!", msg=pattern)
  }
}

///|
test "nullable repetition preserves captures at the empty priority point" {
  let regex = @string.Regex("^(?<word>(?:|a)*)")
  guard regex.execute("aa") is Some(m) else { fail("expected a match") }
  assert_eq(m.group(0), Some(""))
  assert_eq(m.group(1), Some(""))
  assert_eq(m.after(), "aa")
}

///|
test "nullable repetition preserves loop priority after consuming input" {
  for pattern in ["^(?:a?|b)*", "^(?:a?|b)+", "^(?:a?|b){2,}", "^(?:(?:|a)*a)*"] {
    let regex = @string.Regex(pattern)
    let input = if pattern == "^(?:(?:|a)*a)*" { "aaa!" } else { "aab!" }
    for _ in 0..<2 {
      guard regex.execute(input) is Some(m) else { fail("expected a match") }
      let end = if pattern == "^(?:(?:|a)*a)*" { 3 } else { 2 }
      assert_eq(m.content(), input[0:end], msg=pattern)
      assert_eq(m.after(), input[end:], msg=pattern)
    }
  }
  let regex = @string.Regex("^(?<word>(?:a?|b)*)b")
  guard regex.execute("aabb!") is Some(m) else { fail("expected a match") }
  assert_eq(m.named_group("word"), Some("aa"))
  assert_eq(m.after(), "b!")
}

///|
test "nullable repetitions follow spec continuation priority" {
  for
    (pattern, input, expected, rest) in [
      ("^(?:a*?b*?)*a", "baaa", "ba", "aa"),
      ("^(?:a?|b)*$", "ab", "ab", ""),
      ("^(?:a?b??)*", "ab", "a", "b"),
      ("^(?:a?b??){2,}", "aab", "aa", "b"),
      ("^(?:a?b??){3,}", "ab", "a", "b"),
      ("^(?:a?b??){2,3}", "ab", "a", "b"),
      ("^(?:(?:a*?b*?)*a)*", "baaa!", "baaa", "!"),
      ("^(?:$|a)+?", "aa", "a", "a"),
    ] {
    let regex = @string.Regex(pattern)
    // Repeat execution also exercises cached transitions.
    for _ in 0..<2 {
      guard regex.execute(input) is Some(m) else { fail(pattern) }
      assert_eq(m.content(), expected, msg=pattern)
      assert_eq(m.after(), rest, msg=pattern)
    }
  }
}

///|
test "nullable repetition records the final empty iteration" {
  let regex = @string.Regex("^(?<body>(?<item>a*?b*?))*(?<tail>a)")
  guard regex.execute("baaa") is Some(m) else { fail("expected a match") }
  assert_eq(m.content(), "ba")
  assert_eq(m.after(), "aa")
  assert_eq(m.named_group("body"), Some(""))
  assert_eq(m.named_group("item"), Some(""))
  assert_eq(m.named_group("tail"), Some("a"))
}

///|
test "copied nullable repetitions retain continuation priority and captures" {
  for
    pattern in [
      "^(?:(?<item>a*?b*?)*a){2}", "^(?:(?<item>a*?b*?)+a){2}", "^(?:(?<item>a*?b*?)*a){0,2}",
      "^(?:(?<item>a*?b*?)+a){0,2}", "^(?:(?<item>a*?b*?)*a){2}?",
    ] {
    let regex = @string.Regex(pattern)
    for _ in 0..<2 {
      guard regex.execute("baaaa") is Some(m) else { fail(pattern) }
      assert_eq(m.content(), "baa", msg=pattern)
      assert_eq(m.after(), "aa", msg=pattern)
      assert_eq(m.named_group("item"), Some(""), msg=pattern)
    }
  }
  let regex = @string.Regex("^(?<item>a?){0}b")
  guard regex.execute("b!") is Some(m) else { fail("expected a match") }
  assert_eq(m.content(), "b")
  assert_eq(m.after(), "!")
  assert_eq(m.named_group("item"), None)
}

///|
test "nullable repetition retains consuming-first and non-greedy priority" {
  for pattern in ["^(?:a|)*", "^(?:a|)+", "^(?:a?)*", "^a*"] {
    let regex = @string.Regex(pattern)
    guard regex.execute("aa!") is Some(m) else { fail("expected a match") }
    assert_eq(m.content(), "aa", msg=pattern)
    assert_eq(m.after(), "!", msg=pattern)
  }
  for pattern in ["^(?:a|)*?", "^(?:|a)*?", "^(?:a?)*?"] {
    let regex = @string.Regex(pattern)
    guard regex.execute("aa!") is Some(m) else { fail("expected a match") }
    assert_eq(m.content(), "", msg=pattern)
    assert_eq(m.after(), "aa!", msg=pattern)
  }
}
