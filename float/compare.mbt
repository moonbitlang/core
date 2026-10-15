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
/// IEEE numerical equality. Returns false if either operand is NaN.
/// Positive and negative zero compare equal.
///
/// ```mbt check
/// test {
///   let nan = 0.0F / 0.0F
///   inspect(nan == nan, content="true")
///   inspect(nan.ieee_equal(nan), content="false")
///   inspect(nan.ieee_lt(1.0F), content="false")
/// }
/// ```
pub fn Float::ieee_equal(self : Float, other : Float) -> Bool = "%f32.eq"

///|
/// IEEE numerical inequality. Returns true if either operand is NaN.
pub fn Float::ieee_not_equal(self : Float, other : Float) -> Bool = "%f32.ne"

///|
/// IEEE numerical less-than. Returns false if either operand is NaN.
pub fn Float::ieee_lt(self : Float, other : Float) -> Bool = "%f32.lt"

///|
/// IEEE numerical less-than-or-equal. Returns false if either operand is NaN.
pub fn Float::ieee_le(self : Float, other : Float) -> Bool = "%f32.le"

///|
/// IEEE numerical greater-than. Returns false if either operand is NaN.
pub fn Float::ieee_gt(self : Float, other : Float) -> Bool = "%f32.gt"

///|
/// IEEE numerical greater-than-or-equal. Returns false if either operand is NaN.
pub fn Float::ieee_ge(self : Float, other : Float) -> Bool = "%f32.ge"
