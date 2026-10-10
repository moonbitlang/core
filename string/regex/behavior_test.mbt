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
test "regex matches the first search result" {
  let re = @regex.Regex("[[:digit:]]+")
  guard re.execute("x12y34") is Some(m) else { fail("missing match") }
  inspect(m.content(), content="12")
  guard re.execute("x12y34", last_index=3) is Some(m) else {
    fail("missing second match")
  }
  inspect(m.content(), content="34")
}

///|
test "regex preserves capture groups" {
  let re = @regex.Regex("(?<name>[[:alpha:]]+)-([[:digit:]]+)")
  guard re.execute("id=moon-123") is Some(m) else { fail("missing match") }
  debug_inspect(m.named_group("name"), content="Some(<StringView: \"moon\">)")
  debug_inspect(m.group(2), content="Some(<StringView: \"123\">)")
}

///|
test "regex honors greedy and non-greedy repetition" {
  let greedy = @regex.Regex("[[:digit:]]{2,4}")
  let nongreedy = @regex.Regex("[[:digit:]]{2,4}?")
  guard greedy.execute("a12345") is Some(g) else { fail("missing greedy") }
  guard nongreedy.execute("a12345") is Some(l) else {
    fail("missing non-greedy")
  }
  inspect(g.content(), content="1234")
  inspect(l.content(), content="12")
}

///|
test "regex handles anchors and unicode" {
  inspect(@regex.Regex("^ab$").execute("ab") is Some(_), content="true")
  inspect(@regex.Regex("^ab$").execute("xaby") is None, content="true")
  let re = @regex.Regex("😀+")
  guard re.execute("x😀😀y") is Some(m) else {
    fail("missing unicode match")
  }
  inspect(m.content(), content="😀😀")
}

///|
test "regex exposes the same combinators" {
  let re = @regex.Regex::string("ab") + @regex.Regex::string("cd")
  inspect(re.execute("xabcd") is Some(_), content="true")
  let alt = @regex.Regex::string("cat") | @regex.Regex::string("dog")
  inspect(alt.execute("dog") is Some(_), content="true")
}

///|
test "regex retains an accepted candidate until higher priorities fail" {
  let re = @regex.Regex("(?:(a.*z)|(a))")
  guard re.execute("abc") is Some(fallback) else { fail("missing fallback") }
  inspect(fallback.content(), content="a")
  debug_inspect(fallback.group(1), content="None")
  debug_inspect(fallback.group(2), content="Some(<StringView: \"a\">)")
  guard re.execute("abcz") is Some(preferred) else { fail("missing preferred") }
  inspect(preferred.content(), content="abcz")
  debug_inspect(preferred.group(1), content="Some(<StringView: \"abcz\">)")
  debug_inspect(preferred.group(2), content="None")
  // An old result remains valid after the shared automaton runs again.
  inspect(fallback.content(), content="a")
}

///|
test "regex greedy nullable loops preserve the final empty capture" {
  let re = @regex.Regex("(a*)*")
  guard re.execute("aa") is Some(m) else { fail("missing match") }
  inspect(m.content(), content="aa")
  debug_inspect(m.group(1), content="Some(<StringView: \"\">)")
}
