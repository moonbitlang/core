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
  fn equal(Self, Self) -> Bool
  fn not_equal(Self, Self) -> Bool = _
}

///|
impl Eq with fn not_equal(x, y) {
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
  fn compare(Self, Self) -> Int
  fn op_lt(Self, Self) -> Bool = _
  fn op_gt(Self, Self) -> Bool = _
  fn op_le(Self, Self) -> Bool = _
  fn op_ge(Self, Self) -> Bool = _
}

///|
impl Compare with fn op_lt(x, y) {
  x.compare(y).is_neg()
}

///|
impl Compare with fn op_gt(x, y) {
  x.compare(y).is_pos()
}

///|
impl Compare with fn op_le(x, y) {
  x.compare(y).is_non_pos()
}

///|
impl Compare with fn op_ge(x, y) {
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
  fn hash_combine(Self, Hasher) -> Unit
  fn hash(Self) -> Int = _
}

///|
impl Hash with fn hash(self) {
  let h = Hasher::new()
  h.combine(self)
  h.finalize()
}

///|
/// Trait for types with a default value
pub(open) trait Default {
  fn default() -> Self
}

///|
/// Trait for append-only text sinks used by `Show` implementations.
///
/// A logger receives formatted output without requiring callers to allocate a
/// complete `String` first.
pub(open) trait Logger {
  /// Writes a string to the logger.
  fn write_string(Self, String) -> Unit = _
  /// Writes a substring of the given string to the logger.
  #deprecated("use `write_view` instead", skip_current_package=true)
  fn write_substring(Self, String, Int, Int) -> Unit = _
  /// Writes a string view to the logger.
  fn write_view(Self, StringView) -> Unit = _
  /// Writes a character to the logger.
  fn write_char(Self, Char) -> Unit = _
  fn write(Self, &Show) -> Unit = _
}

///|
impl Logger with fn write(self, show) {
  show.output(self)
}

///|
/// Writes a substring of the given string to the logger.
impl Logger with fn write_substring(self, value, start, len) {
  self.write_view(value[start:start + len])
}

///|
/// Writes a string to the logger.
impl Logger with fn write_string(self, value) {
  self.write_view(value)
}

///|
/// Writes a string view to the logger.
#deprecated("replace `impl write_substring` with `impl write_view`")
impl Logger with fn write_view(self, value) {
  self.write_substring(value.data(), value.start_offset(), value.length())
}

///|
/// Writes a character to the logger.
impl Logger with fn write_char(self, value) {
  self.write_string([value])
}

///|
/// Trait for types that can be converted to `String`
#must_implement_one(output, to_string)
pub(open) trait Show {
  // `output` writes a string representation of `self` to a logger.
  // The behaviors of output and to_string should be the same.
  fn output(Self, &Logger) -> Unit = _
  // `to_string` should be used by end users of `Show`,
  // for printing, interpolation, etc. only, and should not be used for composition.
  fn to_string(Self) -> String = _
}

///|
/// Default implementation for `Show::output`, uses `Show::to_string`.
impl Show with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
/// Default implementation for `Show::to_string`, uses a `StringBuilder`
impl Show with fn to_string(self) {
  let logger = StringBuilder()
  self.output(logger)
  logger.to_string()
}

///|
/// Writes the `Show` representation of an object to the logger.
pub fn[Obj : Show] &Logger::write_object(self : &Logger, obj : Obj) -> Unit {
  obj.output(self)
}

///|
/// Writes an iterator of `Show` values to the logger.
///
/// By default, values are written in list form, such as `[1, 2]`. The
/// `prefix`, `suffix`, and `sep` arguments customize the surrounding text and
/// separator. If `trailing` is true, `sep` is also written after the last value.
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
  } else if iter.next() is Some(x) {
    self.write_object(x)
    for x in iter {
      self.write_string(sep)
      self.write_object(x)
    }
  }
  self.write_string(suffix)
}
// TODO: Logger::write_double(self:Logger, val:Double) -> Unit
