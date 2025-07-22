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
test {
  let unit1 = ()
  let unit2 = ()
  assert_eq(unit1, unit2)
}

///|
test {
  let unit1 = ()
  let unit2 = ()
  assert_true(physical_equal(unit1, unit2))
}

///|
test {
  let unit = ()
  assert_eq(@unit.default(), unit)
  inspect(unit.to_string(), content="()")
}

///|
test {
  let unit1 = ()
  let unit2 = ()
  inspect(unit1.compare(unit2), content="0")
}

///|
test {
  let unit = ()
  inspect(unit.hash(), content="0")
}

///|
test "Unit hash_combine test" {
  let hasher = Hasher::new()
  let _ = Hash::hash_combine((), hasher)
  let hash1 = hasher.finalize()
  let hasher2 = Hasher::new()
  assert_not_eq(hash1, hasher2.finalize())
}

///|
test "Unit::default returns unit value" {
  let unit = Unit::default()
  inspect(unit, content="()")
}

///|
/// Test Unit behavior in collection contexts
test "Unit in collections" {
  let unit_array = [(), (), ()]
  assert_eq(unit_array.length(), 3)

  // All units should be equal
  for i = 0; i < unit_array.length(); i = i + 1 {
    assert_eq(unit_array[i], ())
  }

  // Test Unit in option
  let some_unit : Unit? = Some(())
  let none_unit : Unit? = None
  assert_true(some_unit != none_unit)
}

///|
/// Test Unit hashing properties
test "Unit hashing consistency" {
  let hasher1 = Hasher::new()
  let hasher2 = Hasher::new()

  // Hash the same unit value multiple times
  Hash::hash_combine((), hasher1)
  Hash::hash_combine((), hasher2)
  let hash1 = hasher1.finalize()
  let hash2 = hasher2.finalize()

  // Should produce identical hashes
  assert_eq(hash1, hash2)

  // Hash should be deterministic
  assert_eq(().hash(), 0)
}

///|
/// Test Unit comparison properties
test "Unit comparison properties" {
  let unit1 = ()
  let unit2 = ()
  let unit3 = Unit::default()

  // Reflexivity
  assert_eq(unit1.compare(unit1), 0)

  // Symmetry
  assert_eq(unit1.compare(unit2), unit2.compare(unit1))

  // All units compare equal
  assert_eq(unit1.compare(unit2), 0)
  assert_eq(unit1.compare(unit3), 0)
  assert_eq(unit2.compare(unit3), 0)
}

///|
/// Test Unit as function parameter and return type
test "Unit in functional contexts" {
  fn takes_unit(u : Unit) -> String {
    let _ = u
    "received unit"
  }

  fn returns_unit() -> Unit {
    ()
  }

  fn unit_to_unit(u : Unit) -> Unit {
    let _ = u
    ()
  }

  let result1 = takes_unit(())
  assert_eq(result1, "received unit")
  let result2 = returns_unit()
  assert_eq(result2, ())
  let result3 = unit_to_unit(())
  assert_eq(result3, ())
}
