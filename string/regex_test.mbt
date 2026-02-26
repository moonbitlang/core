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
test "execute/non_capture_group" {
  let regex = @string.Regex("(?:ab)(c)(?:d)")
  guard regex.execute("abcd") is Some(m) else { fail("Expected match") }
  inspect(m.group(0).unwrap(), content="abcd")
  inspect(m.group(1).unwrap(), content="c")
  inspect(m.group(2), content="None")
}

///|
test "execute/non_capture_with_named_group" {
  let regex = @string.Regex("(?:a)(b)(?:c)(?<d>d)")
  guard regex.execute("abcd") is Some(m) else { fail("Expected match") }
  inspect(m.group(1).unwrap(), content="b")
  inspect(m.group(2).unwrap(), content="d")
  inspect(m.named_group("d").unwrap(), content="d")
}

///|
test "execute/any_char_on_supplementary_plane" {
  let regex = @string.Regex(".")
  guard regex.execute("😀") is Some(m) else {
    fail("Expected match for supplementary-plane Unicode escape")
  }
  inspect(m.content(), content="😀")
}

///|
test "execute/range_crossing_surrogate_gap_has_no_half_match" {
  let regex = @string.Regex("[\\uD7FF-\\uE000]")
  guard regex.execute("😀") is None else {
    fail("Expected no surrogate-half match")
  }
}

///|
test "compile/error_unclosed_group" {
  guard (try? @string.Regex("(")) is Err(_) else {
    fail("Expected compile failure for unclosed group")
  }
}

///|
test "compile/error_unclosed_char_class" {
  guard (try? @string.Regex("[abc")) is Err(_) else {
    fail("Expected compile failure for unclosed char class")
  }
}

///|
test "compile/unicode_escape_supplementary_plane" {
  let regex = @string.Regex("\\u{1F600}")
  guard regex.execute("a😀b") is Some(m) else {
    fail("Expected match for supplementary-plane Unicode escape")
  }
  inspect(m.content(), content="😀")
}

///|
test "string/literal_metacharacters" {
  let regex = @string.Regex::string("a+b(c)")
  guard regex.execute("xa+b(c)y") is Some(m) else {
    fail("Expected literal match")
  }
  inspect(m.content(), content="a+b(c)")
  inspect(regex.execute("xabccy") is Some(_), content="false")
}

///|
test "repeat/greedy_and_nongreedy" {
  let base = @string.Regex("[[:digit:]]")
  let greedy = base.repeat(min=2, max=4)
  let nongreedy = base.repeat(min=2, max=4, greedy=false)
  guard greedy.execute("a12345") is Some(m1) else {
    fail("Expected greedy match")
  }
  guard nongreedy.execute("a12345") is Some(m2) else {
    fail("Expected non-greedy match")
  }
  inspect(m1.content(), content="1234")
  inspect(m2.content(), content="12")
}

///|
test "panic repeat/invalid_min_negative" {
  let base = @string.Regex("[[:digit:]]")
  ignore(base.repeat(min=-1))
}

///|
test "panic repeat/invalid_max_less_than_min" {
  let base = @string.Regex("[[:digit:]]")
  ignore(base.repeat(min=3, max=2))
}

///|
test "panic repeat/invalid_min_too_large" {
  let base = @string.Regex("[[:digit:]]")
  ignore(base.repeat(min=257))
}

///|
test "panic repeat/invalid_max_too_large" {
  let base = @string.Regex("[[:digit:]]")
  ignore(base.repeat(min=0, max=257))
}

///|
test "add/sequence" {
  let regex = @string.Regex::string("ab") + @string.Regex::string("cd")
  guard regex.execute("xxabcdyy") is Some(m) else {
    fail("Expected concatenated match")
  }
  inspect(m.content(), content="abcd")
}

///|
test "bitor/alternation" {
  let regex = @string.Regex::string("cat") | @string.Regex::string("dog")
  inspect(regex.execute("dog") is Some(_), content="true")
  inspect(regex.execute("cow") is Some(_), content="false")
}
