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
pub impl[A : Debug, B : Debug] Debug for (A, B) with fn to_repr(self) {
  let (a, b) = self
  Repr::tuple([Repr(a), Repr(b)])
}

///|
pub impl[A : Debug, B : Debug, C : Debug] Debug for (A, B, C) with fn to_repr(
  self,
) {
  let (a, b, c) = self
  Repr::tuple([Repr(a), Repr(b), Repr(c)])
}

///|
pub impl[A : Debug, B : Debug, C : Debug, D : Debug] Debug for (A, B, C, D) with fn to_repr(
  self,
) {
  let (a, b, c, d) = self
  Repr::tuple([Repr(a), Repr(b), Repr(c), Repr(d)])
}

///|
pub impl[A : Debug, B : Debug, C : Debug, D : Debug, E : Debug] Debug for (
  A,
  B,
  C,
  D,
  E,
) with fn to_repr(self) {
  let (a, b, c, d, e) = self
  Repr::tuple([Repr(a), Repr(b), Repr(c), Repr(d), Repr(e)])
}

///|
pub impl[A : Debug, B : Debug, C : Debug, D : Debug, E : Debug, F : Debug] Debug for (
  A,
  B,
  C,
  D,
  E,
  F,
) with fn to_repr(self) {
  let (a, b, c, d, e, f) = self
  Repr::tuple([Repr(a), Repr(b), Repr(c), Repr(d), Repr(e), Repr(f)])
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
] Debug for (A, B, C, D, E, F, G) with fn to_repr(self) {
  let (a, b, c, d, e, f, g) = self
  Repr::tuple([Repr(a), Repr(b), Repr(c), Repr(d), Repr(e), Repr(f), Repr(g)])
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
] Debug for (A, B, C, D, E, F, G, H) with fn to_repr(self) {
  let (a, b, c, d, e, f, g, h) = self
  Repr::tuple([
    Repr(a),
    Repr(b),
    Repr(c),
    Repr(d),
    Repr(e),
    Repr(f),
    Repr(g),
    Repr(h),
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
] Debug for (A, B, C, D, E, F, G, H, I) with fn to_repr(self) {
  let (a, b, c, d, e, f, g, h, i) = self
  Repr::tuple([
    Repr(a),
    Repr(b),
    Repr(c),
    Repr(d),
    Repr(e),
    Repr(f),
    Repr(g),
    Repr(h),
    Repr(i),
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
] Debug for (A, B, C, D, E, F, G, H, I, J) with fn to_repr(self) {
  let (a, b, c, d, e, f, g, h, i, j) = self
  Repr::tuple([
    Repr(a),
    Repr(b),
    Repr(c),
    Repr(d),
    Repr(e),
    Repr(f),
    Repr(g),
    Repr(h),
    Repr(i),
    Repr(j),
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
] Debug for (A, B, C, D, E, F, G, H, I, J, K) with fn to_repr(self) {
  let (a, b, c, d, e, f, g, h, i, j, k) = self
  Repr::tuple([
    Repr(a),
    Repr(b),
    Repr(c),
    Repr(d),
    Repr(e),
    Repr(f),
    Repr(g),
    Repr(h),
    Repr(i),
    Repr(j),
    Repr(k),
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
] Debug for (A, B, C, D, E, F, G, H, I, J, K, L) with fn to_repr(self) {
  let (a, b, c, d, e, f, g, h, i, j, k, l) = self
  Repr::tuple([
    Repr(a),
    Repr(b),
    Repr(c),
    Repr(d),
    Repr(e),
    Repr(f),
    Repr(g),
    Repr(h),
    Repr(i),
    Repr(j),
    Repr(k),
    Repr(l),
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
] Debug for (A, B, C, D, E, F, G, H, I, J, K, L, M) with fn to_repr(self) {
  let (a, b, c, d, e, f, g, h, i, j, k, l, m) = self
  Repr::tuple([
    Repr(a),
    Repr(b),
    Repr(c),
    Repr(d),
    Repr(e),
    Repr(f),
    Repr(g),
    Repr(h),
    Repr(i),
    Repr(j),
    Repr(k),
    Repr(l),
    Repr(m),
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
] Debug for (A, B, C, D, E, F, G, H, I, J, K, L, M, N) with fn to_repr(self) {
  let (a, b, c, d, e, f, g, h, i, j, k, l, m, n) = self
  Repr::tuple([
    Repr(a),
    Repr(b),
    Repr(c),
    Repr(d),
    Repr(e),
    Repr(f),
    Repr(g),
    Repr(h),
    Repr(i),
    Repr(j),
    Repr(k),
    Repr(l),
    Repr(m),
    Repr(n),
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
] Debug for (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O) with fn to_repr(self) {
  let (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o) = self
  Repr::tuple([
    Repr(a),
    Repr(b),
    Repr(c),
    Repr(d),
    Repr(e),
    Repr(f),
    Repr(g),
    Repr(h),
    Repr(i),
    Repr(j),
    Repr(k),
    Repr(l),
    Repr(m),
    Repr(n),
    Repr(o),
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
] Debug for (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P) with fn to_repr(
  self,
) {
  let (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) = self
  Repr::tuple([
    Repr(a),
    Repr(b),
    Repr(c),
    Repr(d),
    Repr(e),
    Repr(f),
    Repr(g),
    Repr(h),
    Repr(i),
    Repr(j),
    Repr(k),
    Repr(l),
    Repr(m),
    Repr(n),
    Repr(o),
    Repr(p),
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
] Debug for (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q) with fn to_repr(
  self,
) {
  let (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q) = self
  Repr::tuple([
    Repr(a),
    Repr(b),
    Repr(c),
    Repr(d),
    Repr(e),
    Repr(f),
    Repr(g),
    Repr(h),
    Repr(i),
    Repr(j),
    Repr(k),
    Repr(l),
    Repr(m),
    Repr(n),
    Repr(o),
    Repr(p),
    Repr(q),
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
] Debug for (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R) with fn to_repr(
  self,
) {
  let (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r) = self
  Repr::tuple([
    Repr(a),
    Repr(b),
    Repr(c),
    Repr(d),
    Repr(e),
    Repr(f),
    Repr(g),
    Repr(h),
    Repr(i),
    Repr(j),
    Repr(k),
    Repr(l),
    Repr(m),
    Repr(n),
    Repr(o),
    Repr(p),
    Repr(q),
    Repr(r),
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
] Debug for (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S) with fn to_repr(
  self,
) {
  let (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) = self
  Repr::tuple([
    Repr(a),
    Repr(b),
    Repr(c),
    Repr(d),
    Repr(e),
    Repr(f),
    Repr(g),
    Repr(h),
    Repr(i),
    Repr(j),
    Repr(k),
    Repr(l),
    Repr(m),
    Repr(n),
    Repr(o),
    Repr(p),
    Repr(q),
    Repr(r),
    Repr(s),
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
] Debug for (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T) with fn to_repr(
  self,
) {
  let (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) = self
  Repr::tuple([
    Repr(a),
    Repr(b),
    Repr(c),
    Repr(d),
    Repr(e),
    Repr(f),
    Repr(g),
    Repr(h),
    Repr(i),
    Repr(j),
    Repr(k),
    Repr(l),
    Repr(m),
    Repr(n),
    Repr(o),
    Repr(p),
    Repr(q),
    Repr(r),
    Repr(s),
    Repr(t),
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
] Debug for (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U) with fn to_repr(
  self,
) {
  let (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) = self
  Repr::tuple([
    Repr(a),
    Repr(b),
    Repr(c),
    Repr(d),
    Repr(e),
    Repr(f),
    Repr(g),
    Repr(h),
    Repr(i),
    Repr(j),
    Repr(k),
    Repr(l),
    Repr(m),
    Repr(n),
    Repr(o),
    Repr(p),
    Repr(q),
    Repr(r),
    Repr(s),
    Repr(t),
    Repr(u),
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
] Debug for (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V) with fn to_repr(
  self,
) {
  let (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) = self
  Repr::tuple([
    Repr(a),
    Repr(b),
    Repr(c),
    Repr(d),
    Repr(e),
    Repr(f),
    Repr(g),
    Repr(h),
    Repr(i),
    Repr(j),
    Repr(k),
    Repr(l),
    Repr(m),
    Repr(n),
    Repr(o),
    Repr(p),
    Repr(q),
    Repr(r),
    Repr(s),
    Repr(t),
    Repr(u),
    Repr(v),
  ])
}
