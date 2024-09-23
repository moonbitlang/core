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

/// Convert char array to string.
/// 
/// ```
/// String::from_array(['H', 'e', 'l', 'l', 'o']) // "Hello"  
/// ```
/// 
/// Do not convert large datas to `Array[Char]` and build a string with `String::join`.
/// 
/// For efficiency considerations, it's recommended to use `Buffer` instead.
pub fn String::from_array(chars : Array[Char]) -> String {
  let buf = Buffer::new(size_hint=chars.length() * 4)
  for c in chars {
    buf.write_char(c)
  }
  buf.to_string()
}

/// Concatenate strings.
/// 
/// ```
/// String::concat(["Hello", ", ", "world!"]) // "Hello, world!"
/// String::concat(["a", "b", "c"], separator=",") // "a,b,c"
/// ```
/// 
pub fn String::concat(
  strings : Array[String],
  ~separator : String = ""
) -> String {
  let buf = Buffer::new()
  if separator == "" {
    for s in strings {
      buf.write_string(s)
    }
  } else {
    match strings {
      [] => ()
      [hd, .. as tl] => {
        buf.write_string(hd)
        for s in tl {
          buf.write_string(separator)
          buf.write_string(s)
        }
      }
    }
  }
  buf.to_string()
}

/// Compare two strings.
/// String with longer length is bigger.
/// strings of the same length are compared in lexicalgraphic order.
pub fn compare(self : String, other : String) -> Int {
  let len = self.length()
  match len.compare(other.length()) {
    0 => {
      for i = 0; i < len; i = i + 1 {
        let order = self[i].compare(other[i])
        if order != 0 {
          return order
        }
      }
      0
    }
    order => order
  }
}

/// The empty string
pub fn String::default() -> String {
  ""
}

/// `String` holds a sequence of UTF-16 code units encoded in little endian format
pub fn to_bytes(self : String) -> Bytes {
  let len = self.length()
  let bytes = Bytes::new(len * 2)
  bytes.blit_from_string(0, self, 0, len)
  bytes
}

/// Converts the String into an array of Chars.
pub fn to_array(self : String) -> Array[Char] {
  self
  .iter()
  .fold(
    init=Array::new(capacity=self.length()),
    fn(rv, c) {
      rv.push(c)
      rv
    },
  )
}

/// @intrinsic %string.substring
fn unsafe_substring(str : String, start : Int, end : Int) -> String {
  let len = end - start
  let buf = Buffer::new(size_hint=len)
  buf.write_sub_string(str, start, len)
  buf.to_string()
}

/// Get substring of the string from [start] to [end] exclusive.
pub fn substring(
  self : String,
  ~start : Int = 0,
  ~end : Int = self.length()
) -> String {
  if start < 0 {
    abort("String::substring: start index is negative")
  }
  if end < 0 {
    abort("String::substring: end index is negative")
  }
  if start > end {
    abort("String::substring: start index is greater than end index")
  }
  if end > self.length() {
    abort(
      "String::substring: end index is greater than the length of the string",
    )
  }
  unsafe_substring(self, start, end)
}

pub fn iter(self : String) -> Iter[Char] {
  Iter::new(
    fn(yield) {
      let len = self.length()
      for index = 0; index < len; index = index + 1 {
        let c1 = self[index]
        if is_leading_surrogate(c1) && index + 1 < len {
          let c2 = self[index + 1]
          if is_trailing_surrogate(c2) {
            let c = code_point_of_surrogate_pair(c1, c2)
            guard let IterContinue = yield(c) else { x => break x }
            continue index + 2
          }
        }
        //TODO: handle garbage input
        guard let IterContinue = yield(c1) else { x => break x }

      } else {
        IterContinue
      }
    },
  )
}

pub fn iter2(self : String) -> Iter2[Int, Char] {
  Iter2::new(
    fn(yield) {
      let len = self.length()
      for index = 0, n = 0; index < len; index = index + 1, n = n + 1 {
        let c1 = self[index]
        if is_leading_surrogate(c1) && index + 1 < len {
          let c2 = self[index + 1]
          if is_trailing_surrogate(c2) {
            let c = code_point_of_surrogate_pair(c1, c2)
            guard let IterContinue = yield(n, c) else { x => break x }
            continue index + 2, n + 1
          }
        }
        //TODO: handle garbage input
        guard let IterContinue = yield(n, c1) else { x => break x }

      } else {
        IterContinue
      }
    },
  )
}

pub fn fold[A](self : String, ~init : A, f : (A, Char) -> A) -> A {
  let mut rv = init
  for c in self {
    rv = f(rv, c)
  }
  rv
}

pub fn rev_fold[A](self : String, ~init : A, f : (A, Char) -> A) -> A {
  let mut rv = init
  for c in self.rev_iter() {
    rv = f(rv, c)
  }
  rv
}

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
/// - Stops iteration if the `yield` function returns `IterEnd`.
/// 
/// # Examples
/// 
/// ```moonbit
/// test {
///   let input = "Hello, World!"
///   let reversed = rev_iter(input).collect()
///   inspect!(reversed, content="[\"!\", \"d\", \"l\", \"r\", \"o\", \"W\", \" \", \",\", \"o\", \"l\", \"l\", \"e\", \"H\"]")
/// }
/// ```
pub fn rev_iter(self : String) -> Iter[Char] {
  Iter::new(
    fn(yield) {
      let len = self.length()
      for index = len - 1; index >= 0; index = index - 1 {
        let c1 = self[index]
        if is_trailing_surrogate(c1) && index - 1 >= 0 {
          let c2 = self[index - 1]
          if is_leading_surrogate(c2) {
            let c = code_point_of_surrogate_pair(c2, c1)
            guard let IterContinue = yield(c) else { x => break x }
            continue index - 2
          }
        }
        // TODO: handle garbage input
        guard let IterContinue = yield(c1) else { x => break x }

      } else {
        IterContinue
      }
    },
  )
}

/// Removes all leading and trailing spaces.
pub fn trim_space(self : String) -> String {
  self.trim(" \n\r\t")
}

/// Removes all leading and trailing chars contained in the given string.
pub fn trim(self : String, trim_set : String) -> String {
  if self == "" || trim_set == "" {
    self
  } else {
    self.trim_start(trim_set).trim_end(trim_set)
  }
}

pub fn contains_char(self : String, c : Char) -> Bool {
  self.iter().any(fn(ch) { ch == c })
}

/// @alert deprecated "Use `String::trim_start` instead"
pub fn trim_left(self : String, trim_set : String) -> String {
  self.trim_start(trim_set)
}

/// Removes all leading chars contained in the given string.
pub fn trim_start(self : String, trim_set : String) -> String {
  let len = self.length()
  for i = 0; i < len; i = i + 1 {
    let c1 = self[i]
    // check surrogate pair
    if is_leading_surrogate(c1) && i + 1 < len {
      let c2 = self[i + 1]
      if is_trailing_surrogate(c2) {
        let ch = code_point_of_surrogate_pair(c1, c2)
        if trim_set.contains_char(ch) {
          continue i + 2
        } else {
          return self.substring(start=i)
        }
      }
    }
    if trim_set.contains_char(self[i]).not() {
      return self.substring(start=i)
    }
  } else {
    ""
  }
}

/// @alert deprecated "Use `String::trim_end` instead"
pub fn trim_right(self : String, trim_set : String) -> String {
  self.trim_end(trim_set)
}

/// Removes all trailing chars contained in the given string.
pub fn trim_end(self : String, trim_set : String) -> String {
  let len = self.length()
  for i = len - 1; i >= 0; i = i - 1 {
    let c2 = self[i]
    // check surrogate pair
    if is_trailing_surrogate(c2) && i - 1 >= 0 {
      let c1 = self[i - 1]
      if is_leading_surrogate(c1) {
        let ch = code_point_of_surrogate_pair(c1, c2)
        if trim_set.contains_char(ch) {
          continue i - 2
        } else {
          return self.substring(end=i + 1)
        }
      }
    }
    if trim_set.contains_char(self[i]).not() {
      return self.substring(end=i + 1)
    }
  } else {
    ""
  }
}

/// Returns true if this string is empty.
pub fn is_empty(self : String) -> Bool {
  self == ""
}

/// Returns true if this string is blank.
pub fn is_blank(self : String) -> Bool {
  self.trim_space() == ""
}

/// Returns the first index of the sub string.
pub fn index_of(self : String, str : String, ~from : Int = 0) -> Int {
  let from = if from < 0 {
    0
  } else if from >= self.length() {
    self.length() - 1
  } else {
    from
  }
  let len = self.length()
  let sub_len = str.length()
  let max_idx = len - sub_len
  if sub_len == 0 {
    return 0
  }
  if sub_len > len {
    return -1
  }
  let first = str[0]
  let mut i = from
  while i <= max_idx {
    // find first character
    while i < len && self[i] != first {
      i += 1
    }
    // check the rest
    if i <= max_idx {
      let mut j = i + 1
      let mut k = 1
      let end = j + sub_len - 1
      while j < end && self[j] == str[k] {
        j += 1
        k += 1
      }
      if j == end {
        return i
      }
    }
    i += 1
  }
  -1
}

/// Returns the last index of the sub string.
pub fn last_index_of(
  self : String,
  str : String,
  ~from : Int = self.length()
) -> Int {
  let from = if from < 0 {
    0
  } else if from > self.length() {
    self.length()
  } else {
    from
  }
  let len = self.length()
  let sub_len = str.length()
  if sub_len == 0 {
    return from
  }
  if len < sub_len {
    return -1
  }
  let min = sub_len - 1
  let last = str[sub_len - 1]
  let mut i = from - 1
  while i >= 0 {
    // find last character
    while i >= min && self[i] != last {
      i -= 1
    }
    if i < min {
      return -1
    }
    let mut j = i - 1
    let mut k = sub_len - 2
    let start = i - sub_len
    let found = while j > start {
      if self[j] != str[k] {
        break false
      }
      j -= 1
      k -= 1
    } else {
      true
    }
    if found {
      return start + 1
    }
    i -= 1
  }
  -1
}

/// Returns true if this string contains given sub string.
pub fn contains(self : String, str : String) -> Bool {
  self.index_of(str) >= 0
}

/// Returns true if this string starts with a sub string.
pub fn starts_with(self : String, str : String) -> Bool {
  if str.length() > self.length() {
    false
  } else {
    self.index_of(str) == 0
  }
}

/// Returns true if this string ends with a sub string.
pub fn ends_with(self : String, str : String) -> Bool {
  let len = self.length()
  let sub_len = str.length()
  if sub_len > len {
    false
  } else {
    self.last_index_of(str) == len - sub_len
  }
}

/// Splits the input `String` into an `Iter` of `String` using the specified `separator`.
/// 
/// # Parameters
/// 
/// - `self` : The input `String` to be split.
/// - `separator` : The `String` used as the delimiter for splitting.
/// 
/// # Returns
/// 
/// - An `Iter` of `String` where each element is a substring of the original string, separated by the `separator`.
/// 
/// # Behavior
/// 
/// - If the `separator` is an empty string (`""`), the function returns an `Iter` where each element is a single character from the input string converted to a `String`.
/// - If the `separator` is not empty, the function searches for occurrences of the `separator` in the input string and yields substrings between these occurrences.
/// - If no more occurrences of the `separator` are found, the remaining part of the string is yielded as the last element of the `Iter`.
/// 
/// # Examples
/// 
/// ```moonbit
/// test {
///   let input = "a,b,c,d"
///   let separator = ","
///   let result = split(input, separator).collect()
///   inspect!(result, content="[\"a\", \"b\", \"c\", \"d\"]")
/// }
/// ```
pub fn split(self : String, seperator : String) -> Iter[String] {
  let len = self.length()
  let sep_len = seperator.length()
  if sep_len == 0 {
    return self.iter().map(fn(c) { c.to_string() })
  }
  Iter::new(
    fn(yield) {
      let mut start = 0
      while start < len {
        let end = self.index_of(seperator, from=start)
        if end < 0 {
          if yield(self.substring(~start)) == IterEnd {
            break IterEnd
          }
          break IterContinue
        }
        if yield(self.substring(~start, ~end)) == IterEnd {
          break IterEnd
        }
        start = end + sep_len
      } else {
        IterContinue
      }
    },
  )
}

/// Replace the first old string in this string to new string.
pub fn replace(self : String, ~old : String, ~new : String) -> String {
  let old_idx = self.index_of(old)
  if old_idx < 0 {
    self
  } else {
    self.substring(end=old_idx) +
    new +
    self.substring(start=old_idx + old.length())
  }
}

/// Replace all old string in this string to new string.
pub fn replace_all(self : String, ~old : String, ~new : String) -> String {
  let buf = Buffer::new()
  let len = self.length()
  let old_len = old.length()
  if old_len == 0 {
    buf.write_string(new)
    self
    .iter()
    .each(
      fn(c) {
        buf.write_char(c)
        buf.write_string(new)
      },
    )
  } else {
    let mut start = 0
    while start < len {
      let end = self.index_of(old, from=start)
      if end < 0 {
        buf.write_string(self.substring(~start))
        break
      }
      buf.write_string(self.substring(~start, ~end))
      buf.write_string(new)
      start = end + old_len
    }
  }
  buf.to_string()
}

/// Converts this string to lowercase.
pub fn to_lower(self : String) -> String {
  // TODO: deal with non-ascii characters
  let buf = Buffer::new(size_hint=self.length())
  for c in self {
    if c >= 'A' && c <= 'Z' {
      buf.write_char(Char::from_int(c.to_int() + 32))
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

/// Converts this string to uppercase.
pub fn to_upper(self : String) -> String {
  // TODO: deal with non-ascii characters
  let buf = Buffer::new(size_hint=self.length())
  for c in self {
    if c >= 'a' && c <= 'z' {
      buf.write_char(Char::from_int(c.to_int() - 32))
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

/// Reverse string
pub fn rev(self : String) -> String {
  // TODO: deal with non-ascii characters
  let mut result : String = ""
  let len = self.length()
  for i = len - 1; i >= 0; i = i - 1 {
    result = result + self[i].to_string()
  }
  result
}

/// Repeats the string `n` times.
pub fn repeat(self : String, n : Int) -> String {
  if n <= 0 {
    return ""
  }
  if n == 1 {
    return self
  }
  let len = self.length()
  let buf = Buffer::new(size_hint=len * n)
  for _ in 0..<n {
    buf.write_string(self)
  }
  buf.to_string()
}

/// `pad_left` is a new string with `padding_char`s prefixed to `self` if `self.length() < total_width`. The length of the
/// returned string is `total_width`.
/// 
/// Example:
/// 
/// ```"2".pad_left(3, '0') == "002"```
pub fn pad_start(
  self : String,
  total_width : Int,
  padding_char : Char
) -> String {
  let len = self.length()
  if len >= total_width {
    self
  } else {
    let buf = Buffer::new(size_hint=total_width)
    for i = 0; i < total_width - len; i = i + 1 {
      buf.write_char(padding_char)
    }
    buf.write_string(self)
    buf.to_string()
  }
}

/// `pad_right` is a new String with `padding_char`s suffixed to `self` if `self.length() < total_width`. The length of the
/// returned string is `total_width`.
/// 
/// Example:
/// 
/// ```"2".pad_right(3, 'x') == "2xx"```
pub fn pad_end(self : String, total_width : Int, padding_char : Char) -> String {
  let len = self.length()
  if len >= total_width {
    self
  } else {
    let buf = Buffer::new(size_hint=total_width)
    buf.write_string(self)
    for i = 0; i < total_width - len; i = i + 1 {
      buf.write_char(padding_char)
    }
    buf.to_string()
  }
}
