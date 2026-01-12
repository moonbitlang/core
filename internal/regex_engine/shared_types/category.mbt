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
pub struct Category(Int) derive(Eq, Hash)

///|
pub fn Category::dummy() -> Category {
  Category(-1)
}

///|
pub fn Category::inexistant() -> Category {
  Category(1)
}

///|
pub fn Category::word() -> Category {
  Category(2)
}

///|
pub fn Category::not_word() -> Category {
  Category(4)
}

///|
pub fn Category::newline() -> Category {
  Category(8)
}

///|
pub fn Category::inexistant_or_newline() -> Category {
  Category(1 | 8)
}

///|
pub fn Category::inexistant_or_non_word() -> Category {
  Category(1 | 4)
}

///|
pub impl Add for Category with add(cat1, cat2) {
  Category(cat1.0 | cat2.0)
}

///|
pub fn Category::intersects(a : Category, b : Category) -> Bool {
  (a.0 & b.0) != 0
}
