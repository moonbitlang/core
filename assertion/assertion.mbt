// Copyright 2024 International Digital Economy Academy
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

pub fn assert_eq[T : Debug + Eq](
  a : T,
  b : T,
  ~loc : SourceLoc = _
) -> Result[Unit, String] {
  @test.eq(a, b, ~loc)
}

pub fn assert_ne[T : Debug + Eq](
  a : T,
  b : T,
  ~loc : SourceLoc = _
) -> Result[Unit, String] {
  @test.not_eq(a, b, ~loc)
}

pub fn assert_false(x : Bool, ~loc : SourceLoc = _) -> Result[Unit, String] {
  @test.is_false(x, ~loc)
}

pub fn assert_true(x : Bool, ~loc : SourceLoc = _) -> Result[Unit, String] {
  @test.is_true(x, ~loc)
}

/// Assert referential equality of two values.
///
/// Returns Ok if the two arguments are the same object by reference, using
/// `physical_equal`; raises an Error otherwise. Certain objects may be equal by
/// value, but they are different objects in the memory. This function checks
/// the latter.
///
/// # Examples
///
/// ```
/// let a = "4" + "2"
/// let b = "4" + "2"
/// assert_is(a, a)?  // this is okay
/// assert_is(a, b)?  // yields an error
/// ```
pub fn assert_is[T : Debug](
  a : T,
  b : T,
  ~loc : SourceLoc = _
) -> Result[Unit, String] {
  @test.is(a, b, ~loc)
}

/// Assert referential inequality of two values.
///
/// Returns Ok if the two arguments are NOT the same object by reference, using
/// `physical_equal`; raises an Error otherwise. Certain objects may be equal
/// by value, but they are different objects in the memory. This function
/// checks the latter.
///
/// # Examples
///
/// ```
/// let a = "4" + "2"
/// let b = "4" + "2"
/// assert_is_not(a, b)?  // this is okay
/// assert_is_not(a, a)?  // yields an error
/// ```
pub fn assert_is_not[T : Debug](
  a : T,
  b : T,
  ~loc : SourceLoc = _
) -> Result[Unit, String] {
  @test.is_not(a, b, ~loc)
}
