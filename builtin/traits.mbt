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
/// Trait for types whose elements can test for equality
pub(open) trait Eq {
  equal(Self, Self) -> Bool = _
  #deprecated("use `equal` instead", skip_current_package=true)
  op_equal(Self, Self) -> Bool = _
  not_equal(Self, Self) -> Bool = _
}

///|
impl Eq with not_equal(x, y) {
  !(x == y)
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
  op_lt(Self, Self) -> Bool = _
  op_gt(Self, Self) -> Bool = _
  op_le(Self, Self) -> Bool = _
  op_ge(Self, Self) -> Bool = _
}

///|
impl Compare with op_lt(x, y) {
  x.compare(y).is_neg()
}

///|
impl Compare with op_gt(x, y) {
  x.compare(y).is_pos()
}

///|
impl Compare with op_le(x, y) {
  x.compare(y).is_non_pos()
}

///|
impl Compare with op_ge(x, y) {
  x.compare(y).is_non_neg()
}

///|
/// Trait for types that can be hashed
/// 
/// The `hash` method should return a hash value for the type, which is used in hash tables and other data structures.
/// The `hash_combine` method is used to combine the hash of the current value with another hash value,
/// typically used to hash composite types.
/// 
/// When two values are equal according to the `Eq` trait, they should produce the same hash value.
/// 
/// The `hash` method does not need to be implemented if `hash_combine` is implemented,
/// When implemented separately, `hash` **does not need** to produce a hash value that is consistent with `hash_combine`.
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
  write_string(Self, String) -> Unit = _
  #deprecated("use `write_view` instead", skip_current_package=true)
  write_substring(Self, String, Int, Int) -> Unit = _
  write_view(Self, StringView) -> Unit = _
  write_char(Self, Char) -> Unit = _
}

///|
impl Logger with write_substring(self, value, start, len) {
  self.write_view(try! value[start:start + len])
}

///|
impl Logger with write_string(self, value) {
  self.write_view(value[:])
}

///|
#deprecated("replace `impl write_substring` with `impl write_view`")
impl Logger with write_view(self, value) {
  self.write_substring(value.data(), value.start_offset(), value.length())
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
/// Default implementation for `Show::to_string`, uses a `StringBuilder`
impl Show with to_string(self) {
  let logger = StringBuilder::new()
  self.output(logger)
  logger.to_string()
}

///|
pub fn[Obj : Show] &Logger::write_object(self : &Logger, obj : Obj) -> Unit {
  obj.output(self)
}

///|
pub fn[T : Show] &Logger::write_iter(
  self : &Logger,
  iter : Iter[T],
  prefix? : String = "[",
  suffix? : String = "]",
  sep? : String = ", ",
  trailing? : Bool = false,
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
pub fn[T : Show] repr(t : T) -> String {
  let logger = StringBuilder::new()
  t.output(logger)
  logger.to_string()
}

///|
#deprecated("replace `impl op_equal` with `impl equal`")
impl Eq with equal(self, other) {
  Eq::op_equal(self, other)
}

///|
impl Eq with op_equal(self, other) {
  Eq::equal(self, other)
}
