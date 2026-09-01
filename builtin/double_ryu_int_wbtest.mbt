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
/// The integral fast path must be indistinguishable from the full algorithm.
/// The oracle is `Int::to_string`, which is the definition of the shortest
/// decimal form for an integer; for values outside the fast path the expected
/// strings are pinned so a widened guard cannot silently change them.
test "ryu integral fast path agrees with Int::to_string over a dense band" {
  for i in -3000..<=3000 {
    assert_true(ryu_to_string(i.to_double()) == i.to_string())
  }
}

///|
test "ryu integral fast path at the Int range boundary" {
  // Inside the guard, both signs.
  inspect(ryu_to_string(2147483646.0), content="2147483646")
  inspect(ryu_to_string(2147483647.0), content="2147483647")
  inspect(ryu_to_string(-2147483647.0), content="-2147483647")
  inspect(ryu_to_string(-2147483648.0), content="-2147483648")
  // Just outside Int range: now served by the Int64 tier, same rendering.
  inspect(ryu_to_string(2147483648.0), content="2147483648")
  inspect(ryu_to_string(2147483649.0), content="2147483649")
  inspect(ryu_to_string(-2147483649.0), content="-2147483649")
  inspect(ryu_to_string(-2147483650.0), content="-2147483650")
}

///|
test "ryu integral fast path never captures special or fractional values" {
  // -0.0 is handled by the existing zero check before the fast path.
  inspect(ryu_to_string(-0.0), content="0")
  inspect(ryu_to_string(0.0 / 0.0), content="NaN")
  inspect(ryu_to_string(1.0 / 0.0), content="Infinity")
  inspect(ryu_to_string(-1.0 / 0.0), content="-Infinity")
  // Fractional values whose truncation is in range must not take the path.
  inspect(ryu_to_string(0.5), content="0.5")
  inspect(ryu_to_string(-0.5), content="-0.5")
  inspect(ryu_to_string(2147483646.5), content="2147483646.5")
  inspect(ryu_to_string(-2147483647.5), content="-2147483647.5")
  // The next representable double below 1.0 and above 1.0: integrality test
  // must reject both.
  inspect(ryu_to_string(0.9999999999999999), content="0.9999999999999999")
  inspect(ryu_to_string(1.0000000000000002), content="1.0000000000000002")
}

///|
test "ryu integral fast path across power-of-two neighbourhoods" {
  // Exact powers of two and neighbours on both sides of the guard, both signs.
  for p in 0..<=53 {
    let v = (1L << p).to_double()
    for d in -2L..<=2L {
      let x = v + d.to_double()
      let expected = x.to_int64().to_string()
      assert_true(ryu_to_string(x) == expected)
      let nx = -v + d.to_double()
      let nexpected = if nx == 0.0 { "0" } else { nx.to_int64().to_string() }
      assert_true(ryu_to_string(nx) == nexpected)
    }
  }
}

///|
test "ryu integral fast path at the 2^53 boundary" {
  // 2^53 is the inclusive bound of MAX_EXACTLY_REPRESENTABLE_INT.
  inspect(ryu_to_string(9007199254740992.0), content="9007199254740992")
  inspect(ryu_to_string(-9007199254740992.0), content="-9007199254740992")
  inspect(ryu_to_string(9007199254740991.0), content="9007199254740991")
  inspect(ryu_to_string(-9007199254740991.0), content="-9007199254740991")
  // 2^53 + 2 is the first representable integer past the bound: it must fall
  // through to the full algorithm and render identically to before.
  inspect(ryu_to_string(9007199254740994.0), content="9007199254740994")
  inspect(ryu_to_string(-9007199254740994.0), content="-9007199254740994")
  // Values between Int and Int64 tiers: a millisecond timestamp.
  inspect(ryu_to_string(1700000000000.0), content="1700000000000")
  inspect(ryu_to_string(-1700000000000.0), content="-1700000000000")
}

///|
test "ryu integral fast path rejects fractional values in the Int64 tier" {
  // These sit between the Int tier and the 2^53 bound; truncation is exact
  // but the values are not integral, so they must use the full algorithm.
  inspect(ryu_to_string(1700000000000.5), content="1700000000000.5")
  inspect(ryu_to_string(-1700000000000.5), content="-1700000000000.5")
  inspect(ryu_to_string(4503599627370495.5), content="4503599627370495.5")
}

///|
test "ryu bound is load-bearing above 2^53" {
  // 2^62 is exactly representable and round-trips through Int64, but its
  // SHORTEST decimal form is not its exact integer digits (4611686018427387904):
  // doubles are spaced 512 apart here, so a shorter decimal round-trips.
  // Widening MAX_EXACTLY_REPRESENTABLE_INT past 2^53 would break this.
  inspect(ryu_to_string(4611686018427387904.0), content="4611686018427388000")
  inspect(ryu_to_string(-4611686018427387904.0), content="-4611686018427388000")
  // 2^60: spacing 128; its shortest form is also shortened, not exact.
  inspect(ryu_to_string(1152921504606846976.0), content="1152921504606847000")
}
