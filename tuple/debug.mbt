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
using @debug {trait Debug, type Repr}

///|
pub impl[A : Debug, B : Debug] Debug for (A, B) with to_repr(self) {
  let (a, b) = self
  Repr::tuple([@debug.to_repr(a), @debug.to_repr(b)])
}

///|
pub impl[A : Debug, B : Debug, C : Debug] Debug for (A, B, C) with to_repr(self) {
  let (a, b, c) = self
  Repr::tuple([@debug.to_repr(a), @debug.to_repr(b), @debug.to_repr(c)])
}

///|
pub impl[A : Debug, B : Debug, C : Debug, D : Debug] Debug for (A, B, C, D) with to_repr(
  self,
) {
  let (a, b, c, d) = self
  Repr::tuple([
    @debug.to_repr(a),
    @debug.to_repr(b),
    @debug.to_repr(c),
    @debug.to_repr(d),
  ])
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
  Repr::tuple([
    @debug.to_repr(a),
    @debug.to_repr(b),
    @debug.to_repr(c),
    @debug.to_repr(d),
    @debug.to_repr(e),
  ])
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
    @debug.to_repr(a),
    @debug.to_repr(b),
    @debug.to_repr(c),
    @debug.to_repr(d),
    @debug.to_repr(e),
    @debug.to_repr(f),
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
    @debug.to_repr(a),
    @debug.to_repr(b),
    @debug.to_repr(c),
    @debug.to_repr(d),
    @debug.to_repr(e),
    @debug.to_repr(f),
    @debug.to_repr(g),
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
    @debug.to_repr(a),
    @debug.to_repr(b),
    @debug.to_repr(c),
    @debug.to_repr(d),
    @debug.to_repr(e),
    @debug.to_repr(f),
    @debug.to_repr(g),
    @debug.to_repr(h),
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
    @debug.to_repr(a),
    @debug.to_repr(b),
    @debug.to_repr(c),
    @debug.to_repr(d),
    @debug.to_repr(e),
    @debug.to_repr(f),
    @debug.to_repr(g),
    @debug.to_repr(h),
    @debug.to_repr(i),
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
    @debug.to_repr(a),
    @debug.to_repr(b),
    @debug.to_repr(c),
    @debug.to_repr(d),
    @debug.to_repr(e),
    @debug.to_repr(f),
    @debug.to_repr(g),
    @debug.to_repr(h),
    @debug.to_repr(i),
    @debug.to_repr(j),
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
    @debug.to_repr(a),
    @debug.to_repr(b),
    @debug.to_repr(c),
    @debug.to_repr(d),
    @debug.to_repr(e),
    @debug.to_repr(f),
    @debug.to_repr(g),
    @debug.to_repr(h),
    @debug.to_repr(i),
    @debug.to_repr(j),
    @debug.to_repr(k),
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
    @debug.to_repr(a),
    @debug.to_repr(b),
    @debug.to_repr(c),
    @debug.to_repr(d),
    @debug.to_repr(e),
    @debug.to_repr(f),
    @debug.to_repr(g),
    @debug.to_repr(h),
    @debug.to_repr(i),
    @debug.to_repr(j),
    @debug.to_repr(k),
    @debug.to_repr(l),
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
    @debug.to_repr(a),
    @debug.to_repr(b),
    @debug.to_repr(c),
    @debug.to_repr(d),
    @debug.to_repr(e),
    @debug.to_repr(f),
    @debug.to_repr(g),
    @debug.to_repr(h),
    @debug.to_repr(i),
    @debug.to_repr(j),
    @debug.to_repr(k),
    @debug.to_repr(l),
    @debug.to_repr(m),
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
    @debug.to_repr(a),
    @debug.to_repr(b),
    @debug.to_repr(c),
    @debug.to_repr(d),
    @debug.to_repr(e),
    @debug.to_repr(f),
    @debug.to_repr(g),
    @debug.to_repr(h),
    @debug.to_repr(i),
    @debug.to_repr(j),
    @debug.to_repr(k),
    @debug.to_repr(l),
    @debug.to_repr(m),
    @debug.to_repr(n),
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
    @debug.to_repr(a),
    @debug.to_repr(b),
    @debug.to_repr(c),
    @debug.to_repr(d),
    @debug.to_repr(e),
    @debug.to_repr(f),
    @debug.to_repr(g),
    @debug.to_repr(h),
    @debug.to_repr(i),
    @debug.to_repr(j),
    @debug.to_repr(k),
    @debug.to_repr(l),
    @debug.to_repr(m),
    @debug.to_repr(n),
    @debug.to_repr(o),
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
    @debug.to_repr(a),
    @debug.to_repr(b),
    @debug.to_repr(c),
    @debug.to_repr(d),
    @debug.to_repr(e),
    @debug.to_repr(f),
    @debug.to_repr(g),
    @debug.to_repr(h),
    @debug.to_repr(i),
    @debug.to_repr(j),
    @debug.to_repr(k),
    @debug.to_repr(l),
    @debug.to_repr(m),
    @debug.to_repr(n),
    @debug.to_repr(o),
    @debug.to_repr(p),
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
    @debug.to_repr(a),
    @debug.to_repr(b),
    @debug.to_repr(c),
    @debug.to_repr(d),
    @debug.to_repr(e),
    @debug.to_repr(f),
    @debug.to_repr(g),
    @debug.to_repr(h),
    @debug.to_repr(i),
    @debug.to_repr(j),
    @debug.to_repr(k),
    @debug.to_repr(l),
    @debug.to_repr(m),
    @debug.to_repr(n),
    @debug.to_repr(o),
    @debug.to_repr(p),
    @debug.to_repr(q),
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
    @debug.to_repr(a),
    @debug.to_repr(b),
    @debug.to_repr(c),
    @debug.to_repr(d),
    @debug.to_repr(e),
    @debug.to_repr(f),
    @debug.to_repr(g),
    @debug.to_repr(h),
    @debug.to_repr(i),
    @debug.to_repr(j),
    @debug.to_repr(k),
    @debug.to_repr(l),
    @debug.to_repr(m),
    @debug.to_repr(n),
    @debug.to_repr(o),
    @debug.to_repr(p),
    @debug.to_repr(q),
    @debug.to_repr(r),
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
    @debug.to_repr(a),
    @debug.to_repr(b),
    @debug.to_repr(c),
    @debug.to_repr(d),
    @debug.to_repr(e),
    @debug.to_repr(f),
    @debug.to_repr(g),
    @debug.to_repr(h),
    @debug.to_repr(i),
    @debug.to_repr(j),
    @debug.to_repr(k),
    @debug.to_repr(l),
    @debug.to_repr(m),
    @debug.to_repr(n),
    @debug.to_repr(o),
    @debug.to_repr(p),
    @debug.to_repr(q),
    @debug.to_repr(r),
    @debug.to_repr(s),
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
    @debug.to_repr(a),
    @debug.to_repr(b),
    @debug.to_repr(c),
    @debug.to_repr(d),
    @debug.to_repr(e),
    @debug.to_repr(f),
    @debug.to_repr(g),
    @debug.to_repr(h),
    @debug.to_repr(i),
    @debug.to_repr(j),
    @debug.to_repr(k),
    @debug.to_repr(l),
    @debug.to_repr(m),
    @debug.to_repr(n),
    @debug.to_repr(o),
    @debug.to_repr(p),
    @debug.to_repr(q),
    @debug.to_repr(r),
    @debug.to_repr(s),
    @debug.to_repr(t),
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
    @debug.to_repr(a),
    @debug.to_repr(b),
    @debug.to_repr(c),
    @debug.to_repr(d),
    @debug.to_repr(e),
    @debug.to_repr(f),
    @debug.to_repr(g),
    @debug.to_repr(h),
    @debug.to_repr(i),
    @debug.to_repr(j),
    @debug.to_repr(k),
    @debug.to_repr(l),
    @debug.to_repr(m),
    @debug.to_repr(n),
    @debug.to_repr(o),
    @debug.to_repr(p),
    @debug.to_repr(q),
    @debug.to_repr(r),
    @debug.to_repr(s),
    @debug.to_repr(t),
    @debug.to_repr(u),
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
    @debug.to_repr(a),
    @debug.to_repr(b),
    @debug.to_repr(c),
    @debug.to_repr(d),
    @debug.to_repr(e),
    @debug.to_repr(f),
    @debug.to_repr(g),
    @debug.to_repr(h),
    @debug.to_repr(i),
    @debug.to_repr(j),
    @debug.to_repr(k),
    @debug.to_repr(l),
    @debug.to_repr(m),
    @debug.to_repr(n),
    @debug.to_repr(o),
    @debug.to_repr(p),
    @debug.to_repr(q),
    @debug.to_repr(r),
    @debug.to_repr(s),
    @debug.to_repr(t),
    @debug.to_repr(u),
    @debug.to_repr(v),
  ])
}

///|
test "tuple Debug implementations" {
  @debug.debug_inspect(
    (1, "a"),
    content=(
      #|(1, "a")
    ),
  )

  @debug.debug_inspect(
    (1, "a", true),
    content=(
      #|(1, "a", true)
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0),
    content=(
      #|(1, "a", true, 2)
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c'),
    content=(
      #|(1, "a", true, 2, 'c')
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6),
    content=(
      #|(1, "a", true, 2, 'c', 6)
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g"),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g")
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g", false)
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g", false, 9)
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j"),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g", false, 9, "j")
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g", false, 9, "j", 11)
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l"),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g", false, 9, "j", 11, "l")
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g", false, 9, "j", 11, "l", 13)
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n"),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n")
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15)
    ),
  )

  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p"),
    content=(
      #|(
      #|  1,
      #|  "a",
      #|  true,
      #|  2,
      #|  'c',
      #|  6,
      #|  "g",
      #|  false,
      #|  9,
      #|  "j",
      #|  11,
      #|  "l",
      #|  13,
      #|  "n",
      #|  15,
      #|  "p",
      #|)
    ),
  )

  @debug.debug_inspect(
    (
      1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p", 17,
    ),
    content=(
      #|(
      #|  1,
      #|  "a",
      #|  true,
      #|  2,
      #|  'c',
      #|  6,
      #|  "g",
      #|  false,
      #|  9,
      #|  "j",
      #|  11,
      #|  "l",
      #|  13,
      #|  "n",
      #|  15,
      #|  "p",
      #|  17,
      #|)
    ),
  )

  @debug.debug_inspect(
    (
      1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p", 17,
      "r",
    ),
    content=(
      #|(
      #|  1,
      #|  "a",
      #|  true,
      #|  2,
      #|  'c',
      #|  6,
      #|  "g",
      #|  false,
      #|  9,
      #|  "j",
      #|  11,
      #|  "l",
      #|  13,
      #|  "n",
      #|  15,
      #|  "p",
      #|  17,
      #|  "r",
      #|)
    ),
  )

  @debug.debug_inspect(
    (
      1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p", 17,
      "r", 19,
    ),
    content=(
      #|(
      #|  1,
      #|  "a",
      #|  true,
      #|  2,
      #|  'c',
      #|  6,
      #|  "g",
      #|  false,
      #|  9,
      #|  "j",
      #|  11,
      #|  "l",
      #|  13,
      #|  "n",
      #|  15,
      #|  "p",
      #|  17,
      #|  "r",
      #|  19,
      #|)
    ),
  )

  @debug.debug_inspect(
    (
      1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p", 17,
      "r", 19, "t",
    ),
    content=(
      #|(
      #|  1,
      #|  "a",
      #|  true,
      #|  2,
      #|  'c',
      #|  6,
      #|  "g",
      #|  false,
      #|  9,
      #|  "j",
      #|  11,
      #|  "l",
      #|  13,
      #|  "n",
      #|  15,
      #|  "p",
      #|  17,
      #|  "r",
      #|  19,
      #|  "t",
      #|)
    ),
  )

  @debug.debug_inspect(
    (
      1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p", 17,
      "r", 19, "t", 21,
    ),
    content=(
      #|(
      #|  1,
      #|  "a",
      #|  true,
      #|  2,
      #|  'c',
      #|  6,
      #|  "g",
      #|  false,
      #|  9,
      #|  "j",
      #|  11,
      #|  "l",
      #|  13,
      #|  "n",
      #|  15,
      #|  "p",
      #|  17,
      #|  "r",
      #|  19,
      #|  "t",
      #|  21,
      #|)
    ),
  )

  @debug.debug_inspect(
    (
      1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p", 17,
      "r", 19, "t", 21, "v",
    ),
    content=(
      #|(
      #|  1,
      #|  "a",
      #|  true,
      #|  2,
      #|  'c',
      #|  6,
      #|  "g",
      #|  false,
      #|  9,
      #|  "j",
      #|  11,
      #|  "l",
      #|  13,
      #|  "n",
      #|  15,
      #|  "p",
      #|  17,
      #|  "r",
      #|  19,
      #|  "t",
      #|  21,
      #|  "v",
      #|)
    ),
  )
}
