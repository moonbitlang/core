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
/// Creates a `View` into a `String`.
/// 
/// # Example
/// 
/// ```mbt
///   let str = "Hello🤣🤣🤣"
///   let view1 = str.view()
///   inspect(view1, content=
///    "Hello🤣🤣🤣"
///   )
///   let start_offset = str.offset_of_nth_char(1).unwrap()
///   let end_offset = str.offset_of_nth_char(6).unwrap() // the second emoji
///   let view2 = str.view(start_offset~, end_offset~)
///   inspect(view2, content=
///    "ello🤣"
///   )
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
pub fn StringView::from_iter(iter : Iter[Char]) -> StringView {
  String::from_iter(iter)
}

///|
/// Convert char iterator to string view.
pub fn StringView::from_iterator(iter : Iterator[Char]) -> StringView {
  String::from_iterator(iter)
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
pub type View = StringView
