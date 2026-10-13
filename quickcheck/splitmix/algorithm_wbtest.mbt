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
test "mix64 follows the MurmurHash3 finalizer" {
  // Reference algorithm (all three shifts are 33):
  // https://github.com/haskellari/splitmix/blob/master/src/System/Random/SplitMix.hs#L222-L228
  inspect(
    mix64(0x123456789abcdef0).to_string(radix=16),
    content="18b8c062f6f42398",
  )
}

///|
test "mix_gamma makes the mixed output odd" {
  // Mixing an odd input need not produce an odd output. In particular, the
  // default constructor's step used to be even and lose four bits of period.
  inspect(
    mix_gamma(37UL + golden_gamma).to_string(radix=16),
    content="c7ab56057c8da907",
  )
}

///|
test "mix_gamma repairs too few bit transitions" {
  // These inputs have fewer than 24 adjacent-bit transitions after mixing.
  // Counting with OR instead of XOR incorrectly skips the repair.
  // https://github.com/haskellari/splitmix/blob/master/src/System/Random/SplitMix.hs#L240-L248
  inspect(
    mix_gamma(12UL + golden_gamma).to_string(radix=16),
    content="3e955356337425a9",
  )
  // The old implementation returned 0xffffff0000000000 for this seed,
  // reducing the period to 2^24.
  inspect(
    mix_gamma(1252319804544721972UL + golden_gamma).to_string(radix=16),
    content="555555aaaaaaaaab",
  )
}

///|
test "RandomState follows the SplitMix reference sequence" {
  // Published nextWord64 example for mkSMGen 1337:
  // https://github.com/haskellari/splitmix/blob/master/src/System/Random/SplitMix.hs#L102-L110
  let state = RandomState(seed=1337)
  @debug.debug_inspect(
    (state.seed.to_string(radix=16), state.gamma.to_string(radix=16)),
    content="(\"5b0059b4cf84c580\", \"b6a8a9b313caa00b\")",
  )
  inspect(state.next_uint64().to_string(radix=16), content="b5c19e300e8b07b3")
  inspect(state.next_uint64().to_string(radix=16), content="d600e0e216c0ac76")
  inspect(state.next_uint64().to_string(radix=16), content="c54efc3b3cc5af29")
}

///|
test "RandomState::split follows the SplitMix reference states" {
  // Known answers independently calculated from splitSMGen, modulo 2^64:
  // https://github.com/haskellari/splitmix/blob/master/src/System/Random/SplitMix.hs#L200-L206
  let parent = RandomState(seed=1337)
  let child = parent.split()
  @debug.debug_inspect(
    (parent.seed.to_string(radix=16), parent.gamma.to_string(radix=16)),
    content="(\"c851ad1af71a0596\", \"b6a8a9b313caa00b\")",
  )
  @debug.debug_inspect(
    (child.seed.to_string(radix=16), child.gamma.to_string(radix=16)),
    content="(\"b5c19e300e8b07b3\", \"269f937bf754bcf1\")",
  )
  inspect(parent.next_uint64().to_string(radix=16), content="c54efc3b3cc5af29")
  inspect(child.next_uint64().to_string(radix=16), content="6f1cb305da11d9f9")
}

///|
test "constructors and split descendants preserve gamma invariants" {
  let states = [RandomState(), (Default::default() : RandomState)]
  let seeds : Array[UInt64] = [
    0,
    1,
    12,
    37,
    1252319804544721972,
    0x7fffffffffffffff,
    0x8000000000000000,
    0xffffffffffffffff - golden_gamma,
    0UL - golden_gamma,
    0xffffffffffffffff,
  ]
  for seed in seeds {
    states.push(RandomState(seed~))
  }
  // Exercise both children at each level, including addition across UInt64
  // boundaries. An odd gamma gives the additive state a full 2^64 period.
  for _ in 0..<4 {
    let count = states.length()
    for i in 0..<count {
      let state = states[i]
      @test.assert_eq(state.gamma & 1UL, 1UL)
      assert_true((state.gamma ^ (state.gamma >> 1)).popcnt() >= 24)
      let child = state.split()
      @test.assert_eq(child.gamma & 1UL, 1UL)
      assert_true((child.gamma ^ (child.gamma >> 1)).popcnt() >= 24)
      states.push(child)
    }
  }
}
