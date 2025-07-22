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

///|
// For testing purposes
priv struct T {
  x : Int
} derive(Show, Eq, Compare)

///|
/// Test comparison functions with various numeric types
test "cmp functions with different numeric types" {
  // Test with Double
  inspect(@cmp.maximum(1.5, 2.7), content="2.7")
  inspect(@cmp.minimum(1.5, 2.7), content="1.5")
  inspect(@cmp.maximum(3.14, 3.14), content="3.14")

  // Test with UInt
  inspect(@cmp.maximum(10U, 5U), content="10")
  inspect(@cmp.minimum(10U, 5U), content="5")

  // Test with Int64  
  inspect(@cmp.maximum(100L, 200L), content="200")
  inspect(@cmp.minimum(100L, 200L), content="100")
}

///|
/// Test comparison edge cases with equal values
test "comparison with equal values" {
  // Test maximum returns second when equal
  let a = 42
  let b = 42
  let max_result = @cmp.maximum(a, b)
  @test.same_object(max_result, b)

  // Test minimum returns first when equal
  let min_result = @cmp.minimum(a, b)
  @test.same_object(min_result, a)

  // Test with different objects but equal values
  let obj1 = T::{ x: 10 }
  let obj2 = T::{ x: 10 }
  @test.same_object(@cmp.maximum(obj1, obj2), obj2)
  @test.same_object(@cmp.minimum(obj1, obj2), obj1)
}

///|
/// Test comparison functions with extreme values
test "comparison with extreme values" {
  // Test with maximum and minimum integers
  let max_int = 2147483647 // Int max
  let min_int = -2147483648 // Int min
  assert_eq(@cmp.maximum(max_int, min_int), max_int)
  assert_eq(@cmp.minimum(max_int, min_int), min_int)

  // Test with zero
  assert_eq(@cmp.maximum(0, -1), 0)
  assert_eq(@cmp.minimum(0, 1), 0)

  // Test with very close doubles
  let d1 = 1.0000000001
  let d2 = 1.0000000002
  assert_eq(@cmp.maximum(d1, d2), d2)
  assert_eq(@cmp.minimum(d1, d2), d1)
}

///|
/// Test chaining comparison operations
test "chained comparison operations" {
  let values = [1, 5, 3, 9, 2]

  // Find maximum of first two, then compare with third
  let partial_max = @cmp.maximum(values[0], values[1])
  let extended_max = @cmp.maximum(partial_max, values[2])
  assert_eq(extended_max, 5)

  // Chain multiple minimum operations
  let min1 = @cmp.minimum(values[0], values[1])
  let min2 = @cmp.minimum(min1, values[4])
  assert_eq(min2, 1)
}

///|
/// Test maximum_by_key and minimum_by_key with simple key functions
test "key-based comparison with simple key functions" {
  // Test with absolute value
  inspect(@cmp.maximum_by_key(-2, 1, @int.abs), content="-2")
  inspect(@cmp.minimum_by_key(-2, 1, @int.abs), content="1")

  // Test with negative transformation
  fn negate(x : Int) -> Int {
    -x
  }

  inspect(@cmp.maximum_by_key(3, 5, negate), content="3") // -3 > -5
  inspect(@cmp.minimum_by_key(3, 5, negate), content="5") // -5 < -3
}
