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
test "unwrap should return value on Some" {
  let some : Int? = Some(42)
  assert_eq(some.unwrap(), 42)
}

///|
test "Option::default should return None" {
  let x : Int? = Option::default()
  assert_eq(x, None)
}

///|
test "Option::default should return None for String" {
  let x : String? = Option::default()
  assert_eq(x, None)
}

///|
test "Option::default should return None for Bool" {
  let x : Bool? = Option::default()
  assert_eq(x, None)
}

///|
fn test_option_arg(x? : Int, y? : Int) -> Int {
  let x = x.unwrap_or(3)
  let y = y.unwrap_or(4)
  x + y
}

///|
test {
  inspect(test_option_arg(), content="7")
  inspect(test_option_arg(x=1), content="5")
  inspect(test_option_arg(y=2), content="5")
  inspect(test_option_arg(x=1, y=2), content="3")
}

///|
test "filter with predicate" {
  let some_even = Some(4)
  let some_odd = Some(3)
  let none : Int? = None
  assert_eq(some_even.filter(x => x % 2 == 0), Some(4))
  assert_eq(some_odd.filter(x => x % 2 == 0), None)
  assert_eq(none.filter(x => x % 2 == 0), None)
}

///|
test "bind chaining" {
  let safe_divide = (x : Int) => if x == 0 { None } else { Some(100 / x) }
  let some_value = Some(4)
  let result = some_value.bind(x => safe_divide(x))
  assert_eq(result, Some(25))
  let zero_value = Some(0)
  let result2 = zero_value.bind(x => safe_divide(x))
  assert_eq(result2, None)
  let none_value : Int? = None
  let result3 = none_value.bind(x => safe_divide(x))
  assert_eq(result3, None)
}

///|
test "unwrap_or with default value" {
  let x = Some(2)
  let y : Int? = None
  assert_eq(x.unwrap_or(100), 2)
  assert_eq(y.unwrap_or(100), 100)
  let none1 : Int? = None
  assert_eq(none1.unwrap_or(42), 42)
}
