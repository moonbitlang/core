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
pub impl[A : Debug, B : Debug] Debug for (A, B) with to_repr(self) {
  let (a, b) = self
  Repr::tuple([to_repr(a), to_repr(b)])
}

///|
pub impl[A : Debug, B : Debug, C : Debug] Debug for (A, B, C) with to_repr(self) {
  let (a, b, c) = self
  Repr::tuple([to_repr(a), to_repr(b), to_repr(c)])
}

///|
pub impl[A : Debug, B : Debug, C : Debug, D : Debug] Debug for (A, B, C, D) with to_repr(
  self,
) {
  let (a, b, c, d) = self
  Repr::tuple([to_repr(a), to_repr(b), to_repr(c), to_repr(d)])
}

///|
pub impl[A : Debug, B : Debug, C : Debug, D : Debug, E : Debug] Debug for (
  A,
  B,
  C,
  D,
  E,
) with to_repr(self) {
  let (a, b, c, d, e) = self
  Repr::tuple([to_repr(a), to_repr(b), to_repr(c), to_repr(d), to_repr(e)])
}

///|
pub impl[A : Debug, B : Debug, C : Debug, D : Debug, E : Debug, F : Debug] Debug for (
  A,
  B,
  C,
  D,
  E,
  F,
) with to_repr(self) {
  let (a, b, c, d, e, f) = self
  Repr::tuple([
    to_repr(a),
    to_repr(b),
    to_repr(c),
    to_repr(d),
    to_repr(e),
    to_repr(f),
  ])
}

///|
pub impl[
  A : Debug,
  B : Debug,
  C : Debug,
  D : Debug,
  E : Debug,
  F : Debug,
  G : Debug,
] Debug for (A, B, C, D, E, F, G) with to_repr(self) {
  let (a, b, c, d, e, f, g) = self
  Repr::tuple([
    to_repr(a),
    to_repr(b),
    to_repr(c),
    to_repr(d),
    to_repr(e),
    to_repr(f),
    to_repr(g),
  ])
}

///|
pub impl[
  A : Debug,
  B : Debug,
  C : Debug,
  D : Debug,
  E : Debug,
  F : Debug,
  G : Debug,
  H : Debug,
] Debug for (A, B, C, D, E, F, G, H) with to_repr(self) {
  let (a, b, c, d, e, f, g, h) = self
  Repr::tuple([
    to_repr(a),
    to_repr(b),
    to_repr(c),
    to_repr(d),
    to_repr(e),
    to_repr(f),
    to_repr(g),
    to_repr(h),
  ])
}

///|
pub impl[
  A : Debug,
  B : Debug,
  C : Debug,
  D : Debug,
  E : Debug,
  F : Debug,
  G : Debug,
  H : Debug,
  I : Debug,
] Debug for (A, B, C, D, E, F, G, H, I) with to_repr(self) {
  let (a, b, c, d, e, f, g, h, i) = self
  Repr::tuple([
    to_repr(a),
    to_repr(b),
    to_repr(c),
    to_repr(d),
    to_repr(e),
    to_repr(f),
    to_repr(g),
    to_repr(h),
    to_repr(i),
  ])
}

///|
pub impl[
  A : Debug,
  B : Debug,
  C : Debug,
  D : Debug,
  E : Debug,
  F : Debug,
  G : Debug,
  H : Debug,
  I : Debug,
  J : Debug,
] Debug for (A, B, C, D, E, F, G, H, I, J) with to_repr(self) {
  let (a, b, c, d, e, f, g, h, i, j) = self
  Repr::tuple([
    to_repr(a),
    to_repr(b),
    to_repr(c),
    to_repr(d),
    to_repr(e),
    to_repr(f),
    to_repr(g),
    to_repr(h),
    to_repr(i),
    to_repr(j),
  ])
}

///|
pub impl[
  A : Debug,
  B : Debug,
  C : Debug,
  D : Debug,
  E : Debug,
  F : Debug,
  G : Debug,
  H : Debug,
  I : Debug,
  J : Debug,
  K : Debug,
] Debug for (A, B, C, D, E, F, G, H, I, J, K) with to_repr(self) {
  let (a, b, c, d, e, f, g, h, i, j, k) = self
  Repr::tuple([
    to_repr(a),
    to_repr(b),
    to_repr(c),
    to_repr(d),
    to_repr(e),
    to_repr(f),
    to_repr(g),
    to_repr(h),
    to_repr(i),
    to_repr(j),
    to_repr(k),
  ])
}

///|
pub impl[
  A : Debug,
  B : Debug,
  C : Debug,
  D : Debug,
  E : Debug,
  F : Debug,
  G : Debug,
  H : Debug,
  I : Debug,
  J : Debug,
  K : Debug,
  L : Debug,
] Debug for (A, B, C, D, E, F, G, H, I, J, K, L) with to_repr(self) {
  let (a, b, c, d, e, f, g, h, i, j, k, l) = self
  Repr::tuple([
    to_repr(a),
    to_repr(b),
    to_repr(c),
    to_repr(d),
    to_repr(e),
    to_repr(f),
    to_repr(g),
    to_repr(h),
    to_repr(i),
    to_repr(j),
    to_repr(k),
    to_repr(l),
  ])
}

///|
pub impl[
  A : Debug,
  B : Debug,
  C : Debug,
  D : Debug,
  E : Debug,
  F : Debug,
  G : Debug,
  H : Debug,
  I : Debug,
  J : Debug,
  K : Debug,
  L : Debug,
  M : Debug,
] Debug for (A, B, C, D, E, F, G, H, I, J, K, L, M) with to_repr(self) {
  let (a, b, c, d, e, f, g, h, i, j, k, l, m) = self
  Repr::tuple([
    to_repr(a),
    to_repr(b),
    to_repr(c),
    to_repr(d),
    to_repr(e),
    to_repr(f),
    to_repr(g),
    to_repr(h),
    to_repr(i),
    to_repr(j),
    to_repr(k),
    to_repr(l),
    to_repr(m),
  ])
}

///|
pub impl[
  A : Debug,
  B : Debug,
  C : Debug,
  D : Debug,
  E : Debug,
  F : Debug,
  G : Debug,
  H : Debug,
  I : Debug,
  J : Debug,
  K : Debug,
  L : Debug,
  M : Debug,
  N : Debug,
] Debug for (A, B, C, D, E, F, G, H, I, J, K, L, M, N) with to_repr(self) {
  let (a, b, c, d, e, f, g, h, i, j, k, l, m, n) = self
  Repr::tuple([
    to_repr(a),
    to_repr(b),
    to_repr(c),
    to_repr(d),
    to_repr(e),
    to_repr(f),
    to_repr(g),
    to_repr(h),
    to_repr(i),
    to_repr(j),
    to_repr(k),
    to_repr(l),
    to_repr(m),
    to_repr(n),
  ])
}

///|
pub impl[
  A : Debug,
  B : Debug,
  C : Debug,
  D : Debug,
  E : Debug,
  F : Debug,
  G : Debug,
  H : Debug,
  I : Debug,
  J : Debug,
  K : Debug,
  L : Debug,
  M : Debug,
  N : Debug,
  O : Debug,
] Debug for (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O) with to_repr(self) {
  let (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o) = self
  Repr::tuple([
    to_repr(a),
    to_repr(b),
    to_repr(c),
    to_repr(d),
    to_repr(e),
    to_repr(f),
    to_repr(g),
    to_repr(h),
    to_repr(i),
    to_repr(j),
    to_repr(k),
    to_repr(l),
    to_repr(m),
    to_repr(n),
    to_repr(o),
  ])
}

///|
pub impl[
  A : Debug,
  B : Debug,
  C : Debug,
  D : Debug,
  E : Debug,
  F : Debug,
  G : Debug,
  H : Debug,
  I : Debug,
  J : Debug,
  K : Debug,
  L : Debug,
  M : Debug,
  N : Debug,
  O : Debug,
  P : Debug,
] Debug for (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P) with to_repr(self) {
  let (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) = self
  Repr::tuple([
    to_repr(a),
    to_repr(b),
    to_repr(c),
    to_repr(d),
    to_repr(e),
    to_repr(f),
    to_repr(g),
    to_repr(h),
    to_repr(i),
    to_repr(j),
    to_repr(k),
    to_repr(l),
    to_repr(m),
    to_repr(n),
    to_repr(o),
    to_repr(p),
  ])
}

///|
pub impl[
  A : Debug,
  B : Debug,
  C : Debug,
  D : Debug,
  E : Debug,
  F : Debug,
  G : Debug,
  H : Debug,
  I : Debug,
  J : Debug,
  K : Debug,
  L : Debug,
  M : Debug,
  N : Debug,
  O : Debug,
  P : Debug,
  Q : Debug,
] Debug for (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q) with to_repr(
  self,
) {
  let (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q) = self
  Repr::tuple([
    to_repr(a),
    to_repr(b),
    to_repr(c),
    to_repr(d),
    to_repr(e),
    to_repr(f),
    to_repr(g),
    to_repr(h),
    to_repr(i),
    to_repr(j),
    to_repr(k),
    to_repr(l),
    to_repr(m),
    to_repr(n),
    to_repr(o),
    to_repr(p),
    to_repr(q),
  ])
}

///|
pub impl[
  A : Debug,
  B : Debug,
  C : Debug,
  D : Debug,
  E : Debug,
  F : Debug,
  G : Debug,
  H : Debug,
  I : Debug,
  J : Debug,
  K : Debug,
  L : Debug,
  M : Debug,
  N : Debug,
  O : Debug,
  P : Debug,
  Q : Debug,
  R : Debug,
] Debug for (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R) with to_repr(
  self,
) {
  let (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r) = self
  Repr::tuple([
    to_repr(a),
    to_repr(b),
    to_repr(c),
    to_repr(d),
    to_repr(e),
    to_repr(f),
    to_repr(g),
    to_repr(h),
    to_repr(i),
    to_repr(j),
    to_repr(k),
    to_repr(l),
    to_repr(m),
    to_repr(n),
    to_repr(o),
    to_repr(p),
    to_repr(q),
    to_repr(r),
  ])
}

///|
pub impl[
  A : Debug,
  B : Debug,
  C : Debug,
  D : Debug,
  E : Debug,
  F : Debug,
  G : Debug,
  H : Debug,
  I : Debug,
  J : Debug,
  K : Debug,
  L : Debug,
  M : Debug,
  N : Debug,
  O : Debug,
  P : Debug,
  Q : Debug,
  R : Debug,
  S : Debug,
] Debug for (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S) with to_repr(
  self,
) {
  let (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) = self
  Repr::tuple([
    to_repr(a),
    to_repr(b),
    to_repr(c),
    to_repr(d),
    to_repr(e),
    to_repr(f),
    to_repr(g),
    to_repr(h),
    to_repr(i),
    to_repr(j),
    to_repr(k),
    to_repr(l),
    to_repr(m),
    to_repr(n),
    to_repr(o),
    to_repr(p),
    to_repr(q),
    to_repr(r),
    to_repr(s),
  ])
}

///|
pub impl[
  A : Debug,
  B : Debug,
  C : Debug,
  D : Debug,
  E : Debug,
  F : Debug,
  G : Debug,
  H : Debug,
  I : Debug,
  J : Debug,
  K : Debug,
  L : Debug,
  M : Debug,
  N : Debug,
  O : Debug,
  P : Debug,
  Q : Debug,
  R : Debug,
  S : Debug,
  T : Debug,
] Debug for (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T) with to_repr(
  self,
) {
  let (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) = self
  Repr::tuple([
    to_repr(a),
    to_repr(b),
    to_repr(c),
    to_repr(d),
    to_repr(e),
    to_repr(f),
    to_repr(g),
    to_repr(h),
    to_repr(i),
    to_repr(j),
    to_repr(k),
    to_repr(l),
    to_repr(m),
    to_repr(n),
    to_repr(o),
    to_repr(p),
    to_repr(q),
    to_repr(r),
    to_repr(s),
    to_repr(t),
  ])
}

///|
pub impl[
  A : Debug,
  B : Debug,
  C : Debug,
  D : Debug,
  E : Debug,
  F : Debug,
  G : Debug,
  H : Debug,
  I : Debug,
  J : Debug,
  K : Debug,
  L : Debug,
  M : Debug,
  N : Debug,
  O : Debug,
  P : Debug,
  Q : Debug,
  R : Debug,
  S : Debug,
  T : Debug,
  U : Debug,
] Debug for (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U) with to_repr(
  self,
) {
  let (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) = self
  Repr::tuple([
    to_repr(a),
    to_repr(b),
    to_repr(c),
    to_repr(d),
    to_repr(e),
    to_repr(f),
    to_repr(g),
    to_repr(h),
    to_repr(i),
    to_repr(j),
    to_repr(k),
    to_repr(l),
    to_repr(m),
    to_repr(n),
    to_repr(o),
    to_repr(p),
    to_repr(q),
    to_repr(r),
    to_repr(s),
    to_repr(t),
    to_repr(u),
  ])
}

///|
pub impl[
  A : Debug,
  B : Debug,
  C : Debug,
  D : Debug,
  E : Debug,
  F : Debug,
  G : Debug,
  H : Debug,
  I : Debug,
  J : Debug,
  K : Debug,
  L : Debug,
  M : Debug,
  N : Debug,
  O : Debug,
  P : Debug,
  Q : Debug,
  R : Debug,
  S : Debug,
  T : Debug,
  U : Debug,
  V : Debug,
] Debug for (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V) with to_repr(
  self,
) {
  let (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) = self
  Repr::tuple([
    to_repr(a),
    to_repr(b),
    to_repr(c),
    to_repr(d),
    to_repr(e),
    to_repr(f),
    to_repr(g),
    to_repr(h),
    to_repr(i),
    to_repr(j),
    to_repr(k),
    to_repr(l),
    to_repr(m),
    to_repr(n),
    to_repr(o),
    to_repr(p),
    to_repr(q),
    to_repr(r),
    to_repr(s),
    to_repr(t),
    to_repr(u),
    to_repr(v),
  ])
}
