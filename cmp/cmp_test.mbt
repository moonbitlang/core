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
test "maximum_by_key" {
  inspect(@cmp.maximum_by_key(1, -2, @int.abs), content="-2")
  inspect(@cmp.maximum_by_key(-2, 1, @int.abs), content="-2")
  inspect(@cmp.maximum_by_key(-2, 2, @int.abs), content="2")
}

///|
test "minimum_by_key" {
  inspect(@cmp.minimum_by_key(1, -2, @int.abs), content="1")
  inspect(@cmp.minimum_by_key(-2, 1, @int.abs), content="1")
  inspect(@cmp.minimum_by_key(-2, 2, @int.abs), content="-2")
}

///|
test "maximum.value" {
  // inspect(@math.maximum(1, 2), content="2")
  inspect(1 |> maximum(2), content="2")
  // inspect(@math.maximum(2, 1), content="2")
  inspect(2 |> maximum(1), content="2")
  // inspect(@math.maximum(2, 2), content="2")
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
  @test.same_object(@cmp.maximum(x1, x2), x2)
  @test.same_object(@cmp.maximum(x2, x1), x2)
  @test.same_object(@cmp.maximum(x2, x2t), x2t)
  @test.same_object(@cmp.maximum(x2t, x2), x2)
}

///|
test "minimum.value" {
  inspect(@cmp.minimum(1, 2), content="1")
  inspect(@cmp.minimum(2, 1), content="1")
  inspect(@cmp.minimum(2, 2), content="2")
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
  @test.same_object(@cmp.minimum(x1, x2), x1)
  @test.same_object(@cmp.minimum(x2, x1), x1)
  @test.same_object(@cmp.minimum(x2, x2t), x2)
  @test.same_object(@cmp.minimum(x2t, x2), x2t)
}

// For testing purposes
///|
priv struct T {
  x : Int
} derive(Show, Eq, Compare)

///|
test "maximum_by_key with tuples" {
  let t1 = ("Alice", 85)
  let t2 = ("Bob", 92)
  let t3 = ("Charlie", 92)
  let max1 = @cmp.maximum_by_key(t1, t2, t => t.1)
  assert_eq(max1.0, "Bob")

  // When equal, returns second argument
  let max2 = @cmp.maximum_by_key(t2, t3, t => t.1)
  assert_eq(max2.0, "Charlie")
}

///|
test "minimum_by_key with strings" {
  let s1 = "hello"
  let s2 = "hi"
  let s3 = "hey"
  let min1 = @cmp.minimum_by_key(s1, s2, s => s.length())
  assert_eq(min1, "hi")

  // When equal, returns first argument
  let min2 = @cmp.minimum_by_key(s2, s3, s => s.length())
  assert_eq(min2, "hi")
}

///|
test "maximum and minimum with negative numbers" {
  assert_eq(@cmp.maximum(-5, -3), -3)
  assert_eq(@cmp.maximum(-3, -5), -3)
  assert_eq(@cmp.minimum(-5, -3), -5)
  assert_eq(@cmp.minimum(-3, -5), -5)

  // Edge case with zero
  assert_eq(@cmp.maximum(0, -1), 0)
  assert_eq(@cmp.minimum(0, -1), -1)
}
