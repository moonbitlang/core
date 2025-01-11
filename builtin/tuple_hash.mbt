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
pub impl[A : Hash, B : Hash] Hash for (A, B) with hash_combine(self, hasher) {
  let (a, b) = self
  hasher..combine(a).combine(b)
}

///|
pub impl[A : Hash, B : Hash, C : Hash] Hash for (A, B, C) with hash_combine(
  self,
  hasher
) {
  let (a, b, c) = self
  hasher..combine(a)..combine(b).combine(c)
}

///|
pub impl[A : Hash, B : Hash, C : Hash, D : Hash] Hash for (A, B, C, D) with hash_combine(
  self,
  hasher
) {
  let (a, b, c, d) = self
  hasher..combine(a)..combine(b)..combine(c).combine(d)
}

///|
pub impl[A : Hash, B : Hash, C : Hash, D : Hash, E : Hash] Hash for (
  A,
  B,
  C,
  D,
  E,
) with hash_combine(self, hasher) {
  let (a, b, c, d, e) = self
  hasher..combine(a)..combine(b)..combine(c)..combine(d).combine(e)
}

///|
pub impl[A : Hash, B : Hash, C : Hash, D : Hash, E : Hash, F : Hash] Hash for (
  A,
  B,
  C,
  D,
  E,
  F,
) with hash_combine(self, hasher) {
  let (a, b, c, d, e, f) = self
  hasher..combine(a)..combine(b)..combine(c)..combine(d)..combine(e).combine(f)
}

///|
pub impl[A : Hash, B : Hash, C : Hash, D : Hash, E : Hash, F : Hash, G : Hash] Hash for (
  A,
  B,
  C,
  D,
  E,
  F,
  G,
) with hash_combine(self, hasher) {
  let (a, b, c, d, e, f, g) = self
  hasher
  ..combine(a)
  ..combine(b)
  ..combine(c)
  ..combine(d)
  ..combine(e)
  ..combine(f)
  .combine(g)
}
