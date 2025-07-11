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
  assert_eq(unit.to_string(), "()")
}

///|
test {
  let unit1 = ()
  let unit2 = ()
  assert_eq(unit1.compare(unit2), 0)
}

///|
test {
  let unit = ()
  assert_eq(unit.hash(), 0)
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
test "Unit to_string comprehensive testing" {
  let unit1 = ()
  let str1 = unit1.to_string()
  inspect(str1, content="()")
  let unit2 = Unit::default()
  let str2 = unit2.to_string()
  inspect(str2, content="()")

  // Test that all unit values have the same string representation
  let unit3 = 42
  let _ = unit3 // Use unit3 then ignore to create another unit
  let unit_result = ()
  let str3 = unit_result.to_string()
  inspect(str3, content="()")
}

///|
test "Unit compare comprehensive testing" {
  let unit1 = ()
  let unit2 = ()
  let unit3 = Unit::default()

  // All units should compare equal
  let cmp1 = unit1.compare(unit2)
  inspect(cmp1, content="0")
  let cmp2 = unit1.compare(unit3)
  inspect(cmp2, content="0")
  let cmp3 = unit2.compare(unit3)
  inspect(cmp3, content="0")

  // Self comparison
  let cmp4 = unit1.compare(unit1)
  inspect(cmp4, content="0")
}

///|
test "Unit hash comprehensive testing" {
  let unit1 = ()
  let hash1 = unit1.hash()
  inspect(hash1, content="0")
  let unit2 = Unit::default()
  let hash2 = unit2.hash()
  inspect(hash2, content="0")

  // All units should have the same hash
  let unit3 = ()
  let hash3 = unit3.hash()
  inspect(hash3, content="0")
  assert_eq(hash1, hash2)
  assert_eq(hash2, hash3)
}

///|
test "Unit default comprehensive testing" {
  let default1 = Unit::default()
  inspect(default1, content="()")
  let default2 = @unit.default()
  inspect(default2, content="()")

  // Test that default values are equal
  assert_eq(default1, default2)
  assert_eq(default1, ())
  assert_eq(default2, ())
}
