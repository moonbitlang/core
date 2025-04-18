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
/// Trait for types whose elements can test for equality
pub(open) trait Eq {
  op_equal(Self, Self) -> Bool
}

///|
/// Trait for types whose elements are ordered
///
/// The return value of [compare] is:
/// - zero, if the two arguments are equal
/// - negative, if the first argument is smaller
/// - positive, if the first argument is greater
pub(open) trait Compare: Eq {
  compare(Self, Self) -> Int
}

///|
/// Trait for types that can be hashed
pub(open) trait Hash {
  hash_combine(Self, Hasher) -> Unit
  hash(Self) -> Int = _
}

///|
impl Hash with hash(self) {
  Hasher::new()..combine(self).finalize()
}

///|
/// Trait for types with a default value
pub(open) trait Default {
  default() -> Self
}

///|
/// Trait for a logger, where debug logs can be written into
pub(open) trait Logger {
  write_string(Self, String) -> Unit
  write_substring(Self, String, Int, Int) -> Unit
  write_char(Self, Char) -> Unit = _
}

///|
impl Logger with write_char(self, value) {
  self.write_string([value])
}

///|
/// Trait for types that can be converted to `String`
pub(open) trait Show {
  // `output` is used for composition of aggregate structure.
  // `output` writes a string representation of `self` to a logger.
  // `output` should produce a valid MoonBit-syntax representation if possible.
  // For example, `Show::output` for `String` should be quoted
  output(Self, &Logger) -> Unit
  // `to_string` should be used by end users of `Show`,
  // for printing, interpolation, etc. only, and should not be used for composition.
  // By default `to_string` is implemented using `output` and a buffer,
  // but some types, such as `String`, may override `to_string`,
  // for different (unescaped) behavior when interpolated/printed directly
  to_string(Self) -> String = _
}

///|
// Default implementation for `Show::to_string`, uses a `Buffer`
impl Show with to_string(self) {
  let logger = StringBuilder::new()
  self.output(logger)
  logger.to_string()
}

///|
pub fn &Logger::write_object[Obj : Show](self : &Logger, obj : Obj) -> Unit {
  obj.output(self)
}

///|
pub fn &Logger::write_iter[T : Show](
  self : &Logger,
  iter : Iter[T],
  prefix~ : String = "[",
  suffix~ : String = "]",
  sep~ : String = ", ",
  trailing~ : Bool = false
) -> Unit {
  self.write_string(prefix)
  if trailing {
    for x in iter {
      self.write_object(x)
      self.write_string(sep)
    }
  } else {
    // trailing is false
    let mut first = true
    for x in iter {
      if first {
        first = false
      } else {
        self.write_string(sep)
      }
      self.write_object(x)
    }
  }
  self.write_string(suffix)
}
// TODO: Logger::write_double(self:Logger, val:Double) -> Unit

///|
pub fn repr[T : Show](t : T) -> String {
  let logger = StringBuilder::new()
  t.output(logger)
  logger.to_string()
}
