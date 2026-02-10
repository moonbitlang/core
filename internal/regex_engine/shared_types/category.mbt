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
/// Bitset category used by regex boundary assertions.
///
/// Categories may be combined with `+` and queried by `intersects`.
///
/// Example:
///
/// ```mbt check
/// test {
///   let w = @shared_types.Category::word()
///   let nw = @shared_types.Category::not_word()
///   inspect(w.intersects(nw), content="false")
///   inspect((w + nw).intersects(w), content="true")
/// }
/// ```
pub struct Category(Int) derive(Eq, Hash)

///|
/// A sentinel category used in internal transitions.
pub fn Category::dummy() -> Category {
  Category(-1)
}

///|
/// Category representing the "outside input" position.
pub fn Category::inexistant() -> Category {
  Category(1)
}

///|
/// Category representing a word character.
pub fn Category::word() -> Category {
  Category(2)
}

///|
/// Category representing a non-word character.
pub fn Category::not_word() -> Category {
  Category(4)
}

///|
/// Category representing a newline character.
pub fn Category::newline() -> Category {
  Category(8)
}

///|
/// Convenience category: outside input or newline.
pub fn Category::inexistant_or_newline() -> Category {
  Category(1 | 8)
}

///|
/// Convenience category: outside input or non-word.
pub fn Category::inexistant_or_non_word() -> Category {
  Category(1 | 4)
}

///|
pub impl Add for Category with add(cat1, cat2) {
  Category(cat1.0 | cat2.0)
}

///|
/// Return `true` if two categories share at least one bit.
pub fn Category::intersects(a : Category, b : Category) -> Bool {
  (a.0 & b.0) != 0
}
