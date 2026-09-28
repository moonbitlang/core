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
/// Encode a UTF-16 string into raw bytes.
///
/// Deprecated: use `@encoding/utf8.encode` for text encoding.
///
/// Example:
///
/// ```mbt check
/// test {
///   let bytes = Bytes::from_array([b'A'])
///   inspect(bytes.length(), content="1")
/// }
/// ```
#deprecated("check `@encoding/utf8.encode`")
#coverage.skip
pub fn Bytes::of_string(str : String) -> Bytes {
  let arr = FixedArray::make(str.length() * 2, b'\x00')
  arr.blit_from_string(0, str, 0, str.length())
  arr.unsafe_reinterpret_as_bytes()
}

///|
/// Return a copied `Bytes` value.
///
/// Deprecated because `Bytes` is immutable and copying is usually unnecessary.
///
/// Example:
///
/// ```mbt check
/// test {
///   let a = b"abc"
///   let b = Bytes::makei(a.length(), i => a[i])
///   inspect(a == b, content="true")
/// }
/// ```
#deprecated("Bytes are immutable. Use `FixedArray::blit_from_bytes` if it's really necessary.")
#alias(clone, deprecated)
pub fn Bytes::copy(self : Bytes) -> Bytes {
  Bytes::makei(self.length(), i => self[i])
}

///|
/// Create a hash map.
/// The capacity of the map will be the smallest power of 2 that is
/// greater than or equal to the provided [capacity].
///
/// Deprecated: use `Map([], capacity=...)` instead.
#deprecated("Use `Map([], capacity=...)` instead")
pub fn[K, V] Map::new(capacity? : Int = default_init_capacity) -> Map[K, V] {
  new_map(capacity)
}

///|
/// Shifts the bits of a `Byte` value to the left by the given number of bit
/// positions.
///
/// Parameters:
///
/// - `self` : The `Byte` value whose bits are to be shifted.
/// - `count` : The number of bit positions to shift `self` to the left.
///
/// Returns the resulting `Byte` value after the bitwise left shift operation.
///
#deprecated("Use infix operator `<<` instead")
#coverage.skip
pub fn Byte::lsl(self : Byte, count : Int) -> Byte {
  (self.to_int() << count).to_byte()
}

///|
/// Performs a logical (zero-filling) right shift of a `Byte` value by the
/// given number of bits.
///
/// Parameters:
///
/// - `self` : The `Byte` value to be shifted.
/// - `count` : The number of bits to shift `self` to the right.
///
/// Returns the result of the logical shift right operation as a `Byte`.
///
#deprecated("Use infix operator `>>` instead")
#coverage.skip
pub fn Byte::lsr(self : Byte, count : Int) -> Byte {
  (self.to_uint() >> count).reinterpret_as_int().to_byte()
}

///|
/// Returns the Unicode code point at the given index without bounds checking.
#deprecated("Use `s.get_char(i).unwrap()` instead", skip_current_package=true)
pub fn String::unsafe_char_at(self : String, index : Int) -> Char {
  let c1 = self.unsafe_get(index)
  if c1.is_leading_surrogate() {
    let c2 = self.unsafe_get(index + 1)
    code_point_of_surrogate_pair(c1.to_int(), c2.to_int())
  } else {
    c1.unsafe_to_char()
  }
}

///|
/// Creates a new empty array with an optional initial capacity.
///
/// Deprecated: use `Array(capacity=...)` instead.
#deprecated("Use `Array(capacity=...)` instead")
pub fn[T] Array::new(capacity? : Int = 0) -> Array[T] {
  Array(capacity~)
}

///|
/// Creates an iterator that iterates over a range of Double with default step 1.0 .
/// To grow the range downward, set the `step` parameter to a negative value.
///
/// # Arguments
///
/// * `self` - The starting value of the range (inclusive).
/// * `end` - The ending value of the range (exclusive by default).
/// * `step` - The step size of the range (default 1.0).
/// * `inclusive` - Whether the ending value is inclusive (default false).
///
/// # Returns
///
/// Returns an iterator yielding `self`, `self + step`, `(self + step) + step`,
/// ..., stopping before `end` (or at `end` when `inclusive` is set). Returns
/// an empty iterator when `step` is `0.0`.
///
/// Deprecated: each element is the previous one plus `step`, so rounding
/// error accumulates (`0.0.until(1.0, step=0.1)` yields 11 elements, the last
/// `0.9999999999999999`). And once adding `step` no longer changes the
/// element, it is yielded forever: a `step` below the element's precision
/// (`1.0e16.until(1.0e16 + 100.0)`), an infinite start (`(-inf).until(0.0)`),
/// or an element that reached infinity with `inclusive` set and an infinite
/// `end`.
///
/// Use `@range.iter` (package `moonbitlang/core/range`) instead. It computes
/// element `k` as `start + k * step` and stops as soon as the next element
/// would not advance, so all of the cases above terminate. Its results differ
/// from this function's wherever rounding error has accumulated, wherever this
/// function would repeat an element, and for a zero `step`:
/// `@range.iter(from=x, to=x, step=0.0, inclusive=true)` yields `[x]`, while
/// this function yields nothing. For exact decimal end points, iterate over
/// integers and scale, e.g. `(0).until(10).map(k => k.to_double() / 10.0)`.
#deprecated("Use `@range.iter(from=start, to=end, step=..., inclusive=...)` instead; `Double::until` accumulates rounding error")
#coverage.skip
pub fn Double::until(
  self : Double,
  end : Double,
  step? : Double = 1.0,
  inclusive? : Bool = false,
) -> Iter[Double] {
  until_impl(self, end, step, inclusive)
}
