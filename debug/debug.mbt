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
pub impl[A] Debug for Iterator[A] with to_repr(_) {
  Repr::opaque_("Iterator", Omitted)
}

///|
pub impl[A, B] Debug for Iter2[A, B] with to_repr(_) {
  Repr::opaque_("Iter2", Omitted)
}

///|
pub impl[A, B] Debug for Iterator2[A, B] with to_repr(_) {
  Repr::opaque_("Iterator2", Omitted)
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
test "tuple Debug implementations" {
  inspect(pretty_test((1, "a")), content="(1, \"a\")")

  // Test tuple3
  inspect(pretty_test((1, "a", true)), content="(1, \"a\", true)")

  // Test tuple4
  inspect(
    pretty_test((1, "a", true, 2.0)),
    content=(
      #|(1, "a", true, 2)
    ),
  )

  // Test tuple5
  inspect(
    pretty_test((1, "a", true, 2.0, 'c')),
    content=(
      #|(1, "a", true, 2, 'c')
    ),
  )

  // Test tuple6
  inspect(
    pretty_test((1, "a", true, 2.0, 'c', 6)),
    content=(
      #|(1, "a", true, 2, 'c', 6)
    ),
  )

  // Test tuple7
  inspect(
    pretty_test((1, "a", true, 2.0, 'c', 6, "g")),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g")
    ),
  )

  // Test tuple8
  inspect(
    pretty_test((1, "a", true, 2.0, 'c', 6, "g", false)),
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
      #|)
    ),
  )

  // Test tuple9
  inspect(
    pretty_test((1, "a", true, 2.0, 'c', 6, "g", false, 9)),
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
      #|)
    ),
  )

  // Test tuple10
  inspect(
    pretty_test((1, "a", true, 2.0, 'c', 6, "g", false, 9, "j")),
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
      #|)
    ),
  )

  // Test tuple11
  inspect(
    pretty_test((1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11)),
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
      #|)
    ),
  )

  // Test tuple12
  inspect(
    pretty_test((1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l")),
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
      #|)
    ),
  )

  // Test tuple13
  inspect(
    pretty_test((1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13)),
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
      #|)
    ),
  )

  // Test tuple14
  inspect(
    pretty_test(
      (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n"),
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
      #|)
    ),
  )

  // Test tuple15
  inspect(
    pretty_test(
      (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15),
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
      #|)
    ),
  )

  // Test tuple16
  inspect(
    pretty_test(
      (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p"),
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
      #|)
    ),
  )

  // Test tuple17
  inspect(
    pretty_test(
      (
        1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p",
        17,
      ),
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

  // Test tuple18
  inspect(
    pretty_test(
      (
        1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p",
        17, "r",
      ),
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

  // Test tuple19
  inspect(
    pretty_test(
      (
        1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p",
        17, "r", 19,
      ),
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

  // Test tuple20
  inspect(
    pretty_test(
      (
        1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p",
        17, "r", 19, "t",
      ),
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

  // Test tuple21
  inspect(
    pretty_test(
      (
        1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p",
        17, "r", 19, "t", 21,
      ),
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

  // Test tuple22
  inspect(
    pretty_test(
      (
        1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p",
        17, "r", 19, "t", 21, "v",
      ),
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

///|
#warnings("-deprecated")
test "core data structures Debug implementations" {
  inspect(pretty_test((1 : Int16)), content="1")
  inspect(pretty_test((1 : UInt16)), content="1")
  inspect(pretty_test((1 : UInt64)), content="1")
  inspect(pretty_test((1.0 : Float)), content="1")
  let b : Bytes = b"ab"
  inspect(pretty_test(b), content="<Bytes: [0x61, 0x62]>")
  let bv : BytesView = b[:]
  inspect(pretty_test(bv), content="<BytesView: [0x61, 0x62]>")
  let sv : StringView = "abc"[:]
  inspect(
    pretty_test(sv),
    content=(
      #|<StringView: "abc">
    ),
  )
  let av : ArrayView[Int] = [1, 2, 3][1:3]
  inspect(pretty_test(av), content="<ArrayView: [2, 3]>")
  let fa : FixedArray[Int] = [1, 2, 3]
  inspect(pretty_test(fa), content="<FixedArray: [1, 2, 3]>")
  let ro : ReadOnlyArray[Int] = [1, 2, 3]
  inspect(pretty_test(ro), content="<ReadOnlyArray: [1, 2, 3]>")
  let lst : @list.List[Int] = @list.from_array([1, 2, 3])
  inspect(pretty_test(lst), content="<List: [1, 2, 3]>")
  let dq : @deque.Deque[Int] = @deque.from_array([1, 2, 3])
  inspect(pretty_test(dq), content="<Deque: [1, 2, 3]>")
  let q : @queue.Queue[Int] = @queue.from_array([1, 2, 3])
  inspect(pretty_test(q), content="<Queue: [1, 2, 3]>")
  let pq : @priority_queue.PriorityQueue[Int] = @priority_queue.from_array([
    3, 1, 2,
  ])
  inspect(pretty_test(pq), content="<PriorityQueue: [3, 2, 1]>")
  let buf = @buffer.new()
  buf.write_bytes(b"ab")
  inspect(pretty_test(buf), content="<Buffer: [0x61, 0x62]>")
  let r : Ref[Int] = @ref.new(1)
  inspect(pretty_test(r), content="<Ref: 1>")
  let mv : MutArrayView[Int] = [1, 2, 3].mut_view(start=1, end=3)
  inspect(pretty_test(mv), content="<MutArrayView: [2, 3]>")
  inspect(pretty_test((Ok(1) : Result[Int, String])), content="Ok(1)")
  inspect(pretty_test((Err("e") : Result[Int, String])), content="Err(\"e\")")

  // Test immut containers
  let immut_lst = @immut_list.from_array([1, 2, 3])
  inspect(pretty_test(immut_lst), content="<List: [1, 2, 3]>")
  let immut_arr = @immut_array.from_array([1, 2, 3])
  inspect(pretty_test(immut_arr), content="<Array: [1, 2, 3]>")
  let immut_pq = @immut_priority_queue.from_array([3, 1, 2])
  inspect(pretty_test(immut_pq), content="<PriorityQueue: [3, 2, 1]>")
  let immut_sm = @immut_sorted_map.from_array([(1, "a"), (2, "b")])
  inspect(
    pretty_test(immut_sm),
    content=(
      #|<SortedMap:
      #|  { 1: "a", 2: "b" }>
    ),
  )
  let immut_ss = @immut_sorted_set.from_array([3, 1, 2])
  inspect(pretty_test(immut_ss), content="<SortedSet: [1, 2, 3]>")
}

///|
test "Debug for hash-based collections" {
  // The order is unstable.
  let hm : @hashmap.HashMap[Int, String] = @hashmap.from_array([(2, "b")])
  inspect(
    pretty_test(hm),
    content=(
      #|<HashMap: { 2: "b" }>
    ),
  )
  let hs : @hashset.HashSet[Int] = @hashset.from_array([1])
  inspect(pretty_test(hs), content="<HashSet: [1]>")
  let immut_hm = @immut_hashmap.from_array([(2, "b")])
  inspect(pretty_test(immut_hm), content="<HashMap: { 2: \"b\" }>")
  let immut_hs = @immut_hashset.from_array([3])
  inspect(pretty_test(immut_hs), content="<HashSet: [3]>")
}

///|
fn[T : Debug] pretty_test(x : T) -> String {
  x.to_repr() |> render
}
