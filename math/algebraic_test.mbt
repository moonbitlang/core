// Copyright 2025 International Digital Economy Academy
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
test "maximum.value" {
  // assert_eq(@math.maximum(1, 2), 2)
  inspect(1 |> maximum(2), content="2")
  // assert_eq(@math.maximum(2, 1), 2)
  inspect(2 |> maximum(1), content="2")
  // assert_eq(@math.maximum(2, 2), 2)
  inspect(2 |> maximum(2), content="2")
}

///|
test "maximum.ref" {
  let v1 = 1
  let v2 = 2
  let x1 = T::{ x: v1 }
  let x2 = T::{ x: v2 }

  // We need another value that equals to x2 by value but not reference
  let x2t = T::{ x: v2 }
  @test.is_not(x2, x2t)
  @test.same_object(@math.maximum(x1, x2), x2)
  @test.same_object(@math.maximum(x2, x1), x2)
  @test.same_object(@math.maximum(x2, x2t), x2t)
  @test.same_object(@math.maximum(x2t, x2), x2)
}

///|
test "minimum.value" {
  assert_eq(@math.minimum(1, 2), 1)
  assert_eq(@math.minimum(2, 1), 1)
  assert_eq(@math.minimum(2, 2), 2)
}

///|
test "minimum.ref" {
  let v1 = 1
  let v2 = 2
  let x1 = T::{ x: v1 }
  let x2 = T::{ x: v2 }

  // We need another value that equals to x2 by value but not reference
  let x2t = T::{ x: v2 }
  @test.is_not(x2, x2t)
  @test.same_object(@math.minimum(x1, x2), x1)
  @test.same_object(@math.minimum(x2, x1), x1)
  @test.same_object(@math.minimum(x2, x2t), x2)
  @test.same_object(@math.minimum(x2t, x2), x2t)
}

///|
test "cbrtf" {
  inspect(cbrtf(0), content="0")
  inspect(cbrtf(1), content="1")
  inspect(cbrtf(2), content="1.2599210739135742")
  inspect(cbrtf(3), content="1.4422495365142822")
  inspect(cbrtf(4), content="1.587401032447815")
  inspect(cbrtf(5), content="1.7099759578704834")
  inspect(cbrtf(-6), content="-1.8171205520629883")
  inspect(cbrtf(-7), content="-1.912931203842163")
  inspect(cbrtf(-8), content="-2")
  inspect(cbrtf(@float.not_a_number), content="NaN")
  inspect(cbrtf(@float.infinity), content="Infinity")
  inspect(cbrtf(@float.neg_infinity), content="-Infinity")
}

///|
test "hypotf" {
  inspect(hypotf(3, 4), content="5")
  inspect(hypotf(5, 12.0), content="13")
  inspect(hypotf(8, 15.0), content="17")
  inspect(hypotf(7, 24.0), content="25")
  inspect(hypotf(20, 21.0), content="29")
  inspect(hypotf(9, 40.0), content="41")
  inspect(hypotf(12, 35.0), content="37")
  inspect(hypotf(11, 60.0), content="61")
  inspect(hypotf(16, 63.0), content="65")
  inspect(hypotf(@float.not_a_number, 1.0), content="NaN")
  inspect(hypotf(1, @float.not_a_number), content="NaN")
  inspect(hypotf(@float.infinity, 1.0), content="Infinity")
  inspect(hypotf(1.0, @float.infinity), content="Infinity")
  inspect(hypotf(@float.neg_infinity, 1.0), content="Infinity")
  inspect(hypotf(1, @float.neg_infinity), content="Infinity")
}

///|
// For testing purposes
priv struct T {
  x : Int
} derive(Show, Eq, Compare)
