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
using @quickcheck {trait Arbitrary}

///|
pub impl[A : Arbitrary, B : Arbitrary] Arbitrary for (A, B) with arbitrary(
  size,
  r0,
) {
  let r1 = r0.split()
  (Arbitrary::arbitrary(size, r0), Arbitrary::arbitrary(size, r1))
}

///|
pub impl[A : Arbitrary, B : Arbitrary, C : Arbitrary] Arbitrary for (A, B, C) with arbitrary(
  size,
  r0,
) {
  let r1 = r0.split()
  let (v1, v2) = Arbitrary::arbitrary(size, r1)
  (Arbitrary::arbitrary(size, r0), v1, v2)
}

///|
pub impl[A : Arbitrary, B : Arbitrary, C : Arbitrary, D : Arbitrary] Arbitrary for (
  A,
  B,
  C,
  D,
) with arbitrary(size, r0) {
  let r1 = r0.split()
  let (v1, v2, v3) = Arbitrary::arbitrary(size, r1)
  (Arbitrary::arbitrary(size, r0), v1, v2, v3)
}

///|
pub impl[
  A : Arbitrary,
  B : Arbitrary,
  C : Arbitrary,
  D : Arbitrary,
  E : Arbitrary,
] Arbitrary for (A, B, C, D, E) with arbitrary(size, r0) {
  let r1 = r0.split()
  let (v1, v2, v3, v4) = Arbitrary::arbitrary(size, r1)
  (Arbitrary::arbitrary(size, r0), v1, v2, v3, v4)
}

///|
pub impl[
  A : Arbitrary,
  B : Arbitrary,
  C : Arbitrary,
  D : Arbitrary,
  E : Arbitrary,
  F : Arbitrary,
] Arbitrary for (A, B, C, D, E, F) with arbitrary(size, r0) {
  let r1 = r0.split()
  let (v1, v2, v3, v4, v5) = Arbitrary::arbitrary(size, r1)
  (Arbitrary::arbitrary(size, r0), v1, v2, v3, v4, v5)
}

///|
pub impl[
  A : Arbitrary,
  B : Arbitrary,
  C : Arbitrary,
  D : Arbitrary,
  E : Arbitrary,
  F : Arbitrary,
  G : Arbitrary,
] Arbitrary for (A, B, C, D, E, F, G) with arbitrary(size, r0) {
  let r1 = r0.split()
  let (v1, v2, v3, v4, v5, v6) = Arbitrary::arbitrary(size, r1)
  (Arbitrary::arbitrary(size, r0), v1, v2, v3, v4, v5, v6)
}
