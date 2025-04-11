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
test "test_tuple3_eq" {
  let t1 : (Int, String, Bool) = (1, "a", true)
  let t2 : (Int, String, Bool) = (1, "a", true)
  let t3 : (Int, String, Bool) = (2, "a", true)
  inspect!(t1 == t2, content="true")
  inspect!(t1 == t3, content="false")
}

///|
test "test tuple4 equality - same values" {
  let t1 : (Int, Int, Int, Int) = (1, 2, 3, 4)
  let t2 : (Int, Int, Int, Int) = (1, 2, 3, 4)
  assert_true!(t1 == t2)
}

///|
test "test_tuple7_equality" {
  let t1 = (1, "a", true, 42.0, 'x', [1, 2], "hello")
  let t2 = (1, "a", true, 42.0, 'x', [1, 2], "hello")
  let t3 = (2, "a", true, 42.0, 'x', [1, 2], "hello")
  assert_true!(t1 == t2)
  assert_false!(t1 == t3)
}

///|
test "test tuple8 equality" {
  let t1 = (1, "hello", true, 42L, 3.14, 'a', [1, 2], "world")
  let t2 = (1, "hello", true, 42L, 3.14, 'a', [1, 2], "world")
  let t3 = (2, "hello", true, 42L, 3.14, 'a', [1, 2], "world")
  inspect!(t1 == t2, content="true")
  inspect!(t1 == t3, content="false")
}

///|
test "tuple9 equal" {
  let t1 = (1, 2, 3, 4, 5, 6, 7, 8, 9)
  let t2 = (1, 2, 3, 4, 5, 6, 7, 8, 9)
  inspect!(t1 == t2, content="true")
}

///|
test "tuple10_equality" {
  // Test case 1: identical tuples
  let t1 = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
  let t2 = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
  inspect!(t1 == t2, content="true")

  // Test case 2: tuples differ at first element
  let t3 = (0, 2, 3, 4, 5, 6, 7, 8, 9, 10)
  inspect!(t1 == t3, content="false")
}

///|
test "Tuple11::op_equal with equal tuples" {
  let t1 = (1, "a", true, 1.0, b'x', false, 42, 'c', -1, "hello", 100)
  let t2 = (1, "a", true, 1.0, b'x', false, 42, 'c', -1, "hello", 100)
  inspect!(t1 == t2, content="true")
}

///|
test "tuple12_equal_same_values" {
  let t1 = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)
  let t2 = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)
  assert_true!(t1 == t2)
}

///|
test "tuple14_equal_true" {
  let t1 : (
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
  ) = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
  let t2 = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
  inspect!(t1 == t2, content="true")
}

///|
test "tuple15_eq_same_values" {
  let t1 = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
  let t2 = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
  inspect!(t1 == t2, content="true")
}

///|
test "tuple16_equal" {
  let t1 = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
  let t2 = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
  let t3 = (1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
  assert_true!(t1 == t2)
  assert_false!(t1 == t3)
  assert_eq!(t1, t2)
  assert_not_eq!(t1, t3)
}

///|
test "test tuple5 equality with equal values" {
  let t1 = (1, "a", true, 3.14, 42)
  let t2 = (1, "a", true, 3.14, 42)
  inspect!(t1 == t2, content="true")
}

///|
test "tuple6 equal" {
  let t1 = (1, "a", true, 2.0, 'b', 3U)
  let t2 = (1, "a", true, 2.0, 'b', 3U)
  assert_true!(t1 == t2)
}

///|
test "tuple13_equal_test_same_values" {
  let t1 = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13)
  let t2 = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13)
  inspect!(t1 == t2, content="true")
}
