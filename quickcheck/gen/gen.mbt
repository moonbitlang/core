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
struct Gen[T] {
  generate : (Int, RandomState) -> T
}

///|
/// Creates a generator from a function of size and random state.
pub fn[T] Gen::new(generate : (Int, RandomState) -> T) -> Gen[T] {
  { generate, }
}

///|
/// Runs a generator with an explicit size and random state.
pub fn[T] Gen::run(self : Gen[T], size : Int, state : RandomState) -> T {
  (self.generate)(size, state)
}

///|
/// Generates one deterministic sample.
pub fn[T] Gen::sample(
  self : Gen[T],
  size? : Int = 100,
  seed? : UInt64 = 37,
) -> T {
  self.run(size, @splitmix.new(seed~))
}

///|
/// Generates several deterministic samples from one random state.
pub fn[T] Gen::samples(
  self : Gen[T],
  count? : Int = 10,
  size? : Int = 100,
  seed? : UInt64 = 37,
) -> Array[T] {
  let state = @splitmix.new(seed~)
  Array::makei(count, _ => self.run(size, state))
}

///|
/// Creates a generator that always returns `value`.
pub fn[T] pure(value : T) -> Gen[T] {
  Gen::new((_, _) => value)
}

///|
/// Transforms the output of a generator.
pub fn[T, U] Gen::map(self : Gen[T], transform : (T) -> U) -> Gen[U] {
  Gen::new((size, state) => transform(self.run(size, state)))
}

///|
/// Sequences a generator with a generator-producing function.
pub fn[T, U] Gen::flat_map(self : Gen[T], transform : (T) -> Gen[U]) -> Gen[U] {
  Gen::new((size, state) => {
    let next_state = state.split()
    transform(self.run(size, state)).run(size, next_state)
  })
}

///|
/// Creates a generator that can inspect the current size.
pub fn[T] sized(create : (Int) -> Gen[T]) -> Gen[T] {
  Gen::new((size, state) => create(size).run(size, state))
}

///|
/// Runs a generator with a fixed size.
pub fn[T] Gen::resize(self : Gen[T], size : Int) -> Gen[T] {
  Gen::new((_, state) => self.run(size, state))
}

///|
/// Generates an integer in the half-open interval `[lower, upper)`.
pub fn int_range(lower : Int, upper : Int) -> Gen[Int] {
  guard lower < upper else {
    if lower == upper {
      return pure(lower)
    }
    abort("int_range: lower bound exceeds upper bound")
  }
  let width = (upper - lower).reinterpret_as_uint()
  Gen::new((_, state) => {
    (state.next_uint() % width).reinterpret_as_int() + lower
  })
}

///|
/// Randomly selects one of the supplied generators.
pub fn[T] one_of(generators : Array[Gen[T]]) -> Gen[T] {
  guard !generators.is_empty() else { abort("one_of: empty array") }
  int_range(0, generators.length()).flat_map(index => generators[index])
}

///|
/// Randomly selects a generator according to its weight.
pub fn[T] frequency(generators : Array[(UInt, Gen[T])]) -> Gen[T] {
  guard !generators.is_empty() else { abort("frequency: empty array") }
  let total = for pair in generators; total = 0U {
    let (weight, _) = pair
    continue total + weight
  } nobreak {
    total
  }
  guard total > 0 else { abort("frequency: total weight is zero") }
  Gen::new((size, state) => {
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
pub fn[T] Gen::array_with_size(self : Gen[T], size : Int) -> Gen[Array[T]] {
  guard size >= 0 else { abort("array_with_size: negative size") }
  Gen::new((sample_size, state) => {
    Array::makei(size, _ => self.run(sample_size, state))
  })
}
