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
  // Just outside: must fall back to the full algorithm, same rendering.
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
  for p in 0..<=34 {
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
