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
