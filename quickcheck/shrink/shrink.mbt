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
/// Types that can enumerate "smaller" variants of a given value for
/// the classical QuickCheck shrinker. Each call to `shrink(x)` returns
/// an `Iter[Self]` of candidates strictly simpler than `x`; the driver
/// walks these candidates after a failure, keeping the first one that
/// still falsifies the property.
///
/// The return type is `Iter[Self]` rather than `Array[Self]` so large
/// or recursive shrink spaces stay lazy. The default body (`= _`)
/// means "no shrinks" — a conservative starting point for types where
/// shrinking isn't meaningful.
///
/// ```mbt check
/// test {
///   // `Int` has a built-in Shrink instance that walks toward 0.
///   let candidates : Array[Int] = Shrink::shrink(100).collect()
///   assert_true(candidates.contains(0))
///   assert_true(candidates.length() > 0)
///   // `Bool` shrinks `true` to `false`, and `false` has no shrinks.
///   @debug.assert_eq(Shrink::shrink(true).collect(), [false])
///   @debug.assert_eq(Shrink::shrink(false).collect(), [])
/// }
/// ```
pub(open) trait Shrink {
  fn shrink(Self) -> Iter[Self] = _
}

///|
impl Shrink with fn shrink(_a) {
  Iter::empty()
}

///|
pub impl Shrink for Int with fn shrink(x) {
  [|
    ..[ for z = x / 2; (x - z).abs() < x.abs(); z = z / 2 => x - z ].rev_iter(),
    ..if x != 0 {
      [0]
    },
  |]
}

///|
pub impl Shrink for Int64 with fn shrink(x) {
  [|
    ..[ for z = x / 2; (x - z).abs() < x.abs(); z = z / 2 => x - z ].rev_iter(),
    ..if x != 0 {
      [(0 : Int64)]
    },
  |]
}

///|
pub impl Shrink for UInt with fn shrink(x) {
  [|
    ..[ for z = x / 2; z > 0; z = z / 2 => x - z ].rev_iter(),
    ..if x != 0 {
      [(0 : UInt)]
    },
  |]
}

///|
pub impl Shrink for UInt64 with fn shrink(x) {
  [|
    ..[ for z = x / 2; z > 0; z = z / 2 => x - z ].rev_iter(),
    ..if x != 0 {
      [(0 : UInt64)]
    },
  |]
}

///|
pub impl Shrink for Bool with fn shrink(b) {
  if !b {
    Iter::empty()
  } else {
    Iter::singleton(false)
  }
}

///|
pub impl Shrink for Byte with fn shrink(x) {
  let xi = x.to_int()
  [|
    ..[ for z = xi / 2; z > 0; z = z / 2 => (xi - z).to_byte() ].rev_iter(),
    ..if xi != 0 {
      [Int::to_byte(0)]
    },
  |]
}

///|
pub impl Shrink for Char with fn shrink(c) {
  let ci = c.to_int()
  if ci == 0 {
    return Iter::empty()
  } else {
    let (cl, ch) = (Int::unsafe_to_char(ci - 1), Int::unsafe_to_char(ci + 1))
    [|cl, ch, 'a', 'A', '1', '\n', '\t', '\b', '\\', '\'', '\r', ' '|]
  }
}

///|
pub impl Shrink for Double with fn shrink(x) {
  shrink_decimal(x)
}

///|
pub impl Shrink for Float with fn shrink(x) {
  shrink_decimal(x.to_double()).map(Float::from_double)
}

///|
pub impl Shrink for String

///|
pub impl Shrink for Bytes

///|
pub impl Shrink for Unit
