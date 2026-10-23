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
test "compression levels clamp at both public boundaries" {
  let source = b"level clamping must be deterministic deterministic"
  @test.assert_eq(deflate_all(source, level=-7), deflate_all(source, level=0))
  @test.assert_eq(deflate_all(source, level=99), deflate_all(source, level=9))
  let low = Deflater(level=-7)
  let high = Deflater(level=99)
  @test.assert_eq(low.level, 0)
  @test.assert_eq(high.level, 9)
  @test.assert_eq(
    inflate_all(deflate_all_optimal(b"iteration clamp", iterations=0)),
    b"iteration clamp",
  )
}

///|
test "lazy match pending at a block boundary is committed" {
  // The token range is one byte wide, but lookahead extends beyond it. A
  // history match beginning at index 3 is deferred by lazy parsing; reaching
  // `end=4` commits that pending match in tokenize's boundary epilogue.
  let data = b"abcabcabc"
  let tokens : Array[Int32] = []
  let ll_freq = FixedArray::make(286, 0)
  let d_freq = FixedArray::make(30, 0)
  let finder = MatchFinder()
  for i in 0..<3 {
    finder.insert_pos(data, i, data.length())
  }
  let processed = tokenize(
    data,
    finder,
    3,
    4,
    level_configs[6],
    tokens,
    ll_freq,
    d_freq,
  )
  @test.assert_eq(tokens.length(), 1)
  let token = tokens[0]
  assert_true(token >= 256)
  let length = token >> 16
  let distance = token & 0xFFFF
  assert_true(length >= 3)
  @test.assert_eq(distance, 3)
  assert_true(ll_freq[257 + len_to_idx[length]] > 0)
  assert_true(d_freq[dist_index(distance)] > 0)
  assert_true(processed > 4)
}

///|
test "optimal planner crosses its master-block boundary" {
  // Repetition keeps the optimal parse small while forcing the outer planner
  // to choose its capped master target at least once.
  let source = Bytes::from_array(
    Array::make(OPTIMAL_MASTER_BLOCK + MIN_LOOKAHEAD + 1, b'\x41'),
  )
  let compressed = deflate_all_optimal(source, iterations=1)
  @test.assert_eq(inflate_all(compressed), source)
}

///|
test "split planner cuts and resets observations across literal-class changes" {
  // Exercise planner behavior independently of a particular matchfinder's
  // token choices: three long literal regions have sharply different classes.
  let tokens : Array[Int32] = []
  for literal in [97, 98, 97] {
    for _ in 0..<12000 {
      tokens.push(literal)
    }
  }
  let cuts = choose_splits(tokens)
  @test.assert_eq(cuts.length() >= 2, true)
  let data = Bytes::makei(tokens.length(), i => tokens[i].to_byte())
  let writer = BitWriter()
  cuts.push(tokens.length())
  let mut start = 0
  for end in cuts {
    @test.assert_eq(end > start && end <= tokens.length(), true)
    let literal_freq = FixedArray::make(MAX_NUM_LIT, 0)
    let distance_freq = FixedArray::make(MAX_NUM_DIST, 0)
    for i in start..<end {
      literal_freq[tokens[i]] += 1
    }
    writer.emit_block(
      data,
      start,
      end,
      tokens[start:end],
      literal_freq,
      distance_freq,
      is_final=end == tokens.length(),
    )
    start = end
  }
  writer.flush()
  @test.assert_eq(inflate_all(Bytes::from_array(writer.out)), data)
}
