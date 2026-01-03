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
///
/// A `ArrayView` represents a view into a section of an array without copying the data.
///
/// # Example
///
/// ```mbt check
/// test {
///   let arr = [1, 2, 3, 4, 5]
///   let view = arr[1:4] // Creates a view of elements at indices 1,2,3
///   inspect(view[0], content="2")
///   inspect(view.length(), content="3")
/// }
/// ```
#deprecated
pub type View[T] = ArrayView[T]
