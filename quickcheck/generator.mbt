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
pub using @splitmix {type RandomState}

///|
/// A size-aware random value generator.
struct Generator[T] {
  generate : (Int, RandomState) -> T
}

///|
/// Creates a generator from a function of size and random state.
pub fn[T] Generator::Generator(
  generate : (Int, RandomState) -> T,
) -> Generator[T] {
  { generate, }
}

///|
/// Creates a generator that draws values from the type's `Arbitrary`
/// instance, for mixing `Arbitrary`-based generation into hand-written
/// generators.
///
/// ```mbt check
/// test "spawn draws from Arbitrary" {
///   let strings : @quickcheck.Generator[String] = @quickcheck.spawn()
///   let lengths = strings.samples(count=3, size=4, seed=37).map(s => s.length())
///   debug_inspect(
///     lengths,
///     content=(
///       #|[3, 2, 1]
///     ),
///   )
/// }
/// ```
pub fn[T : Arbitrary] spawn() -> Generator[T] {
  Generator(Arbitrary::arbitrary)
}

///|
/// Runs a generator with an explicit size and random state.
pub fn[T] Generator::run(
  self : Generator[T],
  size : Int,
  state : RandomState,
) -> T {
  (self.generate)(size, state)
}

///|
/// Generates one deterministic sample.
pub fn[T] Generator::sample(
  self : Generator[T],
  size? : Int = 100,
  seed? : UInt64 = 37,
) -> T {
  self.run(size, @splitmix.new(seed~))
}

///|
/// Generates several deterministic samples from one random state.
pub fn[T] Generator::samples(
  self : Generator[T],
  count? : Int = 10,
  size? : Int = 100,
  seed? : UInt64 = 37,
) -> Array[T] {
  let state = @splitmix.new(seed~)
  Array::makei(count, _ => self.run(size, state))
}

///|
/// Creates a generator that always returns `value`.
pub fn[T] pure(value : T) -> Generator[T] {
  Generator((_, _) => value)
}

///|
/// Transforms the output of a generator.
pub fn[T, U] Generator::map(
  self : Generator[T],
  transform : (T) -> U,
) -> Generator[U] {
  Generator((size, state) => transform(self.run(size, state)))
}

///|
/// Sequences a generator with a generator-producing function.
pub fn[T, U] Generator::flat_map(
  self : Generator[T],
  transform : (T) -> Generator[U],
) -> Generator[U] {
  Generator((size, state) => {
    let next_state = state.split()
    transform(self.run(size, state)).run(size, next_state)
  })
}

///|
/// Combines two generators into one producing pairs.
pub fn[T, U] Generator::zip(
  self : Generator[T],
  other : Generator[U],
) -> Generator[(T, U)] {
  self.zip_with(other, (first, second) => (first, second))
}

///|
/// Combines the outputs of two generators with `combine`.
pub fn[T, U, V] Generator::zip_with(
  self : Generator[T],
  other : Generator[U],
  combine : (T, U) -> V,
) -> Generator[V] {
  Generator((size, state) => {
    let other_state = state.split()
    combine(self.run(size, state), other.run(size, other_state))
  })
}

///|
/// Combines the outputs of three generators with `combine`.
pub fn[T, U, V, W] Generator::zip_with3(
  self : Generator[T],
  second : Generator[U],
  third : Generator[V],
  combine : (T, U, V) -> W,
) -> Generator[W] {
  Generator((size, state) => {
    let second_state = state.split()
    let third_state = second_state.split()
    combine(
      self.run(size, state),
      second.run(size, second_state),
      third.run(size, third_state),
    )
  })
}

///|
/// Creates a generator that can inspect the current size.
pub fn[T] sized(create : (Int) -> Generator[T]) -> Generator[T] {
  Generator((size, state) => create(size).run(size, state))
}

///|
/// Transforms the size supplied to a generator.
pub fn[T] Generator::scale(
  self : Generator[T],
  transform : (Int) -> Int,
) -> Generator[T] {
  Generator((size, state) => self.run(transform(size), state))
}

///|
/// Runs a generator with a fixed size.
pub fn[T] Generator::resize(self : Generator[T], size : Int) -> Generator[T] {
  self.scale(_ => size)
}

///|
/// Generates an integer in the half-open interval `[lower, upper)`.
pub fn int_range(lower : Int, upper : Int) -> Generator[Int] {
  guard lower < upper else {
    if lower == upper {
      return pure(lower)
    }
    abort("int_range: lower bound exceeds upper bound")
  }
  let width = (upper - lower).reinterpret_as_uint()
  Generator((_, state) => {
    (state.next_uint() % width).reinterpret_as_int() + lower
  })
}

///|
/// Generates a character in the inclusive range `[lower, upper]`.
///
/// A range spanning the surrogate block skips it, so every generated code
/// point is a valid Unicode scalar value. The bounds themselves must be
/// valid scalar values (aborts on a surrogate or out-of-range bound, which
/// can only be produced with `unsafe_to_char`) and must form a non-empty
/// range.
pub fn char_range(lower : Char, upper : Char) -> Generator[Char] {
  let lo = lower.to_int()
  let hi = upper.to_int()
  fn is_surrogate(code : Int) -> Bool {
    code >= 0xD800 && code <= 0xDFFF
  }

  guard lo <= hi else { abort("char_range: lower bound exceeds upper bound") }
  guard lo >= 0 && hi <= 0x10FFFF && !is_surrogate(lo) && !is_surrogate(hi) else {
    abort("char_range: bounds must be Unicode scalar values")
  }
  // When the range spans the surrogate block, draw from a contiguous index
  // space of the valid scalars and shift past the block.
  let gap = if lo < 0xD800 && hi > 0xDFFF { 0x800 } else { 0 }
  int_range(lo, hi + 1 - gap).map(code => {
    let code = if code >= 0xD800 { code + gap } else { code }
    code.to_char().unwrap()
  })
}

///|
/// Randomly selects one of the supplied generators.
pub fn[T] one_of(generators : Array[Generator[T]]) -> Generator[T] {
  guard !generators.is_empty() else { abort("one_of: empty array") }
  int_range(0, generators.length()).flat_map(index => generators[index])
}

///|
/// Randomly selects one of the supplied values.
/// @alert unsafe "Panics if `values` is empty."
pub fn[T] elements(values : Array[T]) -> Generator[T] {
  guard !values.is_empty() else { abort("elements: empty array") }
  int_range(0, values.length()).map(index => values[index])
}

///|
/// Randomly selects a generator according to its weight.
pub fn[T] frequency(generators : Array[(UInt, Generator[T])]) -> Generator[T] {
  guard !generators.is_empty() else { abort("frequency: empty array") }
  let total = for pair in generators; total = 0U {
    let (weight, _) = pair
    continue total + weight
  } nobreak {
    total
  }
  guard total > 0 else { abort("frequency: total weight is zero") }
  Generator((size, state) => {
    let choice = state.next_uint() % total
    for pair in generators; remaining = choice {
      let (weight, generator) = pair
      if remaining < weight {
        break generator.run(size, state)
      }
      continue remaining - weight
    } nobreak {
      abort("frequency: invalid weights")
    }
  })
}

///|
/// Generates an array with exactly `size` independently drawn elements.
pub fn[T] Generator::array_with_size(
  self : Generator[T],
  size : Int,
) -> Generator[Array[T]] {
  guard size >= 0 else { abort("array_with_size: negative size") }
  Generator((sample_size, state) => {
    Array::makei(size, _ => self.run(sample_size, state))
  })
}
