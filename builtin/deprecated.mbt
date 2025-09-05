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
/// Creates an iterator that iterates over a range of Int with default step 1.
///
/// # Arguments
///
/// * `start` - The starting value of the range (inclusive).
/// * `end` - The ending value of the range (exclusive).
/// * `inclusive` - Whether the ending value is inclusive (default false).
///
/// # Returns
///
/// Returns an iterator that iterates over the range of Int from `start` to `end - 1`.
#deprecated("Use `..<` in for loop or `until` method instead")
#coverage.skip
pub fn Int::upto(self : Int, end : Int, inclusive? : Bool = false) -> Iter[Int] {
  yield_ => {
    let mut i = self
    while i < end || (inclusive && i == end) {
      if yield_(i) is IterEnd {
        break IterEnd
      }
      if i == end {
        break IterContinue
      }
      i += 1
    } else {
      IterContinue
    }
  }
}

///|
/// Creates an iterator that iterates over a range of UInt with default step 1U.
///
/// # Arguments
///
/// * `start` - The starting value of the range (inclusive).
/// * `end` - The ending value of the range (exclusive).
/// * `inclusive` - Whether the ending value is inclusive (default false).
///
/// # Returns
///
/// Returns an iterator that iterates over the range of UInt from `start` to `end - 1`.
#deprecated("Use `..<` in for loop or `until` method instead")
#coverage.skip
pub fn UInt::upto(
  self : UInt,
  end : UInt,
  inclusive? : Bool = false,
) -> Iter[UInt] {
  yield_ => {
    let mut i = self
    while i < end || (inclusive && i == end) {
      if yield_(i) is IterEnd {
        break IterEnd
      }
      if i == end {
        break IterContinue
      }
      i += 1
    } else {
      IterContinue
    }
  }
}

///|
/// Creates an iterator that iterates over a range of UInt64 with default step 1UL.
///
/// # Arguments
///
/// * `start` - The starting value of the range (inclusive).
/// * `end` - The ending value of the range (exclusive).
/// * `inclusive` - Whether the ending value is inclusive (default false).
///
/// # Returns
///
/// Returns an iterator that iterates over the range of UInt64 from `start` to `end - 1`.
#deprecated("Use `..<` in for loop or `until` method instead")
#coverage.skip
pub fn UInt64::upto(
  self : UInt64,
  end : UInt64,
  inclusive? : Bool = false,
) -> Iter[UInt64] {
  yield_ => {
    let mut i = self
    while i < end || (inclusive && i == end) {
      if yield_(i) is IterEnd {
        break IterEnd
      }
      if i == end {
        break IterContinue
      }
      i += 1
    } else {
      IterContinue
    }
  }
}

///|
/// Creates an iterator that iterates over a range of Int64 with default step 1L.
///
/// # Arguments
///
/// * `start` - The starting value of the range (inclusive).
/// * `end` - The ending value of the range (exclusive).
/// * `inclusive` - Whether the ending value is inclusive (default false).
///
/// # Returns
///
/// Returns an iterator that iterates over the range of Int64 from `start` to `end - 1`.
#deprecated("Use `..<` in for loop or `until` method instead")
#coverage.skip
pub fn Int64::upto(
  self : Int64,
  end : Int64,
  inclusive? : Bool = false,
) -> Iter[Int64] {
  yield_ => {
    let mut i = self
    while i < end || (inclusive && i == end) {
      if yield_(i) is IterEnd {
        break IterEnd
      }
      if i == end {
        break IterContinue
      }
      i += 1
    } else {
      IterContinue
    }
  }
}

///|
/// Creates an iterator that iterates over a range of Float with default step 1.0 .
///
/// # Arguments
///
/// * `start` - The starting value of the range (inclusive).
/// * `end` - The ending value of the range (exclusive).
/// * `inclusive` - Whether the ending value is inclusive (default false).
///
/// # Returns
///
/// Returns an iterator that iterates over the range of Float from `start` to `end - 1`.
#deprecated("Use `..<` in for loop or `until` method instead")
#coverage.skip
pub fn Float::upto(
  self : Float,
  end : Float,
  inclusive? : Bool = false,
) -> Iter[Float] {
  yield_ => {
    let mut i = self
    while i < end || (inclusive && i == end) {
      if yield_(i) is IterEnd {
        break IterEnd
      }
      if i == end {
        break IterContinue
      }
      i += 1
    } else {
      IterContinue
    }
  }
}

///|
/// Creates an iterator that iterates over a range of Double with default step 1.0 .
///
/// # Arguments
///
/// * `start` - The starting value of the range (inclusive).
/// * `end` - The ending value of the range (exclusive).
/// * `inclusive` - Whether the ending value is inclusive (default false).
///
/// # Returns
///
/// Returns an iterator that iterates over the range of Double from `start` to `end - 1`.
#deprecated("Use `..<` in for loop or `until` method instead")
#coverage.skip
pub fn Double::upto(
  self : Double,
  end : Double,
  inclusive? : Bool = false,
) -> Iter[Double] {
  yield_ => {
    let mut i = self
    while i < end || (inclusive && i == end) {
      if yield_(i) is IterEnd {
        break IterEnd
      }
      if i == end {
        break IterContinue
      }
      i += 1
    } else {
      IterContinue
    }
  }
}

///|
/// Search the index of the first element that satisfies the predicate.
///

///|
/// Creates a byte sequence from a UTF-16 encoded string. Each character in the
/// string is encoded as a pair of bytes in little-endian order.
///
/// Parameters:
///
/// * `string` : The input string to be converted to a byte sequence.
///
/// Returns a new byte sequence containing the UTF-16LE encoded representation of
/// the input string.
///
/// Example:
///
/// ```moonbit
///   let bytes = "ABC".to_bytes()
///   inspect(bytes, content="b\"\\x41\\x00\\x42\\x00\\x43\\x00\"")
/// ```
#deprecated("Use `str.to_bytes()` instead")
pub fn Bytes::of_string(str : String) -> Bytes {
  FixedArray::make(str.length() * 2, Byte::default())
  ..blit_from_string(0, str, 0, str.length())
  .unsafe_reinterpret_as_bytes()
}

///|
#deprecated("Bytes are immutable. Use `FixedArray::blit_from_bytes` if it's really necessary.")
pub fn Bytes::copy(self : Bytes) -> Bytes {
  Bytes::makei(self.length(), i => self[i])
}

///|
/// positions.
///
/// Parameters:
///
/// - `byte_value` : The `Byte` value whose bits are to be shifted.
/// - `shift_count` : The number of bit positions to shift the `byte_value` to
///   the left.
///
/// Returns the resulting `Byte` value after the bitwise left shift operation.
///
#deprecated("Use infix operator `<<` instead")
#coverage.skip
pub fn Byte::lsl(self : Byte, count : Int) -> Byte {
  (self.to_int() << count).to_byte()
}

///|
/// bits.
///
/// Parameters:
///
/// - `value` : The `Byte` value to be shifted.
/// - `count` : The number of bits to shift the `value` to the right.
///
/// Returns the result of the logical shift right operation as a `Byte`.
///
#deprecated("Use infix operator `>>` instead")
#coverage.skip
pub fn Byte::lsr(self : Byte, count : Int) -> Byte {
  (self.to_uint() >> count).reinterpret_as_int().to_byte()
}

///|
/// Prints and returns the value of a given expression for quick and dirty debugging.
#callsite(autofill(loc))
#deprecated("This function is for debugging only and should not be used in production")
pub fn[T] dump(t : T, name? : String, loc~ : SourceLoc) -> T {
  let name = match name {
    Some(name) => name
    None => ""
  }
  println("dump(\{name}@\{loc}) = \{any_to_string(t)}")
  t
}

///|
/// Returns the Unicode code point at the given index.
///
/// This method counts Unicode code points (characters) rather than UTF-16 code units.
/// It properly handles surrogate pairs to return the correct Unicode character.
///
/// # Examples
///
/// ```mbt
/// let s = "Hello🤣"
/// inspect(s.get_char(0).unwrap(), content="H")
/// inspect(s.get_char(5).unwrap(), content="🤣")
/// ```
///
/// # Panics
///
/// Panics if:
/// - The index is out of bounds
/// - The string contains an invalid surrogate pair
#deprecated("The index will be changed to utf16 index. If you want to access n-th character, use `str.iter().nth(n).unwrap()` instead.")
pub fn String::codepoint_at(self : String, index : Int) -> Char {
  let charcode_len = self.length()
  guard index >= 0 && index < charcode_len else { abort("index out of bounds") }
  for char_count = 0, utf16_offset = 0
      char_count < charcode_len && utf16_offset < index
      char_count = char_count + 1, utf16_offset = utf16_offset + 1 {
    let c1 = self.unsafe_charcode_at(char_count)
    if c1.is_leading_surrogate() && char_count + 1 < charcode_len {
      let c2 = self.unsafe_charcode_at(char_count + 1)
      if c2.is_trailing_surrogate() {
        continue char_count + 2, utf16_offset + 1
      } else {
        abort("invalid surrogate pair")
      }
    }
  } else {
    guard utf16_offset == index && char_count < charcode_len else {
      abort("index out of bounds")
    }
    let c1 = self.unsafe_charcode_at(char_count)
    if c1.is_leading_surrogate() && char_count + 1 < charcode_len {
      let c2 = self.unsafe_charcode_at(char_count + 1)
      if c2.is_trailing_surrogate() {
        code_point_of_surrogate_pair(c1, c2)
      } else {
        abort("invalid surrogate pair")
      }
    } else {
      c1.unsafe_to_char()
    }
  }
}

///|
/// Returns the Unicode code point at the given index without bounds checking.
#deprecated("Use `s.get_char(i).unwrap()` instead")
pub fn String::unsafe_char_at(self : String, index : Int) -> Char {
  let c1 = self.unsafe_charcode_at(index)
  if c1.is_leading_surrogate() {
    let c2 = self.unsafe_charcode_at(index + 1)
    code_point_of_surrogate_pair(c1, c2)
  } else {
    c1.unsafe_to_char()
  }
}
