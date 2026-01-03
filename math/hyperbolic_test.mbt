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
test "sinhf Test" {
  let data : Array[Float] = [
    1, 2, 3, 4, 5, 6.5, 7.5, 8.5, 9.5, 10.5, 0.25, 1.25, 2.25, 3.25, 4.25, -0.125,
    -1.125, -2.125, -3.125, -4.125, -0.0625, -1.0625, -2.0625, -3.0625, -4.0625,
  ]
  let libm_results : Array[Float] = [
    1.175201177597046, 3.6268603801727295, 10.017874717712402, 27.2899169921875,
    74.20320892333984, 332.570068359375, 904.0209350585938, 2457.38427734375, 6679.86328125,
    18157.751953125, 0.25261232256889343, 1.6019190549850464, 4.691168308258057,
    12.87578296661377, 35.04557418823242, -0.1253257691860199, -1.3777822256088257,
    -4.126732349395752, -11.357978820800781, -30.925823211669922, -0.0625406950712204,
    -1.2740025520324707, -3.869236707687378, -10.667085647583008, -29.051111221313477,
  ]
  for i in 0..<data.length() {
    let x = data[i]
    let res = @math.sinhf(x)
    let libm_res = libm_results[i]
    assert_true(
      (res.reinterpret_as_int() - libm_res.reinterpret_as_int()).abs() <= 2,
    )
  }
}

///|
test "coshf Test" {
  let data : Array[Float] = [
    1, 2, 3, 4, 5, 6.5, 7.5, 8.5, 9.5, 10.5, 0.25, 1.25, 2.25, 3.25, 4.25, -0.125,
    -1.125, -2.125, -3.125, -4.125, -0.0625, -1.0625, -2.0625, -3.0625, -4.0625,
  ]
  let libm_results : Array[Float] = [
    1.5430806875228882, 3.762195587158203, 10.067662239074707, 27.3082332611084,
    74.20994567871094, 332.5715637207031, 904.021484375, 2457.384521484375, 6679.86328125,
    18157.751953125, 1.0314130783081055, 1.8884239196777344, 4.796567440032959, 12.914557456970215,
    35.059837341308594, 1.0078226327896118, 1.7024346590042114, 4.2461652755737305,
    11.401915550231934, 30.941986083984375, 1.0019537210464478, 1.6195933818817139,
    3.9963724613189697, 10.71385669708252, 29.068317413330078,
  ]
  for i in 0..<data.length() {
    let x = data[i]
    let res = @math.coshf(x)
    let libm_res = libm_results[i]
    assert_true(
      (res.reinterpret_as_int() - libm_res.reinterpret_as_int()).abs() <= 2,
    )
  }
}

///|
test "tanhf Test" {
  let data : Array[Float] = [
    1, 2, 3, 4, 5, 6.5, 7.5, 8.5, 9.5, 10.5, 0.25, 1.25, 2.25, 3.25, 4.25, -0.125,
    -1.125, -2.125, -3.125, -4.125, -0.0625, -1.0625, -2.0625, -3.0625, -4.0625,
  ]
  let libm_results : Array[Float] = [
    0.7615941762924194, 0.9640275835990906, 0.9950547814369202, 0.9993293285369873,
    0.9999092221260071, 0.9999954700469971, 0.9999994039535522, 0.9999999403953552,
    1, 1, 0.24491865932941437, 0.8482836484909058, 0.9780260920524597, 0.9969976544380188,
    0.9995931386947632, -0.12435299903154373, -0.8093010783195496, -0.9718727469444275,
    -0.996146559715271, -0.9994776248931885, -0.06241874769330025, -0.7866188287734985,
    -0.9681872129440308, -0.9956345558166504, -0.9994080662727356,
  ]
  for i in 0..<data.length() {
    let x = data[i]
    let res = @math.tanhf(x)
    let libm_res = libm_results[i]
    assert_true(
      (res.reinterpret_as_int() - libm_res.reinterpret_as_int()).abs() <= 2,
    )
  }
}

///|
test "asinhf Test" {
  let data : Array[Float] = [
    1, 2, 3, 4, 5, 6.5, 7.5, 8.5, 9.5, 10.5, 0.25, 1.25, 2.25, 3.25, 4.25, -0.125,
    -1.125, -2.125, -3.125, -4.125, -0.0625, -1.0625, -2.0625, -3.0625, -4.0625,
  ]
  let libm_results : Array[Float] = [
    0.8813735842704773, 1.4436354637145996, 1.8184465169906616, 2.094712495803833,
    2.3124382495880127, 2.570814609527588, 2.712465286254883, 2.836655616760254,
    2.947197675704956, 3.0467822551727295, 0.24746645987033844, 1.0475929975509644,
    1.550157904624939, 1.894672155380249, 2.15362811088562, -0.12467674911022186,
    -0.9670596122741699, -1.498179316520691, -1.8572508096694946, -2.1245920658111572,
    -0.06245937943458557, -0.924884557723999, -1.4712419509887695, -1.8380275964736938,
    -2.1097605228424072,
  ]
  for i in 0..<data.length() {
    let x = data[i]
    let res = @math.asinhf(x)
    let libm_res = libm_results[i]
    assert_true(
      (res.reinterpret_as_int() - libm_res.reinterpret_as_int()).abs() <= 2,
    )
  }
}

///|
test "acoshf Test" {
  let data : Array[Float] = [
    1, 2, 3, 4, 5, 6.5, 7.5, 8.5, 9.5, 10.5, 1.25, 2.25, 3.25, 4.25,
  ]
  let libm_results : Array[Float] = [
    0, 1.316957950592041, 1.7627471685409546, 2.063436985015869, 2.292431592941284,
    2.558979034423828, 2.703575849533081, 2.829735040664673, 2.941657304763794, 3.0422470569610596,
    0.6931471824645996, 1.450574517250061, 1.8472460508346558, 2.1259288787841797,
  ]
  for i in 0..<data.length() {
    let x = data[i]
    let res = @math.acoshf(x)
    let libm_res = libm_results[i]
    assert_true(
      (res.reinterpret_as_int() - libm_res.reinterpret_as_int()).abs() <= 2,
    )
  }
}

///|
test "atanhf Test" {
  let data : Array[Float] = [
    0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 0.15, 0.25, 0.35, 0.45, 0.55, 0.65,
    0.75, 0.85, 0.95, -0.125, -0.225, -0.325, -0.425, -0.525,
  ]
  let libm_results : Array[Float] = [
    0.10033535212278366, 0.20273256301879883, 0.30951961874961853, 0.4236489236354828,
    0.5493061542510986, 0.6931472420692444, 0.8673005104064941, 1.0986123085021973,
    1.4722193479537964, 0.15114043653011322, 0.2554128170013428, 0.36544373631477356,
    0.4847002625465393, 0.6183813214302063, 0.7752986550331116, 0.972955048084259,
    1.256152868270874, 1.8317806720733643, -0.12565721571445465, -0.22891654074192047,
    -0.3372275233268738, -0.45377853512763977, -0.5832173824310303,
  ]
  for i in 0..<data.length() {
    let x = data[i]
    let res = @math.atanhf(x)
    let libm_res = libm_results[i]
    assert_true(
      (res.reinterpret_as_int() - libm_res.reinterpret_as_int()).abs() <= 2,
    )
  }
}

///|
test "tanhf midrange branch" {
  let res = @math.tanhf(0.4)
  assert_true(res > 0.0 && res < 1.0)
}

///|
test "hyperbolic double branch coverage" {
  inspect(@math.sinh(0.5), content="0.5210953054937474")
  assert_true(@math.sinh(10.0) > 0.0)
  assert_true(@math.sinh(25.0) > 0.0)
  assert_true(@math.sinh(710.0) > 0.0)
  assert_true(@math.cosh(30.0) > 0.0)
  assert_true(@math.cosh(710.0) > 0.0)
  assert_true(@math.tanh(0.5).is_close(0.46211715726000974))
  assert_true(@math.asinh(1.0e20) > 0.0)
  assert_true(@math.acosh(1.0e20) > 0.0)
}
