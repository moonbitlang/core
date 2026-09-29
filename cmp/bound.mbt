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
/// One end of a range over an ordered type.
///
/// Ordered collections such as `@sorted_map.SortedMap` take a lower and an
/// upper `Bound` to select a range of keys:
///
/// - `Included(x)`: the range includes `x`.
/// - `Excluded(x)`: the range stops just before (or starts just after) `x`.
/// - `Unbounded`: the range is open on this side.
///
/// A bound is an ordinary value, so which kind to use can be decided at
/// runtime, for example from a `<` versus `<=` comparison in a query.
///
/// # Example
///
/// ```mbt check
/// test {
///   let strict = true
///   let lower : @cmp.Bound[Int] = if strict { Excluded(3) } else { Included(3) }
///   @debug.debug_inspect(lower, content="Excluded(3)")
/// }
/// ```
pub(all) enum Bound[T] {
  Included(T)
  Excluded(T)
  Unbounded
} derive(Eq, Hash, @debug.Debug)

///|
test "Bound equality and hashing" {
  let a : Bound[Int] = Included(1)
  assert_true(a == Included(1))
  assert_true(a != Excluded(1))
  assert_true(Unbounded == (Unbounded : Bound[Int]))
  assert_true(a.hash() == Bound::Included(1).hash())
}
