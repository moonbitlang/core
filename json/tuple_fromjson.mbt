// Copyright 2024 International Digital Economy Academy
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
