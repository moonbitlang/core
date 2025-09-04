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
/// Convert char array to string.
///
/// ```mbt
///   let s = @string.from_array(['H', 'e', 'l', 'l', 'o'])
///   assert_eq(s, "Hello")
/// ```
///
/// Do not convert large datas to `Array[Char]` and build a string with `String::from_array`.
///
/// For efficiency considerations, it's recommended to use `Buffer` instead.
#as_free_fn
pub fn String::from_array(chars : Array[Char]) -> String {
  let buf = StringBuilder::new(size_hint=chars.length() * 4)
  for c in chars {
    buf.write_char(c)
  }
  buf.to_string()
}

///|
/// Convert char iterator to string,
/// a simple wrapper for `from_array`.
#as_free_fn
pub fn String::from_iter(iter : Iter[Char]) -> String {
  let chars = iter.collect()
  String::from_array(chars)
}

///|
/// Strings are ordered based on shortlex order by their charcodes (code units). This 
/// orders Unicode characters based on their positions in the code charts. This is
/// not necessarily the same as "alphabetical" order, which varies by language
/// and locale.
pub impl Compare for String with compare(self, other) {
  let len = self.length()
  match len.compare(other.length()) {
    0 => {
      for i in 0..<len {
        let order = self
          .unsafe_charcode_at(i)
          .compare(other.unsafe_charcode_at(i))
        if order != 0 {
          return order
        }
      }
      0
    }
    order => order
  }
}

///|
/// The empty string
pub impl Default for String with default() {
  ""
}

///|
/// same as `String::default`
pub fn default() -> String {
  ""
}

///|
/// `String` holds a sequence of UTF-16 code units encoded in little endian format
pub fn to_bytes(self : String) -> Bytes {
  let array = FixedArray::make(self.length() * 2, Byte::default())
  array.blit_from_string(0, self, 0, self.length())
  array |> unsafe_to_bytes
}

///|
fn unsafe_to_bytes(array : FixedArray[Byte]) -> Bytes = "%identity"

///|
/// Converts the String into an array of Chars.
pub fn to_array(self : String) -> Array[Char] {
  self
  .iter()
  .fold(init=Array::new(capacity=self.length()), (rv, c) => {
    rv.push(c)
    rv
  })
}

///|
/// Returns an iterator over the Unicode characters in the string.
///
/// Note: This iterator yields Unicode characters, not Utf16 code units.
/// As a result, the count of characters returned by `iter().count()` may not be equal to the length of the string returned by `length()`.
///
/// ```mbt
///   let s = "Hello, World!🤣";
///   assert_eq(s.iter().count(), 14); // Unicode characters
///   assert_eq(s.length(), 15); // Utf16 code units
/// ```
pub fn iter(self : String) -> Iter[Char] {
  Iter::new(yield_ => {
    let len = self.length()
    for index in 0..<len {
      let c1 = self.unsafe_charcode_at(index)
      if c1.is_leading_surrogate() && index + 1 < len {
        let c2 = self.unsafe_charcode_at(index + 1)
        if c2.is_trailing_surrogate() {
          let c = code_point_of_surrogate_pair(c1, c2)
          guard yield_(c) is IterContinue else { break IterEnd }
          continue index + 2
        }
      }
      //TODO: handle garbage input
      guard yield_(c1.unsafe_to_char()) is IterContinue else { break IterEnd }
    } else {
      IterContinue
    }
  })
}

///|
pub fn iter2(self : String) -> Iter2[Int, Char] {
  Iter2::new(yield_ => {
    let len = self.length()
    for index = 0, n = 0; index < len; index = index + 1, n = n + 1 {
      let c1 = self.unsafe_charcode_at(index)
      if c1.is_leading_surrogate() && index + 1 < len {
        let c2 = self.unsafe_charcode_at(index + 1)
        if c2.is_trailing_surrogate() {
          let c = code_point_of_surrogate_pair(c1, c2)
          guard yield_(n, c) is IterContinue else { break IterEnd }
          continue index + 2, n + 1
        }
      }
      //TODO: handle garbage input
      guard yield_(n, c1.unsafe_to_char()) is IterContinue else {
        break IterEnd
      }
    } else {
      IterContinue
    }
  })
}

///|
/// Returns an iterator that yields characters from the end to the start of the string. This function handles
/// Unicode surrogate pairs correctly, ensuring that characters are not split across surrogate pairs.
///
/// # Parameters
///
/// - `self` : The input `String` to be iterated in reverse.
///
/// # Returns
///
/// - An `Iter[Char]` that yields characters from the end to the start of the string.
///
/// # Behavior
///
/// - The function iterates over the string in reverse order.
/// - If a trailing surrogate is encountered, it checks for a preceding leading surrogate to form a complete Unicode code point.
/// - Yields each character or combined code point to the iterator.
/// - Stops iteration if the `yield_` function returns `IterEnd`.
///
/// # Examples
///
/// ```mbt
///   let input = "Hello, World!"
///   let reversed = input.rev_iter().collect()
///   assert_eq(reversed, ['!', 'd', 'l', 'r', 'o', 'W', ' ', ',', 'o', 'l', 'l', 'e', 'H'])
/// ```
pub fn rev_iter(self : String) -> Iter[Char] {
  Iter::new(yield_ => {
    let len = self.length()
    for index = len - 1; index >= 0; index = index - 1 {
      let c1 = self.unsafe_charcode_at(index)
      if c1.is_trailing_surrogate() && index - 1 >= 0 {
        let c2 = self.unsafe_charcode_at(index - 1)
        if c2.is_leading_surrogate() {
          let c = code_point_of_surrogate_pair(c2, c1)
          guard yield_(c) is IterContinue else { break IterEnd }
          continue index - 2
        }
      }
      // TODO: handle garbage input
      guard yield_(c1.unsafe_to_char()) is IterContinue else { break IterEnd }
    } else {
      IterContinue
    }
  })
}

///|
/// Returns the index of the n-th (zero-indexed) character within the range [start, end).
fn String::offset_of_nth_char_forward(
  self : String,
  n : Int,
  start_offset~ : Int,
  end_offset~ : Int,
) -> Int? {
  guard start_offset >= 0 && start_offset <= end_offset else {
    abort("Invalid start index")
  }
  let mut utf16_offset = start_offset
  let mut char_count = 0
  while utf16_offset < end_offset && char_count < n {
    let c = self.unsafe_charcode_at(utf16_offset)
    // check if this is a surrogate pair
    if c.is_leading_surrogate() {
      utf16_offset = utf16_offset + 2
    } else {
      utf16_offset = utf16_offset + 1
    }
    char_count = char_count + 1
  }
  // Return None if either:
  // 1. We couldn't reach the requested character offset
  // 2. The resulting offset is beyond the end of the string
  // This handles the empty string case correctly.
  if char_count < n || utf16_offset >= end_offset {
    None
  } else {
    Some(utf16_offset)
  }
}

///|
/// Returns the index of the n-th (zero-indexed) character within the range [start, end).
/// self[end] is counted as the 0-th character (though it might not exist if end = self.length()).
fn String::offset_of_nth_char_backward(
  self : String,
  n : Int,
  start_offset~ : Int,
  end_offset~ : Int,
) -> Int? {
  let mut char_count = 0
  let mut utf16_offset = end_offset
  // Iterating backwards from the end of the string. 
  // Invariant: utf16_offset always points to the previous character
  while utf16_offset - 1 >= start_offset && char_count < n {
    let c = self.unsafe_charcode_at(utf16_offset - 1)
    if c.is_trailing_surrogate() {
      utf16_offset = utf16_offset - 2
    } else {
      utf16_offset = utf16_offset - 1
    }
    char_count = char_count + 1
  }
  if char_count < n || utf16_offset < start_offset {
    None
  } else {
    Some(utf16_offset)
  }
}

///|
/// Returns the UTF-16 index of the i-th (zero-indexed) Unicode character 
/// within the range [start, end). If i is negative, it returns the index of 
/// the (n + i)-th character where n is the number of Unicode characters 
/// in the range [start, end).
/// 
/// This functions assumes that the string is valid UTF-16.
pub fn String::offset_of_nth_char(
  self : String,
  i : Int,
  start_offset? : Int = 0,
  end_offset? : Int,
) -> Int? {
  let end_offset = if end_offset is Some(o) { o } else { self.length() }
  if i >= 0 {
    // forward case
    self.offset_of_nth_char_forward(i, start_offset~, end_offset~)
  } else {
    // backward case
    self.offset_of_nth_char_backward(-i, start_offset~, end_offset~)
  }
}

///|
/// Test if the length of the string is equal to the given length.
///
/// This has O(n) complexity where n is the length in the parameter.
pub fn String::char_length_eq(
  self : String,
  len : Int,
  start_offset? : Int = 0,
  end_offset? : Int,
) -> Bool {
  let end_offset = if end_offset is Some(o) { o } else { self.length() }
  for index = start_offset, count = 0
      index < end_offset && count < len
      index = index + 1, count = count + 1 {
    let c1 = self.unsafe_charcode_at(index)
    if c1.is_leading_surrogate() && index + 1 < end_offset {
      let c2 = self.unsafe_charcode_at(index + 1)
      if c2.is_trailing_surrogate() {
        continue index + 2, count + 1
      } else {
        abort("invalid surrogate pair")
      }
    }
  } else {
    count == len && index == end_offset
  }
}

///|
/// Test if the length of the string is greater than or equal to the given length.
///
/// This has O(n) complexity where n is the length in the parameter.
pub fn String::char_length_ge(
  self : String,
  len : Int,
  start_offset? : Int = 0,
  end_offset? : Int,
) -> Bool {
  let end_offset = if end_offset is Some(o) { o } else { self.length() }
  for index = start_offset, count = 0
      index < end_offset && count < len
      index = index + 1, count = count + 1 {
    let c1 = self.unsafe_charcode_at(index)
    if c1.is_leading_surrogate() && index + 1 < end_offset {
      let c2 = self.unsafe_charcode_at(index + 1)
      if c2.is_trailing_surrogate() {
        continue index + 2, count + 1
      } else {
        abort("invalid surrogate pair")
      }
    }
  } else {
    count >= len
  }
}
