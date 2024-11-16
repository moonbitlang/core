// Copyright 2024 International Digital Economy Academy
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

test "maximum.value" {
  assert_eq!(@math.maximum(1, 2), 2)
  assert_eq!(@math.maximum(2, 1), 2)
  assert_eq!(@math.maximum(2, 2), 2)
}

test "maximum.ref" {
  let v1 = 1
  let v2 = 2
  let x1 = T::{ x: v1 }
  let x2 = T::{ x: v2 }

  // We need another value that equals to x2 by value but not reference
  let x2t = T::{ x: v2 }
  @test.is_not!(x2, x2t)
  @test.is!(@math.maximum(x1, x2), x2)
  @test.is!(@math.maximum(x2, x1), x2)
  @test.is!(@math.maximum(x2, x2t), x2t)
  @test.is!(@math.maximum(x2t, x2), x2)
}

test "minimum.value" {
  assert_eq!(@math.minimum(1, 2), 1)
  assert_eq!(@math.minimum(2, 1), 1)
  assert_eq!(@math.minimum(2, 2), 2)
}

test "minimum.ref" {
  let v1 = 1
  let v2 = 2
  let x1 = T::{ x: v1 }
  let x2 = T::{ x: v2 }

  // We need another value that equals to x2 by value but not reference
  let x2t = T::{ x: v2 }
  @test.is_not!(x2, x2t)
  @test.is!(@math.minimum(x1, x2), x1)
  @test.is!(@math.minimum(x2, x1), x1)
  @test.is!(@math.minimum(x2, x2t), x2)
  @test.is!(@math.minimum(x2t, x2), x2t)
}

test "exp" {
  assert_eq!(@math.exp(1), 2.718281828459045)
  assert_eq!(@math.exp(-1), 0.36787944117144233)
}

test "log" {
  inspect!(@math.ln(@math.exp(1)), content="1")
  inspect!(@math.log2(4), content="2")
  inspect!(@math.log10(10), content="1")
}

///|
// For testing purposes
priv struct T {
  x : Int
} derive(Show, Eq, Compare)
