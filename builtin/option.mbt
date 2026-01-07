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
pub impl[X : Eq] Eq for X? with equal(self, other) {
  match (self, other) {
    (None, None) => true
    (Some(x), Some(y)) => x == y
    _ => false
  }
}

///|
pub fn[X : Show] Option::to_string(self : X?) -> String {
  match self {
    None => "None"
    Some(x) => "Some(" + x.to_string() + ")"
  }
}

///|
/// Extract the value in `Some`.
/// 
/// If the value is `None`, it throws a panic.
pub fn[X] Option::unwrap(self : X?) -> X {
  match self {
    None => panic()
    Some(x) => x
  }
}

///|
/// Return the contained `Some` value or the provided default.
#alias(or, deprecated)
pub fn[T] Option::unwrap_or(self : T?, default : T) -> T {
  match self {
    None => default
    Some(t) => t
  }
}

///|
/// Return the contained `Some` value or the provided default.
///
/// Default is lazily evaluated
#alias(or_else, deprecated)
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
/// Return the contained `Some` value or the result of the `T::default()`.
#alias(or_default, deprecated)
pub fn[T : Default] Option::unwrap_or_default(self : T?) -> T {
  match self {
    None => T::default()
    Some(t) => t
  }
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
#alias(or_error, deprecated)
pub fn[T, Err : Error] Option::unwrap_or_error(
  self : T?,
  err : Err,
) -> T raise Err {
  match self {
    Some(v) => v
    None => raise err
  }
}

///|
/// `None`
pub impl[X] Default for X? with default() {
  None
}

///|
#alias(iterator, deprecated)
pub fn[T] Option::iter(self : T?) -> Iter[T] {
  match self {
    Some(v) => Iter::singleton(v)
    None => Iter::empty()
  }
}

///|
/// Maps the value of an `Option` using a provided function.
///
/// # Example
///
/// ```mbt check
/// test {
///   let a = Some(5)
///   assert_eq(a.map(x => x * 2), Some(10))
///   let b = None
///   assert_eq(b.map(x => x * 2), None)
/// }
/// ```
pub fn[T, U] Option::map(self : T?, f : (T) -> U raise?) -> U? raise? {
  match self {
    Some(t) => Some(f(t))
    None => None
  }
}

///|
/// Returns the provided default result (if none), or applies a function to the contained value (if any).
/// Arguments passed to map_or are eagerly evaluated; if you are passing the result of a function call, it is recommended to use `map_or_else`, which is lazily evaluated.
///
/// # Example
///
/// ```mbt check
/// test {
///   let a = Some(5)
///   assert_eq(a.map_or(3, x => x * 2), 10)
/// }
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
/// Computes a default function result (if none), or applies a different function to the contained value (if any).
///
/// # Example
///
/// ```mbt check
/// test {
///   let a = Some(5)
///   assert_eq(a.map_or_else(() => 3, x => x * 2), 10)
/// }
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
/// Binds an option to a function that returns another option.
///
/// # Example
///
/// ```mbt check
/// test {
///   let a = Option::Some(5)
///   let r1 = a.bind(x => Some(x * 2))
///   assert_eq(r1, Some(10))
///   let b : Int? = None
///   let r2 = b.bind(x => Some(x * 2))
///   assert_eq(r2, None)
/// }
/// ```
pub fn[T, U] Option::bind(self : T?, f : (T) -> U? raise?) -> U? raise? {
  match self {
    Some(t) => f(t)
    None => None
  }
}

///|
#deprecated("use `option.bind(x => x)` instead")
pub fn[T] Option::flatten(self : T??) -> T? {
  match self {
    Some(inner) => inner
    None => None
  }
}

///|
/// Checks if the option is empty.
#deprecated("use `x is None` instead")
pub fn[T] Option::is_empty(self : T?) -> Bool {
  self is None
}

///|
/// Filters the option by applying the given predicate function `f`.
///
/// If the predicate function `f` returns `true` for the value contained in the option,
/// the same option is returned. Otherwise, `None` is returned.
///
/// # Example
/// ```mbt check
/// test {
///   let x = Some(3)
///   assert_eq(x.filter(x => x > 5), None)
///   assert_eq(x.filter(x => x < 5), Some(3))
/// }
/// ```
pub fn[T] Option::filter(self : T?, f : (T) -> Bool raise?) -> T? raise? {
  match self {
    Some(t) => if f(t) { self } else { None }
    None => None
  }
}

///|
/// Checks if the option contains a value.
#deprecated("use `x is Some(_)` instead")
pub fn[T] Option::is_some(self : T?) -> Bool {
  self is Some(_)
}

///|
/// Checks if the option is None.
#deprecated("use `x is None` instead")
pub fn[T] Option::is_none(self : T?) -> Bool {
  self is None
}
