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

// These tests *document* what `physical_equal` currently does with a
// `#valtype` struct; they do not specify it. `physical_equal` is a performance
// hint whose result "may not be consistent across different backends and/or
// different compiler optimization settings" (see `intrinsics.mbt`), and
// `#valtype` is precisely an instruction to change a type's representation --
// so this is the corner where that warning is at its sharpest. Nothing outside
// these files should depend on the answers.
//
// Unlike the NaN cases, the answers here genuinely differ by target, because
// they follow the representation rather than the source:
//
//   * native / llvm / wasm -- a `#valtype` struct is unboxed, so there is no
//     identity to compare and `physical_equal` degrades to a field-wise value
//     comparison. Two independently constructed `Point`s with equal fields are
//     "physically equal".
//   * js / wasm-gc -- a multi-field `#valtype` struct is still a heap object,
//     so `physical_equal` stays identity comparison and those same two
//     `Point`s are not equal.
//
// This file holds the cases that agree on every target. The divergent ones live
// in `physical_equal_valtype_unboxed_test.mbt` and
// `physical_equal_valtype_boxed_test.mbt`, split by `options(targets:)` in
// `moon.pkg`, so that each target group's answer is written down explicitly
// rather than hidden behind a conditional.

///|
/// The struct under test, and an ordinary (reference-represented) struct with
/// the same fields to contrast against.
#valtype
struct Point {
  x : Int
  y : Int
}

///|
struct RefPoint {
  x : Int
  y : Int
}

///|
fn[T] physical_equal_via_generic(a : T, b : T) -> Bool {
  physical_equal(a, b)
}

///|
/// A `Point` is always physically equal to itself, on every target -- though
/// for two different reasons: identity on js/wasm-gc, and a field-wise
/// comparison that happens to succeed on native/llvm/wasm.
test "physical_equal on a #valtype struct is reflexive" {
  let p = Point::{ x: 1, y: 2 }
  inspect(physical_equal(p, p), content="true")
  inspect(physical_equal_via_generic(p, p), content="true")
  // Keep the fields read so they are not reported as unused.
  inspect(p.x + p.y, content="3")
}

///|
/// `Point`s that differ are never physically equal, on any target. Note that
/// this holds even for a difference in a single field, so the unboxed targets'
/// field-wise comparison is not a partial or first-field-only one.
test "physical_equal on distinct #valtype values" {
  let p = Point::{ x: 1, y: 2 }
  let different_x = Point::{ x: 9, y: 2 }
  let different_y = Point::{ x: 1, y: 9 }
  inspect(physical_equal(p, different_x), content="false")
  inspect(physical_equal(p, different_y), content="false")
  inspect(physical_equal_via_generic(p, different_y), content="false")
}

///|
/// The contrast case: an ordinary struct is reference-represented on every
/// target, so `physical_equal` is identity everywhere and two equal-valued
/// `RefPoint`s are never physically equal. This is the behavior `#valtype`
/// changes on the unboxed targets.
test "physical_equal on an ordinary struct is identity everywhere" {
  let a = RefPoint::{ x: 1, y: 2 }
  let b = RefPoint::{ x: 1, y: 2 }
  inspect(physical_equal(a, a), content="true")
  inspect(physical_equal(a, b), content="false")
  inspect(physical_equal_via_generic(a, b), content="false")
  inspect(a.x + b.y, content="3")
}

///|
/// Copying a `Point` through a container does not create a distinguishable
/// value on any target: both reads come back physically equal to the original.
/// On js/wasm-gc that is because the same reference was stored twice; on
/// native/llvm/wasm it is because the copied fields still compare equal.
test "physical_equal on #valtype values read back from an array" {
  let p = Point::{ x: 1, y: 2 }
  let arr : ReadOnlyArray[Point] = [p, p]
  inspect(physical_equal(arr[0], arr[1]), content="true")
  inspect(physical_equal(arr[0], p), content="true")
}

///|
/// A single-field `#valtype` struct is unwrapped to its field on *every*
/// target, including js and wasm-gc. So the split described at the top of this
/// file is about multi-field structs; a one-field one is uniformly a value.
/// Wrapping a `Double` this way is enough to inherit NaN's non-reflexivity --
/// `physical_equal` on an unboxed float is an IEEE-754 value comparison, so a
/// wrapped NaN is not physically equal even to itself.
#valtype
struct DoubleWrapper {
  value : Double
}

///|
test "physical_equal on a single-field #valtype struct" {
  let seven = DoubleWrapper::{ value: 7.0 }
  let also_seven = DoubleWrapper::{ value: 7.0 }
  let eight = DoubleWrapper::{ value: 8.0 }
  inspect(physical_equal(seven, also_seven), content="true")
  inspect(physical_equal(seven, eight), content="false")
  // The wrapped NaN shows through: not even reflexive.
  let nan = DoubleWrapper::{ value: @double.not_a_number }
  inspect(physical_equal(nan, nan), content="false")
  inspect(seven.value + eight.value, content="15")
}
