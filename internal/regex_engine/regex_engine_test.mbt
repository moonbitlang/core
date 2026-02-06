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
let profile : @regex_engine.Profile = @regex_engine.Profile::new(
  valid=@regex_engine.RecharSet::char_range(0, 0x10FFFF),
  word=@regex_engine.RecharSet::char_range('a', 'z') +
    @regex_engine.RecharSet::char_range('A', 'Z') +
    @regex_engine.RecharSet::char_range('0', '9') +
    @regex_engine.RecharSet::char('_'),
  category=c => {
    match c {
      'a'..='z' | 'A'..='Z' | '0'..='9' | '_' => @regex_engine.Category::word()
      '\n' => @regex_engine.Category::newline()
      _ => @regex_engine.Category::not_word()
    }
  },
)

///|
let profile_ascii : @regex_engine.Profile = @regex_engine.Profile::new(
  valid=@regex_engine.RecharSet::char_range(0, 0x7f),
  word=@regex_engine.RecharSet::char_range('a', 'z') +
    @regex_engine.RecharSet::char_range('A', 'Z') +
    @regex_engine.RecharSet::char_range('0', '9') +
    @regex_engine.RecharSet::char('_'),
  category=c => {
    match c {
      'a'..='z' | 'A'..='Z' | '0'..='9' | '_' => @regex_engine.Category::word()
      '\n' => @regex_engine.Category::newline()
      _ => @regex_engine.Category::not_word()
    }
  },
)

///|
test "abc" {
  let pat = @regex_engine.seq([
    @regex_engine.char(@regex_engine.RecharSet::char('a')),
    @regex_engine.char(@regex_engine.RecharSet::char('b')),
    @regex_engine.char(@regex_engine.RecharSet::char('c')),
  ])
  let re = @regex_engine.compile(profile~, pat)
  guard re.execute("abc"[:], 0) is Some(result) else { fail("Expected match") }
  assert_eq(result.group(0), Some((0, 3)))
  assert_eq(result.group(1), None)
}

///|
test "anchored start-of-input mismatch" {
  let pat = @regex_engine.seq([
    @regex_engine.start_of_input,
    @regex_engine.char(@regex_engine.RecharSet::char('a')),
  ])
  let re = @regex_engine.compile(profile~, pat)
  assert_true(re.execute("b"[:], 0) is None)
}

///|
test "execute with lastIndex and cached transitions/start-state" {
  let pat = @regex_engine.char(@regex_engine.RecharSet::char('a'))
  let re = @regex_engine.compile(profile~, pat)
  guard re.execute("ba"[:], 1) is Some(mr) else { fail("Expected match") }
  assert_eq(mr.group(0), Some((1, 2)))
  // second run hits cached start state + transition
  guard re.execute("ba"[:], 1) is Some(mr2) else { fail("Expected match") }
  assert_eq(mr2.group(0), Some((1, 2)))
}

///|
test "alternation compiles and matches" {
  let pat = @regex_engine.alt([
    @regex_engine.char(@regex_engine.RecharSet::char('a')),
    @regex_engine.char(@regex_engine.RecharSet::char('b')),
  ])
  let re = @regex_engine.compile(profile~, pat)
  guard re.execute("b"[:], 0) is Some(mr) else { fail("Expected match") }
  assert_eq(mr.group(0), Some((0, 1)))
}

///|
test "finite quantifiers greedy vs non-greedy compile" {
  let a = @regex_engine.char(@regex_engine.RecharSet::char('a'))
  let greedy = @regex_engine.quantifier(a, {
    min: 0,
    max: Some(2),
    mode: Greedy,
  })
  let pat1 = @regex_engine.seq([greedy, a])
  let re1 = @regex_engine.compile(profile~, pat1)
  guard re1.execute("aa"[:], 0) is Some(_mr) else { fail("Expected match") }
  let nongreedy = @regex_engine.quantifier(a, {
    min: 0,
    max: Some(2),
    mode: NonGreedy,
  })
  let pat2 = @regex_engine.seq([nongreedy, a])
  let re2 = @regex_engine.compile(profile~, pat2)
  guard re2.execute("aa"[:], 0) is Some(_mr) else { fail("Expected match") }
}

///|
test "epsilon in sequences (translate eps optimizations)" {
  let a = @regex_engine.char(@regex_engine.RecharSet::char('a'))
  let pat1 = @regex_engine.seq([
    @regex_engine.start_of_input, a, @regex_engine.end_of_input, @regex_engine.epsilon,
  ])
  let re1 = @regex_engine.compile(profile~, pat1)
  guard re1.execute("a"[:], 0) is Some(mr1) else { fail("Expected match") }
  assert_eq(mr1.group(0), Some((0, 1)))
  let pat2 = @regex_engine.seq([
    @regex_engine.start_of_input, @regex_engine.epsilon, a, @regex_engine.end_of_input,
  ])
  let re2 = @regex_engine.compile(profile~, pat2)
  guard re2.execute("a"[:], 0) is Some(mr2) else { fail("Expected match") }
  assert_eq(mr2.group(0), Some((0, 1)))
}

///|
test "line assertions" {
  let a = @regex_engine.char(@regex_engine.RecharSet::char('a'))

  // StartOfLine should match after newline.
  let pat1 = @regex_engine.seq([@regex_engine.start_of_line, a])
  let re1 = @regex_engine.compile(profile~, pat1)
  guard re1.execute("\na"[:], 0) is Some(mr1) else { fail("Expected match") }
  assert_eq(mr1.group(0), Some((1, 2)))

  // EndOfLine is a lookahead (needs next-cat check).
  let pat2 = @regex_engine.seq([a, @regex_engine.end_of_line])
  let re2 = @regex_engine.compile(profile~, pat2)
  guard re2.execute("a\n"[:], 0) is Some(mr2) else { fail("Expected match") }
  assert_eq(mr2.group(0), Some((0, 1)))
}

///|
test "word boundary assertions" {
  let a = @regex_engine.char(@regex_engine.RecharSet::char('a'))
  let b = @regex_engine.char(@regex_engine.RecharSet::char('b'))
  let pat1 = @regex_engine.seq([@regex_engine.start_of_word, a])
  let re1 = @regex_engine.compile(profile~, pat1)
  guard re1.execute("a"[:], 0) is Some(mr1) else { fail("Expected match") }
  assert_eq(mr1.group(0), Some((0, 1)))
  let pat2 = @regex_engine.seq([a, @regex_engine.end_of_word])
  let re2 = @regex_engine.compile(profile~, pat2)
  guard re2.execute("a!"[:], 0) is Some(mr2) else { fail("Expected match") }
  assert_eq(mr2.group(0), Some((0, 1)))
  assert_true(re2.execute("ab"[:], 0) is None)
  let pat3 = @regex_engine.seq([a, @regex_engine.not_word_boundary, b])
  let re3 = @regex_engine.compile(profile~, pat3)
  guard re3.execute("ab"[:], 0) is Some(mr3) else { fail("Expected match") }
  assert_eq(mr3.group(0), Some((0, 2)))
}

///|
test "bytesview input" {
  let pat = @regex_engine.char(@regex_engine.RecharSet::char('a'))
  let re = @regex_engine.compile(profile=profile_ascii, pat)
  guard re.execute(b"a"[:], 0) is Some(mr) else { fail("Expected match") }
  assert_eq(mr.group(0), Some((0, 1)))
}

///|
test "quantifier min > 0 uses iter step" {
  let a = @regex_engine.char(@regex_engine.RecharSet::char('a'))
  let pat = @regex_engine.seq([
    @regex_engine.start_of_input,
    @regex_engine.quantifier(a, { min: 2, max: Some(3), mode: Greedy }),
    @regex_engine.end_of_input,
  ])
  let re = @regex_engine.compile(profile~, pat)
  guard re.execute("aa"[:], 0) is Some(mr) else { fail("Expected match") }
  assert_eq(mr.group(0), Some((0, 2)))
}

///|
test "preference node triggers enforce_pref(First, k)" {
  let a = @regex_engine.char(@regex_engine.RecharSet::char('a'))
  let b = @regex_engine.char(@regex_engine.RecharSet::char('b'))
  let c = @regex_engine.char(@regex_engine.RecharSet::char('c'))
  let pat = @regex_engine.seq([
    @regex_engine.start_of_input,
    @regex_engine.alt([
      @regex_engine.shortest(@regex_engine.seq([a, b])),
      @regex_engine.seq([a, c]),
    ]),
    @regex_engine.end_of_input,
  ])
  let re = @regex_engine.compile(profile~, pat)
  guard re.execute("ab"[:], 0) is Some(mr) else { fail("Expected match") }
  assert_eq(mr.group(0), Some((0, 2)))
}

///|
test "Regex::group_names includes capture name" {
  let a = @regex_engine.char(@regex_engine.RecharSet::char('a'))
  let pat = @regex_engine.seq([
    @regex_engine.start_of_input,
    @regex_engine.capture(name="x", a),
    @regex_engine.end_of_input,
  ])
  let re = @regex_engine.compile(profile~, pat)
  let names = re.group_names()
  assert_eq(names.length(), 2)
  assert_eq(names[0], None)
  assert_eq(names[1], Some("x"))
}
