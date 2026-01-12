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
using @regex_engine {
  type RecharSet,
  type Profile,
  type Category,
  capture,
  epsilon,
  char,
  seq,
  alt,
  quantifier,
  shortest,
  start_of_input,
  end_of_input,
  start_of_line,
  end_of_line,
  start_of_word,
  end_of_word,
  not_word_boundary,
  compile,
}

///|
let profile : Profile = Profile::new(
  valid=RecharSet::char_range(0, 0x10FFFF),
  word=RecharSet::char_range('a', 'z') +
    RecharSet::char_range('A', 'Z') +
    RecharSet::char_range('0', '9') +
    RecharSet::char('_'),
  space=RecharSet::char(' ') +
    RecharSet::char('\t') +
    RecharSet::char('\n') +
    RecharSet::char('\r') +
    RecharSet::char('\u{000B}') +
    RecharSet::char('\f'),
  digit=RecharSet::char_range('0', '9'),
  line_terminator=RecharSet::char('\n'),
  case_insensitive=cs => cs +
    (cs & RecharSet::char_range('A', 'Z')).offset_by(it => it + 32) +
    (cs & RecharSet::char_range('a', 'z')).offset_by(it => it - 32),
  category=c => match c {
    'a'..='z' | 'A'..='Z' | '0'..='9' | '_' => Category::word()
    '\n' => Category::newline()
    _ => Category::not_word()
  },
)

///|
let profile_ascii : Profile = Profile::new(
  valid=RecharSet::char_range(0, 0x7f),
  word=RecharSet::char_range('a', 'z') +
    RecharSet::char_range('A', 'Z') +
    RecharSet::char_range('0', '9') +
    RecharSet::char('_'),
  space=RecharSet::char(' ') +
    RecharSet::char('\t') +
    RecharSet::char('\n') +
    RecharSet::char('\r') +
    RecharSet::char('\u{000B}') +
    RecharSet::char('\f'),
  digit=RecharSet::char_range('0', '9'),
  line_terminator=RecharSet::char('\n'),
  case_insensitive=cs => cs +
    (cs & RecharSet::char_range('A', 'Z')).offset_by(it => it + 32) +
    (cs & RecharSet::char_range('a', 'z')).offset_by(it => it - 32),
  category=c => match c {
    'a'..='z' | 'A'..='Z' | '0'..='9' | '_' => Category::word()
    '\n' => Category::newline()
    _ => Category::not_word()
  },
)

///|
test "abc" {
  let pat = seq([
    char(RecharSet::char('a')),
    char(RecharSet::char('b')),
    char(RecharSet::char('c')),
  ])
  let re = compile(profile~, pat)
  guard re.execute("abc"[:], 0) is Some(result) else { fail("Expected match") }
  assert_eq(result.group(0), Some((0, 3)))
  assert_eq(result.group(1), None)
}

///|
test "anchored start-of-input mismatch" {
  let pat = seq([start_of_input, char(RecharSet::char('a'))])
  let re = compile(profile~, pat)
  assert_true(re.execute("b"[:], 0) is None)
}

///|
test "execute with lastIndex and cached transitions/start-state" {
  let pat = char(RecharSet::char('a'))
  let re = compile(profile~, pat)
  guard re.execute("ba"[:], 1) is Some(mr) else { fail("Expected match") }
  assert_eq(mr.group(0), Some((1, 2)))
  // second run hits cached start state + transition
  guard re.execute("ba"[:], 1) is Some(mr2) else { fail("Expected match") }
  assert_eq(mr2.group(0), Some((1, 2)))
}

///|
test "alternation compiles and matches" {
  let pat = alt([char(RecharSet::char('a')), char(RecharSet::char('b'))])
  let re = compile(profile~, pat)
  guard re.execute("b"[:], 0) is Some(mr) else { fail("Expected match") }
  assert_eq(mr.group(0), Some((0, 1)))
}

///|
test "finite quantifiers greedy vs non-greedy compile" {
  let a = char(RecharSet::char('a'))
  let greedy = quantifier(a, { min: 0, max: Some(2), mode: Greedy })
  let pat1 = seq([greedy, a])
  let re1 = compile(profile~, pat1)
  guard re1.execute("aa"[:], 0) is Some(_mr) else { fail("Expected match") }
  let nongreedy = quantifier(a, { min: 0, max: Some(2), mode: NonGreedy })
  let pat2 = seq([nongreedy, a])
  let re2 = compile(profile~, pat2)
  guard re2.execute("aa"[:], 0) is Some(_mr) else { fail("Expected match") }
}

///|
test "epsilon in sequences (translate eps optimizations)" {
  let a = char(RecharSet::char('a'))
  let pat1 = seq([start_of_input, a, end_of_input, epsilon])
  let re1 = compile(profile~, pat1)
  guard re1.execute("a"[:], 0) is Some(mr1) else { fail("Expected match") }
  assert_eq(mr1.group(0), Some((0, 1)))
  let pat2 = seq([start_of_input, epsilon, a, end_of_input])
  let re2 = compile(profile~, pat2)
  guard re2.execute("a"[:], 0) is Some(mr2) else { fail("Expected match") }
  assert_eq(mr2.group(0), Some((0, 1)))
}

///|
test "line assertions" {
  let a = char(RecharSet::char('a'))

  // StartOfLine should match after newline.
  let pat1 = seq([start_of_line, a])
  let re1 = compile(profile~, pat1)
  guard re1.execute("\na"[:], 0) is Some(mr1) else { fail("Expected match") }
  assert_eq(mr1.group(0), Some((1, 2)))

  // EndOfLine is a lookahead (needs next-cat check).
  let pat2 = seq([a, end_of_line])
  let re2 = compile(profile~, pat2)
  guard re2.execute("a\n"[:], 0) is Some(mr2) else { fail("Expected match") }
  assert_eq(mr2.group(0), Some((0, 1)))
}

///|
test "word boundary assertions" {
  let a = char(RecharSet::char('a'))
  let b = char(RecharSet::char('b'))
  let pat1 = seq([start_of_word, a])
  let re1 = compile(profile~, pat1)
  guard re1.execute("a"[:], 0) is Some(mr1) else { fail("Expected match") }
  assert_eq(mr1.group(0), Some((0, 1)))
  let pat2 = seq([a, end_of_word])
  let re2 = compile(profile~, pat2)
  guard re2.execute("a!"[:], 0) is Some(mr2) else { fail("Expected match") }
  assert_eq(mr2.group(0), Some((0, 1)))
  assert_true(re2.execute("ab"[:], 0) is None)
  let pat3 = seq([a, not_word_boundary, b])
  let re3 = compile(profile~, pat3)
  guard re3.execute("ab"[:], 0) is Some(mr3) else { fail("Expected match") }
  assert_eq(mr3.group(0), Some((0, 2)))
}

///|
test "bytesview input" {
  let pat = char(RecharSet::char('a'))
  let re = compile(profile=profile_ascii, pat)
  guard re.execute(b"a"[:], 0) is Some(mr) else { fail("Expected match") }
  assert_eq(mr.group(0), Some((0, 1)))
}

///|
test "quantifier min > 0 uses iter step" {
  let a = char(RecharSet::char('a'))
  let pat = seq([
    start_of_input,
    quantifier(a, { min: 2, max: Some(3), mode: Greedy }),
    end_of_input,
  ])
  let re = compile(profile~, pat)
  guard re.execute("aa"[:], 0) is Some(mr) else { fail("Expected match") }
  assert_eq(mr.group(0), Some((0, 2)))
}

///|
test "preference node triggers enforce_pref(First, k)" {
  let a = char(RecharSet::char('a'))
  let b = char(RecharSet::char('b'))
  let c = char(RecharSet::char('c'))
  let pat = seq([
    start_of_input,
    alt([shortest(seq([a, b])), seq([a, c])]),
    end_of_input,
  ])
  let re = compile(profile~, pat)
  guard re.execute("ab"[:], 0) is Some(mr) else { fail("Expected match") }
  assert_eq(mr.group(0), Some((0, 2)))
}

///|
test "Regex::group_names includes capture name" {
  let a = char(RecharSet::char('a'))
  let pat = seq([start_of_input, capture(name="x", a), end_of_input])
  let re = compile(profile~, pat)
  let names = re.group_names()
  assert_eq(names.length(), 2)
  assert_eq(names[0], None)
  assert_eq(names[1], Some("x"))
}
