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
pub impl[A : Hash, B : Hash] Hash for (A, B) with fn hash_combine(self, hasher) {
  let (a, b) = self
  hasher.combine(a)
  hasher.combine(b)
}

///|
pub impl[A : Hash, B : Hash, C : Hash] Hash for (A, B, C) with fn hash_combine(
  self,
  hasher,
) {
  let (a, b, c) = self
  hasher.combine(a)
  hasher.combine(b)
  hasher.combine(c)
}

///|
pub impl[A : Hash, B : Hash, C : Hash, D : Hash] Hash for (A, B, C, D) with fn hash_combine(
  self,
  hasher,
) {
  let (a, b, c, d) = self
  hasher.combine(a)
  hasher.combine(b)
  hasher.combine(c)
  hasher.combine(d)
}

///|
pub impl[A : Hash, B : Hash, C : Hash, D : Hash, E : Hash] Hash for (
  A,
  B,
  C,
  D,
  E,
) with fn hash_combine(self, hasher) {
  let (a, b, c, d, e) = self
  hasher.combine(a)
  hasher.combine(b)
  hasher.combine(c)
  hasher.combine(d)
  hasher.combine(e)
}

///|
pub impl[A : Hash, B : Hash, C : Hash, D : Hash, E : Hash, F : Hash] Hash for (
  A,
  B,
  C,
  D,
  E,
  F,
) with fn hash_combine(self, hasher) {
  let (a, b, c, d, e, f) = self
  hasher.combine(a)
  hasher.combine(b)
  hasher.combine(c)
  hasher.combine(d)
  hasher.combine(e)
  hasher.combine(f)
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
) with fn hash_combine(self, hasher) {
  let (a, b, c, d, e, f, g) = self
  hasher.combine(a)
  hasher.combine(b)
  hasher.combine(c)
  hasher.combine(d)
  hasher.combine(e)
  hasher.combine(f)
  hasher.combine(g)
}

///|
pub impl[
  A : Hash,
  B : Hash,
  C : Hash,
  D : Hash,
  E : Hash,
  F : Hash,
  G : Hash,
  H : Hash,
] Hash for (A, B, C, D, E, F, G, H) with fn hash_combine(self, hasher) {
  let (a, b, c, d, e, f, g, h) = self
  hasher.combine(a)
  hasher.combine(b)
  hasher.combine(c)
  hasher.combine(d)
  hasher.combine(e)
  hasher.combine(f)
  hasher.combine(g)
  hasher.combine(h)
}

///|
pub impl[
  A : Hash,
  B : Hash,
  C : Hash,
  D : Hash,
  E : Hash,
  F : Hash,
  G : Hash,
  H : Hash,
  I : Hash,
] Hash for (A, B, C, D, E, F, G, H, I) with fn hash_combine(self, hasher) {
  let (a, b, c, d, e, f, g, h, i) = self
  hasher.combine(a)
  hasher.combine(b)
  hasher.combine(c)
  hasher.combine(d)
  hasher.combine(e)
  hasher.combine(f)
  hasher.combine(g)
  hasher.combine(h)
  hasher.combine(i)
}

///|
pub impl[
  A : Hash,
  B : Hash,
  C : Hash,
  D : Hash,
  E : Hash,
  F : Hash,
  G : Hash,
  H : Hash,
  I : Hash,
  J : Hash,
] Hash for (A, B, C, D, E, F, G, H, I, J) with fn hash_combine(self, hasher) {
  let (a, b, c, d, e, f, g, h, i, j) = self
  hasher.combine(a)
  hasher.combine(b)
  hasher.combine(c)
  hasher.combine(d)
  hasher.combine(e)
  hasher.combine(f)
  hasher.combine(g)
  hasher.combine(h)
  hasher.combine(i)
  hasher.combine(j)
}

///|
pub impl[
  A : Hash,
  B : Hash,
  C : Hash,
  D : Hash,
  E : Hash,
  F : Hash,
  G : Hash,
  H : Hash,
  I : Hash,
  J : Hash,
  K : Hash,
] Hash for (A, B, C, D, E, F, G, H, I, J, K) with fn hash_combine(self, hasher) {
  let (a, b, c, d, e, f, g, h, i, j, k) = self
  hasher.combine(a)
  hasher.combine(b)
  hasher.combine(c)
  hasher.combine(d)
  hasher.combine(e)
  hasher.combine(f)
  hasher.combine(g)
  hasher.combine(h)
  hasher.combine(i)
  hasher.combine(j)
  hasher.combine(k)
}

///|
pub impl[
  A : Hash,
  B : Hash,
  C : Hash,
  D : Hash,
  E : Hash,
  F : Hash,
  G : Hash,
  H : Hash,
  I : Hash,
  J : Hash,
  K : Hash,
  L : Hash,
] Hash for (A, B, C, D, E, F, G, H, I, J, K, L) with fn hash_combine(
  self,
  hasher,
) {
  let (a, b, c, d, e, f, g, h, i, j, k, l) = self
  hasher.combine(a)
  hasher.combine(b)
  hasher.combine(c)
  hasher.combine(d)
  hasher.combine(e)
  hasher.combine(f)
  hasher.combine(g)
  hasher.combine(h)
  hasher.combine(i)
  hasher.combine(j)
  hasher.combine(k)
  hasher.combine(l)
}

///|
pub impl[
  A : Hash,
  B : Hash,
  C : Hash,
  D : Hash,
  E : Hash,
  F : Hash,
  G : Hash,
  H : Hash,
  I : Hash,
  J : Hash,
  K : Hash,
  L : Hash,
  M : Hash,
] Hash for (A, B, C, D, E, F, G, H, I, J, K, L, M) with fn hash_combine(
  self,
  hasher,
) {
  let (a, b, c, d, e, f, g, h, i, j, k, l, m) = self
  hasher.combine(a)
  hasher.combine(b)
  hasher.combine(c)
  hasher.combine(d)
  hasher.combine(e)
  hasher.combine(f)
  hasher.combine(g)
  hasher.combine(h)
  hasher.combine(i)
  hasher.combine(j)
  hasher.combine(k)
  hasher.combine(l)
  hasher.combine(m)
}

///|
pub impl[
  A : Hash,
  B : Hash,
  C : Hash,
  D : Hash,
  E : Hash,
  F : Hash,
  G : Hash,
  H : Hash,
  I : Hash,
  J : Hash,
  K : Hash,
  L : Hash,
  M : Hash,
  N : Hash,
] Hash for (A, B, C, D, E, F, G, H, I, J, K, L, M, N) with fn hash_combine(
  self,
  hasher,
) {
  let (a, b, c, d, e, f, g, h, i, j, k, l, m, n) = self
  hasher.combine(a)
  hasher.combine(b)
  hasher.combine(c)
  hasher.combine(d)
  hasher.combine(e)
  hasher.combine(f)
  hasher.combine(g)
  hasher.combine(h)
  hasher.combine(i)
  hasher.combine(j)
  hasher.combine(k)
  hasher.combine(l)
  hasher.combine(m)
  hasher.combine(n)
}

///|
pub impl[
  A : Hash,
  B : Hash,
  C : Hash,
  D : Hash,
  E : Hash,
  F : Hash,
  G : Hash,
  H : Hash,
  I : Hash,
  J : Hash,
  K : Hash,
  L : Hash,
  M : Hash,
  N : Hash,
  O : Hash,
] Hash for (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O) with fn hash_combine(
  self,
  hasher,
) {
  let (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o) = self
  hasher.combine(a)
  hasher.combine(b)
  hasher.combine(c)
  hasher.combine(d)
  hasher.combine(e)
  hasher.combine(f)
  hasher.combine(g)
  hasher.combine(h)
  hasher.combine(i)
  hasher.combine(j)
  hasher.combine(k)
  hasher.combine(l)
  hasher.combine(m)
  hasher.combine(n)
  hasher.combine(o)
}

///|
pub impl[
  A : Hash,
  B : Hash,
  C : Hash,
  D : Hash,
  E : Hash,
  F : Hash,
  G : Hash,
  H : Hash,
  I : Hash,
  J : Hash,
  K : Hash,
  L : Hash,
  M : Hash,
  N : Hash,
  O : Hash,
  P : Hash,
] Hash for (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P) with fn hash_combine(
  self,
  hasher,
) {
  let (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) = self
  hasher.combine(a)
  hasher.combine(b)
  hasher.combine(c)
  hasher.combine(d)
  hasher.combine(e)
  hasher.combine(f)
  hasher.combine(g)
  hasher.combine(h)
  hasher.combine(i)
  hasher.combine(j)
  hasher.combine(k)
  hasher.combine(l)
  hasher.combine(m)
  hasher.combine(n)
  hasher.combine(o)
  hasher.combine(p)
}
