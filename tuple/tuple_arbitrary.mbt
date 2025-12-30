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
using @quickcheck {trait Arbitrary}

///|
/// Arbitrary implementation for 2-element tuples.
/// Uses the provided size and random state to generate both elements.
///
/// # Example
/// ```mbt check
/// test {
///   let values : Array[(Int, String)] = @quickcheck.samples(5)
///   inspect(
///     values,
///     content=(
///       #|[(0, ""), (0, ""), (0, ""), (-2, "=l"), (2, "m")]
///     ),
///   )
/// }
/// ```
pub impl[A : Arbitrary, B : Arbitrary] Arbitrary for (A, B) with arbitrary(
  size,
  r0,
) {
  let r1 = r0.split()
  (Arbitrary::arbitrary(size, r0), Arbitrary::arbitrary(size, r1))
}

///|
/// Arbitrary implementation for 3-element tuples.
/// Uses the provided size and random state to generate the tuple elements.
///
/// # Example
/// ```mbt check
/// test {
///   let values : Array[(Int, String, UInt)] = @quickcheck.samples(5)
///   inspect(
///     values,
///     content=(
///       #|[(0, "", 0), (0, "", 0), (0, "", 1), (-2, "@>", 0), (2, "\u{1a}", 0)]
///     ),
///   )
/// }
/// ```
pub impl[A : Arbitrary, B : Arbitrary, C : Arbitrary] Arbitrary for (A, B, C) with arbitrary(
  size,
  r0,
) {
  let r1 = r0.split()
  let (v1, v2) = Arbitrary::arbitrary(size, r1)
  (Arbitrary::arbitrary(size, r0), v1, v2)
}

///|
/// Arbitrary implementation for 4-element tuples.
/// Uses the provided size and random state to generate the tuple elements.
///
/// # Example
/// ```mbt check
/// test {
///   let values : Array[(Int, String, UInt, Byte)] = @quickcheck.samples(5)
///   inspect(
///     values,
///     content=(
///       #|[(0, "", 0, b'\x2A'), (0, "", 0, b'\x77'), (0, "", 1, b'\x0D'), (-2, "@>", 1, b'\x4A'), (2, "\u{1a}", 0, b'\xE5')]
///     ),
///   )
/// }
/// ```
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
/// Arbitrary implementation for 5-element tuples.
/// Uses the provided size and random state to generate the tuple elements.
///
/// # Example
/// ```mbt check
/// test {
///   let values : Array[(Int, String, UInt, Byte, Char)] = @quickcheck.samples(5)
///   inspect(
///     values,
///     content=(
///       #|[(0, "", 0, b'\x89', '%'), (0, "", 0, b'\x3B', '\u{16}'), (0, "", 1, b'\x08', 'l'), (-2, "@>", 1, b'\x23', 't'), (2, "\u{1a}", 0, b'\xB7', 'q')]
///     ),
///   )
/// }
/// ```
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
/// Arbitrary implementation for 6-element tuples.
/// Uses the provided size and random state to generate the tuple elements.
///
/// # Example
/// ```mbt check
/// test {
///   let values : Array[(Int, String, UInt, Byte, Char, Bool)] = @quickcheck.samples(
///     5,
///   )
///   inspect(
///     values,
///     content=(
///       #|[(0, "", 0, b'\x89', '3', true), (0, "", 0, b'\x3B', 'x', true), (0, "", 1, b'\x08', 'P', true), (-2, "@>", 1, b'\x23', 'd', false), (2, "\u{1a}", 0, b'\xB7', '\u{1d}', true)]
///     ),
///   )
/// }
/// ```
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
/// Arbitrary implementation for 7-element tuples.
/// Uses the provided size and random state to generate the tuple elements.
///
/// # Example
/// ```mbt check
/// test {
///   let values : Array[(Int, String, UInt, Byte, Char, Bool, Unit)] = @quickcheck.samples(
///     5,
///   )
///   inspect(
///     values,
///     content=(
///       #|[(0, "", 0, b'\x89', '3', false, ()), (0, "", 0, b'\x3B', 'x', true, ()), (0, "", 1, b'\x08', 'P', true, ()), (-2, "@>", 1, b'\x23', 'd', true, ()), (2, "\u{1a}", 0, b'\xB7', '\u{1d}', true, ())]
///     ),
///   )
/// }
/// ```
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
