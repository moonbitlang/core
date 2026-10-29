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
/// A reference matcher that shares only the NFA with the engine: a Pike-style
/// simulation with concrete capture positions per thread and a fresh visited
/// set per input position. It has no DFA states, registers, cache or
/// transition table, so it checks all of those independently. It is also a
/// valid oracle for repetitions of nullable bodies.
fn pike(re : Regex, input : BytesView, start : Int32) -> Array[Int32]? {
  let mut seeds = [(re.entry, Array::make(re.ntags, -1))]
  let mut candidate : Array[Int32]? = None
  for pos in start..<=input.length() {
    let seen = Array::make(re.nodes.length(), false)
    let stack : Array[(Int32, Array[Int32])] = []
    for i in (seeds.length() - 1)>=..0 {
      stack.push(seeds[i])
    }
    let ready : Array[(ByteSet, Int32, Array[Int32])] = []
    let column = if pos == input.length() {
      re.nsym
    } else {
      re.table.map(input.unsafe_get(pos))
    }
    let ctx = if pos == 0 {
      re.ctx_start
    } else {
      re.sym_ctx[re.table.map(input.unsafe_get(pos - 1))]
    }
    while stack.pop() is Some((pc, caps)) {
      if seen[pc] {
        continue
      }
      seen[pc] = true
      match re.nodes[pc] {
        Accept => {
          candidate = Some(caps)
          break
        }
        Char(chars, next) => ready.push((chars, next, caps))
        Tag(tag, next) => {
          let copy = caps.copy()
          copy[tag] = pos
          stack.push((next, copy))
        }
        Union(alts) =>
          for i in (alts.length() - 1)>=..0 {
            stack.push((alts[i], caps))
          }
        After(bit, next) =>
          if (ctx & (1 << bit)) != 0 {
            stack.push((next, caps))
          }
        Before(cat, next) =>
          if re.col_cat[column].intersects(cat) {
            stack.push((next, caps))
          }
      }
    }
    if pos == input.length() {
      return candidate
    }
    seeds = []
    for (chars, next, caps) in ready {
      if chars.contains(column) {
        seeds.push((next, caps))
      }
    }
    if seeds.is_empty() {
      return candidate
    }
  }
  candidate
}

///|
priv struct OracleRng {
  mut seed : UInt32
}

///|
fn OracleRng::pick(self : OracleRng, n : Int32) -> Int32 {
  self.seed = self.seed * 1664525U + 1013904223U
  ((self.seed >> 8) % n.reinterpret_as_uint()).reinterpret_as_int()
}

///|
fn oracle_pattern(rng : OracleRng, depth : Int32) -> Pattern {
  let a = char(ByteSet::char('a'))
  let b = char(ByteSet::char('b'))
  let atoms : ReadOnlyArray[Pattern] = [
    a,
    b,
    epsilon,
    empty,
    start_of_input,
    end_of_input,
    start_of_word,
    end_of_word,
    not_word_boundary,
    start_of_line,
    end_of_line,
    char(ByteSet::char_range(0, 255)),
    char(ByteSet::char_range(0x80, 0xff)),
  ]
  if depth <= 0 {
    return atoms[rng.pick(atoms.length())]
  }
  match rng.pick(8) {
    0 => atoms[rng.pick(atoms.length())]
    1 => seq([oracle_pattern(rng, depth - 1), oracle_pattern(rng, depth - 1)])
    2 => alt([oracle_pattern(rng, depth - 1), oracle_pattern(rng, depth - 1)])
    3 => capture(oracle_pattern(rng, depth - 1))
    _ => {
      let body = oracle_pattern(rng, depth - 1)
      let (min, max) = [
          (0, None),
          (1, None),
          (2, None),
          (0, Some(1)),
          (0, Some(3)),
          (2, Some(4)),
          (3, Some(3)),
        ][rng.pick(7)]
      quantifier(body, {
        min,
        max,
        mode: if rng.pick(2) == 0 {
          Greedy
        } else {
          NonGreedy
        },
      })
    }
  }
}

///|
/// Random patterns built from the AST, including nullable repetitions, lazy
/// quantifiers, captures in loops and every assertion; random views with a
/// non-zero offset and a random `last_index`; cache budgets from "flush on
/// every state" to the default.
test "lazy DFA agrees with a Pike VM over the same NFA" {
  let rng = { seed: 924761U, }
  // `\xf0\x9f` is the start of a UTF-8 emoji: bytes above `0x7F` that are
  // neither word bytes nor newlines.
  let alphabet : ReadOnlyArray[Bytes] = [b"a", b"b", b" ", b"\n", b"\xf0\x9f"]
  let mut checks = 0
  for round in 0..<4000 {
    let pat = oracle_pattern(rng, 4)
    let re = compile(
      pat,
      max_cache_words=if round % 3 == 0 {
        1
      } else if round % 3 == 1 {
        200
      } else {
        MAX_CACHE_WORDS
      },
    )
    for _ in 0..<12 {
      let mut text = b"prefix"
      for _ in 0..<rng.pick(15) {
        text = text + alphabet[rng.pick(alphabet.length())]
      }
      let text = text + b"suffix"
      let input = text[6:text.length() - 6]
      let start = rng.pick(input.length() + 1)
      let expected = pike(re, input, start)
      let actual = re.execute(input, start).map(m => m.0)
      if expected != actual {
        fail(
          "Pike mismatch pattern=\{@debug.to_string(pat)} input=\{@debug.to_string(input)} start=\{start} expected=\{@debug.to_string(expected)} actual=\{@debug.to_string(actual)}",
        )
      }
      checks += 1
    }
  }
  @test.assert_eq(checks, 48000)
}
