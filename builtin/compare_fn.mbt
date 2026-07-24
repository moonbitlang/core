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
/// Three-way comparison of two values, returning a negative integer, zero, or
/// a positive integer when `x` is less than, equal to, or greater than `y`.
///
/// This is the free-function form of the `Compare::compare` trait method,
/// symmetric with `hash`. Being a plain function, it can also be passed as a
/// function value, e.g. `array.sort_by(compare)`.
///
/// ```mbt check
/// test {
///   inspect(compare(1, 2).is_neg(), content="true")
///   inspect(compare("abc", "abc"), content="0")
/// }
/// ```
pub fn[A : Compare] compare(x : A, y : A) -> Int {
  Compare::compare(x, y)
}
