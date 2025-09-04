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
/// A `@string.View` represents a view of a String that maintains proper Unicode
/// character boundaries. It allows safe access to a substring while handling 
/// multi-byte characters correctly.
#builtin.valtype
type View

///|
/// Returns the source string being viewed.
fn View::str(self : View) -> String = "%stringview.str"

///|
/// Returns the starting UTF-16 code unit index into the string.
fn View::start(self : View) -> Int = "%stringview.start"

///|
/// Returns the ending UTF-16 code unit index into the string (not included).
fn View::end(self : View) -> Int = "%stringview.end"

///|
fn View::make_view(str : String, start : Int, end : Int) -> View = "%stringview.make"

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
pub fn View::op_get(self : View, index : Int) -> Int {
  guard index >= 0 && index < self.length() else {
    abort("Index out of bounds")
  }
  self.str().unsafe_charcode_at(self.start() + index)
}

///|
/// Returns the original string that is being viewed.
pub fn data(self : View) -> String {
  self.str()
}

///|
/// Returns the starting offset (in UTF-16 code units) of this view into its
/// underlying string.
pub fn start_offset(self : View) -> Int {
  self.start()
}

///|
/// Returns the length of the view.
/// 
/// This method counts the charcodes(code unit) in the view and has O(1) complexity.
pub fn length(self : View) -> Int {
  self.end() - self.start()
}

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
) -> View {
  let end_offset = if end_offset is Some(o) { o } else { self.length() }
  guard start_offset >= 0 &&
    start_offset <= end_offset &&
    end_offset <= self.length() else {
    abort("Invalid index for View")
  }
  View::make_view(self, start_offset, end_offset)
}

///|
/// Returns a new view of the view with the given start and end offsets.
pub fn View::view(
  self : View,
  start_offset? : Int = 0,
  end_offset? : Int,
) -> View {
  let end_offset = if end_offset is Some(o) { o } else { self.length() }
  guard start_offset >= 0 &&
    start_offset <= end_offset &&
    end_offset <= self.length() else {
    abort("Invalid index for View")
  }
  View::make_view(
    self.str(),
    self.start() + start_offset,
    self.start() + end_offset,
  )
}

///|
/// Returns the UTF-16 index of the i-th (zero-indexed) Unicode character of
/// the view. If i is negative, it returns the index of the (n + i)-th character
/// where n is the total number of Unicode characters in the view.
pub fn View::offset_of_nth_char(self : View, i : Int) -> Int? {
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
pub fn View::unsafe_charcode_at(self : View, index : Int) -> Int {
  self.str().unsafe_charcode_at(self.start() + index)
}

///|
/// Returns the number of Unicode characters in this view.
/// 
/// Note this has O(n) complexity where n is the length of the code points in 
/// the view.
pub fn View::char_length(self : View) -> Int {
  self.str().char_length(start_offset=self.start(), end_offset=self.end())
}

///|
/// Test if the length of the view is equal to the given length.
/// 
/// This has O(n) complexity where n is the length in the parameter.
pub fn View::char_length_eq(self : View, len : Int) -> Bool {
  self
  .str()
  .char_length_eq(len, start_offset=self.start(), end_offset=self.end())
}

///|
/// Test if the length of the view is greater than or equal to the given length.
/// 
/// This has O(n) complexity where n is the length in the parameter.
pub fn View::char_length_ge(self : View, len : Int) -> Bool {
  self
  .str()
  .char_length_ge(len, start_offset=self.start(), end_offset=self.end())
}

///|
pub impl Show for View with output(self, logger) {
  let substr = self.str().unsafe_substring(start=self.start(), end=self.end())
  String::output(substr, logger)
}

///|
/// Returns a new String containing a copy of the characters in this view.
/// 
/// # Examples
/// 
/// ```mbt
///   let str = "Hello World"
///   let view = str.view(start_offset = str.offset_of_nth_char(0).unwrap(),end_offset = str.offset_of_nth_char(5).unwrap()) // "Hello"
///   inspect(view.to_string(), content="Hello")
/// ```
pub impl Show for View with to_string(self) {
  self.str().unsafe_substring(start=self.start(), end=self.end())
}

///|
/// Returns an iterator over the Unicode characters in the string view.
pub fn View::iter(self : View) -> Iter[Char] {
  Iter::new(yield_ => for index in self.start()..<self.end() {
    let c1 = self.str().unsafe_charcode_at(index)
    if c1.is_leading_surrogate() && index + 1 < self.end() {
      let c2 = self.str().unsafe_charcode_at(index + 1)
      if c2.is_trailing_surrogate() {
        let c = code_point_of_surrogate_pair(c1, c2)
        guard yield_(c) is IterContinue else { break IterEnd }
        continue index + 2
      }
    }
    guard yield_(c1.unsafe_to_char()) is IterContinue else { break IterEnd }
  } else {
    IterContinue
  })
}

///|
pub fn View::iter2(self : View) -> Iter2[Int, Char] {
  Iter2::new(yield_ => {
    let len = self.length()
    for index = 0, n = 0; index < len; index = index + 1, n = n + 1 {
      let c1 = self.str().unsafe_charcode_at(self.start() + index)
      if c1.is_leading_surrogate() && index + 1 < len {
        let c2 = self.str().unsafe_charcode_at(self.start() + index + 1)
        if c2.is_trailing_surrogate() {
          let c = code_point_of_surrogate_pair(c1, c2)
          guard yield_(n, c) is IterContinue else { break IterEnd }
          continue index + 2, n + 1
        }
      }
      guard yield_(n, c1.unsafe_to_char()) is IterContinue else {
        break IterEnd
      }
    } else {
      IterContinue
    }
  })
}

///|
/// Returns an iterator over the Unicode characters in the string view in reverse order.
pub fn View::rev_iter(self : View) -> Iter[Char] {
  Iter::new(yield_ => for index = self.end() - 1
                          index >= self.start()
                          index = index - 1 {
    let c1 = self.str().unsafe_charcode_at(index)
    if c1.is_trailing_surrogate() && index - 1 >= 0 {
      let c2 = self.str().unsafe_charcode_at(index - 1)
      if c2.is_leading_surrogate() {
        let c = code_point_of_surrogate_pair(c2, c1)
        guard yield_(c) is IterContinue else { break IterEnd }
        continue index - 2
      }
    }
    guard yield_(c1.unsafe_to_char()) is IterContinue else { break IterEnd }
  } else {
    IterContinue
  })
}

///|
/// Compares two views for equality. Returns true only if both views
/// have the same length and contain identical characters in the same order.
pub impl Eq for View with equal(self, other) {
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
pub impl Compare for View with compare(self, other) {
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
/// The empty view of a string
pub impl Default for View with default() {
  View::make_view("", 0, 0)
}

///|
/// Convert char array to string view.
pub fn View::from_array(chars : Array[Char]) -> View {
  let s = String::from_array(chars)
  View::make_view(s, 0, s.length())
}

///|
/// Convert char iterator to string view.
pub fn View::from_iter(iter : Iter[Char]) -> View {
  let s = String::from_iter(iter)
  View::make_view(s, 0, s.length())
}

///|
/// Create a new string by repeating the given character `value` `length` times.
pub fn View::make(length : Int, value : Char) -> View {
  // todo: remove .view() in new version
  String::make(length, value).view()
}

///|
pub impl ToJson for View with to_json(self) {
  String::to_json(self.to_string())
}

///|
pub impl Hash for View with hash_combine(self : View, hasher : Hasher) -> Unit {
  for i in 0..<self.length() {
    hasher.combine_uint(self.unsafe_charcode_at(i).reinterpret_as_uint())
  }
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
#alias(op_as_view)
pub fn String::sub(
  self : String,
  start? : Int = 0,
  end? : Int,
) -> View raise CreatingViewError {
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
  View::make_view(self, start, end)
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
#alias(op_as_view)
pub fn View::sub(
  self : View,
  start? : Int = 0,
  end? : Int,
) -> View raise CreatingViewError {
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
  View::make_view(self.str(), abs_start, abs_end)
}

///|
pub impl Add for View with add(self, other) {
  [..self, ..other]
}
