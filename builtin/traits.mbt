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

/// Trait for types whose elements can test for equality
pub trait Eq {
  op_equal(Self, Self) -> Bool
}

/// Trait for types whose elements are ordered
///
/// The return value of [compare] is:
/// - zero, if the two arguments are equal
/// - negative, if the first argument is smaller
/// - positive, if the first argument is greater
pub trait Compare: Eq {
  compare(Self, Self) -> Int
}

/// Trait for types that can be hashed
pub trait Hash {
  hash_combine(Self, Hasher) -> Unit
  hash(Self) -> Int
}

/// Trait for types with a default value
pub trait Default {
  default() -> Self
}

/// Trait for a logger, where debug logs can be written into
pub trait Logger {
  write_string(Self, String) -> Unit
  write_sub_string(Self, String, Int, Int) -> Unit
  write_char(Self, Char) -> Unit
}

/// Trait for types that can be converted to `String`
pub trait Show {
  // `output` is used for composition of aggregate structure.
  // `output` writes a string representation of `self` to a logger.
  // `output` should produce a valid MoonBit-syntax representation if possible.
  // For example, `Show::output` for `String` should be quoted
  output(Self, Logger) -> Unit
  // `to_string` should be used by end users of `Show`,
  // for printing, interpolation, etc. only, and should not be used for composition.
  // By default `to_string` is implemented using `output` and a buffer,
  // but some types, such as `String`, may override `to_string`,
  // for different (unescaped) behavior when interpolated/printed directly
  //
  // By default, `to_string` cannot be called via dot directly.
  // If implementors of `Show` wants to allow `.to_string()` usage,
  // they should create a method wrapper manually:
  //
  //    fn to_string(self : T) -> String { Show::to_string(self) }
  to_string(Self) -> String
}

// Default implementation for `Show::to_string`, uses a `Buffer`
impl Show with to_string(self) {
  let logger = Buffer::new()
  self.output(logger)
  logger.to_string()
}
