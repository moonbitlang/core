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

// The js/wasm-gc half of the `#valtype` documentation; see
// `physical_equal_valtype_test.mbt` for the full story and the caveats. On
// these targets a multi-field `#valtype` struct is still a heap object, so
// `physical_equal` remains an identity comparison and `#valtype` does not
// change its answer at all.

///|
/// Two independently constructed `Point`s with equal fields are *not*
/// physically equal here -- the same result an ordinary struct gives, and the
/// opposite of what native/llvm/wasm report.
test "physical_equal on equal-valued #valtype structs (boxed targets)" {
  let p = Point::{ x: 1, y: 2 }
  let q = Point::{ x: 1, y: 2 }
  inspect(physical_equal(p, q), content="false")
  inspect(physical_equal_via_generic(p, q), content="false")
}

///|
/// Since the struct is already a pointer, `Some(p)` needs no allocation of its
/// own and is represented as `p` itself, so two `Some(p)`s are physically
/// equal. On native/llvm/wasm the opposite holds -- see the unboxed-target
/// file.
test "physical_equal on Some(#valtype) (boxed targets)" {
  let p = Point::{ x: 1, y: 2 }
  let boxed = Some(p)
  inspect(physical_equal(boxed, boxed), content="true")
  inspect(physical_equal(Some(p), Some(p)), content="true")
}
