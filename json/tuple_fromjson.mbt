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
pub impl[A : FromJson, B : FromJson] FromJson for (A, B) with from_json!(
  json,
  path
) {
  match json {
    [a, b] => {
      let a : A = FromJson::from_json!(a, path.add_index(0))
      let b : B = FromJson::from_json!(b, path.add_index(1))
      (a, b)
    }
    _ => decode_error!(path, "expected tuple of size 2")
  }
}

///|
pub impl[A : FromJson, B : FromJson, C : FromJson] FromJson for (A, B, C) with from_json!(
  json,
  path
) {
  match json {
    [a, b, c] => {
      let a : A = FromJson::from_json!(a, path.add_index(0))
      let b : B = FromJson::from_json!(b, path.add_index(1))
      let c : C = FromJson::from_json!(c, path.add_index(2))
      (a, b, c)
    }
    _ => decode_error!(path, "expected tuple of size 3")
  }
}

///|
pub impl[A : FromJson, B : FromJson, C : FromJson, D : FromJson] FromJson for (
  A,
  B,
  C,
  D,
) with from_json!(json, path) {
  match json {
    [a, b, c, d] => {
      let a : A = FromJson::from_json!(a, path.add_index(0))
      let b : B = FromJson::from_json!(b, path.add_index(1))
      let c : C = FromJson::from_json!(c, path.add_index(2))
      let d : D = FromJson::from_json!(d, path.add_index(3))
      (a, b, c, d)
    }
    _ => decode_error!(path, "expected tuple of size 4")
  }
}

///|
pub impl[A : FromJson, B : FromJson, C : FromJson, D : FromJson, E : FromJson] FromJson for (
  A,
  B,
  C,
  D,
  E,
) with from_json!(json, path) {
  match json {
    [a, b, c, d, e] => {
      let a : A = FromJson::from_json!(a, path.add_index(0))
      let b : B = FromJson::from_json!(b, path.add_index(1))
      let c : C = FromJson::from_json!(c, path.add_index(2))
      let d : D = FromJson::from_json!(d, path.add_index(3))
      let e : E = FromJson::from_json!(e, path.add_index(4))
      (a, b, c, d, e)
    }
    _ => decode_error!(path, "expected tuple of size 5")
  }
}

///|
pub impl[A : FromJson, B : FromJson, C : FromJson, D : FromJson, E : FromJson, F : FromJson] FromJson for (
  A,
  B,
  C,
  D,
  E,
  F,
) with from_json!(json, path) {
  match json {
    [a, b, c, d, e, f] => {
      let a : A = FromJson::from_json!(a, path.add_index(0))
      let b : B = FromJson::from_json!(b, path.add_index(1))
      let c : C = FromJson::from_json!(c, path.add_index(2))
      let d : D = FromJson::from_json!(d, path.add_index(3))
      let e : E = FromJson::from_json!(e, path.add_index(4))
      let f : F = FromJson::from_json!(f, path.add_index(5))
      (a, b, c, d, e, f)
    }
    _ => decode_error!(path, "expected tuple of size 6")
  }
}

///|
pub impl[A : FromJson, B : FromJson, C : FromJson, D : FromJson, E : FromJson, F : FromJson, G : FromJson] FromJson for (
  A,
  B,
  C,
  D,
  E,
  F,
  G,
) with from_json!(json, path) {
  match json {
    [a, b, c, d, e, f, g] => {
      let a : A = FromJson::from_json!(a, path.add_index(0))
      let b : B = FromJson::from_json!(b, path.add_index(1))
      let c : C = FromJson::from_json!(c, path.add_index(2))
      let d : D = FromJson::from_json!(d, path.add_index(3))
      let e : E = FromJson::from_json!(e, path.add_index(4))
      let f : F = FromJson::from_json!(f, path.add_index(5))
      let g : G = FromJson::from_json!(g, path.add_index(6))
      (a, b, c, d, e, f, g)
    }
    _ => decode_error!(path, "expected tuple of size 7")
  }
}

///|
pub impl[T0 : FromJson, T1 : FromJson, T2 : FromJson, T3 : FromJson, T4 : FromJson, T5 : FromJson, T6 : FromJson, T7 : FromJson] FromJson for (
  T0,
  T1,
  T2,
  T3,
  T4,
  T5,
  T6,
  T7,
) with from_json!(json, path) {
  match json {
    [x0, x1, x2, x3, x4, x5, x6, x7] => {
      let x0 : T0 = FromJson::from_json!(x0, path.add_index(0))
      let x1 : T1 = FromJson::from_json!(x1, path.add_index(1))
      let x2 : T2 = FromJson::from_json!(x2, path.add_index(2))
      let x3 : T3 = FromJson::from_json!(x3, path.add_index(3))
      let x4 : T4 = FromJson::from_json!(x4, path.add_index(4))
      let x5 : T5 = FromJson::from_json!(x5, path.add_index(5))
      let x6 : T6 = FromJson::from_json!(x6, path.add_index(6))
      let x7 : T7 = FromJson::from_json!(x7, path.add_index(7))
      (x0, x1, x2, x3, x4, x5, x6, x7)
    }
    _ => decode_error!(path, "expected tuple of size 8")
  }
}

///|
pub impl[T0 : FromJson, T1 : FromJson, T2 : FromJson, T3 : FromJson, T4 : FromJson, T5 : FromJson, T6 : FromJson, T7 : FromJson, T8 : FromJson] FromJson for (
  T0,
  T1,
  T2,
  T3,
  T4,
  T5,
  T6,
  T7,
  T8,
) with from_json!(json, path) {
  match json {
    [x0, x1, x2, x3, x4, x5, x6, x7, x8] => {
      let x0 : T0 = FromJson::from_json!(x0, path.add_index(0))
      let x1 : T1 = FromJson::from_json!(x1, path.add_index(1))
      let x2 : T2 = FromJson::from_json!(x2, path.add_index(2))
      let x3 : T3 = FromJson::from_json!(x3, path.add_index(3))
      let x4 : T4 = FromJson::from_json!(x4, path.add_index(4))
      let x5 : T5 = FromJson::from_json!(x5, path.add_index(5))
      let x6 : T6 = FromJson::from_json!(x6, path.add_index(6))
      let x7 : T7 = FromJson::from_json!(x7, path.add_index(7))
      let x8 : T8 = FromJson::from_json!(x8, path.add_index(8))
      (x0, x1, x2, x3, x4, x5, x6, x7, x8)
    }
    _ => decode_error!(path, "expected tuple of size 9")
  }
}

///|
pub impl[T0 : FromJson, T1 : FromJson, T2 : FromJson, T3 : FromJson, T4 : FromJson, T5 : FromJson, T6 : FromJson, T7 : FromJson, T8 : FromJson, T9 : FromJson] FromJson for (
  T0,
  T1,
  T2,
  T3,
  T4,
  T5,
  T6,
  T7,
  T8,
  T9,
) with from_json!(json, path) {
  match json {
    [x0, x1, x2, x3, x4, x5, x6, x7, x8, x9] => {
      let x0 : T0 = FromJson::from_json!(x0, path.add_index(0))
      let x1 : T1 = FromJson::from_json!(x1, path.add_index(1))
      let x2 : T2 = FromJson::from_json!(x2, path.add_index(2))
      let x3 : T3 = FromJson::from_json!(x3, path.add_index(3))
      let x4 : T4 = FromJson::from_json!(x4, path.add_index(4))
      let x5 : T5 = FromJson::from_json!(x5, path.add_index(5))
      let x6 : T6 = FromJson::from_json!(x6, path.add_index(6))
      let x7 : T7 = FromJson::from_json!(x7, path.add_index(7))
      let x8 : T8 = FromJson::from_json!(x8, path.add_index(8))
      let x9 : T9 = FromJson::from_json!(x9, path.add_index(9))
      (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9)
    }
    _ => decode_error!(path, "expected tuple of size 10")
  }
}

///|
pub impl[T0 : FromJson, T1 : FromJson, T2 : FromJson, T3 : FromJson, T4 : FromJson, T5 : FromJson, T6 : FromJson, T7 : FromJson, T8 : FromJson, T9 : FromJson, T10 : FromJson] FromJson for (
  T0,
  T1,
  T2,
  T3,
  T4,
  T5,
  T6,
  T7,
  T8,
  T9,
  T10,
) with from_json!(json, path) {
  match json {
    [x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10] => {
      let x0 : T0 = FromJson::from_json!(x0, path.add_index(0))
      let x1 : T1 = FromJson::from_json!(x1, path.add_index(1))
      let x2 : T2 = FromJson::from_json!(x2, path.add_index(2))
      let x3 : T3 = FromJson::from_json!(x3, path.add_index(3))
      let x4 : T4 = FromJson::from_json!(x4, path.add_index(4))
      let x5 : T5 = FromJson::from_json!(x5, path.add_index(5))
      let x6 : T6 = FromJson::from_json!(x6, path.add_index(6))
      let x7 : T7 = FromJson::from_json!(x7, path.add_index(7))
      let x8 : T8 = FromJson::from_json!(x8, path.add_index(8))
      let x9 : T9 = FromJson::from_json!(x9, path.add_index(9))
      let x10 : T10 = FromJson::from_json!(x10, path.add_index(10))
      (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10)
    }
    _ => decode_error!(path, "expected tuple of size 11")
  }
}

///|
pub impl[T0 : FromJson, T1 : FromJson, T2 : FromJson, T3 : FromJson, T4 : FromJson, T5 : FromJson, T6 : FromJson, T7 : FromJson, T8 : FromJson, T9 : FromJson, T10 : FromJson, T11 : FromJson] FromJson for (
  T0,
  T1,
  T2,
  T3,
  T4,
  T5,
  T6,
  T7,
  T8,
  T9,
  T10,
  T11,
) with from_json!(json, path) {
  match json {
    [x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11] => {
      let x0 : T0 = FromJson::from_json!(x0, path.add_index(0))
      let x1 : T1 = FromJson::from_json!(x1, path.add_index(1))
      let x2 : T2 = FromJson::from_json!(x2, path.add_index(2))
      let x3 : T3 = FromJson::from_json!(x3, path.add_index(3))
      let x4 : T4 = FromJson::from_json!(x4, path.add_index(4))
      let x5 : T5 = FromJson::from_json!(x5, path.add_index(5))
      let x6 : T6 = FromJson::from_json!(x6, path.add_index(6))
      let x7 : T7 = FromJson::from_json!(x7, path.add_index(7))
      let x8 : T8 = FromJson::from_json!(x8, path.add_index(8))
      let x9 : T9 = FromJson::from_json!(x9, path.add_index(9))
      let x10 : T10 = FromJson::from_json!(x10, path.add_index(10))
      let x11 : T11 = FromJson::from_json!(x11, path.add_index(11))
      (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11)
    }
    _ => decode_error!(path, "expected tuple of size 12")
  }
}

///|
pub impl[T0 : FromJson, T1 : FromJson, T2 : FromJson, T3 : FromJson, T4 : FromJson, T5 : FromJson, T6 : FromJson, T7 : FromJson, T8 : FromJson, T9 : FromJson, T10 : FromJson, T11 : FromJson, T12 : FromJson] FromJson for (
  T0,
  T1,
  T2,
  T3,
  T4,
  T5,
  T6,
  T7,
  T8,
  T9,
  T10,
  T11,
  T12,
) with from_json!(json, path) {
  match json {
    [x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12] => {
      let x0 : T0 = FromJson::from_json!(x0, path.add_index(0))
      let x1 : T1 = FromJson::from_json!(x1, path.add_index(1))
      let x2 : T2 = FromJson::from_json!(x2, path.add_index(2))
      let x3 : T3 = FromJson::from_json!(x3, path.add_index(3))
      let x4 : T4 = FromJson::from_json!(x4, path.add_index(4))
      let x5 : T5 = FromJson::from_json!(x5, path.add_index(5))
      let x6 : T6 = FromJson::from_json!(x6, path.add_index(6))
      let x7 : T7 = FromJson::from_json!(x7, path.add_index(7))
      let x8 : T8 = FromJson::from_json!(x8, path.add_index(8))
      let x9 : T9 = FromJson::from_json!(x9, path.add_index(9))
      let x10 : T10 = FromJson::from_json!(x10, path.add_index(10))
      let x11 : T11 = FromJson::from_json!(x11, path.add_index(11))
      let x12 : T12 = FromJson::from_json!(x12, path.add_index(12))
      (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12)
    }
    _ => decode_error!(path, "expected tuple of size 13")
  }
}

///|
pub impl[T0 : FromJson, T1 : FromJson, T2 : FromJson, T3 : FromJson, T4 : FromJson, T5 : FromJson, T6 : FromJson, T7 : FromJson, T8 : FromJson, T9 : FromJson, T10 : FromJson, T11 : FromJson, T12 : FromJson, T13 : FromJson] FromJson for (
  T0,
  T1,
  T2,
  T3,
  T4,
  T5,
  T6,
  T7,
  T8,
  T9,
  T10,
  T11,
  T12,
  T13,
) with from_json!(json, path) {
  match json {
    [x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13] => {
      let x0 : T0 = FromJson::from_json!(x0, path.add_index(0))
      let x1 : T1 = FromJson::from_json!(x1, path.add_index(1))
      let x2 : T2 = FromJson::from_json!(x2, path.add_index(2))
      let x3 : T3 = FromJson::from_json!(x3, path.add_index(3))
      let x4 : T4 = FromJson::from_json!(x4, path.add_index(4))
      let x5 : T5 = FromJson::from_json!(x5, path.add_index(5))
      let x6 : T6 = FromJson::from_json!(x6, path.add_index(6))
      let x7 : T7 = FromJson::from_json!(x7, path.add_index(7))
      let x8 : T8 = FromJson::from_json!(x8, path.add_index(8))
      let x9 : T9 = FromJson::from_json!(x9, path.add_index(9))
      let x10 : T10 = FromJson::from_json!(x10, path.add_index(10))
      let x11 : T11 = FromJson::from_json!(x11, path.add_index(11))
      let x12 : T12 = FromJson::from_json!(x12, path.add_index(12))
      let x13 : T13 = FromJson::from_json!(x13, path.add_index(13))
      (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13)
    }
    _ => decode_error!(path, "expected tuple of size 14")
  }
}

///|
pub impl[T0 : FromJson, T1 : FromJson, T2 : FromJson, T3 : FromJson, T4 : FromJson, T5 : FromJson, T6 : FromJson, T7 : FromJson, T8 : FromJson, T9 : FromJson, T10 : FromJson, T11 : FromJson, T12 : FromJson, T13 : FromJson, T14 : FromJson] FromJson for (
  T0,
  T1,
  T2,
  T3,
  T4,
  T5,
  T6,
  T7,
  T8,
  T9,
  T10,
  T11,
  T12,
  T13,
  T14,
) with from_json!(json, path) {
  match json {
    [x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14] => {
      let x0 : T0 = FromJson::from_json!(x0, path.add_index(0))
      let x1 : T1 = FromJson::from_json!(x1, path.add_index(1))
      let x2 : T2 = FromJson::from_json!(x2, path.add_index(2))
      let x3 : T3 = FromJson::from_json!(x3, path.add_index(3))
      let x4 : T4 = FromJson::from_json!(x4, path.add_index(4))
      let x5 : T5 = FromJson::from_json!(x5, path.add_index(5))
      let x6 : T6 = FromJson::from_json!(x6, path.add_index(6))
      let x7 : T7 = FromJson::from_json!(x7, path.add_index(7))
      let x8 : T8 = FromJson::from_json!(x8, path.add_index(8))
      let x9 : T9 = FromJson::from_json!(x9, path.add_index(9))
      let x10 : T10 = FromJson::from_json!(x10, path.add_index(10))
      let x11 : T11 = FromJson::from_json!(x11, path.add_index(11))
      let x12 : T12 = FromJson::from_json!(x12, path.add_index(12))
      let x13 : T13 = FromJson::from_json!(x13, path.add_index(13))
      let x14 : T14 = FromJson::from_json!(x14, path.add_index(14))
      (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14)
    }
    _ => decode_error!(path, "expected tuple of size 15")
  }
}

///|
pub impl[T0 : FromJson, T1 : FromJson, T2 : FromJson, T3 : FromJson, T4 : FromJson, T5 : FromJson, T6 : FromJson, T7 : FromJson, T8 : FromJson, T9 : FromJson, T10 : FromJson, T11 : FromJson, T12 : FromJson, T13 : FromJson, T14 : FromJson, T15 : FromJson] FromJson for (
  T0,
  T1,
  T2,
  T3,
  T4,
  T5,
  T6,
  T7,
  T8,
  T9,
  T10,
  T11,
  T12,
  T13,
  T14,
  T15,
) with from_json!(json, path) {
  match json {
    [x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15] => {
      let x0 : T0 = FromJson::from_json!(x0, path.add_index(0))
      let x1 : T1 = FromJson::from_json!(x1, path.add_index(1))
      let x2 : T2 = FromJson::from_json!(x2, path.add_index(2))
      let x3 : T3 = FromJson::from_json!(x3, path.add_index(3))
      let x4 : T4 = FromJson::from_json!(x4, path.add_index(4))
      let x5 : T5 = FromJson::from_json!(x5, path.add_index(5))
      let x6 : T6 = FromJson::from_json!(x6, path.add_index(6))
      let x7 : T7 = FromJson::from_json!(x7, path.add_index(7))
      let x8 : T8 = FromJson::from_json!(x8, path.add_index(8))
      let x9 : T9 = FromJson::from_json!(x9, path.add_index(9))
      let x10 : T10 = FromJson::from_json!(x10, path.add_index(10))
      let x11 : T11 = FromJson::from_json!(x11, path.add_index(11))
      let x12 : T12 = FromJson::from_json!(x12, path.add_index(12))
      let x13 : T13 = FromJson::from_json!(x13, path.add_index(13))
      let x14 : T14 = FromJson::from_json!(x14, path.add_index(14))
      let x15 : T15 = FromJson::from_json!(x15, path.add_index(15))
      (x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15)
    }
    _ => decode_error!(path, "expected tuple of size 16")
  }
}
