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
/// Returns the source string being viewed.
pub fn StringView::str(self : StringView) -> String = "%stringview.str"

///|
/// Returns the starting UTF-16 code unit index into the string.
pub fn StringView::start(self : StringView) -> Int = "%stringview.start"

///|
/// Returns the ending UTF-16 code unit index into the string (not included).
pub fn StringView::end(self : StringView) -> Int = "%stringview.end"

///|
pub fn StringView::make_view(
  str : String,
  start : Int,
  end : Int,
) -> StringView = "%stringview.make"

///|
/// Returns the length of the view.
/// 
/// This method counts the charcodes(code unit) in the view and has O(1) complexity.
pub fn StringView::length(self : StringView) -> Int {
  self.end() - self.start()
}

///|
/// Returns the charcode(code unit) at the given index without checking if the
/// index is within bounds.
/// 
/// This method has O(1) complexity.
/// #Example
/// 
/// ```mbt
///   let str = "B🤣🤣C"
///   let view = str[:]
///   inspect(view.unsafe_charcode_at(0), content="66")
///   inspect(view.unsafe_charcode_at(1), content="55358")
///   inspect(view.unsafe_charcode_at(2), content="56611")
///   inspect(view.unsafe_charcode_at(3), content="55358")
///   inspect(view.unsafe_charcode_at(4), content="56611")
///   inspect(view.unsafe_charcode_at(5), content="67")
/// ```
/// TODO: rename to `unsafe_get`
pub fn StringView::unsafe_charcode_at(self : StringView, index : Int) -> Int {
  self.str().unsafe_charcode_at(self.start() + index)
}

///|
/// Returns the charcode(UTF-16 code unit) at the given index.
/// 
/// This method has O(1) complexity.
/// 
/// # Example
/// 
/// ```mbt
///   let str = "Hello🤣🤣🤣"
///   let view = str.view(start_offset = str.offset_of_nth_char(1).unwrap(), end_offset = str.offset_of_nth_char(6).unwrap())
///   inspect(view[0].to_char(), content="Some('e')")
///   inspect(view[4], content="55358")
/// ```
#alias("_[_]")
pub fn StringView::at(self : StringView, index : Int) -> Int {
  guard index >= 0 && index < self.length() else {
    abort("Index out of bounds")
  }
  self.str().unsafe_charcode_at(self.start() + index)
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
/// ```mbt
/// let str = "Hello🤣World"[1:-1] // "ello🤣Worl"
/// let view1 = str[0:6]
/// inspect(view1, content="ello🤣")
/// let view2 = str[-2:]
/// inspect(view2, content="rl")
/// let view3 = try? str[:5]
/// inspect(view3, content="Err(InvalidIndex)")
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
pub impl Hash for StringView with hash_combine(
  self : StringView,
  hasher : Hasher,
) -> Unit {
  for i in 0..<self.length() {
    hasher.combine_uint(self.unsafe_charcode_at(i).reinterpret_as_uint())
  }
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
pub suberror CreatingViewError {
  IndexOutOfBounds
  InvalidIndex
} derive(Show)
