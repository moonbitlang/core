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
/// Compute the hash of `value`.
///
/// This is the free-function form of the `Hash::hash` trait method, symmetric
/// with `@json.to_json`. Prefer it over the promoted `value.hash()` method.
///
/// ```mbt check
/// test {
///   inspect(hash(42) == hash(42), content="true")
/// }
/// ```
pub fn[T : Hash] hash(value : T) -> Int {
  Hash::hash(value)
}
