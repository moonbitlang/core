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

// The native/llvm/wasm half of the `#valtype` documentation; see
// `physical_equal_valtype_test.mbt` for the full story and the caveats. On
// these targets a `#valtype` struct is genuinely unboxed, so `physical_equal`
// has no identity to compare and degrades to a field-wise value comparison.

///|
/// Two independently constructed `Point`s with equal fields *are* physically
/// equal here -- the answer `physical_equal` gives for a `#valtype` struct is
/// structural, not an identity check.
test "physical_equal on equal-valued #valtype structs (unboxed targets)" {
  let p = Point::{ x: 1, y: 2 }
  let q = Point::{ x: 1, y: 2 }
  inspect(physical_equal(p, q), content="true")
  inspect(physical_equal_via_generic(p, q), content="true")
}

///|
/// Because the struct cannot be represented as a pointer, `Some(p)` has to
/// allocate a real box, and two such boxes are distinct. On js/wasm-gc the
/// opposite holds -- see the boxed-target file.
test "physical_equal on Some(#valtype) (unboxed targets)" {
  let p = Point::{ x: 1, y: 2 }
  let boxed = Some(p)
  inspect(physical_equal(boxed, boxed), content="true")
  inspect(physical_equal(Some(p), Some(p)), content="false")
}
