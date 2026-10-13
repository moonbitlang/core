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
fn matched(pattern : String, input : String) -> String {
  match @string.Regex::unsafe_from_string(pattern).execute(input) {
    None => "no match"
    Some(m) => "[\{m.before()}](\{m.content()})[\{m.after()}]"
  }
}

///|
/// Repeating a body that can match the empty string follows the compiler's
/// construction: `x*` is built as `(x+)?`, and an iteration that would loop
/// back without consuming input ends the repetition. These are the results
/// compile-time `lexmatch` and `=~` give for the same patterns;
/// the engine used before this one answered `(a)`, `(a xac)` and `(aaa)` for
/// the first three.
test "nullable repetition matches compile-time lexmatch" {
  inspect(matched("(((a)){0,2}?)+", "a"), content="[]()[a]")
  inspect(matched("([a-c]|[^😀]{0,2}?){2,}", "a xac"), content="[](a)[ xac]")
  inspect(matched("((a{0,2}?){0,2}?){2,}", "aaaba"), content="[]()[aaaba]")
  inspect(matched("(?:a*)*b", "aaab"), content="[](aaab)[]")
  inspect(matched("(?:a|)*", "aa"), content="[](aa)[]")
  inspect(matched("(?:|a)*", "aa"), content="[]()[aa]")
}

///|
test "captures inside repetitions keep the last iteration" {
  let re = @string.Regex::unsafe_from_string("(?:(a)|(b))+")
  guard re.execute("aab") is Some(m) else { fail("expected a match") }
  debug_inspect(
    (m.group(0), m.group(1), m.group(2)),
    content=(
      #|(
      #|  Some(<StringView: "aab">),
      #|  Some(<StringView: "a">),
      #|  Some(<StringView: "b">),
      #|)
    ),
  )
  let re = @string.Regex::unsafe_from_string("([ab]*)*")
  guard re.execute("ab") is Some(m) else { fail("expected a match") }
  // The repetition stops instead of adding an empty iteration.
  debug_inspect(
    m.group(1),
    content=(
      #|Some(<StringView: "ab">)
    ),
  )
}

///|
/// The runtime counterparts of the compiler's Unicode scalar tests for
/// `lexmatch` (`check_unicode_scalars` and `check_unicode_negation` in
/// `test/pipeline_test/lexmatch_first.mbt`): `.` and negated classes consume
/// whole scalars and never half of a surrogate pair.
test "unicode scalars are never split" {
  for c in ['😀', '𠮷', '\u{10000}', '\u{10FFFF}', '\u{D7FF}', '\u{E000}'] {
    let input = c.to_string()
    inspect(matched("^..$", input), content="no match")
    let re = @string.Regex::unsafe_from_string("^(?<prefix>.*)(?<last>.$)")
    guard re.execute(input) is Some(m) else { fail("expected a match") }
    assert_true(m.named_group("prefix") is Some(""))
    assert_true(m.named_group("last") is Some(last) && last == input)
    let padded = "!" + input + "?"
    let view = padded[1:1 + input.length()]
    let re = @string.Regex::unsafe_from_string("^.$")
    assert_true(re.execute(view) is Some(m) && m.content() == input)
    let re = @string.Regex::unsafe_from_string("^.")
    assert_true(re.execute(input) is Some(m) && m.after().length() == 0)
  }
  inspect(matched("^.", ""), content="no match")
  inspect(matched("^$", ""), content="[]()[]")
  inspect(matched("^[^😀]+$", "😀"), content="no match")
  inspect(matched("^[^𠮷]+$", "𠮷"), content="no match")
  inspect(matched("^..$", "😀a"), content="[](😀a)[]")
  inspect(matched("[^😀]", "😀𠮷!"), content="[😀](𠮷)[!]")
  inspect(matched("(x*?){2,}[^😀]", "😀xxb\n"), content="[😀](x)[xb\n]")
}

///|
test "last_index keeps anchors and word boundaries relative to the input" {
  let re = @string.Regex::unsafe_from_string("^ab")
  assert_true(re.execute("abab", last_index=0) is Some(_))
  assert_true(re.execute("abab", last_index=2) is None)
  let re = @string.Regex::unsafe_from_string("\\bab")
  assert_true(
    re.execute("xab ab", last_index=1) is Some(m) && m.before() == "xab ",
  )
  let re = @string.Regex::unsafe_from_string("b$")
  assert_true(re.execute("ab", last_index=2) is None)
  let re = @string.Regex::unsafe_from_string("$")
  assert_true(re.execute("ab", last_index=2) is Some(m) && m.before() == "ab")
}

///|
/// Building the automaton must not recurse once per alternative.
test "wide alternations" {
  let mut words = @string.Regex::string("w0;")
  for i in 1..<400 {
    words = words | @string.Regex::string("w\{i};")
  }
  assert_true(words.execute("...w399;...") is Some(m) && m.content() == "w399;")
  assert_true(words.execute("...w400;...") is None)
}

///|
/// A periodic literal keeps one thread alive per period, so every DFA state
/// is large and distinct. The cache budget keeps memory flat regardless.
test "many simultaneous threads stay within the cache budget" {
  let literal = "ab".repeat(3000)
  let re = @string.Regex::string(literal + "c")
  assert_true(re.execute(literal + literal) is None)
  assert_true(re.execute("ab" + literal + "c") is Some(m) && m.before() == "ab")
}

///|
test "one regex can serve interleaved searches" {
  let re = @string.Regex::unsafe_from_string("([a-z]+)=([0-9]+)")
  let outer = re.find("a=1 bb=22 ccc=333")
  let seen = []
  for m in outer {
    // Run another search on the same regex while iterating.
    guard re.execute("zz=9") is Some(inner) else { fail("expected a match") }
    seen.push(
      "\{m.group(1).unwrap()}:\{m.group(2).unwrap()}/\{inner.content()}",
    )
  }
  inspect(seen.join(" "), content="a:1/zz=9 bb:22/zz=9 ccc:333/zz=9")
}

///|
/// A negated class inside `(?i:...)` folds case before it is complemented:
/// `(?i:[^a-c])` matches none of `a`, `A`, `b`, `B`, `c`, `C`. It used to
/// match all of them, because folding the complement put them back.
test "a negated class in a case-insensitive group" {
  let folded = @string.Regex("^(?i:[^a-c])$")
  assert_true(folded.execute("a") is None)
  assert_true(folded.execute("B") is None)
  assert_true(folded.execute("d") is Some(_))
  assert_true(folded.execute("D") is Some(_))
  // Outside the group nothing is folded.
  let plain = @string.Regex("^[^a-c]$")
  assert_true(plain.execute("a") is None)
  assert_true(plain.execute("A") is Some(_))
  // A class that is not negated is unchanged.
  let positive = @string.Regex("^(?i:[a-c])$")
  assert_true(positive.execute("B") is Some(_))
  assert_true(positive.execute("d") is None)
}
