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

///-----------------------------------------------------------------------------
pub impl[A : ToJson, B : ToJson] ToJson for (A, B) with to_json(self) {
  [self.0.to_json(), self.1.to_json()]
}

///-----------------------------------------------------------------------------
pub impl[A : ToJson, B : ToJson, C : ToJson] ToJson for (A, B, C) with to_json(
  self
) {
  [self.0.to_json(), self.1.to_json(), self.2.to_json()]
}

///-----------------------------------------------------------------------------
pub impl[A : ToJson, B : ToJson, C : ToJson, D : ToJson] ToJson for (A, B, C, D) with to_json(
  self
) {
  [self.0.to_json(), self.1.to_json(), self.2.to_json(), self.3.to_json()]
}

///-----------------------------------------------------------------------------
pub impl[A : ToJson, B : ToJson, C : ToJson, D : ToJson, E : ToJson] ToJson for (
  A,
  B,
  C,
  D,
  E,
) with to_json(self) {
  [
    self.0.to_json(),
    self.1.to_json(),
    self.2.to_json(),
    self.3.to_json(),
    self.4.to_json(),
  ]
}

///-----------------------------------------------------------------------------
pub impl[A : ToJson, B : ToJson, C : ToJson, D : ToJson, E : ToJson, F : ToJson] ToJson for (
  A,
  B,
  C,
  D,
  E,
  F,
) with to_json(self) {
  [
    self.0.to_json(),
    self.1.to_json(),
    self.2.to_json(),
    self.3.to_json(),
    self.4.to_json(),
    self.5.to_json(),
  ]
}

///-----------------------------------------------------------------------------
pub impl[A : ToJson, B : ToJson, C : ToJson, D : ToJson, E : ToJson, F : ToJson, G : ToJson] ToJson for (
  A,
  B,
  C,
  D,
  E,
  F,
  G,
) with to_json(self) {
  [
    self.0.to_json(),
    self.1.to_json(),
    self.2.to_json(),
    self.3.to_json(),
    self.4.to_json(),
    self.5.to_json(),
    self.6.to_json(),
  ]
}

///-----------------------------------------------------------------------------
pub impl[A : ToJson, B : ToJson, C : ToJson, D : ToJson, E : ToJson, F : ToJson, G : ToJson, H : ToJson] ToJson for (
  A,
  B,
  C,
  D,
  E,
  F,
  G,
  H,
) with to_json(self) {
  [
    self.0.to_json(),
    self.1.to_json(),
    self.2.to_json(),
    self.3.to_json(),
    self.4.to_json(),
    self.5.to_json(),
    self.6.to_json(),
    self.7.to_json(),
  ]
}

///-----------------------------------------------------------------------------
pub impl[A : ToJson, B : ToJson, C : ToJson, D : ToJson, E : ToJson, F : ToJson, G : ToJson, H : ToJson, I : ToJson] ToJson for (
  A,
  B,
  C,
  D,
  E,
  F,
  G,
  H,
  I,
) with to_json(self) {
  [
    self.0.to_json(),
    self.1.to_json(),
    self.2.to_json(),
    self.3.to_json(),
    self.4.to_json(),
    self.5.to_json(),
    self.6.to_json(),
    self.7.to_json(),
    self.8.to_json(),
  ]
}

///-----------------------------------------------------------------------------
pub impl[A : ToJson, B : ToJson, C : ToJson, D : ToJson, E : ToJson, F : ToJson, G : ToJson, H : ToJson, I : ToJson, J : ToJson] ToJson for (
  A,
  B,
  C,
  D,
  E,
  F,
  G,
  H,
  I,
  J,
) with to_json(self) {
  [
    self.0.to_json(),
    self.1.to_json(),
    self.2.to_json(),
    self.3.to_json(),
    self.4.to_json(),
    self.5.to_json(),
    self.6.to_json(),
    self.7.to_json(),
    self.8.to_json(),
    self.9.to_json(),
  ]
}

///-----------------------------------------------------------------------------
pub impl[A : ToJson, B : ToJson, C : ToJson, D : ToJson, E : ToJson, F : ToJson, G : ToJson, H : ToJson, I : ToJson, J : ToJson, K : ToJson] ToJson for (
  A,
  B,
  C,
  D,
  E,
  F,
  G,
  H,
  I,
  J,
  K,
) with to_json(self) {
  [
    self.0.to_json(),
    self.1.to_json(),
    self.2.to_json(),
    self.3.to_json(),
    self.4.to_json(),
    self.5.to_json(),
    self.6.to_json(),
    self.7.to_json(),
    self.8.to_json(),
    self.9.to_json(),
    self.10.to_json(),
  ]
}

///-----------------------------------------------------------------------------
pub impl[A : ToJson, B : ToJson, C : ToJson, D : ToJson, E : ToJson, F : ToJson, G : ToJson, H : ToJson, I : ToJson, J : ToJson, K : ToJson, L : ToJson] ToJson for (
  A,
  B,
  C,
  D,
  E,
  F,
  G,
  H,
  I,
  J,
  K,
  L,
) with to_json(self) {
  [
    self.0.to_json(),
    self.1.to_json(),
    self.2.to_json(),
    self.3.to_json(),
    self.4.to_json(),
    self.5.to_json(),
    self.6.to_json(),
    self.7.to_json(),
    self.8.to_json(),
    self.9.to_json(),
    self.10.to_json(),
    self.11.to_json(),
  ]
}

///-----------------------------------------------------------------------------
pub impl[A : ToJson, B : ToJson, C : ToJson, D : ToJson, E : ToJson, F : ToJson, G : ToJson, H : ToJson, I : ToJson, J : ToJson, K : ToJson, L : ToJson, M : ToJson] ToJson for (
  A,
  B,
  C,
  D,
  E,
  F,
  G,
  H,
  I,
  J,
  K,
  L,
  M,
) with to_json(self) {
  [
    self.0.to_json(),
    self.1.to_json(),
    self.2.to_json(),
    self.3.to_json(),
    self.4.to_json(),
    self.5.to_json(),
    self.6.to_json(),
    self.7.to_json(),
    self.8.to_json(),
    self.9.to_json(),
    self.10.to_json(),
    self.11.to_json(),
    self.12.to_json(),
  ]
}

///-----------------------------------------------------------------------------
pub impl[A : ToJson, B : ToJson, C : ToJson, D : ToJson, E : ToJson, F : ToJson, G : ToJson, H : ToJson, I : ToJson, J : ToJson, K : ToJson, L : ToJson, M : ToJson, N : ToJson] ToJson for (
  A,
  B,
  C,
  D,
  E,
  F,
  G,
  H,
  I,
  J,
  K,
  L,
  M,
  N,
) with to_json(self) {
  [
    self.0.to_json(),
    self.1.to_json(),
    self.2.to_json(),
    self.3.to_json(),
    self.4.to_json(),
    self.5.to_json(),
    self.6.to_json(),
    self.7.to_json(),
    self.8.to_json(),
    self.9.to_json(),
    self.10.to_json(),
    self.11.to_json(),
    self.12.to_json(),
    self.13.to_json(),
  ]
}

///-----------------------------------------------------------------------------
pub impl[A : ToJson, B : ToJson, C : ToJson, D : ToJson, E : ToJson, F : ToJson, G : ToJson, H : ToJson, I : ToJson, J : ToJson, K : ToJson, L : ToJson, M : ToJson, N : ToJson, O : ToJson] ToJson for (
  A,
  B,
  C,
  D,
  E,
  F,
  G,
  H,
  I,
  J,
  K,
  L,
  M,
  N,
  O,
) with to_json(self) {
  [
    self.0.to_json(),
    self.1.to_json(),
    self.2.to_json(),
    self.3.to_json(),
    self.4.to_json(),
    self.5.to_json(),
    self.6.to_json(),
    self.7.to_json(),
    self.8.to_json(),
    self.9.to_json(),
    self.10.to_json(),
    self.11.to_json(),
    self.12.to_json(),
    self.13.to_json(),
    self.14.to_json(),
  ]
}

///-----------------------------------------------------------------------------
pub impl[A : ToJson, B : ToJson, C : ToJson, D : ToJson, E : ToJson, F : ToJson, G : ToJson, H : ToJson, I : ToJson, J : ToJson, K : ToJson, L : ToJson, M : ToJson, N : ToJson, O : ToJson, P : ToJson] ToJson for (
  A,
  B,
  C,
  D,
  E,
  F,
  G,
  H,
  I,
  J,
  K,
  L,
  M,
  N,
  O,
  P,
) with to_json(self) {
  [
    self.0.to_json(),
    self.1.to_json(),
    self.2.to_json(),
    self.3.to_json(),
    self.4.to_json(),
    self.5.to_json(),
    self.6.to_json(),
    self.7.to_json(),
    self.8.to_json(),
    self.9.to_json(),
    self.10.to_json(),
    self.11.to_json(),
    self.12.to_json(),
    self.13.to_json(),
    self.14.to_json(),
    self.15.to_json(),
  ]
}
