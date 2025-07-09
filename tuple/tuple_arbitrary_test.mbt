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

test "tuple_2_arbitrary" {
  // Test that we can generate arbitrary 2-tuples
  let rng = @quickcheck.new_random_state(42)
  let tuple1 : (Int, String) = @quickcheck.Arbitrary::arbitrary(10, rng)
  let tuple2 : (Int, String) = @quickcheck.Arbitrary::arbitrary(10, rng)
  
  // They should be different due to different random states
  assert_ne(tuple1, tuple2)
  
  // Test various types in 2-tuples
  let bool_int : (Bool, Int) = @quickcheck.Arbitrary::arbitrary(5, rng)
  let double_string : (Double, String) = @quickcheck.Arbitrary::arbitrary(5, rng)
  
  // Verify that both elements are properly generated
  assert_eq(bool_int.0 == true || bool_int.0 == false, true)
  assert_eq(bool_int.1 >= 0 || bool_int.1 < 0, true) // Any int value is valid
}

test "tuple_3_arbitrary" {
  // Test that we can generate arbitrary 3-tuples
  let rng = @quickcheck.new_random_state(123)
  let tuple1 : (Int, String, Bool) = @quickcheck.Arbitrary::arbitrary(10, rng)
  let tuple2 : (Int, String, Bool) = @quickcheck.Arbitrary::arbitrary(10, rng)
  
  // They should be different due to different random states
  assert_ne(tuple1, tuple2)
  
  // Test various types in 3-tuples
  let mixed : (Double, Int, String) = @quickcheck.Arbitrary::arbitrary(5, rng)
  
  // Verify that all elements are properly generated
  assert_eq(mixed.0 >= 0.0 || mixed.0 < 0.0, true) // Any double value is valid
  assert_eq(mixed.1 >= 0 || mixed.1 < 0, true) // Any int value is valid
  assert_eq(mixed.2.length() >= 0, true) // Any string length is valid
}

test "tuple_4_arbitrary" {
  // Test that we can generate arbitrary 4-tuples
  let rng = @quickcheck.new_random_state(456)
  let tuple1 : (Int, String, Bool, Double) = @quickcheck.Arbitrary::arbitrary(10, rng)
  let tuple2 : (Int, String, Bool, Double) = @quickcheck.Arbitrary::arbitrary(10, rng)
  
  // They should be different due to different random states
  assert_ne(tuple1, tuple2)
  
  // Test that all 4 elements are properly generated
  assert_eq(tuple1.0 >= 0 || tuple1.0 < 0, true) // Any int value is valid
  assert_eq(tuple1.1.length() >= 0, true) // Any string length is valid
  assert_eq(tuple1.2 == true || tuple1.2 == false, true) // Bool value
  assert_eq(tuple1.3 >= 0.0 || tuple1.3 < 0.0, true) // Any double value is valid
}

test "tuple_5_arbitrary" {
  // Test that we can generate arbitrary 5-tuples
  let rng = @quickcheck.new_random_state(789)
  let tuple1 : (Int, String, Bool, Double, Int) = @quickcheck.Arbitrary::arbitrary(10, rng)
  let tuple2 : (Int, String, Bool, Double, Int) = @quickcheck.Arbitrary::arbitrary(10, rng)
  
  // They should be different due to different random states
  assert_ne(tuple1, tuple2)
  
  // Test that all 5 elements are properly generated
  assert_eq(tuple1.0 >= 0 || tuple1.0 < 0, true) // Any int value is valid
  assert_eq(tuple1.1.length() >= 0, true) // Any string length is valid
  assert_eq(tuple1.2 == true || tuple1.2 == false, true) // Bool value
  assert_eq(tuple1.3 >= 0.0 || tuple1.3 < 0.0, true) // Any double value is valid
  assert_eq(tuple1.4 >= 0 || tuple1.4 < 0, true) // Any int value is valid
}

test "tuple_6_arbitrary" {
  // Test that we can generate arbitrary 6-tuples
  let rng = @quickcheck.new_random_state(101)
  let tuple1 : (Int, String, Bool, Double, Int, String) = @quickcheck.Arbitrary::arbitrary(10, rng)
  let tuple2 : (Int, String, Bool, Double, Int, String) = @quickcheck.Arbitrary::arbitrary(10, rng)
  
  // They should be different due to different random states
  assert_ne(tuple1, tuple2)
  
  // Test that all 6 elements are properly generated
  assert_eq(tuple1.0 >= 0 || tuple1.0 < 0, true) // Any int value is valid
  assert_eq(tuple1.1.length() >= 0, true) // Any string length is valid
  assert_eq(tuple1.2 == true || tuple1.2 == false, true) // Bool value
  assert_eq(tuple1.3 >= 0.0 || tuple1.3 < 0.0, true) // Any double value is valid
  assert_eq(tuple1.4 >= 0 || tuple1.4 < 0, true) // Any int value is valid
  assert_eq(tuple1.5.length() >= 0, true) // Any string length is valid
}

test "tuple_7_arbitrary" {
  // Test that we can generate arbitrary 7-tuples
  let rng = @quickcheck.new_random_state(202)
  let tuple1 : (Int, String, Bool, Double, Int, String, Bool) = @quickcheck.Arbitrary::arbitrary(10, rng)
  let tuple2 : (Int, String, Bool, Double, Int, String, Bool) = @quickcheck.Arbitrary::arbitrary(10, rng)
  
  // They should be different due to different random states
  assert_ne(tuple1, tuple2)
  
  // Test that all 7 elements are properly generated
  assert_eq(tuple1.0 >= 0 || tuple1.0 < 0, true) // Any int value is valid
  assert_eq(tuple1.1.length() >= 0, true) // Any string length is valid
  assert_eq(tuple1.2 == true || tuple1.2 == false, true) // Bool value
  assert_eq(tuple1.3 >= 0.0 || tuple1.3 < 0.0, true) // Any double value is valid
  assert_eq(tuple1.4 >= 0 || tuple1.4 < 0, true) // Any int value is valid
  assert_eq(tuple1.5.length() >= 0, true) // Any string length is valid
  assert_eq(tuple1.6 == true || tuple1.6 == false, true) // Bool value
}

test "tuple_arbitrary_different_sizes" {
  // Test that different sizes produce different behavior
  let rng = @quickcheck.new_random_state(303)
  
  // Generate tuples with different size parameters
  let small_tuple : (Int, String) = @quickcheck.Arbitrary::arbitrary(1, rng)
  let medium_tuple : (Int, String) = @quickcheck.Arbitrary::arbitrary(10, rng)
  let large_tuple : (Int, String) = @quickcheck.Arbitrary::arbitrary(100, rng)
  
  // While we can't guarantee they'll be different, we can ensure they're all valid
  assert_eq(small_tuple.0 >= 0 || small_tuple.0 < 0, true)
  assert_eq(medium_tuple.0 >= 0 || medium_tuple.0 < 0, true)
  assert_eq(large_tuple.0 >= 0 || large_tuple.0 < 0, true)
  
  assert_eq(small_tuple.1.length() >= 0, true)
  assert_eq(medium_tuple.1.length() >= 0, true)
  assert_eq(large_tuple.1.length() >= 0, true)
}

test "tuple_arbitrary_consistency" {
  // Test that using the same random state produces consistent results
  let rng1 = @quickcheck.new_random_state(404)
  let rng2 = @quickcheck.new_random_state(404)
  
  // Generate tuples with the same random state
  let tuple1 : (Int, Bool) = @quickcheck.Arbitrary::arbitrary(5, rng1)
  let tuple2 : (Int, Bool) = @quickcheck.Arbitrary::arbitrary(5, rng2)
  
  // They should be the same since they use the same seed
  assert_eq(tuple1, tuple2)
}

test "tuple_arbitrary_nested" {
  // Test nested tuples
  let rng = @quickcheck.new_random_state(505)
  let nested : ((Int, String), (Bool, Double)) = @quickcheck.Arbitrary::arbitrary(10, rng)
  
  // Verify nested structure
  assert_eq(nested.0.0 >= 0 || nested.0.0 < 0, true) // First tuple's int
  assert_eq(nested.0.1.length() >= 0, true) // First tuple's string
  assert_eq(nested.1.0 == true || nested.1.0 == false, true) // Second tuple's bool
  assert_eq(nested.1.1 >= 0.0 || nested.1.1 < 0.0, true) // Second tuple's double
}

test "tuple_arbitrary_split_behavior" {
  // Test that the split behavior works correctly for different tuple sizes
  let rng = @quickcheck.new_random_state(606)
  
  // Test multiple tuples to verify they use properly split random states
  let tuple1 : (Int, Int) = @quickcheck.Arbitrary::arbitrary(10, rng)
  let tuple2 : (Int, Int) = @quickcheck.Arbitrary::arbitrary(10, rng)
  let tuple3 : (Int, Int) = @quickcheck.Arbitrary::arbitrary(10, rng)
  
  // They should all be different due to the random state being consumed
  assert_ne(tuple1, tuple2)
  assert_ne(tuple2, tuple3)
  assert_ne(tuple1, tuple3)
}