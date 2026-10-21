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
/// Compares two values using MoonBit's total ordering.
///
/// Returns `-1`, `0`, or `1` when `self` is less than, equivalent to, or greater
/// than `other`. Numbers follow numerical order, including infinities and
/// subnormals. Signed zeros are equivalent. All NaNs are equivalent and sort
/// before every number, regardless of their sign, payload, or signaling status.
///
/// This differs from IEEE `totalOrder`, which distinguishes signed zeros and
/// NaN encodings. It also differs from ordinary equality: NaNs compare as zero
/// here even though `nan == nan` is false. Values and their stored bits are not
/// changed.
///
/// Use this comparator explicitly when sorting values that may contain NaNs,
/// and use the same comparison for subsequent searches:
///
/// ```mbt check
/// test {
///   let nan = @float.not_a_number
///   let values : Array[Float] = [1.0, nan, -0.0, -1.0]
///   values.sort_by(Float::total_compare)
///   inspect(values[0].is_nan(), content="true")
///   debug_inspect(
///     values.binary_search_by(x => x.total_compare(nan)),
///     content="Ok(0)",
///   )
///   debug_inspect(
///     values.binary_search_by(x => x.total_compare(0.0)),
///     content="Ok(2)",
///   )
/// }
/// ```
pub fn Float::total_compare(self : Float, other : Float) -> Int32 {
  (self > other).to_int() -
  (self < other).to_int() +
  (other.is_nan().to_int() - self.is_nan().to_int())
}
