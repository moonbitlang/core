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
/// A `@string.Index` provides O(1) time and unicode-safe access to String.
type Index Int derive(Compare, Eq, Show)

///|
/// Returns an `Index` pointing to the start of a string (position 0).
///
/// # Examples
///
/// ```
/// let i = Index::zero()
/// let s = "hello"
/// inspect!(s.codepoint_at(i), content="'h'")
/// ```
pub fn Index::zero() -> Index {
  0
}

///|
/// Returns an `Index` pointing to the end of a string.
///
/// Note this position is not a valid index for `String::codepoint_at`.
///
/// # Examples
///
/// ```
/// let s = "hello"
/// let i = Index::end(s)
/// let i2 = shift_index(s, i, -1)
/// inspect!(s.codepoint_at(i2), content="'o'")
/// ```
pub fn Index::end(s : String) -> Index {
  s.charcode_length()
}

///|
/// Shifts an index forward or backward by a given number of Unicode code points.
///
/// This function safely handles surrogate pairs when moving the index, ensuring
/// proper navigation through Unicode characters like emojis.
///
/// # Arguments
///
/// * `str` - The string to shift the index within
/// * `index` - The starting index position
/// * `shift` - Number of code points to shift (positive for forward, negative for backward)
///
/// # Examples
///
/// ```
/// let s = "Hello🤣"
/// let i = Index::zero()
/// let i2 = shift_index(s, i, 5) // Move to emoji position
/// inspect!(s.codepoint_at(i2), content="'🤣'")
/// let i3 = shift_index(s, i2, -1) // Move back to 'o'
/// inspect!(s.codepoint_at(i3), content="'o'")
/// ```
///
/// # Panics
///
/// Panics if:
/// - The resulting index would be out of bounds
/// - The string contains invalid surrogate pairs
pub fn shift_index(str : String, index : Index, shift : Int) -> Index {
  let len = str.charcode_length()
  if shift >= 0 {
    for char_count = 0, cur_index = index._
        char_count < shift && cur_index < len
        char_count = char_count + 1, cur_index = cur_index + 1 {
      let c1 = str.unsafe_charcode_at(cur_index)
      if is_leading_surrogate(c1) {
        guard cur_index + 1 < len else { abort("invalid surrogate pair") }
        let c2 = str.unsafe_charcode_at(cur_index + 1)
        if is_trailing_surrogate(c2) {
          continue char_count + 1, cur_index + 2
        } else {
          abort("invalid surrogate pair")
        }
      }
    } else {
      guard char_count == shift && cur_index <= len else {
        abort("index out of bounds")
      }
      cur_index
    }
  } else {
    let shift = -shift
    for char_count = 0, cur_index = index._
        char_count < shift && cur_index > 0
        char_count = char_count + 1, cur_index = cur_index - 1 {
      let c1 = str.unsafe_charcode_at(cur_index - 1)
      if is_trailing_surrogate(c1) {
        guard cur_index - 1 > 0 else { abort("invalid surrogate pair") }
        let c2 = str.unsafe_charcode_at(cur_index - 2)
        if is_leading_surrogate(c2) {
          continue char_count + 1, cur_index - 2
        } else {
          abort("invalid surrogate pair")
        }
      }
    } else {
      guard char_count == shift && cur_index >= 0 else {
        abort("index out of bounds")
      }
      let c1 = str.unsafe_charcode_at(cur_index)
      if is_trailing_surrogate(c1) {
        guard cur_index > 0 else { abort("invalid surrogate pair") }
        let c2 = str.unsafe_charcode_at(cur_index - 1)
        guard is_leading_surrogate(c2) else { abort("invalid surrogate pair") }
        cur_index - 1
      } else {
        cur_index
      }
    }
  }
}

///|
/// Unsafe version of `shift_index`. This function does not check if the
/// index is out of bounds, and does not check if the surrogate pair is valid.
pub fn unsafe_shift_index(index : Index, shift : Int) -> Index {
  index._ + shift
}

///|
/// Returns the Unicode code point at the given index.
///
/// # Panics
///
/// Panics if the index is out of bounds or the surrogate pair is invalid.
///
/// # Examples
///
/// ```
/// let s = "Hello🤣"
/// let i = Index::zero()
/// inspect!(s.codepoint_at(i), content="'H'")
/// ```
pub fn codepoint_at(self : String, index : Index) -> Char {
  guard index._ >= 0 && index._ < self.length() else {
    abort("index out of bounds")
  }
  let c1 = self.unsafe_charcode_at(index._)
  if is_leading_surrogate(c1) {
    guard index._ + 1 < self.length() else { abort("invalid surrogate pair") }
    let c2 = self.unsafe_charcode_at(index._ + 1)
    if is_trailing_surrogate(c2) {
      return code_point_of_surrogate_pair(c1, c2)
    } else {
      abort("invalid surrogate pair")
    }
  }
  Char::from_int(c1)
}

///|
/// Unsafe version of `codepoint_at`. This function does not check if the
/// index is out of bounds, and does not check if the surrogate pair is valid.
pub fn unsafe_codepoint_at(self : String, index : Index) -> Char {
  let c1 = self.unsafe_charcode_at(index._)
  if is_leading_surrogate(c1) {
    let c2 = self.unsafe_charcode_at(index._ + 1)
    if is_trailing_surrogate(c2) {
      return code_point_of_surrogate_pair(c1, c2)
    } else {
      abort("invalid surrogate pair")
    }
  }
  Char::from_int(c1)
}

///|
/// Returns a view of the string from the start index to the end index.
///
/// # Examples
///
/// ```
/// let s = "Hello🤣"
/// let i = Index::zero()
/// let v = s.as_view(start=i, end=Index::end(s))
/// inspect!(v, content="Hello🤣")
/// ```
///
/// # Panics
///
/// Panics if the start index is out of bounds or the end index is out of bounds.
pub fn as_view(self : String, start~ : Index = 0, end? : Index) -> View {
  guard 0 <= start._ else { abort("index out of bounds") }
  let end = match end {
    None => self.length()
    Some(e) => {
      guard start._ <= e._ && e._ <= self.length() else {
        abort("index out of bounds")
      }
      e._
    }
  }
  View::{ str: self, start: start._, end }
}
