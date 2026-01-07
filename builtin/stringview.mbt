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
/// Returns the source string being viewed.
fn StringView::str(self : StringView) -> String = "%stringview.str"

///|
/// Returns the starting UTF-16 code unit index into the string.
fn StringView::start(self : StringView) -> Int = "%stringview.start"

///|
/// Returns the ending UTF-16 code unit index into the string (not included).
fn StringView::end(self : StringView) -> Int = "%stringview.end"

///|
fn StringView::make_view(str : String, start : Int, end : Int) -> StringView = "%stringview.make"

///|
/// Returns the UTF-16 code unit at the given index.
/// 
/// This method has O(1) complexity.
#alias("_[_]")
#alias(code_unit_at)
pub fn StringView::at(self : StringView, index : Int) -> UInt16 {
  guard index >= 0 && index < self.length() else {
    abort("Index out of bounds")
  }
  self.str().code_unit_at(self.start() + index)
}

///|
/// Returns the length of the view.
/// 
/// This method counts the charcodes(code unit) in the view and has O(1) complexity.
pub fn StringView::length(self : StringView) -> Int {
  self.end() - self.start()
}

///|
/// Iterates over all suffixes of the view, advancing by a Unicode character at
/// a time. Each yielded suffix is itself a view into the original string.
pub fn StringView::suffixes(
  self : StringView,
  include_empty? : Bool = false,
) -> Iter[StringView] {
  let str = self.str()
  let end = self.end()
  let mut next_start = self.start()
  let mut finished = false
  Iter::new(fn() -> StringView? {
    if finished {
      None
    } else if next_start == end {
      finished = true
      if include_empty {
        Some(StringView::make_view(str, next_start, end))
      } else {
        None
      }
    } else {
      let suffix = StringView::make_view(str, next_start, end)
      let code = str.unsafe_charcode_at(next_start)
      if code.is_leading_surrogate() &&
        next_start + 1 < end &&
        str.unsafe_charcode_at(next_start + 1).is_trailing_surrogate() {
        next_start += 2
      } else {
        next_start += 1
      }
      Some(suffix)
    }
  })
}

///|
/// Returns the original string that is being viewed.
pub fn StringView::data(self : StringView) -> String {
  self.str()
}

///|
/// Returns the starting offset (in UTF-16 code units) of this view into its
/// underlying string.
pub fn StringView::start_offset(self : StringView) -> Int {
  self.start()
}

///|
/// Returns a new view of the view with the given start and end offsets.
pub fn StringView::view(
  self : StringView,
  start_offset? : Int = 0,
  end_offset? : Int,
) -> StringView {
  let end_offset = if end_offset is Some(o) { o } else { self.length() }
  guard start_offset >= 0 &&
    start_offset <= end_offset &&
    end_offset <= self.length() else {
    abort("Invalid index for View")
  }
  StringView::make_view(
    self.str(),
    self.start() + start_offset,
    self.start() + end_offset,
  )
}

///|
/// Returns the charcode(code unit) at the given index without checking if the
/// index is within bounds.
/// 
/// This method has O(1) complexity.
/// #Example
/// 
/// ```mbt check
/// test {
///   let str = "B🤣🤣C"
///   let view = str[:]
///   inspect(view.unsafe_charcode_at(0), content="66")
///   inspect(view.unsafe_charcode_at(1), content="55358")
///   inspect(view.unsafe_charcode_at(2), content="56611")
///   inspect(view.unsafe_charcode_at(3), content="55358")
///   inspect(view.unsafe_charcode_at(4), content="56611")
///   inspect(view.unsafe_charcode_at(5), content="67")
/// }
/// ```
/// TODO: rename to `unsafe_get`
pub fn StringView::unsafe_charcode_at(self : StringView, index : Int) -> Int {
  self.str().unsafe_charcode_at(self.start() + index)
}

///|
/// Returns the number of Unicode characters in this view.
/// 
/// Note this has O(n) complexity where n is the length of the code points in 
/// the view.
pub fn StringView::char_length(self : StringView) -> Int {
  self.str().char_length(start_offset=self.start(), end_offset=self.end())
}

///|
pub impl Show for StringView with output(self, logger) {
  let substr = self.str().unsafe_substring(start=self.start(), end=self.end())
  String::output(substr, logger)
}

///|
/// Returns a new String containing a copy of the characters in this view.
/// 
/// # Examples
/// 
/// ```mbt check
/// test {
///   let str = "Hello World"
///   let view = str.view(
///     start_offset=str.offset_of_nth_char(0).unwrap(),
///     end_offset=str.offset_of_nth_char(5).unwrap(),
///   ) // "Hello"
///   inspect(view.to_string(), content="Hello")
/// }
/// ```
pub impl Show for StringView with to_string(self) {
  // when `self == self.str()`, `String::unsafe_substring` would return original string, which doesn't create a new copy.
  self.str().unsafe_substring(start=self.start(), end=self.end())
}

///|
/// Returns an iterator over the Unicode characters in the string view.
#alias(iterator, deprecated)
pub fn StringView::iter(self : StringView) -> Iter[Char] {
  let start = self.start()
  let end = self.end()
  let mut index = start
  Iter::new(fn() {
    guard index < end else { None }
    let c1 = self.str().unsafe_charcode_at(index)
    if c1.is_leading_surrogate() && index + 1 < self.end() {
      let c2 = self.str().unsafe_charcode_at(index + 1)
      if c2.is_trailing_surrogate() {
        index += 2
        return Some(code_point_of_surrogate_pair(c1, c2))
      }
    }
    index += 1
    Some(c1.unsafe_to_char())
  })
}

///|
#alias(iterator2, deprecated)
pub fn StringView::iter2(self : StringView) -> Iter2[Int, Char] {
  let start = self.start()
  let end = self.end()
  let mut index = start
  let mut char_index = 0
  Iter2::new(fn() {
    guard index < end else { None }
    let c1 = self.str().unsafe_charcode_at(index)
    if c1.is_leading_surrogate() && index + 1 < self.end() {
      let c2 = self.str().unsafe_charcode_at(index + 1)
      if c2.is_trailing_surrogate() {
        let result = (char_index, code_point_of_surrogate_pair(c1, c2))
        index += 2
        char_index += 1
        return Some(result)
      }
    }
    let result = (char_index, c1.unsafe_to_char())
    index += 1
    char_index += 1
    Some(result)
  })
}

///|
/// Returns an iterator over the Unicode characters in the string view in reverse order.
#alias(rev_iterator, deprecated)
pub fn StringView::rev_iter(self : StringView) -> Iter[Char] {
  let start = self.start()
  let end = self.end()
  let mut index = end
  Iter::new(fn() {
    guard index > start else { None }
    index -= 1
    let c1 = self.str().unsafe_charcode_at(index)
    if c1.is_trailing_surrogate() && index - 1 >= 0 {
      let c2 = self.str().unsafe_charcode_at(index - 1)
      if c2.is_leading_surrogate() {
        index -= 1
        return Some(code_point_of_surrogate_pair(c2, c1))
      }
    }
    Some(c1.unsafe_to_char())
  })
}

///|
/// Compares two views for equality. Returns true only if both views
/// have the same length and contain identical characters in the same order.
pub impl Eq for StringView with equal(self, other) {
  let len = self.length()
  guard len == other.length() else { return false }
  if physical_equal(self.str(), other.str()) && self.start() == other.start() {
    return true
  }
  for i in 0..<len {
    guard self.str().unsafe_charcode_at(self.start() + i) ==
      other.str().unsafe_charcode_at(other.start() + i) else {
      return false
    }
  }
  true
}

///|
/// Views are ordered based on shortlex order by their charcodes (code units). This 
/// orders Unicode characters based on their positions in the code charts. This is
/// not necessarily the same as "alphabetical" order, which varies by language
/// and locale.
pub impl Compare for StringView with compare(self, other) {
  let self_len = self.length()
  let other_len = other.length()
  let cmp = self_len.compare(other_len)
  guard cmp == 0 else { return cmp }
  if physical_equal(self.str(), other.str()) && self.start() == other.start() {
    return 0
  }
  for i in 0..<self_len {
    let cmp = self
      .str()
      .unsafe_charcode_at(self.start() + i)
      .compare(other.str().unsafe_charcode_at(other.start() + i))
    guard cmp == 0 else { return cmp }
  }
  0
}

///|
/// Performs a lexicographical comparison of two string views.
///
/// This method compares the views character by character (UTF-16 code unit by code unit),
/// similar to Java's `String.compareTo()`. Unlike the `Compare` trait implementation which
/// uses shortlex order (shorter strings come first), this method compares based purely on
/// character values until a difference is found or one view is exhausted.
///
/// # Returns
///
/// - A negative integer if `self` is lexicographically less than `other`
/// - Zero if `self` is lexicographically equal to `other`
/// - A positive integer if `self` is lexicographically greater than `other`
///
/// # Example
///
/// ```mbt check
/// test {
///   let str = "abc"
///   inspect(
///     str
///     .view(start_offset=0, end_offset=2)
///     .lexical_compare(str.view(start_offset=0, end_offset=3)),
///     content="-1",
///   )
///   inspect(
///     str
///     .view(start_offset=0, end_offset=3)
///     .lexical_compare(str.view(start_offset=0, end_offset=2)),
///     content="1",
///   )
///   inspect(
///     str
///     .view(start_offset=0, end_offset=2)
///     .lexical_compare(str.view(start_offset=1, end_offset=3)),
///     content="-1",
///   )
/// }
/// ```
///
/// # Note
///
/// Since MoonBit strings are UTF-16 encoded (like Java), this comparison operates on
/// UTF-16 code units, not Unicode code points. Surrogate pairs (used for characters
/// outside the Basic Multilingual Plane) are compared as individual code units.
pub fn StringView::lexical_compare(
  self : StringView,
  other : StringView,
) -> Int {
  let self_len = self.length()
  let other_len = other.length()
  let min_len = if self_len < other_len { self_len } else { other_len }

  // Compare character by character up to the minimum length
  for i in 0..<min_len {
    let self_char = self.str().unsafe_charcode_at(self.start() + i)
    let other_char = other.str().unsafe_charcode_at(other.start() + i)
    let cmp = self_char.compare(other_char)
    if cmp != 0 {
      return cmp
    }
  }

  // If all characters match up to min_len, the shorter one is lexicographically smaller
  self_len.compare(other_len)
}

///|
/// Creates a `View` into a `String`.
/// 
/// # Example
/// 
/// ```mbt check
/// test {
///   let str = "Hello🤣🤣🤣"
///   let view1 = str.view()
///   inspect(view1, content="Hello🤣🤣🤣")
///   let start_offset = str.offset_of_nth_char(1).unwrap()
///   let end_offset = str.offset_of_nth_char(6).unwrap() // the second emoji
///   let view2 = str.view(start_offset~, end_offset~)
///   inspect(view2, content="ello🤣")
/// }
/// ```
pub fn String::view(
  self : String,
  start_offset? : Int = 0,
  end_offset? : Int,
) -> StringView {
  let end_offset = if end_offset is Some(o) { o } else { self.length() }
  guard start_offset >= 0 &&
    start_offset <= end_offset &&
    end_offset <= self.length() else {
    abort("Invalid index for View")
  }
  StringView::make_view(self, start_offset, end_offset)
}

///|
/// Convert char array to string view.
pub fn StringView::from_array(chars : ArrayView[Char]) -> StringView {
  String::from_array(chars)
}

///|
/// Convert char iterator to string view.
#alias(from_iterator, deprecated)
pub fn StringView::from_iter(iter : Iter[Char]) -> StringView {
  String::from_iter(iter)
}

///|
pub suberror CreatingViewError {
  IndexOutOfBounds
  InvalidIndex
} derive(Show)

///|
/// Creates a view of a string with proper UTF-16 boundary validation.
/// 
/// # Parameters
/// 
/// - `start` : Starting UTF-16 code unit index (default: 0)
///   - If positive: counts from the beginning of the string
///   - If negative: counts from the end of the string (e.g., -1 means last position)
/// - `end` : Ending UTF-16 code unit index (optional)
///   - If `None`: extends to the end of the string
///   - If positive: counts from the beginning of the string
///   - If negative: counts from the end of the string
/// 
/// # Returns
/// 
/// - A `View` representing the specified substring range
/// 
/// # Errors
/// 
/// - `IndexOutOfBounds` : If start or end indices are out of valid range
/// - `InvalidIndex` : If start or end position would split a UTF-16 surrogate pair
/// 
/// This prevents creating views that would split surrogate pairs, which would
/// result in invalid Unicode characters.
/// 
/// # Performance
/// 
/// This function has O(1) complexity as it only performs boundary checks
/// without scanning the string content.
/// 
/// # Examples
/// 
/// ```mbt
/// let str = "Hello🤣World"
/// let view1 =  str[0:5]
/// inspect(
///   view1,
///   content=(
///     "Hello"
///   ),
/// )
/// let view2 = try? str[-5:]
/// inspect(
///   view2,
///   content=(
///     #|Ok("World")
///   ),
/// )
/// let view3 = try? str[:6]
/// inspect(view3, content="Err(InvalidIndex)")
/// ```
#alias("_[_:_]")
pub fn String::sub(
  self : String,
  start? : Int = 0,
  end? : Int,
) -> StringView raise CreatingViewError {
  let len = self.length()
  let end = match end {
    None => len
    Some(end) => if end < 0 { len + end } else { end }
  }
  let start = if start < 0 { len + start } else { start }
  guard start >= 0 && start <= end && end <= len else { raise IndexOutOfBounds }
  if start < len && self.unsafe_charcode_at(start).is_trailing_surrogate() {
    raise InvalidIndex
  }
  if end < len && self.unsafe_charcode_at(end).is_trailing_surrogate() {
    raise InvalidIndex
  }
  StringView::make_view(self, start, end)
}

///|
/// Creates a subview of an existing view with proper UTF-16 boundary validation.
/// 
/// # Parameters
/// 
/// - `start` : Starting UTF-16 code unit index relative to this view (default: 0)
///   - If positive: counts from the beginning of this view
///   - If negative: counts from the end of this view
/// - `end` : Ending UTF-16 code unit index relative to this view (optional)
///   - If `None`: extends to the end of this view
///   - If positive: counts from the beginning of this view
///   - If negative: counts from the end of this view
/// 
/// # Returns
/// 
/// - A `View` representing the specified subrange of this view
/// 
/// # Errors
/// 
/// - `IndexOutOfBounds` : If start or end indices are out of this view's range
/// - `InvalidIndex` : If start or end position would split a UTF-16 surrogate pair
/// 
/// This prevents creating views that would split surrogate pairs, which would
/// result in invalid Unicode characters.
/// 
/// # Performance
/// 
/// This function has O(1) complexity as it only performs boundary checks
/// without scanning the string content.
/// 
/// # Examples
/// 
/// ```mbt check
/// test {
///   let str = "Hello🤣World"[1:-1] // "ello🤣Worl"
///   let view1 = str[0:6]
///   inspect(view1, content="ello🤣")
///   let view2 = str[-2:]
///   inspect(view2, content="rl")
///   let view3 = try? str[:5]
///   inspect(view3, content="Err(InvalidIndex)")
/// }
/// ```
#alias("_[_:_]")
pub fn StringView::sub(
  self : StringView,
  start? : Int = 0,
  end? : Int,
) -> StringView raise CreatingViewError {
  let str_len = self.str().length()

  // Calculate absolute positions in the original string
  let abs_end = match end {
    None => self.end()
    Some(end) => if end < 0 { self.end() + end } else { self.start() + end }
  }
  let abs_start = if start < 0 {
    self.end() + start
  } else {
    self.start() + start
  }

  // Validate bounds against the original string
  guard abs_start >= self.start() &&
    abs_start <= abs_end &&
    abs_end <= self.end() else {
    raise IndexOutOfBounds
  }

  // Check for surrogate pair boundaries
  if abs_start < str_len &&
    self.str().unsafe_charcode_at(abs_start).is_trailing_surrogate() {
    raise InvalidIndex
  }
  if abs_end < str_len &&
    self.str().unsafe_charcode_at(abs_end).is_trailing_surrogate() {
    raise InvalidIndex
  }
  StringView::make_view(self.str(), abs_start, abs_end)
}

///|
/// Test if the length of the view is equal to the given length.
/// 
/// This has O(n) complexity where n is the length in the parameter.
pub fn StringView::char_length_eq(self : StringView, len : Int) -> Bool {
  self
  .str()
  .char_length_eq(len, start_offset=self.start(), end_offset=self.end())
}

///|
/// Test if the length of the view is greater than or equal to the given length.
/// 
/// This has O(n) complexity where n is the length in the parameter.
pub fn StringView::char_length_ge(self : StringView, len : Int) -> Bool {
  self
  .str()
  .char_length_ge(len, start_offset=self.start(), end_offset=self.end())
}

///|
/// Returns the UTF-16 index of the i-th (zero-indexed) Unicode character of
/// the view. If i is negative, it returns the index of the (n + i)-th character
/// where n is the total number of Unicode characters in the view.
pub fn StringView::offset_of_nth_char(self : StringView, i : Int) -> Int? {
  if self
    .str()
    .offset_of_nth_char(i, start_offset=self.start(), end_offset=self.end())
    is Some(index) {
    Some(index - self.start())
  } else {
    None
  }
}

///|
/// The empty view of a string
pub impl Default for StringView with default() {
  ""
}

///|
/// Create a new string by repeating the given character `value` `length` times.
pub fn StringView::make(length : Int, value : Char) -> StringView {
  String::make(length, value)
}

///|
pub impl ToJson for StringView with to_json(self) {
  String::to_json(self.to_string())
}

///|
pub impl Add for StringView with add(self, other) {
  [..self, ..other]
}
