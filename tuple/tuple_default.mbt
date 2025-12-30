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
/// Default implementation for 2-element tuples.
/// Each element uses `Default::default()`.
///
/// # Example
/// ```mbt check
/// test {
///   let value : (Int, Bool) = Default::default()
///   inspect(value, content="(0, false)")
/// }
/// ```
pub impl[A : Default, B : Default] Default for (A, B) with default() {
  (Default::default(), Default::default())
}

///|
/// Default implementation for 3-element tuples.
/// Each element uses `Default::default()`.
///
/// # Example
/// ```mbt check
/// test {
///   let value : (Int, String, Bool) = Default::default()
///   inspect(value, content="(0, \"\", false)")
/// }
/// ```
pub impl[A : Default, B : Default, C : Default] Default for (A, B, C) with default() {
  (Default::default(), Default::default(), Default::default())
}

///|
/// Default implementation for 4-element tuples.
/// Each element uses `Default::default()`.
///
/// # Example
/// ```mbt check
/// test {
///   let value : (Int, Int, Int, Int) = Default::default()
///   inspect(value, content="(0, 0, 0, 0)")
/// }
/// ```
pub impl[A : Default, B : Default, C : Default, D : Default] Default for (
  A,
  B,
  C,
  D,
) with default() {
  (
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
  )
}

///|
/// Default implementation for 5-element tuples.
/// Each element uses `Default::default()`.
///
/// # Example
/// ```mbt check
/// test {
///   let value : (Int, Int, Int, Int, Int) = Default::default()
///   inspect(value, content="(0, 0, 0, 0, 0)")
/// }
/// ```
pub impl[A : Default, B : Default, C : Default, D : Default, E : Default] Default for (
  A,
  B,
  C,
  D,
  E,
) with default() {
  (
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
  )
}

///|
/// Default implementation for 6-element tuples.
/// Each element uses `Default::default()`.
///
/// # Example
/// ```mbt check
/// test {
///   let value : (Int, Int, Int, Int, Int, Int) = Default::default()
///   inspect(value, content="(0, 0, 0, 0, 0, 0)")
/// }
/// ```
pub impl[
  A : Default,
  B : Default,
  C : Default,
  D : Default,
  E : Default,
  F : Default,
] Default for (A, B, C, D, E, F) with default() {
  (
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
  )
}

///|
/// Default implementation for 7-element tuples.
/// Each element uses `Default::default()`.
///
/// # Example
/// ```mbt check
/// test {
///   let value : (Int, Int, Int, Int, Int, Int, Int) = Default::default()
///   inspect(value, content="(0, 0, 0, 0, 0, 0, 0)")
/// }
/// ```
pub impl[
  A : Default,
  B : Default,
  C : Default,
  D : Default,
  E : Default,
  F : Default,
  G : Default,
] Default for (A, B, C, D, E, F, G) with default() {
  (
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
  )
}

///|
/// Default implementation for 8-element tuples.
/// Each element uses `Default::default()`.
///
/// # Example
/// ```mbt check
/// test {
///   let value : (Int, Int, Int, Int, Int, Int, Int, Int) = Default::default()
///   inspect(value, content="(0, 0, 0, 0, 0, 0, 0, 0)")
/// }
/// ```
pub impl[
  A : Default,
  B : Default,
  C : Default,
  D : Default,
  E : Default,
  F : Default,
  G : Default,
  H : Default,
] Default for (A, B, C, D, E, F, G, H) with default() {
  (
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
  )
}

///|
/// Default implementation for 9-element tuples.
/// Each element uses `Default::default()`.
///
/// # Example
/// ```mbt check
/// test {
///   let value : (Int, Int, Int, Int, Int, Int, Int, Int, Int) = Default::default()
///   inspect(value, content="(0, 0, 0, 0, 0, 0, 0, 0, 0)")
/// }
/// ```
pub impl[
  A : Default,
  B : Default,
  C : Default,
  D : Default,
  E : Default,
  F : Default,
  G : Default,
  H : Default,
  I : Default,
] Default for (A, B, C, D, E, F, G, H, I) with default() {
  (
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
  )
}

///|
/// Default implementation for 10-element tuples.
/// Each element uses `Default::default()`.
///
/// # Example
/// ```mbt check
/// test {
///   let value : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = Default::default()
///   inspect(value, content="(0, 0, 0, 0, 0, 0, 0, 0, 0, 0)")
/// }
/// ```
pub impl[
  A : Default,
  B : Default,
  C : Default,
  D : Default,
  E : Default,
  F : Default,
  G : Default,
  H : Default,
  I : Default,
  J : Default,
] Default for (A, B, C, D, E, F, G, H, I, J) with default() {
  (
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
  )
}

///|
/// Default implementation for 11-element tuples.
/// Each element uses `Default::default()`.
///
/// # Example
/// ```mbt check
/// test {
///   let value : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = Default::default()
///   inspect(value, content="(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)")
/// }
/// ```
pub impl[
  A : Default,
  B : Default,
  C : Default,
  D : Default,
  E : Default,
  F : Default,
  G : Default,
  H : Default,
  I : Default,
  J : Default,
  K : Default,
] Default for (A, B, C, D, E, F, G, H, I, J, K) with default() {
  (
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
  )
}

///|
/// Default implementation for 12-element tuples.
/// Each element uses `Default::default()`.
///
/// # Example
/// ```mbt check
/// test {
///   let value : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = Default::default()
///   inspect(value, content="(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)")
/// }
/// ```
pub impl[
  A : Default,
  B : Default,
  C : Default,
  D : Default,
  E : Default,
  F : Default,
  G : Default,
  H : Default,
  I : Default,
  J : Default,
  K : Default,
  L : Default,
] Default for (A, B, C, D, E, F, G, H, I, J, K, L) with default() {
  (
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
  )
}

///|
/// Default implementation for 13-element tuples.
/// Each element uses `Default::default()`.
///
/// # Example
/// ```mbt check
/// test {
///   let value : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = Default::default()
///   inspect(value, content="(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)")
/// }
/// ```
pub impl[
  A : Default,
  B : Default,
  C : Default,
  D : Default,
  E : Default,
  F : Default,
  G : Default,
  H : Default,
  I : Default,
  J : Default,
  K : Default,
  L : Default,
  M : Default,
] Default for (A, B, C, D, E, F, G, H, I, J, K, L, M) with default() {
  (
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
  )
}

///|
/// Default implementation for 14-element tuples.
/// Each element uses `Default::default()`.
///
/// # Example
/// ```mbt check
/// test {
///   let value : (
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///   ) = Default::default()
///   inspect(value, content="(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)")
/// }
/// ```
pub impl[
  A : Default,
  B : Default,
  C : Default,
  D : Default,
  E : Default,
  F : Default,
  G : Default,
  H : Default,
  I : Default,
  J : Default,
  K : Default,
  L : Default,
  M : Default,
  N : Default,
] Default for (A, B, C, D, E, F, G, H, I, J, K, L, M, N) with default() {
  (
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
  )
}

///|
/// Default implementation for 15-element tuples.
/// Each element uses `Default::default()`.
///
/// # Example
/// ```mbt check
/// test {
///   let value : (
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///   ) = Default::default()
///   inspect(value, content="(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)")
/// }
/// ```
pub impl[
  A : Default,
  B : Default,
  C : Default,
  D : Default,
  E : Default,
  F : Default,
  G : Default,
  H : Default,
  I : Default,
  J : Default,
  K : Default,
  L : Default,
  M : Default,
  N : Default,
  O : Default,
] Default for (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O) with default() {
  (
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
  )
}

///|
/// Default implementation for 16-element tuples.
/// Each element uses `Default::default()`.
///
/// # Example
/// ```mbt check
/// test {
///   let value : (
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///     Int,
///   ) = Default::default()
///   inspect(value, content="(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)")
/// }
/// ```
pub impl[
  A : Default,
  B : Default,
  C : Default,
  D : Default,
  E : Default,
  F : Default,
  G : Default,
  H : Default,
  I : Default,
  J : Default,
  K : Default,
  L : Default,
  M : Default,
  N : Default,
  O : Default,
  P : Default,
] Default for (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P) with default() {
  (
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
    Default::default(),
  )
}
