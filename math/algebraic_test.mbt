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
test "@math.cbrtf" {
  inspect(@math.cbrtf(0), content="0")
  inspect(@math.cbrtf(1), content="1")
  inspect(@math.cbrtf(2), content="1.2599210739135742")
  inspect(@math.cbrtf(3), content="1.4422495365142822")
  inspect(@math.cbrtf(4), content="1.587401032447815")
  inspect(@math.cbrtf(5), content="1.7099759578704834")
  inspect(@math.cbrtf(-6), content="-1.8171205520629883")
  inspect(@math.cbrtf(-7), content="-1.912931203842163")
  inspect(@math.cbrtf(-8), content="-2")
  inspect(@math.cbrtf(@float.not_a_number), content="NaN")
  inspect(@math.cbrtf(@float.infinity), content="Infinity")
  inspect(@math.cbrtf(@float.neg_infinity), content="-Infinity")
  let subnormal = Float::reinterpret_from_uint(1U)
  let sub_res = @math.cbrtf(subnormal)
  assert_false(sub_res.is_nan())
  assert_false(sub_res.is_inf())
}

///|
test "@math.hypotf" {
  inspect(@math.hypotf(3, 4), content="5")
  inspect(@math.hypotf(5, 12.0), content="13")
  inspect(@math.hypotf(8, 15.0), content="17")
  inspect(@math.hypotf(7, 24.0), content="25")
  inspect(@math.hypotf(20, 21.0), content="29")
  inspect(@math.hypotf(9, 40.0), content="41")
  inspect(@math.hypotf(12, 35.0), content="37")
  inspect(@math.hypotf(11, 60.0), content="61")
  inspect(@math.hypotf(16, 63.0), content="65")
  inspect(@math.hypotf(@float.not_a_number, 1.0), content="NaN")
  inspect(@math.hypotf(1, @float.not_a_number), content="NaN")
  inspect(@math.hypotf(@float.infinity, 1.0), content="Infinity")
  inspect(@math.hypotf(1.0, @float.infinity), content="Infinity")
  inspect(@math.hypotf(@float.neg_infinity, 1.0), content="Infinity")
  inspect(@math.hypotf(1, @float.neg_infinity), content="Infinity")
  let small = @math.hypotf(1.0, 1.0e-8)
  assert_true(small.is_close(1.0))
}

///|
test "@math.hypot small ratio" {
  let ys = [0.0]
  let small = @math.hypot(1.0, ys[0])
  assert_true(small.is_close(1.0))
}
