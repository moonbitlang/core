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
test "canonical Huffman codes retain symbol order across frequency groups" {
  // The classic six-symbol tree, with unused symbols interspersed. The
  // optimal lengths are 4,4,3,3,3,1; DEFLATE transmits reversed codewords.
  let frequencies : FixedArray[Int32] = [5, 0, 9, 12, 0, 13, 16, 45]
  let lengths = FixedArray::make(8, 0)
  let values = FixedArray::make(8, 0U)
  gen_huffman(frequencies, 8, 15, lengths, code_val=values)
  @test.assert_eq(lengths, [4, 0, 4, 3, 0, 3, 3, 1])
  @test.assert_eq(values, [7U, 0U, 15U, 1U, 0U, 5U, 3U, 0U])

  let limited_lengths = FixedArray::make(8, 0)
  let limited_values = FixedArray::make(8, 0U)
  gen_huffman(frequencies, 8, 3, limited_lengths, code_val=limited_values)
  @test.assert_eq(limited_lengths, [3, 0, 3, 3, 0, 3, 2, 2])
  @test.assert_eq(limited_values, [1U, 0U, 5U, 3U, 0U, 7U, 0U, 2U])

  let lengths_only = FixedArray::make(8, 0)
  gen_huffman(frequencies, 8, 3, lengths_only)
  @test.assert_eq(lengths_only, limited_lengths)
}

///|
test "canonical Huffman assigns values for two symbols" {
  let frequencies : FixedArray[Int32] = [3, 0, 2]
  let lengths = FixedArray::make(3, 0)
  let values = FixedArray::make(3, 0U)
  gen_huffman(frequencies, 3, 15, lengths, code_val=values)
  @test.assert_eq(lengths, [1, 0, 1])
  @test.assert_eq(values, [0U, 0U, 1U])
}

///|
// Independent Huffman merge cost: no production tree builder or code
// assignment is used to compute the expected cost. The small frequency range
// keeps the unrestricted optimum within 15 bits; the bounded case is above.
test "Huffman construction achieves an independently computed optimal cost" {
  let rng = MatchLenDifferentialRng(0x142BCE83U)
  for n in [3, 5, 8, 19, 30, 64, 128, 286] {
    for distribution in 0..<6 {
      let weights : Array[Int32] = []
      let frequencies = FixedArray::makei(n, _ => {
        let frequency = if distribution == 0 {
          1
        } else if distribution % 2 == 0 {
          1 << rng.below(6)
        } else {
          1 + rng.below(32)
        }
        weights.push(frequency)
        frequency
      })
      let mut optimal_cost = 0
      while weights.length() > 1 {
        weights.sort_by((a, b) => b - a)
        let merged = weights.pop().unwrap() + weights.pop().unwrap()
        optimal_cost += merged
        weights.push(merged)
      }
      let lengths = FixedArray::make(n, 0)
      gen_huffman(frequencies, n, 15, lengths)
      let mut cost = 0
      let mut kraft_sum = 0
      for i in 0..<n {
        let bits = lengths[i]
        assert_true(bits >= 1 && bits <= 15)
        cost += frequencies[i] * bits
        kraft_sum += 1 << (15 - bits)
      }
      @test.assert_eq(cost, optimal_cost)
      @test.assert_eq(kraft_sum, 1 << 15)
    }
  }
}
