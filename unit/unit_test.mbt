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

test "unit_to_string" {
  // Test that unit values convert to string correctly
  let unit_val : Unit = ()
  assert_eq(unit_val.to_string(), "()")
  
  // Test various unit expressions
  assert_eq(().to_string(), "()")
  
  // Test unit from function return
  fn returns_unit() -> Unit { () }
  assert_eq(returns_unit().to_string(), "()")
  
  // Test unit in various contexts
  let unit_array = [(), (), ()]
  assert_eq(unit_array[0].to_string(), "()")
  assert_eq(unit_array[1].to_string(), "()")
  assert_eq(unit_array[2].to_string(), "()")
}

test "unit_hash" {
  // Test that unit values hash consistently
  let unit1 : Unit = ()
  let unit2 : Unit = ()
  
  assert_eq(unit1.hash(), unit2.hash())
  assert_eq(unit1.hash(), 0)
  assert_eq(unit2.hash(), 0)
  
  // Test unit hash in various contexts
  let unit_from_fn = { () }
  assert_eq(unit_from_fn.hash(), 0)
  
  // Test multiple unit values have same hash
  let units = [(), (), (), (), ()]
  for unit_val in units {
    assert_eq(unit_val.hash(), 0)
  }
}

test "unit_hash_combine" {
  // Test that unit values can be combined with hasher
  let unit_val : Unit = ()
  let hasher = @builtin.new_hasher()
  
  // Test hash_combine returns unit
  let result = unit_val.hash_combine(hasher)
  assert_eq(result, ())
  
  // Test multiple hash_combine calls
  let unit1 : Unit = ()
  let unit2 : Unit = ()
  let hasher1 = @builtin.new_hasher()
  let hasher2 = @builtin.new_hasher()
  
  let result1 = unit1.hash_combine(hasher1)
  let result2 = unit2.hash_combine(hasher2)
  
  assert_eq(result1, result2)
  assert_eq(result1, ())
  assert_eq(result2, ())
}

test "unit_default" {
  // Test that default returns unit
  assert_eq(Unit::default(), ())
  assert_eq(default(), ())
  
  // Test that default values are equal
  let default1 = Unit::default()
  let default2 = default()
  assert_eq(default1, default2)
  
  // Test default in various contexts
  let default_array = [Unit::default(), default(), ()]
  assert_eq(default_array[0], default_array[1])
  assert_eq(default_array[1], default_array[2])
  assert_eq(default_array[0], default_array[2])
}

test "unit_compare" {
  // Test that unit values compare as equal
  let unit1 : Unit = ()
  let unit2 : Unit = ()
  
  assert_eq(unit1.compare(unit2), 0)
  assert_eq(unit2.compare(unit1), 0)
  
  // Test various unit expressions
  assert_eq(().compare(()), 0)
  
  // Test unit comparison in contexts
  let unit_from_fn1 = { () }
  let unit_from_fn2 = { () }
  assert_eq(unit_from_fn1.compare(unit_from_fn2), 0)
  
  // Test multiple unit values
  let units = [(), (), (), (), ()]
  for i in 0..<units.length() {
    for j in 0..<units.length() {
      assert_eq(units[i].compare(units[j]), 0)
    }
  }
}

test "unit_equality" {
  // Test that unit values are equal
  let unit1 : Unit = ()
  let unit2 : Unit = ()
  
  assert_eq(unit1, unit2)
  assert_eq(unit2, unit1)
  
  // Test with various unit expressions
  assert_eq((), ())
  
  // Test unit equality in contexts
  let unit_from_fn1 = { () }
  let unit_from_fn2 = { () }
  assert_eq(unit_from_fn1, unit_from_fn2)
  
  // Test unit equality with defaults
  assert_eq(Unit::default(), ())
  assert_eq(default(), ())
  assert_eq(Unit::default(), default())
}

test "unit_operations" {
  // Test that unit can be used in various operations
  let unit_val : Unit = ()
  
  // Test pattern matching
  match unit_val {
    () => assert_eq(true, true)
  }
  
  // Test in function calls
  fn takes_unit(u : Unit) -> String {
    u.to_string()
  }
  assert_eq(takes_unit(()), "()")
  
  // Test in collections
  let unit_list = [(), (), ()]
  assert_eq(unit_list.length(), 3)
  for unit_item in unit_list {
    assert_eq(unit_item, ())
  }
}

test "unit_in_tuples" {
  // Test unit values in tuple contexts
  let tuple_with_unit : (Unit, Int, Unit) = ((), 42, ())
  assert_eq(tuple_with_unit.0, ())
  assert_eq(tuple_with_unit.1, 42)
  assert_eq(tuple_with_unit.2, ())
  
  // Test unit comparison in tuples
  let tuple1 : (Unit, Unit) = ((), ())
  let tuple2 : (Unit, Unit) = ((), ())
  assert_eq(tuple1, tuple2)
  
  // Test unit hash in tuples
  let tuple_hash1 = tuple1.hash()
  let tuple_hash2 = tuple2.hash()
  assert_eq(tuple_hash1, tuple_hash2)
}

test "unit_consistency" {
  // Test that all unit operations are consistent
  let unit_val : Unit = ()
  
  // Test consistency across all operations
  assert_eq(unit_val.to_string(), "()")
  assert_eq(unit_val.hash(), 0)
  assert_eq(unit_val.compare(()), 0)
  assert_eq(unit_val, ())
  assert_eq(unit_val, Unit::default())
  assert_eq(unit_val, default())
  
  // Test that operations don't mutate the unit (though units are immutable anyway)
  let original_unit = unit_val
  let _ = unit_val.to_string()
  let _ = unit_val.hash()
  let _ = unit_val.compare(())
  assert_eq(unit_val, original_unit)
}
