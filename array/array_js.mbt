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
priv type JSArray

///|
fn JSArray::ofAnyArray[T](array : Array[T]) -> JSArray = "%identity"

///|
fn JSArray::toAnyArray[T](self : JSArray) -> Array[T] = "%identity"

///|
extern "js" fn JSArray::copy(self : JSArray) -> JSArray =
  #|(arr) => arr.slice(0)

///|
/// Creates and returns a new array with a copy of all elements from the input
/// array.
///
/// Parameters:
///
/// * `array` : The array to be copied.
///
/// Returns a new array containing all elements from the original array.
///
/// Example:
///
/// ```moonbit
/// test "copy" {
///   let original = [1, 2, 3]
///   let copied = original.copy()
///   inspect!(copied, content="[1, 2, 3]")
///   inspect!(physical_equal(original, copied), content="false")
/// }
/// ```
pub fn copy[T](self : Array[T]) -> Array[T] {
  JSArray::ofAnyArray(self).copy().toAnyArray()
}
