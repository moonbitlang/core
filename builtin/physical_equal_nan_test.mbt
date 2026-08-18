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

// These tests *document* what `physical_equal` currently does with NaN; they do
// not specify it. `physical_equal` is explicitly a performance hint whose result
// "may not be consistent across different backends and/or different compiler
// optimization settings", so nothing outside this file should depend on these
// answers. They are pinned here so that a change in any backend shows up as a
// visible diff rather than as a silent behavior change.
//
// As of this commit every case below produces the same answer on all four
// targets (native, js, wasm, wasm-gc), so no per-target expectations are needed.

///|
/// On an unboxed float, `%refeq` lowers to an IEEE-754 value comparison, so
/// `physical_equal` inherits the fact that NaN is not equal to itself: it is
/// *not* reflexive on NaN, not even when both arguments are the very same
/// binding.
test "physical_equal is not reflexive on Double NaN" {
  let nan = @double.not_a_number
  inspect(physical_equal(nan, nan), content="false")
  // For reference, the value comparison it agrees with:
  inspect(nan == nan, content="false")
}

///|
/// Same for `Float`.
test "physical_equal is not reflexive on Float NaN" {
  let nan = @float.not_a_number
  inspect(physical_equal(nan, nan), content="false")
  inspect(nan == nan, content="false")
}

///|
/// NaN payloads are not distinguished either: two NaNs with *different* bit
/// patterns compare `false`, exactly like two NaNs with the same bit pattern.
/// So `physical_equal` gives no way to tell NaNs apart.
test "physical_equal on NaNs with different bit patterns" {
  let quiet_nan = @double.not_a_number
  let payload_nan = 0x7FF8_0000_0000_0DEFUL.reinterpret_as_double()
  let negative_nan = -@double.not_a_number
  assert_true(payload_nan.is_nan())
  assert_true(negative_nan.is_nan())
  inspect(physical_equal(quiet_nan, payload_nan), content="false")
  inspect(physical_equal(quiet_nan, negative_nan), content="false")
  inspect(physical_equal(payload_nan, payload_nan), content="false")
}

///|
/// NaN is the only float for which reflexivity fails. Ordinary values -- and
/// infinities -- are physically equal whenever they are equal by value, even
/// when they come from unrelated computations, because there is no identity to
/// compare in the first place.
test "physical_equal on non-NaN Doubles is value equality" {
  let one = 1.0
  let also_one = 0.5 + 0.5
  inspect(physical_equal(one, also_one), content="true")
  inspect(physical_equal(@double.infinity, @double.infinity), content="true")
  inspect(physical_equal(0.0, -0.0), content="true")
  inspect(0.0 == -0.0, content="true")
}

///|
/// Reading NaN back out of a container does not change the answer: what is
/// compared is still the loaded floating-point value.
test "physical_equal on NaN elements of an array" {
  let nan = @double.not_a_number
  let arr : ReadOnlyArray[Double] = [nan, nan]
  inspect(physical_equal(arr[0], arr[0]), content="false")
  inspect(physical_equal(arr[1], arr[0]), content="false")
  // The array itself is a heap value, so it *is* physically equal to itself.
  inspect(physical_equal(arr, arr), content="true")
}

///|
/// Boxing a NaN restores reflexivity, since the comparison is then between the
/// boxes and never reaches the float. Two separately allocated boxes holding
/// NaN remain distinct, as they would for any other payload.
test "physical_equal on boxed NaN compares the box" {
  let nan = @double.not_a_number
  let boxed = Some(nan)
  let other_box = Some(nan)
  inspect(physical_equal(boxed, boxed), content="true")
  inspect(physical_equal(boxed, other_box), content="false")
}

///|
fn[T] physical_equal_via_generic(a : T, b : T) -> Bool {
  physical_equal(a, b)
}

///|
/// Going through a polymorphic call site -- where a backend might box the
/// argument -- does not change any of the above.
test "physical_equal on NaN through a generic call site" {
  let nan = @double.not_a_number
  let boxed = Some(nan)
  inspect(physical_equal_via_generic(nan, nan), content="false")
  inspect(physical_equal_via_generic(boxed, boxed), content="true")
}
