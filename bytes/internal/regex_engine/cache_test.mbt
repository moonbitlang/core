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
fn chars(lo : Char, hi : Char) -> @regex_engine.Pattern {
  @regex_engine.char(
    @regex_engine.ByteSet::char_range(lo.to_int(), hi.to_int()),
  )
}

///|
/// `([a-c]+)x([a-c]{1,3})|(b+)c`: enough threads and captures to make the
/// lazy DFA grow over a varied input.
fn sample_pattern() -> @regex_engine.Pattern {
  let abc = chars('a', 'c')
  @regex_engine.alt([
    @regex_engine.seq([
      @regex_engine.capture(
        @regex_engine.quantifier(abc, { min: 1, max: None, mode: Greedy, }),
      ),
      chars('x', 'x'),
      @regex_engine.capture(
        @regex_engine.quantifier(abc, { min: 1, max: Some(3), mode: Greedy, }),
      ),
    ]),
    @regex_engine.seq([
      @regex_engine.capture(
        @regex_engine.quantifier(chars('b', 'b'), {
          min: 1,
          max: None,
          mode: Greedy,
        }),
      ),
      chars('c', 'c'),
    ]),
  ])
}

///|
/// With a tiny cache budget the cache is dropped over and over in the middle
/// of a scan. Threads keep their registers across a flush, so results must
/// not change.
test "flushing the lazy DFA cache does not change results" {
  let roomy = @regex_engine.compile(sample_pattern())
  let tight = @regex_engine.compile(sample_pattern(), max_cache_words=1)
  let letters : ReadOnlyArray[Byte] = [b'a', b'b', b'c', b'x', b'y']
  let mut seed = 7U
  let mut matches = 0
  for _ in 0..<2000 {
    let input = Bytes::makei(12, _ => {
      seed = seed * 1664525U + 1013904223U
      letters[((seed >> 10) % 5U).reinterpret_as_int()]
    })
    let expected = roomy.execute(input, 0)
    let actual = tight.execute(input, 0)
    if expected is Some(_) {
      matches += 1
    }
    for group in 0..<4 {
      @test.assert_eq(
        actual.map(m => m.group(group)),
        expected.map(m => m.group(group)),
      )
    }
  }
  assert_true(matches > 500)
}

///|
/// One state can be larger than the whole budget: here every alternative has
/// its own group and all of them stay alive after the first `a`. The state
/// is kept anyway and matching stays correct. Found in review.
test "a state larger than the cache budget still works" {
  let branches = Array::makei(300, _ => {
    @regex_engine.capture(
      @regex_engine.seq([
        @regex_engine.quantifier(chars('a', 'a'), {
          min: 0,
          max: None,
          mode: Greedy,
        }),
        chars('b', 'b'),
      ]),
    )
  })
  let pattern = @regex_engine.seq([
    @regex_engine.start_of_input,
    @regex_engine.alt(ReadOnlyArray::from_array(branches)),
  ])
  // One state needs about 300 rows of 602 registers, far above 1,000 words.
  let re = @regex_engine.compile(pattern, max_cache_words=1000)
  for input in [b"aaab", b"b", b"aaaaaaaab"] {
    guard re.execute(input, 0) is Some(m) else { fail("expected a match") }
    @test.assert_eq(m.group(0), Some((0, input.length())))
    @test.assert_eq(m.group(1), Some((0, input.length())))
    @test.assert_eq(m.group(2), None)
  }
  assert_true(re.execute(b"aaac", 0) is None)
}
