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
pub impl[T : Shrink] Shrink for T? with fn shrink(x) {
  match x {
    None => [||]
    Some(v) => Shrink::shrink(v).map(v1 => Some(v1)).concat([|None|])
  }
}

///|
pub impl[T : Shrink, E : Shrink] Shrink for Result[T, E] with fn shrink(x) {
  match x {
    Ok(v) => Shrink::shrink(v).map(v1 => Ok(v1))
    Err(e) => Shrink::shrink(e).map(e1 => Err(e1))
  }
}

///|
pub impl[X : Shrink] Shrink for Array[X] with fn shrink(xs) {
  let view = xs[:]
  let n = view.length()
  fn shr_sub_terms(arr : ArrayView[X]) {
    match arr {
      [] => [||]
      [x, .. xs] =>
        X::shrink(x)
        .map(x_ => [x_, ..xs])
        .concat(shr_sub_terms(xs).map(xs_ => [x, ..xs_]))
    }
  }

  [
    for k = n; k > 0; k = k / 2 => k
  ]
  .iter()
  .flat_map(k => removes_array(k, n, xs))
  .concat(shr_sub_terms(view))
}

///|
pub impl[X : Shrink] Shrink for FixedArray[X] with fn shrink(xs) {
  Shrink::shrink(xs[:].to_owned()).map(candidate => {
    FixedArray::from_array(candidate)
  })
}

///|
pub impl[X : Shrink] Shrink for ArrayView[X] with fn shrink(xs) {
  let candidates : Iter[Array[X]] = Shrink::shrink(xs.to_owned())
  candidates.map(candidate => candidate)
}

///|
pub impl[A : Shrink, B : Shrink] Shrink for (A, B) with fn shrink(x) {
  let (a, b) = x
  Shrink::shrink(a)
  .map(a1 => (a1, b))
  .concat(Shrink::shrink(b).map(b1 => (a, b1)))
}

///|
pub impl[A : Shrink, B : Shrink, C : Shrink] Shrink for (A, B, C) with fn shrink(
  x,
) {
  let (a, b, c) = x
  Shrink::shrink((a, (b, c))).map(y => {
    let (a1, (b1, c1)) = y
    (a1, b1, c1)
  })
}

///|
pub impl[A : Shrink, B : Shrink, C : Shrink, D : Shrink] Shrink for (A, B, C, D) with fn shrink(
  x,
) {
  let (a, b, c, d) = x
  Shrink::shrink((a, (b, c, d))).map(y => {
    let (a1, (b1, c1, d1)) = y
    (a1, b1, c1, d1)
  })
}

///|
pub impl[A : Shrink, B : Shrink, C : Shrink, D : Shrink, E : Shrink] Shrink for (
  A,
  B,
  C,
  D,
  E,
) with fn shrink(x) {
  let (a, b, c, d, e) = x
  Shrink::shrink((a, (b, c, d, e))).map(y => {
    let (a1, (b1, c1, d1, e1)) = y
    (a1, b1, c1, d1, e1)
  })
}

///|
pub impl[A : Shrink, B : Shrink, C : Shrink, D : Shrink, E : Shrink, F : Shrink] Shrink for (
  A,
  B,
  C,
  D,
  E,
  F,
) with fn shrink(x) {
  let (a, b, c, d, e, f) = x
  Shrink::shrink((a, (b, c, d, e, f))).map(y => {
    let (a1, (b1, c1, d1, e1, f1)) = y
    (a1, b1, c1, d1, e1, f1)
  })
}

///|
pub impl[
  A : Shrink,
  B : Shrink,
  C : Shrink,
  D : Shrink,
  E : Shrink,
  F : Shrink,
  G : Shrink,
] Shrink for (A, B, C, D, E, F, G) with fn shrink(x) {
  let (a, b, c, d, e, f, g) = x
  Shrink::shrink((a, (b, c, d, e, f, g))).map(y => {
    let (a1, (b1, c1, d1, e1, f1, g1)) = y
    (a1, b1, c1, d1, e1, f1, g1)
  })
}

///|
pub impl[
  A : Shrink,
  B : Shrink,
  C : Shrink,
  D : Shrink,
  E : Shrink,
  F : Shrink,
  G : Shrink,
  H : Shrink,
] Shrink for (A, B, C, D, E, F, G, H) with fn shrink(x) {
  let (a, b, c, d, e, f, g, h) = x
  Shrink::shrink((a, (b, c, d, e, f, g, h))).map(y => {
    let (a1, (b1, c1, d1, e1, f1, g1, h1)) = y
    (a1, b1, c1, d1, e1, f1, g1, h1)
  })
}

///|
pub impl[
  A : Shrink,
  B : Shrink,
  C : Shrink,
  D : Shrink,
  E : Shrink,
  F : Shrink,
  G : Shrink,
  H : Shrink,
  I : Shrink,
] Shrink for (A, B, C, D, E, F, G, H, I) with fn shrink(x) {
  let (a, b, c, d, e, f, g, h, i) = x
  Shrink::shrink((a, (b, c, d, e, f, g, h, i))).map(y => {
    let (a1, (b1, c1, d1, e1, f1, g1, h1, i1)) = y
    (a1, b1, c1, d1, e1, f1, g1, h1, i1)
  })
}
