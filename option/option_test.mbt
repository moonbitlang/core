// Copyright 2026 International Digital Economy Academy
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

///|
test "some equals to Some" {
  let x : Int? = Some(5)
  let y : Int? = Some(5)
  assert_eq(x, y)
}

///|
test "map" {
  let a = Some(5)
  let b : Int? = None
  assert_eq(a.map(x => x * 2), Some(10))
  assert_eq(b.map(x => x * 2), None)
}

///|
test "map_or" {
  let a = Option::Some("foo")
  let b : String? = Option::None
  assert_eq(a.map_or(42, x => x.length()), 3)
  assert_eq(b.map_or(42, x => x.length()), 42)
}

///|
test "map_or_else" {
  let k = 21
  let a = Option::Some("foo")
  let b : String? = Option::None
  assert_eq(a.map_or_else(() => 2 * k, x => x.length()), 3)
  assert_eq(b.map_or_else(() => 2 * k, x => x.length()), 42)
}

///|
test "bind" {
  let a = Option::Some(5)
  let b : Int? = None
  assert_eq(a.bind(x => Some(x * 2)), Some(10))
  assert_eq(b.bind(x => Some(x * 2)), None)
}

///|
test "flatten" {
  let a : Int?? = Some(Some(42))
  assert_eq(a.bind(fn(x) { x }), Some(42))
  let b : Int?? = Some(None)
  assert_eq(b.bind(fn(x) { x }), None)
}

///|
test "is_empty" {
  let x = Option::Some(3)
  let y : Int? = None
  assert_false(x is None)
  assert_true(y is None)
}

///|
test "filter" {
  let x = Option::Some(3)
  assert_eq(x.filter(x => x > 5), None)
  assert_eq(x.filter(x => x < 5), Some(3))
}

///|
test "unwrap_or" {
  let x = Option::Some(3)
  assert_eq(x.unwrap_or(5), 3)
  assert_eq((None : Int?).unwrap_or(5), 5)
}

///|
test "or else" {
  let x = Option::Some(3)
  assert_eq(x.unwrap_or_else(() => 5), 3)
  assert_eq(None.unwrap_or_else(() => 5), 5)
}

///|
test "or default" {
  let x = Option::Some(3)
  assert_eq(x.unwrap_or_default(), 3)
  assert_eq((None : Int?).unwrap_or_default(), 0)
}

///|
test "compare" {
  let some1 = Option::Some(1)
  let some2 = Option::Some(2)
  let none = Option::None
  assert_eq(0, some1.compare(Option::Some(1)))
  assert_eq(-1, some1.compare(some2))
  assert_eq(1, some2.compare(some1))
  assert_eq(0, none.compare(none))
  assert_eq(-1, none.compare(some1))
  assert_eq(1, some2.compare(none))
}

///|
test "iter" {
  let x = Option::Some(42)
  let exb = StringBuilder::new(size_hint=0)
  x
  .iter()
  .each(x => {
    exb.write_string(x.to_string())
    exb.write_char('\n')
  })
  inspect(
    exb,
    content=(
      #|42
      #|
    ),
  )
  exb.reset()
  let y : Int? = None
  y
  .iter()
  .each(x => {
    exb.write_string(x.to_string())
    exb.write_char('\n')
  })
  inspect(exb, content="")
}

///|
test "or error" {
  assert_eq(
    (None : String?).unwrap_or_error(Failure::Failure("This is serious")) catch {
      Failure(err) => err
    },
    "This is serious",
  )
  assert_eq(
    Some("This is ok").unwrap_or_error(Failure::Failure("This is serious")) catch {
      Failure(err) => err
    },
    "This is ok",
  )
}

///|
test "arbitrary" {
  let samples : Array[Int?] = @quickcheck.samples(10)
  inspect(
    samples,
    content="[None, None, Some(-1), Some(0), None, Some(0), Some(-5), Some(2), None, Some(4)]",
  )
}

///|
test "optional interpolation" {
  let some_value : Int? = Some(10)
  let none_value : Int? = None
  @json.inspect([1, 2, 3, ..some_value, ..none_value, 4, 5], content=[
    1, 2, 3, 10, 4, 5,
  ])
}
