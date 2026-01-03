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
test "expf Test" {
  let data : Array[Float] = [
    1, 2, 3, 4, 5, 6.5, 7.5, 8.5, 9.5, 10.5, 0.25, 1.25, 2.25, 3.25, 4.25, -0.125,
    -1.125, -2.125, -3.125, -4.125, -0.0625, -1.0625, -2.0625, -3.0625, -4.0625,
    @float.neg_infinity, @float.infinity, @float.not_a_number,
  ]
  let libm_results : Array[Float] = [
    2.7182817459106445, 7.389056205749512, 20.08553695678711, 54.598148345947266,
    148.4131622314453, 665.1416625976562, 1808.0423583984375, 4914.76904296875, 13359.7265625,
    36315.50390625, 1.2840254306793213, 3.490342855453491, 9.487735748291016, 25.790340423583984,
    70.10541534423828, 0.8824968934059143, 0.32465246319770813, 0.1194329708814621,
    0.04393693432211876, 0.016163494437932968, 0.9394130706787109, 0.345590740442276,
    0.1271357387304306, 0.046770621091127396, 0.017205949872732162, 0, @float.infinity,
    @float.not_a_number,
  ]
  for i in 0..<data.length() {
    let x = data[i]
    let res = @math.expf(x)
    let libm_res = libm_results[i]
    assert_true(
      (res.reinterpret_as_int() - libm_res.reinterpret_as_int()).abs() <= 2,
    )
  }
}

///|
test "expm1f Test" {
  let data : Array[Float] = [
    1, 2, 3, 4, 5, 6.5, 7.5, 8.5, 9.5, 10.5, 0.25, 1.25, 2.25, 3.25, 4.25, -0.125,
    -1.125, -2.125, -3.125, -4.125, -0.0625, -1.0625, -2.0625, -3.0625, -4.0625,
    @float.neg_infinity, @float.infinity, @float.not_a_number,
  ]
  let libm_results : Array[Float] = [
    1.718281865119934, 6.389056205749512, 19.08553695678711, 53.598148345947266,
    147.4131622314453, 664.1416625976562, 1807.0423583984375, 4913.76904296875, 13358.7265625,
    36314.50390625, 0.2840254306793213, 2.490342855453491, 8.487735748291016, 24.790340423583984,
    69.10541534423828, -0.1175030991435051, -0.6753475069999695, -0.8805670142173767,
    -0.9560630917549133, -0.9838365316390991, -0.06058693677186966, -0.6544092297554016,
    -0.8728642463684082, -0.9532293677330017, -0.9827940464019775, -1.0, @float.infinity,
    @float.not_a_number,
  ]
  for i in 0..<data.length() {
    let x = data[i]
    let res = @math.expm1f(x)
    let libm_res = libm_results[i]
    assert_true(
      (res.reinterpret_as_int() - libm_res.reinterpret_as_int()).abs() <= 2,
    )
  }
}

///|
test "expm1f reduced branch k=1" {
  let res = @math.expm1f(0.4)
  inspect(res > 0.0 && res < 1.0, content="true")
}

///|
test "expm1f large k branch" {
  let x = Float::reinterpret_from_uint(0x42b17217U)
  let res = @math.expm1f(x)
  assert_true(res > 0.0)
}

///|
test "exp double special cases" {
  assert_true(@math.exp(@double.infinity).is_pos_inf())
  inspect(@math.exp(@double.neg_infinity), content="0")
  assert_true(@math.exp(1000.0).is_pos_inf())
  inspect(@math.exp(-1000.0), content="0")
}

///|
test "exp double moderate values" {
  inspect(@math.exp(0.1), content="1.1051709180756477")
}

///|
test "expm1 double special cases" {
  inspect(@math.expm1(-100.0), content="-1")
  inspect(@math.expm1(0.1), content="0.10517091807564763")
}

///|
test "expf underflow path" {
  let res = @math.expf(-110.0)
  assert_true(res == 0.0)
}

///|
test "exp double k boundaries" {
  let high = @math.exp(709.5)
  assert_true(!high.is_inf())
  assert_true(high > 0.0)
  let low = @math.exp(-740.0)
  assert_true(low > 0.0)
  assert_true(low < 1.0e-300)
}

///|
test "expm1 double branches" {
  let mid = @math.expm1(0.4)
  assert_true(mid > 0.0 && mid < 1.0)
  let big = @math.expm1(20.0)
  assert_true(big > 1.0e8)
}
