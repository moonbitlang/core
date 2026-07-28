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
/// Convert `value` to `Json`.
///
/// This is the free-function form of the `ToJson` trait method, symmetric with
/// `@json.from_json`. Prefer it over the promoted `value.to_json()` method.
///
/// ```mbt check
/// test {
///   @debug.debug_inspect(
///     @json.to_json([1, 2, 3]),
///     content="Array([Number(1), Number(2), Number(3)])",
///   )
/// }
/// ```
pub fn[T : ToJson] to_json(value : T) -> Json {
  ToJson::to_json(value)
}
