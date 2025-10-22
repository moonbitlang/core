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
test "some equals to Some" {
  let x : Int? = Some(5)
  let y : Int? = some(5)
  assert_eq(x, y)
}

///|
/// Maps the value of an `Option` using a provided function.
///
/// # Example
///
/// ```mbt
///   let a = Some(5)
///   assert_eq(a.map(x => x * 2), Some(10))
///
///   let b = None
///   assert_eq(b.map(x => x * 2), None)
/// ```
pub fn[T, U] Option::map(self : T?, f : (T) -> U raise?) -> U? raise? {
  match self {
    Some(t) => Some(f(t))
    None => None
  }
}

///|
test "map" {
  let a = Some(5)
  let b : Int? = None
  assert_eq(a.map(x => x * 2), Some(10))
  assert_eq(b.map(x => x * 2), None)
}

///|
/// Returns the provided default result (if none), or applies a function to the contained value (if any).
/// Arguments passed to map_or are eagerly evaluated; if you are passing the result of a function call, it is recommended to use `map_or_else`, which is lazily evaluated.
///
/// # Example
///
/// ```mbt
///   let a = Some(5)
///   assert_eq(a.map_or(3, x => x * 2), 10)
/// ```
pub fn[T, U] Option::map_or(
  self : T?,
  default : U,
  f : (T) -> U raise?,
) -> U raise? {
  match self {
    None => default
    Some(x) => f(x)
  }
}

///|
test "map_or" {
  let a = Option::Some("foo")
  let b : String? = Option::None
  assert_eq(a.map_or(42, x => x.length()), 3)
  assert_eq(b.map_or(42, x => x.length()), 42)
}

///|
/// Computes a default function result (if none), or applies a different function to the contained value (if any).
///
/// # Example
///
/// ```mbt
///   let a = Some(5)
///   assert_eq(a.map_or_else(() => 3, x => x * 2), 10)
/// ```
pub fn[T, U] Option::map_or_else(
  self : T?,
  default : () -> U raise?,
  f : (T) -> U raise?,
) -> U raise? {
  match self {
    None => default()
    Some(x) => f(x)
  }
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
/// Binds an option to a function that returns another option.
///
/// # Example
///
/// ```mbt
///   let a = Option::Some(5)
///   let r1 = a.bind(x => Some(x * 2))
///   assert_eq(r1, Some(10))
///   let b : Option[Int] = None
///   let r2 = b.bind(x => Some(x * 2))
///   assert_eq(r2, None)
/// ```
pub fn[T, U] Option::bind(self : T?, f : (T) -> U? raise?) -> U? raise? {
  match self {
    Some(t) => f(t)
    None => None
  }
}

///|
test "bind" {
  let a = Option::Some(5)
  let b : Int? = None
  assert_eq(a.bind(x => Some(x * 2)), Some(10))
  assert_eq(b.bind(x => Some(x * 2)), None)
}

///|
/// Flattens an `Option` of `Option` into a single `Option`.
///
/// If the input `Option` is `Some(Some(value))`, the function returns `Some(value)`.
///
/// # Example
///
/// ```mbt
///   let a = Some(Some(42));
///   assert_eq(a.flatten(), Some(42))
///   let b : Int?? = Some(None)
///   assert_eq(b.flatten(), None)
/// ```
pub fn[T] Option::flatten(self : T??) -> T? {
  match self {
    Some(inner) => inner
    None => None
  }
}

///|
test "flatten" {
  let a : Int?? = Some(Some(42))
  assert_eq(a.flatten(), Some(42))
  let b : Int?? = Some(None)
  assert_eq(b.flatten(), None)
}

///|
/// Checks if the option is empty.
pub fn[T] Option::is_empty(self : T?) -> Bool {
  self is None
}

///|
test "is_empty" {
  let x = Option::Some(3)
  let y : Int? = None
  assert_false(x.is_empty())
  assert_true(y.is_empty())
}

///|
/// Filters the option by applying the given predicate function `f`.
///
/// If the predicate function `f` returns `true` for the value contained in the option,
/// the same option is returned. Otherwise, `None` is returned.
///
/// # Example
/// ```mbt
///   let x = Some(3)
///   assert_eq(x.filter(x => x > 5), None)
///   assert_eq(x.filter(x => x < 5), Some(3))
/// ```
pub fn[T] Option::filter(self : T?, f : (T) -> Bool raise?) -> T? raise? {
  match self {
    Some(t) => if f(t) { self } else { None }
    None => None
  }
}

///|
test "filter" {
  let x = Option::Some(3)
  assert_eq(x.filter(x => x > 5), None)
  assert_eq(x.filter(x => x < 5), Some(3))
}

///|
/// Return the contained `Some` value or the provided default.
pub fn[T] Option::unwrap_or(self : T?, default : T) -> T {
  match self {
    None => default
    Some(t) => t
  }
}

///|
test "unwrap_or" {
  let x = Option::Some(3)
  assert_eq(x.unwrap_or(5), 3)
  assert_eq((None : Int?).unwrap_or(5), 5)
}

///|
/// Return the contained `Some` value or the provided default.
///
/// Default is lazily evaluated
pub fn[T] Option::unwrap_or_else(
  self : T?,
  default : () -> T raise?,
) -> T raise? {
  match self {
    None => default()
    Some(t) => t
  }
}

///|
test "or else" {
  let x = Option::Some(3)
  assert_eq(x.unwrap_or_else(() => 5), 3)
  assert_eq(None.unwrap_or_else(() => 5), 5)
}

///|
/// Return the contained `Some` value or the result of the `T::default()`.
pub fn[T : Default] Option::unwrap_or_default(self : T?) -> T {
  match self {
    None => T::default()
    Some(t) => t
  }
}

///|
test "or default" {
  let x = Option::Some(3)
  assert_eq(x.unwrap_or_default(), 3)
  assert_eq((None : Int?).unwrap_or_default(), 0)
}

///|
pub impl[X : Compare] Compare for X? with compare(self, other) {
  match (self, other) {
    (Some(x), Some(y)) => x.compare(y)
    (Some(_), None) => 1
    (None, Some(_)) => -1
    (None, None) => 0
  }
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
/// `None`
pub impl[X] Default for X? with default() {
  None
}

///|
pub fn[T] Option::iter(self : T?) -> Iter[T] {
  match self {
    Some(v) => Iter::singleton(v)
    None => Iter::empty()
  }
}

///|
pub fn[T] Option::iterator(self : T?) -> Iterator[T] {
  match self {
    Some(v) => Iterator::singleton(v)
    None => Iterator::empty()
  }
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
pub fn[T, Err : Error] Option::or_error(self : T?, err : Err) -> T raise Err {
  match self {
    Some(v) => v
    None => raise err
  }
}

///|
test "or error" {
  assert_eq(
    (None : String?).or_error(Failure("This is serious")) catch {
      Failure(err) => err
    },
    "This is serious",
  )
  assert_eq(
    Some("This is ok").or_error(Failure("This is serious")) catch {
      Failure(err) => err
    },
    "This is ok",
  )
}

///|
pub impl[X : @quickcheck.Arbitrary] @quickcheck.Arbitrary for X? with arbitrary(
  i,
  rs,
) {
  if rs.next_double() < 0.3 {
    None
  } else {
    Some(@quickcheck.Arbitrary::arbitrary(i, rs))
  }
}

///|
test "arbitrary" {
  let samples : Array[Int?] = @quickcheck.samples(10)
  inspect(
    samples,
    content="[None, None, Some(-1), Some(0), None, Some(0), Some(-5), Some(2), None, Some(4)]",
  )
}
