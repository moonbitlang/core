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

// `BytesRegex` has its own parser and engine, a copy of the string ones
// specialized for bytes. The previous `BytesRegex` of this library drifted
// away from `@string.Regex` until it was removed. This test is what keeps
// the two together: on ASCII patterns and inputs, which both accept, they
// must agree on every error, match and group.

///|
priv struct Rng {
  mut state : UInt32
}

///|
fn Rng::pick(self : Rng, n : Int32) -> Int32 {
  self.state = self.state * 1664525U + 1013904223U
  ((self.state >> 8) % n.reinterpret_as_uint()).reinterpret_as_int()
}

///|
priv struct Gen {
  rng : Rng
  /// Capture groups so far, named or not, to know how many to compare.
  mut groups : Int32
  names : Array[String]
}

///|
/// Every escape and class the two parsers accept, plus some literals.
let atoms : ReadOnlyArray[String] = [
  "a", "b", "c", "A", "_", "1", " ", "/", "\\n", "\\t", "\\r", "\\f", "\\v", "\\.",
  "\\\\", "\\/", "\\^", "\\$", "\\*", "\\+", "\\?", "\\(", "\\)", "\\[", "\\]", "\\{",
  "\\}", "\\|", "\\\"", ".", "[abc]", "[^a]", "[a-c]", "[^a-cA]", "[b-z_]", "[\\b]",
  "[\\t\\r\\f\\v]", "[\\-\\:\\&]", "[\\^\\]\\[]", "[ -/]", "[[:ascii:]]", "[[:upper:]]",
  "[[:lower:]]", "[[:alpha:]]", "[[:alnum:]]", "[[:digit:]]", "[[:xdigit:]]", "[[:blank:]]",
  "[[:space:]]", "[[:word:]]", "[^[:word:]]", "[^[:space:][:digit:]]", "[\\n ]",
]

///|
let assertions : ReadOnlyArray[String] = ["^", "$", "\\b", "\\B"]

///|
let quantifiers : ReadOnlyArray[String] = [
  "*", "+", "?", "{2}", "{1,3}", "{2,}", "{0,2}", "*?", "+?", "??", "{1,2}?", "{2,}?",
]

///|
fn Gen::pattern(self : Gen, depth : Int32) -> String {
  let rng = self.rng
  if depth <= 0 {
    return atoms[rng.pick(atoms.length())]
  }
  match rng.pick(10) {
    0 | 1 => atoms[rng.pick(atoms.length())]
    2 => assertions[rng.pick(assertions.length())]
    3 | 4 => self.pattern(depth - 1) + self.pattern(depth - 1)
    5 => self.pattern(depth - 1) + "|" + self.pattern(depth - 1)
    6 => {
      // Groups are numbered by their `(`, which comes before the body.
      self.groups += 1
      match rng.pick(3) {
        0 => {
          let name = "n\{self.names.length()}"
          self.names.push(name)
          "(?<\{name}>" + self.pattern(depth - 1) + ")"
        }
        _ => "(" + self.pattern(depth - 1) + ")"
      }
    }
    7 => "(?:" + self.pattern(depth - 1) + ")"
    8 => "(?i:" + self.pattern(depth - 1) + ")"
    _ =>
      "(?:" +
      self.pattern(depth - 1) +
      ")" +
      quantifiers[rng.pick(quantifiers.length())]
  }
}

///|
/// Damage a pattern so that the error paths are compared too.
fn Gen::mutate(self : Gen, pattern : String) -> String {
  let pieces : ReadOnlyArray[String] = [
    "(", ")", "[", "]", "{", "}", "{3,1}", "{999}", "\\", "\\q", "-", "[z-a]", "[[:foo:]]",
    "(?", "(?x:", "(?=", "(?<", "*", "+", "|", "^*", "[a-]", "[-a]", "[a&&b]", "[a--b]",
    "[[a]]", "[:digit:]", "\\d", "a++", "[[:punct:]]", "(?<n0>a)", "a{256}", "a{257}",
  ]
  let at = self.rng.pick(pattern.length() + 1)
  let piece = pieces[self.rng.pick(pieces.length())]
  // The one piece that can add a group to a valid pattern: count it, so that
  // its number and its name are compared too. Inside a class it adds none,
  // and both engines then report the extra group and name as absent.
  if piece is "(?<n0>a)" {
    self.groups += 1
    if !self.names.contains("n0") {
      self.names.push("n0")
    }
  }
  pattern[:at].to_owned() + piece + pattern[at:].to_owned()
}

///|
fn ascii_bytes(s : String) -> Bytes {
  Bytes::makei(s.length(), i => s.unsafe_get(i).to_byte())
}

///|
/// The same view of a match from both engines: the same offsets in the
/// searched view and the same contents.
fn same_view(
  s_input : StringView,
  s : StringView?,
  b_input : BytesView,
  b : BytesView?,
) -> Bool {
  string_span(s_input, s) == bytes_span(b_input, b) &&
  s.map(s => ascii_bytes(s.to_owned())) == b.map(b => b.to_owned())
}

///|
fn error_of(pattern : String) -> (String?, String?) {
  let s = try @string.Regex(pattern) catch {
    e => Some("\{e}")
  } noraise {
    _ => None
  }
  let b = try @bytes.BytesRegex(pattern) catch {
    e => Some("\{e}")
  } noraise {
    _ => None
  }
  (s, b)
}

///|
/// Offsets of a group relative to the searched view.
fn string_span(input : StringView, g : StringView?) -> (Int32, Int32)? {
  g.map(g => {
    let start = g.start_offset() - input.start_offset()
    (start, start + g.length())
  })
}

///|
fn bytes_span(input : BytesView, g : BytesView?) -> (Int32, Int32)? {
  g.map(g => {
    let start = g.start_offset() - input.start_offset()
    (start, start + g.length())
  })
}

///|
test "BytesRegex agrees with @string.Regex on ASCII" {
  let rng = { state: 20261029U, }
  // Every ASCII byte the escapes and classes above tell apart.
  let alphabet = "abcAB_12xF /.-^]\\\n\t\r\u{b}\u{c}\u{8}\u{0}\u{7f}"
  let mut matches = 0
  let mut errors = 0
  let mut compared = 0
  for round in 0..<3000 {
    let gen = { rng, groups: 0, names: [], }
    let mut pattern = gen.pattern(1 + rng.pick(4))
    if round % 4 == 3 {
      pattern = gen.mutate(pattern)
    }
    let (s_error, b_error) = error_of(pattern)
    if s_error != b_error {
      fail(
        "errors differ for \{pattern.escape()}: string=\{@debug.to_string(s_error)} bytes=\{@debug.to_string(b_error)}",
      )
    }
    guard s_error is None else {
      errors += 1
      continue
    }
    let s_re = @string.Regex(pattern)
    let b_re = @bytes.BytesRegex(pattern)
    for _ in 0..<10 {
      let text = String::from_array(
        Array::makei(rng.pick(16), _ => {
          alphabet.unsafe_get(rng.pick(alphabet.length())).unsafe_to_char()
        }),
      )
      let bytes = ascii_bytes(text)
      // A view that does not start at the start of its data, as left by an
      // earlier match.
      let lo = rng.pick(text.length() + 1)
      let hi = lo + rng.pick(text.length() - lo + 1)
      let s_input = text[lo:hi]
      let b_input = bytes[lo:hi]
      let last_index = rng.pick(s_input.length() + 1)
      let s_match = s_re.execute(s_input, last_index~)
      let b_match = b_re.execute(b_input, last_index~)
      let ctx = "pattern=\{pattern.escape()} input=\{s_input.to_owned().escape()} last_index=\{last_index}"
      match (s_match, b_match) {
        (None, None) => ()
        (Some(s), Some(b)) => {
          matches += 1
          // One past the last group, which both must report as absent.
          for i in 0..<=(gen.groups + 1) {
            if !same_view(s_input, s.group(i), b_input, b.group(i)) {
              fail(
                "group \{i} differs, \{ctx}: string=\{@debug.to_string(string_span(s_input, s.group(i)))} bytes=\{@debug.to_string(bytes_span(b_input, b.group(i)))}",
              )
            }
          }
          for name in gen.names {
            if !same_view(
                s_input,
                s.named_group(name),
                b_input,
                b.named_group(name),
              ) {
              fail("group \{name} differs, \{ctx}")
            }
          }
          if !same_view(s_input, Some(s.content()), b_input, Some(b.content())) ||
            !same_view(s_input, Some(s.before()), b_input, Some(b.before())) ||
            !same_view(s_input, Some(s.after()), b_input, Some(b.after())) {
            fail("content, before or after differ, \{ctx}")
          }
        }
        _ =>
          fail(
            "match differs, \{ctx}: string=\{s_match is Some(_)} bytes=\{b_match is Some(_)}",
          )
      }
      compared += 1
    }
  }
  // The generator must keep exercising both outcomes and the error paths.
  assert_true(matches > 5000)
  assert_true(compared - matches > 2000)
  assert_true(errors > 500)
}

///|
test "BytesRegex agrees with @string.Regex on every ASCII byte" {
  // Each atom alone, folded or negated, on every ASCII byte: a random input
  // could miss the one byte that tells two meanings of an escape apart.
  for atom in atoms {
    let negated = match atom {
      [.. "[^", .. rest] => "[" + rest.to_owned()
      [.. "[", .. rest] => "[^" + rest.to_owned()
      _ => "[^" + atom + "]"
    }
    for
      pattern in ["^" + atom + "$", "^(?i:" + atom + ")$", "^" + negated + "$"] {
      // Every atom is valid in all three forms, so nothing is skipped.
      match error_of(pattern) {
        (None, None) => ()
        errors =>
          fail(
            "\{pattern.escape()} does not parse: \{@debug.to_string(errors)}",
          )
      }
      let s_re = @string.Regex(pattern)
      let b_re = @bytes.BytesRegex(pattern)
      for c in 0..<128 {
        let text = Int32::unsafe_to_char(c).to_string()
        let s_match = s_re.execute(text) is Some(_)
        let b_match = b_re.execute(ascii_bytes(text)) is Some(_)
        if s_match != b_match {
          fail(
            "match differs for \{pattern.escape()} on \{c}: string=\{s_match} bytes=\{b_match}",
          )
        }
      }
    }
  }
}

///|
test "BytesRegex agrees with @string.Regex at the parser limits" {
  let patterns = [
    "(?<x>a)(?<x>b)",
    "(?<x>a)|(?<y>b)",
    "(".repeat(64) + ")".repeat(64),
    "(".repeat(65) + ")".repeat(65),
    "(?:".repeat(64) + "a" + ")".repeat(64),
    "(?i:".repeat(65) + "a" + ")".repeat(65),
    "a{256}",
    "a{257}",
    "a{0,256}",
    "a{256,}",
    "a{256,257}",
    "a{2,1}",
    "[[:punct:]]",
    "[[:Digit:]]",
  ]
  for pattern in patterns {
    let (s_error, b_error) = error_of(pattern)
    if s_error != b_error {
      fail(
        "errors differ for \{pattern.escape()}: string=\{@debug.to_string(s_error)} bytes=\{@debug.to_string(b_error)}",
      )
    }
  }
}

///|
test "BytesRegex + and | agree with @string.Regex" {
  // Two generated patterns, joined by the operators rather than in the
  // pattern text: the groups of the right operand follow those of the left.
  let rng = { state: 4573U, }
  let alphabet = "abcAB_12 \n.-"
  let mut matches = 0
  for _ in 0..<1000 {
    let gen = { rng, groups: 0, names: [], }
    let p1 = gen.pattern(1 + rng.pick(3))
    let p2 = gen.pattern(1 + rng.pick(3))
    guard error_of(p1) is (None, None) && error_of(p2) is (None, None) else {
      continue
    }
    let seq = (
      @string.Regex(p1) + Regex(p2),
      @bytes.BytesRegex(p1) + BytesRegex(p2),
    )
    let alt = (
      @string.Regex(p1) | Regex(p2),
      @bytes.BytesRegex(p1) | BytesRegex(p2),
    )
    for pair in [("+", seq), ("|", alt)] {
      let (op, (s_re, b_re)) = pair
      for _ in 0..<5 {
        let text = String::from_array(
          Array::makei(rng.pick(12), _ => {
            alphabet.unsafe_get(rng.pick(alphabet.length())).unsafe_to_char()
          }),
        )
        let s_match = s_re.execute(text)
        let b_match = b_re.execute(ascii_bytes(text))
        let ctx = "\{p1.escape()} \{op} \{p2.escape()} on \{text.escape()}"
        match (s_match, b_match) {
          (None, None) => ()
          (Some(s), Some(b)) => {
            matches += 1
            for i in 0..<=(gen.groups + 1) {
              if !same_view(text, s.group(i), ascii_bytes(text), b.group(i)) {
                fail("group \{i} differs, \{ctx}")
              }
            }
            for name in gen.names {
              if !same_view(
                  text,
                  s.named_group(name),
                  ascii_bytes(text),
                  b.named_group(name),
                ) {
                fail("group \{name} differs, \{ctx}")
              }
            }
          }
          _ => fail("match differs, \{ctx}")
        }
      }
    }
  }
  assert_true(matches > 2000)
}

///|
test "BytesRegex::internal_from_string is BytesRegex" {
  // The compiler builds the value of a `reb"..."` literal with it, and lifts
  // each call to a static initializer, so it is only ever called with a
  // literal: a call with a variable would not compile in release mode.
  let cases = [
    ("^GET /", @bytes.BytesRegex::internal_from_string("^GET /")),
    (
      "\\xef\\xbb\\xbf",
      @bytes.BytesRegex::internal_from_string("\\xef\\xbb\\xbf"),
    ),
    (
      "(?<n>[[:digit:]]+)|x",
      @bytes.BytesRegex::internal_from_string("(?<n>[[:digit:]]+)|x"),
    ),
  ]
  for case in cases {
    let (pattern, a) = case
    let b = @bytes.BytesRegex(pattern)
    @test.assert_eq(@debug.to_string(a), @debug.to_string(b))
    let input = b"GET /12\xef\xbb\xbf"
    @test.assert_eq(
      a.execute(input).map(m => m.content().to_owned()),
      b.execute(input).map(m => m.content().to_owned()),
    )
  }
}
