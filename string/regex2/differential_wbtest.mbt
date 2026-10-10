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
let profile : @re.Profile = Profile(
  valid=@re.RecharSet::char_range(0, 0x10FFFF),
  word=@re.RecharSet::char_range('a', 'z') +
    @re.RecharSet::char_range('A', 'Z') +
    @re.RecharSet::char_range('0', '9') +
    @re.RecharSet::char('_'),
  category=c => {
    match c {
      'a'..='z' | 'A'..='Z' | '0'..='9' | '_' => @re.Category::word()
      '\n' => @re.Category::newline()
      _ => @re.Category::not_word()
    }
  },
)

///|
test "ordered captures agree with the existing engine" {
  let a = @re.char(@re.RecharSet::char('a'))
  let b = @re.char(@re.RecharSet::char('b'))
  let empty_a = @re.quantifier(a, { min: 0, max: None, mode: Greedy, })
  let nongreedy_a = @re.quantifier(a, { min: 0, max: None, mode: NonGreedy, })
  let pats = [
    @re.epsilon,
    @re.empty,
    a,
    @re.capture(a),
    @re.seq([@re.capture(empty_a), @re.capture(empty_a)]),
    @re.seq([@re.capture(nongreedy_a), @re.capture(empty_a)]),
    @re.alt([@re.capture(a), @re.capture(a)]),
    @re.quantifier(@re.capture(a), { min: 0, max: None, mode: Greedy, }),
    @re.quantifier(@re.capture(empty_a), { min: 0, max: None, mode: Greedy, }),
    @re.quantifier(@re.capture(empty_a), { min: 0, max: None, mode: NonGreedy, }),
    @re.quantifier(@re.capture(@re.alt([a, @re.seq([a, b])])), {
      min: 0,
      max: None,
      mode: Greedy,
    }),
    @re.seq([
      @re.quantifier(@re.capture(a), { min: 0, max: Some(3), mode: Greedy, }),
      @re.capture(empty_a),
    ]),
    @re.seq([@re.capture(@re.alt([a, @re.epsilon])), @re.capture(b)]),
    @re.seq([
      @re.start_of_input,
      @re.capture(empty_a),
      @re.capture(@re.quantifier(b, { min: 0, max: None, mode: Greedy, })),
      @re.end_of_input,
    ]),
    @re.seq([@re.start_of_word, @re.capture(a), @re.end_of_word]),
    @re.seq([@re.start_of_line, @re.capture(a), @re.end_of_line]),
    @re.seq([@re.capture(a), @re.not_word_boundary, @re.capture(b)]),
  ]
  // Deterministic mixed nested captures, alternatives and nullable quantifiers.
  let seed : FixedArray[Int] = [7]
  fn pick(n : Int) -> Int {
    seed[0] = seed[0] * 1103515245 + 12345
    ((seed[0] >> 16) & 0x7FFF) % n
  }
  fn generate(depth : Int) -> @re.Pattern {
    if depth == 0 {
      return match pick(4) {
        0 => a
        1 => b
        2 => @re.epsilon
        _ => @re.empty
      }
    }
    match pick(7) {
      0 => @re.capture(generate(depth - 1))
      1 => @re.seq([generate(depth - 1), generate(depth - 1)])
      2 => @re.alt([generate(depth - 1), generate(depth - 1)])
      3 => @re.first(generate(depth - 1))
      4 =>
        @re.seq([
          match pick(5) {
            0 => @re.start_of_word
            1 => @re.end_of_word
            2 => @re.not_word_boundary
            3 => @re.start_of_input
            _ => @re.end_of_input
          },
          generate(depth - 1),
        ])
      _ => {
        let min = pick(2)
        let max = if pick(2) == 0 { None } else { Some(min + pick(3)) }
        let mode : @re.QuantifierMode = if pick(2) == 0 {
          Greedy
        } else {
          NonGreedy
        }
        @re.quantifier(generate(depth - 1), { min, max, mode, })
      }
    }
  }
  for _ in 0..<200 {
    pats.push(generate(3))
  }
  let inputs = ["", "éa", "\na\n", "a!", "!a", "a\u{1F600}"]
  for length in 1..<=5 {
    let count = 1 << (2 * length)
    for code in 0..<count {
      let sb = StringBuilder()
      let mut rest = code
      for _ in 0..<length {
        sb.write_char(
          match rest & 3 {
            0 => 'a'
            1 => 'b'
            2 => '!'
            _ => '\n'
          },
        )
        rest = rest >> 2
      }
      inputs.push(sb.to_string())
    }
  }
  for pat_index, pat in pats {
    let derivative = @baseline.compile(profile~, pat)
    let tagged = @re.compile(profile~, pat)
    for input in inputs {
      for offset in 0..<=input.length() {
        // Repeat after different inputs to detect stale register/candidate state.
        for _ in 0..<2 {
          let expected = derivative.execute(input, offset)
          let actual = tagged.execute(input, offset)
          for group in 0..<=tagged.group_names().length() {
            let expected_group = expected.map(m => m.group(group))
            let actual_group = actual.map(m => m.group(group))
            if actual_group != expected_group {
              @test.assert_eq(
                actual_group,
                expected_group,
                msg="pattern=\{pat_index} \{@debug.Repr(pat)}, input=\{input}, offset=\{offset}, group=\{group}, actual=\{@debug.Repr(actual_group)}, expected=\{@debug.Repr(expected_group)}",
              )
            }
          }
        }
      }
    }
  }
}

///|
test "UTF-16 lowering agrees with the existing public regex" {
  let patterns = [
    ".", "(.)*", "(.+?)(.*)", "(😀|.)+", "[\u{10000}-\u{10FFFF}]+", "[\u{D7FF}-\u{E000}]",
    "[^a]*", "\\b(.)*\\b", "\\B", "^(.?)*$", "(a|(😀)?)*", "((a?)*)*", "(?<x>.*?)(.*)",
  ]
  let inputs = ["", "a", "aa", "😀", "a😀!", "😀😀", "éa\n😀", "!a!"]
  for pattern in patterns {
    let previous = try! @legacy.Regex(pattern)
    let current = try! Regex(pattern)
    for input in inputs {
      // Exercise views whose backing strings have a different start offset.
      let backed = "xx" + input + "yy"
      let view = backed[2:2 + input.length()]
      for offset in 0..<=view.length() {
        let expected = previous.execute(view, last_index=offset)
        let actual = current.execute(view, last_index=offset)
        for group in 0..<8 {
          @test.assert_eq(
            actual.map(m => m.group(group)),
            expected.map(m => m.group(group)),
            msg="pattern=\{pattern}, input=\{input}, offset=\{offset}, group=\{group}",
          )
        }
      }
    }
  }
}

///|
test "cached transitions preserve captures across inputs and views" {
  let a = @re.char(@re.RecharSet::char('a'))
  let q = @re.quantifier(a, { min: 0, max: None, mode: Greedy, })
  let pat = @re.seq([
    @re.start_of_input,
    @re.capture(q),
    @re.capture(q),
    @re.capture(q),
    @re.end_of_input,
  ])
  let tagged = @re.compile(profile~, pat)
  let derivative = @baseline.compile(profile~, pat)
  for input in ["a", "aaaa", "", "aaaaa", "b", "aa", "aaaa"] {
    for i in 0..<=3 {
      @test.assert_eq(
        tagged.execute(input, 0).map(m => m.group(i)),
        derivative.execute(input, 0).map(m => m.group(i)),
      )
    }
  }
  for _ in 0..<100 {
    ignore(tagged.execute("aaaa", 0))
  }
  let view : StringView = "xxaaaayy"[2:6]
  for i in 0..<=3 {
    @test.assert_eq(
      tagged.execute(view, 0).map(m => m.group(i)),
      derivative.execute(view, 0).map(m => m.group(i)),
    )
  }
}
