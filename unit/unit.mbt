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
/// Returns the canonical string representation of `Unit`, which is `"()"`.
/// This matches the standard display form used for debugging.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(().to_string(), content="()")
/// }
/// ```
pub fn Unit::to_string(_ : Self) -> String {
  "()"
}

///|
/// Implements `Hash` for `Unit` with a stable, deterministic hash value.
/// Since `Unit` has a single value, all `Unit` hashes are identical.
///
/// Example:
///
/// ```mbt check
/// test {
///   let h1 = (() : Unit).hash()
///   let h2 = (() : Unit).hash()
///   inspect(h1 == h2, content="true")
/// }
/// ```
pub impl Hash for Unit with hash_combine(_, hasher) -> Unit {
  hasher.combine_unit()
}

///|
/// Provides the default `Unit` value `()`, which is the only value of `Unit`.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(Unit::default() == (), content="true")
/// }
/// ```
pub impl Default for Unit with default() -> Unit {
  ()
}

///|
/// Returns the default `Unit` value `()`, same as `Unit::default()`.
/// This is the package-level helper for obtaining `Unit`.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@unit.default() == (), content="true")
/// }
/// ```
pub fn default() -> Unit {
  ()
}

///|
/// Compares two `Unit` values; they are always equal.
/// The comparison is total and always returns `0`.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect((() : Unit).compare(()) == 0, content="true")
/// }
/// ```
pub impl Compare for Unit with compare(_, _) {
  0
}
