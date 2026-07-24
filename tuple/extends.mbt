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

// Private aliases so tuple promotions can name the (unnameable) tuple types.

///|
type Tuple2[A, B] = (A, B)

///|
type Tuple3[A, B, C] = (A, B, C)

///|
type Tuple4[A, B, C, D] = (A, B, C, D)

///|
type Tuple5[A, B, C, D, E] = (A, B, C, D, E)

///|
type Tuple6[A, B, C, D, E, F] = (A, B, C, D, E, F)

///|
type Tuple7[A, B, C, D, E, F, G] = (A, B, C, D, E, F, G)

///|
type Tuple8[A, B, C, D, E, F, G, H] = (A, B, C, D, E, F, G, H)

///|
type Tuple9[A, B, C, D, E, F, G, H, I] = (A, B, C, D, E, F, G, H, I)

///|
type Tuple10[A, B, C, D, E, F, G, H, I, J] = (A, B, C, D, E, F, G, H, I, J)

///|
type Tuple11[A, B, C, D, E, F, G, H, I, J, K] = (
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
)

///|
type Tuple12[A, B, C, D, E, F, G, H, I, J, K, L] = (
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
)

///|
type Tuple13[A, B, C, D, E, F, G, H, I, J, K, L, M] = (
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
)

///|
type Tuple14[A, B, C, D, E, F, G, H, I, J, K, L, M, N] = (
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
)

///|
type Tuple15[A, B, C, D, E, F, G, H, I, J, K, L, M, N, O] = (
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
)

///|
type Tuple16[A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P] = (
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
)

// --- deprecated: hidden from the generated interface ---

// Tuples have no promoted trait methods; every promotion below is deprecated.

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple10 with Default::{default}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple11 with Default::{default}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple12 with Default::{default}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple13 with Default::{default}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple14 with Default::{default}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple15 with Default::{default}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple16 with Default::{default}

///|
#deprecated("Use `@quickcheck.Arbitrary::arbitrary` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple2 with @quickcheck.Arbitrary::{arbitrary}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple2 with Default::{default}

///|
#deprecated("Use `@quickcheck.Arbitrary::arbitrary` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple3 with @quickcheck.Arbitrary::{arbitrary}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple3 with Default::{default}

///|
#deprecated("Use `@quickcheck.Arbitrary::arbitrary` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple4 with @quickcheck.Arbitrary::{arbitrary}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple4 with Default::{default}

///|
#deprecated("Use `@quickcheck.Arbitrary::arbitrary` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple5 with @quickcheck.Arbitrary::{arbitrary}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple5 with Default::{default}

///|
#deprecated("Use `@quickcheck.Arbitrary::arbitrary` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple6 with @quickcheck.Arbitrary::{arbitrary}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple6 with Default::{default}

///|
#deprecated("Use `@quickcheck.Arbitrary::arbitrary` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple7 with @quickcheck.Arbitrary::{arbitrary}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple7 with Default::{default}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple8 with Default::{default}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Tuple9 with Default::{default}
