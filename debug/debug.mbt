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
/// Trait for types that can be converted to human-readable debugging info.
pub trait Debug {
  to_repr(Self) -> Repr
}

///|
pub impl Debug for Int with to_repr(self) {
  Repr::integer(self.to_string())
}

///|
pub impl Debug for Int16 with to_repr(self) {
  Repr::integer(self.to_string())
}

///|
pub impl Debug for Int64 with to_repr(self) {
  Repr::integer(self.to_string())
}

///|
pub impl Debug for UInt16 with to_repr(self) {
  Repr::integer(self.to_string())
}

///|
pub impl Debug for UInt with to_repr(self) {
  Repr::integer(self.to_string())
}

///|
pub impl Debug for UInt64 with to_repr(self) {
  Repr::integer(self.to_string())
}

///|
pub impl Debug for Double with to_repr(self) {
  Repr::double(self)
}

///|
pub impl Debug for Float with to_repr(self) {
  Repr::float(self)
}

///|
pub impl Debug for Bool with to_repr(self) {
  Repr::bool(self)
}

///|
pub impl Debug for Byte with to_repr(self) {
  // Use hex to make byte sequences easier to read.
  Repr::literal("0x" + self.to_hex())
}

///|
pub impl Debug for Char with to_repr(self) {
  Repr::char(self)
}

///|
pub impl Debug for String with to_repr(self) {
  Repr::string(self)
}

///|
pub impl Debug for StringView with to_repr(self) {
  Repr::opaque_("StringView", Repr::string(self.to_string()))
}

///|
pub impl Debug for Bytes with to_repr(self) {
  Repr::opaque_(
    "Bytes",
    Repr::array(self.to_array().map(fn(b) { Debug::to_repr(b) })),
  )
}

///|
pub impl Debug for BytesView with to_repr(self) {
  Repr::opaque_(
    "BytesView",
    Repr::array(self.to_array().map(fn(b) { Debug::to_repr(b) })),
  )
}

///|
pub impl Debug for Unit with to_repr(_) {
  Repr::unit()
}

///|
pub impl[T : Debug] Debug for Array[T] with to_repr(self) {
  Repr::array(self.map(fn(x) { x.to_repr() }))
}

///|
pub impl[T : Debug] Debug for ArrayView[T] with to_repr(self) {
  Repr::opaque_(
    "ArrayView",
    Repr::array(self.to_array().map(fn(x) { x.to_repr() })),
  )
}

///|
pub impl[T : Debug] Debug for FixedArray[T] with to_repr(self) {
  // `FixedArray` can be viewed as `ArrayView` via slicing.
  let view : ArrayView[T] = self[:]
  Repr::opaque_(
    "FixedArray",
    Repr::array(view.to_array().map(fn(x) { x.to_repr() })),
  )
}

///|
pub impl[T : Debug] Debug for ReadOnlyArray[T] with to_repr(self) {
  // `ReadOnlyArray` can be viewed as `ArrayView` via slicing.
  let view : ArrayView[T] = self[:]
  Repr::opaque_(
    "ReadOnlyArray",
    Repr::array(view.to_array().map(fn(x) { x.to_repr() })),
  )
}

///|
pub impl[T : Debug] Debug for T? with to_repr(self) {
  match self {
    None => Repr::ctor("None", [])
    Some(x) => Repr::ctor("Some", [(None, x.to_repr())])
  }
}

///|
pub impl[T : Debug, E : Debug] Debug for Result[T, E] with to_repr(self) {
  match self {
    Ok(x) => Repr::ctor("Ok", [(None, x.to_repr())])
    Err(e) => Repr::ctor("Err", [(None, e.to_repr())])
  }
}

///|
pub impl[A : Debug] Debug for @list.List[A] with to_repr(self) {
  Repr::opaque_("List", Repr::array(self.to_array().map(fn(x) { x.to_repr() })))
}

///|
pub impl[K : Debug, V : Debug] Debug for @hashmap.HashMap[K, V] with to_repr(
  self,
) {
  let entries : Array[(Repr, Repr)] = self
    .to_array()
    .map(kv => (kv.0.to_repr(), kv.1.to_repr()))
  Repr::opaque_("HashMap", Repr::map(entries))
}

///|
pub impl[K : Debug] Debug for @hashset.HashSet[K] with to_repr(self) {
  let xs : Array[Repr] = self.to_array().map(fn(x) { x.to_repr() })
  Repr::opaque_("HashSet", Repr::array(xs))
}

///|
pub impl[A : Debug] Debug for @deque.Deque[A] with to_repr(self) {
  Repr::opaque_("Deque", Repr::array(self.to_array().map(x => x.to_repr())))
}

///|
pub impl[A : Debug] Debug for @queue.Queue[A] with to_repr(self) {
  Repr::opaque_(
    "Queue",
    Repr::array(self.iter().to_array().map(x => x.to_repr())),
  )
}

///|
pub impl[A] Debug for Iter[A] with to_repr(_) {
  Repr::opaque_("Iter", Omitted)
}

///|
pub impl[A, B] Debug for Iter2[A, B] with to_repr(_) {
  Repr::opaque_("Iter2", Omitted)
}

///|
pub impl[T : Debug] Debug for MutArrayView[T] with to_repr(self) {
  Repr::opaque_(
    "MutArrayView",
    Repr::array(self[:].to_array().map(x => x.to_repr())),
  )
}

///|
pub impl[T : Debug] Debug for Ref[T] with to_repr(self) {
  Repr::opaque_("Ref", self.val.to_repr())
}

///|
pub impl[A : Debug + Compare] Debug for @priority_queue.PriorityQueue[A] with to_repr(
  self,
) {
  // `PriorityQueue` iteration order depends on internal heap state; sort for stable output.
  let xs : Array[Repr] = self.to_array().map(x => x.to_repr())
  Repr::opaque_("PriorityQueue", Repr::array(xs))
}

///|
pub impl Debug for @buffer.Buffer with to_repr(self) {
  // Represent buffer by its current bytes content.
  Repr::opaque_("Buffer", Debug::to_repr(self.to_bytes().to_array()))
}

///|
pub impl[K : Debug, V : Debug] Debug for @immut_sorted_map.SortedMap[K, V] with to_repr(
  self,
) {
  Repr::opaque_(
    "SortedMap",
    Repr::map(self.to_array().map(kv => (kv.0.to_repr(), kv.1.to_repr()))),
  )
}

///|
pub impl[K : Debug] Debug for @immut_sorted_set.SortedSet[K] with to_repr(self) {
  Repr::opaque_(
    "SortedSet",
    Repr::array(self.to_array().map(fn(x) { x.to_repr() })),
  )
}

///|
pub impl[K : Debug, V : Debug] Debug for @immut_hashmap.HashMap[K, V] with to_repr(
  self,
) {
  let entries : Array[(Repr, Repr)] = self
    .to_array()
    .map(kv => (kv.0.to_repr(), kv.1.to_repr()))
  Repr::opaque_("HashMap", Repr::map(entries))
}

///|
pub impl[K : Debug] Debug for @immut_hashset.HashSet[K] with to_repr(self) {
  let xs : Array[Repr] = self.iter().to_array().map(fn(x) { x.to_repr() })
  Repr::opaque_("HashSet", Repr::array(xs))
}

///|
#warnings("-deprecated")
pub impl[A : Debug] Debug for @immut_list.T[A] with to_repr(self) {
  Repr::opaque_("List", Repr::array(self.to_array().map(fn(x) { x.to_repr() })))
}

///|
pub impl[A : Debug] Debug for @immut_array.T[A] with to_repr(self) {
  Repr::opaque_(
    "Array",
    Repr::array(self.to_array().map(fn(x) { x.to_repr() })),
  )
}

///|
pub impl[A : Debug + Compare] Debug for @immut_priority_queue.PriorityQueue[A] with to_repr(
  self,
) {
  let xs : Array[Repr] = self.to_array().map(fn(x) { x.to_repr() })
  Repr::opaque_("PriorityQueue", Repr::array(xs))
}

///|
pub impl[K : Debug, V : Debug] Debug for Map[K, V] with to_repr(self) {
  Repr::map(
    self
    .to_array()
    .map(fn(kv) {
      let (k, v) = kv
      (k.to_repr(), v.to_repr())
    }),
  )
}

///|
pub impl Debug for SourceLoc with to_repr(self) {
  Repr::opaque_("SourceLoc", Repr::string(self.to_string()))
}

///|
pub impl[A : Debug, B : Debug] Debug for (A, B) with to_repr(self) {
  let (a, b) = self
  Repr::tuple([a.to_repr(), b.to_repr()])
}

///|
pub impl[A : Debug, B : Debug, C : Debug] Debug for (A, B, C) with to_repr(self) {
  let (a, b, c) = self
  Repr::tuple([a.to_repr(), b.to_repr(), c.to_repr()])
}

///|
pub impl[A : Debug, B : Debug, C : Debug, D : Debug] Debug for (A, B, C, D) with to_repr(
  self,
) {
  let (a, b, c, d) = self
  Repr::tuple([a.to_repr(), b.to_repr(), c.to_repr(), d.to_repr()])
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
  Repr::tuple([a.to_repr(), b.to_repr(), c.to_repr(), d.to_repr(), e.to_repr()])
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
    a.to_repr(),
    b.to_repr(),
    c.to_repr(),
    d.to_repr(),
    e.to_repr(),
    f.to_repr(),
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
    a.to_repr(),
    b.to_repr(),
    c.to_repr(),
    d.to_repr(),
    e.to_repr(),
    f.to_repr(),
    g.to_repr(),
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
    a.to_repr(),
    b.to_repr(),
    c.to_repr(),
    d.to_repr(),
    e.to_repr(),
    f.to_repr(),
    g.to_repr(),
    h.to_repr(),
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
    a.to_repr(),
    b.to_repr(),
    c.to_repr(),
    d.to_repr(),
    e.to_repr(),
    f.to_repr(),
    g.to_repr(),
    h.to_repr(),
    i.to_repr(),
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
    a.to_repr(),
    b.to_repr(),
    c.to_repr(),
    d.to_repr(),
    e.to_repr(),
    f.to_repr(),
    g.to_repr(),
    h.to_repr(),
    i.to_repr(),
    j.to_repr(),
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
    a.to_repr(),
    b.to_repr(),
    c.to_repr(),
    d.to_repr(),
    e.to_repr(),
    f.to_repr(),
    g.to_repr(),
    h.to_repr(),
    i.to_repr(),
    j.to_repr(),
    k.to_repr(),
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
    a.to_repr(),
    b.to_repr(),
    c.to_repr(),
    d.to_repr(),
    e.to_repr(),
    f.to_repr(),
    g.to_repr(),
    h.to_repr(),
    i.to_repr(),
    j.to_repr(),
    k.to_repr(),
    l.to_repr(),
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
    a.to_repr(),
    b.to_repr(),
    c.to_repr(),
    d.to_repr(),
    e.to_repr(),
    f.to_repr(),
    g.to_repr(),
    h.to_repr(),
    i.to_repr(),
    j.to_repr(),
    k.to_repr(),
    l.to_repr(),
    m.to_repr(),
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
    a.to_repr(),
    b.to_repr(),
    c.to_repr(),
    d.to_repr(),
    e.to_repr(),
    f.to_repr(),
    g.to_repr(),
    h.to_repr(),
    i.to_repr(),
    j.to_repr(),
    k.to_repr(),
    l.to_repr(),
    m.to_repr(),
    n.to_repr(),
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
    a.to_repr(),
    b.to_repr(),
    c.to_repr(),
    d.to_repr(),
    e.to_repr(),
    f.to_repr(),
    g.to_repr(),
    h.to_repr(),
    i.to_repr(),
    j.to_repr(),
    k.to_repr(),
    l.to_repr(),
    m.to_repr(),
    n.to_repr(),
    o.to_repr(),
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
    a.to_repr(),
    b.to_repr(),
    c.to_repr(),
    d.to_repr(),
    e.to_repr(),
    f.to_repr(),
    g.to_repr(),
    h.to_repr(),
    i.to_repr(),
    j.to_repr(),
    k.to_repr(),
    l.to_repr(),
    m.to_repr(),
    n.to_repr(),
    o.to_repr(),
    p.to_repr(),
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
    a.to_repr(),
    b.to_repr(),
    c.to_repr(),
    d.to_repr(),
    e.to_repr(),
    f.to_repr(),
    g.to_repr(),
    h.to_repr(),
    i.to_repr(),
    j.to_repr(),
    k.to_repr(),
    l.to_repr(),
    m.to_repr(),
    n.to_repr(),
    o.to_repr(),
    p.to_repr(),
    q.to_repr(),
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
    a.to_repr(),
    b.to_repr(),
    c.to_repr(),
    d.to_repr(),
    e.to_repr(),
    f.to_repr(),
    g.to_repr(),
    h.to_repr(),
    i.to_repr(),
    j.to_repr(),
    k.to_repr(),
    l.to_repr(),
    m.to_repr(),
    n.to_repr(),
    o.to_repr(),
    p.to_repr(),
    q.to_repr(),
    r.to_repr(),
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
    a.to_repr(),
    b.to_repr(),
    c.to_repr(),
    d.to_repr(),
    e.to_repr(),
    f.to_repr(),
    g.to_repr(),
    h.to_repr(),
    i.to_repr(),
    j.to_repr(),
    k.to_repr(),
    l.to_repr(),
    m.to_repr(),
    n.to_repr(),
    o.to_repr(),
    p.to_repr(),
    q.to_repr(),
    r.to_repr(),
    s.to_repr(),
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
    a.to_repr(),
    b.to_repr(),
    c.to_repr(),
    d.to_repr(),
    e.to_repr(),
    f.to_repr(),
    g.to_repr(),
    h.to_repr(),
    i.to_repr(),
    j.to_repr(),
    k.to_repr(),
    l.to_repr(),
    m.to_repr(),
    n.to_repr(),
    o.to_repr(),
    p.to_repr(),
    q.to_repr(),
    r.to_repr(),
    s.to_repr(),
    t.to_repr(),
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
    a.to_repr(),
    b.to_repr(),
    c.to_repr(),
    d.to_repr(),
    e.to_repr(),
    f.to_repr(),
    g.to_repr(),
    h.to_repr(),
    i.to_repr(),
    j.to_repr(),
    k.to_repr(),
    l.to_repr(),
    m.to_repr(),
    n.to_repr(),
    o.to_repr(),
    p.to_repr(),
    q.to_repr(),
    r.to_repr(),
    s.to_repr(),
    t.to_repr(),
    u.to_repr(),
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
    a.to_repr(),
    b.to_repr(),
    c.to_repr(),
    d.to_repr(),
    e.to_repr(),
    f.to_repr(),
    g.to_repr(),
    h.to_repr(),
    i.to_repr(),
    j.to_repr(),
    k.to_repr(),
    l.to_repr(),
    m.to_repr(),
    n.to_repr(),
    o.to_repr(),
    p.to_repr(),
    q.to_repr(),
    r.to_repr(),
    s.to_repr(),
    t.to_repr(),
    u.to_repr(),
    v.to_repr(),
  ])
}

///|
/// Checks that the structural representation (`Repr`) of an object matches the
/// expected content. Used in test blocks to ensure API results are as expected,
/// and stores a pretty-printed string for comparison.
///
/// Parameters:
/// - `obj`: The object to inspect. Must implement the `Debug` trait.
/// - `content`: The expected string representation of the object. Defaults to an empty string if not provided.
/// - `loc`: Source code location information for error reporting. Automatically provided by the compiler.
/// - `args_loc`: Location information for function arguments in the source code. Automatically provided by the compiler.
///
/// Raises an `InspectError` if the actual `Repr` does not match the expected content.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(42, content="42")
///   inspect('c', content="'c'")
///   inspect(
///     "hello",
///     content=(
///       #|"hello"
///     ),
///   )
///   inspect(
///     ([1, 2, 3, 4], "string", Some(3.14)),
///     content=(
///       #|(
///       #|  [1, 2, 3, 4],
///       #|  "string",
///       #|  Some(3.14),
///       #|)
///     ),
///   )
/// }
/// ```
#callsite(autofill(args_loc, loc))
pub fn inspect(
  obj : &Debug,
  content? : String,
  loc~ : SourceLoc,
  args_loc~ : ArgsLoc,
) -> Unit raise InspectError {
  let loc = loc.to_json_string()
  let args_loc = args_loc.to_json()
  let actual = render(obj.to_repr())
  let want = match content {
    None => ""
    Some(x) => x
  }
  if actual != want {
    raise InspectError(
      "@EXPECT_FAILED {\"loc\": \{loc}, \"args_loc\": \{args_loc}, \"expect\": \{want.escape()}, \"actual\": \{actual.escape()} }",
    )
  }
}
