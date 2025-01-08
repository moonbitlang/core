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

///| 
/// A `CharsView` represents a slice of a String, storing UTF-16 character indices.
///
/// # Fields
///
/// - `str`: The source String being viewed
/// - `start`: Starting UTF-16 code unit index into the string
/// - `end`: Ending UTF-16 code unit index into the string (not included)
/// - `len`: Number of Unicode codepoints (characters) in this view
///
/// Note that `start` and `end` are UTF-16 code unit indices, while `len` 
/// counts actual Unicode codepoints which may span multiple UTF-16 code units.
struct CharsView {
  str : String
  start : Int
  end : Int
  len : Int
}

///|
/// A `CharOffset` represents an offset into a string based on UTF-16 code units.
///
/// This is an opaque type that represents positions within a string based on 
/// raw UTF-16 code unit offsets. This ensures that string slicing operations 
/// work with proper character boundaries and do not split surrogate pairs.
///
/// The offset counts the number of UTF-16 code units from the start of the 
/// string. This makes it safe to use for string indexing operations since it 
/// will always align with character boundaries.
///
/// This type is intentionally opaque - it can only be constructed through the 
/// `CharOffset::offset_by(str: String, char_offset: Int) -> CharOffset` method 
/// and cannot be manipulated directly as an integer.
type CharOffset Int derive(Show, Eq)

///|
/// Returns the UTF-16 code unit index of the character at the given offset.
/// Returns `None` if the offset is beyond the end of the string.
fn offset_by(str : String, char_offset : Int, start~ : Int = 0) -> Int? {
  let str_len = str.length()
  let mut utf16_offset = start
  let mut char_count = 0
  while utf16_offset < str_len && char_count < char_offset {
    let c1 = str[utf16_offset]
    // check if this is a surrogate pair
    if is_leading_surrogate(c1) && utf16_offset + 1 < str_len {
      let c2 = str[utf16_offset + 1]
      if is_trailing_surrogate(c2) {
        utf16_offset = utf16_offset + 2
        char_count = char_count + 1
        continue
      }
    }
    // single utf-16 code unit
    utf16_offset = utf16_offset + 1
    char_count = char_count + 1
  }
  // Return None if:
  // 1. We couldn't reach the requested character offset
  // 2. The resulting offset is beyond the end of the string
  if char_count < char_offset || utf16_offset >= str_len {
    None
  } else {
    Some(utf16_offset)
  }
}

///|
/// Returns a `CharOffset` representing the position after skipping `char_offset` characters.
///
/// This method counts Unicode characters (codepoints) from the start of the string and returns
/// a `CharOffset` representing that position. Returns `None` if the offset would go beyond the 
/// end of the string.
///
/// # Examples
/// 
/// ```
/// let str = "🤣🤣🤣"
/// let offset = CharOffset::offset_by(str, 1)          // Skip 1 character
/// inspect!(offset, content="Some(CharOffset(2))")     // Points to second emoji
/// 
/// let offset = CharOffset::offset_by(str, 2)          // Skip 2 characters  
/// inspect!(offset, content="Some(CharOffset(4))")     // Points to third emoji
///
/// let offset = CharOffset::offset_by(str, 3)          // Skip 3 characters
/// inspect!(offset, content="None")                    // Beyond end of string
/// ```
/// 
pub fn CharOffset::offset_by(str : String, char_offset : Int) -> CharOffset? {
  match offset_by(str, char_offset, start=0) {
    Some(utf16_offset) => Some(utf16_offset)
    None => None
  }
}

///|
/// Creates a `CharOffset` from an integer.
///
/// This is an unsafe operation that assumes the integer is a valid UTF-16 
/// code unit index. It does not perform any validation or bounds checking.
pub fn CharOffset::unsafe_from_int(i : Int) -> CharOffset {
  i
}

///|
pub fn length(self : CharsView) -> Int {
  self.len
}

///|
/// Creates a `CharsView` into a `String`.
/// 
/// # Example
/// 
/// ```
/// let str = "Hello🤣🤣🤣"
/// guard let Some(start) = CharOffset::offset_by(str, 1)
/// guard let Some(end) = CharOffset::offset_by(str, 6)
/// let view = str[start:end]
/// inspect!(view, content=
///  #|"ello🤣"
///)
/// ```
pub fn op_as_view(
  self : String,
  start~ : CharOffset = 0,
  end? : CharOffset
) -> CharsView {
  let str_len = self.length()
  let start = start._
  let end = match end {
    Some(e) => e._
    None => str_len
  }
  guard start >= 0 && start <= end && end <= str_len else {
    abort("Invalid index for CharsView")
  }
  let mut len = 0
  for index = start; index < end; index = index + 1 {
    let c1 = self[index]
    if is_leading_surrogate(c1) && index + 1 < end {
      let c2 = self[index + 1]
      if is_trailing_surrogate(c2) {
        len = len + 1
        continue index + 2
      } else {
        abort("invalid surrogate pair")
      }
    }
    len = len + 1
  }
  { str: self, start, end, len }
}

///|
/// Creates a new `CharsView` from an existing `CharsView`.
/// 
/// # Example
/// 
/// ```
/// let str = "Hello🤣🤣🤣"
/// guard let Some(start) = CharOffset::offset_by(str, 1)
/// guard let Some(end) = CharOffset::offset_by(str, 7)
/// let view = str[start:end]
/// let view2 = view[1:5]
/// inspect!(view2, content=
///   #|"llo🤣"
/// )
/// ```
pub fn op_as_view(self : CharsView, start~ : Int = 0, end? : Int) -> CharsView {
  let cv_len = self.len
  match end {
    Some(end) => {
      guard start >= 0 && start <= end && end <= cv_len else {
        abort("Invalid index for CharsView")
      }
      guard let Some(start) = offset_by(self.str, start, start=self.start)
      // TODO: provide offset_by_rev or offset_by2 to avoid repeatedly iterate the string
      guard let Some(end) = offset_by(self.str, end, start=self.start)
      { str: self.str, start, end, len: end - start }
    }
    None => {
      guard start >= 0 && start <= cv_len else {
        abort("Invalid index for CharsView")
      }
      guard let Some(start) = offset_by(self.str, start, start=self.start)
      { str: self.str, start, end: self.end, len: cv_len - start }
    }
  }
}

///|
/// Return the character at the given index.
/// 
/// This method has O(n) complexity.
/// 
/// # Example
/// 
/// ```
/// let str = "Hello🤣🤣🤣"
/// guard let Some(start) = CharOffset::offset_by(str, 1)
/// guard let Some(end) = CharOffset::offset_by(str, 6)
/// let view = str[start:end]
/// inspect!(view[0], content="'e'")
/// inspect!(view[4], content="'🤣'")
/// ```
pub fn op_get(self : CharsView, index : Int) -> Char {
  guard index >= 0 && index < self.len else {
    abort(
      "index out of bounds: the len is from 0 to \{self.len} but the index is \{index}",
    )
  }
  let mut utf16_offset = self.start
  let mut char_count = 0
  while char_count < index {
    let c1 = self.str[utf16_offset]
    if is_leading_surrogate(c1) && utf16_offset + 1 < self.str.length() {
      let c2 = self.str[utf16_offset + 1]
      if is_trailing_surrogate(c2) {
        utf16_offset = utf16_offset + 2
        char_count = char_count + 1
        continue
      }
    }
    utf16_offset = utf16_offset + 1
    char_count = char_count + 1
  }
  let c1 = self.str[utf16_offset]
  if is_leading_surrogate(c1) {
    let c2 = self.str[utf16_offset + 1]
    if is_trailing_surrogate(c2) {
      code_point_of_surrogate_pair(c1, c2)
    } else {
      abort("invalid surrogate pair")
    }
  } else {
    c1
  }
}

///|
pub impl Show for CharsView with output(self, logger) {
  let substr = self.str.substring(start=self.start, end=self.end)
  String::output(substr, logger)
}
